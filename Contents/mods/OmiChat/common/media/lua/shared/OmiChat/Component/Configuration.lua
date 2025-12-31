---Contains mod configuration and enables updating it.
---@namespace omichat

local utils = require 'OmiChat/Utils'
local Preset = require 'OmiChat/Component/Configuration/Preset'
local Logic = require 'OmiChat/Component/Configuration/Logic'
local sort = table.sort
local isempty = table.isempty

---@class ConfigurationHelper : Configuration, omi.ConfigurationHelper<Configuration>
local Configuration = utils.configuration {
    schema = Logic.getSchema(),
    filename = string.format('omichat/configuration_%s.json', getServerName()),
    logger = utils.log,

    ---@param self ConfigurationHelper
    init = function(self)
        self:loadCustomPresets()
        self:loadDefaults()

        if not isClient() then
            self:loadFile()
        end
    end,

    ---@param self ConfigurationHelper
    onLoad = function(self) self:refreshValueCaches() end,
}

--#region Static Fields

---Class representing a configuration preset.
Configuration.Preset = Preset

---Filename used for storing presets on the server.
---@private
Configuration._presetFilename = 'omichat/presets.json'

---Table containing built-in presets.
---@private
Configuration._presets = {
    Buffy = require 'OmiChat/Definition/Preset/Buffy',
    LightRP = require 'OmiChat/Definition/Preset/LightRP',
    Vanilla = require 'OmiChat/Definition/Preset/Vanilla',
}

---Set of languages that should be allowed for self-adding.
---@type omi.SetTable<string>
---@private
Configuration._languageAllowSet = {}

---Set of languages that should be disallowed for self-adding.
---@type omi.SetTable<string>
---@private
Configuration._languageBlockSet = {}

---List of configured language names.
---@type string[]
---@private
Configuration._languageNameList = {}

---Associates language IDs to information about languages.
---@type table<integer, LanguageRecord>
---@private
Configuration._idToLanguage = {}

---Associates language names to information about languages.
---@type table<string, LanguageRecord>
---@private
Configuration._nameToLanguage = {}

---List containing presets in presentation order. Contains built-in and custom presets.
---@type ConfigurationPreset[]
---@private
Configuration._presetList = {}

---Associates preset names to custom user-defined presets.
---@type table<string, ConfigurationPreset>
---@private
Configuration._customPresets = {}

---Contains arbitary variables.
---@type table<string, string>
---@private
Configuration._variables = {}

--#endregion

--#region Constants

---Constant for the maximum number of configured chat streams.
---This should match the `max-items` field of `config-Streams-List` in the configuration schema.
---@readonly
Configuration.MAX_CHAT_STREAMS = 50

---Constant for the maximum number of custom shouts that can be configured.
---@readonly
Configuration.MAX_CUSTOM_SHOUTS = 20

---Constant for the maximum length of a custom shout.
---@readonly
Configuration.MAX_CUSTOM_SHOUT_LEN = 200

---Constant for the maximum number of languages that can be configured.
---This should match the `max-items` field of `config-Language-List` in the configuration schema.
---@readonly
Configuration.MAX_LANGUAGES = 1000

---Constant for the maximum number of languages that a player character can speak.
---@readonly
Configuration.MAX_LANGUAGE_SLOTS = 50

---Constant for the maximum number of profiles a player can have.
---@readonly
Configuration.MAX_PROFILES = 20


---Constant for the signal character for indicating an asterisk.
---@readonly
Configuration.SIGNAL_ASTERISK = 0x91

---Constant for the signal character for the start of encoded metadata.
---@readonly
Configuration.SIGNAL_DATA_START = 0x92

---Constant for the signal character for indicating an ignored character.
---@readonly
Configuration.SIGNAL_IGNORE = 0x9A

--#endregion


---Checks the language against the add language allow/block list.
---This does not check whether the language is a valid roleplay language.
---@param language string The language to check.
---@return boolean canAdd
---@see api.shared.language.exists
function Configuration:canAddLanguage(language)
    if not isempty(self._languageAllowSet) and not self._languageAllowSet[language] then
        return false
    end

    return not self._languageBlockSet[language]
end

