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
---| 'card'
---| 'roll'

---@alias omichat.FormatterName
---| omichat.CustomStreamName
---| 'callout'
---| 'sneakcallout'

---@class omichat.CustomStreamInfo
---@field name string The name of the custom stream.
---@field formatID integer The constant ID to use for message formatting.
---@field colorOpt string The name of the option used to determine message color.
---@field rangeOpt string The name of the option used to determine message range.
---@field chatFormatOpt string The name of the option used for the chat format.
---@field overheadFormatOpt string The name of the option used for the overhead format.
---@field showOnRadio boolean Whether messages sent on this stream should be visible over the radio.
---@field chatTypes table<omichat.ChatTypeString, true?> Chat types for which this stream is enabled.
---@field isCommand true? Whether this stream is a command stream.
---@field streamAlias string? An alias to use for determining color and range.
---@field stripColors boolean? Whether to strip colors from messages sent via this stream.
---@field allowColorCustomization false? Whether to allow color customization for this stream.
---@field defaultRangeOpt string? The option used for the default message range. Defaults to `RangeSay`.
---@field titleID string? The string ID to use for chat tags associated with this stream.
---@field attractZombies true? Whether messages sent with this stream should attract zombies.


---@type table<omichat.CustomStreamName, omichat.CustomStreamInfo>
local customStreamTable = {}

---@type omichat.CustomStreamInfo[]
local customStreamList = {
    -- chat streams (1–25)
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

    -- command streams (26–50)
    {
        name = 'roll',
        formatID = 26,
        isCommand = true,
        streamAlias = 'me',
        colorOpt = 'ColorMe',
        rangeOpt = 'RangeMe',
        chatFormatOpt = 'ChatFormatRoll',
        overheadFormatOpt = 'OverheadFormatRoll',
        chatTypes = { say = true },
        showOnRadio = false,
        allowColorCustomization = false,
    },
    {
        name = 'card',
        formatID = 27,
        isCommand = true,
        streamAlias = 'me',
        colorOpt = 'ColorMe',
        rangeOpt = 'RangeMe',
        chatFormatOpt = 'ChatFormatCard',
        overheadFormatOpt = 'OverheadFormatCard',
        chatTypes = { say = true },
        showOnRadio = false,
        allowColorCustomization = false,
    },
}

for _, v in pairs(customStreamList) do
    customStreamTable[v.name] = v
end

return {
    list = customStreamList,
    table = customStreamTable,
}
