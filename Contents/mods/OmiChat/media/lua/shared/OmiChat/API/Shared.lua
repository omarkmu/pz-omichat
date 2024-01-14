---Base shared API.

local config = require 'OmiChat/config'
local utils = require 'OmiChat/util'
local Option = require 'OmiChat/Component/Options'
local MetaFormatter = require 'OmiChat/Component/MetaFormatter'


---@class omichat.api.shared
---@field protected _modDataKey string
---@field protected _modDataVersion integer
---@field protected _playerModDataVersion integer
---@field protected _languageInfo omichat.LanguageInfoStore
local OmiChat = {}

OmiChat.Option = Option
OmiChat.MetaFormatter = MetaFormatter
OmiChat.config = config
OmiChat.utils = utils
OmiChat._modDataKey = 'omichat'
OmiChat._modDataVersion = 1
OmiChat._playerModDataVersion = 1


---Returns the admin chat icon for a given username.
---@param username string
---@return string?
function OmiChat.getAdminChatIcon(username)
    if not username then
        return
    end

    local tokens = {
        username = username,
    }

    return utils.interpolate(Option.FormatAdminIcon, tokens, username)
end

---Returns the chat icon for a given username.
---@param username string
---@return string?
function OmiChat.getChatIcon(username)
    return OmiChat.getModData().icons[username]
end

---Gets or creates the global mod data table.
---@return omichat.ModData
function OmiChat.getModData()
    ---@type omichat.ModData
    local modData = ModData.getOrCreate(OmiChat._modDataKey)

    modData.version = OmiChat._modDataVersion
    modData.nicknames = modData.nicknames or {}
    modData.nameColors = modData.nameColors or {}
    modData.languages = modData.languages or {}
    modData.languageSlots = modData.languageSlots or {}
    modData.currentLanguage = modData.currentLanguage or {}
    modData.icons = modData.icons or {}

    return modData
end

---Returns the color table for a user's name color, or `nil` if unset.
---@param username string
---@return omichat.ColorTable?
function OmiChat.getNameColor(username)
    if not Option.EnableSetNameColor or not username then
        return
    end

    return utils.stringToColor(OmiChat.getModData().nameColors[username])
end

---Returns the color table used for a user's name color in chat, or `nil` if unset.
---This respects the `EnableSpeechColorAsDefaultNameColor` option.
---@param username string
---@return omichat.ColorTable?
function OmiChat.getNameColorInChat(username)
    local nameColor = OmiChat.getNameColor(username)
    if nameColor then
        return nameColor
    end

    if Option.EnableSpeechColorAsDefaultNameColor then
        return Option:getDefaultColor('name', username)
    end
end

---Retrieves the name that should be used in chat for a given username.
---@param username string
---@param chatType omichat.ChatTypeString The chat type to use in format string interpolation.
---@return string? name The name to use in chat, or `nil` if unable to retrieve information about the user.
function OmiChat.getNameInChat(username, chatType)
    if not username then
        return
    end

    local player = utils.getPlayerByUsername(username)
    local tokens = player and OmiChat.getPlayerSubstitutions(player)
    if not tokens then
        return
    end

    local modData = OmiChat.getModData()
    if modData.nicknames[username] then
        tokens.name = utils.escapeRichText(modData.nicknames[username])
    end

    tokens.username = username
    tokens.chatType = chatType
    return utils.interpolate(Option.FormatName, tokens, username)
end

---Gets substitution tokens to use in interpolation for a given player.
---If the player descriptor could not be obtained, returns `nil`.
---@param player IsoPlayer?
---@return table?
function OmiChat.getPlayerSubstitutions(player)
    local desc = player and player:getDescriptor()
    if not player or not desc then
        return
    end

    return {
        forename = desc:getForename(),
        surname = desc:getSurname(),
        username = player:getUsername(),
    }
end

---Returns true if the custom chat stream specified is enabled.
---@param name omichat.CustomStreamName
---@return boolean
function OmiChat.isCustomStreamEnabled(name)
    local info = config:getCustomStreamInfo(name)
    if not info then
        return false
    end

    local value = Option[info.chatFormatOpt]
    return value and value ~= ''
end

---Adds a function that should be available to all interpolator patterns.
---@param name string
---@param func function
function OmiChat.registerInterpolatorFunction(name, func)
    ---@diagnostic disable-next-line: invisible
    utils.Interpolator._registeredFunctions[name:lower()] = func
end


return OmiChat
