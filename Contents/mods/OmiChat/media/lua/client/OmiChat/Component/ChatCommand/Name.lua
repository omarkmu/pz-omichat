---@namespace omichat
---Command stream definition for `/name`.

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local config = API.Configuration

return API.CommandStream:new {
    name = 'name',
    command = '/name ',
    helpTextID = 'UI_OmiChat_HelpText_Name',
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
            API.chat.addInfoMessage(getText('UI_OmiChat_Info_SetNameEmpty'))
            return
        end

        local _, feedback = API.player.updateCharacterName(input, config:isNameCommandSetFullName())
        if feedback then
            API.chat.addInfoMessage(feedback)
        end
    end,
    onHelp = function()
        local msg = 'UI_OmiChat_HelpText_Name'
        if config:isNameCommandSetFullName() then
            msg = 'UI_OmiChat_HelpText_NameFull'
        end

        API.chat.addInfoMessage(getText(msg))
    end,
}
