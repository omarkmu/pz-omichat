---API functionality available on both the client and server.
---@namespace omichat
---@class(partial) api.shared
local API = {}

---The mod identifier key.
---Used for mod data and the request dispatcher.
---@protected
API._key = 'omichat'


---Contains various utility functions.
API.utils = require 'OmiChat/Utils'

---Helper for managing and retrieving mod configuration.
API.Configuration = require 'OmiChat/Component/Configuration'

---Helper for formatting text with invisible metadata.
API.MetaFormatter = require 'OmiChat/Component/MetaFormatter'


return API
