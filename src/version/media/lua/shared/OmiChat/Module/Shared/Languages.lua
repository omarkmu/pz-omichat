---Handles operations related to roleplay languages.
---@namespace omichat

---@class(partial) api.shared
local API = require 'OmiChat/Module/Core/Shared'
local config = API.Configuration


---@class(partial) api.shared.language
local Language = {}

---Contains functions related to roleplay languages.
API.language = Language


---Checks whether a player character speaks a roleplay language.
---On the client, this can only retrieve information for online players.
---@param username string The player's username.
---@param language string The language name.
---@return boolean isKnown `True` if the player has the language in their list, `false` otherwise.
function Language.doesPlayerKnow(username, language)
    if config:getLanguageCount() == 0 then
        -- no configured languages → understand everything
        return true
    end

    local data = API.data.getPlayerData(username)
    local knownLanguages = data and data.languages
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

---Checks whether a configured roleplay language with the given name exists.
---@param language string The language name to check.
---@return boolean exists `True` if the language exists, `false` otherwise.
function Language.exists(language)
    return config:getLanguageByName(language) ~= nil
end

---Gets the name of a roleplay language given a language ID.
---@param id integer The language ID.
---@return string? name The language name.
function Language.fromID(id)
    return config:getLanguageNameFromId(id)
end

---Gets the name of the default roleplay language.
---@return string? default The default language, which is the first language listed in the configuration.
---If no languages are included, `nil`.
function Language.getDefault()
    return config:getLanguageNameFromId(1)
end

---Returns the ID used for a configured roleplay language.
---@param language string The language name.
---@return integer? id The language ID, or `nil` if no such language exists.
function Language.getID(language)
    return config:getLanguageIDFromName(language)
end

---Returns a list of configured roleplay languages.
---@return string[] list A list of language names.
function Language.getList()
    return config:getLanguageNameList()
end

---Returns a set of configured roleplay languages.
---@return omi.SetTable<string> list A list of language names.
function Language.getSet()
    return config:getLanguageNameSet()
end

---Returns whether a configured roleplay language is signed.
---@param language string The language name.
---@return boolean signed `True` if the language is signed, `false` otherwise.
function Language.isSigned(language)
    return config:isLanguageSigned(language)
end


return Language
