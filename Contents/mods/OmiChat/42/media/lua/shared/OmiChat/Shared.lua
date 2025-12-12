---Shared API.
---@namespace omichat

---@class(partial) api.shared
local API = require 'OmiChat/Module/Shared/Core'

require 'OmiChat/Module/Shared/Data'
require 'OmiChat/Module/Shared/Extension'
require 'OmiChat/Module/Shared/Hooks'
require 'OmiChat/Module/Shared/Languages'
require 'OmiChat/Module/Shared/Request'
require 'OmiChat/InterpolationLibrary'

require 'OmiChat/Module/Shared/SharedEvents'

return API
