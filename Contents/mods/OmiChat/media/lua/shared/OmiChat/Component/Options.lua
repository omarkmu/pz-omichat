local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'
local config = require 'OmiChat/config'
local DelimitedList = utils.DelimitedList

local getActivatedMods = getActivatedMods


---Helper for retrieving sandbox variables and their defaults.
---@class omichat.Options : omi.SandboxHelper
---@field EnableCustomShouts boolean
---@field EnableEmotes boolean
---@field EnableSetNameColor boolean
---@field EnableSpeechColorAsDefaultNameColor boolean
---@field EnableSetSpeechColor boolean
---@field EnableCompatBuffyRPGSystem integer
---@field EnableCompatBuffyCharacterBios integer
---@field EnableCompatChatBubble integer
---@field EnableCompatSearchPlayers integer
---@field EnableCompatTAD integer
---@field EnableFactionColorAsDefault boolean
---@field EnableCharacterCustomization boolean
---@field EnableAlwaysShowChat boolean
---@field EnableCleanCharacter integer
---@field EnableDiscordColorOption integer
---@field EnableSetName integer
---@field EnableCaseInsensitiveChatStreams boolean
---@field CardItems string
---@field CoinItems string
---@field DiceItems string
---@field BuffCooldown integer
---@field BuffReduceBoredom number
---@field BuffReduceCigaretteStress number
---@field BuffReduceFatigue number
---@field BuffReduceHunger number
---@field BuffReduceThirst number
---@field BuffReduceUnhappiness number
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
---@field RangeMeWhisper integer
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
---@field ColorMeWhisper string
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
---@field PredicateClearOnDeath string
---@field PredicateApplyBuff string
---@field PredicateUseNameColor string
---@field PredicateUseNarrativeStyle string
---@field PredicateAllowLanguage string
---@field PredicateTransmitOverRadio string
---@field PredicateEnableStream string
---@field PredicateShowTypingIndicator string
---@field AvailableLanguages string
---@field AddLanguageAllowlist string
---@field AddLanguageBlocklist string
---@field SignedLanguages string
---@field LanguageSlots integer
---@field InterpretationRolls integer
---@field InterpretationChance integer
---@field FormatCard string
---@field FormatRoll string
---@field FormatFlip string
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
---@field FormatTyping string
---@field PatternNarrativeCustomTag string
---@field OverheadFormatFull string
---@field OverheadFormatCard string
---@field OverheadFormatRoll string
---@field OverheadFormatFlip string
---@field OverheadFormatDo string
---@field OverheadFormatDoLoud string
---@field OverheadFormatDoQuiet string
---@field OverheadFormatEcho string
---@field OverheadFormatMe string
---@field OverheadFormatWhisper string
---@field OverheadFormatMeQuiet string
---@field OverheadFormatMeWhisper string
---@field OverheadFormatMeLoud string
---@field OverheadFormatOoc string
---@field OverheadFormatLow string
---@field OverheadFormatOther string
---@field ChatFormatFull string
---@field ChatFormatCard string
---@field ChatFormatRoll string
---@field ChatFormatFlip string
---@field ChatFormatDo string
---@field ChatFormatDoLoud string
---@field ChatFormatDoQuiet string
---@field ChatFormatEcho string
---@field ChatFormatMe string
---@field ChatFormatMeQuiet string
---@field ChatFormatMeWhisper string
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

local addLangAllowlist = DelimitedList:new({ table = Option, source = 'AddLanguageAllowlist' })
local addLangBlocklist = DelimitedList:new({ table = Option, source = 'AddLanguageBlocklist' })
local cardItemsList = DelimitedList:new({ table = Option, source = 'CardItems' })
local coinItemsList = DelimitedList:new({ table = Option, source = 'CoinItems' })
local diceItemsList = DelimitedList:new({ table = Option, source = 'DiceItems' })


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


---Checks the language against the add language allow/block list.
---This does not check whether the language is a valid roleplay language.
---@param language string
---@return boolean
---@see omichat.api.shared.isConfiguredRoleplayLanguage
function Option:canAddLanguage(language)
    local allowlist = addLangAllowlist:list()
    local blocklist = addLangBlocklist:list()

    local found = #allowlist == 0
    for i = 1, #allowlist do
        if allowlist[i] == language then
            found = true
            break
        end
    end

    if not found then
        return false
    end

    for i = 1, #blocklist do
        if blocklist[i] == language then
            return false
        end
    end

    return true
end

---Returns whether players have a way to set their chat nickname.
---@return boolean
function Option:canPlayersSetNickname()
    return self:isNicknameCommandEnabled() or self.EnableSetName == 2
end

---Returns whether the Buffy's Character Bios compatibility patch is enabled.
function Option:compatBuffyCharacterBiosEnabled()
    return isCompatEnabled(Option.EnableCompatBuffyCharacterBios, 'CharacterBio')
end

---Returns whether the Buffy's Tabletop RPG System compatibility patch is enabled.
function Option:compatBuffyRPGSystemEnabled()
    return isCompatEnabled(Option.EnableCompatBuffyRPGSystem, 'roleplaydnd_update15')
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

---Returns a table of valid items for /card.
---@return table
function Option:getCardItems()
    return cardItemsList:list()
end

---Returns a table of valid items for /flip.
---@return table
function Option:getCoinItems()
    return coinItemsList:list()
end

---Returns a table of valid items for /roll.
---@return table
function Option:getDiceItems()
    return diceItemsList:list()
end

---Returns the configured default color associated with a category.
---@param category omichat.ColorCategory
---@param username string? The username of the user to use for getting defaults, if applicable.
---@return omichat.ColorTable
function Option:getDefaultColor(category, username)
    if category == 'speech' or (category == 'name' and self.EnableSpeechColorAsDefaultNameColor) then
        local player = username and utils.getPlayerInfoByUsername(username)
        local speechColor = player and player.speechColor

        if not speechColor then
            return { r = 255, g = 255, b = 255 }
        end

        return {
            r = speechColor.r,
            g = speechColor.g,
            b = speechColor.b,
        }
    elseif category == 'faction' and Option.EnableFactionColorAsDefault then
        -- faction messages should share the player's faction
        local player = getSpecificPlayer(0)

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

---Returns the default value for a color option.
---@param option string
---@return omichat.ColorTable
function Option:getOptionDefaultColor(option)
    local defaultStr = Option:getDefault(option)
    local defaultColor = defaultStr and utils.stringToColor(defaultStr) or { r = 255, g = 255, b = 255 }

    return defaultColor
end

---Returns whether the clean character option is set to clean clothing.
---This does not check for whether the macro character customization feature is enabled.
---@return boolean
function Option:isCleanClothingEnabled()
    return Option.EnableCleanCharacter == 3
end

---Returns whether the clean character option is enabled.
---This does not check for whether the macro character customization feature is enabled.
---@return boolean
function Option:isCleanCustomizationEnabled()
    return Option.EnableCleanCharacter ~= 1
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

---Returns whether the /nickname command is enabled, or /name sets nicknames.
---@return boolean
function Option:isNicknameEnabled()
    return self.EnableSetName > 4 or self.EnableSetName == 2
end

---Checks whether an item is required for /card.
---@return boolean
function Option:requireCardItem()
    return #self:getCardItems() > 0
end

---Checks whether an item is required for /flip.
---@return boolean
function Option:requireCoinItem()
    return #self:getCoinItems() > 0
end

---Checks whether an item is required for /roll.
---@return boolean
function Option:requireDiceItem()
    return #self:getDiceItems() > 0
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
