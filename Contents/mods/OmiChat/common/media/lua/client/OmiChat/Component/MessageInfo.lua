---Helper for building information about a chat message.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'
local Metadata = require 'OmiChat/Component/MessageMetadata'

local utils = API.utils
local config = API.Configuration
local MimicMessage = API.MimicMessage
local MultiMap = utils.MultiMap
local ISChat = ISChat --[[@as omichat.ISChat]]

local format = string.format
local getTexture = getTexture
local getTextVanilla = getText


---@class MessageInfo : omi.Class
---@field message Message The message object.
---@field tokens table<string, any> Token substitution values.
---@field chatText string The message content to display in chat.
---@field overheadText string The text to display in the overhead speech bubble.
---@field hidden boolean Flag for whether the message has been hidden both in chat and overhead.
---@field meta MessageMetadata Metadata attached to the message.
---@field parsed ParsedMessage The parsed message information.
---@field chatType omi.ChatTypeString The chat type of the message's chat.
---@field overheadFormat? string The format string to use for the overhead speech bubble.
---@field chatFormat? string The format string to use for the chat message.
---@field chatDefault? string The name of the default to use for the `$Default()` function for chat. Defaults to `Chat`.
---@field overheadDefault? string The name of the default to use for the `$Default()` function for the speech bubble. Defaults to `Overhead`.
---@field stream? ChatStream The source stream of the message.
---@field originalStream? ChatStream The original stream of a radio message.
---@field author string The username of the message author.
---@field titleID string The string ID of the chat type's tag.
---@field zombieAttractRange? number The range at which the message will be heard by zombies.
---@field tags omi.SetTable<string> A set of tags to add to the message tokens.
---@field doOverhead boolean Flag for whether overhead text should be built.
---@field datetime string A string representing the date and time the message was sent.
---@field usePerceivedText? boolean Flag for whether the message text should be replaced by the "perception range" text.
---@field useUnknownLanguageText? boolean Flag for whether the message text should be replaced by the unknown language text.
---@field tag? string The result of the `FormatTag` option.
---@field timestamp? string The result of the `FormatTimestamp` option.
---@field language? string The result of the `FormatLanguage` option.
---@field color? omi.ColorTable<integer> The message color.
---@field keepRichText boolean Flag for whether rich text chat content should be maintained, rather than escaped.
---@field private rawText string The raw text of the message.
---@field private rawTextWithPrefix string The raw text of the message, with the prefix.
---@field private showTitle boolean Flag for whether the message will include the chat type tag.
---@field private showTimestamp boolean Flag for whether the message will include a timestamp.
---@field private font ChatFont The font size of the message.
local MessageInfo = utils.class()

---Helper for building information about a chat message.
API.MessageInfo = MessageInfo


local _ChatBase = __classmetatables[ChatBase.class].__index ---@type any
local _ChatMessage = __classmetatables[ChatMessage.class].__index ---@type any

local _getChatTitleID = _ChatBase.getTitleID
local _getTextWithPrefix = _ChatMessage.getTextWithPrefix


---Adds the given tags to the set of tags in the interpolation tokens.
---@param tags string[]
function MessageInfo:addTags(tags)
    for i = 1, #tags do
        self.tags[tags[i]] = true
    end
end

