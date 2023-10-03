---Base server API.

if not isServer() then return end

---@class omichat.api.server : omichat.api.shared
local OmiChat = require 'OmiChatShared'


---Transmits mod data to clients.
function OmiChat.transmitModData()
    OmiChat.getModData()
    ModData.transmit(OmiChat._modDataKey)
end


return OmiChat
