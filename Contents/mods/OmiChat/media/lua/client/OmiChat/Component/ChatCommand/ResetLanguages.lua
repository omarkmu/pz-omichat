---Command stream definition for `/resetlanguages`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'resetlanguages',
    command = '/resetlanguages ',
    helpTextID = 'UI_OmiChat_HelpText_ResetLanguages',
    suggestSpec = { 'online-username-with-self' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('resetLanguages', ctx.text)
    end,
}
