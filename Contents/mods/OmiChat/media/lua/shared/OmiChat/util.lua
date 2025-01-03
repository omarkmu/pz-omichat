local lib = require 'OmiChat/lib'
local Interpolator = require 'OmiChat/Component/Interpolator'

local pow = math.pow
local floor = math.floor
local max = math.max
local min = math.min
local char = string.char
local format = string.format
local concat = table.concat
local getTimestampMs = getTimestampMs


---Utility functions.
---@class omichat.utils : omi.utils
---@field private _interpolatorCache table<string, omichat.utils.InterpolatorCacheItem>
---@field private _playerCacheByUsername table<string, omichat.utils.PlayerCacheItem>
---@field private _playerCacheByOnlineID table<string, omichat.utils.PlayerCacheItem>
local utils = lib.utils.copy(lib.utils)
utils.Interpolator = Interpolator
utils._interpolatorCache = {}
utils._playerCacheByUsername = {}
utils._playerCacheByOnlineID = {}

---@class omichat.utils.InterpolatorCacheItem
---@field interpolator omichat.Interpolator
---@field lastAccess number

---@class omichat.utils.PlayerCacheItem
---@field username string
---@field forename string
---@field surname string
---@field onlineID number
---@field speechColor omichat.ColorTable


local CACHE_EXPIRY_MS = 600000 -- ten minutes
local shortHexPattern = '^%s*#?(%x)(%x)(%x)%s*$'
local fullHexPattern = '^%s*#?(%x%x)%s*(%x%x)%s*(%x%x)%s*$'
local rgbPattern = '^%s*(%d%d?%d?)[,%s]+(%d%d?%d?)[,%s]+(%d%d?%d?)%s*$'

local accessLevels = {
    admin = 32,
    moderator = 16,
    overseer = 8,
    gm = 4,
    observer = 2,
}
local suits = {
    'Clubs',
    'Diamonds',
    'Hearts',
    'Spades',
}
local cards = {
    'Ace',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Jack',
    'Queen',
    'King',
}

---@type table<string, string>
local iconToTextureNameMap = {}
local loadedIcons = false


---Gets an interpolator from the cache.
---@param text string
---@return omichat.Interpolator?
local function getCachedInterpolator(text)
    local item = utils._interpolatorCache[text]
    if item then
        item.lastAccess = getTimestampMs()
        return item.interpolator
    end
end

---Collects valid icons and builds a map of icon names to texture names.
local function loadIcons()
    local dest = HashMap.new()
    Texture.collectAllIcons(HashMap.new(), dest)
    iconToTextureNameMap = transformIntoKahluaTable(dest)
    iconToTextureNameMap.music = 'Icon_music_notes' -- special case for 'music'
    loadedIcons = true
end

---Adds an interpolator to the cache.
---@param text string
---@param interpolator omichat.Interpolator
local function setCachedInterpolator(text, interpolator)
    utils._interpolatorCache[text] = {
        interpolator = interpolator,
        lastAccess = getTimestampMs(),
    }
end

---Attempts to read an RGB or hex color from a string.
---@param text string
---@return number?
---@return number?
---@return number?
local function readColor(text)
    local r, g, b = text:match(rgbPattern)
    if r then
        return tonumber(r), tonumber(g), tonumber(b)
    end

    r, g, b = text:match(shortHexPattern)
    if r then
        r = r .. r
        g = g .. g
        b = b .. b
    else
        r, g, b = text:match(fullHexPattern)
    end

    if not r then
        return
    end

    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

---Creates a cache item for the given player.
---@param player IsoPlayer
---@return omichat.utils.PlayerCacheItem
local function buildPlayerCacheItem(player)
    local desc = player:getDescriptor()

    local speechColor
    local color = player:getSpeakColour()
    if color then
        speechColor = {
            r = color:getRed(),
            g = color:getGreen(),
            b = color:getBlue(),
        }
    else
        speechColor = { r = 255, g = 255, b = 255 }
    end

    ---@type omichat.utils.PlayerCacheItem
    local item = {
        username = player:getUsername(),
        forename = desc:getForename(),
        surname = desc:getSurname(),
        onlineID = player:getOnlineID(),
        speechColor = speechColor,
    }

    return item
