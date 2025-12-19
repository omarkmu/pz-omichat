---Handles dispatching server commands to clients.
---@namespace omichat

if isClient() then return end

---@class(partial) api.server
local API = require 'OmiChat/Module/Server/Core'


---@class api.server.request : api.shared.request
local Request = API.request
local Topic = Request.TOPIC

---Contains functions for sending requests to the client.
API.request = Request

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
    ---@type request.Args.UpdateTyping
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
    ---@type request.Args.ShowMessage
    local args = { text = text, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:toPlayer(player, args)
end

---Sends an info message that will show for all players.
---@param text string
---@param serverAlert boolean?
---@return boolean success
---@return string? error
function Request.sendServerMessage(text, serverAlert)
    ---@type request.Args.ShowMessage
    local args = { text = text, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:broadcast(args)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param stringID string
---@param stringArgs omi.TranslateTableArgs<string | number>?
---@param serverAlert boolean?
---@return boolean success
---@return string? error
function Request.sendTranslatedInfoMessage(player, stringID, stringArgs, serverAlert)
    ---@type request.Args.ShowMessage
    local args = { id = stringID, args = stringArgs, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:toPlayer(player, args)
end

---Sends an info message that will show for all players.
---@param stringID string
---@param stringArgs omi.TranslateTableArgs<string | number>?
---@param serverAlert boolean?
---@return boolean success
---@return string? error
function Request.sendTranslatedServerMessage(stringID, stringArgs, serverAlert)
    ---@type request.Args.ShowMessage
    local args = { id = stringID, args = stringArgs, serverAlert = serverAlert }

    return Topic.SHOW_MESSAGE:broadcast(args)
end

---Sends a request to all players to update the player cache.
---@return boolean success
---@return string? error
function Request.updatePlayerCache() return Topic.PLAYER_CACHE:broadcast() end


return Request
