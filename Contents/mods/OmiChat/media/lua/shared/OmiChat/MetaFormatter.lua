local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'

local char = string.char
local concat = table.concat
local floor = math.floor


---@class omichat.MetaFormatterOptions
---@field format string

---Handles formatting for special chat messages with invisible characters.
---@class omichat.MetaFormatter : omi.Class
---@field protected _id integer
---@field protected _formatString string
---@field protected _idPrefix string
---@field protected _idSuffix string
---@field private _nextID integer
local MetaFormatter = lib.class()
MetaFormatter._nextID = 101

---@type omichat.MetaFormatter[]
local formatters = {}

---Formats the text according to the formatter's format string.
---This encodes invisible characters for later identification.
---If the format string doesn't return proper content, this will
---behave as if the format string were `$1`.
---@param text string
---@return string
function MetaFormatter:format(text)
    text = self:wrap(text)
    local formatted = utils.interpolate(self._formatString, { text })

    if not self:isMatch(formatted) then
        return text
    end

    return formatted
end

---Wraps the provided text in the formatter's invisible characters.
---@param text string
---@return string
function MetaFormatter:wrap(text)
    return concat { self._idPrefix, text, self._idSuffix }
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

---Returns the formatter's format string.
---@return string
function MetaFormatter:getFormatString()
    return self._formatString
end

---Sets the ID of the formatter.
---This should not be used under normal circumstances; an ID is automatically assigned in `new`.
---IDs 1 to 100 are reserved by OmiChat.
---@param id integer
function MetaFormatter:setID(id)
    if id < 1 then
        error('id must be a positive integer')
    end

    local old
    if self._id then
        old = formatters[self._id]
        formatters[self._id] = nil
    end

    self._id = id

    -- taking advantage of the ISO-8859-1 character set
    -- 128–160 are unused and are invisible ingame
    local n = id - 1
    local c1 = char(128 + floor(n / 32))
    local c2 = char(128 + (n % 32))

    self._idPrefix = c1 .. c2
    self._idSuffix = c2 .. c1

    formatters[self._id] = self

    if id > MetaFormatter._nextID then
        MetaFormatter._nextID = id + 1
    end

    if old and old ~= self then
        old:setID(MetaFormatter._nextID)
        MetaFormatter._nextID = MetaFormatter._nextID + 1
    end
end

---Sets the format string to the given string.
---@param format string
function MetaFormatter:setFormatString(format)
    self._formatString = format
end

---Initializes formatter values.
---@param options omichat.MetaFormatterOptions
function MetaFormatter:init(options)
    self:setFormatString(tostring(options.format or '$1'))
end

---Creates a new meta formatter.
---@param options omichat.MetaFormatterOptions
---@return omichat.MetaFormatter
function MetaFormatter:new(options)
    ---@type omichat.MetaFormatter
    local this = setmetatable({}, MetaFormatter)

    this:init(options or {})
    this:setID(MetaFormatter._nextID)
    MetaFormatter._nextID = MetaFormatter._nextID + 1

    return this
end


return MetaFormatter