end

---Updates the cache with the player's information.
---@param player IsoPlayer
---@return omichat.utils.PlayerCacheItem
local function updateCacheWithPlayer(player)
    local item = buildPlayerCacheItem(player)

    utils._playerCacheByUsername[item.username] = item
    utils._playerCacheByOnlineID[item.onlineID] = item
    return item
end


---Encodes additional information in a message tag.
---@param message omichat.Message
---@param key string
---@param value unknown
function utils.addMessageTagValue(message, key, value)
    local tag = message:getCustomTag()
    local success, newTag, encodedTag
    success, newTag = utils.json.tryDecode(tag)
    if not success or type(newTag) ~= 'table' then
        newTag = {}
    end

    newTag[key] = value
    success, encodedTag = utils.json.tryEncode(newTag)
    if not success then
        -- other data is bad, so just throw it out
        if type(value) == 'string' then
            value = string.format('%q', value)
        end

        encodedTag = string.format('{"%s":%s}', key, tostring(value))
    end

    message:setCustomTag(encodedTag)
end

---Adds a player to the cache.
---@param player IsoPlayer
---@return omichat.utils.PlayerCacheItem
function utils.cachePlayer(player)
    return updateCacheWithPlayer(player)
end

---Adds an item to the player cache.
---@param item omichat.utils.PlayerCacheItem
function utils.cachePlayerInfo(item)
    utils._playerCacheByUsername[item.username] = item
    utils._playerCacheByOnlineID[item.onlineID] = item
end

---Clamps the RGB color values in `color` to within the provided range.
---@param color omichat.DecimalColorTable An RGB color table with values in [0, 1].
---@param minVal number A value in [0, 1].
---@param maxVal number A value in [0, 1].
---@return omichat.DecimalColorTable
function utils.clampDecimalColor(color, minVal, maxVal)
    return {
        r = min(max(color.r, minVal), maxVal),
        g = min(max(color.g, minVal), maxVal),
        b = min(max(color.b, minVal), maxVal),
    }
end

