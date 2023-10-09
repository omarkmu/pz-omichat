---Client command handling.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
OmiChat.Commands = {}


local utils = OmiChat.utils
local Option = OmiChat.Option
local unpack = unpack


---Reports the results of drawing a card.
---@param args omichat.request.ReportDrawCard
function OmiChat.Commands.reportDrawCard(args)
    local command = utils.interpolate(Option.FormatCard, { card = args.card })
    local formatted = OmiChat.getFormatter('card'):format(command)

    processSayMessage(formatted)
end

---Reports the results of a dice roll.
---@param args omichat.request.ReportRoll
function OmiChat.Commands.reportRoll(args)
    local command = utils.interpolate(Option.FormatRoll, { roll = args.roll, sides = args.sides })
    local formatted = OmiChat.getFormatter('roll'):format(command)

    processSayMessage(formatted)
end

---Adds an info message for the local player.
---@param args omichat.request.ShowMessage
function OmiChat.Commands.showInfoMessage(args)
    local text
    if args.text then
        text = args.text
    elseif args.stringID then
        local substitutions = args.args or {}
        text = getText(args.stringID, unpack(substitutions))
    end

    if not text then
        return
    end

    OmiChat.showInfoMessage(text, args.serverAlert)
end


---Event handler for processing commands from the server.
---@param module string
---@param command string
---@param args table
---@protected
function OmiChat._onServerCommand(module, command, args)
    if module ~= OmiChat._modDataKey then
        return
    end

    if OmiChat.Commands[command] then
        OmiChat.Commands[command](args)
    end
end
