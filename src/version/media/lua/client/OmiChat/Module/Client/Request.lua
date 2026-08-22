---Handles making client command requests to the server.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'

local utils = API.utils


---@class api.client.request : api.shared.request
local Request = API.request
local Channel = Request.CHANNEL

---Contains functions for sending requests to the server.
API.request = Request


---Requests adding a user-defined configuration preset to the list.
---Fails if the local player is not an admin.
---@param name string The name of the preset.
---@param values table The configuration values.
---@return boolean success
---@return string? error
function Request.addPreset(name, values)
    ---@type Args.Request.AddOrRemovePreset
    local args = { type = 'ADD', name = name, values = values }

    return Channel.CONFIGURATION_PRESETS:toServer(args)
end

---Requests attempting to apply a buff.
---@return boolean success
---@return string? error
function Request.applyBuff() return Channel.APPLY_BUFF:toServer() end

---Requests applying a customization option.
---@param customizationType request.CustomizationType The customization to apply.
---@param args Partial<Args.Request.Customization>? Additional arguments for the customization.
---@return boolean success
---@return string? error
function Request.applyCustomization(customizationType, args)
    local _args = utils.copy(args --[[@as any]]) --[[@as Args.Request.Customization]]
    _args.type = customizationType

    return Channel.APPLY_CUSTOMIZATION:toServer(_args)
end

---Requests clearing all player data for a username.
---Fails if the local player is not an admin.
---@param username string The username to clear data for.
---@return boolean success
---@return string? error
function Request.clearData(username)
    ---@type Args.Request.ClearPlayerData
    local args = { username = username }

    return Channel.DATA_CLEAR:toServer(args)
end

---Requests drawing a card from a card deck in the player's inventory.
---@return boolean success
---@return string? error
function Request.drawCard() return Channel.DRAW_CARD:toServer() end

---Sends a request to execute a chat command.
---@param command request.ChatCommandName The name of the command to execute.
---@param text string? The command text, excluding the command. Defaults to the empty string.
---@return boolean success
---@return string? error
function Request.executeCommand(command, text)
    ---@type Args.Request.Command
    local args = { name = command, text = text or '' }

    return Channel.COMMAND:toServer(args)
end

---Requests flipping a coin.
---@return boolean success
---@return string? error
function Request.flipCoin() return Channel.FLIP_COIN:toServer() end

---Requests a list of player data.
---Fails if the local player is not an admin.
---@return boolean success
---@return string? error
function Request.getPlayerDataList() return Channel.DATA_LIST:toServer() end

---Requests rolling dice.
---@param command string The dice expression.
---@return boolean success
---@return string? error
function Request.rollDice(command)
    ---@type Args.Request.RollDice
    local args = { command = command }

    return Channel.ROLL_DICE:toServer(args)
end

---Requests deleting a user-defined configuration preset.
---Fails if the local player is not an admin.
---@param name string The name of the preset to remove.
---@return boolean success
---@return string? error
function Request.removePreset(name)
    ---@type Args.Request.AddOrRemovePreset
    local args = { type = 'DELETE', name = name }

    return Channel.CONFIGURATION_PRESETS:toServer(args)
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
function Request.updateConfiguration() return Channel.CONFIGURATION:toServer() end

---Requests an update to player data.
---@param args Args.Request.PlayerDataUpdate Arguments for the update.
---@return boolean success
---@return string? error
function Request.updateData(args) return Channel.DATA_UPDATE:toServer(args) end

---Requests that the server broadcasts a player cache update.
---@return boolean success
---@return string? error
function Request.updatePlayerCache() return Channel.PLAYER_CACHE:toServer() end

---Sends the current typing status to the server.
---@param range integer? The range of the current chat stream.
---@param chatType omi.ChatTypeString? The chat type of the current chat stream.
---@return boolean success
---@return string? error
function Request.updateTypingStatus(range, chatType)
    ---@type Args.Request.Typing
    local args = { range = range, chatType = chatType, typing = API.chat.isTyping() }

    return Channel.TYPING:toServer(args)
end


return Request
