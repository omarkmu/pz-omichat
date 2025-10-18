---API functionality available on both the client and server.
---@class omichat.api.shared
local API = {}

---The mod identifier key.
---Used for mod data and the request dispatcher.
---@protected
API._key = 'omichat'


API.utils = require 'OmiChat/Utils'
API.Configuration = require 'OmiChat/Component/Configuration'
API.MetaFormatter = require 'OmiChat/Component/MetaFormatter'


return API
