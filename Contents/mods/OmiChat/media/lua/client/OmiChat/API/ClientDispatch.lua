---Client API functionality related to dispatching commands to the server.


---@class omichat.ISChat
local ISChat = ISChat

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'


---Dispatches a client command.
---@param command string
---@param player IsoPlayer
---@param args table?
---@return boolean success Whether the command was successfully sent.
local function dispatchCommand(command, player, args)
    player = player or getSpecificPlayer(0)
    if not player then
        return false
    end

    sendClientCommand(player, OmiChat._modDataKey, command, args or {})
    return true
end


---Executes the /clearnames command.
---@param player IsoPlayer
function OmiChat.sendClearNames(player)
    return dispatchCommand('clearNames', player)
end

---Informs the server that a player was created.
---@param player IsoPlayer
function OmiChat.informPlayerCreated(player)
    return dispatchCommand('informPlayerCreated', player)
end

---Requests an update to global mod data.
---@param player IsoPlayer
---@param updates omichat.ModDataUpdateRequest
function OmiChat.requestDataUpdate(player, updates)
    return dispatchCommand('requestDataUpdate', player, updates)
end

---Requests drawing a card from a card deck in the player's inventory.
---@param player IsoPlayer
---@return boolean
function OmiChat.requestDrawCard(player)
    return dispatchCommand('requestDrawCard', player)
end

---Requests rolling dice in the player's inventory.
---@param player IsoPlayer
---@return boolean
function OmiChat.requestRollDice(player, sides)
    return dispatchCommand('requestRollDice', player, { sides = sides })
end

---Executes the /setname command.
---@param player IsoPlayer
---@param command string
function OmiChat.sendSetName(player, command)
    return dispatchCommand('setName', player, { command = command })
end

---Executes the /resetname command.
---@param player IsoPlayer
---@param command string
function OmiChat.sendResetName(player, command)
    return dispatchCommand('resetName', player, { command = command })
end
