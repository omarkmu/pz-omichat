---Compatibility patch for Buffy's Character Bios.

local OmiChat = require 'OmiChatClient'
local Option = OmiChat.Option
local utils = OmiChat.utils

OmiChat.addMessageTransformer({
    name = 'handle-buffy-character-bios',
    priority = 34,
    transform = function(_, info)
        if info.context.ocIsOtherOverhead or info.tokens.customStream or info.context.ocCustomStream then
            return
        end

        if info.chatType ~= 'say' or not Option:compatBuffyCharacterBiosEnabled() then
            return
        end

        local text = info.content or info.rawText
        if not text:match('^.+ updated their description%.$') and not text:match('^.+ updated their portrait%.$') then
            return
        end

        if info.context.ocIsRadio then
            info.message:setShowInChat(false)
            info.message:setOverHeadSpeech(false)
            return
        end

        info.chatType = 'server'
        info.tokens.stream = 'server'
        info.titleID = 'UI_chat_server_chat_title_id'
        info.format = Option.ChatFormatServer
        info.formatOptions.color = OmiChat.getColorOrDefault('server')
        info.formatOptions.useDefaultChatColor = false
        info.context.ocSkipLanguage = true

        local authorEnd = utils.getAuthorEndPos(text, info.author)
        if authorEnd then
            info.content = text:sub(authorEnd + 1)
        end
    end,
})
