---Interpolation function library.

local Interpolator = require 'OmiChat/Component/Interpolator' ---@class omichat.Interpolator
local Library = require 'OmiChat/Module/InterpolationLibrary/Core'

require 'OmiChat/Module/InterpolationLibrary/Defaults'
require 'OmiChat/Module/InterpolationLibrary/Utility'


Interpolator.Library = Library


return Library
