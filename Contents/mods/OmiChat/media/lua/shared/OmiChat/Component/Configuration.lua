---Contains mod configuration and enables updating it.

local utils = require 'OmiChat/Utils'
local MetaFormatter = require 'OmiChat/Component/MetaFormatter'
local Preset = require 'OmiChat/Component/Configuration/Preset'
local base = utils.configuration.ConfigurationHelper
local sort = table.sort
local isempty = table.isempty


---Helper for managing and retrieving mod configuration.
---@class omichat.ConfigurationHelper : omi.ConfigurationHelper, omichat.Configuration
---@field private _enabledMods table<string, boolean?> Cache of enabled mods.
---@field private _languageAllowSet omi.SimpleSet Set of languages that should be allowed for self-adding.
---@field private _languageBlockSet omi.SimpleSet Set of languages that should be disallowed for self-adding.
---@field private _languageNameList string[] List of configured language names.
---@field private _idToLanguage table<integer, omichat.LanguageRecord> Associates language IDs to information about languages.
---@field private _nameToLanguage table<string, omichat.LanguageRecord> Associates language names to information about languages.
---@field private _formatterInfo table<integer, omichat.FormatterInfo> Associates formatter IDs to information about formatters used for encoding metadata.
---@field private _presetList omichat.ConfigurationPreset[] List containing presets in presentation order. Contains both built-in and custom presets.
---@field private _customPresets table<string, omichat.ConfigurationPreset> Associates preset names to custom user-defined presets.
---@field private _variables table<string, string> Contains arbitary variables.
local Configuration = utils.configuration {
    schema = require 'OmiChat/Component/Configuration/ConfigurationSchema',
    modDataKey = 'omichat.settings',
    logger = utils.log,

    ---@param self omichat.ConfigurationHelper
    init = function(self)
        self:loadCustomPresets()
        self:refreshEnabledMods()
        self:loadDefaults()
    end,

    ---@param self omichat.ConfigurationHelper
    onLoad = function(self) self:refreshValueCaches() end,
}

Configuration.Preset = Preset

--#region Static Fields

---Filename used for storing presets on the server.
---@private
Configuration._presetFilename = 'omichat_presets.json'

---Table containing built-in presets.
---@private
Configuration._presets = {
    Default = require 'OmiChat/Definition/Preset/Default',
    Buffy = require 'OmiChat/Definition/Preset/Buffy',
    Vanilla = require 'OmiChat/Definition/Preset/Vanilla',
}

Configuration._enabledMods = {}
Configuration._languageAllowSet = {}
Configuration._languageBlockSet = {}
Configuration._languageNameList = {}
Configuration._idToLanguage = {}
Configuration._nameToLanguage = {}
Configuration._formatterInfo = {}
Configuration._presetList = {}
Configuration._customPresets = {}
Configuration._variables = {}

--#endregion

--#region Constants

-- reserved ID layout:
--   1–10: general-purpose arguments
--  11–32: other arguments & signals
--  33–64: chat streams
--  65–80: command streams
-- 81–100: metadata


---Constant for the number at which chat format IDs start.
Configuration.MIN_CHAT_ID = 33

---Constant for the number at which chat format IDs end.
Configuration.MAX_CHAT_ID = 64

---Constant for the number at which metadata format IDs start.
Configuration.MIN_META_ID = 81

---Constant for the number at which metadata format IDs end.
Configuration.MAX_META_ID = 89

---Constant for the maximum number of configured chat streams.
Configuration.MAX_CHAT_STREAMS = 32

---Constant for the maximum number of custom shouts that can be configured.
Configuration.MAX_CUSTOM_SHOUTS = 20

---Constant for the maximum length of a custom shout.
Configuration.MAX_CUSTOM_SHOUT_LEN = 200

---Constant for the maximum number of languages that can be configured.
Configuration.MAX_LANGUAGES = 1000

---Constant for the maximum number of languages that a player character can speak.
Configuration.MAX_LANGUAGE_SLOTS = 50

---Constant for the maximum number of profiles a player can have.
Configuration.MAX_PROFILES = 20


---Constant for a narrative style dialogue tag argument.
Configuration.ID_NARRATIVE_TAG = 11

---Constant for a narrative style content argument.
Configuration.ID_NARRATIVE_TEXT = 12

---Constant for echo type argument.
Configuration.ID_ECHO_TYPE = 13

---Constant for an invisible asterisk for coloring actions.
Configuration.ID_ASTERISK_SIGNAL = 14

---Constant for an indicator for the position of encoded command arguments.
Configuration.ID_COMMAND_ARGS = 15


---Constant for the format ID for `/card`.
Configuration.ID_CARD = 65

