---Server API functionality related to handling player data.

if not isServer() then return end


---@class omichat.api.server
local API = require 'OmiChat/API/Server/Core'
local Option = API.Option


---Adds a roleplay language for a given player.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param language string
---@return boolean success
---@return ('UNKNOWN' | 'FULL' | 'ALREADY_KNOW')? error
function API.addRoleplayLanguage(username, language)
    if not API.isConfiguredRoleplayLanguage(language) then
        return false, 'UNKNOWN'
    end

    local languages = API.getRoleplayLanguages(username)
    if #languages >= API.config:maxLanguageSlots() then
        return false, 'FULL'
    end

    for i = 1, #languages do
        if languages[i] == language then
            return false, 'ALREADY_KNOW'
        end
    end

    languages[#languages + 1] = language
    API.refreshLanguageInfo(username)
    return true
end

---Clears all player nicknames.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
function API.clearNicknames()
    local modData = API.getModData()
    modData.nicknames = {}
end

---Clears mod data for a given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
function API.clearModData(username)
    API._clearModData(username)
end

---Gets the current roleplay language for the player with the given username.
---@param username string
---@return string?
function API.getCurrentRoleplayLanguage(username)
    local modData = API.getModData()
    API.refreshLanguageInfo(username)
    return modData.currentLanguage[username]
end

---Gets the nickname for the player with the given username.
---If no nickname is set for the given username, returns `nil`.
---@param username string
---@return string?
function API.getNickname(username)
    local modData = API.getModData()
    return modData.nicknames[username]
end

---Gets a list of known roleplay languages for the player with the given username.
---@param username string
---@return string[]
function API.getRoleplayLanguages(username)
    local modData = API.getModData()
    if not modData.languages[username] then
        API.resetRoleplayLanguages(username)
    end

    return modData.languages[username]
end

---Gets the number of roleplay language slots for the player with the given username.
---@param username string
---@return integer
function API.getRoleplayLanguageSlots(username)
    local modData = API.getModData()
    return modData.languageSlots[username] or Option.LanguageSlots
end

---Resets roleplay languages for a given player.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
function API.resetRoleplayLanguages(username)
    local modData = API.getModData()
    modData.languages[username] = { API.getDefaultRoleplayLanguage() }
    API.refreshLanguageInfo(username)
end

---Sets the chat icon for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param icon string?
function API.setChatIcon(username, icon)
    local modData = API.getModData()
    modData.icons[username] = icon
end

---Sets the current roleplay language for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param language string?
---@return boolean success
function API.setCurrentRoleplayLanguage(username, language)
    if language and not API.isConfiguredRoleplayLanguage(language) then
        return false
    end

    local modData = API.getModData()
    modData.currentLanguage[username] = language

    API.refreshLanguageInfo(username)
    return true
end

---Sets the name color for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param color string? The color to use, in hex format.
function API.setNameColorString(username, color)
    local modData = API.getModData()
    modData.nameColors[username] = color
end

---Sets the roleplay languages for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param languages string[]?
function API.setRoleplayLanguages(username, languages)
    local modData = API.getModData()
    modData.languages[username] = languages
    API.refreshLanguageInfo(username)
end

---Sets the number of roleplay language slots for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param slots integer?
---@return boolean success
function API.setRoleplayLanguageSlots(username, slots)
    if slots and (slots < 1 or slots > API.config:maxLanguageSlots()) then
        return false
    end

    local modData = API.getModData()
    modData.languageSlots[username] = slots
    return true
end

---Sets the nickname for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param nickname string?
function API.setNickname(username, nickname)
    local modData = API.getModData()
    modData.nicknames[username] = nickname
end

---Sets the mod data for a given user.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param data omichat.UserModData?
function API.setUserModData(username, data)
    data = data or {}
    API.setNickname(username, data.nickname)
    API.setChatIcon(username, data.icon)
    API.setNameColorString(username, data.nameColor)
    API.setRoleplayLanguageSlots(username, data.languageSlots)
    API.setRoleplayLanguages(username, data.languages)
    API.setCurrentRoleplayLanguage(username, data.currentLanguage)
end

---Transmits mod data to clients.
function API.transmitModData()
    API.getModData()
    ModData.transmit(API._modDataKey)
end
