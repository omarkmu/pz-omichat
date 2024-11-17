---Provides API access to OmiChat.
---@class omichat.api.shared
local API = require 'OmiChat/API/Shared/Core'

require 'OmiChat/API/Shared/Languages'
require 'OmiChat/Component/InterpolatorLibrary'

Events.EveryDays.Add(API.utils.cleanupCache)


return API
