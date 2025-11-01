---Command stream definition for `/resetname`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'resetname',
    command = '/resetname ',
    helpTextID = 'UI_OmiChat_HelpText_ResetName',
    suggestSpec = { 'online-username' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('resetName', ctx.text)
    end,
}
