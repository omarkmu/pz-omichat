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


---Informs the server that a player was created.
---@param player IsoPlayer
function OmiChat.informPlayerCreated(player)
    return dispatchCommand('informPlayerCreated', player)
end

---Executes the /clearnames command.
---@param player IsoPlayer
function OmiChat.requestClearNames(player)
    return dispatchCommand('requestClearNames', player)
end

---Requests an update to global mod data.
---@param player IsoPlayer
---@param updates omichat.request.ModDataUpdate
function OmiChat.requestDataUpdate(player, updates)
    return dispatchCommand('requestDataUpdate', player, updates)
end

---Requests drawing a card from a card deck in the player's inventory.
---@param player IsoPlayer
---@return boolean
function OmiChat.requestDrawCard(player)
    local inv = player:getInventory()
    if not inv:contains('CardDeck') and player:getAccessLevel() == 'None' then
        return false
    end

    return dispatchCommand('requestDrawCard', player)
end

---Executes the /resetname command.
---@param player IsoPlayer
---@param command string
function OmiChat.requestResetName(player, command)
    ---@type omichat.request.Command
    local req = { command = command }

    return dispatchCommand('requestResetName', player, req)
end

---Requests rolling dice.
---@param player IsoPlayer
---@param sides integer
---@return boolean
function OmiChat.requestRollDice(player, sides)
    local inv = player:getInventory()
    if not inv:contains('Dice') and player:getAccessLevel() == 'None' then
        return false
    end

    if not sides or sides < 1 or sides > 100 then
        return false
    end

    ---@type omichat.request.RollDice
    local req = { sides = sides }

    return dispatchCommand('requestRollDice', player, req)
end

---Executes the /setname command.
---@param player IsoPlayer
---@param command string
function OmiChat.requestSetName(player, command)
    ---@type omichat.request.Command
    local req = { command = command }

    return dispatchCommand('requestSetName', player, req)
end
