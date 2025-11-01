---Utility functions.
---@namespace omichat

local lib = require 'OmiLibrary'

local min = math.min
local pow = math.pow
local floor = math.floor
local char = string.char
local concat = table.concat

local INVISIBLE_PATTERN = '['
    .. char(128) .. '-' .. char(159) .. ']?'
    .. char(65535) .. '?'


---@class utils : omi.proxy
local utils = lib.proxy('OmiChat')

---The interpolator used for basic interpolation.
---@private
utils._interpolator = lib.interpolate.Interpolator:new({
    logger = utils.log,
})

---The interpolator used for interpolation without character entities.
---@private
utils._noEntityInterpolator = lib.interpolate.Interpolator:new({
    logger = utils.log,
    allowCharacterEntities = false,
})


local API_C ---@type api.client?

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


---Checks whether a player has permission to execute a command.
---@param player IsoPlayer The player to check for permissions.
---@param target string The username of the target player.
---@param minAccessLevel integer The minimum command access level.
---@param fromCommand boolean? Flag for whether the request came from a command.
---@return boolean canAccess
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

---Replaces invisible text with indicators for debugging.
---@param text string The text to replace invisible characters in.
---@return string debugText
function utils.debugText(text)
    text = text:gsub(INVISIBLE_PATTERN, function(chars)
        local result = ''
        for i = 1, #chars do
            local c = chars:sub(i, i):byte()
            if c == 65535 then
                c = 0
            else
                c = c - 127
            end

            result = result .. '\\' .. c
        end

        return result
    end)

    return text
end

---Decodes an encoded character.
---@param text string The text to decode an invisible character from.
---@param index integer? The index of the invisible character in the text. Defaults to `1`.
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
---@param text string The text to decode an integer value from.
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

        value = value + digit * pow(32, i - 2) --[[@as integer]]
    end

    return value, text:sub(endPos + 1)
end

---Decodes a sequence of encoded invisible integers.
---@param text string The text to encode an integer sequence from.
---@param amount integer The expected number of encoded integers.
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

---Encodes an integer value as a character.
---@param value integer The integer to encode, in [1, 32].
---@return string encoded
function utils.encodeInvisibleCharacter(value)
    return char(value + 127)
end

---Encodes a non-negative integer value as an invisible representation of its digits.
---@param value integer The integer value to encode.
---@return string encoded
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

---Gets an error from the error tokens, if one is set, and unsets the tokens.
---@param tokens table The table of tokens that an error should be extracted from.
---@return string? error The error string, or `nil` if none was found.
function utils.extractError(tokens)
    local result
    local error = tostring(tokens.error or '')
    local errorID = tostring(tokens.errorID or '')

    if error ~= '' then
        result = error
    elseif errorID ~= '' then
        result = getText(errorID)
    end

    tokens.error = ''
    tokens.errorID = ''

    return result
end

---Helper for requiring the client API in a shared context.
---Should only be used client-side.
---@return api.client API
function utils.getAPI()
    if not API_C then
        API_C = (require 'OmiChat/Shared') --[[@as api.client]]
    end

    return API_C
end

---Gets the name of a playing card in English.
---@param card integer The card value, in [1, 13].
---@param suit integer The suit value, in [1, 4].
---@return string name
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
---@return string accessLevel
function utils.getEffectiveAccessLevel()
    if isCoopHost() then
        return 'admin'
    end

    local player = getSpecificPlayer(0)
    return player and player:getAccessLevel() or 'none'
end

---Gets the text within invisible character wrapping.
---Returns the text and the invisible character prefix & suffix.
---@param text string The text to extract invisible characters from.
---@return string internal The internal text.
---@return string prefix The invisible characters from the start of the text.
---@return string suffix The invisible characters from the end of the text.
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
---@param text string The text to get lines from.
---@param maxLen integer? The maximum length of each line. Truncates lines if given.
---@return string[]? lines
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
---@param access string The access level.
---@return integer accessLevel The numeric access level associated with the access level.
function utils.getNumericAccessLevel(access)
    if not access then
        return 1
    end

    return accessLevels[access:lower()] or 1
