---Configuration of custom streams and formatters.
---@class omichat.Configuration
---@field private _streamTable table<omichat.CustomStreamName, omichat.CustomStreamInfo>
---@field private _streamList omichat.CustomStreamInfo[]
---@field private _chatStreams omichat.CustomStreamInfo[]
---@field private _formatters omichat.FormatterInfo[]
local Configuration = {}
Configuration._streamList = {}
Configuration._streamTable = {}


-- IDs 1–32 are reserved for encoding additional data

-- command streams (33–50)
Configuration._commandStreams = {
    {
        name = 'roll',
        formatID = 33,
        streamAlias = 'me',
        colorOpt = 'ColorMe',
        rangeOpt = 'RangeMe',
        chatFormatOpt = 'ChatFormatRoll',
        overheadFormatOpt = 'OverheadFormatRoll',
        chatTypes = { say = true },
        autoColorOption = false,
        ignoreLanguage = true,
    },
    {
        name = 'card',
        formatID = 34,
        streamAlias = 'me',
        colorOpt = 'ColorMe',
        rangeOpt = 'RangeMe',
        chatFormatOpt = 'ChatFormatCard',
        overheadFormatOpt = 'OverheadFormatCard',
        chatTypes = { say = true },
        autoColorOption = false,
        ignoreLanguage = true,
    },
}

-- chat streams (51–75)
Configuration._chatStreams = {
    {
        name = 'low',
        formatID = 51,
        colorOpt = 'ColorLow',
        rangeOpt = 'RangeLow',
        chatFormatOpt = 'ChatFormatLow',
        overheadFormatOpt = 'OverheadFormatLow',
        titleID = 'UI_OmiChat_low_chat_title_id',
        chatTypes = { say = true },
        convertToRadio = true,
    },
    {
        name = 'whisper',
        formatID = 52,
        colorOpt = 'ColorWhisper',
        rangeOpt = 'RangeWhisper',
        chatFormatOpt = 'ChatFormatWhisper',
        overheadFormatOpt = 'OverheadFormatWhisper',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        convertToRadio = true,
    },
    {
        name = 'me',
        formatID = 53,
        colorOpt = 'ColorMe',
        rangeOpt = 'RangeMe',
        chatFormatOpt = 'ChatFormatMe',
        overheadFormatOpt = 'OverheadFormatMe',
        chatTypes = { say = true },
        stripColors = true,
        ignoreLanguage = true,
    },
    {
        name = 'mequiet',
        formatID = 54,
        colorOpt = 'ColorMeQuiet',
        rangeOpt = 'RangeMeQuiet',
        chatFormatOpt = 'ChatFormatMeQuiet',
        overheadFormatOpt = 'OverheadFormatMeQuiet',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        stripColors = true,
        ignoreLanguage = true,
    },
    {
        name = 'meloud',
        formatID = 55,
        colorOpt = 'ColorMeLoud',
        rangeOpt = 'RangeMeLoud',
        defaultRangeOpt = 'RangeYell',
        chatFormatOpt = 'ChatFormatMeLoud',
        overheadFormatOpt = 'OverheadFormatMeLoud',
        chatTypes = { shout = true },
        stripColors = true,
        attractZombies = true,
        ignoreLanguage = true,
    },
    {
        name = 'do',
        formatID = 56,
        colorOpt = 'ColorDo',
        rangeOpt = 'RangeDo',
        chatFormatOpt = 'ChatFormatDo',
        overheadFormatOpt = 'OverheadFormatDo',
        chatTypes = { say = true },
        stripColors = true,
        ignoreLanguage = true,
    },
    {
        name = 'doquiet',
        formatID = 57,
        colorOpt = 'ColorDoQuiet',
        rangeOpt = 'RangeDoQuiet',
        chatFormatOpt = 'ChatFormatDoQuiet',
        overheadFormatOpt = 'OverheadFormatDoQuiet',
        titleID = 'UI_OmiChat_whisper_chat_title_id',
        chatTypes = { say = true },
        stripColors = true,
        ignoreLanguage = true,
    },
    {
        name = 'doloud',
        formatID = 58,
        colorOpt = 'ColorDoLoud',
        rangeOpt = 'RangeDoLoud',
        chatFormatOpt = 'ChatFormatDoLoud',
        overheadFormatOpt = 'OverheadFormatDoLoud',
        defaultRangeOpt = 'RangeYell',
        chatTypes = { shout = true },
        stripColors = true,
        attractZombies = true,
        ignoreLanguage = true,
    },
    {
        name = 'looc',
        formatID = 59,
        colorOpt = 'ColorLooc',
        rangeOpt = 'RangeLooc',
        chatFormatOpt = 'ChatFormatLooc',
        overheadFormatOpt = 'OverheadFormatLooc',
        chatTypes = { say = true },
        ignoreLanguage = true,
    },
}

-- other formatters (76–100)
Configuration._formatters = {
    {
        name = 'callout',
        formatID = 76,
    },
    {
        name = 'sneakcallout',
        formatID = 77,
    },
    {
        name = 'language',
        formatID = 78,
    },
    {
        name = 'overhead',
        formatID = 79,
        overheadFormatOpt = 'OverheadFormatFull',
    },
    {
        name = 'adminIcon',
        formatID = 80,
    },
}


---Returns an iterator over custom chat stream information.
---@return fun(): omichat.CustomStreamInfo?
function Configuration:chatStreams()
    local i = 0
    return function()
        i = i + 1
        return self._chatStreams[i]
    end
end

---Returns an iterator over custom command stream information.
---@return fun(): omichat.CustomStreamInfo?
function Configuration:commandStreams()
    local i = 0
    return function()
        i = i + 1
        return self._commandStreams[i]
    end
end

---Returns an iterator over custom formatter information.
---@return fun(): omichat.FormatterInfo?
function Configuration:formatters()
    local i = 0
    return function()
        i = i + 1
        local info
        if i <= #self._streamList then
            info = self._streamList[i]
        elseif i - #self._streamList <= #self._formatters then
            info = self._formatters[i - #self._streamList]
        end

        if info then
            return {
                name = info.name,
                formatID = info.formatID,
                overheadFormatOpt = info.overheadFormatOpt,
            }
        end
    end
end

---Returns information about a custom stream.
---@param streamName string?
---@return omichat.CustomStreamInfo?
function Configuration:getCustomStreamInfo(streamName)
    return self._streamTable[streamName]
end

---Returns the overhead format option name for a custom stream.
---@param streamName string
---@return string?
function Configuration:getOverheadFormatOption(streamName)
    local stream = self._streamTable[streamName]
    return stream and stream.overheadFormatOpt
end

---@private
function Configuration:init()
    for i = 1, #self._chatStreams do
        self._streamList[#self._streamList + 1] = self._chatStreams[i]
    end

    for i = 1, #self._commandStreams do
        self._streamList[#self._streamList + 1] = self._commandStreams[i]
    end

    for stream in Configuration:streams() do
        self._streamTable[stream.name] = stream
    end

    return self
end

---Returns an iterator over custom stream information.
---@return fun(): omichat.CustomStreamInfo?
function Configuration:streams()
    local i = 0
    return function()
        i = i + 1
        return self._streamList[i]
    end
end


return Configuration:init()
