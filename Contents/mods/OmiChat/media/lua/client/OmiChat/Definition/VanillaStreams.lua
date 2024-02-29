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
        aliases = { '/shout ' },
    },
    private = {
        commandType = 'chat',
        chatType = 'whisper',
        streamIdentifier = 'private',
        isEnabledCommand = '/w',
        suggestUsernames = true,
        appendResultToLast = true,
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
