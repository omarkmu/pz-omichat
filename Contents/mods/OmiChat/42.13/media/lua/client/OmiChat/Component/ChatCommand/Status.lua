---Command stream definition for `/status`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
require 'OmiChat/Module/Client/Player'

local utils = API.utils
local config = API.Configuration
local getText = utils.getText

return API.CommandStream:new {
    name = 'status',
    command = '/status ',
    helpTextID = 'help-text-status',
    isEnabled = function() return config.Commands.Status.Enable end,
    onUse = function(ctx)
        local text = utils.trim(ctx.text)

        if #text == 0 then
            local username = API.player.getUsername()
            local status = username and API.data.getStatus(username)

            local message
            if status then
                message = getText('info-current-status', { status = status })
            else
                message = getText('info-current-status-unset')
            end

            local helpText = ctx.stream:getHelpText()
            if helpText then
                message = message .. ' <LINE> ' .. helpText
            end

            API.chat.addInfoMessage(message)
            return
        elseif text == 'clear' then
            text = ''
        end

        local _, feedback = API.player.setStatus(text)
        if feedback then
            API.chat.addInfoMessage(feedback)
        end
    end,
}
