local lib = require 'OmiChat/lib'
local OmiChatInterpolator = require 'OmiChat/Interpolator'


---Utility functions.
---@class omichat.utils : omi.utils
local utils = lib.utils.copy(lib.utils)
utils.kvp = {}
utils.Interpolator = OmiChatInterpolator

local string = string
local format = string.format
local concat = table.concat

local shortHexPattern = '^%s*#?(%x)(%x)(%x)%s*$'
local fullHexPattern = '^%s*#?(%x%x)%s*(%x%x)%s*(%x%x)%s*$'
local rgbPattern = '^%s*(%d%d?%d?)[,%s]+(%d%d?%d?)[,%s]+(%d%d?%d?)%s*$'


---Encodes a string for use as a key or value in kvp format.
---@param text string
---@param forceQuotes boolean?
---@return string
local function kvpEncodeString(text, forceQuotes)
    text = tostring(text)
    if forceQuotes or #text == 0 or text:find('"') then
        return concat { '"', text:gsub('([\\"])', '\\%1'), '"' }
    end

    return text
end

---Reads a key or value from a kvp-encoded string.
---@param text string
---@param i integer Current character index.
---@return string decodedValue
---@return integer index
local function kvpReadString(text, i)
    local escape = false
    local value = {}

    local current = text:sub(i, i)
    if current == '"' then
        i = i + 1
    else
        -- not quote-wrapped → skip to next quote if possible
        local nextQuote = text:find('"', i)
        if nextQuote then
            return text:sub(i, nextQuote - 1), nextQuote
        end
    end

    while i <= #text do
        local c = text:sub(i, i)
        if escape then
            if c ~= '"' and c ~= '\\' then
                value[#value+1] = '\\'
            end

            value[#value+1] = c
            escape = false
        elseif c == '"' then
            break
        elseif c == '\\' then
            escape = true
        else
            value[#value+1] = c
        end

        i = i + 1
    end

    if escape then
        -- should not happen
        value[#value+1] = '\\'
    end

    return concat(value), i + 1
end

---Attempts to read an RGB or hex color from a string.
---@param text string
---@return number?
---@return number?
---@return number?
local function readColor(text)
    local r, g, b = text:match(rgbPattern)
    if r then
        return tonumber(r), tonumber(g), tonumber(b)
    end

    r, g, b = text:match(shortHexPattern)
    if r then
        r = r .. r
        g = g .. g
        b = b .. b
    else
        r, g, b = text:match(fullHexPattern)
    end

    if not r then
        return
    end

    return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end

---Checks a color table for validity.
---@param color table
---@return boolean
local function checkColorTable(color)
    if type(color) ~= 'table' then
        return false
    end

    local r = color.r
    local g = color.g
    local b = color.b

    if type(r) ~= 'number' or r < 0 or r > 255 then
        return false
    end
    if type(g) ~= 'number' or g < 0 or g > 255 then
        return false
    end
    if type(b) ~= 'number' or b < 0 or b > 255 then
        return false
    end

    return true
end


---Interpolates substitutions into a string with format strings using $var format.
---Functions are referenced using $func(...) syntax.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param options omi.interpolate.Options? Interpolation options.
---@return string
function utils.interpolate(text, tokens, options)
    options = options or {}
    options.libraryExclude = utils.copy(options.libraryExclude or {})

    -- randomness would result in messages changing due to refreshes
    options.libraryExclude['mutators.choose'] = true
    options.libraryExclude['mutators.random'] = true
    options.libraryExclude['mutators.randomseed'] = true

    ---@type omichat.Interpolator
    local interpolator = OmiChatInterpolator:new(options)
    interpolator:setPattern(text)

    return interpolator:interpolate(tokens)
end

---Converts a color table to an RGB string.
---@param color omichat.ColorTable
---@return string
function utils.colorToRGBString(color)
    return string.format('%d,%d,%d', color.r, color.g, color.b)
end

---Converts a color table to a hex string.
---@param color omichat.ColorTable
---@return string
function utils.colorToHexString(color)
    return string.format('%02x%02x%02x', color.r, color.g, color.b)
end

---Attempts to convert a color string to a color. Returns false and an error message on failure.
---@param text string A color string, in RGB or hex.
---@param minColor integer? Minimum color value [0, 255].
---@param maxColor integer? Maximum color value [0, 255].
---@return omi.Result<omichat.ColorTable>
function utils.tryStringToColor(text, minColor, maxColor)
    if not text then
        return { success = false, error = getText('UI_OmiChat_error_invalid_color') }
    end

    local r, g, b = readColor(text)
    if not r then
        return { success = false, error = getText('UI_OmiChat_error_invalid_color') }
    end

    maxColor = maxColor or 255
    if r > maxColor or g > maxColor or b > maxColor then
        return { success = false, error = getText('UI_OmiChat_error_color_max', tostring(maxColor)) }
    end

    minColor = minColor or 0
    if r < minColor or g < minColor or b < minColor then
        return { success = false, error = getText('UI_OmiChat_error_color_min', tostring(minColor)) }
    end

    return { success = true, value = { r = r, g = g, b = b } }
end

---Converts a color string to a color. Returns nil on failure.
---@param text string A color string, in RGB or hex.
---@return omichat.ColorTable?
function utils.stringToColor(text)
    return utils.tryStringToColor(text).value
end

---Converts a color table to a color string for chat messages.
---@param color omichat.ColorTable
---@param pushFormat boolean? If true, PUSHRGB format will be used.
---@return string
function utils.toChatColor(color, pushFormat)
    if not checkColorTable(color) then
        return ''
    end

    return concat {
        ' <',
        pushFormat and 'PUSH' or '',
        'RGB:',
        format('%.7f', color.r / 255):gsub('00+$', '0'),
        ',',
        format('%.7f', color.g / 255):gsub('00+$', '0'),
        ',',
        format('%.7f', color.b / 255):gsub('00+$', '0'),
        '> '
    }
end

---Converts a color table to a color string for overhead messages.
---@param color omichat.ColorTable
---@param bbCodeFormat boolean? If true, BBCode format will be used.
---@return string
function utils.toOverheadColor(color, bbCodeFormat)
    if not checkColorTable(color) then
        return ''
    end

    return concat {
        bbCodeFormat and '[col=' or '*',
        color.r,
        ',',
        color.g,
        ',',
        color.b,
        bbCodeFormat and ']' or '*'
    }
end

---Encodes a table as a string of key-value pairs.
---Keys and values are converted to strings.
---@param table table
---@return string
function utils.kvp.encode(table)
    local result = {}

    for k, v in pairs(table) do
        result[#result+1] = kvpEncodeString(k)
        result[#result+1] = kvpEncodeString(v, true)
    end

    return concat(result)
end

---Decodes a string of key-value pairs.
---@param text string
---@return table
function utils.kvp.decode(text)
    local result = {}

    local i = 1
    local key, value
    while i <= #text do
        key, i = kvpReadString(text, i)
        value, i = kvpReadString(text, i)

        result[key] = value
    end

    return result
end


return utils
