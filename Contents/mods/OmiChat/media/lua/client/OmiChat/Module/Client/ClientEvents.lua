---Client-side event handlers.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'


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
    API.ui.getConfigPanel()
end

---Called on game start.
---@private
function API._onGameStart()
    API.chat.updateState(true)
end


Events.OnGameBoot.Add(API._onGameBoot)
Events.OnGameStart.Add(API._onGameStart)
Events.OnCreatePlayer.Add(API._onCreatePlayer)