---Returns whether the Discord color option should be shown.
---@return boolean canShow
function Configuration:canShowDiscordColorOption()
    local opt = self.Discord.ShowColorOption
    if opt == 'Respect-Server-Setting' then
        return getServerOptions():getBoolean('DiscordEnable')
    end

    return opt == 'Yes'
end

---Returns an iterator over configured streams.
---@return fun(): Configuration.StreamDefinition? iterator
function Configuration:chatStreams()
    local list = self.Streams.List
    local i = 0
    return function()
        i = i + 1
        return list[i]
    end
end

---Returns whether the Chat Bubble compatibility patch is enabled.
---@return boolean enabled
function Configuration:compatChatBubbleEnabled()
    return self:_isCompatEnabled(self.Compatibility.ChatBubble, 'ChatBubble')
end

---Returns whether the Search Players For Weapons compatibility patch is enabled.
---@return boolean enabled
function Configuration:compatSearchPlayersEnabled()
    return self:_isCompatEnabled(self.Compatibility.SearchPlayers, 'SearchPlayersForWeapons')
end

---Returns whether the True Actions Dancing compatibility patch is enabled.
---@return boolean enabled
function Configuration:compatTADEnabled()
    return self:_isCompatEnabled(self.Compatibility.TrueActionsDancing, 'TrueActionsDancing')
end

---Returns a table of valid items for /card.
---@return string[] items
function Configuration:getCardItems()
    return utils.copy(self.Commands.Card.Items)
end

---Returns a table of valid items for /flip.
---@return string[] items
function Configuration:getCoinItems()
    return utils.copy(self.Commands.Flip.Items)
end

---Gets a user-defined custom preset by name.
---@param name string The name of the preset to retrieve.
---@return ConfigurationPreset? preset
function Configuration:getCustomPreset(name)
    if not name then
        return
    end

    return Configuration._customPresets[name]
end

---Returns a list of custom presets as simple tables.
---@return Configuration.PresetTable[] presets
function Configuration:getCustomPresetsForSave()
    local list = {}
    local schema = self:getSchema()
    for i = 1, #self._presetList do
        local preset = self._presetList[i]
        if preset:isCustom() then
            local values = preset:getValues()
            list[#list + 1] = {
                name = preset:getName(),
                values = schema:sanitize(values),
            }
        end
    end

    return list
end

---Returns a table of valid items for /roll.
---@return string[] items
function Configuration:getDiceItems()
    return utils.copy(self.Commands.Roll.Items)
end

---Retrieves information about a roleplay language given its id.
---@param id integer The ID of the language to retrieve.
---@return LanguageRecord? language
function Configuration:getLanguageById(id)
    local rec = self._idToLanguage[id]
    if rec then
        return utils.copy(rec)
    end
end

---Retrieves information about a roleplay language given its name.
---@param name string The name of the language to retrieve.
---@return LanguageRecord? language
function Configuration:getLanguageByName(name)
    local rec = self._nameToLanguage[name]
    if rec then
        return utils.copy(rec)
    end
end

---Retrieves the number of configured roleplay languages.
---@return integer count
function Configuration:getLanguageCount()
    return #self._idToLanguage
end

---Gets the id of a language given its name.
---@param name string The name of the language.
---@return integer? id
function Configuration:getLanguageIDFromName(name)
    local rec = self._nameToLanguage[name]
    if rec then
        return rec.ID
    end
end

---Retrieves the list of configured roleplay languages.
---@return LanguageRecord[] languages
function Configuration:getLanguageList()
    return utils.mapList(utils.copy, self._idToLanguage) --[[@as LanguageRecord[] ]]
end

---Gets the name of a language given its id.
---@param id integer The ID of the language.
---@return string? name
function Configuration:getLanguageNameFromId(id)
    local rec = self._idToLanguage[id]
    if rec then
        return rec.Name
    end
end

---Retrieves the list of configured roleplay languages' names.
---@return string[] names
function Configuration:getLanguageNameList()
    return utils.copyList(self._languageNameList)
end

