---Client-side event handlers.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client


---Called when a player is created.
---@param playerNum integer
---@param player IsoPlayer
---@private
function API._onCreatePlayer(playerNum, player)
    if playerNum == 0 then
        API.ui.updateInfoText(player)
    end
end

---Called on game boot.
---Pregenerates the configuration UI.
---@private
function API._onGameBoot()
    API.ui.generateConfigPanel()
end

---Called on game start.
---@private
function API._onGameStart()
    API.chat.updateState(true)
end


Events.OnGameBoot.Add(API._onGameBoot)
Events.OnGameStart.Add(API._onGameStart)
Events.OnCreatePlayer.Add(API._onCreatePlayer)
