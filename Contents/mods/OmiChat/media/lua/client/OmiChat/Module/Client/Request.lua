---Handles making client command requests to the server.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration

local getTexture = getTexture
local getSpecificPlayer = getSpecificPlayer
local sendClientCommand = sendClientCommand
local SINGLEPLAYER = not isClient()


---@class omichat.api.client.request
local Request = {}


---Executes the /addlanguage command.
---@param command string
---@return boolean success
function Request.addLanguage(command)
    ---@type omichat.request.Command
    local req = {
        name = 'addLanguage',
        text = command,
    }

    return Request._dispatch('executeCommand', req)
end

---Requests adding a user-defined configuration preset to the list.
---@param name string
---@param values table
---@return boolean success
function Request.addPreset(name, values)
    ---@type omichat.request.AddPreset
    local req = {
        name = name,
        values = values,
    }

    return Request._dispatch('requestAddPreset', req)
end

---Requests clearing mod data for a given username.
---@param username string
---@return boolean success
function Request.clearModData(username)
    ---@type omichat.request.ClearModData
    local req = { username = username }

    return Request._dispatch('requestClearModData', req)
end

---Executes the /clearnames command.
function Request.clearNames()
    ---@type omichat.request.Command
    local req = {
        name = 'clearNames',
        text = '',
    }

    return Request._dispatch('executeCommand', req)
end

---Requests drawing a card from a card deck in the player's inventory.
---@return boolean success
function Request.drawCard()
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config.Commands.Card.Items) then
        return false
    end

    return Request._dispatch('requestDrawCard')
end

---Requests flipping a coin.
---@return boolean success
function Request.flipCoin()
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config.Commands.Flip.Items) then
        return false
    end

    return Request._dispatch('requestFlipCoin')
end

---Reports to the server that the player died.
---@return boolean success
function Request.reportPlayerDeath()
    return Request._dispatch('playerDied')
end

---Reports to the server that the player joined.
---@return boolean success
function Request.reportPlayerJoined()
    return Request._dispatch('playerJoined')
end

---Executes the /reseticon command.
---@param command string
---@return boolean success
function Request.resetIcon(command)
    ---@type omichat.request.Command
    local req = {
        name = 'resetIcon',
        text = command,
    }

    return Request._dispatch('executeCommand', req)
end

---Requests rolling dice.
---@param sides integer
---@return boolean success
function Request.rollDice(sides)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config.Commands.Roll.Items) then
        return false
    end

    if not sides or sides < 1 or sides > 100 then
        return false
    end

    ---@type omichat.request.RollDice
    local req = { sides = sides }

    return Request._dispatch('requestRollDice', req)
end

---Requests an update to global mod data.
---@param updates omichat.request.ModDataUpdate
---@return boolean success
function Request.updateData(updates)
    return Request._dispatch('requestDataUpdate', updates)
end

---Requests that the server updates the player cache.
---@return boolean success
function Request.updatePlayerCache()
    return Request._dispatch('requestPlayerCacheUpdate')
end

---Requests removing a user-defined configuration preset to the list.
---@param name string
---@return boolean success
function Request.removePreset(name)
    ---@type omichat.request.RemovePreset
    local req = {
        name = name,
    }

    return Request._dispatch('requestRemovePreset', req)
end


---Executes the /resetlanguages command.
---@param command string
---@return boolean success
function Request.resetLanguages(command)
    ---@type omichat.request.Command
    local req = {
        name = 'resetLanguages',
        text = command,
    }

    return Request._dispatch('executeCommand', req)
end

---Executes the /resetname command.
---@param command string
---@return boolean success
function Request.resetName(command)
    ---@type omichat.request.Command
    local req = {
        name = 'resetName',
        text = command,
    }

    return Request._dispatch('executeCommand', req)
end

---Executes the /seticon command.
---@param command string
---@return boolean success
function Request.setIcon(command)
    -- need to validate texture client-side
    local args = utils.parseCommandArgs(command)
    local username = args[1]
    local icon = args[2]

    if not username or not icon then
        return false
    end

    if not getTexture(icon) then
        local textureName = utils.getTextureNameFromIcon(icon)
        if textureName and getTexture(textureName) then
            command = string.format('%q', username) .. ' ' .. textureName
        else
            return false
        end
    end

    ---@type omichat.request.Command
    local req = {
        name = 'setIcon',
        text = command,
    }

    return Request._dispatch('executeCommand', req)
end

---Executes the /setlanguageslots command.
---@param command string
---@return boolean success
function Request.setLanguageSlots(command)
    ---@type omichat.request.Command
    local req = {
        name = 'setLanguageSlots',
        text = command,
    }

    return Request._dispatch('executeCommand', req)
end

---Sets the mod data for the given username.
---@param username string
---@param data omichat.PlayerModData?
function Request.setModData(username, data)
    API.data.set(username, data)

    Request.updateData({
        target = username,
        field = 'all',
        value = data,
    })
end

---Executes the /setname command.
---@param command string
---@return boolean success
function Request.setName(command)
    ---@type omichat.request.Command
    local req = {
        name = 'setName',
        text = command,
    }

    return Request._dispatch('executeCommand', req)
end

---Sends updated configuration values to the server.
---@return boolean success
function Request.updateConfiguration()
    if not isAdmin() then
        return false
    end

    ---@type omichat.request.UpdateConfiguration
    local req = { value = config:getValues() }

    return Request._dispatch('updateConfiguration', req)
end

---Sends the current typing status to the server.
---@param range integer?
---@param chatType omichat.ChatTypeString?
---@return boolean success
function Request.updateTypingStatus(range, chatType)
    ---@type omichat.request.Typing
    local req = {
        range = range,
        chatType = chatType,
        typing = API.chat.isTyping(),
    }

    return Request._dispatch('requestTyping', req)
end


---Dispatches a client command.
---@param command string
---@param args table?
---@return boolean success Whether the command was successfully sent.
---@private
function Request._dispatch(command, args)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:isDead() and command ~= 'playerDied' then
        -- prevent processing commands while dead
        return false
    end

    if SINGLEPLAYER then
        local _API = API --[[@as omichat.api.server]]
        _API._onClientCommand(API._key, command, player, args or {}) ---@diagnostic disable-line: invisible
        return true
    end

    sendClientCommand(player, API._key, command, args or {})
    return true
end


API.request = Request
return Request
