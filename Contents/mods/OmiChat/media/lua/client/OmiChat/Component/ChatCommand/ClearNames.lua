---@namespace omichat
---Command stream definition for `/clearnames`.

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'clearnames',
    command = '/clearnames ',
    helpTextID = 'UI_OmiChat_HelpText_ClearNames',
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function() API.request.executeCommand('clearNames') end,
}
