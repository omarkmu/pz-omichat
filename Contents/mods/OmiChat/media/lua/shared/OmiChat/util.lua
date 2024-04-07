local lib = require 'OmiChat/lib'
local Interpolator = require 'OmiChat/Component/Interpolator'

local pow = math.pow
local floor = math.floor
local min = math.min
local format = string.format
local concat = table.concat
local getTimestampMs = getTimestampMs


---Utility functions.
---@class omichat.utils : omi.utils
---@field private _interpolatorCache table<string, omichat.utils.InterpolatorCacheItem>
local utils = lib.utils.copy(lib.utils)
utils.Interpolator = Interpolator
utils._interpolatorCache = {}

---@class omichat.utils.InterpolatorCacheItem
---@field interpolator omichat.Interpolator
---@field lastAccess number

---@class omichat.utils.InternalSearchContext : omichat.SearchContext
---@field search string
---@field startsWith omichat.utils.InternalSearchResult[]
---@field contains omichat.utils.InternalSearchResult[]
---@field args table

---@class omichat.utils.InternalSearchResult : omichat.SearchResult
---@field value unknown


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
    'clubs',
    'diamonds',
    'hearts',
    'spades',
}
local cards = {
    'ace',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'jack',
    'queen',
    'king',
}

---@type Perk[]
local perkList = {}; do
    local perkArrayList = PerkFactory.PerkList
    for i = 0, perkArrayList:size() - 1 do
        local perk = perkArrayList:get(i) ---@cast perk Perk
        if perk:getParent() ~= Perks.None then
            perkList[#perkList + 1] = perk
        end
    end

    table.sort(perkList, function(a, b) return not string.sort(a:getName(), b:getName()) end)
end

---@type table<string, string>
local iconToTextureNameMap = {}
local loadedIcons = false


---Creates internal context given search context.
---@param ctx omichat.SearchContext | string
---@return omichat.utils.InternalSearchContext
local function buildInternalSearchContext(ctx)
    if type(ctx) == 'string' then
        ctx = { search = ctx }
    end

    ---@type omichat.utils.InternalSearchContext
    return {
        search = utils.trim(ctx.search:lower()),
        display = ctx.display,
        filter = ctx.filter,
        max = ctx.max,
        args = ctx.args or {},
        searchDisplay = ctx.searchDisplay,
        terminateForExact = ctx.terminateForExact,
        startsWith = {},
        contains = {},
        collectResults = true,
    }
end

---Display function for perks.
---@param perk Perk
---@return string
local function displayPerk(perk)
    return perk:getName() .. ' (' .. perk:getParent():getName() .. ')'
end

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

---Internal string search.
---@param ctx omichat.utils.InternalSearchContext Search context.
---@param primary string Primary string to search.
---@param value unknown? Object to use as the result value instead of `primary`.
---@param ... string Secondary strings to search.
---@return omichat.utils.InternalSearchResult?
local function searchInternal(ctx, primary, value, ...)
    if ctx.filter and not ctx.filter(primary, ctx.args) then
        return
    end

    local search = ctx.search
    local strings = { primary, ... }
    local compare = {}
    local displayStrings = {}

    if value == nil then
        value = primary
    end

    ---@type omichat.utils.InternalSearchResult?
    local result

    -- check for exact match
    if #search > 0 then
        for i = 1, #strings do
            local str = strings[i]
            local lower = str:lower()
            local match = lower == search

            local display
            if not match and ctx.searchDisplay then
                display = ctx.display and ctx.display(value) or nil
                match = display ~= nil and display:lower() == search
            end

            if match then
                result = {
                    value = value,
                    display = displayStrings[i] or (ctx.display and ctx.display(value) or nil),
                    exact = true,
                }

                ctx.startsWith[#ctx.startsWith + 1] = result
                return result
            end

            compare[i] = lower
            displayStrings[i] = display
        end
    end

    if ctx.max and #ctx.startsWith + #ctx.contains >= ctx.max then
        -- exceeded maximum
        return
    end

    if #search == 0 then
        -- no search → include all
        result = {
            value = value,
            display = ctx.display and ctx.display(value) or nil,
            exact = false,
        }

        ctx.startsWith[#ctx.startsWith + 1] = result
        return result
    end

    for i = 1, #strings do
        local display
        local match = utils.startsWith(compare[i], search)
        if not match and ctx.searchDisplay then
            display = displayStrings[i] or (ctx.display and ctx.display(value) or nil)
            if display and utils.startsWith(display:lower(), search) then
                match = true
            end
        end

        if match then
            result = {
                value = value,
                display = display or displayStrings[i] or (ctx.display and ctx.display(value) or nil),
                exact = false,
            }

            ctx.startsWith[#ctx.startsWith + 1] = result
            return result
        end
    end

    for i = 1, #strings do
        local display
        local match = utils.contains(compare[i], search)
        if not match and ctx.searchDisplay then
            display = displayStrings[i] or (ctx.display and ctx.display(value) or nil)
            if display and utils.contains(display:lower(), search) then
                match = true
            end
        end

        if match then
            result = {
                value = value,
                display = display or displayStrings[i] or (ctx.display and ctx.display(value) or nil),
                exact = false,
            }

            ctx.contains[#ctx.contains + 1] = result
            return result
        end
    end
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
---@return integer?
function utils.decodeInvisibleInt(text)
    local len = utils.decodeInvisibleCharacter(text)
    if len < 1 or len > 32 then
        return
    end

    local value = 0
    for i = 2, min(#text, len + 1) do
        local digit = utils.decodeInvisibleCharacter(text:sub(i, i)) - 1
        if digit < 0 or digit > 31 then
            return
        end

        value = value + digit * pow(32, i - 2)
    end

    return value
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
        utils.logError('Attempted to encode negative value: ' .. value)
        return ''
    end

    local originalValue = value
    local result = {}
    while value > 0 do
        if #result == 32 then
            utils.logError('Value is too large to encode: ' .. originalValue)
            return ''
        end

        result[#result + 1] = utils.encodeInvisibleCharacter((value % 32) + 1)
        value = floor(value / 32)
    end

    if #result == 0 then
        result[#result + 1] = utils.encodeInvisibleCharacter(1)
    end

    local len = utils.encodeInvisibleCharacter(#result)
    return len .. concat(result)
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

---Gets a numeric access level given an access level string.
---@param access string
---@return integer
function utils.getNumericAccessLevel(access)
    if not access then
        return 1
    end

    return accessLevels[access:lower()] or 1
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

    local cardTranslated = getText('UI_OmiChat_card_' .. cards[card])
    local suitTranslated = getText('UI_OmiChat_suit_' .. suits[suit])
    return getText('UI_OmiChat_card_name', cardTranslated, suitTranslated)
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

---Collects online usernames based on a search string.
---If there's an exact match, no results are returned.
---@param ctxOrSearch omichat.SearchContext | string Context for the search.
---@param includeSelf boolean? If true, player 1's username will be included in the search.
---@return omichat.SearchResults
function utils.searchOnlineUsernames(ctxOrSearch, includeSelf)
    local ctx = buildInternalSearchContext(ctxOrSearch)
    local onlinePlayers = getOnlinePlayers()
    local player = getSpecificPlayer(0)
    local ownUsername = player and player:getUsername()

    local exact
    for i = 0, onlinePlayers:size() - 1 do
        local onlinePlayer = onlinePlayers:get(i)
        local user = onlinePlayer and onlinePlayer:getUsername()
        if user and (includeSelf or user ~= ownUsername) then
            local result = searchInternal(ctx, user)
            if result and result.exact then
                exact = result
                if ctx.terminateForExact then
                    break
                end
            end
        end
    end

    ---@type omichat.SearchResults
    return {
        exact = exact,
        results = utils.extend(ctx.startsWith, ctx.contains),
    }
end

---Collects perk IDs based on a search string.
---@param ctxOrSearch omichat.SearchContext | string
---@return omichat.SearchResults
function utils.searchPerks(ctxOrSearch)
    local ctx = buildInternalSearchContext(ctxOrSearch)
    ctx.display = ctx.display or displayPerk

    for i = 1, #perkList do
        local perk = perkList[i]
        local name = perk:getName():lower()
        local id = perk:getId():lower()
        local result = searchInternal(ctx, id, perk, name)
        if result and result.exact and ctx.terminateForExact then
            break
        end
    end

    local exact
    local results = utils.extend(ctx.startsWith, ctx.contains)
    for i = 1, #results do
        local result = results[i]
        local perk = result.value
        result.value = perk:getId()

        if result.exact then
            exact = result
        end
    end

    ---@type omichat.SearchResults
    return {
        exact = exact,
        results = results,
    }
end

---Collects results from a list of strings based on a search string.
---If there's an exact match, no results are returned.
---@param ctxOrSearch omichat.SearchContext | string Context for the search.
---@param list string[] The list of strings to search.
---@return omichat.SearchResults
function utils.searchStrings(ctxOrSearch, list)
    local ctx = buildInternalSearchContext(ctxOrSearch)

    local exact
    for i = 1, #list do
        local result = searchInternal(ctx, list[i])
        if result and result.exact then
            exact = result
            if ctx.terminateForExact then
                break
            end
        end
    end

    ---@type omichat.SearchResults
    return {
        exact = exact,
        results = utils.extend(ctx.startsWith, ctx.contains),
    }
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

---Attempts to convert a color string to a color. Returns false and an error message on failure.
---@param text string A color string, in RGB or hex.
---@param minColor integer? Minimum color value [0, 255].
---@param maxColor integer? Maximum color value [0, 255].
---@return omi.Result<omichat.ColorTable>
function utils.tryStringToColor(text, minColor, maxColor)
    if not text then
        return { success = false, error = getText('UI_OmiChat_error_invalid_color') }
    end

    local r, g, b = readColor(text)
    if not r then
        return { success = false, error = getText('UI_OmiChat_error_invalid_color') }
    end

    maxColor = maxColor or 255
    if r > maxColor or g > maxColor or b > maxColor then
        return { success = false, error = getText('UI_OmiChat_error_color_max', tostring(maxColor)) }
    end

    minColor = minColor or 0
    if r < minColor or g < minColor or b < minColor then
        return { success = false, error = getText('UI_OmiChat_error_color_min', tostring(minColor)) }
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
