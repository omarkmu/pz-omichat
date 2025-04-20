---Handles player data.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server
local config = API.Configuration
local SINGLEPLAYER = not isServer()


---@class omichat.api.server.data : omichat.api.shared.data
local Data = API.data


---Adds a roleplay language for a given player.
---This does not transmit changes to clients.
---@param username string
---@param language string
---@return boolean success
---@return ('UNKNOWN' | 'FULL' | 'ALREADY_KNOW')? error
---@see omichat.api.server.data.transmit
function Data.addLanguage(username, language)
    if not API.language.exists(language) then
        return false, 'UNKNOWN'
    end

    local languages = Data.getLanguages(username)
    if #languages >= config.MAX_LANGUAGE_SLOTS then
        return false, 'FULL'
    end

    for i = 1, #languages do
        if languages[i] == language then
            return false, 'ALREADY_KNOW'
        end
    end

    languages[#languages + 1] = language
    Data.refreshLanguageInfo(username)
    return true
end

---Clears mod data for a given username.
---This does not transmit changes to clients.
---@see omichat.api.server.data.transmit
---@param username string
function Data.clearModData(username)
    Data.clear(username)
end

---Clears all player nicknames.
---This does not transmit changes to clients.
---@see omichat.api.server.data.transmit
function Data.clearNicknames()
    local modData = Data.get()
    modData.nicknames = {}
end

---Gets a list of known roleplay languages for the player with the given username.
---@param username string
---@return string[]
function Data.getLanguages(username)
    local modData = Data.get()
    if not modData.languages[username] then
        Data.resetLanguages(username)
    end

    return modData.languages[username]
end

---Gets the number of roleplay language slots for the player with the given username.
---@param username string
---@return integer
function Data.getLanguageSlots(username)
    local modData = Data.get()
    return modData.languageSlots[username] or config.Language.DefaultSlots
end

---Resets roleplay languages for a given player.
---This does not transmit changes to clients.
---@param username string
---@see omichat.api.server.data.transmit
function Data.resetLanguages(username)
    local modData = Data.get()
    modData.languages[username] = { API.language.getDefault() }
    Data.refreshLanguageInfo(username)
end

---Refreshes the cache with information from the currently online players.
---@return omi.PlayerCacheData[]
function Data.refreshPlayerCache()
    local items = {}

    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            items[#items + 1] = Data._playerCache:createPlayerData(onlinePlayers:get(i))
        end
    end

    Data.resetPlayerCache(items)
    return items
end

---Sets the chat icon for the player with the given username.
---This does not transmit changes to clients.
---@param username string
---@param icon string?
---@see omichat.api.server.data.transmit
function Data.setChatIcon(username, icon)
    local modData = Data.get()
    modData.icons[username] = icon
end

---Sets the current roleplay language for the player with the given username.
---This does not transmit changes to clients.
---@param username string
---@param language string?
---@return boolean success
---@see omichat.api.server.data.transmit
function Data.setCurrentLanguage(username, language)
    if language and not API.language.exists(language) then
        return false
    end

    local modData = Data.get()
    modData.currentLanguage[username] = language

    Data.refreshLanguageInfo(username)
    return true
end

---Sets the roleplay languages for the player with the given username.
---This does not transmit changes to clients.
---@param username string
---@param languages string[]?
---@see omichat.api.server.data.transmit
function Data.setLanguages(username, languages)
    local modData = Data.get()
    modData.languages[username] = languages
    Data.refreshLanguageInfo(username)
end

---Sets the number of roleplay language slots for the player with the given username.
---This does not transmit changes to clients.
---@param username string
---@param slots integer?
---@return boolean success
---@see omichat.api.server.data.transmit
function Data.setLanguageSlots(username, slots)
    if slots and (slots < 1 or slots > config.MAX_LANGUAGE_SLOTS) then
        return false
    end

    local modData = Data.get()
    modData.languageSlots[username] = slots
    return true
end

---Sets the nickname for the player with the given username.
---This does not transmit changes to clients.
---@param username string
---@param nickname string?
---@see omichat.api.server.data.transmit
function Data.setNickname(username, nickname)
    local modData = Data.get()
    modData.nicknames[username] = nickname
end

---Sets the mod data for a given player.
---This does not transmit changes to clients.
---@param username string
---@param data omichat.PlayerModData?
---@see omichat.api.server.data.transmit
function Data.setPlayerData(username, data)
    data = data or {}
    Data.setNickname(username, data.nickname)
    Data.setChatIcon(username, data.icon)
    Data.setLanguageSlots(username, data.languageSlots)
    Data.setLanguages(username, data.languages)
    Data.setCurrentLanguage(username, data.currentLanguage)
    Data.setStatus(username, data.status)
end

---Sets the status for the player with the given username.
---This does not transmit changes to clients.
---@param username string
---@param status string?
---@see omichat.api.server.data.transmit
function Data.setStatus(username, status)
    local modData = Data.get()
    modData.statuses[username] = status
end

---Transmits mod data to clients.
function Data.transmit()
    local data = Data.get()
    if SINGLEPLAYER then
        local _API = API --[[@as omichat.api.client]]
        _API._onReceiveGlobalModData(API._key, data) ---@diagnostic disable-line: invisible
        return
    end

    ModData.transmit(API._key)
end


API.data = Data
return Data
