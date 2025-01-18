---Utility interpolation library functions.

local API = require 'OmiChat/API/Shared/Core'

local utils = API.utils
local MultiMap = utils.MultiMap
local baseLib = utils.lib.interpolate.Interpolator.Libraries
local stringLib = baseLib.string


---@class omichat.InterpolationLibrary
local Library = require 'OmiChat/Component/InterpolationLibrary/Core'
local Helpers = Library.Helpers


---Capitalizes the first non-invisible character of a string.
---@type fun(interpolator: omi.Interpolator, ...: unknown): string
Library.Capitalize = Helpers.internalWrap(stringLib.Capitalize)

---Adds punctuation to a string if it isn't already present.
---Handles encoded invisible characters.
---@type fun(interpolator: omi.Interpolator, ...: unknown): string
Library.Punctuate = Helpers.internalWrap(stringLib.Punctuate)


---Returns the access level of player 1.
---@return string
function Library.AccessLevel()
    local player = getSpecificPlayer(0)
    return player and player:getAccessLevel() or 'none'
end

---Colors actions in a string based on the streams tagged with `ActionColorTarget`.
---@param interpolator omichat.Interpolator
---@param message unknown
---@param options unknown
---@return string?
function Library.ColorActions(interpolator, message, options)
    if not message then
        return
    end

    message = tostring(message)
    if utils.isinstance(options, MultiMap) then
        ---@cast options omi.MultiMap
        options = options:toOptions()
    else
        options = nil
    end

    return Helpers.colorActions(message, options, Helpers.readTags(interpolator))
end

---Colors quotes in a string based on the streams tagged with `QuoteColorTarget`.
---@param interpolator omichat.Interpolator
---@param message unknown
---@param options unknown
---@return string?
function Library.ColorQuotes(interpolator, message, options)
    if not message then
        return
    end

    message = tostring(message)
    if utils.isinstance(options, MultiMap) then
        ---@cast options omi.MultiMap
        options = options:toOptions()
    else
        options = nil
    end

    return Helpers.colorQuotes(message, options, Helpers.readTags(interpolator))
end

---Validates that the message is not being sent with a signed language.
---Sets an error token if it is.
---@param interpolator omichat.Interpolator
---@param options omi.MultiMap?
---@return boolean
function Library.DisallowSignedOverRadio(interpolator, options)
    if utils.isinstance(options, MultiMap) then
        ---@cast options omi.MultiMap
        options = options:toOptions()
    else
        options = nil
    end

    local condition = options and options:get('condition')
    if condition ~= nil and not interpolator:toBoolean(condition) then
        return true
    end

    local errorID = Helpers.checkSignedOverRadio(interpolator)
    if not errorID then
        return true
    end

    if not options or not options:getBoolean('suppressError') then
        interpolator:setToken('errorID', errorID)
    end

    return false
end

---Escapes rich text in a string.
---@param interpolator omichat.Interpolator
---@param ... unknown
---@return string
---@diagnostic disable-next-line: unused-local
function Library.EscapeRichText(interpolator, ...)
    return utils.escapeRichText(Helpers.stringify(...))
end

---Formats text that indicates the radio channel a message was sent over.
---@param interpolator omichat.Interpolator
---@param ... unknown
---@return string
---@diagnostic disable-next-line: unused-local
function Library.FormatRadio(interpolator, ...)
    local s = Helpers.stringify(...)
    if s == '' then
        s = '???'
    end

    return getText('UI_OmiChat_Radio', s)
end

---Returns a partial quote representing a fragment of what a player character understood.
---@param interpolator omichat.Interpolator
---@param message string
---@return string?
function Library.Fragmented(interpolator, message)
    return Helpers.getFragmentedMessage(interpolator, tostring(message or ''))
end

---Returns text without invisible wrapping characters used for mod functionality.
---@param interpolator omichat.Interpolator
---@param ... unknown
---@return string
---@diagnostic disable-next-line: unused-local
function Library.Internal(interpolator, ...)
    return (utils.getInternalText(Helpers.stringify(...)))
end

---Returns whether the local player is an admin.
---@return boolean
function Library.IsAdmin()
    return isAdmin()
end

---Returns whether the local player is the co-op host.
---@return boolean
function Library.IsCoopHost()
    return isCoopHost()
end

---Returns whether the given language is signed.
---@param interpolator omichat.Interpolator
---@param language unknown
---@return boolean
---@diagnostic disable-next-line: unused-local
function Library.IsSigned(interpolator, language)
    return API.isRoleplayLanguageSigned(tostring(language or ''))
end

---Wraps text in parentheses.
---@param interpolator omichat.Interpolator
---@param ... unknown
---@return string
---@diagnostic disable-next-line: unused-local
function Library.Parens(interpolator, ...)
    return '(' .. Helpers.stringifySep(' ', ...) .. ')'
end

---Returns the stream category given a stream name.
---@param interpolator omichat.Interpolator
---@param name unknown
---@return string?
---@diagnostic disable-next-line: unused-local
function Library.StreamCategory(interpolator, name)
    ---@cast API omichat.api.client
    if not API.getChatStreamByName then
        return
    end

    local stream = API.getChatStreamByName(name)
    if not stream then
        return
    end

    return stream:getCommandType()
end

---Strips rich text colors from a string.
---@param interpolator omichat.Interpolator
---@param s unknown
---@return string
---@diagnostic disable-next-line: unused-local
function Library.StripColors(interpolator, s)
    s = tostring(s or ''):gsub('<RGB:[%d,.]*>', '')
    return s
end
