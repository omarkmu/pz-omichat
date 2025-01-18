---Compatibility patch for Buffy's Tabletop RPG System.

local API = require 'OmiChat/Client'
local config = API.Configuration

API.addMessageTransformer({
    name = 'handle-buffy-rpg',
    priority = 65,
    transform = function(_, info)
        if not config:compatBuffyRPGSystemEnabled() then
            return
        end

        local text = info:getCurrentText()
        local patt = '^.+<IMAGE:Item_Dice[%d,]+>%s+<RGB:([%d%.,]+)>%s*%[CRITICAL (.+)%!].+(rolled%s+.+:%s*%d.+)$'
        local critColor, crit, suffix = text:match(patt)

        if not suffix then
            suffix = text:match('^.+<IMAGE:Item_Dice[%d,]+>%s+.+(rolled%s+.+:%s*%d.+)$')
            if not suffix then
                return
            end
        end

        if info:isChatType('radio') then
            info:hide()
            return
        end

        info:setContent(suffix)
        info:addTags({ 'IsBuffyRoll' })
        info.tokens.buffyRoll = suffix

        if critColor and crit then
            info.tokens.buffyCrit = ' <PUSHRGB:' .. critColor .. '> [CRITICAL ' .. crit .. '!] <POPRGB> '
            info.tokens.buffyCritRaw = crit:lower()
        end

        local targetStream = API.getFirstChatStreamWithTag('BuffyRPGTarget')
        if targetStream then
            info:setStream(targetStream)
        end

        info:skipLanguageProcessing()
    end,
})
