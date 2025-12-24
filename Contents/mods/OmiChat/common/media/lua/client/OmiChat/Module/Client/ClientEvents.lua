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
        API.player._obj = player
        API.ui.updateInfoText(player)
    end
end

---Called on game start.
---@private
function API._onGameStart()
    API.chat.updateState(true)
end


Events.OnGameStart.Add(API._onGameStart)
Events.OnCreatePlayer.Add(API._onCreatePlayer)
