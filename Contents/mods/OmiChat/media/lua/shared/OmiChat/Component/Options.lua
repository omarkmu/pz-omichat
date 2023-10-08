local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'
local customStreams = require 'OmiChat/Data/CustomStreams'

local floor = math.floor


---Helper for retrieving sandbox variables and their defaults.
---@class omichat.Options : omi.Sandbox
---@field EnableCustomShouts boolean
---@field EnableCustomSneakShouts boolean
---@field EnableEmotes boolean
---@field EnableSetName boolean
---@field EnableSetNameColor boolean
---@field EnableSpeechColorAsDefaultNameColor boolean
---@field EnableSetSpeechColor boolean
---@field EnableIconPicker boolean
---@field EnableMiscellaneousIcons boolean
---@field EnableCompatTAD boolean
---@field EnableChatNameAsCharacterName boolean
---@field CustomShoutMaxLength integer
---@field MinimumCommandAccessLevel integer
---@field MaximumCustomShouts integer
---@field RangeDo integer
---@field RangeDoLoud integer
---@field RangeDoQuiet integer
---@field RangeMe integer
---@field RangeMeLoud integer
---@field RangeMeQuiet integer
---@field RangeLooc integer
---@field RangeSay integer
---@field RangeWhisper integer
---@field RangeYell integer
---@field ColorLooc string
---@field ColorDo string
---@field ColorDoQuiet string
---@field ColorDoLoud string
---@field ColorMe string
---@field ColorMeQuiet string
---@field ColorMeLoud string
---@field ColorSay string
---@field ColorWhisper string
---@field ColorYell string
---@field ColorAdmin string
---@field ColorGeneral string
---@field ColorDiscord string
---@field ColorRadio string
---@field ColorFaction string
---@field ColorSafehouse string
---@field ColorPrivate string
---@field ColorServer string
---@field FilterNickname string
---@field PredicateUseNameColor string
---@field FormatCard string
---@field FormatRoll string
---@field FormatInfo string
---@field FormatMenuName string
---@field FormatName string
---@field FormatTag string
---@field FormatTimestamp string
---@field OverheadFormatCard string
---@field OverheadFormatRoll string
---@field OverheadFormatDo string
---@field OverheadFormatDoLoud string
---@field OverheadFormatDoQuiet string
---@field OverheadFormatMe string
---@field OverheadFormatWhisper string
---@field OverheadFormatMeQuiet string
---@field OverheadFormatMeLoud string
---@field OverheadFormatLooc string
---@field ChatFormatCard string
---@field ChatFormatRoll string
---@field ChatFormatDo string
---@field ChatFormatDoQuiet string
---@field ChatFormatDoLoud string
---@field ChatFormatMe string
---@field ChatFormatMeQuiet string
---@field ChatFormatMeLoud string
---@field ChatFormatSay string
---@field ChatFormatLooc string
---@field ChatFormatWhisper string
---@field ChatFormatYell string
---@field ChatFormatAdmin string
---@field ChatFormatGeneral string
---@field ChatFormatDiscord string
---@field ChatFormatRadio string
---@field ChatFormatFaction string
---@field ChatFormatSafehouse string
---@field ChatFormatIncomingPrivate string
---@field ChatFormatOutgoingPrivate string
---@field ChatFormatServer string
local Option = lib.sandbox('OmiChat')


---@type table<omichat.ColorCategory, string>
local colorOpts = {
    admin     = 'ColorAdmin',
    say       = 'ColorSay',
    shout     = 'ColorYell',
    private   = 'ColorPrivate',
    general   = 'ColorGeneral',
    discord   = 'ColorDiscord',
    radio     = 'ColorRadio',
    faction   = 'ColorFaction',
    safehouse = 'ColorSafehouse',
    server    = 'ColorServer',
}

---@type table<omichat.CalloutCategory, string>
local calloutOpts = {
    callouts      = 'EnableCustomShouts',
    sneakcallouts = 'EnableCustomSneakShouts',
}


---@param options omichat.Options
---@param colorOpt string?
---@return omichat.ColorTable?
local function getColorOrDefault(options, colorOpt)
    if not colorOpt then
        return
    end

    local value = options[colorOpt]
    local settingColor = value and utils.stringToColor(value)
    if settingColor then
        return settingColor
    end

    local defaultStr = options:getDefault(colorOpt)
    local defaultColor = defaultStr and utils.stringToColor(defaultStr)

    if defaultColor then
        return defaultColor
    end
end


---Returns the default color associated with a category.
---@param category omichat.ColorCategory
---@param username string? The username of the user to use for getting defaults, if applicable.
---@return omichat.ColorTable
function Option:getDefaultColor(category, username)
    if category == 'speech' or (category == 'name' and self.EnableSpeechColorAsDefaultNameColor) then
        local speechColor
        if username then
            local player = getPlayerFromUsername(username)
            if player then
                speechColor = player:getSpeakColour()
                if not speechColor and category == 'speech' then
                    speechColor = getCore():getMpTextColor()
                end
            end
        else
            speechColor = getCore():getMpTextColor()
        end

        if speechColor then
            return {
                r = floor(speechColor:getR() * 255),
                g = floor(speechColor:getG() * 255),
                b = floor(speechColor:getB() * 255),
            }
        end
    elseif category == 'faction' then
        local player
        if username then
            player = getPlayerFromUsername(username)
        else
            player = getSpecificPlayer(0)
        end

        local playerFaction = player and Faction.getPlayerFaction(player)
        if playerFaction then
            local color = playerFaction:getTagColor():toColor()

            return {
                r = color:getRed(),
                g = color:getGreen(),
                b = color:getBlue(),
            }
        end
    end

    ---@type omichat.CustomStreamInfo?
    local custom = customStreams.table[category]

    return getColorOrDefault(self, custom and custom.colorOpt)
        or getColorOrDefault(self, colorOpts[category])
        or {r = 255, g = 255, b = 255}
end

---Returns whether the provided callout category type is enabled.
---@param category omichat.CalloutCategory
function Option:isCustomCalloutTypeEnabled(category)
    return self[calloutOpts[category]]
end


return Option
