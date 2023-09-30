---The names of default custom streams.
---@see omichat.api.client.getFormatter
---@alias omichat.CustomStreamName
---| 'looc'
---| 'me'
---| 'whisper'
---| 'whisperme'
---| 'yellme'

---@class omichat.CustomStreamInfo
---@field formatID integer
---@field colorOpt string
---@field rangeOpt string
---@field chatFormatOpt string
---@field overheadFormatOpt string
---@field showOnRadio boolean
---@field chatTypes table<omichat.ChatTypeString, boolean>
---@field defaultColor omichat.ColorTable?
---@field defaultRangeOpt string?
---@field titleID string?
---@field attractZombies boolean?

---Information about custom streams added by OmiChat.
---@type table<omichat.CustomStreamName, omichat.CustomStreamInfo>
return {
    me = {
        formatID = 1,
        defaultColor = {r = 130, g = 130, b = 130},
        colorOpt = 'MeColor',
        rangeOpt = 'MeRange',
        chatFormatOpt = 'MeChatFormat',
        overheadFormatOpt = 'MeOverheadFormat',
        chatTypes = { say = true },
        stripColors = true,
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    whisper = {
        formatID = 2,
        defaultColor = {r = 85, g = 48, b = 139},
        colorOpt = 'WhisperColor',
        rangeOpt = 'WhisperRange',
        chatFormatOpt = 'WhisperChatFormat',
        overheadFormatOpt = 'WhisperOverheadFormat',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = true,
    },
    looc = {
        formatID = 3,
        defaultColor = {r = 0, g = 128, b = 128},
        colorOpt = 'LoocColor',
        rangeOpt = 'LoocRange',
        chatFormatOpt = 'LoocChatFormat',
        overheadFormatOpt = 'LoocOverheadFormat',
        chatTypes = { say = true },
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    whisperme = {
        formatID = 4,
        defaultColor = {r = 130, g = 130, b = 130},
        colorOpt = 'MeColor',
        rangeOpt = 'WhisperRange',
        chatFormatOpt = 'MeChatFormat',
        overheadFormatOpt = 'MeOverheadFormat',
        chatTypes = { say = true },
        stripColors = true,
        allowColorCustomization = false,
        attractZombies = false,
        showOnRadio = false,
    },
    yellme = {
        formatID = 5,
        defaultColor = {r = 130, g = 130, b = 130},
        colorOpt = 'MeColor',
        rangeOpt = 'ShoutRange',
        defaultRangeOpt = 'ShoutRange',
        chatFormatOpt = 'MeChatFormat',
        overheadFormatOpt = 'MeOverheadFormat',
        chatTypes = { shout = true },
        stripColors = true,
        allowColorCustomization = false,
        attractZombies = false,
        showOnRadio = false,
    },
}
