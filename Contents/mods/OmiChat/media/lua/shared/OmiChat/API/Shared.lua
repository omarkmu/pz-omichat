---Base shared API.

local config = require 'OmiChat/config'
local utils = require 'OmiChat/util'
local Option = require 'OmiChat/Component/Options'
local MetaFormatter = require 'OmiChat/Component/MetaFormatter'


---@class omichat.api.shared
---@field protected _modDataKey string
---@field protected _modDataVersion integer
---@field protected _playerModDataVersion integer
---@field protected _languageInfo omichat.LanguageInfoStore
local OmiChat = {}

OmiChat.Option = Option
OmiChat.MetaFormatter = MetaFormatter
OmiChat.config = config
OmiChat.utils = utils
OmiChat._modDataKey = 'omichat'
OmiChat._modDataVersion = 1
OmiChat._playerModDataVersion = 1
OmiChat._languageInfo = {
    languageCount = 0,
    availableLanguages = '',
    signedLanguages = '',
    idToLanguage = {},
    languageToID = {},
    languageIsSignedMap = {},
}


---Retrieves information about configured roleplay language options.
---Performs a refresh of cached language info if necessary.
---@return omichat.LanguageInfoStore
local function getLanguageInfo()
    local langInfo = OmiChat._languageInfo
    local noChanges = langInfo.availableLanguages == Option.AvailableLanguages
        and langInfo.signedLanguages == Option.SignedLanguages

    if noChanges then
        return langInfo
    end

    langInfo.availableLanguages = Option.AvailableLanguages
    langInfo.signedLanguages = Option.SignedLanguages
    table.wipe(langInfo.languageToID)
    table.wipe(langInfo.idToLanguage)
    table.wipe(langInfo.languageIsSignedMap)

    local nextId = 1
    local languageList = Option.AvailableLanguages:split(';')
    for i = 1, #languageList do
        local lang = utils.trim(languageList[i])
        if lang ~= '' and not langInfo.languageToID[lang] then
            langInfo.languageToID[lang] = nextId
            langInfo.idToLanguage[nextId] = lang
            nextId = nextId + 1

            if nextId == 33 then
                -- maximum of 32 languages
                break
            end
        end
    end

    local signedLanguageList = Option.SignedLanguages:split(';')
    for i = 1, #signedLanguageList do
        local language = utils.trim(signedLanguageList[i])
        if language ~= '' then
            langInfo.languageIsSignedMap[language] = true
        end
    end

    langInfo.languageCount = nextId - 1
    if isClient() then
        local modData = OmiChat.getPlayerModData(getSpecificPlayer(0))
        if not modData then
            return langInfo
        end

        -- refresh player language data
        local hasCurrentLang
        local validLanguages = {}
        for i = 1, #modData.languages do
            local lang = modData.languages[i]
            if langInfo.languageToID[lang] then
                validLanguages[#validLanguages + 1] = lang

                if lang == modData.currentLanguage then
                    hasCurrentLang = true
                end
            end
        end

        modData.languages = validLanguages
        if not hasCurrentLang or not modData.currentLanguage then
            modData.currentLanguage = validLanguages[1]
        end
    end

    return langInfo
end


---Checks whether a player can understand a given language.
---@param player IsoPlayer
---@param language string
---@return boolean
function OmiChat.canPlayerUnderstandLanguage(player, language)
    local langInfo = getLanguageInfo()
    if langInfo.languageCount == 0 then
        -- no configured languages → understand everything
        return true
    end

    local modData = OmiChat.getPlayerModData(player)
    local knownLanguages = modData and modData.languages
    if type(knownLanguages) ~= 'table' or #knownLanguages == 0 then
        -- no languages chosen → understand only default language
        return langInfo.languageToID[language] == 1
    end

    for i = 1, #knownLanguages do
        if knownLanguages[i] == language then
            return true
        end
    end

    return false
end

---Gets the default roleplay language, which is the first one listed in the configuration.
---@return string?
function OmiChat.getDefaultRoleplayLanguage()
    return OmiChat.getRoleplayLanguageByID(1)
end

---Gets or creates the global mod data table.
---@return omichat.ModData
function OmiChat.getModData()
    ---@type omichat.ModData
    local modData = ModData.getOrCreate(OmiChat._modDataKey)

    modData.version = OmiChat._modDataVersion
    modData.nicknames = modData.nicknames or {}
    modData.nameColors = modData.nameColors or {}

    return modData
end

---Returns the color table for a user's name color, or `nil` if unset.
---@param username string
---@return omichat.ColorTable?
function OmiChat.getNameColor(username)
    if not Option.EnableSetNameColor or not username then
        return
    end

    return utils.stringToColor(OmiChat.getModData().nameColors[username])
end

---Returns the color table used for a user's name color in chat, or `nil` if unset.
---This respects the `EnableSpeechColorAsDefaultNameColor` option.
---@param username string
---@return omichat.ColorTable?
function OmiChat.getNameColorInChat(username)
    local nameColor = OmiChat.getNameColor(username)
    if nameColor then
        return nameColor
    end

    if Option.EnableSpeechColorAsDefaultNameColor then
        return Option:getDefaultColor('name', username)
    end
end

---Retrieves the name that should be used in chat for a given username.
---@param username string
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the user.
function OmiChat.getNameInChat(username, chatType)
    if not username then
        return
    end

    local player = utils.getPlayerByUsername(username)
    local tokens = player and OmiChat.getPlayerSubstitutions(player)
    if not tokens then
        return
    end

    local modData = OmiChat.getModData()
    if modData.nicknames[username] then
        tokens.name = utils.escapeRichText(modData.nicknames[username])
    end

    tokens.username = username
    tokens.chatType = chatType
    return utils.interpolate(Option.FormatName, tokens)
end

---Gets or creates the player mod data table.
---@param player IsoPlayer
---@return omichat.PlayerModData?
function OmiChat.getPlayerModData(player)
    local fullModData = player and player:getModData()
    if not fullModData then
        return
    end

    local modData = fullModData[OmiChat._modDataKey]
    if not modData then
        modData = {}
        fullModData[OmiChat._modDataKey] = modData
    end

    modData.version = OmiChat._playerModDataVersion
    modData.languages = modData.languages or { getLanguageInfo().idToLanguage[1] }
    modData.languageSlots = modData.languageSlots or Option.LanguageSlots

    return modData
end

---Gets substitution tokens to use in interpolation for a given player.
---If the player descriptor could not be obtained, returns `nil`.
---@param player IsoPlayer?
---@return table?
function OmiChat.getPlayerSubstitutions(player)
    local desc = player and player:getDescriptor()
    if not player or not desc then
        return
    end

    return {
        forename = desc:getForename(),
        surname = desc:getSurname(),
        username = player:getUsername(),
    }
end

---Gets a roleplay language given a language ID.
---@param id integer
---@return string?
function OmiChat.getRoleplayLanguageByID(id)
    if id < 1 or id > 32 then
        return
    end

    return getLanguageInfo().idToLanguage[id]
end

---Returns the ID used for a configured roleplay language.
---@param language string
---@return integer?
function OmiChat.getRoleplayLanguageID(language)
    return getLanguageInfo().languageToID[language]
end

---Returns a list of configured roleplay languages.
---@return string[]
function OmiChat.getConfiguredRoleplayLanguages()
    return utils.copy(getLanguageInfo().idToLanguage)
end

---Checks whether the language is a configured roleplay language.
---@param language string
---@return boolean
function OmiChat.isConfiguredRoleplayLanguage(language)
    return getLanguageInfo().languageToID[language] ~= nil
end

---Returns true if the custom chat stream specified is enabled.
---@param name omichat.CustomStreamName
---@return boolean
function OmiChat.isCustomStreamEnabled(name)
    local info = config:getCustomStreamInfo(name)
    if not info then
        return false
    end

    local value = Option[info.chatFormatOpt]
    return value and value ~= ''
end

---Returns whether a configured roleplay language is signed.
---@param language string
---@return boolean
function OmiChat.isRoleplayLanguageSigned(language)
    return getLanguageInfo().languageIsSignedMap[language] or false
end

---Adds a function that should be available to all interpolator patterns.
---@param name string
---@param func function
function OmiChat.registerInterpolatorFunction(name, func)
    ---@diagnostic disable-next-line: invisible
    utils.Interpolator._registeredFunctions[name:lower()] = func
end


return OmiChat
