local lib = require 'OmiChat/lib'

---Helper for retrieving sandbox variables and their defaults.
---@class omichat.Options : omi.Sandbox
---@field EnableCustomShouts boolean
---@field EnableCustomSneakShouts boolean
---@field EnableEmotes boolean
---@field EnableSetName boolean
---@field EnableSetNameColor boolean
---@field EnableNameColorInAllChats boolean
---@field EnableSpeechColorAsDefaultNameColor boolean
---@field EnableSetSpeechColor boolean
---@field EnableIconPicker boolean
---@field EnableRangedMe boolean
---@field EnableMiscellaneousIcons boolean
---@field EnableCompatTAD boolean
---@field UppercaseCustomShouts boolean
---@field LowercaseCustomSneakShouts boolean
---@field EnableChatNameAsCharacterName boolean
---@field CustomShoutMaxLength integer
---@field MaximumCustomShouts integer
---@field MinimumColorValue integer
---@field MaximumColorValue integer
---@field NameMaxLength integer
---@field RangeMe integer
---@field RangeLooc integer
---@field RangeSay integer
---@field RangeWhisper integer
---@field RangeYell integer
---@field ColorLooc string
---@field ColorMe string
---@field ColorWhisper string
---@field FormatMenuName string
---@field FormatName string
---@field FormatTag string
---@field FormatTimestamp string
---@field OverheadFormatMe string
---@field OverheadFormatWhisper string
---@field OverheadFormatLooc string
---@field ChatFormatMe string
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

local floor = math.floor
local utils = require 'OmiChat/util'
local customStreams = require 'OmiChat/CustomStreamData'

---@type table<omichat.ColorCategory, omichat.ColorTable>
local colorDefaults = {
    name      = {r = 255, g = 255, b = 255},
    admin     = {r = 255, g = 255, b = 255},
    say       = {r = 255, g = 255, b = 255},
    shout     = {r = 255, g =  51, b =  51},
    private   = {r =  85, g =  26, b = 139}, -- /pm whisper
    general   = {r = 255, g = 165, b =   0},
    discord   = {r = 114, g = 137, b = 218},
    radio     = {r = 178, g = 178, b = 178},
    faction   = {r =  22, g = 113, b =  20},
    safehouse = {r =  55, g = 148, b =  53},
    server    = {r =   0, g = 128, b = 255},
}

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
    local custom = customStreams[category]
    if custom then
        local settingDefault = utils.stringToColor(custom and custom.colorOpt)
        if settingDefault then
            return settingDefault
        end

        if custom.defaultColor then
            return custom.defaultColor
        end
    end

    if colorDefaults[category] then
        return colorDefaults[category]
    end

    error(string.format('invalid color category: %s', category))
end


return Option
