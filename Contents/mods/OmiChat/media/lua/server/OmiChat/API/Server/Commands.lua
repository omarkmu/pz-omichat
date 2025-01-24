---Server API functionality related to dispatching and handling commands.

if not isServer() then return end


---@class omichat.api.server
local API = require 'OmiChat/API/Server/Core'

---@class omichat.api.server.commands
API.Commands = {}

local config = API.Configuration
local utils = API.utils

---@type table<omichat.ModDataField, function>
local updateModData = {}


---Checks whether a player has permission to execute a command for the given target.
---@param player IsoPlayer
---@param target string
---@param fromCommand boolean?
---@return boolean
local function canAccessTarget(player, target, fromCommand)
    if not target then
        return false
    end

    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if fromCommand and access < config.General.MinimumCommandAccessLevel then
        return false
    end

    if access == 1 and target ~= player:getUsername() then
        return false
    end

    return true
end

---Checks whether the given username belongs to a currently online player.
---@param username string
---@return boolean
local function isOnlinePlayer(username)
    if not username then
        return false
    end

    local player = utils.getPlayerByUsername(username)
    return player ~= nil
end

---Checks whether the typing indicator should be sent for a pair of players.
---@param player IsoPlayer
---@param otherPlayer IsoPlayer
---@param range integer?
---@param chatType omichat.ChatTypeString?
---@return boolean
local function shouldSendTyping(player, otherPlayer, range, chatType)
    if player:isInvisible() and not otherPlayer:isInvisible() then
        return false
    end

    if range then
        local xDiff = otherPlayer:getX() - player:getX()
        local yDiff = otherPlayer:getY() - player:getY()
        if math.sqrt(xDiff * xDiff + yDiff * yDiff) > range then
            return false
        end
    end

    if chatType == 'faction' then
        local faction = Faction.getPlayerFaction(player:getUsername())
        local other = otherPlayer:getUsername()

        return faction and (faction:isOwner(other) or faction:isMember(other))
    elseif chatType == 'safehouse' then
        local safehouse = SafeHouse.hasSafehouse(player:getUsername())
        return safehouse and safehouse:playerAllowed(otherPlayer:getUsername())
    end

    return true
end


