---Command stream definition for `/emote`.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'
local config = API.Configuration

local concat = table.concat

return API.CommandStream:new {
    name = 'emote',
    command = '/emote ',
    helpTextID = 'UI_OmiChat_HelpText_Emote',
    suggestSpec = { 'emote' },
    isEnabled = function() return config:isEmoteMacroEnabled() end,
    onUse = function(ctx)
        local text = ctx.text:trim()
        if text == 'list' then
            ctx.stream:onHelp()
            return
        end

        local player = getSpecificPlayer(0)
        if not player then
            return
        end

        local emote = API.chat.getEmote(text)
        if not emote then
            ctx.stream:onHelp()
            return
        end

        emote:play(player, text)
    end,
    onHelp = function()
        local names = API.chat.getEmoteNames()

        -- no emotes → ignore
        if #names == 0 then
            return
        end

        local parts = {
            getText('UI_OmiChat_Info_AvailableEmotes'),
        }

        for i = 1, #names do
            local name = names[i]
            parts[#parts + 1] = ' <LINE> * '
            parts[#parts + 1] = name
        end

        parts[#parts + 1] = ' <LINE> '
        parts[#parts + 1] = getText('UI_OmiChat_Info_AvailableEmotes_WithMacro')
        parts[#parts + 1] = ' <LINE> '

        API.chat.addInfoMessage(concat(parts))
    end,
}
