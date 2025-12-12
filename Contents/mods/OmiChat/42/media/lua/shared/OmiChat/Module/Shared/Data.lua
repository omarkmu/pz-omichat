---Shared API functionality related to handling player data.
---@namespace omichat

---@class(partial) api.shared
local API = require 'OmiChat/Module/Shared/Core'

local IS_CLIENT = not isServer()

local config = API.Configuration
local utils = API.utils
local ModData = ModData
local getPlayerByOnlineID = getPlayerByOnlineID


---@class(partial) api.shared.data
---@field protected _modData ModData? The cached mod data table. This is only present on the server.
local Data = {}

---Contains functions for handling player data.
---On the client, these functions can only retrieve information for online players.
API.data = Data

---The current mod data version.
---@protected
Data._version = 1

---The player cache.
---On the client, this is received from the server on interval and when a player joins.
---@protected
Data._playerCache = utils.cache.player({
    onCreatePlayerData = function(_, player) return Data._createPlayerCacheData(player) end,
}) --[[@as omi.PlayerCache<PlayerCacheData>]]


---Returns the chat icon for a player.
---@param username string The player's username.
---@return string? icon The texture name of the player's icon.
function Data.getChatIcon(username)
    local playerData = Data.getPlayerData(username)
    return playerData and playerData.icon
end

---Gets the currently active roleplay language for a player.
---@param username string The player's username.
---@return string? language The untranslated name of the player's current roleplay language.
function Data.getCurrentLanguage(username)
    local playerData = Data.getPlayerData(username)
    local language = playerData and playerData.currentLanguage
    if language and not API.language.exists(language) then
        return
    end

    return language
end

---Retrieves the name that should be used in chat for a player.
---@param username string The player's username.
---@param chatType omi.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function Data.getNameInChat(username, chatType)
    local player = username and Data.getPlayerInfoByUsername(username)
    if not player then
        return
    end

    return Data.getPlayerNameInChat(player, chatType)
end

---Retrieves the name that should be used in chat for a player, escaped for rich text.
---@param username string The player's username.
---@param chatType omi.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function Data.getNameInChatRichText(username, chatType)
    local name = Data.getNameInChat(username, chatType)
    if name then
        return utils.escapeRichText(name)
    end
end

---Gets the nickname for a player.
---@param username string The player's username.
---@return string? nickname The player's set nickname. If no nickname is set, `nil`.
function Data.getNickname(username)
    local playerData = Data.getPlayerData(username)
    return playerData and playerData.nickname
end

---Gets player data on the client or server.
---On the server, this retrieves information directly from mod data.
---On the client, it returns a player from the cache.
---@param username string The player's username.
---@return (PlayerData | PlayerCacheData)? data The player mod data or cache data.
function Data.getPlayerData(username)
    if IS_CLIENT then
        return Data._playerCache:get(username, false)
    end

    return Data._getPlayerData(username)
end

---Retrieves player information given an online ID.
---@param onlineID integer The online ID of the player.
---@param noUpdate boolean? Flag for whether the cache should not be updated with new data if the player is available.
---@return PlayerCacheData? data Table containing cached player data.
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
---@param noUpdate boolean? Flag for whether the cache should not be updated with new data if the player is available.
---@return PlayerCacheData? data Table containing cached player data.
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
---@param player IsoPlayer | PlayerCacheData The player whose name should be retrieved.
---@param menuType MenuTypeString The menu type to retrieve a name for.
---@return string? name The name to use in chat. This is `nil` if the menu should not be affected or retrieval fails.
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
---@param player IsoPlayer | PlayerCacheData The player whose name should be retrieved.
---@param chatType omi.ChatTypeString The chat type to use in format string interpolation.
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

---Gets substitution tokens to use in interpolation for a player.
---@param player (IsoPlayer | PlayerCacheData)? The player to get tokens for.
---@return table? tokens Tokens containing the username, forename, and surname of the player. If information could not be obtained, `nil`.
function Data.getPlayerSubstitutions(player)
    if player and not player.getUsername then
        ---@cast player PlayerCacheData
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

