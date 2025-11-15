---Command stream definition for `/flip`.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration

---Command stream for the `/flip` command.
---@private
API._flipCommand = API.CommandStream:new {
    name = 'flip',
    command = '/flip ',
    helpTextID = 'help-text-flip',
    autoTags = { 'IsFlipCommand' },
    onUse = function(ctx)
        if API.hooks.has.flipCommand and API.hooks.flipCommand(ctx) then
            return
        end

        if not API.request.flipCoin() then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = API.player.get()
        if not player then
            return false
        end

        if API.hooks.has.flipCommandEnabled then
            local result = API.hooks.flipCommandEnabled()
            if result ~= nil then
                return result
            end
        end

        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config:getCoinItems()) then
            return false
        end

        if not config.Commands.Flip.Global and not API.streams.firstChatStreamWithTag('FlipCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.streams.firstChatStreamWithTag('FlipCommandTarget') then
            utils.log.warn.once('No target stream defined for /flip; add the `FlipCommandTarget` tag to a stream')
            API.chat.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

return API._flipCommand
