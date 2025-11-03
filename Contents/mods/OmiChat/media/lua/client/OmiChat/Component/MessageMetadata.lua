---Helper for accessing and setting metadata about a chat message.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local config = API.Configuration
local getPlayerFaction = Faction.getPlayerFaction


---@class MessageMetadata : omi.Class
---@field message Message The message associated with the metadata.
---@field adminIcon? string The admin icon when this message was sent, if it was enabled.
---@field attractedZombies? boolean Flag for whether the message has already attracted zombies.
---@field narrative? boolean Flag for whether the message was sent with narrative style.
---@field narrativeTag? string The dialogue tag for narrative style.
---@field faction? string The name of the faction to which the message was sent.
---@field overheadAuthor? string The username of the player that should be used for the overhead message.
---@field recipient? string The recipient of a private message.
---@field displayedOverhead? boolean Flag for whether the replacement overhead text has already displayed.
---@field icon? string The user's icon when this message was sent.
---@field language? string The roleplay language in which the message was sent.
---@field languageResult? MessageMetadata.LanguageResult The result of language checking.
---@field mentions? MessageMetadata.Mention[] The results of formatting mentions.
---@field name? string The name of the author when this message was sent.
---@field nameColor? omi.ColorTable<integer> The name color of the author when this message was sent.
---@field rangeResult? MessageMetadata.RangeResult The result of range checking.
---@field recipientNameColor? omi.ColorTable<integer> The name color of the recipient when this message was sent.
---@field stream? string The name of the stream the message was sent over.
---@field echoType? integer The echo type identifier, if this is an echo message.
---@field ctx? table Arbitary context data.
---@field suppressedRadio? boolean Flag for whether the overhead text for this message has already been suppressed on radio.
local MessageMetadata = utils.lib.class()

---Helper for accessing and setting metadata about a chat message.
API.MessageMetadata = MessageMetadata


---Clears the metadata information contained by the object.
function MessageMetadata:clear()
    local message = self.message
    table.wipe(self)
    self.message = message
end

---Decodes metadata encoded in the message's tag.
function MessageMetadata:decode()
    local tag = self.message:getCustomTag()
    if not tag or tag == '' then
        return
    end

    local _, decoded = utils.json.tryDecode(tag)
    if type(decoded) ~= 'table' then
        return
    end

    self:clear()
    for k, v in pairs(decoded) do
        self[k] = v
    end

    self.nameColor = utils.color.fromString(decoded.nameColor)
    self.recipientNameColor = utils.color.fromString(decoded.recipientNameColor)
end

---Encodes initial data into the message.
---
---This encodes information from the message text, as well as
---current information associated with the message author.
---If encoded message data is found, it will be removed from the message text.
function MessageMetadata:encodeInitialData()
    local message = self.message
    local author = message:getAuthor() ---@type string?
    if author == '' then
        author = nil
    end

    local chatType = API.messages.getChatType(message)
    local data = API.messages.decodeData(message)
    local useAdminIcon = data and data.useAdminIcon
    local onlineID = data and data.id

    if not data and chatType == 'radio' then
        local text = message:getText()
        local interference = text:match('<[bfws]zzt>')

        -- if interference mangled the data, throw everything away
        if interference then
            message:setText(interference)
        end
    end

    local player
    if onlineID then
        player = API.data.getPlayerInfoByOnlineID(onlineID)
    elseif author and chatType ~= 'radio' then
        player = API.data.getPlayerInfoByUsername(author)
    end

    local overheadAuthor ---@type string?
    local faction ---@type string?
    if author and chatType == 'radio' then
        -- for radio messages, determine the sender from the encoded data
        if player then
            overheadAuthor = author
            author = player.username
            message:setAuthor(author)
        elseif author == API.player.getUsername() then
            -- if we can't find the author, clear instead of attributing to the local player
            author = nil
            message:setAuthor('')
        end
    elseif chatType == 'faction' then
        if player then
            faction = player.faction
        elseif author then
            local factionObj = getPlayerFaction(author)
            faction = factionObj and factionObj:getName()
        end
    end

    local color = author and API.data.getSpeechColor(author)
    local encoded = utils.json.tryEncode {
        language = data and data.language,
        stream = data and data.stream,
        echoType = data and data.echoType,
        ctx = data and data.ctx,
        name = author and API.data.getNameInChat(author, chatType),
        nameColor = color and utils.color.toHexString(color) or nil,
        icon = author and API.data.getChatIcon(author) or nil,
        adminIcon = useAdminIcon and config.General.AdminIcon or nil,
        narrative = data and data.useNarrative or nil,
        faction = faction,
        overheadAuthor = overheadAuthor,
    }

    message:setCustomTag(encoded or '')
    self:decode()
