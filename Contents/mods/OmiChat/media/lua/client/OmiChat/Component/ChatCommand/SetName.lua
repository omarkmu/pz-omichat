---@namespace omichat
---Command stream definition for `/setname`.

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'setname',
    command = '/setname ',
    helpTextID = 'UI_OmiChat_HelpText_SetName',
    suggestSpec = { 'online-username' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx) API.request.executeCommand('setName', ctx.text) end,
}
