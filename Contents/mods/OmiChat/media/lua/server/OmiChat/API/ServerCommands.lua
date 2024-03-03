---Server API functionality related to dispatching and handling commands.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'
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

---Instructs the client to report the result of a dice roll.
---@param player IsoPlayer
---@param roll integer
---@param sides integer
function OmiChat.reportRoll(player, roll, sides)
    ---@type omichat.request.ReportRoll
    local req = { roll = roll, sides = sides }

    OmiChat.dispatch('reportRoll', player, req)
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

    -- clear nickname, icon, and languages
    updateModData.nicknames({ target = username })
    updateModData.icons({ target = username })
    updateModData.languages({ target = username })

    OmiChat.transmitModData()
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

    if not success then
        if err == 'FULL' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_add_language_full', { username })
        elseif err == 'ALREADY_KNOW' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_add_language_known', { username, language })
        elseif err == 'UNKNOWN' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_add_language_unknown_language', { language })
        elseif err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_error_unknown_player', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_addlanguage')
        end

        return
    end

    username = utils.escapeRichText(username)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_add_language_success', { username, language })
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
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_clear_names_success')
end

---Updates global mod data.
---@param player IsoPlayer
---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
function OmiChat.Commands.requestDataUpdate(player, args)
    local err
    local success = false
    if not isOnlinePlayer(args.target) then
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

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_error_unknown_player', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_reseticon')
        end

        return
    end

    username = utils.escapeRichText(username)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_reset_other_icon_success', { username })
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

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_error_unknown_player', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_resetlanguages')
        end

        return
    end

    username = utils.escapeRichText(username)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_reset_other_languages_success', { username })
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

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_error_unknown_player', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_resetname')
        end

        return
    end

    username = utils.escapeRichText(username)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_reset_other_name_success', { username })
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
        OmiChat.sendTranslatedServerMessage('UI_OmiChat_roll', { name, tostring(roll), tostring(sides) })
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

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_error_unknown_player', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_seticon')
        end

        return
    end

    username = utils.escapeRichText(username)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_set_other_icon_success', { username })
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

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_error_unknown_player', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_setlanguageslots')
        end

        return
    end

    username = utils.escapeRichText(username)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_set_language_slots_success', { username, slots })
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

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_error_unknown_player', { username })
        else
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_setname')
        end

        return
    end

    username = utils.escapeRichText(username)
    name = utils.escapeRichText(name)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_set_other_name_success', { username, name })
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
