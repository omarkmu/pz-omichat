---Client API functionality related to dispatching commands to the server.


---@class omichat.ISChat
local ISChat = ISChat

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'


---Dispatches a client command.
---@param command string
---@param player IsoPlayer?
---@param args table
---@return boolean success Whether the command was successfully sent.
local function dispatchCommand(command, player, args)
    player = player or getSpecificPlayer(0)
    if not player then
        return false
    end

    sendClientCommand(player, OmiChat._modDataKey, command, args)
    return true
end


---Informs the server that a player was created.
---@param player IsoPlayer
function OmiChat.informPlayerCreated(player)
    return dispatchCommand('informPlayerCreated', player, {})
end

---Requests an update to global mod data.
---@param player IsoPlayer?
---@param updates ModDataUpdateRequest
function OmiChat.requestDataUpdate(player, updates)
    return dispatchCommand('requestDataUpdate', player, updates)
end
