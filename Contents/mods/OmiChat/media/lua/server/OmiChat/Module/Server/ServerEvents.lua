---Server-side event handlers.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server


---Handler for processing commands from the client.
---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
---@private
function API._onClientCommand(module, command, player, args)
    if module ~= API._key then
        return
    end

    local handler = API.handlers[command]
    if handler then
        handler(player, args)
    end
end

---Handler for a scheduled update of the player cache.
---@private
function API._refreshCache()
    API.request.updatePlayerCache(API.data.refreshPlayerCache())
end


Events.EveryTenMinutes.Add(API._refreshCache)
Events.OnClientCommand.Add(API._onClientCommand)
Events.SendCustomModData.Add(API.data.transmit)
