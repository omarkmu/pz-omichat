---Handlers for processing chat commands on the server.
---@namespace omichat

if isClient() then return end

---@class(partial) api.server
local API = require 'OmiChat/Module/Core/Server'
local utils = API.utils


---@class api.server.commands
local Command = {}

---Handlers for processing chat commands on the server.
API.commands = Command


---Handles the `/addlanguage` command.
---@param player IsoPlayer The requesting player.
---@param args Args.Request.Command Arguments with command information.
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
            API.request.sendTranslatedInfoMessage(player, 'error-add-language-full', { username = username })
        elseif err == 'ALREADY_KNOW' then
            API.request.sendTranslatedInfoMessage(player, 'error-add-language-known', {
                username = username,
                language = language,
            })
        elseif err == 'UNKNOWN' then
            API.request.sendTranslatedInfoMessage(player, 'error-add-language-not-configured', { language = language })
        elseif err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'error-unknown-player', { username = username })
        else
            API.request.sendTranslatedInfoMessage(player, 'help-text-add-language')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'success-add-language-other', {
        username = username,
        language = language,
    })
end

---Handles the `/clearnames` command.
---@param player IsoPlayer The requesting player.
function Command.clearNames(player)
    if not utils.hasAdminChatPower(player) then
        return
    end

    API.data.clearNicknames()
    API.request.updatePlayerCache()
    API.request.sendTranslatedInfoMessage(player, 'success-clear-names')
end

---Handles the `/reseticon` command.
---@param player IsoPlayer The requesting player.
---@param args Args.Request.Command Arguments with command information.
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
            API.request.sendTranslatedInfoMessage(player, 'error-unknown-player', { username = username })
        else
            API.request.sendTranslatedInfoMessage(player, 'help-text-reset-icon')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'success-reset-icon-other', { username = username })
end

---Handles the `/resetlanguages` command.
---@param player IsoPlayer The requesting player.
---@param args Args.Request.Command Arguments with command information.
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
            API.request.sendTranslatedInfoMessage(player, 'error-unknown-player', { username = username })
        else
            API.request.sendTranslatedInfoMessage(player, 'help-text-reset-languages')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'success-reset-languages-other', { username = username })
end

---Handles the `/resetname` command.
---@param player IsoPlayer The requesting player.
---@param args Args.Request.Command Arguments with command information.
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
            API.request.sendTranslatedInfoMessage(player, 'error-unknown-player', { username = username })
        else
            API.request.sendTranslatedInfoMessage(player, 'help-text-reset-name')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'success-reset-name-other', { username = username })
end

---Handles the `/seticon` command.
---@param player IsoPlayer The requesting player.
---@param args Args.Request.Command Arguments with command information.
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
            API.request.sendTranslatedInfoMessage(player, 'error-unknown-player', { username = username })
        else
            API.request.sendTranslatedInfoMessage(player, 'help-text-set-icon')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'success-reset-icon-other', { username = username })
end

---Handles the `/setlanguageslots` command.
---@param player IsoPlayer The requesting player.
---@param args Args.Request.Command Arguments with command information.
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
            API.request.sendTranslatedInfoMessage(player, 'error-unknown-player', { username = username })
        else
            API.request.sendTranslatedInfoMessage(player, 'help-text-set-language-slots')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'success-set-language-slots-other', {
        username = username,
        slots = slots,
    })
end

---Handles the `/setname` command.
---@param player IsoPlayer The requesting player.
---@param args Args.Request.Command Arguments with command information.
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
            API.request.sendTranslatedInfoMessage(player, 'error-unknown-player', { username = username })
        else
            API.request.sendTranslatedInfoMessage(player, 'help-text-set-name')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'success-set-name-other', { username = username, name = name })
end


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
