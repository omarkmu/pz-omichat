if not isServer() then return end


---Provides server API access to OmiChat.
---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'

require 'OmiChat/API/ServerCommands'
require 'OmiChat/API/ServerData'

Events.OnClientCommand.Add(OmiChat._onClientCommand)
Events.SendCustomModData.Add(OmiChat.transmitModData)

return OmiChat
