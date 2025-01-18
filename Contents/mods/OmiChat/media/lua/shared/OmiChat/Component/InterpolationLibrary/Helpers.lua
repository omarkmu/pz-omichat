---Helper functions for interpolation functions.

local API = require 'OmiChat/API/Shared/Core'

local concat = table.concat
local utils = API.utils
local config = API.Configuration
local MultiMap = utils.MultiMap

local ASTERISK_CHAR = utils.encodeInvisibleCharacter(config.ID_ASTERISK_SIGNAL)


---@class omichat.InterpolationLibraryHelpers
local Helpers = {}


---Checks whether the language being sent is signed and returns an error ID if it is.
---The translation of the error assumes the stream is intended to be a "radio" channel for RP purposes.
---@param interpolator omichat.Interpolator
---@return string? errorID
function Helpers.checkSignedOverRadio(interpolator)
    local language = interpolator:token('languageRaw')
    if not language or not API.isRoleplayLanguageSigned(language) then
        return
    end

    local errorID = 'UI_OmiChat_Error_SignedRadio'
    local chatType = interpolator:token('chatType')
    if chatType == 'safehouse' then
        errorID = 'UI_OmiChat_Error_SignedSafehouseRadio'
    elseif chatType == 'faction' then
        errorID = 'UI_OmiChat_Error_SignedFactionRadio'
    end

    return errorID
end

