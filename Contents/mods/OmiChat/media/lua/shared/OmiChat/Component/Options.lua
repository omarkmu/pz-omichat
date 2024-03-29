local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'
local config = require 'OmiChat/config'

local getActivatedMods = getActivatedMods
local floor = math.floor


---Helper for retrieving sandbox variables and their defaults.
---@class omichat.Options : omi.SandboxHelper
---@field EnableCustomShouts boolean
---@field EnableEmotes boolean
---@field EnableSetNameColor boolean
---@field EnableSpeechColorAsDefaultNameColor boolean
---@field EnableSetSpeechColor boolean
---@field EnableCompatChatBubble integer
---@field EnableCompatSearchPlayers integer
---@field EnableCompatTAD integer
---@field EnableFactionColorAsDefault boolean
---@field EnableCharacterCustomization boolean
---@field EnableDiscordColorOption integer
---@field EnableSetName integer
---@field BuffCooldown integer
---@field CustomShoutMaxLength integer
---@field MinimumCommandAccessLevel integer
---@field MaximumCustomShouts integer
---@field RangeCallout integer
---@field RangeSneakCallout integer
---@field RangeCalloutZombies integer
---@field RangeSneakCalloutZombies integer
---@field RangeDo integer
---@field RangeDoLoud integer
---@field RangeDoQuiet integer
---@field RangeMe integer
---@field RangeMeLoud integer
---@field RangeMeQuiet integer
---@field RangeMultiplierZombies number
---@field RangeOoc integer
---@field RangeLow integer
---@field RangeSay integer
---@field RangeWhisper integer
---@field RangeVertical string
---@field RangeYell integer
---@field ColorOoc string
---@field ColorLow string
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
---@field FilterChatInput string
---@field FilterNickname string
---@field FilterNarrativeStyle string
---@field PredicateAllowChatInput string
---@field PredicateAttractZombies string
---@field PredicateApplyBuff string
---@field PredicateUseNameColor string
---@field PredicateUseNarrativeStyle string
---@field PredicateAllowLanguage string
---@field PredicateTransmitOverRadio string
---@field AvailableLanguages string
---@field SignedLanguages string
---@field LanguageSlots integer
---@field FormatCard string
---@field FormatRoll string
---@field FormatAliases string
---@field FormatInfo string
---@field FormatMenuName string
---@field FormatName string
---@field FormatChatPrefix string
---@field FormatOverheadPrefix string
---@field FormatTag string
---@field FormatTimestamp string
---@field FormatIcon string
---@field FormatLanguage string
---@field FormatAdminIcon string
---@field FormatNarrativeDialogueTag string
---@field FormatNarrativePunctuation string
---@field OverheadFormatFull string
---@field OverheadFormatCard string
---@field OverheadFormatRoll string
---@field OverheadFormatDo string
---@field OverheadFormatDoLoud string
---@field OverheadFormatDoQuiet string
---@field OverheadFormatEcho string
---@field OverheadFormatMe string
---@field OverheadFormatWhisper string
---@field OverheadFormatMeQuiet string
---@field OverheadFormatMeLoud string
---@field OverheadFormatOoc string
---@field OverheadFormatLow string
---@field OverheadFormatOther string
---@field ChatFormatFull string
---@field ChatFormatCard string
---@field ChatFormatRoll string
---@field ChatFormatDo string
---@field ChatFormatDoLoud string
---@field ChatFormatDoQuiet string
---@field ChatFormatEcho string
---@field ChatFormatMe string
---@field ChatFormatMeQuiet string
---@field ChatFormatMeLoud string
---@field ChatFormatSay string
---@field ChatFormatOoc string
---@field ChatFormatLow string
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
---@field ChatFormatUnknownLanguage string
---@field ChatFormatUnknownLanguageRadio string
local Option = lib.sandbox('OmiChat')


