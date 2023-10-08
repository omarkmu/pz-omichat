---Server command handling.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'
OmiChat.Commands = {}


local Option = OmiChat.Option
local utils = OmiChat.utils

local suits = {
    'Clubs',
    'Diamonds',
    'Hearts',
    'Spades'
}
local cards = {
    'the Ace',
    'a Two',
    'a Three',
    'a Four',
    'a Five',
    'a Six',
    'a Seven',
    'an Eight',
    'a Nine',
    'a Ten',
    'the Jack',
    'the Queen',
    'the King',
}


---Checks whether a player has permission to execute a command for the given target.
---@param player IsoPlayer
---@param target string
---@param isCommand boolean?
---@return boolean
local function canAccessTarget(player, target, isCommand)
    if not target then
        return false
    end

    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if isCommand and access < Option.MinimumCommandAccessLevel then
        return false
    end

    if access == 1 and target ~= player:getUsername() then
        return false
    end

    return true
end

---@param args omichat.ModDataUpdateRequest
---@return boolean
local function updateModDataNameColor(args)
    if not Option.EnableSetNameColor and not args.fromCommand then
        return false
    end

    OmiChat.setNameColorString(args.target, args.value and tostring(args.value) or nil)
    return true
end

---@param args omichat.ModDataUpdateRequest
---@return boolean
local function updateModDataNickname(args)
    if not Option.EnableSetName and not args.fromCommand then
        return false
    end

    OmiChat.setNickname(args.target, args.value and tostring(args.value) or nil)
    return true
end

---Gets a random card name.
---@return string
local function getRandomCard()
    local card = cards[1 + ZombRand(#cards)]
    local suit = suits[1 + ZombRand(#suits)]

    return table.concat({ card, ' of ', suit })
end


---Handles the /clearnames command.
---@param player IsoPlayer
function OmiChat.Commands.clearNames(player)
    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if access < Option.MinimumCommandAccessLevel then
        return
    end

    OmiChat.clearNicknames()
    OmiChat.transmitModData()
    OmiChat.sendTranslatedInfoMessage(player, 'UI_OmiChat_clear_names_success')
end

---Handles side-effects of the `OnCreatePlayer` event.
---@param player IsoPlayer
function OmiChat.Commands.informPlayerCreated(player)
    if Option.EnableChatNameAsCharacterName then
        OmiChat.setNickname(player:getUsername(), nil)
    end

    OmiChat.transmitModData()
end

---Handles the /resetname command.
---@param player IsoPlayer
---@param args table
function OmiChat.Commands.resetName(player, args)
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

---Updates global mod data.
---@param player IsoPlayer
---@param args omichat.ModDataUpdateRequest
---@return boolean
function OmiChat.Commands.requestDataUpdate(player, args)
    local success = false
    if canAccessTarget(player, args.target, args.fromCommand) then
        if args.field == 'nicknames' then
            success = updateModDataNickname(args)
        elseif args.field == 'nameColors' then
            success = updateModDataNameColor(args)
        end
    end

    OmiChat.transmitModData()
    return success
end

---Handles the /card command.
---@param player IsoPlayer
function OmiChat.Commands.requestDrawCard(player)
    local name = OmiChat.getNameInChat(player:getUsername(), 'general') or player:getUsername()
    OmiChat.sendTranslatedServerMessage('UI_OmiChat_card', { name, getRandomCard() })
end

---Handles the /roll command.
---@param player IsoPlayer
---@param args table
function OmiChat.Commands.requestRollDice(player, args)
    local sides = args.sides and tonumber(args.sides)
    if type(sides) ~= 'number' or sides < 1 or sides > 100 then
        OmiChat.sendTranslatedInfoMessage(player, 'UI_ServerOptionDesc_Roll')
        return
    end

    local name = OmiChat.getNameInChat(player:getUsername(), 'general') or player:getUsername()
    local roll = tostring(1 + ZombRand(sides))

    OmiChat.sendTranslatedServerMessage('UI_OmiChat_roll', { name, roll, tostring(sides) })
end

---Handles the /setname command.
---@param player IsoPlayer
---@param args table
function OmiChat.Commands.setName(player, args)
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
