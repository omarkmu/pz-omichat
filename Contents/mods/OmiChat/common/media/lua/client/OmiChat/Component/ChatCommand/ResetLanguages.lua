---Command stream definition for `/resetlanguages`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'resetlanguages',
    command = '/resetlanguages ',
    helpTextID = 'help-text-reset-languages',
    suggestSpec = { 'online-username-with-self' },
    isEnabled = API.player.isChatAdmin,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('resetLanguages', ctx.text)
    end,
}
