---Utility interpolation library functions.
---@diagnostic disable: unused-local

local API = require 'OmiChat/Module/Shared/Core'
local API_C = API --[[@as omichat.api.client]]

local utils = API.utils
local MultiMap = utils.MultiMap

local IS_CLIENT = not isServer()

---@class omichat.InterpolationLibrary
local Library = require 'OmiChat/Module/InterpolationLibrary/Core'
local Helpers = Library.Helpers


---Adds a tag to `tags` token.
---This fails if there is no `tags` token or it is not a multimap.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param tag unknown The tag to add.
function Library.AddTag(interpolator, tag)
    tag = tag and tostring(tag)
    if not tag or utils.trim(tag) == '' then
        return
    end

    local tags = interpolator:token('tags') --[[@as omi.MultiMap]]
    if not utils.isinstance(tags, MultiMap) then
        return
    end

    interpolator:setToken('tags', tags:withSetValue(tag))
end

---Capitalizes the first non-invisible character of a string.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param ... unknown Arguments passed to the interpolator function. Combined and converted into a string.
---@return string capitalized
function Library.Capitalize(interpolator, ...)
    return Helpers.capitalize(utils.concat({ ... }))
end

---Colors actions in a string based on the streams tagged with `ActionColorTarget`.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param message unknown? The message text.
---@param options unknown? A multimap of options.
---@return string? formatted
function Library.ColorActions(interpolator, message, options)
    message = tostring(message or '')
    if message == '' then
        return
    end

    options = Helpers.readOptions(options)
    local segments, prefix, suffix = Helpers.getMessageSegments(tostring(message), {
        optionalActionAsterisk = options:getBoolean('optionalAsterisks'),
    })

    Helpers.colorActions(segments, options, Helpers.readTags(interpolator))
    return prefix .. Helpers.combineSegments(segments) .. suffix
end

---Colors quotes in a string based on the streams tagged with `QuoteColorTarget`.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param message unknown? The message text.
---@param options unknown? A multimap of options.
---@return string? formatted
function Library.ColorQuotes(interpolator, message, options)
    message = tostring(message or '')
    if message == '' then
        return
    end

    options = Helpers.readOptions(options)
    local optionalAsterisks = options:getBoolean('optionalAsterisks')

    local segments, prefix, suffix = Helpers.getMessageSegments(tostring(message), {
        startInAction = true,
        optionalActionAsterisk = optionalAsterisks,
    })

    Helpers.colorQuotes(segments, options, Helpers.readTags(interpolator))
    return prefix .. Helpers.combineSegments(segments) .. suffix
end

---Validates that the message is not being sent with a signed language.
---Sets an error token if it is.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param options unknown? A multimap of options.
---@return boolean isAllowed
function Library.DisallowSignedOverRadio(interpolator, options)
    options = Helpers.readOptions(options)
    local optionalAsterisks = options:getBoolean('optionalAsterisks')

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

---Formats text that indicates the radio channel a message was sent over.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param ... unknown Arguments passed to the interpolator function. Combined and converted into a string.
---@return string formatted
function Library.FormatRadio(interpolator, ...)
    local s = Helpers.stringify(...)
    if s == '' then
        s = '???'
    end

    return getText('UI_OmiChat_Radio', s)
end

---Returns a partial quote representing a fragment of what a player character understood.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param message string The message to fragment.
---@return string? fragmented
function Library.Fragmented(interpolator, message)
    return Helpers.getFragmentedMessage(interpolator, tostring(message or ''))
end

---Checks the `tags` token for a tag.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param tag unknown The tag to check for.
---@return boolean hasTag Whether the tag is present. If there is no `tags` token or it is not a multimap, `false`.
function Library.HasTag(interpolator, tag)
    tag = tag and tostring(tag)
    if not tag or #tag == 0 then
        return false
    end

    local tags = interpolator:token('tags') --[[@as omi.MultiMap]]
    if not utils.isinstance(tags, MultiMap) then
        return false
    end

    return tags:has(tag)
end

---Returns text without invisible wrapping characters used for mod functionality.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param ... unknown Arguments passed to the interpolator function. Combined and converted into a string.
---@return string
function Library.Internal(interpolator, ...)
    return (utils.getInternalText(Helpers.stringify(...)))
end

---Returns whether the given language is signed.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param language unknown
---@return boolean isSigned
function Library.IsSigned(interpolator, language)
    return API.language.isSigned(tostring(language or ''))
end

---Wraps text in parentheses.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param ... unknown Arguments passed to the interpolator function. Combined and converted into a string.
---@return string formatted
function Library.Parens(interpolator, ...)
    return '(' .. Helpers.stringifySep(' ', ...) .. ')'
end

---Adds punctuation to a string if it isn't already present.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param input unknown? The string to punctuate.
---@param punctuation unknown? The punctuation character to use. Defaults to `.`.
---@param characters unknown? Characters to treat as punctuation. Defaults to using the punctuation string pattern.
---@return string formatted
function Library.Punctuate(interpolator, input, punctuation, characters)
    return Helpers.punctuate(tostring(input or ''), punctuation, characters)
end

---Returns the stream category given a stream name.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param name unknown? The name of a stream.
---@return omichat.StreamCategory? category
function Library.StreamCategory(interpolator, name)
    if not IS_CLIENT or not name then
        return
    end

    local stream = API_C.streams.getChatStream(name)
    if not stream then
        return
    end

    return stream:getCategory()
end

---Strips rich text colors from a string.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param input unknown? The input text.
---@return string formatted
function Library.StripColors(interpolator, input)
    input = tostring(input or ''):gsub('<RGB:[%d,.]*>', '')
    return input
end

---Removes a tag from the `tags` token.
---This fails if there is no `tags` token or it is not a multimap.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param tag unknown The tag to remove.
function Library.RemoveTag(interpolator, tag)
    tag = tag and tostring(tag)
    if not tag or #tag == 0 then
        return
    end

    local tags = interpolator:token('tags') --[[@as omi.MultiMap]]
    if not utils.isinstance(tags, MultiMap) then
        return
    end

    local set = tags:toValueSet()
    set[tag] = nil

    interpolator:setToken('tags', MultiMap.fromSet(set))
end
