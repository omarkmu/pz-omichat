---Client API functionality related to dispatching commands to the server.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'


---Dispatches a client command.
---@param command string
---@param args table?
---@return boolean success Whether the command was successfully sent.
local function dispatchCommand(command, args)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    sendClientCommand(player, OmiChat._modDataKey, command, args or {})
    return true
end


---Executes the /addlanguage command.
---@param command string
---@return boolean
function OmiChat.requestAddLanguage(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return dispatchCommand('requestAddLanguage', req)
end

---Executes the /clearnames command.
function OmiChat.requestClearNames()
    return dispatchCommand('requestClearNames')
end

---Requests an update to global mod data.
---@param updates omichat.request.ModDataUpdate
---@return boolean
function OmiChat.requestDataUpdate(updates)
    return dispatchCommand('requestDataUpdate', updates)
end

---Requests drawing a card from a card deck in the player's inventory.
---@return boolean
function OmiChat.requestDrawCard()
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    local inv = player:getInventory()
    if not inv:contains('CardDeck') and player:getAccessLevel() == 'None' then
        return false
    end

    return dispatchCommand('requestDrawCard')
end

---Executes the /resetlanguages command.
---@param command string
---@return boolean
function OmiChat.requestResetLanguages(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return dispatchCommand('requestResetLanguages', req)
end

---Executes the /resetname command.
---@param command string
---@return boolean
function OmiChat.requestResetName(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return dispatchCommand('requestResetName', req)
end

---Requests rolling dice.
---@param sides integer
---@return boolean
function OmiChat.requestRollDice(sides)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    local inv = player:getInventory()
    if not inv:contains('Dice') and player:getAccessLevel() == 'None' then
        return false
    end

    if not sides or sides < 1 or sides > 100 then
        return false
    end

    ---@type omichat.request.RollDice
    local req = { sides = sides }

    return dispatchCommand('requestRollDice', req)
end

---Executes the /setlanguageslots command.
---@param command string
---@return boolean
function OmiChat.requestSetLanguageSlots(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return dispatchCommand('requestSetLanguageSlots', req)
end

---Executes the /setname command.
---@param command string
---@return boolean
function OmiChat.requestSetName(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return dispatchCommand('requestSetName', req)
end
