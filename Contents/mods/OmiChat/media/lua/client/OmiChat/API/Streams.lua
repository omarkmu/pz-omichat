local OmiChat = require 'OmiChat/API/Client'
local utils = require 'OmiChat/util'

local concat = table.concat

---@class omichat.ISChat
local ISChat = ISChat


---Helper for checking if a basic chat stream is enabled.
---@param self omichat.BaseStream
---@return boolean
local function chatIsEnabled(self)
    return checkPlayerCanUseChat(self.command)
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

---Helper for checking if a custom chat stream is enabled.
---@param self omichat.BaseStream
---@return boolean
local function customChatIsEnabled(self)
    return OmiChat.isCustomStreamEnabled(self.name)
end

---Helper for handling formatted chat stream use.
---@param self omichat.ChatStream
---@param command string
local function customChatOnUse(self, command)
    command = utils.trim(command)
    if #command == 0 then
        return
    end

    chatOnUse(self, OmiChat.getFormatter(self.name):format(command))
end

---@type table<string, omichat.ChatStreamConfig>
local streamOverrides = {
    say = {
        context = { ocProcess = processSayMessage },
        allowIconPicker = true,
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
            allowIconPicker = true,
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
        }
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
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
        }
    },
    ['do'] = {
        name = 'do',
        command = '/do ',
        shortCommand = '/d ',
        tabID = 1,
        omichat = {
            allowEmotes = true,
            allowIconPicker = true,
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
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
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
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
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
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
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
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
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
        }
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
            isEnabled = customChatIsEnabled,
            onUse = customChatOnUse,
        }
    },
}

return {
    streamOverrides = streamOverrides,
    customStreams = customStreams
}
