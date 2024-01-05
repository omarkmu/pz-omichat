local lib = require 'OmiChat/lib'
local Interpolator = require 'OmiChat/Component/Interpolator'

local format = string.format
local concat = table.concat
local getTimestampMs = getTimestampMs


---Utility functions.
---@class omichat.utils : omi.utils
---@field private _interpolatorCache table<string, omichat.utils.InterpolatorCacheItem>
local utils = lib.utils.copy(lib.utils)
utils.Interpolator = Interpolator
utils._interpolatorCache = {}

---@class omichat.utils.InterpolatorCacheItem
---@field interpolator omichat.Interpolator
---@field lastAccess number

local CACHE_EXPIRY_MS = 600000 -- ten minutes
local shortHexPattern = '^%s*#?(%x)(%x)(%x)%s*$'
local fullHexPattern = '^%s*#?(%x%x)%s*(%x%x)%s*(%x%x)%s*$'
local rgbPattern = '^%s*(%d%d?%d?)[,%s]+(%d%d?%d?)[,%s]+(%d%d?%d?)%s*$'
local accessLevels = {
    admin = 32,
    moderator = 16,
    overseer = 8,
    gm = 4,
    observer = 2,
}


---Gets an interpolator from the cache.
---@param text string
---@return omichat.Interpolator?
local function getCachedInterpolator(text)
    local item = utils._interpolatorCache[text]
    if item then
        item.lastAccess = getTimestampMs()
        return item.interpolator
    end
end

---Adds an interpolator to the cache.
---@param text string
---@param interpolator omichat.Interpolator
local function setCachedInterpolator(text, interpolator)
    utils._interpolatorCache[text] = {
        interpolator = interpolator,
        lastAccess = getTimestampMs(),
    }
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


---Cleans up unused cache items.
---@param clear boolean If true, the cache will be cleared entirely.
function utils.cleanupCache(clear)
    if clear then
        utils._interpolatorCache = {}
        return
    end

    local toRemove = {}
    local currentTime = getTimestampMs()
    for k, item in pairs(utils._interpolatorCache) do
        if currentTime - item.lastAccess >= CACHE_EXPIRY_MS then
            toRemove[#toRemove + 1] = k
        end
    end

    for i = 1, #toRemove do
        utils._interpolatorCache[toRemove[i]] = nil
    end
end

---Converts a color table to a hex string.
---@param color omichat.ColorTable
---@return string
function utils.colorToHexString(color)
    return format('%02x%02x%02x', color.r, color.g, color.b)
end

---Converts a color table to an RGB string.
---@param color omichat.ColorTable
---@return string
function utils.colorToRGBString(color)
    return format('%d,%d,%d', color.r, color.g, color.b)
end

---Escapes a string for use in a rich text panel.
---@see ISRichTextPanel
---@param text string
---@return string
function utils.escapeRichText(text)
    return (text:gsub('<', '&lt;'):gsub('>', '&gt;'))
end

---Gets a numeric access level given an access level string.
---@param access string
---@return integer
function utils.getNumericAccessLevel(access)
    if not access then
        return 1
    end

    return accessLevels[access:lower()] or 1
end

---Gets a player given their username.
---@param username string
---@return IsoPlayer?
function utils.getPlayerByUsername(username)
    if isClient() then
        return getPlayerFromUsername(username)
    end

    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() do
        local player = onlinePlayers:get(i)
        if player:getUsername() == username then
            return player
        end
    end
end

---Interpolates substitutions into a string with format strings using `$var` format.
---Functions are referenced using `$func(...)` syntax.
---@param text string The format string.
---@param tokens table A table of format substitution strings.
---@param options omi.interpolate.Options? Interpolation options.
---@return string
function utils.interpolate(text, tokens, options)
    -- only use cache for default options, since results may differ
    local useCache = not options

    local interpolator = useCache and getCachedInterpolator(text)
    if not interpolator then
        options = utils.copy(options or {})

        -- prevent randomness; would result in messages changing due to refreshes
        options.libraryExclude = utils.copy(options.libraryExclude or {})
        options.libraryExclude['mutators.choose'] = true
        options.libraryExclude['mutators.random'] = true
        options.libraryExclude['mutators.randomseed'] = true

        interpolator = Interpolator:new(options)
        interpolator:setPattern(text)

        if useCache then
            setCachedInterpolator(text, interpolator)
        end
    end

    return interpolator:interpolate(tokens)
end

---Checks a color table for validity.
---@param color omichat.ColorTable?
---@return boolean
function utils.isValidColor(color)
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

---Logs a non-fatal mod error.
---@param err string
---@param ... unknown
function utils.logError(err, ...)
    print('[OmiChat] ' .. string.format(err, ...))
end

---Parses arguments for a chat command.
---@param text string?
---@return string[]
function utils.parseCommandArgs(text)
    if not text then
        return {}
    end

    local i = 1
    local inQuote = false
    local current = {}
    local args = {}

    while i <= #text do
        local c = text:sub(i, i)
        local next = text:sub(i + 1, i + 1)

        if c == '\\' and next == '"' then
            current[#current + 1] = '"'
            i = i + 1
        elseif c == '"' then
            if #current > 0 then
                args[#args + 1] = concat(current)
                current = {}
            end

            inQuote = not inQuote
        elseif not inQuote and c == ' ' then
            if #current > 0 then
                args[#args + 1] = concat(current)
                current = {}
            end
        else
            current[#current + 1] = c
        end

        i = i + 1
    end

    if #current > 0 then
        args[#args + 1] = concat(current)
    end

    return args
end

---Replaces character entities with the characters that they represent.
---Numeric entities and named entities in ISO-8859-1 are supported.
---@param text string
---@return string
function utils.replaceEntities(text)
    text = text:gsub('(&#?x?[%a%d]+;)', function(entity)
        return utils.getEntityValue(entity) or entity
    end)

    return text
end

---Converts a color string to a color. Returns `nil` on failure.
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
    if not utils.isValidColor(color) then
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
        '> ',
    }
end

---Converts a color table to a color string for overhead messages.
---@param color omichat.ColorTable
---@param bbCodeFormat boolean? If true, BBCode format will be used.
---@return string
function utils.toOverheadColor(color, bbCodeFormat)
    if not utils.isValidColor(color) then
        return ''
    end

    return concat {
        bbCodeFormat and '[col=' or '*',
        color.r,
        ',',
        color.g,
        ',',
        color.b,
        bbCodeFormat and ']' or '*',
    }
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

---Reverses the operation of escaping text for use in a rich text panel.
---@see ISRichTextPanel
---@see omichat.utils.escapeRichText
---@param text string
---@return string
function utils.unescapeRichText(text)
    return (text:gsub('&lt;', '<'):gsub('&gt;', '>'))
end


return utils
