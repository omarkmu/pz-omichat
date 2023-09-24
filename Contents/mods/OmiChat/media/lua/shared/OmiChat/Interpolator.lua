local lib = require 'OmiChat/lib'
local BaseInterpolator = lib.interpolate.Interpolator
local InterpolationParser = lib.interpolate.Parser

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

---Returns a list of the top-level tokens in the interpolator's pattern.
---@return string[]
function Interpolator:getTopLevelTokens()
    if not self._built then
        return {}
    end

    local tokens = {}
    for _, node in pairs(self._built) do
        if node.type == InterpolationParser.NodeType.token then
            tokens[#tokens + 1] = node.value
        end
    end

    return tokens
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
