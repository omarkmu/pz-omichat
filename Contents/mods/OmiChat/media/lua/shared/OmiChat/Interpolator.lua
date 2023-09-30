local lib = require 'OmiChat/lib'
local BaseInterpolator = lib.interpolate.Interpolator

---@class omichat.Interpolator : omi.interpolate.Interpolator
---@field private _registeredFunctions table<string, function>
local Interpolator = BaseInterpolator:derive()
Interpolator._registeredFunctions = {}


---Resolves a function given its name.
---@param name string
---@return function?
function Interpolator:getFunction(name)
    if Interpolator._registeredFunctions[name] and not self._functions[name] then
        return Interpolator._registeredFunctions[name]
    end

    return BaseInterpolator.getFunction(self, name)
end

---Gets the value of an interpolation token.
---@param token unknown
---@return unknown
function Interpolator:token(token)
    if self._tokens[token] then
        return self._tokens[token]
    end

    local num = tonumber(token)
    if num and self._tokens[num] then
        return self._tokens[num]
    end

    return BaseInterpolator.token(self, token)
end

---Sets the interpolation pattern to use and builds the interpolation tree.
---@param pattern string
function Interpolator:setPattern(pattern)
    pattern = (pattern or ''):gsub('&#(%d+);', function(x)
        local s, c = pcall(string.char, tonumber(x))
        return s and c or ''
    end)

    BaseInterpolator.setPattern(self, pattern)
end

---Creates a new interpolator.
---@param options omi.interpolate.Options
---@return omichat.Interpolator
function Interpolator:new(options)
    local this = BaseInterpolator.new(self, options)

    ---@cast this omichat.Interpolator
    return this
end


return Interpolator
