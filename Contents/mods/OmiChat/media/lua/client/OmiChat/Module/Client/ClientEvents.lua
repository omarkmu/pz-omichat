---Client-side event handlers.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local lib = API.utils.lib
local config = API.Configuration


---Called when configuration is saved to a file.
---@private
function API._onConfigurationSave()
    if API.chat and API.chat.updateState then
        API.chat.updateState(true)
    end
end

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
    if getDebug() and not isClient() then
        -- if we're running in singleplayer & debug, mock the chat
        local mock = lib.chat.Mock:new()
        mock:start()

        API.chat._mock = mock ---@diagnostic disable-line: invisible
        API.chat.raw = {
            say = processSayMessage,
            shout = processShoutMessage,
            whisper = proceedPM,
            general = processGeneralMessage,
            safehouse = processSafehouseMessage,
            faction = proceedFactionMessage,
            admin = processAdminChatMessage,
        }
    end

    API.chat.updateState(true)
    API.StatusManager.init()
end

---Called on player death.
---@param player IsoPlayer
---@private
function API._onPlayerDeath(player)
    if player ~= getSpecificPlayer(0) then
        return
    end

    -- reset nickname, icon, and languages
    API.request.reportPlayerDeath()

    local instance = ISChat.instance
    if instance then
        instance:unfocus()
        instance:close()
    end
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

---Called when configuration is saved from the editor form.
---@param args omi.forms.Args.Callback.Save
---@private
function API._onSaveConfiguration(args)
    config:load(args.values)
    API.request.updateConfiguration()

    -- save to mod data if testing in singleplayer
    if getDebug() and not isClient() then
        config:saveModData()
    end
end

---Called when processing commands from the server.
---@param module string
---@param command string
---@param args table
---@private
function API._onServerCommand(module, command, args)
    if module ~= API._key then
        return
    end

    local handler = API.handlers[command]
    if handler then
        handler(args)
    end
end

---Called on tick until the player has loaded.
---@private
function API._onTickTemporary()
    if not getSpecificPlayer(0) then
        return
    end

    Events.OnTick.Remove(API._onTickTemporary)
    API.request.reportPlayerJoined()
end


Events.OnGameStart.Add(API._onGameStart)
Events.OnCreatePlayer.Add(API._onCreatePlayer)
Events.OnPlayerDeath.Add(API._onPlayerDeath)
Events.OnServerCommand.Add(API._onServerCommand)
Events.OnReceiveGlobalModData.Add(API._onReceiveGlobalModData)
Events.OnTick.Add(API._onTickTemporary)
config:setOnSave(API._onConfigurationSave)
