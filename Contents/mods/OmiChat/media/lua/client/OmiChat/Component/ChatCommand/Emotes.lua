---Command stream definition for `/setlanguageslots`.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'
local config = API.Configuration

local concat = table.concat
local sort = table.sort

return API.CommandStream:new {
    name = 'emotes',
    command = '/emotes ',
    helpTextID = 'UI_OmiChat_HelpText_Emotes',
    isEnabled = function() return config:isEmoteMacroEnabled() end,
    onUse = function(ctx) ctx.stream:onHelp() end,
    onHelp = function()
        -- collect currently available emotes
        local emotes = {}
        for k in pairs(API._emotes) do
            emotes[#emotes + 1] = k
        end

        -- no emotes → ignore
        if #emotes == 0 then
            return
        end

        sort(emotes)

        local parts = {
            getText('UI_OmiChat_Info_AvailableEmotes'),
        }

        for i = 1, #emotes do
            parts[#parts + 1] = ' <LINE> * .'
            parts[#parts + 1] = emotes[i]
        end

        API.chat.addInfoMessage(concat(parts))
    end,
}
