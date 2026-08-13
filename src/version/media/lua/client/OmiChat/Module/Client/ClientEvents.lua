---Client-side event handlers.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'

local CustomSandboxUI = require 'OmiChat/Component/UI/CustomSandboxUI'


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

    -- only inject into the ingame sandbox UI,
    -- not the host menu one
    API.utils.ui.injectSandboxPage({
        name = 'OmiChat',
        ui = CustomSandboxUI,
    })
end


Events.OnGameStart.Add(API._onGameStart)
Events.OnCreatePlayer.Add(API._onCreatePlayer)