---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.all(args)
    if not args.value then
        return false
    end

    API.setUserModData(args.target, args.value)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.currentLanguage(args)
    if not args.value then
        return false
    end

    return API.setCurrentRoleplayLanguage(args.target, args.value)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.icons(args)
    API.setChatIcon(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
function updateModData.languages(args)
    if not args.value then
        API.resetRoleplayLanguages(args.target)
        return true
    end

    return API.addRoleplayLanguage(args.target, args.value)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.languageSlots(args)
    local slots = tonumber(args.value)
    if not slots then
        return false
    end

    return API.setRoleplayLanguageSlots(args.target, slots)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.nicknames(args)
    if not config:isNicknameEnabled() and not args.fromCommand then
        return false
    end

    API.setNickname(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.statuses(args)
    if not config.Commands.Status.Enable and not args.fromCommand then
        return false
    end

    API.setStatus(args.target, args.value and tostring(args.value) or nil)
    return true
end


--#region dispatch

---Dispatches a server command.
---@param player IsoPlayer
---@param command string
---@param args table?
function API.dispatch(command, player, args)
    sendServerCommand(player, API._modDataKey, command, args or {})
end

---Dispatches a server command to all players.
---@param command string
---@param args table?
function API.dispatchAll(command, args)
    sendServerCommand(API._modDataKey, command, args or {})
end

---Instructs the client to report the result of drawing a card.
---@param player IsoPlayer
---@param card integer
---@param suit integer
function API.reportDrawCard(player, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { card = card, suit = suit }

    API.dispatch('reportDrawCard', player, req)
end

---Instructs all clients to report the result of drawing a card.
---@param name string
---@param card integer
---@param suit integer
function API.reportDrawCardGlobal(name, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { name = name, card = card, suit = suit }

    API.dispatchAll('reportDrawCard', req)
end

---Instructs the client to report the result of a coin flip.
---@param player IsoPlayer
---@param heads boolean
function API.reportFlipCoin(player, heads)
    ---@type omichat.request.ReportFlipCoin
    local req = { heads = heads }

    API.dispatch('reportFlipCoin', player, req)
end

---Instructs the client to report the result of a dice roll.
---@param player IsoPlayer
---@param roll integer
---@param sides integer
function API.reportRoll(player, roll, sides)
    ---@type omichat.request.ReportRoll
    local req = { roll = roll, sides = sides }

    API.dispatch('reportRoll', player, req)
end

---Sends the configuration to the given player.
---If no player is given, configuration is sent to all players.
---@param player IsoPlayer?
function API.sendConfiguration(player)
    ---@type omichat.request.UpdateConfiguration
    local req = { value = API.Configuration:getValues() }

    if player then
        API.dispatch('updateConfiguration', player, req)
    else
        API.dispatchAll('updateConfiguration', req)
    end
end

---Notifies the client about another typing player.
---@param player IsoPlayer
---@param target IsoPlayer
---@param isTyping boolean
function API.sendTyping(player, target, isTyping)
    ---@type omichat.request.UpdateTyping
    local req = { username = target:getUsername(), typing = isTyping }

    API.dispatch('updateTyping', player, req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param text string
---@param serverAlert boolean?
function API.sendInfoMessage(player, text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    API.dispatch('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param text string
---@param serverAlert boolean?
function API.sendServerMessage(text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    API.dispatchAll('showInfoMessage', req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function API.sendTranslatedInfoMessage(player, stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    API.dispatch('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function API.sendTranslatedServerMessage(stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    API.dispatchAll('showInfoMessage', req)
end


--#endregion

--#region handlers

---Handles player death.
---@param player IsoPlayer
function API.Commands.reportPlayerDeath(player)
    local username = player:getUsername()
    if not canAccessTarget(player, username) then
        return
    end

    local doTransmit = false
    local clearConfig = config.General.ClearOnDeath
    if clearConfig.Nickname then
        updateModData.nicknames({ target = username })
        doTransmit = true
    end

    if clearConfig.Icon then
        updateModData.icons({ target = username })
        doTransmit = true
    end

    if clearConfig.Languages then
        updateModData.languages({ target = username })
        doTransmit = true
    end

    if clearConfig.Status then
        updateModData.statuses({ target = username })
        doTransmit = true
    end

    if doTransmit then
        API.transmitModData()
    end
end

---Handles player join.
---@param player IsoPlayer
function API.Commands.reportPlayerJoined(player)
    API.Commands.requestPlayerCacheUpdate()
    API.sendConfiguration(player)
end

---Handles the /addlanguage command.
---@param player IsoPlayer
---@param args omichat.request.Command
function API.Commands.requestAddLanguage(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local language = args[2]

    local err
    local success = false
    if username and language then
        success, err = API.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
            value = language,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'FULL' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageFull', { username })
        elseif err == 'ALREADY_KNOW' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageKnown', { username, language })
        elseif err == 'UNKNOWN' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageNotConfigured', { language })
        elseif err == 'UNKNOWN_PLAYER' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_AddLanguage')
        end

        return
    end

    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_AddLanguageOther', { username, language })
end

---Handles the /clearnames command.
---@param player IsoPlayer
function API.Commands.requestClearNames(player)
    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if access < config.General.MinimumCommandAccessLevel then
        return
    end

    API.clearNicknames()
    API.transmitModData()
    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ClearNames')
end

---Handles a request to clear mod data for a given username.
---@param player IsoPlayer
---@param req omichat.request.ClearModData
function API.Commands.requestClearModData(player, req)
    if player:getAccessLevel() ~= 'Admin' then
        return
    end

    API.clearModData(req.username)
    API.transmitModData()
end

---Updates global mod data.
---@param player IsoPlayer
---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
function API.Commands.requestDataUpdate(player, args)
    local err
    local success = false
    if args.field ~= 'all' and not isOnlinePlayer(args.target) then
        return false, 'UNKNOWN_PLAYER'
    end

    if canAccessTarget(player, args.target, args.fromCommand) then
        local updateFunc = updateModData[args.field]
        if updateFunc then
            success, err = updateFunc(args)
        end
    end

    API.transmitModData()
    return success, err
end

---Handles the /card command.
---@param player IsoPlayer
function API.Commands.requestDrawCard(player)
    local suit = 1 + ZombRand(4)
    local card = 1 + ZombRand(13)

    if config.Commands.Card.Global then
        local name = API.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        API.reportDrawCardGlobal(name, card, suit)
    else
        API.reportDrawCard(player, card, suit)
    end
end

---Handles the /flip command.
---@param player IsoPlayer
function API.Commands.requestFlipCoin(player)
    local heads = ZombRand(2) == 0
    if config.Commands.Flip.Global then
        local name = API.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        API.sendTranslatedServerMessage('UI_OmiChat_Flip' .. (heads and 'Heads' or 'Tails'), { name })
    else
        API.reportFlipCoin(player, heads)
    end
end

---Updates player cache information.
function API.Commands.requestPlayerCacheUpdate()
    API._refreshCache()
end

---Handles the /reseticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function API.Commands.requestResetIcon(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = API.Commands.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetIcon')
        end

        return
    end

    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetIconOther', { username })
end

---Handles the /resetlanguages command.
---@param player IsoPlayer
---@param args omichat.request.Command
function API.Commands.requestResetLanguages(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = API.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetLanguages')
        end

        return
    end

    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetLanguagesOther', { username })
end

---Handles the /resetname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function API.Commands.requestResetName(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = API.Commands.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetName')
        end

        return
    end

    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetNameOther', { username })
end

---Handles the /roll command.
---@param player IsoPlayer
---@param args omichat.request.RollDice
function API.Commands.requestRollDice(player, args)
    local sides = tonumber(args.sides)
    if type(sides) ~= 'number' or sides < 1 or sides > 100 then
        API.sendTranslatedInfoMessage(player, 'UI_ServerOptionDesc_Roll')
        return
    end

    local roll = 1 + ZombRand(sides)
    if config.Commands.Roll.Global then
        local name = API.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        API.sendTranslatedServerMessage('UI_OmiChat_Roll', { name, tostring(roll), tostring(sides) })
    else
        API.reportRoll(player, roll, sides)
    end
end

---Handles the /seticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function API.Commands.requestSetIcon(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local icon = args[2]

    local err
    local success = false
    if username and icon then
        success, err = API.Commands.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            value = icon,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetIcon')
        end

        return
    end

    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetIconOther', { username })
end

---Handles the /setlanguageslots command.
---@param player IsoPlayer
---@param args omichat.request.Command
function API.Commands.requestSetLanguageSlots(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local slots = args[2]

    local err
    local success = false
    if username and slots then
        success, err = API.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languageSlots',
            fromCommand = true,
            value = slots,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetLanguageSlots')
        end

        return
    end

    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetLanguageSlotsOther', { username, slots })
end

---Handles the /setname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function API.Commands.requestSetName(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local name = args[2]

    local err
    local success = false
    if username and name then
        success, err = API.Commands.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            value = name,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetName')
        end

        return
    end

    name = utils.escapeRichText(name)
    API.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetNameOther', { username, name })
end

---Handles a request to notify other players of typing status.
---@param player IsoPlayer
---@param args omichat.request.Typing
function API.Commands.requestTyping(player, args)
    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local otherPlayer = onlinePlayers:get(i)

        if player ~= otherPlayer or isDebugEnabled() then
            local typing = args.typing and shouldSendTyping(player, otherPlayer, args.range, args.chatType)
            API.sendTyping(otherPlayer, player, typing)
        end
    end
end

---Updates the configuration with data from the client.
---@param player IsoPlayer
---@param args omichat.request.UpdateConfiguration
function API.Commands.updateConfiguration(player, args)
    if not player:isAccessLevel('Admin') then
        return
    end

    API.Configuration:load(args.value)
    API.Configuration:saveFile()
    API.sendConfiguration()
end

--#endregion


---Event handler for processing commands from the client.
---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
---@protected
function API._onClientCommand(module, command, player, args)
    if module ~= API._modDataKey then
        return
    end

    if API.Commands[command] then
        API.Commands[command](player, args)
    end
end

---Event handler for a scheduled update of the player cache.
---@protected
function API._refreshCache()
    local items = utils.refreshPlayerCache()
    local req = { items = items } ---@type omichat.request.UpdatePlayerCache
    API.dispatchAll('updatePlayerCache', req)
end
