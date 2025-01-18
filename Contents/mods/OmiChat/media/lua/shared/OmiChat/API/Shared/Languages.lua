---Shared API functionality related to roleplay languages.

---@class omichat.api.shared
local API = require 'OmiChat/API/Shared/Core'
local config = API.Configuration


---Checks whether the player with the given username can understand a given roleplay language.
---@param username string
---@param language string
---@return boolean
function API.checkPlayerKnowsLanguage(username, language)
    if config:getLanguageCount() == 0 then
        -- no configured languages → understand everything
        return true
    end

    local modData = API.getModData()
    local knownLanguages = modData.languages[username]
    if type(knownLanguages) ~= 'table' or #knownLanguages == 0 then
        -- no languages chosen → understand only default language
        local langInfo = config:getLanguageByName(language)
        return langInfo ~= nil and langInfo.ID == 1
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
function API.getConfiguredRoleplayLanguages()
    return config:getLanguageNameList()
end

---Gets the default roleplay language, which is the first one listed in the configuration.
---@return string?
function API.getDefaultRoleplayLanguage()
    return API.getRoleplayLanguageFromID(1)
end

---Gets a roleplay language given a language ID.
---@param id integer
---@return string?
function API.getRoleplayLanguageFromID(id)
    return config:getLanguageNameFromId(id)
end

---Returns the ID used for a configured roleplay language.
---@param language string
---@return integer?
function API.getRoleplayLanguageID(language)
    return config:getLanguageIDFromName(language)
end

---Checks whether the language is a configured roleplay language.
---@param language string
---@return boolean
function API.isConfiguredRoleplayLanguage(language)
    return config:getLanguageByName(language) ~= nil
end

---Returns whether a configured roleplay language is signed.
---@param language string
---@return boolean
function API.isRoleplayLanguageSigned(language)
    return config:isLanguageSigned(language)
end

---Refreshes roleplay language information for the given username.
---@param username string
function API.refreshLanguageInfo(username)
    local modData = API.getModData()
    local currentLang = modData.currentLanguage[username]
    local languages = modData.languages[username]
    if not languages then
        modData.currentLanguage[username] = nil
        return
    end

    local hasCurrentLang = false
    local validLanguages = {}
    for i = 1, #languages do
        local lang = languages[i]
        if API.isConfiguredRoleplayLanguage(lang) then
            validLanguages[#validLanguages + 1] = lang
            if lang == currentLang then
                hasCurrentLang = true
            end
        end
    end

    modData.languages[username] = validLanguages
    if not hasCurrentLang or not currentLang then
        modData.currentLanguage[username] = validLanguages[1]
    end
end
