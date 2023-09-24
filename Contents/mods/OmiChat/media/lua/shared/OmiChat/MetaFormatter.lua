local lib = require 'OmiChat/lib'

---Handles formatting for special chat messages with invisible characters.
---@class omichat.MetaFormatter : omi.Class
---@field protected pattern string
---@field protected formatString string
---@field protected prefix string
---@field protected suffix string
---@field protected requireExactMatch boolean
---@field protected interpolator omichat.Interpolator
---@field private _nextId integer
local MetaFormatter = lib.class()
MetaFormatter._nextId = 101

local utils = require 'OmiChat/util'

---@type omichat.MetaFormatter[]
local formatters = {}


local char = string.char
local concat = table.concat
local floor = math.floor

---@type omi.interpolate.Options
local interpolateOptions = {
    allowMultiMaps = false,
    allowFunctions = false
}


---Builds the pattern used to reverse the formatting operation.
---@param format string
---@return string?
local function buildPattern(format)
    local found
    local i = 1
    local patt = '($$?[%w_]*)'

    -- build the pattern safely
    local parts = {}
    local start, finish, text = format:find(patt)
    while start do
        parts[#parts+1] = utils.escape(format:sub(i, start - 1))

        if text == '$1' then
            if found then
                -- illegal: only one instance of $1 substitution allowed
                found = false
                break
            end

            found = true
            parts[#parts+1] = '(.+)'
        elseif text:sub(1, 2) == '$$' then
            -- include escaped tokens
            parts[#parts+1] = utils.escape(text:sub(2))
        end

        i = finish + 1
        start, finish, text = format:find(patt, i)
    end

    if not found then
        return
    elseif i <= #format then
        parts[#parts+1] = utils.escape(format:sub(i))
    end

    return concat(parts)
end


---Formats the text according to the formatter's format string.
---This encodes the invisible ID prefix and suffix for later identification.
---@param text string
---@return string
function MetaFormatter:format(text)
    local interpolated = self.interpolator:interpolate({ text })
    return concat {
        self:getPrefix(),
        self.idPrefix,
        interpolated,
        self.idSuffix,
        self:getSuffix(),
    }
end

---Retrieves the text that was formatted using this formatter.
---@param text string
---@return string
function MetaFormatter:read(text)
    text = text:gsub(self:getPattern(), '%1', 1)
    return text
end

---Checks whether the given text matches the formatter's pattern.
---@param text string
---@return boolean
function MetaFormatter:isMatch(text)
    return text:find(self:getPattern()) ~= nil
end

---Returns the formatter's string pattern.
---@return string
function MetaFormatter:getPattern()
    if self.requireExactMatch then
        return concat { '^', self.pattern, '$' }
    end

    return self.pattern
end

---Returns the formatter's format string.
---@return string
function MetaFormatter:getFormatString()
    return self.formatString
end

---Returns the formatter's prefix.
---@return string
function MetaFormatter:getPrefix()
    return self.prefix or ''
end

---Returns the formatter's suffix.
---@return string
function MetaFormatter:getSuffix()
    return self.suffix or ''
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
    self.idPrefix = char(127 + floor(n / 33))
    self.idSuffix = char(127 + (n % 33))
    self:setFormatString(self.formatString)

    formatters[self.id] = self

    if id > MetaFormatter._nextId then
        MetaFormatter._nextId = id + 1
    end

    if old and old ~= self then
        old:setID(MetaFormatter._nextId)
        MetaFormatter._nextId = MetaFormatter._nextId + 1
    end
end

---Sets the format string to the given string.
---This must contain exactly one instance of the $1 substitution string.
---If the given string is invalid, the format will fall back to $1.
---This triggers a rebuild of the associated pattern.
---@param format string
---@return boolean #Whether the given string was valid.
function MetaFormatter:setFormatString(format)
    local validFormat = true

    self.interpolator:setPattern(format)
    local tokens = self.interpolator:getTopLevelTokens()

    local parts
    if #tokens == 1 and tokens[1] == '1' then
        parts = buildPattern(format)
    end

    if not parts then
        -- fallback if invalid
        format = '$1'
        parts = '(.+)'
        validFormat = false
        self.interpolator:setPattern(format)
    end

    self.formatString = format
    self.pattern = concat { self.idPrefix, parts, self.idSuffix }

    return validFormat
end

---Initializes the formatter values.
---@param format string
function MetaFormatter:init(format)
    self.prefix = ''
    self.suffix = ''
    self.formatString = tostring(format or '$1')
    self.requireExactMatch = false
    self.interpolator = utils.Interpolator:new(interpolateOptions)
end

---Creates a new meta formatter.
---@param format string
---@return omichat.MetaFormatter
function MetaFormatter:new(format)
    ---@type omichat.MetaFormatter
    local this = setmetatable({}, MetaFormatter)

    this:init(format)
    this:setID(MetaFormatter._nextId) -- calls setFormatString
    MetaFormatter._nextId = MetaFormatter._nextId + 1

    return this
end


return MetaFormatter
