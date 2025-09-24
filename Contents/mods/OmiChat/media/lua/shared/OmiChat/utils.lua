---Utility functions.

local lib = require 'OmiLibrary'
local Interpolator = require 'OmiChat/Component/Interpolator'

local min = math.min
local pow = math.pow
local floor = math.floor
local char = string.char
local concat = table.concat


---@class omichat.utils : omi.proxy
local utils = lib.proxy({ name = 'OmiChat' })
utils.lib = lib
utils.Interpolator = Interpolator


local clientAPI ---@type omichat.api.client?
local loadedIcons = false
local iconToTextureNameMap = {} ---@type table<string, string>
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
    encodedTag = utils.json.tryEncode(newTag)
    if not encodedTag then
        -- other data is bad, so just throw it out
        if type(value) == 'string' then
            value = string.format('%q', value)
        end

        encodedTag = string.format('{"%s":%s}', key, tostring(value))
    end

    message:setCustomTag(encodedTag)
end

---Checks whether a player has permission to execute a command for the given target username.
---@param player IsoPlayer
---@param target string
---@param minAccessLevel integer
---@param fromCommand boolean?
---@return boolean
function utils.canAccessTarget(player, target, minAccessLevel, fromCommand)
    if not target then
        return false
    end

    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if fromCommand and access < minAccessLevel then
        return false
    end

    if access == 1 and target ~= player:getUsername() then
        return false
    end

    return true
end


---Decodes an encoded character.
---@param text string
---@param index integer?
---@return integer
function utils.decodeInvisibleCharacter(text, index)
    text = text or ''
    if index then
        text = text:sub(index, index)
    end

    if #text == 0 then
        return 0
    end

    return text:byte() - 127
end

---Decodes an encoded invisible integer value.
---@param text string
---@return integer? value The decoded integer value.
---@return string? remaining The remaining text after the integer.
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

---Decodes a sequence of encoded invisible integers.
---@param text string
---@param amount integer
---@return integer[]? sequence The decoded integer sequence.
---@return string? remaining The remaining text after the sequence.
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

---Decodes an encoded invisible string.
---@param text any
---@return string? result The decoded string.
---@return string? remaining The remaining text after the string.
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
        utils.log.error('Attempted to encode negative value: %f', value)
        return ''
    end

    local originalValue = value
    local result = {}
    while value > 0 do
        if #result == 32 then
            utils.log.error('Value is too large to encode: %f', originalValue)
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

    tokens.error = ''
    tokens.errorID = ''

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

---Helper for requiring the client API in a shared context.
---Should only be used client-side.
---@return omichat.api.client
function utils.getAPI()
    if not clientAPI then
        clientAPI = require 'OmiChat/Shared' --[[@as omichat.api.client]]
    end

    return clientAPI
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

---Gets the name of a playing card in English.
---@param card integer The card value, in [1, 13].
---@param suit integer The suit value, in [1, 4].
---@return string
function utils.getCardName(card, suit)
    local cardName = cards[card]
    local suitName = suits[suit]
    if not cardName or not suitName then
        return ''
    end

    local article = 'a '
    if card == 8 then
        article = 'an '
    elseif card == 1 or card > 10 then
        article = 'the '
    end

    return article .. cardName .. ' of ' .. suitName
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

---Retrieves a texture name given a chat icon name.
---@param icon string
---@return string?
function utils.getTextureNameFromIcon(icon)
    if not loadedIcons then
        utils._loadIcons()
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
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed unknown? Seed value for random functions.
---@return string
function utils.interpolate(text, tokens, seed)
    return tostring(utils.interpolateRaw(text, tokens, seed))
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Injects the name into the the `DEFAULT` key of the `tokens` table.
---@param name string The name of the default to use for the interpolation.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed unknown? Seed value for random functions.
---@return string
function utils.interpolateNamed(name, text, tokens, seed)
    tokens.DEFAULT = name
    return utils.interpolate(text, tokens, seed)
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Returns the raw result, which may or may not be a string.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed unknown? Seed value for random functions.
---@return unknown
function utils.interpolateRaw(text, tokens, seed)
    if not text or text == '' then
        return ''
    end

    local interpolator = Interpolator.getOrCreate(text)
    interpolator:randomseed(seed) -- always seed to avoid content changing on refresh

    return interpolator:interpolateRaw(tokens)
end

---Checks whether a byte value is an invisible character used for encoding mod information.
---@param byte integer
---@return boolean
function utils.isInvisibleByte(byte)
    return (byte >= 128 and byte <= 159) or byte == 65535
end

---Returns an iterator over an icon-to-texture name map.
---@return function
---@return table<string, string>
function utils.iterateIcons()
    if not loadedIcons then
        utils._loadIcons()
    end

    return pairs(iconToTextureNameMap)
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

---Converts a color table to a color string for overhead messages.
---@param color omi.ColorTable
---@param bbCodeFormat boolean? If true, BBCode format will be used.
---@return string
function utils.toOverheadColor(color, bbCodeFormat)
    if not utils.color.isValid(color) then
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

---Matches on text wrapped in invisible characters.
---@param text string The string to read.
---@param n integer A number in [1, 32].
---@param pattern string? The string pattern to use. Defaults to `(.-)`.
---@return ...
function utils.unwrapStringArgument(text, n, pattern)
    pattern = pattern or '(.-)'
    local c = utils.encodeInvisibleCharacter(n)
    return text:match(c .. pattern .. c)
end

---Encodes `n` as an invisible character and wraps text with it.
---@param text string The string to wrap.
---@param n integer A number in [1, 32].
---@return string
function utils.wrapStringArgument(text, n)
    local c = utils.encodeInvisibleCharacter(n)
    return c .. text .. c
end


---Collects valid icons and builds a map of icon names to texture names.
---@private
function utils._loadIcons()
    local dest = HashMap.new()
    Texture.collectAllIcons(HashMap.new(), dest)
    iconToTextureNameMap = transformIntoKahluaTable(dest)
    iconToTextureNameMap.music = 'Icon_music_notes' -- special case for 'music'
    loadedIcons = true
end


return utils