---Constant for the format ID for `/flip`.
Configuration.ID_FLIP = 66

---Constant for the format ID for `/roll`.
Configuration.ID_ROLL = 67


---Constant for the format ID for the final overhead text.
Configuration.ID_OVERHEAD_FINAL = 81

---Constant for the format ID for callouts.
Configuration.ID_CALLOUT = 82

---Constant for the format ID for sneak callouts.
Configuration.ID_SNEAK_CALLOUT = 83

---Constant for the format ID for languages.
Configuration.ID_LANGUAGE = 84

---Constant for the format ID for the admin icon.
Configuration.ID_ADMIN_ICON = 85

---Constant for the format ID for narrative style.
Configuration.ID_NARRATIVE_STYLE = 86

---Constant for the format ID for encoded online IDs.
Configuration.ID_ONLINE_ID = 87

---Constant for the format ID for echo messages.
Configuration.ID_ECHO = 88

---Constant for the format ID for mentions.
Configuration.ID_MENTION = 89

---Associates metadata format IDs with names for those formatters.
Configuration.FORMAT_NAMES = {
    [Configuration.ID_OVERHEAD_FINAL] = 'overheadFinal',
    [Configuration.ID_CALLOUT] = 'callout',
    [Configuration.ID_SNEAK_CALLOUT] = 'sneakCallout',
    [Configuration.ID_LANGUAGE] = 'language',
    [Configuration.ID_ADMIN_ICON] = 'adminIcon',
    [Configuration.ID_NARRATIVE_STYLE] = 'narrative',
    [Configuration.ID_ONLINE_ID] = 'onlineID',
    [Configuration.ID_ECHO] = 'echo',
    [Configuration.ID_MENTION] = 'mention',
}

--#endregion


---Checks the language against the add language allow/block list.
---This does not check whether the language is a valid roleplay language.
---@param language string The language to check.
---@return boolean canAdd
---@see omichat.api.shared.language.exists
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
    if opt == 'Respect_Server_Setting' then
        return getServerOptions():getBoolean('DiscordEnable')
    end

    return opt == 'Yes'
end

---Returns an iterator over configured streams.
---@return fun(): omichat.Configuration.StreamDefinition? iterator
function Configuration:chatStreams()
    local list = self.Streams.List
    local i = 0
    return function()
        i = i + 1
        return list[i]
    end
end

---Returns whether the Buffy's Character Bios compatibility patch is enabled.
---@return boolean enabled
function Configuration:compatBuffyCharacterBiosEnabled()
    return self:_isCompatEnabled(self.Compatibility.BuffyCharacterBios, 'CharacterBio')
end

---Returns whether the Buffy's Tabletop RPG System compatibility patch is enabled.
---@return boolean enabled
function Configuration:compatBuffyRPGSystemEnabled()
    return self:_isCompatEnabled(self.Compatibility.BuffyRPGSystem, 'roleplaydnd_update15')
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

---Returns an iterator over metadata formatter information.
---@return fun(): omichat.FormatterInfo? iterator
function Configuration:formatters()
    local i = self.MIN_META_ID - 1
    return function()
        i = i + 1
        local info = self._formatterInfo[i]
        if info then
            return utils.copy(info)
        end
    end
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
---@return omichat.ConfigurationPreset? preset
function Configuration:getCustomPreset(name)
    if not name then
        return
    end

    return Configuration._customPresets[name]
end

---Returns a list of custom presets as simple tables.
---@return omichat.Configuration.PresetTable[] presets
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
---@return omichat.LanguageRecord? language
function Configuration:getLanguageById(id)
    local rec = self._idToLanguage[id]
    if rec then
        return utils.copy(rec)
    end
end

---Retrieves information about a roleplay language given its name.
---@param name string The name of the language to retrieve.
---@return omichat.LanguageRecord? language
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
---@return omichat.LanguageRecord[] languages
function Configuration:getLanguageList()
    return utils.mapList(utils.copy, self._idToLanguage)
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
---@param menuType omichat.MenuTypeString The menu type.
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
---@return omichat.ConfigurationPreset? preset
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
---@return omichat.ConfigurationPreset[] presets
function Configuration:getPresetList()
    return utils.copyList(self._presetList)
end

---Returns the current configuration as a simple table.
---@return omichat.Configuration values
function Configuration:getValues()
    return base.getValues(self)
end

---Gets sanitized configuration values that are prepared for saving.
---@return omichat.Configuration sanitized
function Configuration:getValuesForSave()
    return base.getValuesForSave(self)
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

---Returns whether emote shortcut macros are enabled.
---@return boolean enabled
function Configuration:isEmoteMacroEnabled()
    return self.Macros.AllowEmotes
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
    return mode == 'Forename' or mode == 'Forename_Plus_Nickname'
