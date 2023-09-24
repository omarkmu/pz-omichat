if not isServer() then return end

local OmiChatShared = require 'OmiChatShared'


---Provides server API access to OmiChat.
---@class omichat.api.server : omichat.api.shared
local OmiChat = OmiChatShared:derive()


---Transmits mod data to clients.
function OmiChat.transmitModData()
    OmiChat.getModData()
    ModData.transmit(OmiChat.modDataKey)
end


Events.SendCustomModData.Add(OmiChat.transmitModData)
return OmiChat
