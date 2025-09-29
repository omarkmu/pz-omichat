---Handles player data.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server
local config = API.Configuration
local utils = API.utils


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
    ModData.transmit(API._key)
end

---Attempts to update data as the given player.
---@param player IsoPlayer The player to perform the update as.
---@param args omichat.request.ModDataUpdate The data for the update.
---@param transmit boolean? Whether the update should be transmitted. Defaults to `true`.
---@return boolean success
---@return string? errorID
function Data.tryUpdate(player, args, transmit)
    local field = args.field
    if field ~= 'all' then
        -- individual fields can only be set for online players
        local targetPlayer = args.target and utils.getPlayerByUsername(args.target)
        if not targetPlayer then
            return false, 'UNKNOWN_PLAYER'
        end
    end

    local minAccessLevel = config.General.MinimumCommandAccessLevel
    if not utils.canAccessTarget(player, args.target, minAccessLevel, args.fromCommand) then
        return false
    end

    local success, err = Data._updateField(field, args.target, args.value, args.fromCommand)

    if transmit ~= false then
        API.data.transmit()
    end

    return success, err
end

---Updates a mod data field.
---@param field omichat.ModDataField
---@param target string
---@param value unknown?
---@param fromCommand boolean?
---@return boolean success
---@return string? errorID
---@protected
function Data._updateField(field, target, value, fromCommand)
    if field == 'all' then
        if not value then
            return false
        end

        API.data.setPlayerData(target, value)
    elseif field == 'currentLanguage' then
        if not value then
            return false
        end

        return API.data.setCurrentLanguage(target, value)
    elseif field == 'icons' then
        API.data.setChatIcon(target, value and tostring(value) or nil)
        return true
    elseif field == 'languages' then
        if not value then
            API.data.resetLanguages(target)
            return true
        end

        return API.data.addLanguage(target, value)
    elseif field == 'languageSlots' then
        local slots = tonumber(value)
        if not slots then
            return false
        end

        return API.data.setLanguageSlots(target, slots)
    elseif field == 'nicknames' then
        if not config:isNicknameEnabled() and not fromCommand then
            return false
        end

        API.data.setNickname(target, value and tostring(value) or nil)
    elseif field == 'statuses' then
        if not config.Commands.Status.Enable and not fromCommand then
            return false
        end

        API.data.setStatus(target, value and tostring(value) or nil)
    end

    return true
end


API.data = Data
return Data
