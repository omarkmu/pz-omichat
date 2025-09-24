---Handles dispatching server commands to clients.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server


---@class omichat.api.server.request : omichat.api.shared.request
local Request = API.request
local Topic = Request.TOPIC


---Sends the configuration to the given player.
---If no player is given, configuration is sent to all players.
---@param player IsoPlayer?
---@return boolean success
---@return string? error
function Request.sendConfiguration(player) return Topic.CONFIGURATION:toPlayerOrBroadcast(player) end

---Sends the user-defined configuration presets to the given player.
---If no player is given, presets are sent to all players.
---@param player IsoPlayer?
---@return boolean success
---@return string? error
function Request.sendPresets(player) return Topic.CONFIGURATION_PRESETS:toPlayerOrBroadcast(player) end

---Notifies the client about another typing player.
---@param player IsoPlayer
---@param target IsoPlayer
---@param isTyping boolean
---@return boolean success
---@return string? error
function Request.sendTyping(player, target, isTyping)
    ---@type omichat.request.UpdateTyping
    local args = { username = target:getUsername(), typing = isTyping }

    return Topic.TYPING:toPlayer(player, args)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param text string
---@param serverAlert boolean?
---@return boolean success
---@return string? error
function Request.sendInfoMessage(player, text, serverAlert)
    ---@type omichat.request.ShowMessage
    local args = { text = text, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:toPlayer(player, args)
end

---Sends an info message that will show for all players.
---@param text string
---@param serverAlert boolean?
---@return boolean success
---@return string? error
function Request.sendServerMessage(text, serverAlert)
    ---@type omichat.request.ShowMessage
    local args = { text = text, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:broadcast(args)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param stringID string
---@param stringArgs string[]?
---@param serverAlert boolean?
---@return boolean success
---@return string? error
function Request.sendTranslatedInfoMessage(player, stringID, stringArgs, serverAlert)
    ---@type omichat.request.ShowMessage
    local args = { stringID = stringID, args = stringArgs, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:toPlayer(player, args)
end

---Sends an info message that will show for all players.
---@param stringID string
---@param stringArgs string[]?
---@param serverAlert boolean?
---@return boolean success
---@return string? error
function Request.sendTranslatedServerMessage(stringID, stringArgs, serverAlert)
    ---@type omichat.request.ShowMessage
    local args = { stringID = stringID, args = stringArgs, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:broadcast(args)
end

---Sends a request to all players to update the player cache.
---@return boolean success
---@return string? error
function Request.updatePlayerCache() return Topic.PLAYER_CACHE:broadcast() end


API.request = Request
return Request
