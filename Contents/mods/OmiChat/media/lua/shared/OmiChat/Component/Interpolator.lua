---Handles interpolation operations.

local lib = require 'OmiLibrary'
local BaseInterpolator = lib.interpolate.Interpolator

local getTimestampMs = getTimestampMs


---@class omichat.Interpolator : omi.Interpolator
local Interpolator = BaseInterpolator:derive()
Interpolator._cache = {}
Interpolator._registered = {}


local CACHE_EXPIRY_MS = 600000 -- ten minutes
local FUNCTION_MT = { __index = Interpolator._registered }


---Cleans up unused cache items.
---@param clear boolean If true, the cache will be cleared entirely.
function Interpolator.cleanupCache(clear)
    if clear then
        Interpolator._cache = {}
        return
    end

    local toRemove = {}
    local currentTime = getTimestampMs()
    for k, item in pairs(Interpolator._cache) do
        if currentTime - item.lastAccess >= CACHE_EXPIRY_MS then
            toRemove[#toRemove + 1] = k
        end
    end

    for i = 1, #toRemove do
        Interpolator._cache[toRemove[i]] = nil
    end
end

---Gets a cached interpolator, creating one if it doesn't exist.
---@param text string
---@return omichat.Interpolator
---@static
function Interpolator.getOrCreate(text)
    local item = Interpolator._cache[text]
    if item then
        item.lastAccess = getTimestampMs()
        return item.interpolator
    end

    local interpolator = Interpolator:new()
    interpolator:setPattern(text)
    Interpolator._cache[text] = {
        interpolator = interpolator,
        lastAccess = getTimestampMs(),
    }

    return interpolator
end

---Registers an interpolator function.
---@param name string
---@param f fun(interpolator: omichat.Interpolator, ...: unknown)
---@static
function Interpolator.register(name, f)
    Interpolator._registered[name] = f
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


return Interpolator
