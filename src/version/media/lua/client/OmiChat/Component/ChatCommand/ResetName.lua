---Command stream definition for `/resetname`.
---@namespace omichat

local API = require 'OmiChat/Module/Core/Client'
require 'OmiChat/Module/Client/Player'

return API.CommandStream:new {
    name = 'resetname',
    command = '/resetname ',
    helpTextID = 'help-text-reset-name',
    suggestSpec = { 'online-username' },
    isEnabled = API.player.isChatAdmin,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('resetName', ctx.text)
    end,
}