---Returns the format to use for a given menu type.
---@param menuType MenuTypeString The menu type.
---@return string format
function Configuration:getMenuNameFormat(menuType)
    local option = self.Format.MenuName

    local format
    if menuType == 'trade' then
        format = option.Trade
    elseif menuType == 'medical' then
        format = option.Medical
    elseif menuType == 'mini_scoreboard' then
        format = option.MiniScoreboard
    elseif menuType == 'search_player' then
        format = option.SearchPlayer
    end

    return format or ''
end

---Gets a preset by ID.
---If the ID is prefixed with `custom:`, this will get a custom preset.
---Otherwise, a built-in preset will be returned.
---@param id string The ID of the preset to retrieve.
---@return ConfigurationPreset? preset
function Configuration:getPreset(id)
    if not id then
        return
    end

    if utils.startsWith(id, 'custom:') then
        return Configuration._customPresets[id:sub(8)]
    end

    return Configuration._presets[id]
end

---Gets a list of all presets, including built-in and user defined.
---@return ConfigurationPreset[] presets
function Configuration:getPresetList()
    return utils.copyList(self._presetList)
end

---Gets the string value of a variable. Returns `nil` if the variable doesn't exist.
---@param key string The key to retrieve.
---@return string? value
function Configuration:getVariable(key)
    return self._variables[key]
end

---Gets the boolean value of a variable. Returns `nil` if the variable doesn't exist.
---@param key string The key to retrieve.
---@return boolean? value
function Configuration:getVariableAsBool(key)
    local value = self._variables[key]
    if not value then
        return nil
    end

    return value:lower() == 'true'
end

---Gets the number value of a variable. Returns `nil` if the variable doesn't exist or is not a number.
---@param key string The key to retrieve.
---@return number? value
function Configuration:getVariableAsNumber(key)
    return tonumber(self._variables[key])
end

---Returns whether the clean character option is set to clean the body.
---This does not check for whether the character customization feature is enabled.
---@return boolean enabled
function Configuration:isCleanBodyEnabled()
    return not not self.Customization.CleanEffects.Body
end

---Returns whether the clean character option is set to clean clothing.
---This does not check for whether the character customization feature is enabled.
---@return boolean enabled
function Configuration:isCleanClothingEnabled()
    return not not self.Customization.CleanEffects.Clothing
end

---Returns whether the clean character option is enabled.
---This does not check for whether the character customization feature is enabled.
---@return boolean enabled
function Configuration:isCleanCustomizationEnabled()
    return not isempty(self.Customization.CleanEffects)
end

---Returns whether custom shouts are enabled.
---@return boolean enabled
function Configuration:isCustomShoutsEnabled()
    return self.Customization.AllowCustomShouts
end

---Returns whether the built-in emote macro is enabled.
---This also checks whether macros are enabled.
---@return boolean enabled
function Configuration:isEmoteMacroEnabled()
    return self.Macros.Enable and self.Macros.BuiltIn.Emote == true
end

---Returns `true` if a given language exists and is signed.
---@param name string The name of the language to check.
---@return boolean signed
function Configuration:isLanguageSigned(name)
    local rec = self._nameToLanguage[name]
    return rec ~= nil and rec.Signed == true
end

---Returns whether the `/name` command should be enabled.
---@return boolean enabled
function Configuration:isNameCommandEnabled()
    return self.Commands.Name.Mode ~= 'Disable'
end

---Returns whether `/name` should set characters' forenames.
---@return boolean enabled
function Configuration:isNameCommandSetForename()
    local mode = self.Commands.Name.Mode
    return mode == 'Forename' or mode == 'Forename-Plus-Nickname'
end

---Returns whether `/name` should set characters' full names.
---@return boolean enabled
function Configuration:isNameCommandSetFullName()
    local mode = self.Commands.Name.Mode
    return mode == 'Fullname' or mode == 'Fullname-Plus-Nickname'
end

---Returns whether `/name` should set characters' nicknames.
---@return boolean enabled
function Configuration:isNameCommandSetNickname()
    return self.Commands.Name.Mode == 'Nickname'
end

---Returns whether the `/nickname` command should be enabled.
---@return boolean enabled
function Configuration:isNicknameCommandEnabled()
    local mode = self.Commands.Name.Mode
    return mode == 'Forename-Plus-Nickname' or mode == 'Fullname-Plus-Nickname'
end

