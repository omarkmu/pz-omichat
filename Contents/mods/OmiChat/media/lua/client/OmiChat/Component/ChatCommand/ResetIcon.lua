---Command stream definition for `/reseticon`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'reseticon',
    command = '/reseticon ',
    helpTextID = 'help-text-reset-icon',
    suggestSpec = { 'online-username-with-self' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('resetIcon', ctx.text)
    end,
}