---Colors actions in a string based on the streams tagged with `ActionColorTarget`.
---@param message string
---@param options omi.MultiMap?
---@param tags omi.SimpleSet?
---@return string
function Helpers.colorActions(message, options, tags)
    tags = tags or {}
    local color = Helpers.getColorTarget('ActionColorTarget', options, tags)
    if color == '' then
        return message
    end

    local narrativeStyle
    local keepAsterisk
    if options then
        narrativeStyle = options:get('narrativeStyle', tags.IsNarrativeStyle)
        keepAsterisk = options:get('keepAsterisk', tags.AutoColorActionsKeepAsterisk)
    else
        narrativeStyle = tags.IsNarrativeStyle
        keepAsterisk = tags.AutoColorActionsKeepAsterisk
    end

    local prefix = ''
    local suffix = ''
    local origMessage = message
    if narrativeStyle then
        local startQ = message:find('"')
        local endQ = message:match('.*"()') -- find last quote
        endQ = endQ and (endQ - 1)

        if startQ and endQ and startQ ~= endQ and endQ == #message then
            prefix = message:sub(1, startQ)
            suffix = message:sub(endQ)
            message = message:sub(startQ + 1, endQ - 1)
        end
    end

    message = message:gsub(ASTERISK_CHAR, '*')

    local pos = 1
    local result = {}
    local patt = '"%s*%*'
    local next, nextEnd = message:find(patt)

    local endsWithAction = false
    while next and nextEnd and next <= #message do
        local sub = message:sub(pos, next - 1)
        result[#result + 1] = sub
        result[#result + 1] = '"'

        result[#result + 1] = color
        result[#result + 1] = ' <SPACE> '

        if keepAsterisk then
            result[#result + 1] = '*'
        end

        pos = nextEnd + 1

        -- maintain action color until next quote character
        local nextQuote = message:find('"', pos)
        if not nextQuote then
            result[#result + 1] = message:sub(pos)
            result[#result + 1] = ' <SPACE> <POPRGB> '
            pos = #message + 1
            endsWithAction = true
            break
        end

        result[#result + 1] = message:sub(pos, nextQuote - 1)
        result[#result + 1] = ' <SPACE> <POPRGB> '

        pos = nextQuote
        next, nextEnd = message:find(patt, pos)
    end

    if #result == 0 then
        return origMessage
    end

    if pos <= #message then
        result[#result + 1] = message:sub(pos)
    end

    message = concat(result)

    if endsWithAction or utils.endsWith(message, '"') then
        suffix = suffix:sub(2)
    end

    return prefix .. message .. suffix
end

---Colors quotes in a string based on the streams tagged with `QuoteColorTarget`.
---@param message string
---@param options omi.MultiMap?
---@param tags omi.SimpleSet?
---@return string
function Helpers.colorQuotes(message, options, tags)
    local color = Helpers.getColorTarget('QuoteColorTarget', options, tags)
    if color == '' then
        return message
    end

    message = message:gsub('%b""', function(quote)
        if quote == '""' then
            return ''
        end

        return
            ' <SPACE>' ..
            color ..
            quote ..
            ' <POPRGB> <SPACE> '
    end)

    return message
end

---Gets a string for the base unknown language string, without a message fragment.
---@param tags omi.SimpleSet
---@param language string?
---@param author string?
---@param dialogueTag string?
---@return string?
function Helpers.getBaseUnknownLanguageString(tags, language, author, dialogueTag)
    language = tostring(language or '')
    if language == '' then
        return
    end

    author = tostring(author or '')
    if author ~= '' then
        author = author .. ' <SPACE> '
    else
        author = nil
    end

    if tags.IsRadioStream and not author then
        return getText('UI_OmiChat_UnknownLanguageRadioNoAuthor', language)
    end

    local isSigned = API.isRoleplayLanguageSigned(language)
    language = utils.getTranslatedLanguageName(language)

    -- narrative style
    dialogueTag = tostring(dialogueTag or '')
    if author and dialogueTag ~= '' then
        local stringID = 'UI_OmiChat_UnknownLanguageNarrative_' .. dialogueTag:gsub('%s', '_')

        local translated = getTextOrNull(stringID, author, language)
        if translated then
            return translated
        end

        stringID = 'UI_OmiChat_UnknownLanguageNarrative_' .. (isSigned and 'signs' or 'says')
        return getText(stringID, author, language)
    end

    local stringID = { 'UI_OmiChat_UnknownLanguage' }
    if isSigned then
        stringID[#stringID + 1] = 'Signed'
    end

    if tags.Whisper then
        stringID[#stringID + 1] = 'Whisper'
    elseif tags.Loud then
        stringID[#stringID + 1] = 'Shout'
    else
        stringID[#stringID + 1] = 'Say'
    end

    local text = getText(concat(stringID), language)
    if author then
        return author .. text
    end

    return text
end

---Gets a color to use given a target tag.
---@param colorTag string
---@param options omi.MultiMap?
---@param tags omi.SimpleSet?
---@return string
function Helpers.getColorTarget(colorTag, options, tags)
    ---@cast API unknown
    if not API.getFirstChatStreamWithTag then
        return ''
    end

    tags = tags or {}

    ---@cast API omichat.api.client
    local streams = API.getChatStreamsWithTag(colorTag)
    local targetTag = options and options:get('colorTargetTag')
    if not targetTag then
        if tags.Loud then
            targetTag = 'Loud'
        elseif tags.Quiet then
            targetTag = 'Quiet'
        elseif tags.Whisper then
            targetTag = 'Whisper'
        end
    end

    local colorStream
    if targetTag then
        for i = 1, #streams do
            local stream = streams[i]
            if stream:hasTag(targetTag) then
                colorStream = stream
                break
            end
        end
    end

    colorStream = colorStream or streams[1]
    if not colorStream then
        return ''
    end

    return utils.color.toRichText(API.getColorOrDefault(colorStream:getName()), true)
    ---@cast API omichat.api.shared
end

---Returns a partial quote representing a fragment of what a player character understood.
---@param interpolator omichat.Interpolator
---@param message string
---@return string?
function Helpers.getFragmentedMessage(interpolator, message)
    local parts = message:split('\\s+')
    if #parts <= 1 then
        return
    end

    local rolls = math.min(config.Language.InterpretationRolls, #parts - 1)
    if rolls == 0 then
        return
    end

    -- populate and shuffle
    local indices = {}
    for i = 1, #parts do
        indices[#indices + 1] = i
    end

    for i = #indices, 2, -1 do
        local j = interpolator:random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    -- select indices to include
    local selected = {}
    for _ = 1, rolls do
        if #indices == 0 then
            break
        end

        if interpolator:random(100) < config.Language.InterpretationChance then
            local choice = indices[#indices]
            indices[#indices] = nil
            selected[#selected + 1] = choice
        end
    end

    if #selected == 0 then
        return
    end

    table.sort(selected)

    -- build fragmented message
    local last = 0
    local built = {}
    for i = 1, #selected do
        local idx = selected[i]
        if idx > last + 1 then
            built[#built + 1] = '...'
        end

        built[#built + 1] = parts[idx]
        last = idx
    end

    if last < #parts then
        built[#built + 1] = '...'
    end

    return '"' .. concat(built, ' ') .. '"'
end

---Gets the text to use for an "over radio" indicator based on the chat type.
---@param chatType omichat.ChatTypeString?
---@return string
function Helpers.getOverRadioText(chatType)
    if chatType == 'faction' then
        return getText('UI_OmiChat_FactionRadio')
    elseif chatType == 'safehouse' then
        return getText('UI_OmiChat_SafehouseRadio')
    end

    return getText('UI_OmiChat_OverRadio')
end

---Gets a volume indicator based on tags.
---@param options omi.MultiMap
---@param tags omi.SimpleSet
---@param preset string
---@return string?
function Helpers.getVolumeIndicator(options, tags, preset)
    local indicator
    if not tags.IsSneakCallout and (tags.Loud or tags.IsCallout) then
        indicator = options:getString('loudIndicator', preset == 'Buffy' and 'Long' or 'Loud')
    elseif tags.Quiet or tags.IsSneakCallout then
        indicator = options:getString('quietIndicator', 'Low')
    elseif tags.Whisper then
        indicator = options:getString('whisperIndicator', 'Whisper')
    end

    if indicator then
        return '[' .. indicator .. ']'
    end
end

---Wraps a function so that it gets the internal value before being applied, then reapplies the invisible characters.
---@param f function
---@return fun(interpolator: omi.Interpolator, ...: unknown): string
function Helpers.internalWrap(f)
    return function(interpolator, s, ...)
        local text, prefix, suffix = utils.getInternalText(tostring(s or ''))
        local result = f(interpolator, text, ...)
        return prefix .. tostring(result) .. suffix
    end
end

---Gets the value of an option, or a token as a fallback.
---If neither are defined, this will return the empty string.
---@param interpolator omichat.Interpolator
---@param options omi.MultiMap
---@param key string
---@param token string?
---@return string
function Helpers.optionOrToken(interpolator, options, key, token)
    return options:getString(key, interpolator:tokenString(token or key))
end

---Reads at-function options.
---@param args unknown?
---@return omi.MultiMap options
function Helpers.readOptions(args)
    if type(args) == 'table' and utils.isinstance(args, MultiMap) then
        ---@cast args omi.MultiMap
        return args:toOptions()
    else
        return MultiMap:new()
    end
end

---Reads the preset to use from the options.
---@param options omi.MultiMap
---@return omichat.PresetString
function Helpers.readPreset(options)
    local preset
    local presetArg = options:getString('preset'):lower()
    if presetArg == 'vanilla' then
        preset = 'Vanilla'
    elseif presetArg == 'buffy' then
        preset = 'Buffy'
    elseif presetArg == 'default' then
        preset = 'Default'
    else
        preset = config.General.Preset
    end

    return preset
end

---Reads tags from an interpolator.
---@param interpolator omichat.Interpolator
---@return omi.SimpleSet tags
function Helpers.readTags(interpolator)
    local tags
    local originalTags

    if interpolator:token('chatType') == 'radio' then
        tags = interpolator:token('tags')
        originalTags = interpolator:token('originalTags')
    else
        tags = interpolator:token('tags')
    end

    local tagSet = {}
    if utils.isinstance(tags, MultiMap) then
        ---@cast tags omi.MultiMap
        tagSet = tags:toValueSet()
    end

    if utils.isinstance(originalTags, MultiMap) then
        ---@cast originalTags omi.MultiMap
        utils.extend(tagSet, originalTags:toValueSet())
    end

    return tagSet
end

---Replaces asterisks in a message intended for coloring actions with invisible characters.
---This prevents them from displaying overhead while still allowing the action coloring to handle them properly.
---@param message string
---@return string
function Helpers.replaceColorActionsAsterisks(message)
    local pos = 1
    local result = {}
    local patt = '("%s*)%*'
    local next, nextEnd, prefix = message:find(patt)

    while next and nextEnd and next <= #message do
        result[#result + 1] = message:sub(pos, next - 1)
        result[#result + 1] = prefix
        result[#result + 1] = ASTERISK_CHAR

        pos = nextEnd + 1

        local nextQuote = message:find('"', pos)
        if not nextQuote then
            result[#result + 1] = message:sub(pos)
            pos = #message + 1
            break
        end

        result[#result + 1] = message:sub(pos, nextQuote - 1)

        pos = nextQuote
        next, nextEnd, prefix = message:find(patt, pos)
    end

    if #result == 0 then
        return message
    end

    if pos <= #message then
        result[#result + 1] = message:sub(pos)
    end

    return concat(result)
end

---Stringifies inputs into a single string.
---@param ... unknown
---@return string
function Helpers.stringify(...)
    return Helpers.stringifySep('', ...)
end

---Stringifies inputs into a single delimited string.
---@param sep string
---@param ... unknown
---@return string
function Helpers.stringifySep(sep, ...)
    local t = {}
    for i = 1, select('#', ...) do
        t[#t + 1] = tostring(select(i, ...) or '')
    end

    return concat(t, sep)
end

---Checks whether a message with automatically colored actions will end with an action when formatted.
---@param message string
---@return boolean
function Helpers.willEndWithAction(message)
    message = message:gsub(ASTERISK_CHAR, '*')

    local pos = 1
    local patt = '"%s*%*'
    local next, nextEnd = message:find(patt)

    while next and nextEnd and next <= #message do
        pos = nextEnd + 1

        local nextQuote = message:find('"', pos)
        if not nextQuote then
            return true
        end

        pos = nextQuote
        next, nextEnd = message:find(patt, pos)
    end

    return false
end



return Helpers
