---Handles operations related to roleplay languages.

---@class omichat.api.shared
local API = require 'OmiChat/Module/Shared/Core'
local config = API.Configuration


---@class omichat.api.shared.language
local Language = {}


---Checks whether the player with the given username speaks a roleplay language.
---@param username string
---@param language string
---@return boolean
function Language.doesPlayerKnow(username, language)
    if config:getLanguageCount() == 0 then
        -- no configured languages → understand everything
        return true
    end

    local modData = API.data.get()
    local knownLanguages = modData.languages[username]
    if type(knownLanguages) ~= 'table' or #knownLanguages == 0 then
        -- no languages chosen → understand only default language
        return config:getLanguageIDFromName(language) == 1
    end

    for i = 1, #knownLanguages do
        if knownLanguages[i] == language then
            return true
        end
    end

    return false
end

---Checks whether the given string is the name of a configured roleplay language.
---@param language string
---@return boolean
function Language.exists(language)
    return config:getLanguageByName(language) ~= nil
end

---Gets the name of a roleplay language given a language ID.
---@param id integer
---@return string?
function Language.fromID(id)
    return config:getLanguageNameFromId(id)
end

---Gets the name of the default roleplay language, which is the first one listed in the configuration.
---@return string?
function Language.getDefault()
    return config:getLanguageNameFromId(1)
end

---Returns the ID used for a configured roleplay language.
---@param language string
---@return integer?
function Language.getID(language)
    return config:getLanguageIDFromName(language)
end

---Returns a list of configured roleplay languages.
---@return string[]
function Language.getList()
    return config:getLanguageNameList()
end

---Returns whether a configured roleplay language is signed.
---@param language string
---@return boolean
function Language.isSigned(language)
    return config:isLanguageSigned(language)
end


API.language = Language
return Language
