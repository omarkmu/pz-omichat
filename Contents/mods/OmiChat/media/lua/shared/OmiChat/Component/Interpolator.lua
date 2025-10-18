---@namespace omichat
---Handles interpolation operations.

local lib = require 'OmiLibrary'
local BaseInterpolator = lib.interpolate.Interpolator
local TEN_MINUTES = 60000

---Handles string interpolation.
---@class(partial) Interpolator : omi.Interpolator
local Interpolator = BaseInterpolator:derive()

---Contains registered interpolation functions.
---@type table<string, function>
---@private
Interpolator._registered = {}

---Cache for interpolators.
---@private
Interpolator._cache = lib.cache.new({
    primaryKey = 'text',
    ttl = TEN_MINUTES,
}) --[[@as omi.Cache<InterpolatorCacheData>]]

---Cache for interpolators that disallow character entities.
---@private
Interpolator._noEntityCache = lib.cache.new({
    primaryKey = 'text',
    ttl = TEN_MINUTES,
}) --[[@as omi.Cache<InterpolatorCacheData>]]


---Metatable for the interpolator function table.
local FUNCTION_MT = { __index = Interpolator._registered }


---Cleans up unused cache items.
---@param clear boolean If true, the cache will be cleared entirely.
function Interpolator.cleanupCache(clear)
    if clear then
        Interpolator._cache:clear()
        Interpolator._noEntityCache:clear()
        return
    end

    Interpolator._cache:update()
    Interpolator._noEntityCache:update()
end

---Gets a cached interpolator, creating one if it doesn't exist.
---@param text string The interpolation text.
---@param noEntities boolean? Flag for whether character entities should be disallowed for the interpolator.
---@return Interpolator
function Interpolator.getOrCreate(text, noEntities)
    local cache = noEntities and Interpolator._noEntityCache or Interpolator._cache
    local item = cache:get(text) ---@cast item -?
    return item.interpolator
end

---Registers an interpolator function.
---@param name string The name of the new interpolation function.
---@param func InterpolatorFunction The function to execute when the interpolation function is used.
function Interpolator.register(name, func)
    Interpolator._registered[name] = func
end

---Creates a cache item for the interpolator cache.
---@param _ any?
---@param text string
---@return InterpolatorCacheData
---@protected
function Interpolator._createCacheItem(_, text)
    local interpolator = Interpolator:new()
    interpolator:setPattern(text)

    return {
        text = text,
        interpolator = interpolator,
    }
end

---Creates a cache item for the entity-disallowed interpolator cache.
---@param _ any?
---@param text string
---@return InterpolatorCacheData
---@protected
function Interpolator._createNoEntityCacheItem(_, text)
    local interpolator = Interpolator:new({ allowCharacterEntities = false })
    interpolator:setPattern(text)

    return {
        text = text,
        interpolator = interpolator,
    }
end


---Creates a new interpolator.
---@param options omi.Args.Interpolator? Arguments for creation of the interpolator.
---@return Interpolator interpolator The new interpolator.
function Interpolator:new(options)
    options = lib.copy(options)
    options.caseSensitiveFunctions = options.caseSensitiveFunctions ~= false
    options.libraryExtra = lib.extend(lib.copy(options.libraryExtra or {}), Interpolator.Library --[[@as table]])

    local this = BaseInterpolator.new(self, options) --[[@as Interpolator]]

    this._checkNumericTokens = true
    setmetatable(this._functions, FUNCTION_MT)

    return this
end


Interpolator._cache:setOnCreateItem(nil, Interpolator._createCacheItem)
Interpolator._noEntityCache:setOnCreateItem(nil, Interpolator._createNoEntityCacheItem)
return Interpolator

--#region Type Definitions

---@class InterpolatorCacheData
---@field text string The interpolation text.
---@field interpolator Interpolator The interpolator to use.


---@alias InterpolatorFunction fun(interpolator: Interpolator, ...: any)

--#endregion
