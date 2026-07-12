---Command stream definition for `/language`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local getText = utils.getText

return API.CommandStream:new {
    name = 'language',
    command = '/language ',
    shortCommand = '/lang ',
    helpTextID = 'help-text-switch-language',
    suggestSpec = { 'known-language' },
    isEnabled = function() return #API.player.getLanguages() > 1 end,
    onUse = function(ctx)
        local args = utils.parseCommandArgs(ctx.text)
        local command = args[1]
        if not command then
            API.chat.addInfoMessage(getText('help-text-switch-language'))
            return
        end

        local lang = API.search.matchLanguage(command)
        if not lang or not API.player.setCurrentLanguage(lang) then
            API.chat.addInfoMessage(getText('error-switch-unknown-language', { language = command }))
            return
        end
    end,
}
