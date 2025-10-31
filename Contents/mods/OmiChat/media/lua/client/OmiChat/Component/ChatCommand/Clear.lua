---@namespace omichat
---Command stream definition for `/clear`.

local API = require 'OmiChat/Module/Client/Core'

-- reimplementing this because the vanilla clear doesn't actually clear the chatbox
return API.CommandStream:new {
    name = 'clear',
    command = '/clear ',
    isEnabled = function() return isAdmin() or isCoopHost() end,
    onUse = function()
        API.chat.clear()

        if not getDebug() then
            API.chat.addInfoMessage(getText('UI_OmiChat_Info_Clear'))
        end
    end,
}
