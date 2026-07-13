---Command stream definition for `/name`.
---@namespace omichat

local API = require 'OmiChat/Module/Core/Client'
local utils = API.utils
local config = API.Configuration

local getText = utils.getText

return API.CommandStream:new {
    name = 'name',
    command = '/name ',
    helpTextID = 'help-text-name',
    isEnabled = function() return config:isNameCommandEnabled() end,
    onUse = function(ctx)
        if config:isNameCommandSetNickname() then
            local _, feedback = API.player.setNickname(ctx.text)
            if feedback then
                API.chat.addInfoMessage(feedback)
            end

            return
        end

        local input = utils.trim(ctx.text or '')
        if #input == 0 then
            API.chat.addInfoMessage(getText('info-set-name-empty'))
            return
        end

        local _, feedback = API.player.updateCharacterName(input, config:isNameCommandSetFullName())
        if feedback then
            API.chat.addInfoMessage(feedback)
        end
    end,
    onHelp = function()
        local msg = 'help-text-name'
        if config:isNameCommandSetFullName() then
            msg = 'help-text-name-full'
        end

        API.chat.addInfoMessage(getText(msg))
    end,
}