---Returns `true` if the `/nickname` command is enabled or `/name` sets nicknames.
---@return boolean nicknamesEnabled
function Configuration:isNicknameEnabled()
    return self:isNicknameCommandEnabled() or self.Commands.Name.Mode == 'Nickname'
end

---Loads custom presets from a file.
---If called on the client, this will reset the cache without loading anything.
function Configuration:loadCustomPresets()
    if isClient() then
        self:_cachePresetList()
        return
    end

    local result = utils.schema.read({ filename = self._presetFilename })
    if not result or type(result.list) ~= 'table' then
        return
    end

    self:_setCustomPresets(result.list)
end

---Refreshes caches associated with configuration values.
function Configuration:refreshValueCaches()
    self:_cacheLanguages()
    self:_cacheVariables()
end

---Checks whether an item is required for /card.
---@return boolean required
function Configuration:requireCardItem()
    return #self.Commands.Card.Items > 0
end

---Checks whether an item is required for /flip.
---@return boolean required
function Configuration:requireCoinItem()
    return #self.Commands.Flip.Items > 0
end

---Checks whether an item is required for /roll.
---@return boolean required
function Configuration:requireDiceItem()
    return #self.Commands.Roll.Items > 0
end


---Adds a custom preset to the configuration.
---@param preset ConfigurationPreset
---@private
function Configuration:_addCustomPreset(preset)
    local name = preset:getName()
    self._customPresets[name] = preset
    self:_cachePresetList()
end

