---Server API functionality related to dispatching commands to the client.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'


---Dispatches a server command.
---@param player IsoPlayer
---@param command string
---@param args table?
local function dispatchCommand(command, player, args)
    sendServerCommand(player, OmiChat._modDataKey, command, args or {})
end


---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param text string
---@param serverAlert boolean?
function OmiChat.sendInfoMessage(player, text, serverAlert)
    dispatchCommand('showInfoMessage', player, { text = text, serverAlert = serverAlert, })
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param stringID string
---@param args string[]?
function OmiChat.sendTranslatedInfoMessage(player, stringID, args)
    dispatchCommand('showInfoMessage', player, { stringID = stringID, args = args, })
end
