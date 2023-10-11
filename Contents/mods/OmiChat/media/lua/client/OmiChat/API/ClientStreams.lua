---Chat stream definitions.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
local utils = OmiChat.utils

local concat = table.concat
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---Checks whether the stream associated with a basic chat is enabled.
---@param stream omichat.ChatStream
---@return boolean
local function isBasicChatEnabled(stream)
    local ctx = stream.omichat and stream.omichat.context
    local cmd = ctx and ctx.ocIsEnabledCommand or stream.command
    return checkPlayerCanUseChat(cmd)
end

---Helper for checking if a custom chat stream is enabled.
---@param self omichat.BaseStream
---@return boolean
local function isCustomChatEnabled(self)
    return OmiChat.isCustomStreamEnabled(self.name)
end

---Handler for basic chat streams.
---@param stream omichat.ChatStream
---@param command string
local function useBasicChat(stream, command)
    command = utils.trim(command)
    if #command == 0 then
        return
    end

    local ctx = stream.omichat.context
    if ctx and ctx.ocProcess then
        local result = ctx.ocProcess(command)
        if result and ctx.ocAppendResultToLastCommand then
            local chatText = ISChat.instance.chatText
            chatText.lastChatCommand = concat { chatText.lastChatCommand, result, ' ' }
        end
    else
        processSayMessage(command)
    end
end

---Helper for handling formatted chat stream use.
---@param self omichat.ChatStream
---@param command string
local function useCustomChat(self, command)
    command = utils.trim(command)
    if #command == 0 then
        return
    end

    useBasicChat(self, OmiChat.getFormatter(self.name):format(command))
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
            isEnabled = isCustomChatEnabled,
            onUse = useCustomChat,
        },
    },
}

OmiChat._vanillaStreamConfigs = {
    say = {
        allowIconPicker = true,
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = { ocIsEnabledCommand = '/s' },
    },
    yell = {
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/y',
            ocProcess = processShoutMessage,
        },
    },
    private = {
        allowEmotes = false,
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocSuggestUsernames = true,
            ocAppendResultToLastCommand = true,
            ocIsEnabledCommand = '/w',
            ocProcess = proceedPM,
        },
    },
    faction = {
        allowEmotes = false,
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/f',
            ocProcess = proceedFactionMessage,
        },
    },
    safehouse = {
        allowEmotes = false,
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/sh',
            ocProcess = processSafehouseMessage,
        },
    },
    general = {
        allowEmotes = false,
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/all',
            ocProcess = processGeneralMessage,
        },
    },
    admin = {
        allowEmotes = false,
        isEnabled = isBasicChatEnabled,
        onUse = useBasicChat,
        context = {
            ocIsEnabledCommand = '/a',
            ocProcess = processAdminChatMessage,
        },
    },
}
