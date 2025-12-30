---Handles player data.
---@namespace omichat

if isClient() then return end

---@class(partial) api.server
local API = require 'OmiChat/Module/Server/Core'
local config = API.Configuration
local utils = API.utils

---@class api.server.data : api.shared.data
local Data = API.data

---Contains functions for handling player data.
API.data = Data

---Adds a roleplay language for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param language string The language to add.
---@return boolean success
---@return ('UNKNOWN' | 'FULL' | 'ALREADY_KNOW')? error
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

---Clears data for a player.
---@param username string The player's username.
function Data.clear(username)
    local modData = Data._get()
    modData.players[username] = nil
end

---Clears all player nicknames.
---This does not broadcast changes to clients.
function Data.clearNicknames()
    local modData = Data._get()

    for _, player in pairs(modData.players) do
        player.nickname = nil
    end
end

---Gets a mutable list of known roleplay languages for a player.
---@param username string The player's username.
---@return string[] languages The player's known roleplay languages.
function Data.getLanguages(username)
    local playerData = Data._getOrCreatePlayerData(username)
    if not playerData.languages then
        Data.resetLanguages(username)
    end

    return playerData.languages --[[@as string[] ]]
end

---Gets the number of roleplay language slots for a player.
---@param username string The player's username.
---@return integer slots The total number of slots.
function Data.getLanguageSlots(username)
    local playerData = Data.getPlayerData(username)
    return playerData and playerData.languageSlots or config.Language.DefaultSlots
end

---Retrieves data for a given player, creating it if it doesn't exist.
---@param username string The player's username.
---@return PlayerData data The player's data.
function Data.getOrCreatePlayerData(username)
    return Data._getOrCreatePlayerData(username)
end

---Retrieves data for a given player.
---@param username string The player's username.
---@return PlayerData? data The player's data.
function Data.getPlayerData(username)
    return Data._get().players[username]
end