---Applies the formatting determined by building the message.
---
---If the format string or content are unset, the chat text will be set to the empty string.
---Command messages allow empty content since they have no input.
---@private
function MessageInfo:applyChatFormatting()
    self.chatText = utils.trim(self.chatText)
    if not self.tags.IsCommand and self.chatText == '' then
        self:hideInChat()
        return
    end

    if not self.chatFormat or self.chatFormat == '' then
        self.chatText = ''
        return
    end

    local dt = self.datetime
    local chatType = self.chatType
    local seed = dt
    local stream = self.stream

    self:syncTags()

    if self.showTimestamp then
        local hour, minute, second = dt:match('(%d%d):(%d%d):(%d%d)')

        hour = tonumber(hour)
        minute = tonumber(minute)
        second = tonumber(second)

        if hour and minute and second then
            local hour12 = hour % 12
            if hour12 == 0 then
                hour12 = 12
            end

            local prefer24 = getCore():getOptionClock24Hour()
            local prefHour = format('%d', prefer24 and hour or hour12)
            local prefHourPadded = format('%02d', prefer24 and hour or hour12)

            local ampm = hour < 12 and 'am' or 'pm'
            self.timestamp = utils.interpolateNamed('Timestamp', config.Format.Component.Timestamp, {
                chatType = chatType,
                stream = self.tokens.stream,
                P = prefHour,
                PP = prefHourPadded,
                H = format('%d', hour),
                HH = format('%02d', hour),
                h = format('%d', hour12),
                hh = format('%02d', hour12),
                m = format('%d', minute),
                mm = format('%02d', minute),
                s = format('%d', second),
                ss = format('%02d', second),
                ampm = ampm,
                AMPM = ampm:upper(),
                hourFormat = prefer24 and 24 or 12,
                tags = self.tokens.tags,
                originalTags = self.tokens.originalTags,
            }, seed)
        end
    end

    self.language = utils.interpolateNamed('Language', config.Format.Component.Language, {
        chatType = chatType,
        stream = self.tokens.stream,
        languageRaw = self.tokens.languageRaw,
        language = self.tokens.language,
        unknownLanguage = self.tokens.unknownLanguage,
        tags = self.tokens.tags,
        originalTags = self.tokens.originalTags,
    })

    if self.showTitle then
        self.tag = utils.interpolateNamed('Tag', config.Format.Component.Tag, {
            chatType = chatType,
            stream = self.tokens.stream,
            tag = getTextVanilla(self.titleID),
            tags = self.tokens.tags,
            originalTags = self.tokens.originalTags,
        }, seed)
    end

    local icon = utils.interpolateNamed('Icon', config.Format.Component.Icon, {
        chatType = chatType,
        stream = self.tokens.stream,
        icon = self.meta.icon,
        adminIcon = self.meta.adminIcon,
        tags = self.tokens.tags,
        originalTags = self.tokens.originalTags,
    }, seed)

    if icon and getTexture(icon) then
        local size = 14
        if self.font == 'small' then
            size = 12
        elseif self.font == 'large' then
            size = 16
        end

        self.tokens.iconRaw = icon
        self.tokens.icon = format(' <IMAGE:%s,%d,%d> ', icon, size + 1, size)
    end

    if self:shouldUseNameColors() then
        local encodedColor = self.meta.nameColor
        local nameColor = utils.color.default(encodedColor or API.data.getSpeechColor(self.author), 255, 255, 255)
        local nameColorTag = utils.color.toRichText(nameColor, true)

        if nameColorTag ~= '' then
            if not encodedColor then
                self.meta:setNameColor(nameColor)
            end

            self.tokens.name = nameColorTag .. self.tokens.name .. ' <POPRGB> '
            self.tokens.author = nameColorTag .. self.tokens.author .. ' <POPRGB> '
        end

        local recip = self.tokens.recipient
        if recip then
            local encodedRecipColor = self.meta.recipientNameColor
            local recipColor = utils.color.default(encodedRecipColor or API.data.getSpeechColor(recip), 255, 255, 255)

            local recipColorTag = utils.color.toRichText(recipColor, true)

            if recipColorTag ~= '' then
                if not encodedRecipColor then
                    self.meta:setRecipientNameColor(recipColor)
                end

                self.tokens.recipientName = recipColorTag .. self.tokens.recipientName .. ' <POPRGB> '
                self.tokens.recipient = recipColorTag .. recip .. ' <POPRGB> '
            end
        end
    end

    if not self.color then
        local color
        if stream then
            color = API.player.getColorOrDefault(stream:getName())
        end

        self.color = color or self:getOriginalColor()
    end

    return
end

