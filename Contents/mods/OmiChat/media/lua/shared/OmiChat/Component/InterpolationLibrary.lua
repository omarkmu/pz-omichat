---Format string function library.


local Library = require 'OmiChat/Component/InterpolationLibrary/Core'


require 'OmiChat/Component/InterpolationLibrary/Defaults'
require 'OmiChat/Component/InterpolationLibrary/Utility'


local Interpolator = require 'OmiChat/Component/Interpolator' ---@class omichat.Interpolator
Interpolator.Library = Library


return Library
