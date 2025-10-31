---@namespace omichat
---Command stream definition for `/iconinfo`.

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils

return API.CommandStream:new {
    name = 'iconinfo',
    command = '/iconinfo ',
    helpTextID = 'UI_OmiChat_HelpText_IconInfo',
    suggestSpec = { 'icon' },
    isEnabled = API.player.canUseAdminCommands,
    defaultOnDisabled = false,
    onUse = function(ctx)
        local command = utils.trim(ctx.text)
        if #command == 0 then
            ctx.stream:showHelpText()
            return
        end

        if getTexture(command) then
            local image = ' <SPACE> <IMAGE:' .. command .. ',15,14> '
            API.chat.addInfoMessage(getText('UI_OmiChat_Info_Icon', command, image))
            return
        end

        local textureName = utils.getTextureNameFromIcon(command)
        if not textureName or not getTexture(textureName) then
            API.chat.addInfoMessage(getText('UI_OmiChat_Info_IconUnknown', command))
            return
        end

        local image = ' <SPACE> <IMAGE:' .. textureName .. ',15,14> '
        API.chat.addInfoMessage(getText('UI_OmiChat_Info_IconAlias', textureName, image, command))
    end,
}
