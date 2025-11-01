---Command stream definition for `/card`.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration
local MetaFormatter = API.MetaFormatter

---Command stream for the `/card` command.
---@private
API._cardCommand = API.CommandStream:new {
    name = 'card',
    command = '/card ',
    formatter = MetaFormatter:new(config.ID_CARD),
    helpTextID = 'UI_ServerOptionDesc_Card',
    autoTags = { 'IsCardCommand' },
    onUse = function(ctx)
        if API.hooks.has.cardCommand and API.hooks.cardCommand(ctx) then
            return
        end

        if not API.request.drawCard() then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = getSpecificPlayer(0)
        if not player then
            return false
        end

        if API.hooks.has.cardCommandEnabled then
            local result = API.hooks.cardCommandEnabled()
            if result ~= nil then
                return result
            end
        end

        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config:getCardItems()) then
            return false
        end

        if not config.Commands.Card.Global and not API.streams.firstChatStreamWithTag('CardCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.streams.firstChatStreamWithTag('CardCommandTarget') then
            utils.log.warn.once('No target stream defined for /card')
            API.chat.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

return API._cardCommand
