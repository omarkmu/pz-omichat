---@see omichat.api.client.getFormatter
---@alias omichat.CustomStreamName
---| 'looc'
---| 'me'
---| 'whisper'
---| 'mewhisper'
---| 'meyell'

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
        colorOpt = 'ColorMe',
        rangeOpt = 'RangeMe',
        chatFormatOpt = 'ChatFormatMe',
        overheadFormatOpt = 'OverheadFormatMe',
        chatTypes = { say = true },
        stripColors = true,
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    whisper = {
        formatID = 2,
        defaultColor = {r = 85, g = 48, b = 139},
        colorOpt = 'ColorWhisper',
        rangeOpt = 'RangeWhisper',
        chatFormatOpt = 'ChatFormatWhisper',
        overheadFormatOpt = 'OverheadFormatWhisper',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = true,
    },
    looc = {
        formatID = 3,
        colorOpt = 'ColorLooc',
        rangeOpt = 'RangeLooc',
        chatFormatOpt = 'ChatFormatLooc',
        overheadFormatOpt = 'OverheadFormatLooc',
        chatTypes = { say = true },
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    mewhisper = {
        formatID = 4,
        colorOpt = 'ColorMeWhisper',
        rangeOpt = 'RangeMeWhisper',
        chatFormatOpt = 'ChatFormatMeWhisper',
        overheadFormatOpt = 'OverheadFormatMeWhisper',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        stripColors = true,
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    meyell = {
        formatID = 5,
        colorOpt = 'ColorMeYell',
        rangeOpt = 'RangeMeYell',
        defaultRangeOpt = 'RangeYell',
        chatFormatOpt = 'ChatFormatMeYell',
        overheadFormatOpt = 'OverheadFormatMeYell',
        chatTypes = { shout = true },
        stripColors = true,
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
}
