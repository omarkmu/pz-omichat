---Command stream definition for `/seticon`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils

return API.CommandStream:new {
    name = 'seticon',
    command = '/seticon ',
    helpTextID = 'UI_OmiChat_HelpText_SetIcon',
    suggestSpec = { 'online-username-with-self', 'icon' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        if API.request.executeCommand('setIcon', ctx.text) then
            return
        end

        local args = utils.parseCommandArgs(ctx.text)
        local icon = args[2]
        if not args[1] or not icon then
            ctx.stream:showHelpText()
        else
            API.chat.addInfoMessage(getText('UI_OmiChat_Info_IconUnknown', icon))
        end
    end,
}
