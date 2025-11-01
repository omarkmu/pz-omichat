---Command stream definition for `/nickname`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local config = API.Configuration

return API.CommandStream:new {
    name = 'nickname',
    command = '/nickname ',
    helpTextID = 'UI_OmiChat_HelpText_Nickname',
    isEnabled = function() return config:isNicknameCommandEnabled() end,
    onUse = function(ctx)
        local _, feedback = API.player.setNickname(ctx.text)
        if feedback then
            API.chat.addInfoMessage(feedback)
        end
    end,
}
