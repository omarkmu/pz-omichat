---@class omichat.Interpolator
local Interpolator = require 'OmiChat/Component/Interpolator'

---Format string function library.
local InterpolatorLibrary = {}

local OmiChat = require 'OmiChat/API/Shared'
local utils = OmiChat.utils
local Option = OmiChat.Option

local concat = table.concat
local baseLibraries = (require 'OmiChat/lib').interpolate.Interpolator.Libraries
local stringFunctions = baseLibraries.functions.string


local function internalWrap(f)
    return function(interpolator, s, ...)
        local text, prefix, suffix = utils.getInternalText(tostring(s or ''))
        local result = f(interpolator, text, ...)
        return concat({ prefix, result, suffix })
    end
end

---Returns a partial quote, representing a fragment of what a player character understood.
---@param interpolator omichat.Interpolator
---@param message string
---@return string?
local function getFragmentedMessage(interpolator, message)
    local parts = message:split('\\s+')
    if #parts <= 1 then
        return
    end

    local rolls = math.min(Option.InterpretationRolls, #parts - 1)
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

        local chance = Option.InterpretationChance
        if interpolator:random(100) < chance then
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

---Gets a string for the base unknown language string, without a message fragment.
---@param language string
---@param stream string?
---@param author string?
---@param dialogueTag string?
---@return string?
local function getBaseUnknownLanguageString(language, stream, author, dialogueTag)
    language = language and tostring(language) or ''
    if language == '' then
        return
    end

    stream = stream and tostring(stream) or 'say'
    author = author and tostring(author) or ''

    if stream == 'radio' and author == '' then
        return getText('UI_OmiChat_unknown_language_radio_no_author', language)
    end

    local isSigned = OmiChat.isRoleplayLanguageSigned(language)
    language = utils.getTranslatedLanguageName(language)

    -- narrative style
    dialogueTag = dialogueTag and tostring(dialogueTag) or ''
    if author ~= '' and dialogueTag ~= '' then
        local stringID = 'UI_OmiChat_unknown_language_narrative_' .. dialogueTag:gsub('%s', '_')

        local translated = getTextOrNull(stringID, author, language)
        if translated then
            return translated
        end

        stringID = 'UI_OmiChat_unknown_language_narrative_' .. (isSigned and 'signs' or 'says')
        return getText(stringID, author, language)
    end

    local stringID = { 'UI_OmiChat_unknown_language_' }
    if stream == 'whisper' or stream == 'shout' then
        stringID[#stringID + 1] = stream
    else
        stringID[#stringID + 1] = 'say'
    end

    stringID[#stringID + 1] = 's'
    if isSigned then
        stringID[#stringID + 1] = '_signed'
    end

    return getText(concat(stringID), language)
end

local library = {
    capitalize = internalWrap(stringFunctions.capitalize),
    punctuate = internalWrap(stringFunctions.punctuate),
    ---@param _ omichat.Interpolator
    ---@param ... unknown
    ---@return string, string, string
    internal = function(_, ...)
        local t = {}
        for i = 1, select('#', ...) do
            t[#t + 1] = tostring(select(i, ...) or '')
        end

        return utils.getInternalText(concat({ ... }))
    end,
    ---@param _ omichat.Interpolator
    ---@param s string?
    ---@param category omichat.ColorCategory
    ---@return string?
    colorquotes = function(_, s, category)
        ---@cast OmiChat omichat.api.client
        if not OmiChat.getColorOrDefault then
            return
        end

        s = tostring(s or '')
        if s == '' then
            return
        end

        category = tostring(category or 'say')
        local color = utils.toChatColor(OmiChat.getColorOrDefault(category), true)
        if color == '' then
            return s
        end

        s = s:gsub('%b""', function(quote)
            return concat {
                ' <SPACE>',
                color,
                quote,
                ' <POPRGB> <SPACE> ',
            }
        end)

        return s
    end,
    ---@param _ omichat.Interpolator
    ---@param s string
    ---@return string
    stripcolors = function(_, s)
        s = tostring(s or ''):gsub('<RGB:[%d,.]*>', '')
        return s
    end,
    ---@param _ omichat.Interpolator
    ---@param language string
    ---@return boolean
    issigned = function(_, language)
        return OmiChat.isRoleplayLanguageSigned(tostring(language or ''))
    end,
    escaperichtext = function(_, ...)
        local t = {}
        for i = 1, select('#', ...) do
            t[#t + 1] = tostring(select(i, ...) or '')
        end

        return utils.escapeRichText(concat({ ... }))
    end,
    ---@param interpolator omichat.Interpolator
    ---@param message string
    ---@return string?
    fragmented = function(interpolator, message)
        message = message and tostring(message) or ''
        return getFragmentedMessage(interpolator, message)
    end,
    ---@param interpolator omichat.Interpolator
    ---@param language string
    ---@param stream string?
    ---@param author string?
    ---@param dialogueTag string?
    ---@param message string?
    ---@param category string?
    ---@return string?
    getunknownlanguagestring = function(interpolator, language, stream, author, dialogueTag, message, category)
        local base = getBaseUnknownLanguageString(language, stream, author, dialogueTag)
        if not base then
            return
        end

        message = message and tostring(message) or ''
        local fragment = getFragmentedMessage(interpolator, message)
        if not fragment then
            return base
        end

        local parts = { base, ' <SPACE> ' }

        local pop
        if category ~= '' then
            ---@cast OmiChat omichat.api.client
            local color = OmiChat.getColorOrDefault and utils.toChatColor(OmiChat.getColorOrDefault('say'), true) or ''
            if color ~= '' then
                pop = true
                parts[#parts + 1] = color
            end
        end

        parts[#parts + 1] = fragment
        parts[#parts + 1] = pop and ' <POPRGB> ' or ''

        return concat(parts)
    end,
}


---Loads the library into the destination table.
---@param dest table
function InterpolatorLibrary:load(dest)
    for k, v in pairs(library) do
        dest[k] = v
    end
end


Interpolator.CustomLibrary = InterpolatorLibrary
InterpolatorLibrary.library = library
return InterpolatorLibrary
