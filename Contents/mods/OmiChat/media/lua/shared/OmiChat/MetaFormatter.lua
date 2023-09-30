local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'

local char = string.char
local concat = table.concat
local floor = math.floor


---@class omichat.MetaFormatterOptions
---@field format string

---Handles formatting for special chat messages with invisible characters.
---@class omichat.MetaFormatter : omi.Class
---@field protected formatString string
---@field protected charSequence string
---@field protected interpolator omichat.Interpolator
---@field private _nextID integer
local MetaFormatter = lib.class()
MetaFormatter._nextID = 101

---@type omichat.MetaFormatter[]
local formatters = {}

---@type omi.interpolate.Options
local interpolateOptions = {
    allowMultiMaps = false,
    allowFunctions = false
}

---Replaces numeric character entities in text.
---@param text string
---@return string
local function replaceNumericEntities(text)
    text = text:gsub('&#(%d+);', function(x)
        local s, c = pcall(string.char, tonumber(x))
        return s and c or ''
    end)

    return text
end

---Formats the text according to the formatter's format string.
---This encodes invisible characters for later identification.
---@param text string
---@return string
function MetaFormatter:format(text)
    return self.interpolator:interpolate({ self:wrap(text) })
end

---Wraps the provided text in the formatter's invisible characters.
---@param text string
---@return string
function MetaFormatter:wrap(text)
    return concat { self.charSequence, text, self.charSequence }
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
        self.charSequence,
        '(.+)',
        self.charSequence,
        exact and '$' or '',
    }
end

---Returns the formatter's format string.
---@return string
function MetaFormatter:getFormatString()
    return self.formatString
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
    if self.id then
        old = formatters[self.id]
        formatters[self.id] = nil
    end

    self.id = id

    local n = id - 1
    self.charSequence = char(128 + floor(n / 32)) .. char(128 + (n % 32))

    formatters[self.id] = self

    if id > MetaFormatter._nextID then
        MetaFormatter._nextID = id + 1
    end

    if old and old ~= self then
        old:setID(MetaFormatter._nextID)
        MetaFormatter._nextID = MetaFormatter._nextID + 1
    end
end

---Sets the format string to the given string.
---This must contain exactly one instance of the $1 substitution string.
---If the given string is invalid, the format will fall back to $1.
---This triggers a rebuild of the associated pattern.
---@param format string
---@return boolean valid Whether the given string was valid.
function MetaFormatter:setFormatString(format)
    local validFormat = true

    format = replaceNumericEntities(format)
    self.interpolator:setPattern(format)
    local tokens = self.interpolator:getTopLevelTokens()

    if #tokens ~= 1 or tokens[1] ~= '1' then
        -- fallback if invalid
        format = '$1'
        validFormat = false
        self.interpolator:setPattern(format)
    end

    self.formatString = format
    return validFormat
end

---Initializes formatter values.
---@param options omichat.MetaFormatterOptions
function MetaFormatter:init(options)
    self.interpolator = utils.Interpolator:new(interpolateOptions)
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
