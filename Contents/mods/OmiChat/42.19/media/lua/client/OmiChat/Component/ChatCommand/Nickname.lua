---Command stream definition for `/nickname`.
---@namespace omichat

local API = require 'OmiChat/Module/Core/Client'
local config = API.Configuration

return API.CommandStream:new {
    name = 'nickname',
    command = '/nickname ',
    helpTextID = 'help-text-nickname',
    isEnabled = function() return config:isNicknameCommandEnabled() end,
    onUse = function(ctx)
        local _, feedback = API.player.setNickname(ctx.text)
        if feedback then
            API.chat.addInfoMessage(feedback)
        end
    end,
}
