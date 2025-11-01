---Handles formatting chat messages with invisible characters.
---@namespace omichat

local utils = require 'OmiChat/Utils'

local char = string.char
local concat = table.concat
local floor = math.floor
local metaChar = char(65535)


---@class MetaFormatter : omi.Class
---@field protected _id integer The ID of the metadata formatter.
---@field protected _formatString string The format string used when formatting text.
---@field protected _idPrefix string The prefix for formatted text.
---@field protected _idSuffix string The suffix for formatted text.
---@field protected _defaultName string The name of the default to use for the `$Default()` interpolation function.
---@field private _formatters table<integer, MetaFormatter> Associates IDs to formatter objects.
local MetaFormatter = utils.lib.class()

MetaFormatter._formatters = {}


---Returns the next free ID for a formatter.
---@return integer? id
function MetaFormatter.getNextFreeID()
    for i = 101, 1024 do
        if not MetaFormatter._formatters[i] then
            return i
        end
    end
end


---Formats the text according to the formatter's format string.
---This encodes invisible characters for later identification.
---If the format string doesn't return proper content, this will behave as if the format string were `$input`.
---@param text string The text to format.
---@param tokens table? Tokens for interpolation.
---@return string formatted
function MetaFormatter:format(text, tokens)
    text = self:wrap(text)
    if tokens then
        tokens = utils.copy(tokens)
    else
        tokens = {}
    end

    tokens.input = text
    tokens.DEFAULT = self._defaultName

    local formatted = utils.replaceEntities(utils.interpolate(self:getFormatString(), tokens))

    if not self:isMatch(formatted) then
        return text
    end

    return formatted
end

---Returns the ID of the formatter.
---@return integer id
function MetaFormatter:getID()
    return self._id
end

---Wraps the provided text in the formatter's invisible characters.
---@param text string The text to wrap.
---@return string wrapped
function MetaFormatter:wrap(text)
    return self._idPrefix .. text .. self._idSuffix
end

---Retrieves the text that was formatted using this formatter.
---@param text string The text to read.
---@return string? matched
function MetaFormatter:read(text)
    return text:match(self:getPattern())
end

---Checks whether the given text was encoded with this formatter.
---@param text string The text to check.
---@return boolean isMatch
function MetaFormatter:isMatch(text)
    return text:find(self:getPattern()) ~= nil
end

---Returns the name of the default used with the `$Default()` function.
---@return string defaultName
function MetaFormatter:getDefaultName()
    return self._defaultName
end

---Returns the formatter's format string.
---@return string formatString
function MetaFormatter:getFormatString()
    return self._formatString
end

---Returns the formatter's string pattern.
---@param exact boolean? Flag for whether an exact match should be required.
---@param minimal boolean? Flag for whether a minimal match should be used instead of maximal.
---@return string pattern
function MetaFormatter:getPattern(exact, minimal)
    exact = exact or false
    return concat {
        exact and '^' or '',
        self._idPrefix,
        minimal and '(.-)' or '(.+)',
        self._idSuffix,
        exact and '$' or '',
    }
end

---Sets the default name used with `$Default()` to the given string.
---@param default string? The name to use.
function MetaFormatter:setDefaultName(default)
    self._defaultName = default or 'Overhead'
end

---Sets the format string to the given string.
---@param format string? The format string to use for formatting text. Defaults to `$input`.
function MetaFormatter:setFormatString(format)
    self._formatString = format or '$input'
end


---Sets the ID of the formatter.
---IDs 1 to 100 are reserved by OmiChat.
---@param id integer An ID for the formatter, in [1, 1024].
---@private
function MetaFormatter:_setID(id)
    if type(id) ~= 'number' or id < 1 then
        error('ID must be a positive integer')
    elseif id > 1024 then
        error('ID is too large')
    end

    id = floor(id)
    if MetaFormatter._formatters[id] then
        if id <= 100 then
            error(string.format('Cannot overwrite reserved formatter ID %d', id))
        end

        utils.log.info('Created formatter with duplicate ID %d', id)
    end

    self._id = id

    -- taking advantage of the ISO-8859-1 character set
    -- 128–159 are unused and are invisible ingame
    local n = id - 1
    local c1 = char(128 + floor(n / 32))
    local c2 = char(128 + (n % 32))

    self._idPrefix = metaChar .. c1 .. c2
    self._idSuffix = c2 .. c1 .. metaChar

    MetaFormatter._formatters[self._id] = self
end


---Creates a new meta formatter.
---@param id integer A numerical ID for the formatter, in [101, 1024]. 1–100 are reserved by OmiChat.
---@param options Args.MetaFormatter? Optional initialization options.
---@return MetaFormatter
function MetaFormatter:new(id, options)
    ---@type MetaFormatter
    local this = setmetatable({}, MetaFormatter)

    options = options or {}
    this:setFormatString(options.format)
    this:_setID(id)
    this._defaultName = options.defaultName or 'Overhead'

    return this
end


return MetaFormatter

--#region Type Definitions

---@class Args.MetaFormatter
---@field format string? The format string to use.
---@field defaultName string? The name of the default to use for the `$Default()` interpolation function.

--#endregion
