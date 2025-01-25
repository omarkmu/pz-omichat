---Shared API functionality related to handling player data.

local API = require 'OmiChat/Module/Shared/Core' ---@class omichat.api.shared

local config = API.Configuration
local utils = API.utils
local ModData = ModData


---@class omichat.api.shared.data
local Data = {}
Data._version = 1
Data._playerVersion = 1
Data._playerCacheByUsername = {}
Data._playerCacheByOnlineID = {}

local dataFields = {
    { key = 'nicknames', name = 'nickname' },
    { key = 'statuses', name = 'status' },
    { key = 'icons', name = 'icon' },
    { key = 'currentLanguage', name = 'currentLanguage' },
    { key = 'languageSlots', name = 'languageSlots' },
    { key = 'languages', name = 'languages' },
}

local dataKeys = { 'username' }
for i = 1, #dataFields do
    dataKeys[#dataKeys + 1] = dataFields[i].name
end


---Clears mod data for a given username.
---@param username string
function Data.clear(username)
    local modData = Data.get()

    for _, field in pairs(dataFields) do
        modData[field.key][username] = nil
    end
end

---Gets or creates the global mod data table.
---@return omichat.ModData
function Data.get()
    ---@type omichat.ModData
    local modData = ModData.getOrCreate(API._key)

    modData.version = Data._version
    for _, field in pairs(dataFields) do
        modData[field.key] = modData[field.key] or {}
    end

    return modData
end

---Returns the chat icon for a given username.
---@param username string
---@return string?
function Data.getChatIcon(username)
    return Data.get().icons[username]
end

---Gets the currently active roleplay language for the player with the given username.
---@param username string
---@return string?
function Data.getCurrentLanguage(username)
    local modData = API.data.get()
    local language = modData.currentLanguage[username]
    if language and not API.language.exists(language) then
        return
    end

    return language
end

---Gets the global mod data as a list associated with usernames.
---@return omichat.PlayerModData[] data
---@return string[] fieldList
function Data.getList()
    local list = {}
    local map = {}
    local modData = Data.get()

    for _, field in pairs(dataFields) do
        local key = field.key
        local fieldName = field.name

        for username, v in pairs(modData[key]) do
            if not map[username] then
                local userData = { username = username }
                list[#list + 1] = userData
                map[username] = userData
            end

            map[username][fieldName] = v
        end
    end

    return list, utils.copyList(dataKeys)
end

---Retrieves the name that should be used in chat for a given username.
---@param username string?
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function Data.getNameInChat(username, chatType)
    if not username then
        return
    end

    local player = Data.getPlayerInfoByUsername(username)
    if not player then
        return
    end

    return Data.getPlayerNameInChat(player, chatType)
end

---Retrieves the name that should be used in chat for a given username, escaped for rich text.
---@param username string?
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function Data.getNameInChatRichText(username, chatType)
    local name = Data.getNameInChat(username, chatType)
    if name then
        return utils.escapeRichText(name)
    end
end

---Gets the nickname for the player with the given username.
---If no nickname is set for the given username, returns `nil`.
---@param username string
---@return string?
function Data.getNickname(username)
    return Data.get().nicknames[username]
end

---Retrieves player information given an online ID.
---@param onlineID number
---@return omichat.PlayerCacheItem?
function Data.getPlayerInfoByOnlineID(onlineID)
    local found = getPlayerByOnlineID(onlineID)
    if found then
        return Data._updateCacheWithPlayer(found)
    end

    return Data._playerCacheByOnlineID[onlineID]
end

---Retrieves player information given a username.
---@param username string
---@return omichat.PlayerCacheItem?
function Data.getPlayerInfoByUsername(username)
    local found = utils.getPlayerByUsername(username)
    if found then
        return Data._updateCacheWithPlayer(found)
    end

    return Data._playerCacheByUsername[username]
end

---Retrieves the name that should be used in chat for the given menu type.
---If the menu name should not be affected or retrieving the name fails, this returns `nil`.
---@param player IsoPlayer | omichat.PlayerCacheItem
---@param menuType omichat.MenuTypeString
---@return string?
function Data.getPlayerMenuName(player, menuType)
    if not player then
        return
    end

    local nameFormat = config:getMenuNameFormat(menuType)
    if not nameFormat or nameFormat == '' then
        return
    end

    local chatName = Data.getPlayerNameInChat(player, 'say')
    local tokens = chatName and Data.getPlayerSubstitutions(player)
    if not chatName or not tokens then
        return
    end

    tokens.name = utils.unescapeRichText(chatName)
    tokens.menuType = menuType

    local result = utils.interpolate(nameFormat, tokens, Data._getPlayerUsername(player))
    if result == '' then
        return
    end

    return result
end

---Retrieves the name that should be used in chat for a given player.
---@param player IsoPlayer | omichat.PlayerCacheItem
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function Data.getPlayerNameInChat(player, chatType)
    local tokens = player and Data.getPlayerSubstitutions(player)
    if not tokens then
        return
    end

    local username = Data._getPlayerUsername(player)

    local modData = Data.get()
    if modData.nicknames[username] then
        tokens.name = modData.nicknames[username]
    end

    tokens.username = username
    tokens.chatType = chatType
    return utils.interpolate(config.Format.Component.Name, tokens, username)
end

---Gets substitution tokens to use in interpolation for a given player.
---If the player information could not be obtained, returns `nil`.
---@param player (IsoPlayer | omichat.PlayerCacheItem)?
---@return table?
function Data.getPlayerSubstitutions(player)
    if player and not player.getUsername then
        ---@cast player omichat.PlayerCacheItem
        return {
            forename = utils.trim(player.forename),
            surname = utils.trim(player.surname),
            username = player.username,
        }
    end

    ---@cast player IsoPlayer
    local desc = player and player:getDescriptor()
    if not player or not desc then
        return
    end

    return {
        forename = utils.trim(desc:getForename()),
        surname = utils.trim(desc:getSurname()),
        username = player:getUsername(),
    }
end

---Gets the speech color of the player with the given username, or `nil` if unset.
---@param username string
---@return omi.ColorTable?
function Data.getSpeechColor(username)
    local player = username and Data.getPlayerInfoByUsername(username)
    local speechColor = player and player.speechColor

    if speechColor then
        return utils.color.copy(speechColor)
    end
end

---Gets the status for the player with the given username, or `nil` if unset.
---@param username string
---@return string?
function Data.getStatus(username)
    return Data.get().statuses[username]
end

---Retrieves mod data for a given player.
---@param username string
---@return omichat.PlayerModData
function Data.getPlayerModData(username)
    local modData = Data.get()

    local data = { username = username }
    for _, field in pairs(dataFields) do
        data[field.name] = modData[field.key][username]
    end

    return data
end

---Returns an iterator over the player cache.
---@return function
---@return table<string, omichat.PlayerCacheItem>
function Data.iteratePlayerCache()
    return pairs(Data._playerCacheByUsername)
end

---Refreshes roleplay language information for the given username.
---@param username string
function Data.refreshLanguageInfo(username)
    local modData = API.data.get()
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
        if API.language.exists(lang) then
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

---Resets the player cache.
---@param items omichat.PlayerCacheItem[]
function Data.resetPlayerCache(items)
    items = items or {}

    local byUsername = {}
    local byOnlineID = {}
    for i = 1, #items do
        local item = items[i]
        byUsername[item.username] = item
        byOnlineID[item.onlineID] = item
    end

    Data._playerCacheByUsername = byUsername
    Data._playerCacheByOnlineID = byOnlineID
end

---Sets the mod data for the given username.
---@param username string
---@param data omichat.PlayerModData?
function Data.set(username, data)
    local modData = Data.get()

    data = data or {}
    for _, field in pairs(dataFields) do
        modData[field.key][username] = data[field.name]
    end
end


---Creates a cache item for the given player.
---@param player IsoPlayer
---@return omichat.PlayerCacheItem
---@protected
function Data._buildPlayerCacheItem(player)
    local desc = player:getDescriptor()

    local speechColor
    local color = player:getSpeakColour()
    if color then
        speechColor = {
            r = color:getRed(),
            g = color:getGreen(),
            b = color:getBlue(),
        }
    else
        speechColor = { r = 255, g = 255, b = 255 }
    end

    ---@type omichat.PlayerCacheItem
    local item = {
        username = player:getUsername(),
        forename = desc:getForename(),
        surname = desc:getSurname(),
        onlineID = player:getOnlineID(),
        speechColor = speechColor,
    }

    return item
end

---Gets the username for a player or player cache item.
---@param player IsoPlayer | omichat.PlayerCacheItem
---@return string?
---@protected
function Data._getPlayerUsername(player)
    if player.getUsername then
        ---@cast player IsoPlayer
        return player:getUsername()
    else
        ---@cast player omichat.PlayerCacheItem
        return player.username
    end
end

---Updates the cache with the player's information.
---@param player IsoPlayer
---@return omichat.PlayerCacheItem
---@protected
function Data._updateCacheWithPlayer(player)
    local item = Data._buildPlayerCacheItem(player)

    Data._playerCacheByUsername[item.username] = item
    Data._playerCacheByOnlineID[item.onlineID] = item
    return item
end



API.data = Data
return Data
