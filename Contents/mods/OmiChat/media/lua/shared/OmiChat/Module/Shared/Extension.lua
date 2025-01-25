---Handles extension of mod functionality.

local API = require 'OmiChat/Module/Shared/Core' ---@class omichat.api.shared

local utils = API.utils


---@class omichat.api.shared.extension
local Extension = {}


---Adds a function that should be available to all interpolator patterns.
---@param name string
---@param func function
function Extension.registerInterpolatorFunction(name, func)
    utils.Interpolator.register(name, func)
end


API.extension = Extension
return Extension
