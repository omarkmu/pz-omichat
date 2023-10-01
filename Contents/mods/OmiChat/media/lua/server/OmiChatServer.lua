if not isServer() then return end


---Provides server API access to OmiChat.
---@class omichat.api.server : omichat.api.shared
local OmiChat = require 'OmiChatShared'


---Transmits mod data to clients.
function OmiChat.transmitModData()
    OmiChat.getModData()
    ModData.transmit(OmiChat._modDataKey)
end


Events.SendCustomModData.Add(OmiChat.transmitModData)
return OmiChat
