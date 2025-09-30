---Handles making client command requests to the server.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client


---@class omichat.api.client.request : omichat.api.shared.request
local Request = API.request
local Topic = Request.TOPIC


---Requests adding a user-defined configuration preset to the list.
---@param name string
---@param values table
---@return boolean success
---@return string? error
function Request.addPreset(name, values)
    ---@type omichat.request.AddOrRemovePreset
    local args = { type = 'ADD', name = name, values = values }

    return Topic.CONFIGURATION_PRESETS:toServer(args)
end

---Requests clearing mod data for a given username.
---@param username string
---@return boolean success
---@return string? error
function Request.clearData(username)
    ---@type omichat.request.ClearModData
    local args = { username = username }

    return Topic.DATA_CLEAR:toServer(args)
end

---Requests drawing a card from a card deck in the player's inventory.
---@return boolean success
---@return string? error
function Request.drawCard() return Topic.DRAW_CARD:toServer() end

---Sends a request to execute a chat command.
---@param command omichat.request.CommandName
---@param text string?
---@return boolean success
---@return string? error
function Request.executeCommand(command, text)
    ---@type omichat.request.Command
    local args = { name = command, text = text or '' }

    return Topic.COMMAND:toServer(args)
end

---Requests flipping a coin.
---@return boolean success
---@return string? error
function Request.flipCoin() return Topic.FLIP_COIN:toServer() end

---Requests a list of player mod data.
---@return boolean success
---@return string? error
function Request.getDataList() return Topic.DATA_LIST:toServer() end

---Requests rolling dice.
---@param sides integer
---@return boolean success
---@return string? error
function Request.rollDice(sides)
    ---@type omichat.request.RollDice
    local args = { sides = sides }

    return Topic.ROLL_DICE:toServer(args)
end

---Requests an update to global mod data.
---@param updates omichat.request.ModDataUpdate
---@return boolean success
---@return string? error
function Request.updateData(updates) return Topic.DATA_UPDATE:toServer(updates) end

---Requests that the server updates the player cache.
---@return boolean success
---@return string? error
function Request.updatePlayerCache() return Topic.PLAYER_CACHE:toServer() end

---Requests removing a user-defined configuration preset to the list.
---@param name string
---@return boolean success
---@return string? error
function Request.removePreset(name)
    ---@type omichat.request.AddOrRemovePreset
    local args = { type = 'DELETE', name = name }

    return Topic.CONFIGURATION_PRESETS:toServer(args)
end

---Sets the mod data for the given username.
---@param username string
---@param data omichat.PlayerModData?
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
---@return boolean success
---@return string? error
function Request.updateConfiguration() return Topic.CONFIGURATION:toServer() end

---Sends the current typing status to the server.
---@param range integer?
---@param chatType omichat.ChatTypeString?
---@return boolean success
---@return string? error
function Request.updateTypingStatus(range, chatType)
    ---@type omichat.request.Typing
    local args = { range = range, chatType = chatType, typing = API.chat.isTyping() }

    return Topic.TYPING:toServer(args)
end


API.request = Request
return Request
