---Information about custom streams added by OmiChat.

---@see omichat.api.client.getFormatter
---@alias omichat.CustomStreamName
---| 'whisper'
---| 'me'
---| 'mequiet'
---| 'meloud'
---| 'do'
---| 'doquiet'
---| 'doloud'
---| 'looc'

---@class omichat.CustomStreamInfo
---@field name string
---@field formatID integer
---@field colorOpt string
---@field rangeOpt string
---@field chatFormatOpt string
---@field overheadFormatOpt string
---@field showOnRadio boolean
---@field chatTypes table<omichat.ChatTypeString, boolean>
---@field stripColors boolean?
---@field allowColorCustomization false?
---@field defaultRangeOpt string?
---@field titleID string?
---@field attractZombies true?


---@type table<omichat.CustomStreamName, omichat.CustomStreamInfo>
local customStreamTable = {}

---@type omichat.CustomStreamInfo[]
local customStreamList = {
    {
        name = 'whisper',
        formatID = 1,
        colorOpt = 'ColorWhisper',
        rangeOpt = 'RangeWhisper',
        chatFormatOpt = 'ChatFormatWhisper',
        overheadFormatOpt = 'OverheadFormatWhisper',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        showOnRadio = true,
    },
    {
        name = 'me',
        formatID = 2,
        colorOpt = 'ColorMe',
        rangeOpt = 'RangeMe',
        chatFormatOpt = 'ChatFormatMe',
        overheadFormatOpt = 'OverheadFormatMe',
        chatTypes = { say = true },
        stripColors = true,
        showOnRadio = false,
    },
    {
        name = 'mequiet',
        formatID = 3,
        colorOpt = 'ColorMeQuiet',
        rangeOpt = 'RangeMeQuiet',
        chatFormatOpt = 'ChatFormatMeQuiet',
        overheadFormatOpt = 'OverheadFormatMeQuiet',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        stripColors = true,
        showOnRadio = false,
    },
    {
        name = 'meloud',
        formatID = 4,
        colorOpt = 'ColorMeLoud',
        rangeOpt = 'RangeMeLoud',
        defaultRangeOpt = 'RangeYell',
        chatFormatOpt = 'ChatFormatMeLoud',
        overheadFormatOpt = 'OverheadFormatMeLoud',
        chatTypes = { shout = true },
        stripColors = true,
        showOnRadio = false,
    },
    {
        name = 'do',
        formatID = 5,
        colorOpt = 'ColorDo',
        rangeOpt = 'RangeDo',
        chatFormatOpt = 'ChatFormatDo',
        overheadFormatOpt = 'OverheadFormatDo',
        chatTypes = { say = true },
        stripColors = true,
        showOnRadio = false,
    },
    {
        name = 'doquiet',
        formatID = 6,
        colorOpt = 'ColorDoQuiet',
        rangeOpt = 'RangeDoQuiet',
        chatFormatOpt = 'ChatFormatDoQuiet',
        overheadFormatOpt = 'OverheadFormatDoQuiet',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        stripColors = true,
        showOnRadio = false,
    },
    {
        name = 'doloud',
        formatID = 7,
        colorOpt = 'ColorDoLoud',
        rangeOpt = 'RangeDoLoud',
        chatFormatOpt = 'ChatFormatDoLoud',
        overheadFormatOpt = 'OverheadFormatDoLoud',
        defaultRangeOpt = 'RangeYell',
        chatTypes = { shout = true },
        stripColors = true,
        showOnRadio = false,
    },
    {
        name = 'looc',
        formatID = 8,
        colorOpt = 'ColorLooc',
        rangeOpt = 'RangeLooc',
        chatFormatOpt = 'ChatFormatLooc',
        overheadFormatOpt = 'OverheadFormatLooc',
        chatTypes = { say = true },
        showOnRadio = false,
    },
}

for _, v in pairs(customStreamList) do
    customStreamTable[v.name] = v
end

return {
    list = customStreamList,
    table = customStreamTable,
}