end

---Gets the chat stream matching the encoded stream ID.
---@return ChatStream? stream
function MessageMetadata:getStream()
    local name = self.stream
    return name and API.streams.getChatStream(name)
end

---Checks whether the metadata object is empty.
---@return boolean empty
function MessageMetadata:isEmpty()
    for k in pairs(self) do
        if k ~= 'message' then
            return false
        end
    end

    return true
end

---Sets an arbitrary key in the message's metadata.
---@param key string
---@param value any
---@return boolean success
function MessageMetadata:set(key, value)
    local tag = self.message:getCustomTag()

    local success, newTag = utils.json.tryDecode(tag)
    if not success or type(newTag) ~= 'table' then
        newTag = {}
    end

    newTag[key] = value
    local encodedTag = utils.json.tryEncode(newTag)
    if not encodedTag then
        -- other data may be bad; throw it out and re-encode
        encodedTag = utils.json.tryEncode({ key = value })
    end

    -- if the value is bad, set the original tag
    self.message:setCustomTag(encodedTag or tag)

    -- update fields
    self:decode()

    return encodedTag ~= nil
end

---Sets a flag indicating that the message was already displayed in a speech bubble.
function MessageMetadata:setDisplayedOverhead()
    self:set('displayedOverhead', true)
end

---Sets the language.
---@param language string The name of the roleplay language to use for the message.
---@return boolean success
function MessageMetadata:setLanguage(language)
    return self:set('language', language)
end

---Sets a value to indicate the result of language checking.
---@param result MessageMetadata.LanguageResult
---@return boolean success
function MessageMetadata:setLanguageResult(result)
    return self:set('languageResult', result)
end

---Sets the results of formatting mentions in the message.
---@param mentions MessageMetadata.Mention[]
---@return boolean success
function MessageMetadata:setMentions(mentions)
    return self:set('mentions', mentions)
end

---Sets the color to use for the author name.
---@param color omi.ColorTable<integer>
---@return boolean success
function MessageMetadata:setNameColor(color)
    return self:set('nameColor', utils.color.toHexString(color))
end

---Sets the dialogue tag to use for narrative style.
---@param tag string
function MessageMetadata:setNarrativeTag(tag)
    self:set('narrativeTag', tag)
end

---Sets a value to indicate the result of range checking.
---@param result MessageMetadata.RangeResult
---@return boolean success
function MessageMetadata:setRangeResult(result)
    return self:set('rangeResult', result)
end

---Sets the color to use for the recipient name in the message metadata.
---@param color omi.ColorTable<integer>
---@return boolean success
function MessageMetadata:setRecipientNameColor(color)
    return self:set('recipientNameColor', utils.color.toHexString(color))
end


---Creates a new message metadata object.
---@param message Message The message to create metadata for.
---@return MessageMetadata
function MessageMetadata:new(message)
    local this = setmetatable({}, self) --[[@as MessageMetadata]]

    this.message = message

    this:decode()
    return this
end


return MessageMetadata

--#region Type Definitions

---@class MessageMetadata.Mention
---@field color string The color of the mention text.
---@field name? string The name to display in hover text for the mention.


---@alias MessageMetadata.LanguageResult 'known-language' | 'unknown-language'

---@alias MessageMetadata.RangeResult 'in-range' | 'out-of-range' | 'in-perception-range'

--#endregion
