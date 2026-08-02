---Command stream definition for `/emote`.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'
local config = API.Configuration

local concat = table.concat
local getText = API.utils.getText

return API.CommandStream:new {
    name = 'emote',
    command = '/emote ',
    helpTextID = 'help-text-emote',
    suggestSpec = { 'emote' },
    isEnabled = function() return config:isEmoteMacroEnabled() end,
    onUse = function(ctx)
        local text = ctx.text:trim()
        if text == 'list' then
            ctx.stream:onHelp()
            return
        end

        local player = API.player.get()
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
            getText('info-available-emotes'),
        }

        for i = 1, #names do
            local name = names[i]
            parts[#parts + 1] = ' <LINE> * '
            parts[#parts + 1] = name
        end

        if config:isEmoteMacroEnabled() then
            parts[#parts + 1] = ' <LINE> '
            parts[#parts + 1] = getText('info-available-emotes-with-macro')
        end

        parts[#parts + 1] = ' <LINE> '

        API.chat.addInfoMessage(concat(parts))
    end,
}
