---Client command handling.


---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
OmiChat.Commands = {}

local unpack = unpack or table.unpack


---Adds an info message for the local player.
---@param args omichat.InfoMessageRequest
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
