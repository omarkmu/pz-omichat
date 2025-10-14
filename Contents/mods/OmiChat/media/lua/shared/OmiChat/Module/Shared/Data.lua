---Shared API functionality related to handling player data.

local API = require 'OmiChat/Module/Shared/Core' ---@class omichat.api.shared

local IS_CLIENT = isClient()

local config = API.Configuration
local utils = API.utils
local ModData = ModData


---@class omichat.api.shared.data
local Data = {}
Data._version = 1
Data._playerCache = utils.lib.cache.player({
    onCreatePlayerData = function(_, player) return Data._createPlayerCacheData(player) end,
})



---Returns the chat icon for a given username.
---@param username string
---@return string?
function Data.getChatIcon(username)
    local playerData = Data.getPlayerData(username)
    return playerData and playerData.icon
end

---Gets the currently active roleplay language for the player with the given username.
---@param username string
---@return string?
function Data.getCurrentLanguage(username)
    local playerData = Data.getPlayerData(username)
    local language = playerData and playerData.currentLanguage
    if language and not API.language.exists(language) then
        return
    end

    return language
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
    local playerData = Data.getPlayerData(username)
    return playerData and playerData.nickname
end

---Gets player data on the client or server.
---On the server, this retrieves information from mod data.
---On the client, it returns a player from the cache.
---@param username string
---@return omichat.PlayerModData?
function Data.getPlayerData(username)
    if IS_CLIENT then
        return Data._playerCache:get(username, false)
    end

    return Data._getPlayerData(username)
end

---Retrieves player information given an online ID.
---@param onlineID number The online ID of the player.
---@param noUpdate boolean? If `true`, the cache won't be updated with new data if the player is available.
---@return omichat.PlayerCacheData?
function Data.getPlayerInfoByOnlineID(onlineID, noUpdate)
    if not noUpdate then
        local player = getPlayerByOnlineID(onlineID)
        if player then
            return Data._playerCache:updatePlayer(player)
        end
    end

    return Data._playerCache:getByIndex('onlineID', onlineID, not noUpdate)
end

---Retrieves player information given a username.
---@param username string The username of the player.
---@param noUpdate boolean? If `true`, the cache won't be updated with new data if the player is available.
---@return omichat.PlayerCacheData?
function Data.getPlayerInfoByUsername(username, noUpdate)
    if not noUpdate then
        local player = utils.getPlayerByUsername(username)
        if player then
            return Data._playerCache:updatePlayer(player)
        end
    end

    return Data._playerCache:get(username, not noUpdate)
end

---Retrieves the name that should be used in chat for the given menu type.
---If the menu name should not be affected or retrieving the name fails, this returns `nil`.
---@param player IsoPlayer | omichat.PlayerCacheData
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

    local result = utils.interpolateNamed('MenuName', nameFormat, tokens, Data._getPlayerUsername(player))
    if result == '' then
        return
    end

    return result
end

---Retrieves the name that should be used in chat for a given player.
---@param player IsoPlayer | omichat.PlayerCacheData
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function Data.getPlayerNameInChat(player, chatType)
    local tokens = player and Data.getPlayerSubstitutions(player)
    if not tokens then
        return
    end

    local username = Data._getPlayerUsername(player)

    tokens.name = Data.getNickname(username)
    tokens.username = username
    tokens.chatType = chatType
    return utils.interpolateNamed('Name', config.Format.Component.Name, tokens, username)
end

---Gets substitution tokens to use in interpolation for a given player.
---If the player information could not be obtained, returns `nil`.
---@param player (IsoPlayer | omichat.PlayerCacheData)?
---@return table?
function Data.getPlayerSubstitutions(player)
    if player and not player.getUsername then
        ---@cast player omichat.PlayerCacheData
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
    local playerData = Data.getPlayerData(username)
    return playerData and playerData.status
end

---Returns an iterator over the player cache.
---@return fun(): string?, omichat.PlayerCacheData?
function Data.iteratePlayerCache()
    return Data._playerCache:iterate()
end

---Resets the player cache with the data from the given list.
---@param items omichat.PlayerCacheData[]?
function Data.setPlayerCache(items)
    Data._playerCache:fromList(items or {})
end


---Creates player cache data given a player object.
---@param player IsoPlayer
---@return omichat.PlayerCacheData
---@protected
function Data._createPlayerCacheData(player)
    local username = player:getUsername()
    if IS_CLIENT then
        local existing = Data._playerCache:get(username, false)
        return existing or Data._playerCache:defaultCreatePlayerData(player)
    end

    local item = Data._playerCache:defaultCreatePlayerData(player) --[[@as omichat.PlayerCacheData]]

    local data = Data._getPlayerData(username)
    if not data then
        return item
    end

    for k, v in pairs(data) do
        item[k] = v
    end

    item.languages = data.languages and utils.copyList(data.languages)
    return item
end

---Gets or creates the global mod data table for player data.
---This should only be used on the server.
---@return omichat.ModData
---@protected
function Data._get()
    if Data._modData then
        return Data._modData
    end

    if IS_CLIENT then
        error('Data.get cannot be used on the client')
    end

    ---@type omichat.ModData
    local modData = ModData.getOrCreate(API._key)

    modData.version = Data._version
    modData.players = modData.players or {}

    Data._modData = modData
    return modData
end

---Gets or creates the player data for a player with the given username.
---This should only be used on the server.
---@param username string
---@return omichat.PlayerModData
---@protected
function Data._getOrCreatePlayerData(username)
    local modData = Data._get()

    if not modData.players[username] then
        modData.players[username] = { username = username }
    end

    return modData.players[username]
end

---Gets the player data for a player with the given username. Returns `nil` if no data for the player exists.
---This should only be used on the server.
---@param username string
---@return omichat.PlayerModData?
---@protected
function Data._getPlayerData(username)
    local modData = Data._get()
    if not modData.players[username] then
        return
    end

    return modData.players[username]
end

---Gets the username for a player or player cache item.
---@param player IsoPlayer | omichat.PlayerCacheData
---@return string
---@protected
function Data._getPlayerUsername(player)
    if player.getUsername then
        ---@cast player IsoPlayer
        return player:getUsername()
    else
        ---@cast player omichat.PlayerCacheData
        return player.username
    end
end



API.data = Data
return Data