end

---Returns whether `/name` should set characters' full names.
---@return boolean enabled
function Configuration:isNameCommandSetFullName()
    local mode = self.Commands.Name.Mode
    return mode == 'Fullname' or mode == 'Fullname_Plus_Nickname'
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
    return mode == 'Forename_Plus_Nickname' or mode == 'Fullname_Plus_Nickname'
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

---Reads the currently enabled mods to a cache.
function Configuration:refreshEnabledMods()
    local enabledMods = {}

    local activatedMods = getActivatedMods()
    for i = 0, activatedMods:size() - 1 do
        local id = activatedMods:get(i)
        local modId = id:match('^%d*\\(.+)$')
        if not modId then
            modId = id
        end

        enabledMods[modId] = true
    end

    self._enabledMods = enabledMods
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

---Updates the format text used for metadata formatters.
function Configuration:updateFormatters()
    self._formatterInfo = self._formatterInfo or {}

    local callout = self.Callouts or {}
    local format = self.Format or {}
    local echo = self.EchoMessages or {}
    for i = self.MIN_META_ID, self.MAX_META_ID do
        if not self._formatterInfo[i] then
            local name = self.FORMAT_NAMES[i]
            if not name then
                utils.log.error('Missing name for metadata formatter with ID %d', i)
            end

            self._formatterInfo[i] = {
                id = i,
                name = name or '',
                formatter = MetaFormatter:new(i),
            }
        end

        local targetFormat
        local defaultName
        if i == self.ID_CALLOUT then
            targetFormat = callout.Format
        elseif i == self.ID_SNEAK_CALLOUT then
            targetFormat = callout.SneakFormat
        elseif i == self.ID_OVERHEAD_FINAL then
            defaultName = 'OverheadFinal'
            targetFormat = format.Overhead.Final
        elseif i == self.ID_ECHO then
            targetFormat = echo.OverheadFormat
        end

        if targetFormat then
            local info = self._formatterInfo[i]
            info.formatter:setDefaultName(defaultName)
            info.formatter:setFormatString(targetFormat)
        end
    end
end


---Adds a custom preset to the configuration.
---@param preset omichat.ConfigurationPreset
---@private
function Configuration:_addCustomPreset(preset)
    self._customPresets[preset:getName()] = preset
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
            local rec = utils.copy(lang) --[[@as omichat.LanguageRecord]]
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

    self._languageAllowSet = utils.set.simple(self.Language.SelfAddAllowlist)
    self._languageBlockSet = utils.set.simple(self.Language.SelfAddBlocklist)
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
    local list = { Configuration._presets.Default }

    local other = {}
    for k, v in pairs(Configuration._presets) do
        if k ~= 'Default' then
            other[#other + 1] = v
        end
    end

    for _, v in pairs(Configuration._customPresets) do
        other[#other + 1] = v
    end

    sort(other, Configuration._sortPresets)

    self._presetList = utils.append(list, other)
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

    return self._enabledMods[modId] == true
end

---Removes a custom preset from the configuration.
---@param name string
---@private
function Configuration:_removeCustomPreset(name)
    self._customPresets[name] = nil
    self:_cachePresetList()
end

---Replaces the custom presets list with the given list.
---@param list omichat.Configuration.PresetTable[]
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
---@param a omichat.ConfigurationPreset
---@param b omichat.ConfigurationPreset
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

---@class omichat.LanguageRecord : omichat.Configuration.LanguageDefinition
---@field ID integer The ID of the language.

---@class omichat.FormatterInfo
---@field name string The name of the formatter.
---@field id integer The formatter's ID.
---@field formatter omichat.MetaFormatter The formatter.

---@class omichat.ConfigurationFormState
---@field activePresetDialog omi.ui.Dialog? The active dialog related to presets.
---@field activeFormatStringDialog omi.ui.Dialog? The active dialog with an overview of format strings.

---@class omichat.FormatDataTranslation
---@field name string The name of the token or option.
---@field id string The string ID for the description of the token or option.


---@alias omichat.Configuration.Commands.Name.Mode
---| 'Disable'
---| 'Nickname'
---| 'Forename'
---| 'Fullname'
---| 'Forename_Plus_Nickname'
---| 'Fullname_Plus_Nickname'

---@alias omichat.FormatterName
---| 'callout'
---| 'sneakCallout'
---| 'language'
---| 'overheadFinal'
---| 'adminIcon'
---| 'narrative'
---| 'onlineID'
---| 'echo'
---| 'mention'

---@alias omichat.MenuTypeString
---| 'trade'
---| 'medical'
---| 'mini_scoreboard'
---| 'search_player'

--#endregion
