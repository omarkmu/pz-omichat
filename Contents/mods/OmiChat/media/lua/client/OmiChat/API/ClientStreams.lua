---Chat stream definitions.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
local utils = OmiChat.utils

local concat = table.concat
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---Checks whether the stream associated with a basic chat is enabled.
---@param stream omichat.StreamInfo
---@return boolean
local function isBasicChatEnabled(stream)
    local ctx = stream:getContext()
    local cmd = ctx and ctx.ocIsEnabledCommand or stream:getCommand()
    return checkPlayerCanUseChat(cmd)
end

---Helper for checking if a custom chat stream is enabled.
---@param stream omichat.StreamInfo
---@return boolean
local function isCustomChatEnabled(stream)
    return OmiChat.isCustomStreamEnabled(stream:getName())
end

---Handler for basic chat streams.
---@param ctx omichat.UseCallbackContext
---@param formatterName string?
local function useBasicChat(ctx, formatterName)
    local command = utils.trim(ctx.command)
    if #command == 0 then
        return
    end

    local stream = ctx.stream
    command = OmiChat.formatForChat {
        text = command,
        chatType = stream:getChatType(),
        formatterName = formatterName,
        stream = stream:getIdentifier(),
        playSignedEmote = ctx.playSignedEmote,
    }

    local streamContext = stream:getContext()
    if streamContext and streamContext.ocProcess then
        local result = streamContext.ocProcess(command)
        if result and streamContext.ocAppendResultToLastCommand and OmiChat.getRetainCommand(stream:getCommandType()) then
            local chatText = ISChat.instance.chatText
            chatText.lastChatCommand = concat { chatText.lastChatCommand, result, ' ' }
        end
    else
        processSayMessage(command)
    end
end

---Helper for handling formatted chat stream use.
---@param ctx omichat.UseCallbackContext
local function useCustomChat(ctx)
    useBasicChat(ctx, ctx.stream:getName())
end


OmiChat._customChatStreams = {
    looc = {
        name = 'looc',
        command = '/looc ',
        shortCommand = '/l ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            commandType = 'chat',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    low = {
        name = 'low',
        command = '/low ',
        shortCommand = '/q ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            commandType = 'chat',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    whisper = {
        name = 'whisper',
        command = '/whisper ',
        shortCommand = '/w ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            commandType = 'chat',
            context = { ocIsLocalWhisper = true },
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    ['do'] = {
        name = 'do',
        command = '/do ',
        shortCommand = '/d ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            commandType = 'rp',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    doquiet = {
        name = 'doquiet',
        command = '/doquiet ',
        shortCommand = '/dq ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            commandType = 'rp',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    doloud = {
        name = 'doloud',
        command = '/doloud ',
        shortCommand = '/dl ',
        tabID = 1,
        omichat = {
            context = { ocProcess = processShoutMessage },
            allowEmotes = true,
            allowIconPicker = false,
            commandType = 'rp',
            chatType = 'shout',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    me = {
        name = 'me',
        command = '/me ',
        shortCommand = '/m ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            commandType = 'rp',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    mequiet = {
        name = 'mequiet',
        command = '/mequiet ',
        shortCommand = '/mq ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            commandType = 'rp',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
    meloud = {
        name = 'meloud',
        command = '/meloud ',
        shortCommand = '/ml ',
        tabID = 1,
        omichat = {
            context = { ocProcess = processShoutMessage },
            allowEmotes = true,
            allowIconPicker = false,
            commandType = 'rp',
            chatType = 'shout',
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
}

OmiChat._vanillaStreamConfigs = {
    say = {
        allowIconPicker = true,
        commandType = 'chat',
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = { ocIsEnabledCommand = '/s' },
    },
    yell = {
        commandType = 'chat',
        streamIdentifier = 'shout',
        chatType = 'shout',
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        aliases = { '/shout ' },
        context = {
            ocIsEnabledCommand = '/y',
            ocProcess = processShoutMessage,
        },
    },
    private = {
        allowEmotes = false,
        commandType = 'chat',
        streamIdentifier = 'private',
        chatType = 'whisper',
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocSuggestUsernames = true,
            ocSuggestOwnUsername = false,
            ocAppendResultToLastCommand = true,
            ocIsEnabledCommand = '/w',
            ocProcess = proceedPM,
        },
    },
    faction = {
        allowEmotes = false,
        commandType = 'chat',
        chatType = 'faction',
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/f',
            ocProcess = proceedFactionMessage,
        },
    },
    safehouse = {
        allowEmotes = false,
        commandType = 'chat',
        chatType = 'safehouse',
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/sh',
            ocProcess = processSafehouseMessage,
        },
    },
    general = {
        allowEmotes = false,
        commandType = 'chat',
        chatType = 'general',
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/all',
            ocProcess = processGeneralMessage,
        },
    },
    admin = {
        allowEmotes = false,
        commandType = 'chat',
        chatType = 'admin',
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/a',
            ocProcess = processAdminChatMessage,
        },
    },
}
