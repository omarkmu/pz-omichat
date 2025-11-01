---Command stream definition for `/roll`.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration
local MetaFormatter = API.MetaFormatter

---Command stream for the `/roll` command.
---@private
API._rollCommand = API.CommandStream:new {
    name = 'roll',
    command = '/roll ',
    formatter = MetaFormatter:new(config.ID_ROLL),
    helpTextID = 'UI_ServerOptionDesc_Roll',
    autoTags = { 'IsRollCommand' },
    onUse = function(ctx)
        if API.hooks.has.rollCommand and API.hooks.rollCommand(ctx) then
            return
        end

        local command = utils.trim(ctx.text)
        local first = command:split(' ')[1]
        local sides = utils.tointeger(first)
        if not sides and #command == 0 then
            sides = 6
        elseif not sides then
            ctx.stream:showHelpText()
            return
        end

        if not API.request.rollDice(sides) then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = getSpecificPlayer(0)
        if not player then
            return false
        end

        if API.hooks.has.rollCommandEnabled then
            local result = API.hooks.rollCommandEnabled()
            if result ~= nil then
                return result
            end
        end

        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config:getDiceItems()) then
            return false
        end

        if not config.Commands.Roll.Global and not API.streams.firstChatStreamWithTag('RollCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.streams.firstChatStreamWithTag('RollCommandTarget') then
            utils.log.warn.once('No target stream defined for /roll')
            API.chat.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

return API._rollCommand
