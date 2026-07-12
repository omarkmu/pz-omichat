---Command stream definition for `/setlanguageslots`.
---@namespace omichat

local API = require 'OmiChat/Module/Core/Client'
require 'OmiChat/Module/Client/Player'

return API.CommandStream:new {
    name = 'setlanguageslots',
    command = '/setlanguageslots ',
    helpTextID = 'help-text-set-language-slots',
    suggestSpec = { 'online-username-with-self' },
    isEnabled = API.player.isChatAdmin,
    defaultOnDisabled = false,
    onUse = function(ctx)
        API.request.executeCommand('setLanguageSlots', ctx.text)
    end,
}
