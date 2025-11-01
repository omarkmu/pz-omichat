---Interpolation function library.
---@namespace omichat

---@class(partial) InterpolationLibrary
local Library = {}

---Contains handlers for the `$Default` interpolation function.
---@class(partial) InterpolationLibrary.Defaults
Library.Defaults = {}

---Contains helper functions for the interpolation library.
Library.Helpers = require 'OmiChat/Module/InterpolationLibrary/Helpers'


return Library
