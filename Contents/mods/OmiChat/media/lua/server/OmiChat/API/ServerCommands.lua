---Server API functionality related to dispatching and handling commands.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'

---@class omichat.api.server.commands
OmiChat.Commands = {}

local Option = OmiChat.Option
local utils = OmiChat.utils

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
    if fromCommand and access < Option.MinimumCommandAccessLevel then
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

---Checks whether a field should be reset on player death.
---@param field string
---@param username string
---@return boolean
local function shouldResetFieldOnDeath(field, username)
    return utils.testPredicate(Option.PredicateClearOnDeath, {
        field = field,
        username = username,
    })
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

    OmiChat.setUserModData(args.target, args.value)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.currentLanguage(args)
    if not args.value then
        return false
    end

    return OmiChat.setCurrentRoleplayLanguage(args.target, args.value)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.icons(args)
    OmiChat.setChatIcon(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
function updateModData.languages(args)
    if not args.value then
        OmiChat.resetRoleplayLanguages(args.target)
        return true
    end

    return OmiChat.addRoleplayLanguage(args.target, args.value)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.languageSlots(args)
    local slots = tonumber(args.value)
    if not slots then
        return false
    end

    return OmiChat.setRoleplayLanguageSlots(args.target, slots)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.nameColors(args)
    if not Option.EnableSetNameColor and not args.fromCommand then
        return false
    end

    OmiChat.setNameColorString(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
function updateModData.nicknames(args)
    if not Option:canPlayersSetNickname() and not args.fromCommand then
        return false
    end

    OmiChat.setNickname(args.target, args.value and tostring(args.value) or nil)
    return true
end


--#region dispatch

---Dispatches a server command.
---@param player IsoPlayer
---@param command string
---@param args table?
function OmiChat.dispatch(command, player, args)
    sendServerCommand(player, OmiChat._modDataKey, command, args or {})
end

---Dispatches a server command to all players.
---@param command string
---@param args table?
function OmiChat.dispatchAll(command, args)
    sendServerCommand(OmiChat._modDataKey, command, args or {})
end

---Instructs the client to report the result of drawing a card.
---@param player IsoPlayer
---@param card integer
---@param suit integer
function OmiChat.reportDrawCard(player, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { card = card, suit = suit }

    OmiChat.dispatch('reportDrawCard', player, req)
end

---Instructs all clients to report the result of drawing a card.
---@param name string
---@param card integer
---@param suit integer
function OmiChat.reportDrawCardGlobal(name, card, suit)
    ---@type omichat.request.ReportDrawCard
    local req = { name = name, card = card, suit = suit }

    OmiChat.dispatchAll('reportDrawCard', req)
end

---Instructs the client to report the result of a coin flip.
---@param player IsoPlayer
---@param heads boolean
function OmiChat.reportFlipCoin(player, heads)
    ---@type omichat.request.ReportFlipCoin
    local req = { heads = heads }

    OmiChat.dispatch('reportFlipCoin', player, req)
end

---Instructs the client to report the result of a dice roll.
---@param player IsoPlayer
---@param roll integer
---@param sides integer
function OmiChat.reportRoll(player, roll, sides)
    ---@type omichat.request.ReportRoll
    local req = { roll = roll, sides = sides }

    OmiChat.dispatch('reportRoll', player, req)
end

---Notifies the client about another typing player.
---@param player IsoPlayer
---@param target IsoPlayer
---@param isTyping boolean
function OmiChat.sendTyping(player, target, isTyping)
    ---@type omichat.request.UpdateTyping
    local req = { username = target:getUsername(), typing = isTyping }

    OmiChat.dispatch('updateTyping', player, req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param text string
---@param serverAlert boolean?
function OmiChat.sendInfoMessage(player, text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    OmiChat.dispatch('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param text string
---@param serverAlert boolean?
function OmiChat.sendServerMessage(text, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { text = text, serverAlert = serverAlert }

    OmiChat.dispatchAll('showInfoMessage', req)
end

---Sends an info message that will show only for the specified player.
---@param player IsoPlayer
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function OmiChat.sendTranslatedInfoMessage(player, stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    OmiChat.dispatch('showInfoMessage', player, req)
end

---Sends an info message that will show for all players.
---@param stringID string
---@param args string[]?
---@param serverAlert boolean?
function OmiChat.sendTranslatedServerMessage(stringID, args, serverAlert)
    ---@type omichat.request.ShowMessage
    local req = { stringID = stringID, args = args, serverAlert = serverAlert }

    OmiChat.dispatchAll('showInfoMessage', req)
end


--#endregion

--#region handlers

---Handles player death.
---@param player IsoPlayer
function OmiChat.Commands.reportPlayerDeath(player)
    local username = player:getUsername()
    if not canAccessTarget(player, username) then
        return
    end

    local doTransmit = false
    if shouldResetFieldOnDeath('nickname', username) then
        updateModData.nicknames({ target = username })
        doTransmit = true
    end

    if shouldResetFieldOnDeath('icon', username) then
        updateModData.icons({ target = username })
        doTransmit = true
    end

    if shouldResetFieldOnDeath('languages', username) then
        updateModData.languages({ target = username })
        doTransmit = true
    end

    if doTransmit then
        OmiChat.transmitModData()
    end
end

---Handles player join.
function OmiChat.Commands.reportPlayerJoined()
    OmiChat.Commands.requestPlayerCacheUpdate()
end

---Handles the /addlanguage command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestAddLanguage(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local language = args[2]

    local err
    local success = false
    if username and language then
        success, err = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
            value = language,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'FULL' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageFull', { username })
        elseif err == 'ALREADY_KNOW' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageKnown', { username, language })
        elseif err == 'UNKNOWN' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageNotConfigured', { language })
        elseif err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_AddLanguage')
        end

        return
    end

    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_AddLanguageOther', { username, language })
end

---Handles the /clearnames command.
---@param player IsoPlayer
function OmiChat.Commands.requestClearNames(player)
    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if access < Option.MinimumCommandAccessLevel then
        return
    end

    OmiChat.clearNicknames()
    OmiChat.transmitModData()
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ClearNames')
end

---Handles a request to clear mod data for a given username.
---@param player IsoPlayer
---@param req omichat.request.ClearModData
function OmiChat.Commands.requestClearModData(player, req)
    if player:getAccessLevel() ~= 'Admin' then
        return
    end

    OmiChat.clearModData(req.username)
    OmiChat.transmitModData()
end

---Updates global mod data.
---@param player IsoPlayer
---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
function OmiChat.Commands.requestDataUpdate(player, args)
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

    OmiChat.transmitModData()
    return success, err
end

---Handles the /card command.
---@param player IsoPlayer
function OmiChat.Commands.requestDrawCard(player)
    local suit = 1 + ZombRand(4)
    local card = 1 + ZombRand(13)
    if OmiChat.isCustomStreamEnabled('card') then
        OmiChat.reportDrawCard(player, card, suit)
    else
        local name = OmiChat.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        OmiChat.reportDrawCardGlobal(name, card, suit)
    end
end

---Handles the /flip command.
---@param player IsoPlayer
function OmiChat.Commands.requestFlipCoin(player)
    local heads = ZombRand(2) == 0
    if OmiChat.isCustomStreamEnabled('flip') then
        OmiChat.reportFlipCoin(player, heads)
    else
        local name = OmiChat.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        OmiChat.sendTranslatedServerMessage('UI_OmiChat_Flip' .. (heads and 'Heads' or 'Tails'), { name })
    end
end

---Updates player cache information.
function OmiChat.Commands.requestPlayerCacheUpdate()
    OmiChat._refreshCache()
end

---Handles the /reseticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestResetIcon(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetIcon')
        end

        return
    end

    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetIconOther', { username })
end

---Handles the /resetlanguages command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestResetLanguages(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetLanguages')
        end

        return
    end

    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetLanguagesOther', { username })
end

---Handles the /resetname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestResetName(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetName')
        end

        return
    end

    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetNameOther', { username })
end

---Handles the /roll command.
---@param player IsoPlayer
---@param args omichat.request.RollDice
function OmiChat.Commands.requestRollDice(player, args)
    local sides = tonumber(args.sides)
    if type(sides) ~= 'number' or sides < 1 or sides > 100 then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_ServerOptionDesc_Roll')
        return
    end

    local roll = 1 + ZombRand(sides)
    if OmiChat.isCustomStreamEnabled('roll') then
        OmiChat.reportRoll(player, roll, sides)
    else
        local name = OmiChat.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        OmiChat.sendTranslatedServerMessage('UI_OmiChat_Roll', { name, tostring(roll), tostring(sides) })
    end
end

---Handles sandbox options being updated by an admin.
function OmiChat.Commands.requestSandboxUpdate()
    OmiChat.dispatchAll('updateState')
end

---Handles the /seticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestSetIcon(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local icon = args[2]

    local err
    local success = false
    if username and icon then
        success, err = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            value = icon,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetIcon')
        end

        return
    end

    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetIconOther', { username })
end

---Handles the /setlanguageslots command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestSetLanguageSlots(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local slots = args[2]

    local err
    local success = false
    if username and slots then
        success, err = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languageSlots',
            fromCommand = true,
            value = slots,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetLanguageSlots')
        end

        return
    end

    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetLanguageSlotsOther', { username, slots })
end

---Handles the /setname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestSetName(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local name = args[2]

    local err
    local success = false
    if username and name then
        success, err = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            value = name,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetName')
        end

        return
    end

    name = utils.escapeRichText(name)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetNameOther', { username, name })
end

---Handles a request to notify other players of typing status.
---@param player IsoPlayer
---@param args omichat.request.Typing
function OmiChat.Commands.requestTyping(player, args)
    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local otherPlayer = onlinePlayers:get(i)

        if player ~= otherPlayer or isDebugEnabled() then
            local typing = args.typing and shouldSendTyping(player, otherPlayer, args.range, args.chatType)
            OmiChat.sendTyping(otherPlayer, player, typing)
        end
    end
end

--#endregion


---Event handler for processing commands from the client.
---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
---@protected
function OmiChat._onClientCommand(module, command, player, args)
    if module ~= OmiChat._modDataKey then
        return
    end

    if OmiChat.Commands[command] then
        OmiChat.Commands[command](player, args)
    end
end

---Event handler for a scheduled update of the player cache.
---@protected
function OmiChat._refreshCache()
    local items = utils.refreshPlayerCache()
    local req = { items = items } ---@type omichat.request.UpdatePlayerCache
    OmiChat.dispatchAll('updatePlayerCache', req)
end
