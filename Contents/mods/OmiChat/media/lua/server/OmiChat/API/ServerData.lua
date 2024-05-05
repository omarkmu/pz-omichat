---Server API functionality related to handling player data.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'
local Option = OmiChat.Option


---Adds a roleplay language for a given player.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param language string
---@return boolean success
---@return ('UNKNOWN' | 'FULL' | 'ALREADY_KNOW')? error
function OmiChat.addRoleplayLanguage(username, language)
    if not OmiChat.isConfiguredRoleplayLanguage(language) then
        return false, 'UNKNOWN'
    end

    local languages = OmiChat.getRoleplayLanguages(username)
    if #languages >= OmiChat.config:maxLanguageSlots() then
        return false, 'FULL'
    end

    for i = 1, #languages do
        if languages[i] == language then
            return false, 'ALREADY_KNOW'
        end
    end

    languages[#languages + 1] = language
    OmiChat.refreshLanguageInfo(username)
    return true
end

---Clears all player nicknames.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
function OmiChat.clearNicknames()
    local modData = OmiChat.getModData()
    modData.nicknames = {}
end

---Clears mod data for a given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
function OmiChat.clearModData(username)
    OmiChat._clearModData(username)
end

---Gets the current roleplay language for the player with the given username.
---@param username string
---@return string?
function OmiChat.getCurrentRoleplayLanguage(username)
    local modData = OmiChat.getModData()
    OmiChat.refreshLanguageInfo(username)
    return modData.currentLanguage[username]
end

---Gets the nickname for the player with the given username.
---If no nickname is set for the given username, returns `nil`.
---@param username string
---@return string?
function OmiChat.getNickname(username)
    local modData = OmiChat.getModData()
    return modData.nicknames[username]
end

---Gets a list of known roleplay languages for the player with the given username.
---@param username string
---@return string[]
function OmiChat.getRoleplayLanguages(username)
    local modData = OmiChat.getModData()
    if not modData.languages[username] then
        OmiChat.resetRoleplayLanguages(username)
    end

    return modData.languages[username]
end

---Gets the number of roleplay language slots for the player with the given username.
---@param username string
---@return integer
function OmiChat.getRoleplayLanguageSlots(username)
    local modData = OmiChat.getModData()
    return modData.languageSlots[username] or Option.LanguageSlots
end

---Resets roleplay languages for a given player.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
function OmiChat.resetRoleplayLanguages(username)
    local modData = OmiChat.getModData()
    modData.languages[username] = { OmiChat.getDefaultRoleplayLanguage() }
    OmiChat.refreshLanguageInfo(username)
end

---Sets the chat icon for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param icon string?
function OmiChat.setChatIcon(username, icon)
    local modData = OmiChat.getModData()
    modData.icons[username] = icon
end

---Sets the current roleplay language for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param language string?
---@return boolean success
function OmiChat.setCurrentRoleplayLanguage(username, language)
    if language and not OmiChat.isConfiguredRoleplayLanguage(language) then
        return false
    end

    local modData = OmiChat.getModData()
    modData.currentLanguage[username] = language

    OmiChat.refreshLanguageInfo(username)
    return true
end

---Sets the name color for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param color string? The color to use, in hex format.
function OmiChat.setNameColorString(username, color)
    local modData = OmiChat.getModData()
    modData.nameColors[username] = color
end

---Sets the roleplay languages for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param languages string[]?
function OmiChat.setRoleplayLanguages(username, languages)
    local modData = OmiChat.getModData()
    modData.languages[username] = languages
    OmiChat.refreshLanguageInfo(username)
end

---Sets the number of roleplay language slots for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param slots integer?
---@return boolean success
function OmiChat.setRoleplayLanguageSlots(username, slots)
    if slots and (slots < 1 or slots > OmiChat.config:maxLanguageSlots()) then
        return false
    end

    local modData = OmiChat.getModData()
    modData.languageSlots[username] = slots
    return true
end

---Sets the nickname for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param nickname string?
function OmiChat.setNickname(username, nickname)
    local modData = OmiChat.getModData()
    modData.nicknames[username] = nickname
end

---Sets the mod data for a given user.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param data omichat.UserModData?
function OmiChat.setUserModData(username, data)
    data = data or {}
    OmiChat.setNickname(username, data.nickname)
    OmiChat.setChatIcon(username, data.icon)
    OmiChat.setNameColorString(username, data.nameColor)
    OmiChat.setRoleplayLanguageSlots(username, data.languageSlots)
    OmiChat.setRoleplayLanguages(username, data.languages)
    OmiChat.setCurrentRoleplayLanguage(username, data.currentLanguage)
end

---Transmits mod data to clients.
function OmiChat.transmitModData()
    OmiChat.getModData()
    ModData.transmit(OmiChat._modDataKey)
end
