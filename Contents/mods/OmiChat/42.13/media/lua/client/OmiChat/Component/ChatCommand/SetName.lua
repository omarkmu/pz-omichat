---Command stream definition for `/setname`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
require 'OmiChat/Module/Client/Player'

return API.CommandStream:new {
    name = 'setname',
    command = '/setname ',
    helpTextID = 'help-text-set-name',
    suggestSpec = { 'online-username' },
    isEnabled = API.player.isChatAdmin,
    defaultOnDisabled = false,
    onUse = function(ctx) API.request.executeCommand('setName', ctx.text) end,
}