---Retrieves the name that should be used in the typing indicator for a player.
---If the name should not be affected or retrieving the name fails, this returns `nil`.
---@param player IsoPlayer | PlayerCacheData The player whose name should be retrieved.
---@return string? name The name to use for typing, or `nil` the name should not be displayed or information could not be retrieved.
function Data.getPlayerTypingName(player)
    local format = config.TypingIndicator.NameFormat
    if not player or format == '' then
        return
    end

    local chatName = Data.getPlayerNameInChat(player, 'say')
    local tokens = chatName and Data.getPlayerSubstitutions(player)
    if not chatName or not tokens then
        return
    end

    tokens.name = utils.unescapeRichText(chatName)

    local username = Data._getPlayerUsername(player)
    local result = utils.interpolateNamed('TypingName', format, tokens, username)
    if result == '' then
        return
    end

    return result
end

---Gets the speech color of a player.
---@param username string The player's username.
---@return omi.ColorTable<integer>? speechColor The player's speech color. If the color is unset, `nil`.
function Data.getSpeechColor(username)
    local player = username and Data.getPlayerInfoByUsername(username)
    local speechColor = player and player.speechColor

    if speechColor then
        return utils.color.copy(speechColor)
    end
end

---Gets the status for a player.
---@param username string The player's username.
---@return string? status The player's status. If the status is unset, `nil`.
function Data.getStatus(username)
    local playerData = Data.getPlayerData(username)
    return playerData and playerData.status
end

---Returns an iterator over the player cache.
---@return fun(): string?, PlayerCacheData?
function Data.iteratePlayerCache()
    return Data._playerCache:iterate()
end

---Clears the player cache then populates it with the data from the given list.
---@param items PlayerCacheData[]? The new cache items.
function Data.setPlayerCache(items)
    Data._playerCache:fromList(items or {})
end


---Creates player cache data given a player object.
---@param player IsoPlayer
---@return PlayerCacheData
---@protected
function Data._createPlayerCacheData(player)
    local username = player:getUsername()
    if IS_CLIENT then
        local existing = Data._playerCache:get(username, false)
        return existing or Data._playerCache:defaultCreatePlayerData(player)
    end

    local item = Data._playerCache:defaultCreatePlayerData(player) --[[@as PlayerCacheData]]

    local data = Data._getPlayerData(username)
    if not data then
        return item
    end

    utils.extend(item, data)
    item.languages = data.languages and utils.copyList(data.languages)

    return item
end

---Gets or creates the global mod data table for player data.
---This cannot be used on the client.
---@return ModData
---@protected
function Data._get()
    if Data._modData then
        return Data._modData
    end

    if IS_CLIENT then
        error('Data._get cannot be used on the client')
    end

    ---@type ModData
    local modData = ModData.getOrCreate(API._key)

    modData.version = Data._version
    modData.players = modData.players or {}

    Data._modData = modData
    return modData
end

---Gets or creates the player data for a player with the given username.
---This cannot be used on the client.
---@param username string
---@return PlayerData
---@protected
function Data._getOrCreatePlayerData(username)
    local modData = Data._get()

    if not modData.players[username] then
        modData.players[username] = { username = username }
    end

    return modData.players[username]
end

---Gets the player data for a player with the given username. Returns `nil` if no data for the player exists.
---This cannot be used on the client.
---@param username string
---@return PlayerData?
---@protected
function Data._getPlayerData(username)
    local modData = Data._get()
    if not modData.players[username] then
        return
    end

    return modData.players[username]
end

---Gets the username for a player or player cache item.
---@param player IsoPlayer | PlayerCacheData
---@return string
---@protected
function Data._getPlayerUsername(player)
    if player.getUsername then
        ---@cast player IsoPlayer
        return player:getUsername()
    else
        ---@cast player PlayerCacheData
        return player.username
    end
end


return Data

--#region Type Definitions

---@class ModData
---@field version integer The version of the mod data structure.
---@field players table<string, PlayerData> Associates usernames to player mod data.

---@class PlayerData
---@field username string The player's username.
---@field nickname string? The player's chosen nickname to use in chat.
---@field icon string? The name of a texture to display as an icon for the player in chat.
---@field languages string[]? List of the player's known roleplay languages.
---@field languageSlots integer? Total slots that the player has for selecting languages.
---@field currentLanguage string? The player's currently selected roleplay language.
---@field status string? The player's chosen status message.

---@class PlayerCacheData : omi.PlayerCacheData, PlayerData

--#endregion
