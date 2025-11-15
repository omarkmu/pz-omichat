---Command stream definition for `/clear`.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local getText = API.utils.getText

-- reimplementing this because the vanilla clear doesn't actually clear the chatbox
return API.CommandStream:new {
    name = 'clear',
    command = '/clear ',
    isEnabled = function() return isAdmin() or isCoopHost() end,
    onUse = function()
        API.chat.clear()

        if not getDebug() then
            API.chat.addInfoMessage(getText('info-clear'))
        end
    end,
}