---Gets the message text to use for chat.
---@return string
function MessageInfo:buildChatText()
    local fmt = self.chatFormat
    if not fmt or fmt == '' then
        return self.rawTextWithPrefix
    end

    if not self.tags.IsCommand and self.chatText == '' then
        return self.rawTextWithPrefix
    end

    self.tokens.input = self.chatText
    self:syncTags()

    local seed = self.datetime
    local input = utils.interpolateNamed(self.chatDefault or 'Chat', fmt, self.tokens, seed)
    if input == '' then
        self:hideInChat()
        return self.rawTextWithPrefix
    end

    local tokens = {
        tag = self.tag,
        chatType = self.chatType,
        language = self.language,
        timestamp = self.timestamp,
        admin = self.tokens.admin,
        echo = self.tokens.echo,
        stream = self.tokens.stream,
        icon = self.tokens.icon,
        iconRaw = self.tokens.iconRaw,
        tags = self.tokens.tags,
        originalTags = self.tokens.originalTags,
        input = input,
    }

    tokens.prefix = utils.trim(utils.interpolateNamed('ChatPrefix', config.Format.Chat.Prefix, tokens, seed))

    local color = utils.color.toRichText(self.color)
    local size = ' <SIZE:' .. (self.font or 'medium') .. '> '
    local content = utils.interpolateNamed('ChatFinal', config.Format.Chat.Final, tokens, seed)

    return color .. size .. utils.removeInvisible(content)
end

---Gets the message text to use for the overhead speech bubble.
---@return string?
function MessageInfo:buildOverheadText()
    local tokens = utils.copy(self.tokens)
    local fmt = self.overheadFormat
    if not fmt or fmt == '' then
        return
    end

    local seed = self.datetime
    tokens.input = utils.trim(self.overheadText)
    if not self.tags.IsCommand and tokens.input == '' then
        return
    end

    self:syncTags()

    tokens.input = utils.interpolateNamed(self.overheadDefault or 'Overhead', fmt, tokens, seed)
    if tokens.input == '' then
        return
    end

    local prefixFmt = config.Format.Overhead.Prefix
    tokens.prefix = utils.trimleft(utils.interpolateNamed('OverheadPrefix', prefixFmt, tokens))
    tokens.input = utils.interpolateNamed('OverheadFinal', config.Format.Overhead.Final, tokens, seed)

    return tokens.input
end

---Gets the original text color of the message.
---@return omi.ColorTable<integer>
function MessageInfo:getOriginalColor()
    local textColor = self.message:getTextColor()
    return {
        r = textColor:getRed(),
        g = textColor:getGreen(),
        b = textColor:getBlue(),
    }
end

---Sets the message to not show overhead or in chat.
function MessageInfo:hide()
    self.hidden = true
    self.doOverhead = false
    self.message:setShowInChat(false)
end

---Sets the message to not show in chat.
function MessageInfo:hideInChat()
    self.message:setShowInChat(false)
end

---Updates the stream and associated information to act as if the message was sent on another stream.
---@param stream ChatStream
function MessageInfo:setStream(stream)
    local name = stream:getName()
    self.stream = stream
    self.tokens.stream = name

    local chatType = stream:getChatType()
    if chatType then
        self.chatType = chatType
        self.titleID = API.ui.chatTypeToTitleID(chatType)
    end

    if not self.chatFormat then
        self.chatDefault = nil
        self.chatFormat = stream:getChatFormat()
    end

    if not self.overheadFormat then
        self.overheadDefault = nil
        self.overheadFormat = stream:getOverheadFormat()
    end

    self.color = nil

    local streamTags = stream:getTags()
    for k in pairs(streamTags) do
        self.tags[k] = true
    end
end

---Determines whether a message should attract zombies for a given user.
---@param username string
---@return boolean
function MessageInfo:shouldAttractZombies(username)
    if self.tags.IsCallout or self.tags.IsSneakCallout or self.meta.attractedZombies then
        return false
    end

    local range = self.zombieAttractRange
    if not range or self.author ~= username then
        return false
    end

    return self.message:isShouldAttractZombies()
end

