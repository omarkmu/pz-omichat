---@see omichat.api.client.getFormatter
---@alias omichat.CustomStreamName
---| 'do'
---| 'dowhisper'
---| 'doyell'
---| 'looc'
---| 'me'
---| 'mewhisper'
---| 'meyell'
---| 'whisper'

---@class omichat.CustomStreamInfo
---@field formatID integer
---@field colorOpt string
---@field rangeOpt string
---@field chatFormatOpt string
---@field overheadFormatOpt string
---@field showOnRadio boolean
---@field chatTypes table<omichat.ChatTypeString, boolean>
---@field defaultRangeOpt string?
---@field titleID string?
---@field attractZombies boolean?

---Information about custom streams added by OmiChat.
---@type table<omichat.CustomStreamName, omichat.CustomStreamInfo>
return {
    looc = {
        formatID = 1,
        colorOpt = 'ColorLooc',
        rangeOpt = 'RangeLooc',
        chatFormatOpt = 'ChatFormatLooc',
        overheadFormatOpt = 'OverheadFormatLooc',
        chatTypes = { say = true },
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    whisper = {
        formatID = 2,
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
    me = {
        formatID = 3,
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
    ['do'] = {
        formatID = 6,
        colorOpt = 'ColorDo',
        rangeOpt = 'RangeDo',
        chatFormatOpt = 'ChatFormatDo',
        overheadFormatOpt = 'OverheadFormatDo',
        chatTypes = { say = true },
        stripColors = true,
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    dowhisper = {
        formatID = 7,
        colorOpt = 'ColorDoWhisper',
        rangeOpt = 'RangeDoWhisper',
        chatFormatOpt = 'ChatFormatDoWhisper',
        overheadFormatOpt = 'OverheadFormatDoWhisper',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        stripColors = true,
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
    doyell = {
        formatID = 8,
        colorOpt = 'ColorDoYell',
        rangeOpt = 'RangeDoYell',
        chatFormatOpt = 'ChatFormatDoYell',
        overheadFormatOpt = 'OverheadFormatDoYell',
        defaultRangeOpt = 'RangeYell',
        chatTypes = { shout = true },
        stripColors = true,
        allowColorCustomization = true,
        attractZombies = false,
        showOnRadio = false,
    },
}
