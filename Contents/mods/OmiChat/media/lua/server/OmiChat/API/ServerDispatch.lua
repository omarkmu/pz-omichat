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

---Dispatches a server command to all players.
---@param command string
---@param args table?
local function dispatchCommandToAll(command, args)
    sendServerCommand(OmiChat._modDataKey, command, args or {})
end


---Instructs the client to report the result of drawing a card.
---@param player IsoPlayer
---@param card integer
---@param suit integer
function OmiChat.reportDrawCard(player, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { card = card, suit = suit }

    dispatchCommand('reportDrawCard', player, req)
end

---Instructs all clients to report the result of drawing a card.
---@param name string
---@param card integer
---@param suit integer
function OmiChat.reportDrawCardGlobal(name, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { name = name, card = card, suit = suit }

    dispatchCommandToAll('reportDrawCard', req)
end

---Instructs the client to report the result of a dice roll.
---@param player IsoPlayer
---@param roll integer
---@param sides integer
function OmiChat.reportRoll(player, roll, sides)
    ---@type omichat.request.ReportRoll
    local req = { roll = roll, sides = sides }

    dispatchCommand('reportRoll', player, req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param text string
---@param serverAlert boolean?
function OmiChat.sendInfoMessage(player, text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    dispatchCommand('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param text string
---@param serverAlert boolean?
function OmiChat.sendServerMessage(text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    dispatchCommandToAll('showInfoMessage', req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function OmiChat.sendTranslatedInfoMessage(player, stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    dispatchCommand('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function OmiChat.sendTranslatedServerMessage(stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    dispatchCommandToAll('showInfoMessage', req)
end
