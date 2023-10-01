local utils = require 'OmiChat/util'
local Option = require 'OmiChat/Options'
local MetaFormatter = require 'OmiChat/MetaFormatter'
local customStreamData = require 'OmiChat/CustomStreamData'


---Provides client and server API access to OmiChat.
---@class omichat.api.shared
---@field protected modDataKey string
---@field protected modDataVersion integer
local OmiChat = {}

OmiChat.modDataVersion = 1
OmiChat.modDataKey = 'omichat'
OmiChat.utils = utils
OmiChat.Option = Option
OmiChat.MetaFormatter = MetaFormatter


---Event handler for retrieving global mod data.
---@param key string
---@param newData omichat.ModData
---@protected
function OmiChat._onReceiveGlobalModData(key, newData)
    if key ~= OmiChat.modDataKey or type(newData) ~= 'table' then
        return
    end

    local modData = OmiChat.getModData()

    if isClient() then
        modData.nicknames = newData.nicknames
        modData.nameColors = newData.nameColors
    elseif newData._updates then
        local user = newData._updates.nicknameToUpdate
        if user and Option.EnableSetName then
            modData.nicknames[user] = newData.nicknames[user]
        end

        user = newData._updates.nicknameToClear
        if user then
            modData.nicknames[user] = nil
        end

        user = newData._updates.nameColorToUpdate
        if user and Option.EnableSetNameColor then
            modData.nameColors[user] = newData.nameColors[user]
        end
    end

    modData._updates = nil

    if isServer() then
        ModData.transmit(OmiChat.modDataKey)
    end
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

---Gets or creates the global mod data table.
---@return omichat.ModData
function OmiChat.getModData()
    ---@type omichat.ModData
    local modData = ModData.getOrCreate(OmiChat.modDataKey)

    modData.version = OmiChat.modDataVersion
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
    if Option.EnableSetName and modData.nicknames[username] then
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

---Adds a function that should be available to all interpolator patterns.
---@param name string
---@param func function
function OmiChat.registerInterpolatorFunction(name, func)
    ---@diagnostic disable-next-line: invisible
    utils.Interpolator._registeredFunctions[name:lower()] = func
end

---Returns true if the custom chat stream specified is enabled.
---@param name omichat.CustomStreamName
---@return boolean
function OmiChat.isCustomStreamEnabled(name)
    local opts = customStreamData[name]
    if not opts then
        return false
    end

    local value = Option[opts.chatFormatOpt]
    return value and value ~= ''
end


--#region Types

---Chat types.
---@alias omichat.ChatTypeString
---| 'general'
---| 'whisper'
---| 'say'
---| 'shout'
---| 'faction'
---| 'safehouse'
---| 'radio'
---| 'admin'
---| 'server'

---A table containing color values in [0, 255].
---@class omichat.ColorTable
---@field r integer
---@field g integer
---@field b integer

---Updates to mod data.
---@class omichat.ModDataUpdates
---@field nicknameToClear unknown?
---@field nicknameToUpdate unknown?
---@field nameColorToUpdate unknown?

---Mod data fields.
---@class omichat.ModData
---@field version integer
---@field nicknames table<string, string>
---@field nameColors table<string, string>
---@field _updates omichat.ModDataUpdates?

--#endregion


Events.OnReceiveGlobalModData.Add(OmiChat._onReceiveGlobalModData)

return OmiChat
