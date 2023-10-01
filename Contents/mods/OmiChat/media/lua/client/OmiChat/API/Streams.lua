local OmiChat = require 'OmiChat/API/Base'
local utils = require 'OmiChat/util'

local concat = table.concat


---Helper for checking if a basic chat stream is enabled.
---@param self omichat.BaseStream
---@return boolean
local function chatIsEnabled(self)
    return checkPlayerCanUseChat(self.command)
end

---Helper for checking if a custom chat stream is enabled.
---@param self omichat.BaseStream
---@return boolean
local function customChatIsEnabled(self)
    return OmiChat.isCustomStreamEnabled(self.name)
end

---Helper for handling basic chat stream use.
---@param self omichat.ChatStream
---@param command string
local function chatOnUse(self, command)
    command = utils.trim(command)
    if #command == 0 then
        return
    end

    local ctx = self.omichat.context
    if ctx and ctx.ocProcess then
        ctx.ocProcess(command)
    else
        processSayMessage(command)
    end
end

---Helper for handling formatted chat stream use.
---@param self omichat.ChatStream
---@param command string
local function formattedChatOnUse(self, command)
    command = utils.trim(command)
    if #command == 0 then
        return
    end

    local ctx = self.omichat.context
    local name = ctx and ctx.formatterName or self.name

    local formatted = OmiChat.getFormatter(name):format(command)

    chatOnUse(self, formatted)
end

---@type table<string, omichat.ChatStreamConfig>
local streamOverrides = {
    say = {
        context = { ocProcess = processSayMessage },
        allowEmojiPicker = true,
        isEnabled = chatIsEnabled,
        onUse = chatOnUse,
    },
    yell = {
        context = { ocProcess = processShoutMessage },
        isEnabled = chatIsEnabled,
        onUse = chatOnUse,
    },
    private = {
        allowEmotes = false,
        isEnabled = function() return checkPlayerCanUseChat('/w') end,
        onUse = function(self, command)
            local username = proceedPM(command)
            local chatText = ISChat.instance.chatText
            chatText.lastChatCommand = concat { chatText.lastChatCommand, username, ' ' }
        end,
    },
    faction = {
        allowEmotes = false,
        context = { ocProcess = proceedFactionMessage },
        isEnabled = chatIsEnabled,
        onUse = chatOnUse,
    },
    safehouse = {
        allowEmotes = false,
        context = { ocProcess = processSafehouseMessage },
        isEnabled = chatIsEnabled,
        onUse = chatOnUse,
    },
    general = {
        allowEmotes = false,
        context = { ocProcess = processGeneralMessage },
        isEnabled = chatIsEnabled,
        onUse = chatOnUse,
    },
    admin = {
        allowEmotes = false,
        context = { ocProcess = processAdminChatMessage },
        isEnabled = chatIsEnabled,
        onUse = chatOnUse,
    }
}

---@type table<string, omichat.ChatStream>
local customStreams = {
    looc = {
        name = 'looc',
        command = '/looc ',
        shortCommand = '/l ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowEmojiPicker = true,
            isEnabled = customChatIsEnabled,
            onUse = formattedChatOnUse,
        }
    },
    whisper = {
        name = 'whisper',
        command = '/whisper ',
        shortCommand = '/w ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowEmojiPicker = true,
            context = { ocIsLocalWhisper = true },
            isEnabled = customChatIsEnabled,
            onUse = formattedChatOnUse,
        }
    },
    me = {
        name = 'me',
        command = '/me ',
        shortCommand = '/m ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowEmojiPicker = true,
            isEnabled = customChatIsEnabled,
            onUse = formattedChatOnUse,
        },
    },
    mewhisper = {
        name = 'mewhisper',
        command = '/mewhisper ',
        shortCommand = '/mew ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowEmojiPicker = true,
            isEnabled = customChatIsEnabled,
            onUse = formattedChatOnUse,
        }
    },
    meyell = {
        name = 'meyell',
        command = '/meyell ',
        shortCommand = '/mey ',
        tabID = 1,
        omichat = {
            context = { ocProcess = processShoutMessage },
            allowEmotes = true,
            allowEmojiPicker = false,
            isEnabled = customChatIsEnabled,
            onUse = formattedChatOnUse,
        }
    },
}

return {
    streamOverrides = streamOverrides,
    customStreams = customStreams
}