---Returns whether name colors should be used for mentions.
---@return boolean shouldUseMentionColors
function MessageInfo:shouldUseMentionColors()
    if not config.Customization.EnableNameColors then
        return false
    end

    if not API.preferences.getNameColorsEnabled() then
        return false
    end

    if config.Mentions.AlwaysUseNameColors then
        return true
    end

    return not self.stream or self.stream:canUseNameColors()
end

---Returns whether name colors should be used.
---@return boolean shouldUseNameColors
function MessageInfo:shouldUseNameColors()
    if not config.Customization.EnableNameColors then
        return false
    end

    if not API.preferences.getNameColorsEnabled() then
        return false
    end

    return not self.stream or self.stream:canUseNameColors()
end

---Syncs tags between the token table and the cache.
function MessageInfo:syncTags()
    local tagSet
    local existingTags = self.tokens.tags
    if utils.isinstance(existingTags, MultiMap) then
        tagSet = existingTags:toValueSet()
    else
        tagSet = {}
    end

    utils.extend(self.tags, tagSet)
    self.tokens.tags = MultiMap.fromSet(self.tags)
end


---Determines the source stream of a message based on encoded information.
---@param skipRadio boolean?
---@return ChatStream? stream
---@private
function MessageInfo:_getMessageStream(skipRadio)
    if self.chatType == 'server' then
        return API.streams.getServerStream()
    elseif self.chatType == 'radio' and not skipRadio then
        return API.streams.getRadioStream()
    elseif self.message:isFromDiscord() then
        return API.streams.getDiscordStream()
    end

    return self.meta:getStream()
end


---Creates a new message information object.
---@param message Message The message to create an information object for.
---@return MessageInfo info
---@private
function MessageInfo:new(message)
    local this = utils.new(self)
    local instance = ISChat.instance

    this.tokens = {}
    this.meta = Metadata:new(message)
    this.message = message
    this.chatType = API.messages.getChatType(message)
    this.author = message:getAuthor() or ''
    this.datetime = tostring(message:getDatetime())

    this.chatText = ''
    this.overheadText = ''
    this.hidden = false
    this.font = instance and instance.chatFont or 'medium'
    this.showTitle = instance and instance.showTitle or false
    this.showTimestamp = instance and instance.showTimestamp or false
    this.doOverhead = not this.meta.displayedOverhead and message:isOverHeadSpeech()
    if this.doOverhead then
        -- this will be handled during processing
        this.message:setOverHeadSpeech(false)
    end

    this.stream = this:_getMessageStream()
    this.tags = this.stream and this.stream:getTags() or {}

    if this.chatType == 'radio' then
        this.originalStream = this:_getMessageStream(true)
    end

    this.keepRichText = false
    this.rawText = message:getText()
    if utils.isinstance(message, MimicMessage) then
        this.keepRichText = message:isRichText()
        this.titleID = message:getTitleID()
        this.rawTextWithPrefix = message:getTextWithPrefixBase()
    else
        local chat = message:getChat()
        this.keepRichText = this.chatType == 'server'
        this.titleID = _getChatTitleID(chat)
        this.rawTextWithPrefix = _getTextWithPrefix(message)
    end

    this.rawText = API.messages.stripEncodedData(this.rawText)
    this.rawTextWithPrefix = API.messages.stripEncodedData(this.rawTextWithPrefix)
    this.parsed = API.messages.parse(this.rawText, this.rawTextWithPrefix, this.chatType)

    return this
end


return MessageInfo

--#region Type Definitions

---@class Args.MessageInfo.SetStream
---@field chatType? omi.ChatTypeString The chat type to set alongside the stream. Defaults to the stream's chat type.
---@field forceFormat? boolean Flag for if the format should be set to the chat's format regardless of whether it's already set.
---@field noTagUpdate? boolean Flag for whether the tags shouldn't be updated to include the target stream's tags.
---@field overwriteTags? boolean Flag for whether the previous tags should be overwritten with the tags from the target stream, instead of merging.

--#endregion
