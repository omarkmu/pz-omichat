---Contains mod configuration and enables updating it.

local utils = require 'OmiChat/utils'
local MetaFormatter = require 'OmiChat/Component/MetaFormatter'
local base = utils.configuration.ConfigurationHelper


---@class omichat.ConfigurationHelper : omi.ConfigurationHelper, omichat.Configuration
local Configuration = utils.configuration {
    schema = require 'OmiChat/Component/Configuration/Schema',
    filename = 'omichat_server.json',
    logger = utils.log,

    ---@param self omichat.ConfigurationHelper
    init = function(self)
        self:refreshEnabledMods()

        -- server should load from file
        if not isClient() and self:loadFile() then
            self:saveFile()
            self:updateFormatters()
            return
        end

        -- client should load defaults; will ultimately be received from server
        self:loadDefaults()
        self:updateFormatters()
    end,

    ---@param self omichat.ConfigurationHelper
    onLoad = function(self) self:refreshValueCaches() end,

    ---@param self omichat.ConfigurationHelper
    onSave = function(self)
        ---@diagnostic disable-next-line: invisible
        local cb = self._onSaveCallback
        if cb then
            cb()
        end
    end,
}


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
Configuration.MAX_META_ID = 88

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
}



---Checks the language against the add language allow/block list.
---This does not check whether the language is a valid roleplay language.
---@param language string
---@return boolean
---@see omichat.api.shared.language.exists
function Configuration:canAddLanguage(language)
    if not table.isempty(self._languageAllowSet) and not self._languageAllowSet[language] then
        return false
    end

    return not self._languageBlockSet[language]
end

---Returns whether the Discord color option should be shown.
---@return boolean
function Configuration:canShowDiscordColorOption()
    local opt = self.Discord.ShowColorOption
    if opt == 'Respect_Server_Setting' then
        return getServerOptions():getBoolean('DiscordEnable')
    end

    return opt == 'Yes'
end

---Returns an iterator over configured streams.
---@return fun(): omichat.Configuration.StreamDefinition?
function Configuration:chatStreams()
    local list = self.Streams.List
    local i = 0
    return function()
        i = i + 1
        return list[i]
    end
end

---Returns whether the Buffy's Character Bios compatibility patch is enabled.
function Configuration:compatBuffyCharacterBiosEnabled()
    return self:_isCompatEnabled(self.Compatibility.BuffyCharacterBios, 'CharacterBio')
end

---Returns whether the Buffy's Tabletop RPG System compatibility patch is enabled.
function Configuration:compatBuffyRPGSystemEnabled()
    return self:_isCompatEnabled(self.Compatibility.BuffyRPGSystem, 'roleplaydnd_update15')
end

---Returns whether the Chat Bubble compatibility patch is enabled.
---@return boolean
function Configuration:compatChatBubbleEnabled()
    return self:_isCompatEnabled(self.Compatibility.ChatBubble, 'ChatBubble')
end

---Returns whether the Search Players For Weapons compatibility patch is enabled.
---@return boolean
function Configuration:compatSearchPlayersEnabled()
    return self:_isCompatEnabled(self.Compatibility.SearchPlayers, 'SearchPlayersForWeapons')
end

---Returns whether the True Actions Dancing compatibility patch is enabled.
---@return boolean
function Configuration:compatTADEnabled()
    return self:_isCompatEnabled(self.Compatibility.TrueActionsDancing, 'TrueActionsDancing')
end

---Returns an iterator over metadata formatter information.
---@return fun(): omichat.FormatterInfo?
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
---@return string[]
function Configuration:getCardItems()
    return utils.copy(self.Commands.Card.Items)
end

---Returns a table of valid items for /flip.
---@return table
function Configuration:getCoinItems()
    return utils.copy(self.Commands.Flip.Items)
end

---Returns a table of valid items for /roll.
---@return table
function Configuration:getDiceItems()
    return utils.copy(self.Commands.Roll.Items)
end

---Retrieves information about a roleplay language given its id.
---@param id integer
---@return omichat.LanguageRecord?
function Configuration:getLanguageById(id)
    local rec = self._idToLanguage[id]
    if rec then
        return utils.copy(rec)
    end
end

---Retrieves information about a roleplay language given its name.
---@param name string
---@return omichat.LanguageRecord?
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
---@param name string
---@return integer?
function Configuration:getLanguageIDFromName(name)
    local rec = self._nameToLanguage[name]
    if rec then
        return rec.ID
    end
end

---Retrieves the list of configured roleplay languages.
---@return omichat.LanguageRecord[]
function Configuration:getLanguageList()
    return utils.mapList(utils.copy, self._idToLanguage)
end

---Gets the name of a language given its id.
---@param id integer
---@return string?
function Configuration:getLanguageNameFromId(id)
    local rec = self._idToLanguage[id]
    if rec then
        return rec.Name
    end
end

