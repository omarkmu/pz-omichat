local lib = require 'OmiLibrary'
local BaseInterpolator = lib.interpolate.Interpolator


---@class omichat.Interpolator : omi.Interpolator
---@field private _registeredFunctions table<string, function>
local Interpolator = BaseInterpolator:derive()
Interpolator._registeredFunctions = {}


local FUNCTION_MT = { __index = Interpolator._registeredFunctions }


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
