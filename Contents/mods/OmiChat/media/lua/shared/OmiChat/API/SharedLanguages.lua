---Shared API functionality related to roleplay languages.

---@class omichat.api.shared
local OmiChat = require 'OmiChat/API/Shared'
OmiChat._languageInfo = {
    languageCount = 0,
    availableLanguages = '',
    signedLanguages = '',
    idToLanguage = {},
    languageToID = {},
    languageIsSignedMap = {},
}

local utils = OmiChat.utils
local Option = OmiChat.Option


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
    return langInfo
end


---Checks whether the player with the given username can understand a given roleplay language.
---@param username string
---@param language string
---@return boolean
function OmiChat.checkPlayerKnowsLanguage(username, language)
    local langInfo = getLanguageInfo()
    if langInfo.languageCount == 0 then
        -- no configured languages → understand everything
        return true
    end

    local modData = OmiChat.getModData()
    local knownLanguages = modData.languages[username]
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

---Returns a list of configured roleplay languages.
---@return string[]
function OmiChat.getConfiguredRoleplayLanguages()
    return utils.copy(getLanguageInfo().idToLanguage)
end

---Gets the default roleplay language, which is the first one listed in the configuration.
---@return string?
function OmiChat.getDefaultRoleplayLanguage()
    return OmiChat.getRoleplayLanguageFromID(1)
end

---Gets a roleplay language given a language ID.
---@param id integer
---@return string?
function OmiChat.getRoleplayLanguageFromID(id)
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

---Checks whether the language is a configured roleplay language.
---@param language string
---@return boolean
function OmiChat.isConfiguredRoleplayLanguage(language)
    return getLanguageInfo().languageToID[language] ~= nil
end

---Returns whether a configured roleplay language is signed.
---@param language string
---@return boolean
function OmiChat.isRoleplayLanguageSigned(language)
    return getLanguageInfo().languageIsSignedMap[language] or false
end