end

---Retrieves a texture name given a chat icon name.
---@param icon string A chat icon alias.
---@return string? textureName The name of a texture, or `nil` if not found.
function utils.getTextureNameFromIcon(icon)
    if not loadedIcons then
        utils._loadIcons()
    end

    return iconToTextureNameMap[icon]
end

---Gets the translation for a card name.
---@param card integer The card value, in [1, 13].
---@param suit integer The suit value, in [1, 4].
---@return string cardName The card name, translated into the local player's language.
function utils.getTranslatedCardName(card, suit)
    if not cards[card] or not suits[suit] then
        return ''
    end

    local cardTranslated = getText('UI_OmiChat_Card_' .. cards[card])
    local suitTranslated = getText('UI_OmiChat_CardSuit_' .. suits[suit])
    return getText('UI_OmiChat_CardName', cardTranslated, suitTranslated)
end

---Returns the translation of the given language name.
---@param language string The untranslated language name.
---@return string translated The translated language name, or `language` if no translation was found.
function utils.getTranslatedLanguageName(language)
    return getTextOrNull('UI_OmiChat_Language_' .. language:gsub('%s', '_')) or language
end

---Checks whether a given access level should have access based on provided flags.
---@param flags integer? Bit flags for the access level.
---@param accessLevel string The access level string.
---@return boolean hasAccess
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
---@param player IsoPlayer? The player to check. If not given, player 1 is used.
---@param list string[] The list of valid items. If this is empty, the result will be `true`.
---@return boolean hasItem
function utils.hasAnyItemType(player, list)
    if #list == 0 then
        return true
    end

    player = player or getSpecificPlayer(0)
    if not player then
        return false
    end

    local inv = player:getInventory()
    if not inv then
        return false
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
---@param seed any? Seed value for random functions.
---@return string interpolated
function utils.interpolate(text, tokens, seed)
    return tostring(utils.interpolateRaw(text, tokens, seed))
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Injects the name into the the `DEFAULT` key of the `tokens` table.
---@param name string The name of the default to use for the interpolation.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed any? Seed value for random functions.
---@return string interpolated
function utils.interpolateNamed(name, text, tokens, seed)
    tokens.DEFAULT = name
    return utils.interpolate(text, tokens, seed)
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Leaves character entities as-is.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed any? Seed value for random functions.
---@return string interpolated
function utils.interpolateNoEntities(text, tokens, seed)
    return tostring(utils.interpolateRaw(text, tokens, seed, true))
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Returns the raw result, which may or may not be a string.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param seed any? Seed value for random functions.
---@param noEntities boolean? If given, character entities will be disallowed.
---@return any interpolated
function utils.interpolateRaw(text, tokens, seed, noEntities)
    if not text or text == '' then
        return ''
    end

    local interpolator = noEntities and utils._noEntityInterpolator or utils._interpolator
    interpolator:randomseed(seed) -- always seed to avoid content changing on refresh

    return interpolator:interpolateRaw(text, tokens)
end

---Checks whether a byte value is an invisible character used for encoding mod information.
---@param byte integer The byte to check.
---@return boolean isInvisible
function utils.isInvisibleByte(byte)
    return (byte >= 128 and byte <= 159) or byte == 65535
end

---Returns an iterator over an icon-to-texture name map.
---@return fun(): string?, string? iterator
function utils.iterateIcons()
    if not loadedIcons then
        utils._loadIcons()
    end

    return pairs(iconToTextureNameMap)
end

---Parses arguments for a chat command.
---@param text string? The text to parse arguments from. If this is `nil`, and empty table is returned.
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

---Removes invisible signal characters from text.
---@param text string The text to remove invisible characters from.
---@return string modified The `text`, without invisible characters.
function utils.removeInvisible(text)
    return (text:gsub(INVISIBLE_PATTERN, ''))
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
---@return string wrapped
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
