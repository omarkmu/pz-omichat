---Handlers for processing chat commands on the server.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server
local config = API.Configuration
local utils = API.utils


---@class omichat.api.server.commands
local Command = {}


---Handles the /addlanguage command.
---@param player IsoPlayer
---@param args omichat.request.Command
function Command.addLanguage(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local language = args[2]

    local err
    local success = false
    if username and language then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
            value = language,
        })
    end

    username = utils.escapeRichText(username)
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

---Handles the /clearnames command.
---@param player IsoPlayer
function Command.clearNames(player)
    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if access < config.General.MinimumCommandAccessLevel then
        return
    end

    API.data.clearNicknames()
    API.data.transmit()
    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ClearNames')
end

---Handles the /reseticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function Command.resetIcon(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'icons',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
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

---Handles the /resetlanguages command.
---@param player IsoPlayer
---@param args omichat.request.Command
function Command.resetLanguages(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
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

---Handles the /resetname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function Command.resetName(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'nicknames',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
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

---Handles the /seticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function Command.setIcon(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local icon = args[2]

    local err
    local success = false
    if username and icon then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'icons',
            value = icon,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
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

---Handles the /setlanguageslots command.
---@param player IsoPlayer
---@param args omichat.request.Command
function Command.setLanguageSlots(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local slots = args[2]

    local err
    local success = false
    if username and slots then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'languageSlots',
            fromCommand = true,
            value = slots,
        })
    end

    username = utils.escapeRichText(username)
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

---Handles the /setname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function Command.setName(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local name = args[2]

    local err
    local success = false
    if username and name then
        success, err = API.data.tryUpdate(player, {
            target = username,
            field = 'nicknames',
            value = name,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetName')
        end

        return
    end

    name = utils.escapeRichText(name)
    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetNameOther', { username, name })
end


API.commands = Command
return Command