---Caches the configured languages and information about them.
---@private
function Configuration:_cacheLanguages()
    local languages = self.Language.List

    self._idToLanguage = {}
    self._nameToLanguage = {}
    self._languageNameList = {}

    for i = 1, #languages do
        local lang = languages[i]
        if not self._nameToLanguage[lang.Name] and not utils.isNilOrWhitespace(lang.Name) then
            local rec = utils.copy(lang) --[[@as LanguageRecord]]
            rec.ID = #self._idToLanguage + 1

            self._nameToLanguage[rec.Name] = rec
            self._idToLanguage[rec.ID] = rec
            self._languageNameList[#self._languageNameList + 1] = rec.Name

            -- ignore languages after the maximum
            if #self._idToLanguage >= self.MAX_LANGUAGES then
                break
            end
        end
    end

    self._languageAllowSet = utils.set.table(self.Language.SelfAddAllowlist)
    self._languageBlockSet = utils.set.table(self.Language.SelfAddBlocklist)
end

---Caches the variables and stores them as a map.
---@private
function Configuration:_cacheVariables()
    local varList = self.General.Variables

    self._variables = {}
    for i = 1, #varList do
        local varString = varList[i]
        local split = varString:find(':')
        if split then
            local key = utils.trim(varString:sub(1, split - 1))
            local value = utils.trim(varString:sub(split + 1))
            self._variables[key] = value
        end
    end
end

---Caches the list of presets.
---@private
function Configuration:_cachePresetList()
    local list = {}
    for _, v in pairs(Configuration._presets) do
        list[#list + 1] = v
    end

    for _, v in pairs(Configuration._customPresets) do
        list[#list + 1] = v
    end

    sort(list, Configuration._sortPresets)

    self._presetList = list
end

---Checks whether a mod compatibility option is enabled.
---@param value omi.schema.CompatibilityValue The value of the option.
---@param modId string The mod ID of the relevant mod.
---@return boolean enabled
---@private
function Configuration:_isCompatEnabled(value, modId)
    if value ~= 'Auto' then
        return value == 'Enable'
    end

    return utils.isModActive(modId)
end

---Removes a custom preset from the configuration.
---@param name string
---@private
function Configuration:_removeCustomPreset(name)
    self._customPresets[name] = nil
    self:_cachePresetList()
end

---Replaces the custom presets list with the given list.
---@param list Configuration.PresetTable[]
---@private
function Configuration:_setCustomPresets(list)
    self._customPresets = {}
    for i = 1, #list do
        local data = list[i]
        local preset = Configuration.Preset:new({
            name = data.name,
            values = data.values,
            isCustom = true,
        })

        self._customPresets[data.name] = preset
    end

    self:_cachePresetList()
end

---Sort function for presets.
---@param a ConfigurationPreset
---@param b ConfigurationPreset
---@return boolean
---@private
function Configuration._sortPresets(a, b)
    local aIsCustom = a:isCustom()
    local bIsCustom = b:isCustom()

    if aIsCustom ~= bIsCustom then
        return bIsCustom
    end

    return a:getName() < b:getName()
end


Configuration:init()
return Configuration

--#region Type Definitions

---@class LanguageRecord : Configuration.LanguageDefinition
---@field ID integer The ID of the language.

---@class ConfigurationFormState
---@field activePresetDialog? omi.Dialog The active dialog related to presets.
---@field activeFormatStringDialog? omi.Dialog The active dialog with an overview of format strings.

---@class FormatDataTranslation
---@field name string The name of the token or option.
---@field id string The string ID for the description of the token or option.


---@alias FormatterName
---| 'callout'
---| 'sneakCallout'
---| 'language'
---| 'overheadFinal'
---| 'adminIcon'
---| 'narrative'
---| 'onlineID'
---| 'echo'
---| 'mention'

---@alias MenuTypeString
---| 'trade'
---| 'medical'
---| 'mini_scoreboard'
---| 'search_player'

--#endregion

--#region Configuration Definitions

---@class Configuration
---@field General Configuration.General
---@field Buffs Configuration.Buffs
---@field Callouts Configuration.Callouts
---@field Commands Configuration.Commands
---@field Compatibility Configuration.Compatibility
---@field Customization Configuration.Customization
---@field Discord Configuration.Discord
---@field Format Configuration.Format
---@field EchoMessages Configuration.EchoMessages
---@field Language Configuration.Language
---@field Macros Configuration.Macros
---@field Mentions Configuration.Mentions
---@field NarrativeStyle Configuration.NarrativeStyle
---@field Radio Configuration.Radio
---@field ServerMessages Configuration.ServerMessages
---@field Streams Configuration.Streams
---@field TypingIndicator Configuration.TypingIndicator
---@field ZombieAttraction Configuration.ZombieAttraction
---@field private _Languages? any
---@field private _Streams? any

---@class Configuration.General
---@field Preset string
---@field AlwaysShowChat boolean
---@field CaseInsensitiveChatStreams boolean
---@field ClearOnDeath Configuration.General.ClearOnDeath
---@field AdminIcon string
---@field InfoText string
---@field Variables string[]

---@class Configuration.General.ClearOnDeath
---@field Icon boolean?
---@field Languages boolean?
---@field Nickname boolean?
---@field Status boolean?

---@class Configuration.Buffs
---@field Enable boolean
---@field Cooldown integer
---@field Boredom number
---@field Unhappiness number
---@field Hunger number
---@field Thirst number
---@field Fatigue number
---@field CigaretteStress number

---@class Configuration.Callouts
---@field Format string
---@field SneakFormat string
---@field Range integer
---@field SneakRange integer

---@class Configuration.Commands
---@field Name Configuration.Commands.Name
---@field Status Configuration.Commands.Status
---@field Card Configuration.Commands.ItemCommand
---@field Roll Configuration.Commands.ItemCommand
---@field Flip Configuration.Commands.ItemCommand

---@class Configuration.Commands.Name
---@field Mode Configuration.Commands.Name.Mode

---@class Configuration.Commands.Status
---@field Enable boolean
---@field Range integer

---@class Configuration.Commands.ItemCommand
---@field Global boolean
---@field OverheadFormat string
---@field Items string[]
---@field Tags string[]

---@class Configuration.Compatibility
---@field ApplyOverrides boolean
---@field ChatBubble omi.schema.CompatibilityValue
---@field SearchPlayers omi.schema.CompatibilityValue
---@field TrueActionsDancing omi.schema.CompatibilityValue

---@class Configuration.Customization
---@field AllowCustomShouts boolean
---@field EnableNameColors boolean
---@field EnableCharacterCustomization boolean
---@field CleanEffects omi.SetTable<string>

---@class Configuration.Discord
---@field ChatFormat string
---@field DefaultColor omi.ColorTable<integer>
---@field ShowColorOption 'Yes' | 'No' | 'Respect-Server-Setting'
---@field Tags string[]

---@class Configuration.EchoMessages
---@field Enable boolean
---@field ChatFormat string
---@field OverheadFormat string
---@field Tags string[]

---@class Configuration.Format
---@field Chat Configuration.Format.Chat
---@field Overhead Configuration.Format.Overhead
---@field PerceptionRange Configuration.Format.PerceptionRange
---@field Component Configuration.Format.Component
---@field Filter Configuration.Format.Filter
---@field MenuName Configuration.Format.MenuName

---@class Configuration.Format.Chat
---@field Prefix string
---@field Final string

---@class Configuration.Format.Overhead
---@field Prefix string
---@field Final string

---@class Configuration.Format.PerceptionRange
---@field Chat string
---@field Overhead string

---@class Configuration.Format.Component
---@field Name string
---@field Tag string
---@field Timestamp string
---@field Icon string
---@field Language string
---@field EmbeddedAction string
---@field EmbeddedQuote string

---@class Configuration.Format.Filter
---@field Name string
---@field Status string
---@field ChatInput string

---@class Configuration.Format.MenuName
---@field Trade string
---@field Medical string
---@field SearchPlayer string
---@field MiniScoreboard string

---@class Configuration.Language
---@field DefaultSlots integer
---@field InterpretationRolls integer
---@field InterpretationChance integer
---@field SelfAddAllowlist string[]
---@field SelfAddBlocklist string[]
---@field UnknownLanguageChat string
---@field UnknownLanguageRadio string
---@field UnknownLanguageOverhead string
---@field PlaceholderFormat string
---@field PlaceholderColor omi.ColorTable<integer>
---@field UseDefaultList boolean
---@field List Configuration.LanguageDefinition[]

---@class Configuration.Macros
---@field Enable boolean
---@field BuiltIn Configuration.Macros.BuiltIn

---@class Configuration.Macros.BuiltIn
---@field Emote boolean?

---@class Configuration.Mentions
---@field Enable boolean
---@field AlwaysUseNameColors boolean
---@field Range integer
---@field ChatFormat string
---@field OverheadFormat string

---@class Configuration.NarrativeStyle
---@field Enable boolean
---@field OverheadContentFormat string
---@field ChatContentFormat string
---@field DialogueTagFormat string
---@field InputFilter string

---@class Configuration.Radio
---@field ChatFormat string
---@field OverheadFormat string
---@field DefaultColor omi.ColorTable<integer>
---@field Tags string[]

---@class Configuration.ServerMessages
---@field ChatFormat string
---@field DefaultColor omi.ColorTable<integer>
---@field Tags string[]

---@class Configuration.Streams
---@field UseDefaultList boolean
---@field GlobalTags string[]
---@field List Configuration.StreamDefinition[]

---@class Configuration.TypingIndicator
---@field Enable boolean
---@field NameFormat string
---@field Format string

---@class Configuration.ZombieAttraction
---@field ChatRangeMultiplier number
---@field CalloutRange integer
---@field SneakCalloutRange integer


---@class Configuration.LanguageDefinition
---@field Name string The name of the language.
---@field Signed boolean? Flag for whether the language should be treated as signed.

---@class Configuration.StreamDefinition
---@field Enable boolean?
---@field Stream string?
---@field ChatType omi.ChatTypeString?
---@field Category StreamCategory?
---@field Name string?
---@field Command string?
---@field ShortCommand string?
---@field DefaultColor omi.ColorTable<integer>?
---@field Aliases string[]?
---@field Tags string[]?
---@field OverheadFormat string?
---@field ChatFormat string?
---@field Range integer?
---@field VerticalRange integer?
---@field PerceptionRange integer?
---@field PerceptionRangeSigned integer?
---@field AllowBuffs boolean?
---@field AllowMentions boolean?
---@field AllowLanguages boolean?
---@field AllowTypingIndicator boolean?
---@field AttractZombies boolean?
---@field UseNarrativeStyle boolean?


---@alias Configuration.Commands.Name.Mode
---| 'Disable'
---| 'Nickname'
---| 'Forename'
---| 'Fullname'
---| 'Forename-Plus-Nickname'
---| 'Fullname-Plus-Nickname'

--#endregion
