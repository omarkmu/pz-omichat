---Handles making client command requests to the server.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'


---@class api.client.request : api.shared.request
local Request = API.request
local Topic = Request.TOPIC

---Contains functions for sending requests to the server.
API.request = Request


---Requests adding a user-defined configuration preset to the list.
---Fails if the local player is not an admin.
---@param name string The name of the preset.
---@param values table The configuration values.
---@return boolean success
---@return string? error
function Request.addPreset(name, values)
    ---@type request.Args.AddOrRemovePreset
    local args = { type = 'ADD', name = name, values = values }

    return Topic.CONFIGURATION_PRESETS:toServer(args)
end

---Requests clearing all player data for a username.
---Fails if the local player is not an admin.
---@param username string The username to clear data for.
---@return boolean success
---@return string? error
function Request.clearData(username)
    ---@type request.Args.ClearPlayerData
    local args = { username = username }

    return Topic.DATA_CLEAR:toServer(args)
end

---Requests drawing a card from a card deck in the player's inventory.
---@return boolean success
---@return string? error
function Request.drawCard() return Topic.DRAW_CARD:toServer() end

---Sends a request to execute a chat command.
---@param command request.ChatCommandName The name of the command to execute.
---@param text string? The command text, excluding the command. Defaults to the empty string.
---@return boolean success
---@return string? error
function Request.executeCommand(command, text)
    ---@type request.Args.Command
    local args = { name = command, text = text or '' }

    return Topic.COMMAND:toServer(args)
end

---Requests flipping a coin.
---@return boolean success
---@return string? error
function Request.flipCoin() return Topic.FLIP_COIN:toServer() end

---Requests a list of player data.
---Fails if the local player is not an admin.
---@return boolean success
---@return string? error
function Request.getPlayerDataList() return Topic.DATA_LIST:toServer() end

---Requests rolling dice.
---@param sides integer The number of sides on the die.
---@return boolean success
---@return string? error
function Request.rollDice(sides)
    ---@type request.Args.RollDice
    local args = { sides = sides }

    return Topic.ROLL_DICE:toServer(args)
end

---Requests deleting a user-defined configuration preset.
---Fails if the local player is not an admin.
---@param name string The name of the preset to remove.
---@return boolean success
---@return string? error
function Request.removePreset(name)
    ---@type request.Args.AddOrRemovePreset
    local args = { type = 'DELETE', name = name }

    return Topic.CONFIGURATION_PRESETS:toServer(args)
end

---Requests setting player data to a given table.
---Fails if the local player is not an admin.
---@param username string The username of the player to update data for.
---@param data PlayerData The new player data.
---@return boolean success
---@return string? error
function Request.setPlayerData(username, data)
    return Request.updateData({
        target = username,
        field = 'all',
        value = data,
    })
end

---Sends updated configuration values to the server.
---Fails if the local player is not an admin.
---@return boolean success
---@return string? error
function Request.updateConfiguration() return Topic.CONFIGURATION:toServer() end

---Requests an update to player data.
---@param args request.Args.PlayerDataUpdate Arguments for the update.
---@return boolean success
---@return string? error
function Request.updateData(args) return Topic.DATA_UPDATE:toServer(args) end

---Requests that the server broadcasts a player cache update.
---@return boolean success
---@return string? error
function Request.updatePlayerCache() return Topic.PLAYER_CACHE:toServer() end

---Sends the current typing status to the server.
---@param range integer? The range of the current chat stream.
---@param chatType omi.ChatTypeString? The chat type of the current chat stream.
---@return boolean success
---@return string? error
function Request.updateTypingStatus(range, chatType)
    ---@type request.Args.Typing
    local args = { range = range, chatType = chatType, typing = API.chat.isTyping() }

    return Topic.TYPING:toServer(args)
end


return Request