---Gets a list of all player data.
---@return PlayerData[] list
function Data.getPlayerDataList()
    local list = {}

    local data = Data._get().players
    for _, playerData in pairs(data) do
        local copy = utils.copy(playerData)
        copy.languages = utils.copyList(copy.languages)
        list[#list + 1] = copy
    end

    return list
end

---Resets roleplay languages for a given player.
---This does not broadcast changes to clients.
---@param username string The player's username.
function Data.resetLanguages(username)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.languages = { API.language.getDefault() }

    Data.refreshLanguageInfo(username)
end

---Refreshes roleplay language information for the given username.
---@param username string The player's username.
function Data.refreshLanguageInfo(username)
    local playerData = Data._getOrCreatePlayerData(username)
    local currentLang = playerData.currentLanguage
    local languages = playerData.languages
    if not languages then
        playerData.currentLanguage = nil
        return
    end

    local hasCurrentLang = false
    local validLanguages = {}
    for i = 1, #languages do
        local lang = languages[i]
        if API.language.exists(lang) then
            validLanguages[#validLanguages + 1] = lang
            if lang == currentLang then
                hasCurrentLang = true
            end
        end
    end

    playerData.languages = validLanguages
    if not hasCurrentLang or not currentLang then
        playerData.currentLanguage = validLanguages[1]
    end
end

---Refreshes the cache with information from the currently online players.
---@return PlayerCacheData[] items
function Data.refreshPlayerCache()
    local items = {}

    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            items[#items + 1] = Data._playerCache:createPlayerData(onlinePlayers:get(i))
        end
    end

    Data.setPlayerCache(items)
    return items
end

---Sets the chat icon for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param icon string? The name of the texture to use as the icon, or `nil` to remove.
function Data.setChatIcon(username, icon)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.icon = icon
end

---Sets the current roleplay language for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param language string? The current language.
---@return boolean success
function Data.setCurrentLanguage(username, language)
    if language and not API.language.exists(language) then
        return false
    end

    local playerData = Data._getOrCreatePlayerData(username)
    playerData.currentLanguage = language

    Data.refreshLanguageInfo(username)
    return true
end

---Sets the roleplay languages for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param languages string[]? The new list of languages.
function Data.setLanguages(username, languages)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.languages = languages

    Data.refreshLanguageInfo(username)
end

---Sets the number of roleplay language slots for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param slots integer? The new slot count, or `nil` to unset.
---@return boolean success
function Data.setLanguageSlots(username, slots)
    if slots and (slots < 1 or slots > config.MAX_LANGUAGE_SLOTS) then
        return false
    end

    local playerData = Data._getOrCreatePlayerData(username)
    playerData.languageSlots = slots

    return true
end

---Sets the nickname for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param nickname string? The new nickname.
function Data.setNickname(username, nickname)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.nickname = nickname
end

---Sets the data for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param data PlayerData The new data to set.
function Data.setPlayerData(username, data)
    if not data then
        return
    end

    Data.setNickname(username, data.nickname)
    Data.setChatIcon(username, data.icon)
    Data.setLanguageSlots(username, data.languageSlots)
    Data.setLanguages(username, data.languages)
    Data.setCurrentLanguage(username, data.currentLanguage)
    Data.setStatus(username, data.status)
end

---Sets the status for a player.
---This does not broadcast changes to clients.
---@param username string The player's username.
---@param status string? The new status, or `nil` to unset.
function Data.setStatus(username, status)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.status = status
end

---Attempts to update data as the given player.
---@param player IsoPlayer The player to perform the update as.
---@param args Args.Request.PlayerDataUpdate The data for the update.
---@param broadcast boolean? Flag for whether the update should be broadcast. Defaults to `true`.
---@return boolean success
---@return string? errorID
function Data.tryUpdate(player, args, broadcast)
    local field = args.field
    if field ~= 'all' then
        -- individual fields can only be set for online players
        local targetPlayer = args.target and utils.getPlayerByUsername(args.target)
        if not targetPlayer then
            return false, 'UNKNOWN_PLAYER'
        end
    end

    if not utils.canAccessTarget(player, args.target, args.fromCommand) then
        return false
    end

    local success, err = Data._updateField(field, args.target, args.value, args.fromCommand)

    if broadcast ~= false then
        API.request.updatePlayerCache()
    end

    return success, err
end

---Updates a player data field.
---@param field PlayerDataField The field to update.
---@param target string The target username.
---@param value any? The new field value.
---@param fromCommand boolean? Flag for whether this request comes from a command.
---@return boolean success
---@return string? errorID
---@private
function Data._updateField(field, target, value, fromCommand)
    if field == 'all' then
        if not value then
            return false
        end

        Data.setPlayerData(target, value)
    elseif field == 'currentLanguage' then
        if not value then
            return false
        end

        return Data.setCurrentLanguage(target, value)
    elseif field == 'icon' then
        Data.setChatIcon(target, value and tostring(value) or nil)
        return true
    elseif field == 'languages' then
        if not value then
            Data.resetLanguages(target)
            return true
        end

        return Data.addLanguage(target, value)
    elseif field == 'languageSlots' then
        local slots = utils.tointeger(value)
        if not slots then
            return false
        end

        return Data.setLanguageSlots(target, slots)
    elseif field == 'nickname' then
        if not config:isNicknameEnabled() and not fromCommand then
            return false
        end

        Data.setNickname(target, value and tostring(value) or nil)
    elseif field == 'status' then
        if not config.Commands.Status.Enable and not fromCommand then
            return false
        end

        Data.setStatus(target, value and tostring(value) or nil)
    end

    return true
end


return Data

--#region Type Definitions

---@alias PlayerDataField
---| 'all'
---| 'nickname'
---| 'languages'
---| 'languageSlots'
---| 'currentLanguage'
---| 'icon'
---| 'status'

--#endregion
