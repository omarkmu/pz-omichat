---@namespace omichat
---Command stream definition for `/setlanguageslots`.

local API = require 'OmiChat/Module/Client/Core'

return API.CommandStream:new {
    name = 'setlanguageslots',
    command = '/setlanguageslots ',
    helpTextID = 'UI_OmiChat_HelpText_SetLanguageSlots',
    suggestSpec = { 'online-username-with-self' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('setLanguageSlots', ctx.text)
    end,
}
