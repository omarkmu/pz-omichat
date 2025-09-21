---Handles dispatching server commands to clients.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server
local config = API.Configuration
local SINGLEPLAYER = not isServer()


---@class omichat.api.server.request
local Request = {}


---Instructs the client to report the result of drawing a card.
---@param player IsoPlayer
---@param card integer
---@param suit integer
function Request.reportDrawCard(player, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { card = card, suit = suit }

    Request._dispatch('reportDrawCard', player, req)
end

---Instructs all clients to report the result of drawing a card.
---@param name string
---@param card integer
---@param suit integer
function Request.reportDrawCardGlobal(name, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { name = name, card = card, suit = suit }

    Request._dispatchAll('reportDrawCard', req)
end

---Instructs the client to report the result of a coin flip.
---@param player IsoPlayer
---@param heads boolean
function Request.reportFlipCoin(player, heads)
    ---@type omichat.request.ReportFlipCoin
    local req = { heads = heads }

    Request._dispatch('reportFlipCoin', player, req)
end

---Instructs the client to report the result of a dice roll.
---@param player IsoPlayer
---@param roll integer
---@param sides integer
function Request.reportRoll(player, roll, sides)
    ---@type omichat.request.ReportRoll
    local req = { roll = roll, sides = sides }

    Request._dispatch('reportRoll', player, req)
end

---Sends the configuration to the given player.
---If no player is given, configuration is sent to all players.
---@param player IsoPlayer?
function Request.sendConfiguration(player)
    ---@type omichat.request.UpdateConfiguration
    local req = { value = config:getValues() }

    if player then
        Request._dispatch('updateConfiguration', player, req)
    else
        Request._dispatchAll('updateConfiguration', req)
    end
end

---Sends the user-defined configuration presets to the given player.
---If no player is given, presets are sent to all players.
---@param player IsoPlayer?
function Request.sendPresets(player)
    ---@type omichat.request.UpdatePresets
    local req = { list = config:getCustomPresetsSimple() }

    if player then
        Request._dispatch('updatePresets', player, req)
    else
        Request._dispatchAll('updatePresets', req)
    end
end

---Notifies the client about another typing player.
---@param player IsoPlayer
---@param target IsoPlayer
---@param isTyping boolean
function Request.sendTyping(player, target, isTyping)
    ---@type omichat.request.UpdateTyping
    local req = { username = target:getUsername(), typing = isTyping }

    Request._dispatch('updateTyping', player, req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param text string
---@param serverAlert boolean?
function Request.sendInfoMessage(player, text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    Request._dispatch('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param text string
---@param serverAlert boolean?
function Request.sendServerMessage(text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    Request._dispatchAll('showInfoMessage', req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function Request.sendTranslatedInfoMessage(player, stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    Request._dispatch('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function Request.sendTranslatedServerMessage(stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    Request._dispatchAll('showInfoMessage', req)
end

---Sends a request to all players to update the player cache.
---@param items omi.PlayerCacheData[]
function Request.updatePlayerCache(items)
    local req = { items = items } ---@type omichat.request.UpdatePlayerCache

    Request._dispatchAll('updatePlayerCache', req)
end


---Dispatches a server command to the given player.
---@param player IsoPlayer
---@param command string
---@param args table?
---@private
function Request._dispatch(command, player, args)
    if SINGLEPLAYER then
        Request._dispatchAll(command, args)
        return
    end

    sendServerCommand(player, API._key, command, args or {})
end

---Dispatches a server command to all players.
---@param command string
---@param args table?
---@private
function Request._dispatchAll(command, args)
    if SINGLEPLAYER then
        local _API = API --[[@as omichat.api.client]]
        _API._onServerCommand(API._key, command, args or {}) ---@diagnostic disable-line: invisible
        return
    end

    sendServerCommand(API._key, command, args or {})
end

API.request = Request
return Request
