if not isServer() then return end


---Provides server API access to OmiChat.
---@class omichat.api.server
local API = require 'OmiChat/API/Server/Core'

require 'OmiChat/API/Server/Data'
require 'OmiChat/API/Server/Commands'

Events.OnClientCommand.Add(API._onClientCommand)
Events.SendCustomModData.Add(API.transmitModData)
Events.EveryTenMinutes.Add(API._refreshCache)

return API
