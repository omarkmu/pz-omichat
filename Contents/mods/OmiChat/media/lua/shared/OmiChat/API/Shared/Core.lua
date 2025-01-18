---Base shared API.

local config = require 'OmiChat/Component/Configuration'
local utils = require 'OmiChat/utils'
local MetaFormatter = require 'OmiChat/Component/MetaFormatter'


---@class omichat.api.shared
---@field protected _modDataKey string
---@field protected _modDataVersion integer
---@field protected _playerModDataVersion integer
local API = {}

API.Configuration = config
API.MetaFormatter = MetaFormatter
API.utils = utils
API._modDataKey = 'omichat'
API._modDataVersion = 1
API._playerModDataVersion = 1


local modDataFields = {
    { key = 'nicknames', name = 'nickname' },
    { key = 'icons', name = 'icon' },
    { key = 'currentLanguage', name = 'currentLanguage' },
    { key = 'languageSlots', name = 'languageSlots' },
    { key = 'languages', name = 'languages' },
}

local modDataKeys = { 'username' }
for i = 1, #modDataFields do
    modDataKeys[#modDataKeys + 1] = modDataFields[i].name
end

---Gets the username for a player or player cache item.
---@param player IsoPlayer | omichat.utils.PlayerCacheItem
---@return string?
local function getPlayerUsername(player)
    if player.getUsername then
        ---@cast player IsoPlayer
        return player:getUsername()
    else
        ---@cast player omichat.utils.PlayerCacheItem
        return player.username
    end
end


---Clears mod data for a given username.
---@param username string
---@protected
function API._clearModData(username)
    local modData = API.getModData()

    modData.currentLanguage[username] = nil
    modData.icons[username] = nil
    modData.languageSlots[username] = nil
    modData.languages[username] = nil
    modData.nicknames[username] = nil
end


---Returns the chat icon for a given username.
---@param username string
---@return string?
function API.getChatIcon(username)
    return API.getModData().icons[username]
end

---Gets or creates the global mod data table.
---@return omichat.ModData
function API.getModData()
    ---@type omichat.ModData
    local modData = ModData.getOrCreate(API._modDataKey)

    modData.version = API._modDataVersion
    modData.nicknames = modData.nicknames or {}
    modData.languages = modData.languages or {}
    modData.languageSlots = modData.languageSlots or {}
    modData.currentLanguage = modData.currentLanguage or {}
    modData.icons = modData.icons or {}

    return modData
end

---Gets the global mod data as a list associated with usernames.
---@return omichat.UserModData[] data
---@return string[] fieldList
function API.getModDataList()
    local list = {}
    local map = {}
    local modData = API.getModData()

    for _, field in pairs(modDataFields) do
        local key, fieldName
        if type(field) == 'string' then
            key = field
            fieldName = field
        else
            key = field.key
            fieldName = field.name
        end

        for username, v in pairs(modData[key]) do
            if not map[username] then
                local userData = { username = username }
                list[#list + 1] = userData
                map[username] = userData
            end

            map[username][fieldName] = v
        end
    end

    return list, utils.copy(modDataKeys)
end

---Retrieves the name that should be used in chat for a given username.
---@param username string?
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function API.getNameInChat(username, chatType)
    if not username then
        return
    end

    local player = utils.getPlayerInfoByUsername(username)
    if not player then
        return
    end

    return API.getPlayerNameInChat(player, chatType)
end

---Retrieves the name that should be used in chat for a given username, escaped for rich text.
---@param username string?
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function API.getNameInChatRichText(username, chatType)
    local name = API.getNameInChat(username, chatType)
    if name then
        return utils.escapeRichText(name)
    end
end

---Retrieves the name that should be used in chat for the given menu type.
---If the menu name should not be affected or retrieving the name fails, this returns `nil`.
---@param player IsoPlayer | omichat.utils.PlayerCacheItem
---@param menuType omichat.MenuTypeString
---@return string?
function API.getPlayerMenuName(player, menuType)
    if not player then
        return
    end

    local nameFormat = config:getMenuNameFormat(menuType)
    if not nameFormat or nameFormat == '' then
        return
    end

    local chatName = API.getPlayerNameInChat(player, 'say')
    local tokens = chatName and API.getPlayerSubstitutions(player)
    if not chatName or not tokens then
        return
    end

    tokens.name = API.utils.unescapeRichText(chatName)
    tokens.menuType = menuType

    local result = API.utils.interpolate(nameFormat, tokens, getPlayerUsername(player))
    if result == '' then
        return
    end

    return result
end

---Retrieves the name that should be used in chat for a given player.
---@param player IsoPlayer | omichat.utils.PlayerCacheItem
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the player.
function API.getPlayerNameInChat(player, chatType)
    local tokens = player and API.getPlayerSubstitutions(player)
    if not tokens then
        return
    end

    local username = getPlayerUsername(player)

    local modData = API.getModData()
    if modData.nicknames[username] then
        tokens.name = modData.nicknames[username]
    end

    tokens.username = username
    tokens.chatType = chatType
    return utils.interpolate(config.Format.Component.Name, tokens, username)
end

---Gets substitution tokens to use in interpolation for a given player.
---If the player descriptor could not be obtained, returns `nil`.
---@param player (IsoPlayer | omichat.utils.PlayerCacheItem)?
---@return table?
function API.getPlayerSubstitutions(player)
    if player and not player.getUsername then
        ---@cast player omichat.utils.PlayerCacheItem
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
function API.getSpeechColor(username)
    local player = username and utils.getPlayerInfoByUsername(username)
    local speechColor = player and player.speechColor

    if speechColor then
        return utils.color.copy(speechColor)
    end
end

---Retrieves mod data for a given user.
---@param username string
---@return omichat.UserModData
function API.getUserModData(username)
    local data = { username = username }
    local modData = API.getModData()

    for _, field in pairs(modDataFields) do
        data[field.name] = modData[field.key][username]
    end

    return data
end

---Adds a function that should be available to all interpolator patterns.
---@param name string
---@param func function
function API.registerInterpolatorFunction(name, func)
    ---@diagnostic disable-next-line: invisible
    utils.Interpolator._registeredFunctions[name] = func
end


return API
