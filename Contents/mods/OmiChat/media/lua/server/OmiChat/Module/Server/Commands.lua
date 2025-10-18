---@namespace omichat
---Handlers for processing commands on the server.

if isClient() then return end

---@class(partial) api.server
local API = require 'OmiChat/Module/Server/Core'
local config = API.Configuration
local utils = API.utils


---Contains server handlers for chat commands.
---@class api.server.commands
local Command = {}


---Handles the `/addlanguage` command.
---@param player IsoPlayer The requesting player.
---@param args request.Args.Command Arguments with command information.
function Command.addLanguage(player, args)
    local parsed = utils.parseCommandArgs(args.text)
    local username = parsed[1]
    local language = parsed[2]

    local err
    local success = false
    if username and language then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
            value = language,
        })

        username = utils.escapeRichText(username)
    end

    if not success then
        if err == 'FULL' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageFull', { username })
        elseif err == 'ALREADY_KNOW' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageKnown', { username, language })
        elseif err == 'UNKNOWN' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageNotConfigured', { language })
        elseif err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_AddLanguage')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_AddLanguageOther', { username, language })
end

---Handles the `/clearnames` command.
---@param player IsoPlayer The requesting player.
function Command.clearNames(player)
    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if access < config.General.MinimumCommandAccessLevel then
        return
    end

    API.data.clearNicknames()
    API.request.updatePlayerCache()
    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ClearNames')
end

---Handles the `/reseticon` command.
---@param player IsoPlayer The requesting player.
---@param args request.Args.Command Arguments with command information.
function Command.resetIcon(player, args)
    local parsed = utils.parseCommandArgs(args.text)
    local username = parsed[1]

    local err
    local success = false
    if username then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'icon',
            fromCommand = true,
        })

        username = utils.escapeRichText(username)
    end

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetIcon')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetIconOther', { username })
end

---Handles the `/resetlanguages` command.
---@param player IsoPlayer The requesting player.
---@param args request.Args.Command Arguments with command information.
function Command.resetLanguages(player, args)
    local parsed = utils.parseCommandArgs(args.text)
    local username = parsed[1]

    local err
    local success = false
    if username then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
        })

        username = utils.escapeRichText(username)
    end

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetLanguages')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetLanguagesOther', { username })
end

---Handles the `/resetname` command.
---@param player IsoPlayer The requesting player.
---@param args request.Args.Command Arguments with command information.
function Command.resetName(player, args)
    local parsed = utils.parseCommandArgs(args.text)
    local username = parsed[1]

    local err
    local success = false
    if username then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'nickname',
            fromCommand = true,
        })

        username = utils.escapeRichText(username)
    end

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetName')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetNameOther', { username })
end

---Handles the `/seticon` command.
---@param player IsoPlayer The requesting player.
---@param args request.Args.Command Arguments with command information.
function Command.setIcon(player, args)
    local parsed = utils.parseCommandArgs(args.text)
    local username = parsed[1]
    local icon = parsed[2]

    local err
    local success = false
    if username and icon then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'icon',
            value = icon,
            fromCommand = true,
        })

        username = utils.escapeRichText(username)
    end

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetIcon')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetIconOther', { username })
end

---Handles the `/setlanguageslots` command.
---@param player IsoPlayer The requesting player.
---@param args request.Args.Command Arguments with command information.
function Command.setLanguageSlots(player, args)
    local parsed = utils.parseCommandArgs(args.text)
    local username = parsed[1]
    local slots = parsed[2]

    local err
    local success = false
    if username and slots then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'languageSlots',
            fromCommand = true,
            value = slots,
        })

        username = utils.escapeRichText(username)
    end

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetLanguageSlots')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetLanguageSlotsOther', { username, slots })
end

---Handles the `/setname` command.
---@param player IsoPlayer The requesting player.
---@param args request.Args.Command Arguments with command information.
function Command.setName(player, args)
    local parsed = utils.parseCommandArgs(args.text)
    local username = parsed[1]
    local name = parsed[2]

    local err
    local success = false
    if username and name then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'nickname',
            value = name,
            fromCommand = true,
        })

        username = utils.escapeRichText(username)
        name = utils.escapeRichText(name)
    end

    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetName')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetNameOther', { username, name })
end


API.commands = Command
return Command

--#region Type Definitions

---@alias request.ChatCommandName
---| 'addLanguage'
---| 'clearNames'
---| 'resetIcon'
---| 'resetLanguages'
---| 'resetName'
---| 'setIcon'
---| 'setLanguageSlots'
---| 'setName'

--#endregion
