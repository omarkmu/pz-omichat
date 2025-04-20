---Handles interpolation operations.

local lib = require 'OmiLibrary'
local BaseInterpolator = lib.interpolate.Interpolator


---@class omichat.Interpolator : omi.Interpolator
local Interpolator = BaseInterpolator:derive()
Interpolator._registered = {}
Interpolator._cache = lib.cache.new {
    primaryKey = 'text',
    ttl = 60000, -- ten minutes
}


local FUNCTION_MT = { __index = Interpolator._registered }


---Cleans up unused cache items.
---@param clear boolean If true, the cache will be cleared entirely.
function Interpolator.cleanupCache(clear)
    if clear then
        Interpolator._cache:clear()
        return
    end

    Interpolator._cache:update()
end

---Gets a cached interpolator, creating one if it doesn't exist.
---@param text string
---@return omichat.Interpolator
---@static
function Interpolator.getOrCreate(text)
    local item = Interpolator._cache:get(text) ---@cast item omichat.utils.InterpolatorCacheData
    return item.interpolator
end

---Registers an interpolator function.
---@param name string
---@param f fun(interpolator: omichat.Interpolator, ...: unknown)
---@static
function Interpolator.register(name, f)
    Interpolator._registered[name] = f
end

---Creates a cache item for the interpolator cache.
---@param _ unknown?
---@param text string
---@return omichat.utils.InterpolatorCacheData
---@protected
function Interpolator._createCacheItem(_, text)
    local interpolator = Interpolator:new()
    interpolator:setPattern(text)

    return {
        text = text,
        interpolator = interpolator,
    }
end


---Creates a new interpolator.
---@param options omi.Args.Interpolator?
---@return omichat.Interpolator
function Interpolator:new(options)
    options = lib.copy(options)
    options.caseSensitiveFunctions = lib.default(options.caseSensitiveFunctions, true)
    options.libraryExtra = lib.extend(lib.copy(options.libraryExtra or {}), Interpolator.Library)

    local this = BaseInterpolator.new(self, options)

    this._checkNumericTokens = true
    setmetatable(this._functions, FUNCTION_MT)

    ---@cast this omichat.Interpolator
    return this
end


Interpolator._cache:setOnCreateItem(nil, Interpolator._createCacheItem)
return Interpolator
