---Command stream definition for `/iconinfo`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local getText = utils.getText

return API.CommandStream:new {
    name = 'iconinfo',
    command = '/iconinfo ',
    helpTextID = 'help-text-icon-info',
    suggestSpec = { 'icon' },
    isEnabled = API.player.isChatAdmin,
    defaultOnDisabled = false,
    onUse = function(ctx)
        local command = utils.trim(ctx.text)
        if #command == 0 then
            ctx.stream:showHelpText()
            return
        end

        if getTexture(command) then
            local icon = ' <SPACE> <IMAGE:' .. command .. ',15,14> '
            API.chat.addInfoMessage(getText('info-icon', { name = command, icon = icon }))
            return
        end

        local textureName = utils.getTextureNameFromIcon(command)
        if not textureName or not getTexture(textureName) then
            API.chat.addInfoMessage(getText('info-icon-unknown', { name = command }))
            return
        end

        local image = ' <SPACE> <IMAGE:' .. textureName .. ',15,14> '
        API.chat.addInfoMessage(getText('info-icon-alias', {
            name = textureName,
            icon = image,
            alias = command,
        }))
    end,
}