---Cleans up unused cache items.
---@param clear boolean If true, the cache will be cleared entirely.
function utils.cleanupCache(clear)
    if clear then
        utils._interpolatorCache = {}
        return
    end

    local toRemove = {}
    local currentTime = getTimestampMs()
    for k, item in pairs(utils._interpolatorCache) do
        if currentTime - item.lastAccess >= CACHE_EXPIRY_MS then
            toRemove[#toRemove + 1] = k
        end
    end

    for i = 1, #toRemove do
        utils._interpolatorCache[toRemove[i]] = nil
    end
end

---Converts a color table to a hex string.
---@param color omichat.ColorTable
---@return string
function utils.colorToHexString(color)
    return format('%02x%02x%02x', color.r, color.g, color.b)
end

---Converts a color table to an RGB string.
---@param color omichat.ColorTable
---@return string
function utils.colorToRGBString(color)
    return format('%d,%d,%d', color.r, color.g, color.b)
end

---Builds a callback info object.
---@param target unknown? The first argument to pass to the callback function.
---@param callback function? The callback function.
---@param ... unknown Callback arguments.
---@return omichat.CallbackInfo?
function utils.createCallback(target, callback, ...)
    if not callback then
        return
    end

    local n = select('#', ...)
    local args = { n = n }
    for i = 1, n do
        args[i] = select(i, ...)
    end

    ---@type omichat.CallbackInfo
    local info = {
        target = target,
        callback = callback,
        args = args,
    }

    return info
end

---Creates a yes/no modal dialog.
---@param text string
---@param target unknown?
---@param onclick function?
---@param param1 unknown?
---@param param2 unknown?
---@return ISModalDialog
function utils.createModal(text, target, onclick, param1, param2)
    local w, h = ISModalDialog.CalcSize(0, 0, text) ---@cast h number
    local x, y = utils.getScreenCenter(w, h)

    local modal = ISModalDialog:new(x, y, w, h, text, true, target, onclick, nil, param1, param2)
    modal.moveWithMouse = true
    modal:initialise()
    modal:addToUIManager()

    return modal
end

---Decodes an encoded character.
---@param text string
---@return integer
function utils.decodeInvisibleCharacter(text)
    if not text or #text == 0 then
        return 0
    end

    return text:byte() - 127
end

---Decodes an encoded integer value.
---@param text string
---@return integer? value
---@return string? remaining
function utils.decodeInvisibleInt(text)
    local len = utils.decodeInvisibleCharacter(text)
    if len < 1 or len > 32 then
        return
    end

    local value = 0
    local endPos = min(#text, len + 1)
    for i = 2, endPos do
        local digit = utils.decodeInvisibleCharacter(text:sub(i, i)) - 1
        if digit < 0 or digit > 31 then
            return
        end

        value = value + digit * pow(32, i - 2)
    end

    return value, text:sub(endPos + 1)
end

---Decodes a sequence of encoded integers.
---@param text string
---@param amount integer
---@return integer[]? sequence The integer sequence.
---@return string? remaining The remaining text, after the sequence.
function utils.decodeInvisibleIntSequence(text, amount)
    local decoded
    local remaining = text ---@type string?

    local results = {}
    for _ = 1, amount do
        decoded, remaining = utils.decodeInvisibleInt(text)
        if not decoded or not remaining then
            return
        end

        results[#results + 1] = decoded
        text = remaining
    end

    return results, text
end

---Decodes an encoded string of character indices.
---@param text any
---@return string? result
---@return string? remaining
function utils.decodeInvisibleString(text)
    local seq
    local length
    local remaining

    length, remaining = utils.decodeInvisibleInt(text)
    if not length then
        return
    end

    ---@cast remaining string
    seq, remaining = utils.decodeInvisibleIntSequence(remaining, length)
    if not seq then
        return
    end

    local chars = {}
    for i = 1, #seq do
        chars[#chars + 1] = char(seq[i])
    end

    return concat(chars), remaining
end

---Encodes an integer value in [1, 32] into a character.
---@param n integer
---@return string
function utils.encodeInvisibleCharacter(n)
    return string.char(n + 127)
end

---Encodes a non-negative integer value as an invisible representation of its digits.
---@param value integer
---@return string
function utils.encodeInvisibleInt(value)
    value = floor(value)
    if value < 0 then
        utils.logError('attempted to encode negative value: ' .. value)
        return ''
    end

    local originalValue = value
    local result = {}
    while value > 0 do
        if #result == 32 then
            utils.logError('value is too large to encode: ' .. originalValue)
            return ''
        end

        result[#result + 1] = utils.encodeInvisibleCharacter((value % 32) + 1)
        value = floor(value / 32)
    end

    if #result == 0 then
        result[1] = utils.encodeInvisibleCharacter(1)
    end

    local len = utils.encodeInvisibleCharacter(#result)
    return len .. concat(result)
end

---Encodes a string as a sequence of invisible encoded integers.
---@param text string
---@return string
function utils.encodeInvisibleString(text)
    local chars = {}
    for i = 1, #text do
        chars[#chars + 1] = utils.encodeInvisibleInt(text:sub(i, i):byte())
    end

    return utils.encodeInvisibleInt(#chars) .. concat(chars)
end

---Escapes a string for use in a rich text panel.
---@see ISRichTextPanel
---@param text string
---@return string
function utils.escapeRichText(text)
    return (text:gsub('<', '&lt;'):gsub('>', '&gt;'))
end

---Appends members of `t1` to `t2`.
---@param t1 unknown[]
---@param t2 unknown[]
---@return unknown[]
function utils.extend(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end

    return t1
end

---Gets an error from the error tokens, if one is set, and unsets the tokens.
---@param tokens table
---@return string?
function utils.extractError(tokens)
    local err
    local error = tostring(tokens.error or '')
    local errorID = tostring(tokens.errorID or '')

    if error ~= '' then
        err = tostring(error or '')
    elseif errorID ~= '' then
        err = getText(errorID)
    end

    tokens.error = nil
    tokens.errorID = nil

    return err
end

---Gets the end position of an author in a raw chat message, if present.
---@param text string
---@param author string
---@return integer?
function utils.getAuthorEndPos(text, author)
    local _, authorEnd = text:find('%[' .. utils.escape(author) .. '%]:')
    return authorEnd
end

---Gets the base color picker class given a class object.
---For compatibility with More Everything Colors.
---@param cls ISColorPicker
---@return ISColorPicker
function utils.getBaseColorPicker(cls)
    local mt = getmetatable(cls)
    if mt and mt.Type == 'ISColorPicker' then
        return mt
    end

    return cls
end

---Returns the player's current access level.
---If the connection is a coop host, returns `admin`.
---@return string
function utils.getEffectiveAccessLevel()
    if isCoopHost() then
        return 'admin'
    end

    local player = getSpecificPlayer(0)
    return player and player:getAccessLevel() or 'none'
end

---Gets the text within invisible character wrapping.
---Returns the text and the invisible character prefix & suffix.
---@param text string
---@return string internal
---@return string prefix
---@return string suffix
function utils.getInternalText(text)
    -- first non-invisible pos
    local start = 1
    local i = 1
    while i <= #text do
        local c = text:sub(i, i)
        if not utils.isInvisibleByte(c:byte()) then
            start = i
            break
        end

        i = i + 1
    end

    -- last non-invisible pos
    local finish = #text
    i = #text
    while i > 0 do
        local c = text:sub(i, i)
        if not utils.isInvisibleByte(c:byte()) then
            finish = i
            break
        end

        i = i - 1
    end

    local prefix = ''
    local suffix = ''
    if start > 1 then
        prefix = text:sub(1, start - 1)
    end

    if finish < #text then
        suffix = text:sub(finish + 1, #text)
    end

    return text:sub(start, finish), prefix, suffix
end

---Returns the non-empty lines of a string.
---If there are no non-empty lines, returns `nil`.
---@param text string
---@param maxLen integer?
---@return string[]?
function utils.getLines(text, maxLen)
    if not text then
        return
    end

    local lines = {}
    for line in text:gmatch('[^\n]+\n?') do
        line = utils.trim(line)
        if maxLen and #line > maxLen then
            lines[#lines + 1] = line:sub(1, maxLen)
        elseif #line > 0 then
            lines[#lines + 1] = line
        end
    end

    if #lines == 0 then
        return
    end

    return lines
end

---Gets a numeric access level given an access level string.
---@param access string
---@return integer
function utils.getNumericAccessLevel(access)
    if not access then
        return 1
    end

    return accessLevels[access:lower()] or 1
end

---Retrieves player information given an online ID.
---@param onlineID number
---@return omichat.utils.PlayerCacheItem?
function utils.getPlayerInfoByOnlineID(onlineID)
    local found = getPlayerByOnlineID(onlineID)
    if found then
        return updateCacheWithPlayer(found)
    end

    return utils._playerCacheByOnlineID[onlineID]
end

---Retrieves player information given a username.
---@param username string
---@return omichat.utils.PlayerCacheItem?
function utils.getPlayerInfoByUsername(username)
    local found
    if isClient() then
        found = getPlayerFromUsername(username)
    else
        local onlinePlayers = getOnlinePlayers()
        for i = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(i)
            if player:getUsername() == username then
                found = player
                break
            end
        end
    end

    if found then
        return updateCacheWithPlayer(found)
    end

    return utils._playerCacheByUsername[username]
end

---Gets a player given their username.
---@param username string
---@return IsoPlayer?
function utils.getPlayerByUsername(username)
    if isClient() then
        return getPlayerFromUsername(username)
    end

    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local player = onlinePlayers:get(i)
        if player:getUsername() == username then
            return player
        end
    end
end

---Gets the username of player 1.
---@return string?
function utils.getPlayerUsername()
    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if username then
        return username
    end
end

---Gets the position for the center of the screen given a UI width and height.
---@param width number
---@param height number
---@param playerIndex number?
---@return number
---@return number
function utils.getScreenCenter(width, height, playerIndex)
    playerIndex = playerIndex or 0
    local x = (getPlayerScreenWidth(playerIndex) - width) * 0.5
    local y = (getPlayerScreenHeight(playerIndex) - height) * 0.5

    return x, y
end

---Retrieves a texture name given a chat icon name.
---@param icon string
---@return string?
function utils.getTextureNameFromIcon(icon)
    if not loadedIcons then
        loadIcons()
    end

    return iconToTextureNameMap[icon]
end

---Gets the translation for a card name.
---@param card integer The card value, in [1, 13].
---@param suit integer The suit value, in [1, 4].
---@return string
function utils.getTranslatedCardName(card, suit)
    if not cards[card] or not suits[suit] then
        return ''
    end

    local cardTranslated = getText('UI_OmiChat_Card_' .. cards[card])
    local suitTranslated = getText('UI_OmiChat_CardSuit_' .. suits[suit])
    return getText('UI_OmiChat_CardName', cardTranslated, suitTranslated)
end

---Returns the translation of the given language.
---If no translation exists, returns the same string.
---@param language string
---@return string
function utils.getTranslatedLanguageName(language)
    if not language then
        return language
    end

    return getTextOrNull('UI_OmiChat_Language_' .. language:gsub('%s', '_')) or language
end

---Checks whether a given access level should have access based on provided flags.
---@param flags integer?
---@param accessLevel string
---@return boolean
function utils.hasAccess(flags, accessLevel)
    if not flags then
        return true
    end

    accessLevel = accessLevel:lower()

    if flags >= 32 then
        if accessLevel == 'admin' then
            return true
        end

        flags = flags - 32
    end

    if flags >= 16 then
        if accessLevel == 'moderator' then
            return true
        end

        flags = flags - 16
    end

    if flags >= 8 then
        if accessLevel == 'overseer' then
            return true
        end

        flags = flags - 8
    end

    if flags >= 4 then
        if accessLevel == 'gm' then
            return true
        end

        flags = flags - 4
    end

    if flags >= 2 then
        if accessLevel == 'observer' then
            return true
        end

        flags = flags - 2
    end

    return flags == 1
end

---Checks whether the player has any of the item types in the list.
---If the item list is empty, returns `true`.
---@param player IsoPlayer?
---@param list string[]
---@return boolean
function utils.hasAnyItemType(player, list)
    player = player or getSpecificPlayer(0)
    if not player then
        return false
    end

    local inv = player:getInventory()
    if not inv then
        return false
    end

    if #list == 0 then
        return true
    end

    for i = 1, #list do
        if inv:contains(list[i]) then
            return true
        end
    end

    return false
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Functions are referenced using `$func(...)` syntax.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed unknown? Seed value for random functions.
---@return string
function utils.interpolate(text, tokens, seed)
    return tostring(utils.interpolateRaw(text, tokens, seed))
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Functions are referenced using `$func(...)` syntax.
---This returns the raw result, which may or may not be a string.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed unknown? Seed value for random functions.
---@return unknown
function utils.interpolateRaw(text, tokens, seed)
    if text == '' then
        return ''
    end

    local interpolator = getCachedInterpolator(text)
    if not interpolator then
        interpolator = Interpolator:new({})
        interpolator:setPattern(text)

        setCachedInterpolator(text, interpolator)
    end

    -- always seed to avoid content changing on refresh
    interpolator:randomseed(seed)
    return interpolator:interpolateRaw(tokens)
end

---Checks whether a byte value is an invisible character used for encoding mod information.
---@param byte integer
---@return boolean
function utils.isInvisibleByte(byte)
    return (byte >= 128 and byte <= 159) or byte == 65535
end

---Checks a color table for validity.
---@param color omichat.ColorTable?
---@return boolean
function utils.isValidColor(color)
    if type(color) ~= 'table' then
        return false
    end

    local r = color.r
    local g = color.g
    local b = color.b

    if type(r) ~= 'number' or r < 0 or r > 255 then
        return false
    end

    if type(g) ~= 'number' or g < 0 or g > 255 then
        return false
    end

    if type(b) ~= 'number' or b < 0 or b > 255 then
        return false
    end

    return true
end

---Returns an iterator over an icon-to-texture name map.
---@return function
---@return table<string, string>
function utils.iterateIcons()
    if not loadedIcons then
        loadIcons()
    end

    return pairs(iconToTextureNameMap)
end

---Returns an iterator over the player cache.
---@return function
---@return table<string, omichat.utils.PlayerCacheItem>
function utils.iteratePlayerCache()
    return pairs(utils._playerCacheByUsername)
end

---Logs a non-fatal mod error.
---@param err string
---@param ... unknown
function utils.logError(err, ...)
    print('[OmiChat] ' .. string.format(err, ...))
end

---Parses arguments for a chat command.
---@param text string?
---@return string[] args
---@return boolean hasOpenQuote
function utils.parseCommandArgs(text)
    if not text then
        return {}, false
    end

    local i = 1
    local inQuote = false
    local current = {}
    local args = {}

    while i <= #text do
        local c = text:sub(i, i)

        if c == '\\' and text:sub(i + 1, i + 1) == '"' then
            current[#current + 1] = '"'
            i = i + 1
        elseif c == '"' then
            if #current > 0 then
                args[#args + 1] = concat(current)
                current = {}
            end

            inQuote = not inQuote
        elseif not inQuote and c == ' ' then
            if #current > 0 then
                args[#args + 1] = concat(current)
                current = {}
            end
        else
            current[#current + 1] = c
        end

        i = i + 1
    end

    if #current > 0 then
        args[#args + 1] = concat(current)
    end

    return args, inQuote
end

---Refreshes the cache with information from the currently online players.
---@return omichat.utils.PlayerCacheItem[]
function utils.refreshPlayerCache()
    local onlinePlayers = getOnlinePlayers()
    local items = {}
    for i = 0, onlinePlayers:size() - 1 do
        items[#items + 1] = buildPlayerCacheItem(onlinePlayers:get(i))
    end

    utils.resetPlayerCache(items)
    return items
end

---Replaces character entities with the characters that they represent.
---Numeric entities and named entities in ISO-8859-1 are supported.
---@param text string
---@return string
function utils.replaceEntities(text)
    text = text:gsub('(&#?x?[%a%d]+;)', function(entity)
        return utils.getEntityValue(entity) or entity
    end)

    return text
end

---Resets the player cache.
---@param items omichat.utils.PlayerCacheItem[]
function utils.resetPlayerCache(items)
    items = items or {}

    local byUsername = {}
    local byOnlineID = {}
    for i = 1, #items do
        local item = items[i]
        byUsername[item.username] = item
        byOnlineID[item.onlineID] = item
    end

    utils._playerCacheByUsername = byUsername
    utils._playerCacheByOnlineID = byOnlineID
end

---Converts a color string to a color. Returns `nil` on failure.
---@param text string A color string, in RGB or hex.
---@return omichat.ColorTable?
function utils.stringToColor(text)
    return utils.tryStringToColor(text).value
end

---Tests a predicate.
---@param pred string
---@param tokens table?
---@param seed unknown?
---@param default boolean?
---@return boolean
function utils.testPredicate(pred, tokens, seed, default)
    if pred == '' then
        return default or false
    end

    return utils.interpolate(pred, tokens or {}, seed) ~= ''
end

---Converts a color table to a color string for chat messages.
---@param color omichat.ColorTable
---@param pushFormat boolean? If true, PUSHRGB format will be used.
---@return string
function utils.toChatColor(color, pushFormat)
    if not utils.isValidColor(color) then
        return ''
    end

    return concat {
        ' <',
        pushFormat and 'PUSH' or '',
        'RGB:',
        format('%.7f', color.r / 255):gsub('00+$', '0'),
        ',',
        format('%.7f', color.g / 255):gsub('00+$', '0'),
        ',',
        format('%.7f', color.b / 255):gsub('00+$', '0'),
        '> ',
    }
end

---Converts a color table to a color string for overhead messages.
---@param color omichat.ColorTable
---@param bbCodeFormat boolean? If true, BBCode format will be used.
---@return string
function utils.toOverheadColor(color, bbCodeFormat)
    if not utils.isValidColor(color) then
        return ''
    end

    return concat {
        bbCodeFormat and '[col=' or '*',
        color.r,
        ',',
        color.g,
        ',',
        color.b,
        bbCodeFormat and ']' or '*',
    }
end

---Triggers a callback.
---@param info omichat.CallbackInfo? The callback info object.
---@param ... unknown Prefix arguments to include before the callback arguments.
---@return unknown?
function utils.triggerCallback(info, ...)
    if not info or not info.callback then
        return
    end

    local args = {}
    for i = 1, select('#', ...) do
        args[i] = select(i, ...)
    end

    local count = #args
    local cbArgs = info.args or {}
    for i = 1, cbArgs.n do
        count = count + 1
        args[count] = cbArgs[i]
    end

    return info.callback(info.target, unpack(args, 1, count or 1))
end

---Attempts to convert a color string to a color. Returns false and an error message on failure.
---@param text string A color string, in RGB or hex.
---@param minColor integer? Minimum color value [0, 255].
---@param maxColor integer? Maximum color value [0, 255].
---@return omi.Result<omichat.ColorTable>
function utils.tryStringToColor(text, minColor, maxColor)
    if not text then
        return { success = false, error = getText('UI_OmiChat_Error_InvalidColor') }
    end

    local r, g, b = readColor(text)
    if not r then
        return { success = false, error = getText('UI_OmiChat_Error_InvalidColor') }
    end

    maxColor = maxColor or 255
    if r > maxColor or g > maxColor or b > maxColor then
        return { success = false, error = getText('UI_OmiChat_Error_ValuesMax', tostring(maxColor)) }
    end

    minColor = minColor or 0
    if r < minColor or g < minColor or b < minColor then
        return { success = false, error = getText('UI_OmiChat_Error_ValuesMin', tostring(minColor)) }
    end

    return { success = true, value = { r = r, g = g, b = b } }
end

---Reverses the operation of escaping text for use in a rich text panel.
---@see ISRichTextPanel
---@see omichat.utils.escapeRichText
---@param text string
---@return string
function utils.unescapeRichText(text)
    return (text:gsub('&lt;', '<'):gsub('&gt;', '>'))
end

---Matches on text wrapped in invisible characters.
---@param text string The string to read.
---@param n integer A number in [1, 32].
---@param pattern string? The string pattern to use. Defaults to `(.-)`.
---@return ...
function utils.unwrapStringArgument(text, n, pattern)
    pattern = pattern or '(.-)'
    local c = utils.encodeInvisibleCharacter(n)
    return text:match(concat { c, pattern, c })
end

---Encodes `n` as an invisible character and wraps text with it.
---@param text string The string to wrap.
---@param n integer A number in [1, 32].
---@return string
function utils.wrapStringArgument(text, n)
    local c = utils.encodeInvisibleCharacter(n)
    return concat { c, text, c }
end


return utils
