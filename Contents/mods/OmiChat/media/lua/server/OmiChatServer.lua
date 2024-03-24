if not isServer() then return end


---Provides server API access to OmiChat.
---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'

require 'OmiChat/API/ServerData'
require 'OmiChat/API/ServerCommands'

Events.OnClientCommand.Add(OmiChat._onClientCommand)
Events.SendCustomModData.Add(OmiChat.transmitModData)

return OmiChat
