---Interpolation function library.
---@namespace omichat
---@diagnostic disable: access-invisible


local Library = require 'OmiChat/Module/InterpolationLibrary/Core'
local utils = require 'OmiChat/Utils'

require 'OmiChat/Module/InterpolationLibrary/Defaults'
require 'OmiChat/Module/InterpolationLibrary/Utility'


utils._interpolator:addLibraries(Library --[[@as table]])
utils._noEntityInterpolator:addLibraries(Library --[[@as table]])

return Library
