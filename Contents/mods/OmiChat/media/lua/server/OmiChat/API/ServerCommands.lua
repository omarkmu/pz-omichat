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
    'Spades',
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

---Gets a random card name.
---@return string
local function getRandomCard()
    local card = cards[1 + ZombRand(#cards)]
    local suit = suits[1 + ZombRand(#suits)]

    return table.concat({ card, ' of ', suit })
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
    local card = getRandomCard()
    if OmiChat.isCustomStreamEnabled('card') then
        OmiChat.reportDrawCard(player, card)
    else
        local name = OmiChat.getNameInChat(player:getUsername(), 'general') or player:getUsername()
        OmiChat.sendTranslatedServerMessage('UI_OmiChat_card', { name, card })
    end
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
    local sides = args.sides and tonumber(args.sides)
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
