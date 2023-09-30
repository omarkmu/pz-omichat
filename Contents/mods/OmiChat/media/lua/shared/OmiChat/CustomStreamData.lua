---The names of default custom streams.
---@see omichat.api.client.getFormatter
---@alias omichat.CustomStreamName
---| 'looc'
---| 'me'
---| 'whisper'

---@class omichat.CustomStreamInfo
---@field formatId integer
---@field colorOpt string
---@field rangeOpt string
---@field chatFormatOpt string
---@field overheadFormatOpt string
---@field chatTypes table<string, boolean>
---@field defaultColor omichat.ColorTable?
---@field titleID string?
---@field attractZombies boolean?

---Information about custom streams added by OmiChat.
---@type table<omichat.CustomStreamName, omichat.CustomStreamInfo>
return {
    me = {
        formatId = 1,
        defaultColor = {r = 130, g = 130, b = 130},
        colorOpt = 'MeColor',
        rangeOpt = 'MeRange',
        chatFormatOpt = 'MeChatFormat',
        overheadFormatOpt = 'MeOverheadFormat',
        chatTypes = { say = true },
        stripColors = true,
        allowColorCustomization = true,
        -- generally, described actions should not be heard
        attractZombies = false,
    },
    whisper = {
        formatId = 2,
        defaultColor = {r = 85, g = 48, b = 139},
        colorOpt = 'WhisperColor',
        rangeOpt = 'WhisperRange',
        chatFormatOpt = 'WhisperChatFormat',
        overheadFormatOpt = 'WhisperOverheadFormat',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        allowColorCustomization = true,
        attractZombies = false,
    },
    looc = {
        formatId = 3,
        defaultColor = {r = 0, g = 128, b = 128},
        colorOpt = 'LoocColor',
        rangeOpt = 'LoocRange',
        chatFormatOpt = 'LoocChatFormat',
        overheadFormatOpt = 'LoocOverheadFormat',
        chatTypes = { say = true },
        allowColorCustomization = true,
        attractZombies = false,
    },
}