---@type table<omichat.ColorCategory, string>
local colorOpts = {
    admin = 'ColorAdmin',
    say = 'ColorSay',
    shout = 'ColorYell',
    private = 'ColorPrivate',
    general = 'ColorGeneral',
    discord = 'ColorDiscord',
    radio = 'ColorRadio',
    faction = 'ColorFaction',
    safehouse = 'ColorSafehouse',
    server = 'ColorServer',
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

---Checks whether a mod compatibility option is enabled.
---@param value integer The value of the option.
---@param modId string The mod ID of the relevant mod.
---@return boolean
local function isCompatEnabled(value, modId)
    if value ~= 3 then
        return value == 1
    end

    return getActivatedMods():contains(modId)
end


---Returns whether players have a way to set their chat nickname.
---@return boolean
function Option:canPlayersSetNickname()
    return self:isNicknameCommandEnabled() or self.EnableSetName == 2
end

---Returns whether the Chat Bubble compatibility patch is enabled.
---@return boolean
function Option:compatChatBubbleEnabled()
    return isCompatEnabled(Option.EnableCompatChatBubble, 'ChatBubble')
end

---Returns whether the Search Players For Weapons compatibility patch is enabled.
---@return boolean
function Option:compatSearchPlayersEnabled()
    return isCompatEnabled(Option.EnableCompatSearchPlayers, 'SearchPlayersForWeapons')
end

---Returns whether the True Actions Dancing compatibility patch is enabled.
---@return boolean
function Option:compatTADEnabled()
    return isCompatEnabled(Option.EnableCompatTAD, 'TrueActionsDancing')
end

---Returns the default color associated with a category.
---@param category omichat.ColorCategory
---@param username string? The username of the user to use for getting defaults, if applicable.
---@return omichat.ColorTable
function Option:getDefaultColor(category, username)
    if category == 'speech' or (category == 'name' and self.EnableSpeechColorAsDefaultNameColor) then
        local player = username and utils.getPlayerByUsername(username)
        local speechColor = player and player:getSpeakColour()

        if not speechColor then
            return { r = 255, g = 255, b = 255 }
        end

        return {
            r = floor(speechColor:getR() * 255),
            g = floor(speechColor:getG() * 255),
            b = floor(speechColor:getB() * 255),
        }
    elseif category == 'faction' and Option.EnableFactionColorAsDefault then
        local player
        if username then
            player = utils.getPlayerByUsername(username)
        else
            player = getSpecificPlayer(0)
        end

        local playerFaction = player and Faction.getPlayerFaction(player)
        local tagColor = playerFaction and playerFaction:getTagColor()
        if tagColor then
            local color = tagColor:toColor()

            return {
                r = color:getRed(),
                g = color:getGreen(),
                b = color:getBlue(),
            }
        end
    end

    local custom = config:getCustomStreamInfo(category)
    return getColorOrDefault(self, custom and custom.colorOpt)
        or getColorOrDefault(self, colorOpts[category])
        or { r = 255, g = 255, b = 255 }
end

---Returns whether the /name command should be enabled.
---@return boolean
function Option:isNameCommandEnabled()
    return self.EnableSetName ~= 1
end

---Returns whether /name should set characters' forenames.
---@return boolean
function Option:isNameCommandSetForename()
    local mode = self.EnableSetName
    return mode == 3 or mode == 5
end

---Returns whether /name should set characters' full names.
---@return boolean
function Option:isNameCommandSetFullName()
    local mode = self.EnableSetName
    return mode == 4 or mode == 6
end

---Returns whether /name should set characters' nicknames.
---@return boolean
function Option:isNameCommandSetNickname()
    return self.EnableSetName == 2
end

---Returns whether the /nickname command should be enabled.
---@return boolean
function Option:isNicknameCommandEnabled()
    return self.EnableSetName > 4
end

---Returns whether the Discord color option should be shown.
---@return boolean
function Option:showDiscordColorOption()
    local opt = self.EnableDiscordColorOption
    if opt == 3 then
        return getServerOptions():getBoolean('DiscordEnable')
    end

    return opt == 1
end


return Option
