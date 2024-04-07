local OmiChat = require 'OmiChat/API/Client'

---@type table<string, omichat.ChatStreamConfig>
return {
    say = {
        commandType = 'chat',
        isEnabledCommand = '/s',
        allowIconPicker = true,
    },
    yell = {
        commandType = 'chat',
        chatType = 'shout',
        streamIdentifier = 'shout',
        isEnabledCommand = '/y',
    },
    private = {
        commandType = 'chat',
        chatType = 'whisper',
        streamIdentifier = 'private',
        isEnabledCommand = '/w',
        suggestSpec = { 'online-username' },
        appendResultToLast = true,
        validator = function(_, input)
            -- vanilla regex is /("[^"]*\s+[^"]*"|[^"]\S*)\s(.+)/
            if input:match('^"[^"]*%s+[^"]*"%s.+$') or input:match('^[^"]%S*%s.+$') then
                return true
            end

            OmiChat.addInfoMessage(getText('IGUI_Commands_Whisper'))
            return false
        end,
    },
    faction = {
        commandType = 'chat',
        chatType = 'faction',
        isEnabledCommand = '/f',
    },
    safehouse = {
        commandType = 'chat',
        chatType = 'safehouse',
        isEnabledCommand = '/sh',
    },
    general = {
        commandType = 'chat',
        chatType = 'general',
        isEnabledCommand = '/all',
    },
    admin = {
        commandType = 'chat',
        chatType = 'admin',
        isEnabledCommand = '/a',
    },
}
