---Command stream definition for `/seticon`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local getText = utils.getText

return API.CommandStream:new {
    name = 'seticon',
    command = '/seticon ',
    helpTextID = 'help-text-set-icon',
    suggestSpec = { 'online-username-with-self', 'icon' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        if API.request.executeCommand('setIcon', ctx.text) then
            return
        end

        local args = utils.parseCommandArgs(ctx.text)
        local name = args[2]
        if not args[1] or not name then
            ctx.stream:showHelpText()
        else
            API.chat.addInfoMessage(getText('info-icon-unknown', { name = name }))
        end
    end,
}
