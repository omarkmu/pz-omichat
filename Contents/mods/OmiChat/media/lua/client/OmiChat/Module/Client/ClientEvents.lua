---Client-side event handlers.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local config = API.Configuration


---Called when a player is created.
---@param playerNum integer
---@param player IsoPlayer
---@private
function API._onCreatePlayer(playerNum, player)
    if playerNum == 0 then
        API.ui.updateInfoText(player)
        API.data.refreshLanguageInfo(player:getUsername())
    end
end

---Called on game start.
---@private
function API._onGameStart()
    API.chat.updateState(true)
    API.StatusManager.init()
end

---Called when receiving global mod data from the server.
---@param key string
---@param newData omichat.ModData
---@private
function API._onReceiveGlobalModData(key, newData)
    if type(newData) ~= 'table' then
        return
    end

    if key == API._key then
        local modData = API.data.get()
        for k in pairs(newData) do
            modData[k] = newData[k]
        end
    elseif key == API._configKey then
        config:load(newData)
        config:saveModData()
        return
    end
end


Events.OnGameStart.Add(API._onGameStart)
Events.OnCreatePlayer.Add(API._onCreatePlayer)
Events.OnReceiveGlobalModData.Add(API._onReceiveGlobalModData)
