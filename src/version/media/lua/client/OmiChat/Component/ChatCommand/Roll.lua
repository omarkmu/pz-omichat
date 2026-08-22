---Command stream definition for `/roll`.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'

local concat = table.concat
local utils = API.utils
local config = API.Configuration

---Roll-Command-Plus semi-parity: attempts to resolve dice from literals.
---e.g., `/roll 20 6 2d3` -> `/roll d20 + d6 + 2d3`.
---@param command string
---@return string
local function inferDice(command)
    local dice = {}
    local parts = utils.split(command, ' ')

    local hasDice = false
    for i = 1, #parts do
        local substr = parts[i]:trim()
        if substr:match('^%d*d%d+$') then
            hasDice = true
            dice[#dice + 1] = substr
        elseif substr == '%' or substr:match('^%d+$') then
            dice[#dice + 1] = 'd' .. substr
        elseif substr == '+' and hasDice then
            -- e.g., d20 + 3; use command as-is
            return command
        elseif substr ~= '+' then
            return command
        end
    end

    if #dice > 0 then
        return concat(dice, ' + ')
    end

    return command
end


---Command stream for the `/roll` command.
---@private
API._rollCommand = API.CommandStream:new {
    name = 'roll',
    command = '/roll ',
    helpTextID = 'help-text-roll',
    autoTags = { 'IsRollCommand' },
    onUse = function(ctx)
        if API.hooks.has.rollCommand and API.hooks.rollCommand(ctx) then
            return
        end

        local command = utils.trim(ctx.text)
        if #command == 0 then
            command = 'd6'
        else
            command = inferDice(command)
        end

        if not API.request.rollDice(command) then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = API.player.get()
        if not player then
            return false
        end

        if API.hooks.has.rollCommandEnabled then
            local result = API.hooks.rollCommandEnabled()
            if result ~= nil then
                return result
            end
        end

        if not utils.hasIgnoreItemReqPower(player) and not utils.hasAnyItemType(player, config:getDiceItems()) then
            return false
        end

        if not config.Commands.Roll.Global and not API.streams.firstChatStreamWithTag('RollCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.streams.firstChatStreamWithTag('RollCommandTarget') then
            utils.log.warn.once('No target stream defined for /roll; add the `RollCommandTarget` tag to a stream')
            API.chat.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

return API._rollCommand
