---Server command handling.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'
OmiChat.Commands = {}


local Option = OmiChat.Option
local utils = OmiChat.utils


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

---@param args omichat.request.ModDataUpdate
---@return boolean
local function updateModDataCurrentLanguage(args)
    if not args.value then
        return false
    end

    return OmiChat.setCurrentRoleplayLanguage(args.target, args.value)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
local function updateModDataIcon(args)
    OmiChat.setChatIcon(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
local function updateModDataLanguage(args)
    if not args.value then
        OmiChat.resetRoleplayLanguages(args.target)
        return true
    end

    return OmiChat.addRoleplayLanguage(args.target, args.value)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
local function updateModDataLanguageSlots(args)
    local slots = tonumber(args.value)
    if not slots then
        return false
    end

    return OmiChat.setRoleplayLanguageSlots(args.target, slots)
end

---@param args omichat.request.ModDataUpdate
---@return boolean
local function updateModDataNameColor(args)
    if not Option.EnableSetNameColor and not args.fromCommand then
        return false
    end

    OmiChat.setNameColorString(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@param args omichat.request.ModDataUpdate
---@return boolean
local function updateModDataNickname(args)
    if not Option.EnableSetName and not args.fromCommand then
        return false
    end

    OmiChat.setNickname(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@type table<omichat.ModDataField, function>
local modDataUpdateFunctions = {
    nicknames = updateModDataNickname,
    nameColors = updateModDataNameColor,
    languages = updateModDataLanguage,
    languageSlots = updateModDataLanguageSlots,
    currentLanguage = updateModDataCurrentLanguage,
    icons = updateModDataIcon,
}


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
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_add_language_known', { username })
        elseif err == 'UNKNOWN' then
            OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_add_language_unknown_language', { username, language })
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
    if canAccessTarget(player, args.target, args.fromCommand) then
        local updateFunc = modDataUpdateFunctions[args.field]
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
        local name = OmiChat.getNameInChat(player:getUsername(), 'general') or player:getUsername()
        OmiChat.reportDrawCardGlobal(name, card, suit)
    end
end

---Handles the /reseticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestResetIcon(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]

    local success = false
    if username then
        success = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            fromCommand = true,
        })
    end

    if not success then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_reseticon')
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

    local success = false
    if username then
        success = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
        })
    end

    if not success then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_resetlanguages')
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

    local success = false
    if username then
        success = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            fromCommand = true,
        })
    end

    if not success then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_resetname')
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
        local name = OmiChat.getNameInChat(player:getUsername(), 'general') or player:getUsername()
        OmiChat.sendTranslatedServerMessage('UI_OmiChat_roll', { name, tostring(roll), tostring(sides) })
    end
end

---Handles the /seticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function OmiChat.Commands.requestSetIcon(player, args)
    args = utils.parseCommandArgs(args.command)
    local username = args[1]
    local icon = args[2]

    local success = false
    if username and icon then
        success = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            value = icon,
            fromCommand = true,
        })
    end

    if not success then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_seticon')
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

    local success = false
    if username and slots then
        success = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'languageSlots',
            fromCommand = true,
            value = slots,
        })
    end

    if not success then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_setlanguageslots')
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

    local success = false
    if username and name then
        success = OmiChat.Commands.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            value = name,
            fromCommand = true,
        })
    end

    if not success then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_helptext_setname')
        return
    end

    username = utils.escapeRichText(username)
    name = utils.escapeRichText(name)
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_set_other_name_success', { username, name })
end


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
