---Handles player data.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server
local config = API.Configuration
local utils = API.utils


---@class omichat.api.server.data : omichat.api.shared.data
local Data = API.data


---Adds a roleplay language for a given player.
---This does not broadcast changes to clients.
---@param username string
---@param language string
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

---Clears mod data for a given username.
---@param username string
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

---Gets a list of known roleplay languages for the player with the given username.
---@param username string
---@return string[]
function Data.getLanguages(username)
    local playerData = Data._getOrCreatePlayerData(username)
    if not playerData.languages then
        Data.resetLanguages(username)
    end

    return playerData.languages
end

---Gets the number of roleplay language slots for the player with the given username.
---@param username string
---@return integer
function Data.getLanguageSlots(username)
    local playerData = Data._getOrCreatePlayerData(username)
    return playerData and playerData.languageSlots or config.Language.DefaultSlots
end

---Retrieves mod data for a given player.
---@param username string
---@return omichat.PlayerModData
function Data.getPlayerData(username)
    local playerData = utils.copy(Data._getOrCreatePlayerData(username))
    playerData.languages = utils.copyList(playerData.languages)

    return playerData
end

---Gets player data as a list associated with usernames.
---@return omichat.PlayerModData[] data
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
---@param username string
function Data.resetLanguages(username)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.languages = { API.language.getDefault() }

    Data.refreshLanguageInfo(username)
end

---Refreshes roleplay language information for the given username.
---@param username string
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
---@return omichat.PlayerCacheData[]
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

---Sets the chat icon for the player with the given username.
---This does not broadcast changes to clients.
---@param username string
---@param icon string?
function Data.setChatIcon(username, icon)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.icon = icon
end

---Sets the current roleplay language for the player with the given username.
---This does not broadcast changes to clients.
---@param username string
---@param language string?
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

---Sets the roleplay languages for the player with the given username.
---This does not broadcast changes to clients.
---@param username string
---@param languages string[]?
function Data.setLanguages(username, languages)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.languages = languages

    Data.refreshLanguageInfo(username)
end

---Sets the number of roleplay language slots for the player with the given username.
---This does not broadcast changes to clients.
---@param username string
---@param slots integer?
---@return boolean success
function Data.setLanguageSlots(username, slots)
    if slots and (slots < 1 or slots > config.MAX_LANGUAGE_SLOTS) then
        return false
    end

    local playerData = Data._getOrCreatePlayerData(username)
    playerData.languageSlots = slots

    return true
end

---Sets the nickname for the player with the given username.
---This does not broadcast changes to clients.
---@param username string
---@param nickname string?
function Data.setNickname(username, nickname)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.nickname = nickname
end

---Sets the mod data for a given player.
---This does not broadcast changes to clients.
---@param username string
---@param data omichat.PlayerModData?
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
---This does not broadcast changes to clients.
---@param username string
---@param status string?
function Data.setStatus(username, status)
    local playerData = Data._getOrCreatePlayerData(username)
    playerData.status = status
end

---Attempts to update data as the given player.
---@param player IsoPlayer The player to perform the update as.
---@param args omichat.request.ModDataUpdate The data for the update.
---@param broadcast boolean? Whether the update should be broadcast. Defaults to `true`.
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

    local minAccessLevel = config.General.MinimumCommandAccessLevel
    if not utils.canAccessTarget(player, args.target, minAccessLevel, args.fromCommand) then
        return false
    end

    local success, err = Data._updateField(field, args.target, args.value, args.fromCommand)

    if broadcast ~= false then
        API.request.updatePlayerCache()
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
    elseif field == 'icon' then
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
    elseif field == 'nickname' then
        if not config:isNicknameEnabled() and not fromCommand then
            return false
        end

        API.data.setNickname(target, value and tostring(value) or nil)
    elseif field == 'status' then
        if not config.Commands.Status.Enable and not fromCommand then
            return false
        end

        API.data.setStatus(target, value and tostring(value) or nil)
    end

    return true
end


API.data = Data
return Data
