---Shared event handlers.

local API = require 'OmiChat/Module/Shared/Core' ---@class omichat.api.shared

Events.EveryDays.Add(API.utils.Interpolator.cleanupCache)
