---Server API functionality related to handling player data.

if not isServer() then return end


---@class omichat.api.server
local OmiChat = require 'OmiChat/API/Server'


---Clears all player nicknames.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
function OmiChat.clearNicknames()
    local modData = OmiChat.getModData()
    modData.nicknames = {}
end

---Gets the nickname for the player with the given username.
---If no nickname is set for the given username, returns `nil`.
---@param username string
---@return string?
function OmiChat.getNickname(username)
    local modData = OmiChat.getModData()
    return modData.nicknames[username]
end

---Sets the name color for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param color string? The color to use, in hex format.
function OmiChat.setNameColorString(username, color)
    local modData = OmiChat.getModData()
    modData.nameColors[username] = color
end

---Sets the nickname for the player with the given username.
---This does not transmit changes to clients.
---@see omichat.api.server.transmitModData
---@param username string
---@param nickname string?
function OmiChat.setNickname(username, nickname)
    local modData = OmiChat.getModData()
    modData.nicknames[username] = nickname
end

---Transmits mod data to clients.
function OmiChat.transmitModData()
    OmiChat.getModData()
    ModData.transmit(OmiChat._modDataKey)
end
