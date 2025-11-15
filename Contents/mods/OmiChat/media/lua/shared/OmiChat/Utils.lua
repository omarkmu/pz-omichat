---Utility functions.
---@namespace omichat

local lib = require 'OmiLibrary'
local l10n = lib.l10n

local char = string.char
local concat = table.concat
local getTextVanilla = getText
local transformIntoKahluaTable = transformIntoKahluaTable

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

---Lowercase card suit names, for translations.
---@private
utils._suits = {
    'clubs',
    'diamonds',
    'hearts',
    'spades',
}

---Lowercase playing card names, for translations.
---@private
utils._cards = {
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


local API_C ---@type api.client?
local loadedIcons = false
local iconToBBCodeNameMap = {} ---@type table<string, string>
local iconToTextureNameMap = {} ---@type table<string, string>

local accessLevels = {
    admin = 32,
    moderator = 16,
    overseer = 8,
    gm = 4,
    observer = 2,
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
        result = utils.getTextOrNull(errorID) or getTextVanilla(errorID)
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

---Gets a string from a message ID.
---@param id string The ID of the message to get.
---If a bundle is not included, it defaults to `omichat`.
---@param attr string The name of the attribute to get.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string value
function utils.getAttr(id, attr, args)
    return l10n.getAttr(id, attr, args, 'omichat')
end

---Gets a string from a message ID, or `nil` if no such message exists.
---@param id string The ID of the message to get.
---If a bundle is not included, it defaults to `omichat`.
---@param attr string The name of the attribute to get.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string? value
function utils.getAttrOrNull(id, attr, args)
    return l10n.getAttrOrNull(id, attr, args, 'omichat')
end

---Retrieves a BBCode icon name given a chat icon alias.
---@param icon string A chat icon alias.
---@return string? iconName The name of the icon for BBCode, or `nil` if not found.
function utils.getBBCodeNameFromIcon(icon)
    if not loadedIcons then
        utils._loadIcons()
    end

    return iconToBBCodeNameMap[icon]
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

---Gets a string from a message ID.
---@param id string The ID of the message to get.
---If a bundle is not included, it defaults to `omichat`.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string value
function utils.getText(id, args)
    return l10n.getText(id, args, 'omichat')
end

---Gets a string from a message ID, or `nil` if no such message exists.
---@param id string The ID of the message to get.
---If a bundle is not included, it defaults to `omichat`.
---@param args table<string, omi.l10n.FluentVariable?>? Arguments to pass for message resolution.
---@return string? value
function utils.getTextOrNull(id, args)
    return l10n.getTextOrNull(id, args, 'omichat')
end

---Retrieves a texture name given a chat icon alias.
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
    if not utils._cards[card] or not utils._suits[suit] then
        return ''
    end

    local cardTranslated = utils.getText('card-' .. utils._cards[card])
    local suitTranslated = utils.getText('card-suit-' .. utils._suits[suit])
    return utils.getText('card-name', { card = cardTranslated, suit = suitTranslated })
end

---Returns the translation of the given language name.
---@param language string The untranslated language name.
---@return string translated The translated language name, or `language` if no translation was found.
function utils.getTranslatedLanguageName(language)
    local id = 'language-' .. language:lower():gsub('%s', '-')
    return utils.getTextOrNull(id) or language
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
---@param format string The format string.
---@param tokens table A table of format substitution strings.
---@param seed any? Seed value for random functions.
---@return string interpolated
function utils.interpolate(format, tokens, seed)
    return tostring(utils.interpolateRaw(format, tokens, seed))
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Injects the name into the the `DEFAULT` key of the `tokens` table.
---@param name string The name of the default to use for the interpolation.
---@param format string The format string.
---@param tokens table A table of format substitution strings.
---@param seed any? Seed value for random functions.
---@return string interpolated
function utils.interpolateNamed(name, format, tokens, seed)
    local oldDefault = tokens.DEFAULT
    tokens.DEFAULT = name

    local result = tostring(utils.interpolateRaw(format, tokens, seed))

    tokens.DEFAULT = oldDefault
    return result
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Leaves character entities as-is.
---@param format string The format string.
---@param tokens table A table of format substitution strings.
---@param seed any? Seed value for random functions.
---@return string interpolated
function utils.interpolateNoEntities(format, tokens, seed)
    return tostring(utils.interpolateRaw(format, tokens, seed, true))
end

---Interpolates substitution tokens into a string with format strings using `$var` format.
---Returns the raw result, which may or may not be a string.
---@param format string The format string.
---@param tokens table A table of format substitution strings.
---@param seed any? Seed value for random functions.
---@param noEntities boolean? If given, character entities will be disallowed.
---@return any interpolated
function utils.interpolateRaw(format, tokens, seed, noEntities)
    if not format or format == '' then
        return ''
    end

    local interpolator = noEntities and utils._noEntityInterpolator or utils._interpolator
    interpolator:randomseed(seed) -- always seed to avoid content changing on refresh

    return interpolator:interpolateRaw(format, tokens)
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

---Resolves the value of a translation table.
---@generic T
---@param rec omi.TranslateTable<T> The translation table to resolve.
---@return string? result
function utils.resolveTranslateTable(rec)
    return l10n.resolveTranslateTable(rec, 'omichat')
end


---Collects valid icons and builds a map of icon names to texture names.
---@private
function utils._loadIcons()
    local dest = HashMap.new()
    local fullDest = HashMap.new()
    Texture.collectAllIcons(dest, fullDest)

    iconToBBCodeNameMap = transformIntoKahluaTable(dest)
    iconToTextureNameMap = transformIntoKahluaTable(fullDest)

    -- special case for 'music'
    iconToBBCodeNameMap.music = 'music'
    iconToTextureNameMap.music = 'Icon_music_notes'
    loadedIcons = true
end


return utils
