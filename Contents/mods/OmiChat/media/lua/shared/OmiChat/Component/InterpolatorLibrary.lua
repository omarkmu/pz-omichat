---@class omichat.Interpolator
local Interpolator = require 'OmiChat/Component/Interpolator'

---Format string function library.
local InterpolatorLibrary = {}

local OmiChat = require 'OmiChat/API/Shared'
local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'

local concat = table.concat
local baseLibraries = lib.interpolate.Interpolator.Libraries
local stringFunctions = baseLibraries.functions.string


local function internalWrap(f)
    return function(interpolator, s, ...)
        local text, prefix, suffix = utils.getInternalText(tostring(s or ''))
        local result = f(interpolator, text, ...)
        return concat({ prefix, result, suffix })
    end
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
        language = tostring(language or '')
        return OmiChat.isRoleplayLanguageSigned(tostring(language or ''))
    end,
    escaperichtext = function(_, ...)
        local t = {}
        for i = 1, select('#', ...) do
            t[#t + 1] = tostring(select(i, ...) or '')
        end

        return utils.escapeRichText(concat({ ... }))
    end,
    ---@param _ omichat.Interpolator
    ---@param language string
    ---@param stream string?
    ---@param author string?
    ---@param dialogueTag string?
    ---@return string?
    getunknownlanguagestring = function(_, language, stream, author, dialogueTag)
        if not language then
            return
        end

        language = tostring(language)
        stream = stream and tostring(stream) or 'say'
        author = author and tostring(author) or nil

        local isSigned = OmiChat.isRoleplayLanguageSigned(language)
        language = utils.getTranslatedLanguageName(language)

        if stream == 'radio' and not author then
            return getText('UI_OmiChat_unknown_language_radio_no_author', language)
        end

        dialogueTag = dialogueTag and tostring(dialogueTag) or nil
        if author and dialogueTag then
            local stringID = 'UI_OmiChat_unknown_language_narrative_' .. dialogueTag:gsub('%s', '_')
            local translated = getTextOrNull(stringID, author, language)

            if translated then
                return translated
            elseif isSigned then
                return getText('UI_OmiChat_unknown_language_narrative_signs', author, language)
            end

            return getText('UI_OmiChat_unknown_language_narrative_says', author, language)
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
