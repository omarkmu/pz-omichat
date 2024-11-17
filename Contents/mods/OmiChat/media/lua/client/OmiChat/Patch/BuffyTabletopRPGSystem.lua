---Compatibility patch for Buffy's Tabletop RPG System.

local API = require 'OmiChat/Client'
local Option = API.Option

API.addMessageTransformer({
    name = 'handle-buffy-rpg',
    priority = 49,
    transform = function(_, info)
        if not Option:compatBuffyRPGSystemEnabled() then
            return
        end

        local text = info.content or info.rawText

        local patt = '^.+<IMAGE:Item_Dice[%d,]+>%s+<RGB:([%d%.,]+)>%s*%[CRITICAL (.+)%!].+(rolled%s+.+:%s*%d.+)$'
        local critColor, crit, suffix = text:match(patt)

        if not suffix then
            suffix = text:match('^.+<IMAGE:Item_Dice[%d,]+>%s+.+(rolled%s+.+:%s*%d.+)$')
            if not suffix then
                return
            end
        end

        info.content = suffix
        info.tokens.buffyRoll = suffix

        if critColor and crit then
            info.tokens.buffyCrit = ' <PUSHRGB:' .. critColor .. '> [CRITICAL ' .. crit .. '!] <POPRGB> '
            info.tokens.buffyCritRaw = crit:lower()
        end

        if API.isCustomStreamEnabled('me') then
            info.tokens.stream = 'me'
            info.context.ocCustomStream = 'me'
            info.format = Option.ChatFormatMe
            info.formatOptions.color = API.getColorOrDefault('me')
        end

        info.context.ocSkipLanguage = true
    end,
})
