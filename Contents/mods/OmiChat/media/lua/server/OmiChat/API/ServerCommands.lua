---Server command handling.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'
OmiChat.Commands = {}


local Option = OmiChat.Option


---Checks whether a player has permission to execute a command for the given target.
---@param player IsoPlayer
---@param target string
---@return boolean
local function canAccessTarget(player, target)
    if not target then
        return false
    end

    local playerAccess = player:getAccessLevel() == 'None'
    local targetOtherPlayer = target ~= player:getUsername()

    if playerAccess and targetOtherPlayer then
        return false
    end

    return true
end

---@param player IsoPlayer
---@param args ModDataUpdateRequest
local function updateModDataNameColor(player, args)
    if not Option.EnableSetNameColor and player:getAccessLevel() == 'None' then
        return
    end

    OmiChat.setNameColorString(args.target, args.value and tostring(args.value) or nil)
end

---@param player IsoPlayer
---@param args ModDataUpdateRequest
local function updateModDataNickname(player, args)
    if not Option.EnableSetName and player:getAccessLevel() == 'None' then
        return
    end

    OmiChat.setNickname(args.target, args.value and tostring(args.value) or nil)
end


---Handles character creation.
---@param player IsoPlayer
function OmiChat.Commands.informPlayerCreated(player)
    if Option.EnableChatNameAsCharacterName then
        OmiChat.setNickname(player:getUsername(), nil)
    end

    OmiChat.transmitModData()
end

---Updates global mod data.
---@param player IsoPlayer
---@param args ModDataUpdateRequest
function OmiChat.Commands.requestDataUpdate(player, args)
    if canAccessTarget(player, args.target) then
        if args.field == 'nicknames' then
            updateModDataNickname(player, args)
        elseif args.field == 'nameColors' then
            updateModDataNameColor(player, args)
        end
    end

    OmiChat.transmitModData()
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
