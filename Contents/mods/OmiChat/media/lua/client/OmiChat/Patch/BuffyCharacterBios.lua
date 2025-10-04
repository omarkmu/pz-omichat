---Compatibility patch for Buffy's Character Bios.

local API = require 'OmiChat/Client'
local config = API.Configuration
local utils = API.utils

API.extension.addMessageTransformer({
    name = 'handle-buffy-character-bios',
    priority = 55,
    transform = function(_, info)
        if not config:compatBuffyCharacterBiosEnabled() then
            return
        end

        local text = info:getCurrentText()
        if not text:match('^.+ updated their description%.$') and not text:match('^.+ updated their portrait%.$') then
            return
        end

        local chatType = info:getChatType()
        if chatType == 'radio' then
            info:hide()
            return
        elseif chatType ~= 'say' then
            return
        end

        info:skipLanguageProcessing()
        info:setStream(API.streams.getServerStream(), { forceFormat = true, overwriteTags = true })

        local author = info:getAuthor()
        local _, authorEnd = text:find('%[' .. utils.escape(author) .. '%]:')
        if authorEnd then
            info:setContent(text:sub(authorEnd + 1))
        end
    end,
})
