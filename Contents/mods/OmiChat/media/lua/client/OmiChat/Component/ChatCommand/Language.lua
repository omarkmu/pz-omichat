---@namespace omichat
---Command stream definition for `/language`.

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils

return API.CommandStream:new {
    name = 'language',
    command = '/language ',
    shortCommand = '/lang ',
    helpTextID = 'UI_OmiChat_HelpText_SwitchLanguage',
    suggestSpec = { 'known-language' },
    isEnabled = function() return #API.player.getLanguages() > 1 end,
    onUse = function(ctx)
        local args = utils.parseCommandArgs(ctx.text)
        local command = args[1]
        if not command then
            API.chat.addInfoMessage(getText('UI_OmiChat_HelpText_SwitchLanguage'))
            return
        end

        local lang = API.search.matchLanguage(command)
        if not lang or not API.player.setCurrentLanguage(lang) then
            API.chat.addInfoMessage(getText('UI_OmiChat_Error_SwitchUnknownLanguage', command))
            return
        end

        lang = utils.getTranslatedLanguageName(lang)
        API.chat.addInfoMessage(getText('UI_OmiChat_Success_SwitchLanguage', lang))
    end,
}
