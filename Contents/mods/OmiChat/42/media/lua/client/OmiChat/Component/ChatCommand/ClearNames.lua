---Command stream definition for `/clearnames`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'clearnames',
    command = '/clearnames ',
    helpTextID = 'help-text-clear-names',
    isEnabled = API.player.isChatAdmin,
    defaultOnDisabled = false,
    onUse = function() API.request.executeCommand('clearNames') end,
}
