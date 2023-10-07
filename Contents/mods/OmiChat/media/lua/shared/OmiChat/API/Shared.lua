local utils = require 'OmiChat/util'
local Option = require 'OmiChat/Options'
local MetaFormatter = require 'OmiChat/MetaFormatter'
local customStreamData = require 'OmiChat/CustomStreamData'


---@class omichat.api.shared
---@field protected _modDataKey string
---@field protected _modDataVersion integer
local OmiChat = {}

OmiChat.Option = Option
OmiChat.MetaFormatter = MetaFormatter
OmiChat.utils = utils
OmiChat._modDataKey = 'omichat'
OmiChat._modDataVersion = 1


---Gets or creates the global mod data table.
---@return omichat.ModData
function OmiChat.getModData()
    ---@type omichat.ModData
    local modData = ModData.getOrCreate(OmiChat._modDataKey)

    modData.version = OmiChat._modDataVersion
    modData.nicknames = modData.nicknames or {}
    modData.nameColors = modData.nameColors or {}

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

---Returns the color table used for a user's name color in chat, or nil if unset.
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

    local modData = OmiChat.getModData()
    if modData.nicknames[username] then
        return utils.escapeRichText(modData.nicknames[username])
    end

    local tokens = OmiChat.getPlayerSubstitutions(getPlayerFromUsername(username))
    if not tokens then
        return
    end

    tokens.username = username
    tokens.chatType = chatType
    return utils.interpolate(Option.FormatName, tokens)
end

---Gets substitution tokens to use in interpolation for a given player.
---If the player descriptor could not be obtained, returns `nil`.
---@param player IsoPlayer
---@return table?
function OmiChat.getPlayerSubstitutions(player)
    local desc = player and player:getDescriptor()
    if not desc then
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
    local opts = customStreamData.table[name]
    if not opts then
        return false
    end

    local value = Option[opts.chatFormatOpt]
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
