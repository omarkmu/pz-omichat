---Utility interpolation library functions.
---@namespace omichat

local API = require 'OmiChat/Module/Core/Shared'
local API_C = API --[[@as api.client]]

local utils = API.utils
local MultiMap = utils.MultiMap

local getText = utils.getText
local IS_CLIENT = not isServer()

---@class(partial) InterpolationLibrary
local Library = require 'OmiChat/Module/Core/InterpolationLibrary'
local Helpers = Library.Helpers


---Adds a tag to `tags` token.
---This fails if there is no `tags` token or it is not a multimap.
---@param interpolator omi.Interpolator The interpolator in use.
---@param tag any The tag to add.
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param ...any Arguments passed to the interpolator function. Combined and converted into a string.
---@return string capitalized
function Library.Capitalize(interpolator, ...)
    return Helpers.capitalize(utils.concat({ ... }))
end

---Colors actions in a string based on the streams tagged with `ActionColorTarget`.
---@param interpolator omi.Interpolator The interpolator in use.
---@param message any? The message text.
---@param options any? A multimap of options.
---@return string? formatted
function Library.ColorActions(interpolator, message, options)
    message = tostring(message or '')
    if message == '' then
        return
    end

    options = Helpers.readOptions(options)
    local segments = Helpers.getMessageSegments(message, {
        optionalActionAsterisk = options:getBoolean('optionalAsterisks'),
    })

    Helpers.colorActions(segments, options, Helpers.readTags(interpolator))
    return Helpers.combineSegments(segments)
end

---Colors quotes in a string based on the streams tagged with `QuoteColorTarget`.
---@param interpolator omi.Interpolator The interpolator in use.
---@param message any? The message text.
---@param options any? A multimap of options.
---@return string? formatted
function Library.ColorQuotes(interpolator, message, options)
    message = tostring(message or '')
    if message == '' then
        return
    end

    options = Helpers.readOptions(options)
    local optionalAsterisks = options:getBoolean('optionalAsterisks')

    local segments = Helpers.getMessageSegments(message, {
        startInAction = true,
        optionalActionAsterisk = optionalAsterisks,
    })

    Helpers.colorQuotes(segments, options, Helpers.readTags(interpolator))
    return Helpers.combineSegments(segments)
end

---Validates that the message is not being sent with a signed language.
---Sets an error token if it is.
---@param interpolator omi.Interpolator The interpolator in use.
---@param options any? A multimap of options.
---@return boolean isAllowed
function Library.DisallowSignedOverRadio(interpolator, options)
    options = Helpers.readOptions(options)

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
---@param interpolator omi.Interpolator The interpolator in use.
---@param ...any Arguments passed to the interpolator function. Combined and converted into a string.
---@return string formatted
function Library.FormatRadio(interpolator, ...)
    local s = Helpers.stringify(...)
    if s == '' then
        s = '???'
    end

    return getText('radio', { frequency = s })
end

---Returns a partial quote representing a fragment of what a player character understood.
---@param interpolator omi.Interpolator The interpolator in use.
---@param message string The message to fragment.
---@return string? fragmented
function Library.Fragmented(interpolator, message)
    return Helpers.getFragmentedMessage(interpolator, tostring(message or ''))
end

---Checks the `tags` token for a tag.
---@param interpolator omi.Interpolator The interpolator in use.
---@param tag any The tag to check for.
---@return boolean hasTag Whether the tag is present. If there is no `tags` token or it is not a multimap, `false`.
function Library.HasTag(interpolator, tag)
    tag = tag and tostring(tag)
    if not tag or #tag == 0 then
        return false
    end

    local tags = interpolator:token('tags')
    if not utils.isinstance(tags, MultiMap) then
        return false
    end

    return tags:has(tag)
end

---Returns whether the given language is signed.
---@param interpolator omi.Interpolator The interpolator in use.
---@param language any
---@return boolean isSigned
function Library.IsSigned(interpolator, language)
    return API.language.isSigned(tostring(language or ''))
end

---Wraps text in parentheses.
---@param interpolator omi.Interpolator The interpolator in use.
---@param ...any Arguments passed to the interpolator function. Combined and converted into a string.
---@return string formatted
function Library.Parens(interpolator, ...)
    return '(' .. Helpers.stringifySep(' ', ...) .. ')'
end

---Adds punctuation to a string if it isn't already present.
---@param interpolator omi.Interpolator The interpolator in use.
---@param input any? The string to punctuate.
---@param punctuation any? The punctuation character to use. Defaults to `.`.
---@param characters any? Characters to treat as punctuation. Defaults to `.,!?:/-~`.
---@return string formatted
function Library.Punctuate(interpolator, input, punctuation, characters)
    return Helpers.punctuate(tostring(input or ''), punctuation, characters)
end

---Returns the stream category given a stream name.
---@param interpolator omi.Interpolator The interpolator in use.
---@param name any? The name of a stream.
---@return StreamCategory? category
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param input any? The input text.
---@return string formatted
function Library.StripColors(interpolator, input)
    input = tostring(input or ''):gsub('<RGB:[%d,.]*>', '')
    return input
end

---Removes a tag from the `tags` token.
---This fails if there is no `tags` token or it is not a multimap.
---@param interpolator omi.Interpolator The interpolator in use.
---@param tag any The tag to remove.
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