---Retrieves the list of configured roleplay languages' names.
---@return string[]
function Configuration:getLanguageNameList()
    return utils.copyList(self._languageNameList)
end

---Returns the format to use for a given menu type.
---@param menuType omichat.MenuTypeString
---@return string
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
    elseif menuType == 'typing' then
        format = option.Typing
    end

    if format == '' then
        format = nil
    end

    return format or option.Default or ''
end

---Returns the schema of the configuration.
---@return omichat.ConfigurationSchema
function Configuration:getSchema()
    local schema = base.getSchema(self) ---@cast schema omichat.ConfigurationSchema
    return schema
end

---Returns the current configuration as a simple table.
---@return omichat.Configuration
function Configuration:getValues()
    return base.getValues(self)
end

---Gets sanitized configuration values that are prepared for saving.
---@return omichat.Configuration
function Configuration:getValuesForSave()
    return base.getValuesForSave(self)
end

---Returns whether the clean character option is set to clean the body.
---This does not check for whether the character customization feature is enabled.
---@return boolean
function Configuration:isCleanBodyEnabled()
    return not not self.Customization.CleanEffects.Body
end

---Returns whether the clean character option is set to clean clothing.
---This does not check for whether the character customization feature is enabled.
---@return boolean
function Configuration:isCleanClothingEnabled()
    return not not self.Customization.CleanEffects.Clothing
end

---Returns whether the clean character option is enabled.
---This does not check for whether the character customization feature is enabled.
---@return boolean
function Configuration:isCleanCustomizationEnabled()
    return not table.isempty(self.Customization.CleanEffects)
end

---Returns whether custom shouts are enabled.
---@return boolean
function Configuration:isCustomShoutsEnabled()
    return self.Customization.AllowCustomShouts
end

---Returns whether emote shortcut macros are enabled.
---@return boolean
function Configuration:isEmoteMacroEnabled()
    return self.Macros.AllowEmotes
end

---Returns `true` if a given language exists and is signed.
---@param name string
---@return boolean
function Configuration:isLanguageSigned(name)
    local rec = self._nameToLanguage[name]
    return rec ~= nil and rec.Signed == true
end

---Returns whether the /name command should be enabled.
---@return boolean
function Configuration:isNameCommandEnabled()
    return self.Commands.Name.Mode ~= 'Disable'
end

---Returns whether /name should set characters' forenames.
---@return boolean
function Configuration:isNameCommandSetForename()
    local mode = self.Commands.Name.Mode
    return mode == 'Forename' or mode == 'Forename_Plus_Nickname'
end

---Returns whether /name should set characters' full names.
---@return boolean
function Configuration:isNameCommandSetFullName()
    local mode = self.Commands.Name.Mode
    return mode == 'Fullname' or mode == 'Fullname_Plus_Nickname'
end

---Returns whether /name should set characters' nicknames.
---@return boolean
function Configuration:isNameCommandSetNickname()
    return self.Commands.Name.Mode == 'Nickname'
end

---Returns whether the /nickname command should be enabled.
---@return boolean
function Configuration:isNicknameCommandEnabled()
    local mode = self.Commands.Name.Mode
    return mode == 'Forename_Plus_Nickname' or mode == 'Fullname_Plus_Nickname'
end

---Returns whether the /nickname command is enabled, or /name sets nicknames.
---@return boolean
function Configuration:isNicknameEnabled()
    return self:isNicknameCommandEnabled() or self.Commands.Name.Mode == 'Nickname'
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
end

---Checks whether an item is required for /card.
---@return boolean
function Configuration:requireCardItem()
    return #self.Commands.Card.Items > 0
end

---Checks whether an item is required for /flip.
---@return boolean
function Configuration:requireCoinItem()
    return #self.Commands.Flip.Items > 0
end

---Checks whether an item is required for /roll.
---@return boolean
function Configuration:requireDiceItem()
    return #self.Commands.Roll.Items > 0
end

---Sets a callback to call on save.
---@param onSave function
function Configuration:setOnSave(onSave)
    self._onSaveCallback = onSave
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


---Caches the configured languages and information about them.
---@protected
function Configuration:_cacheLanguages()
    local languages = self.Language.List

    self._idToLanguage = {}
    self._nameToLanguage = {}
    self._languageNameList = {}

    for i = 1, #languages do
        local lang = languages[i]
        if not self._nameToLanguage[lang.Name] and not utils.isNilOrWhitespace(lang.Name) then
            local rec = utils.copy(lang) ---@cast rec omichat.LanguageRecord
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

---Checks whether a mod compatibility option is enabled.
---@param value omi.schema.CompatibilityValue The value of the option.
---@param modId string The mod ID of the relevant mod.
---@return boolean
---@protected
function Configuration:_isCompatEnabled(value, modId)
    if value ~= 'Auto' then
        return value == 'Enable'
    end

    return self._enabledMods[modId] == true
end


Configuration:init()
return Configuration
