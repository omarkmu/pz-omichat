---Handles formatting chat messages with invisible characters.

local utils = require 'OmiChat/utils'

local char = string.char
local concat = table.concat
local floor = math.floor
local metaChar = char(65535)


---@class omichat.MetaFormatter : omi.Class
local MetaFormatter = utils.lib.class()


---@type table<integer, omichat.MetaFormatter>
local formatters = {}


---Returns the next free ID for a formatter.
---@return integer?
---@static
function MetaFormatter.getNextFreeID()
    for i = 101, 1024 do
        if not formatters[i] then
            return i
        end
    end
end


---Formats the text according to the formatter's format string.
---This encodes invisible characters for later identification.
---If the format string doesn't return proper content, this will
---behave as if the format string were `$input`.
---@param text string
---@param tokens table?
---@return string
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
---@return integer
function MetaFormatter:getID()
    return self._id
end

---Wraps the provided text in the formatter's invisible characters.
---@param text string
---@return string
function MetaFormatter:wrap(text)
    return self._idPrefix .. text .. self._idSuffix
end

---Retrieves the text that was formatted using this formatter.
---@param text string
---@return string
function MetaFormatter:read(text)
    return text:match(self:getPattern())
end

---Checks whether the given text was encoded with this formatter.
---@param text string
---@return boolean
function MetaFormatter:isMatch(text)
    return text:find(self:getPattern()) ~= nil
end

---Returns the name of the default used with the `$Default()` function.
---@return string
function MetaFormatter:getDefaultName()
    return self._defaultName
end

---Returns the formatter's format string.
---@return string
function MetaFormatter:getFormatString()
    return self._formatString
end

---Returns the formatter's string pattern.
---@param exact boolean? If true, an exact match will be required. Defaults to false.
---@return string
function MetaFormatter:getPattern(exact)
    exact = utils.default(exact, false)
    return concat {
        exact and '^' or '',
        self._idPrefix,
        '(.+)',
        self._idSuffix,
        exact and '$' or '',
    }
end

---Sets the ID of the formatter.
---IDs 1 to 100 are reserved by OmiChat.
---@param id integer An ID for the formatter, in [1, 1024].
---@private
function MetaFormatter:setID(id)
    if type(id) ~= 'number' or id < 1 then
        error('ID must be a positive integer')
    elseif id > 1024 then
        error('ID is too large')
    end

    id = floor(id)
    if formatters[id] then
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

    formatters[self._id] = self
end

---Sets the default name used with `$Default()` to the given string.
---@param default string?
function MetaFormatter:setDefaultName(default)
    self._defaultName = default or 'Overhead'
end

---Sets the format string to the given string.
---@param format string?
function MetaFormatter:setFormatString(format)
    self._formatString = format or '$input'
end

---Creates a new meta formatter.
---@param id integer A numerical ID for the formatter, in [101, 1024]. 1–100 are reserved by OmiChat.
---@param options omichat.MetaFormatterOptions? Optional initialization options.
---@return omichat.MetaFormatter
function MetaFormatter:new(id, options)
    ---@type omichat.MetaFormatter
    local this = setmetatable({}, MetaFormatter)

    options = options or {}
    this:setFormatString(options.format)
    this:setID(id)
    this._defaultName = options.defaultName or 'Overhead'

    return this
end


return MetaFormatter
