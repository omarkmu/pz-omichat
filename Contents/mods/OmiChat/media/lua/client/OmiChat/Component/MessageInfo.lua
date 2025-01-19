local API = require 'OmiChat/API/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local MimicMessage = API.MimicMessage
local MultiMap = utils.MultiMap
local ISChat = ISChat ---@cast ISChat omichat.ISChat

local isempty = table.isempty
local format = string.format
local getTexture = getTexture


---@class omichat.MessageInfo : omi.Class
local MessageInfo = utils.lib.class()


local _ChatBase = __classmetatables[ChatBase.class].__index
local _ChatMessage = __classmetatables[ChatMessage.class].__index

local _getChatType = _ChatBase.getType
local _getChatTitleID = _ChatBase.getTitleID
local _getTextWithPrefix = _ChatMessage.getTextWithPrefix


---Decodes information encoded in a message's tag.
---@static
---@param tag string The message tag to decode.
---@param metadata table? The table to populate with metadata.
---@return omichat.MessageInfo.Metadata
function MessageInfo.decodeMessageTag(tag, metadata)
    metadata = metadata or {} ---@type omichat.MessageInfo.Metadata
    table.wipe(metadata)
    if not tag or tag == '' then
        return metadata
    end

    local _, decoded = utils.json.tryDecode(tag)
    if type(decoded) ~= 'table' then
        return metadata
    end

    metadata.faction = decoded.faction
    metadata.rangeResult = decoded.rangeResult
    metadata.suppressedRadio = decoded.suppressedRadio
    metadata.attractedZombies = decoded.attractedZombies
    metadata.language = decoded.language
    metadata.name = decoded.name
    metadata.nameColor = utils.color.fromString(decoded.nameColor)
    metadata.recipientNameColor = utils.color.fromString(decoded.recipientNameColor)
    metadata.icon = decoded.icon
    metadata.adminIcon = decoded.adminIcon
    metadata.stream = decoded.stream
    metadata.originalStream = decoded.originalStream

    return metadata
end

---Encodes message information including chat name and colors into a message's metadata.
---@static
---@param message omichat.Message The message to encode.
function MessageInfo.encodeMessageTag(message)
    local author = message:getAuthor() ---@type string?
    if author == '' then
        author = nil
    end

    local text = message:getText()
    local adminFormatter = API.getFormatter('adminIcon')
    local useAdminIcon = adminFormatter and adminFormatter:isMatch(text)

    local color = author and API.getSpeechColor(author)
    local encoded = utils.json.tryEncode {
        language = API.decodeLanguage(message),
        name = API.getNameInChatRichText(author, MessageInfo.getMessageChatType(message)),
        nameColor = color and utils.color.toHexString(color) or nil,
        icon = author and API.getChatIcon(author) or nil,
        adminIcon = useAdminIcon and config.General.AdminIcon or nil,
    }

    message:setCustomTag(encoded or '')
end

---Returns the chat type of a chat message.
---@static
---@param message omichat.Message
---@return string
function MessageInfo.getMessageChatType(message)
    if utils.isinstance(message, MimicMessage) then
        ---@cast message omi.chat.MimicMessage
        return message:getChatType()
    end

    ---@cast message ChatMessage
    return tostring(_getChatType(message:getChat()))
end

---Determines the source stream of a message based on encoded information.
---@static
---@param message omichat.Message
---@param chatType omichat.ChatTypeString
---@param excludeRadio boolean?
---@return omichat.Stream?
function MessageInfo.getMessageStream(message, chatType, excludeRadio)
    if chatType == 'server' then
        return API.getServerStream()
    elseif chatType == 'radio' and not excludeRadio then
        return API.getRadioStream()
    elseif message:isFromDiscord() then
        return API.getDiscordStream()
    end

    local text = message:getText()
    for stream in API.streams() do
        local formatter = stream:getFormatter()
        local isMatch = formatter and formatter:isMatch(text)
        if isMatch then
            return stream
        end
    end
end

---Checks whether a message has metadata encoded into its tag.
---@param message omichat.Message
---@return boolean
function MessageInfo.hasEncodedMetadata(message)
    return not isempty(MessageInfo.decodeMessageTag(message:getCustomTag()))
end

---Returns whether name colors should be used for a stream.
---@static
---@param stream omichat.Stream?
---@return boolean
function MessageInfo.shouldUseNameColors(stream)
    if not config.Customization.EnableNameColors then
        return false
    end

    if not API.getNameColorsEnabled() then
        return false
    end

    return not stream or stream:canUseNameColors()
end


---Adds the given tags to the set of tags in the interpolation tokens.
---@param tags string[]
function MessageInfo:addTags(tags)
    for i = 1, #tags do
        self.tags[tags[i]] = true
    end
end

---Applies the formatting determined by transformers.
---If the format string or content are unset, this will fail.
---@return boolean success
function MessageInfo:applyFormatting()
    local content = self.content
    if not content or content == '' or not self.format or self.format == '' then
        -- hide if the stream is mismatched or unrecognized
        if self.message:isShowInChat() and self:checkMismatch() then
            self:hide()
        end

        -- if there's no format or no content, fail so we can show the original text
        return false
    end

    local dt = self.datetime
    local chatType = self.chatType
    local options = self.options
    local seed = dt
    local stream = self.stream

    self:syncTags()

    if options.showTimestamp then
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
            self.timestamp = utils.interpolate(config.Format.Component.Timestamp, {
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

    self.language = utils.interpolate(config.Format.Component.Language, {
        chatType = chatType,
        stream = self.tokens.stream,
        languageRaw = self.tokens.languageRaw,
        language = self.tokens.language,
        unknownLanguage = self.tokens.unknownLanguage,
        tags = self.tokens.tags,
        originalTags = self.tokens.originalTags,
    })

    if options.showTitle then
        self.tag = utils.interpolate(config.Format.Component.Tag, {
            chatType = chatType,
            stream = self.tokens.stream,
            tag = getText(self:getTitleID()),
            tags = self.tokens.tags,
            originalTags = self.tokens.originalTags,
        }, seed)
    end

    local icon = utils.interpolate(config.Format.Component.Icon, {
        chatType = chatType,
        stream = self.tokens.stream,
        buffyRoll = self.tokens.buffyRoll,
        icon = self:getIcon(),
        adminIcon = self:getAdminIcon(),
        tags = self.tokens.tags,
        originalTags = self.tokens.originalTags,
    }, seed)

    if icon and getTexture(icon) then
        local size = 14
        if options.font == 'small' then
            size = 12
        elseif options.font == 'large' then
            size = 16
        end

        self.tokens.iconRaw = icon
        self.tokens.icon = format(' <IMAGE:%s,%d,%d> ', icon, size + 1, size)
    end

    if self.shouldUseNameColors(stream) then
        local encodedColor = self.meta.nameColor
        local nameColor = encodedColor or API.getSpeechColor(self.author) or { r = 255, g = 255, b = 255 }
        local nameColorTag = utils.color.toRichText(nameColor, true)

        if nameColorTag ~= '' then
            if not encodedColor then
                self:setMetadataNameColor(nameColor)
            end

            self.tokens.name = nameColorTag .. self.tokens.name .. ' <POPRGB> '
            self.tokens.author = nameColorTag .. self.tokens.author .. ' <POPRGB> '
        end

        local recip = self.tokens.recipient
        if recip then
            local encodedRecipColor = self.meta.recipientNameColor
            local recipColor = encodedRecipColor or API.getSpeechColor(recip) or { r = 255, g = 255, b = 255 }

            local recipColorTag = utils.color.toRichText(recipColor, true)

            if recipColorTag ~= '' then
                if not encodedRecipColor then
                    self:setMetadataRecipientNameColor(recipColor)
                end

                self.tokens.recipientName = recipColorTag .. self.tokens.recipientName .. ' <POPRGB> '
                self.tokens.recipient = recipColorTag .. recip .. ' <POPRGB> '
            end
        end
    end

    content = utils.trim(content)
    if not options.color then
        local color
        if stream then
            color = API.getColorOrDefault(stream:getName())
        end

        options.color = color or self:getOriginalColor()
    end

    self.tokens.message = content
    return true
end

---Gets the message text to use.
---This should be called after applying transforms and format options.
---@return string?
function MessageInfo:buildMessageText()
    local inputFormat = self.format
    if not inputFormat or inputFormat == '' then
        return
    end

    self:syncTags()

    local seed = self.datetime
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
        buffyRoll = self.tokens.buffyRoll,
        buffyCrit = self.tokens.buffyCrit,
        buffyCritRaw = self.tokens.buffyCritRaw,
        tags = self.tokens.tags,
        originalTags = self.tokens.originalTags,
        input = utils.interpolate(inputFormat, self.tokens, seed),
    }

    tokens.prefix = utils.trim(utils.interpolate(config.Format.Chat.Prefix, tokens, seed))

    local color = utils.color.toRichText(self.options.color)
    local size = ' <SIZE:' .. (self.options.font or 'medium') .. '> '
    local content = utils.interpolate(config.Format.Chat.Final, tokens, seed)

    return color .. size .. content
end

---Checks whether the stream is a mismatched or currently unrecognized stream.
---@return boolean
function MessageInfo:checkMismatch()
    local stream = self.stream

    -- special streams aren't real chat streams, so they can't be mismatched
    if stream and stream:isSpecialStream() then
        return false
    end

    local text = self.rawText
    local streamFormatter = stream and stream:getFormatter()
    for i = config.MIN_CHAT_ID, config.MAX_CHAT_ID do
        local formatter = API._chatFormatters[i]
        if not formatter then
            return false
        end

        if formatter ~= streamFormatter and formatter:isMatch(text) then
            -- matching on a different chat formatter → message out-of-sync with updated ID
            -- this shouldn't typically happen due to recycling
            return true
        end
    end

    return false
end

---Gets the admin icon encoded in the message.
---@return string?
function MessageInfo:getAdminIcon()
    return self.meta.adminIcon
end

---Gets the username of the author of the message.
---If there is no author, returns the empty string.
---@return string
function MessageInfo:getAuthor()
    return self.author
end

---Returns the chat type of the message.
---@return omichat.ChatTypeString
function MessageInfo:getChatType()
    return self.chatType
end

---Returns the explicitly set color for the message to use.
---If a format color was not set, returns `nil`.
---@return omi.ColorTable?
function MessageInfo:getColor()
    return self.options.color
end

---Returns the content set by transformers, or `nil` if unset.
---@return string?
function MessageInfo:getContent()
    return self.content
end

---Returns the content set by transformers, or the raw text if unset.
---@return string
function MessageInfo:getCurrentText()
    return self.content or self.rawText
end

---Returns a string representing the date and time the message was sent.
---@return string
function MessageInfo:getDatetimeString()
    return self.datetime
end

---Gets the format string set by transformers.
---@return string?
function MessageInfo:getFormat()
    return self.format
end

---Gets the icon encoded in the message.
---@return string?
function MessageInfo:getIcon()
    return self.meta.icon
end

---Gets the text to use as the language indicator in chat.
---@return string?
function MessageInfo:getLanguageText()
    return self.language
end

---Returns metadata about the message.
---@return omichat.MessageInfo.Metadata
function MessageInfo:getMetadata()
    return self.meta
end

---Gets the roleplay language that was encoded in the message metadata.
---@return string?
function MessageInfo:getMetadataLanguage()
    return self.meta.language
end

---Gets the result of range checking stored in the message metadata.
---@return omichat.MessageInfo.Metadata.RangeResult?
function MessageInfo:getMetadataRangeResult()
    return self.meta.rangeResult
end

---Gets the name color encoded in the message.
---@return omi.ColorTable?
function MessageInfo:getNameColor()
    return self.meta.nameColor
end

---Gets the original text color of the message.
---@return omi.ColorTable
function MessageInfo:getOriginalColor()
    local textColor = self.message:getTextColor()
    return {
        r = textColor:getRed(),
        g = textColor:getGreen(),
        b = textColor:getBlue(),
    }
end

---Gets the original stream a radio message was sent over, if it was able to be decoded.
---@return omichat.Stream?
function MessageInfo:getOriginalStream()
    return self.originalStream
end

---Gets the raw message text, without transformations.
---@return string
function MessageInfo:getRawText()
    return self.rawText
end

---Gets the recipient name color encoded in the message.
---@return omi.ColorTable?
function MessageInfo:getRecipientNameColor()
    return self.meta.recipientNameColor
end

---Gets the stream the message was sent over, if it was able to be decoded.
---@return omichat.Stream?
function MessageInfo:getStream()
    return self.stream
end

---Returns the text to use for the message tag.
---@return string?
function MessageInfo:getTag()
    return self.tag
end

---Returns the text to use for the message timestamp.
---@return string?
function MessageInfo:getTimestamp()
    return self.timestamp
end

---Gets the string ID used for the message chat tag.
---@return string
function MessageInfo:getTitleID()
    return self.titleID
end

---Gets the range within which the message should attract zombies.
---A `nil` value indicates that the message should not attract zombies.
---@return integer?
function MessageInfo:getZombieAttractionRange()
    return self.zombieAttractRange
end

---Checks whether content has been set for the message.
---@return boolean
function MessageInfo:hasContent()
    return self.content ~= nil
end

---Checks whether a format has been set for the message.
---@return boolean
function MessageInfo:hasFormat()
    return self.format ~= nil
end

---Checks whether the current tags contain a given tag.
---@param tag string
---@return boolean
function MessageInfo:hasTag(tag)
    return self.tags[tag] == true
end

---Sets the message to not show overhead or in chat.
function MessageInfo:hide()
    self.message:setShowInChat(false)
    self.message:setOverHeadSpeech(false)
end

---Sets the message to not show overhead.
function MessageInfo:hideOverhead()
    self.message:setOverHeadSpeech(false)
end

---Returns whether this message has been marked as a non-sneak callout.
---@return boolean
function MessageInfo:isCallout()
    return self.loudCallout
end

---Returns whether this message has been marked as a sneak callout.
---@return boolean
function MessageInfo:isSneakCallout()
    return self.sneakCallout
end

---Returns whether the message is of the given chat type.
---@param chatType string
---@return boolean
function MessageInfo:isChatType(chatType)
    return self.chatType == chatType
end

---Sets the color to use for the message.
---@param color omi.ColorTable
function MessageInfo:setColor(color)
    self.options.color = color
end

---Sets the display content.
---@param content string?
function MessageInfo:setContent(content)
    self.content = content
end

---Sets the format string to use.
---@param fmt string?
function MessageInfo:setFormat(fmt)
    self.format = fmt
end

---Sets whether the message should be marked as a callout.
---@param callout boolean
function MessageInfo:setIsCallout(callout)
    if callout then
        self.tokens.callout = '1'
        self.tags.IsCallout = true
    end

    self.loudCallout = callout
end

---Sets whether the message should be marked as a sneak callout.
---@param sneakCallout boolean
function MessageInfo:setIsSneakCallout(sneakCallout)
    if sneakCallout then
        self.tokens.callout = '1'
        self.tokens.sneakCallout = '1'
        self.tags.IsCallout = true
        self.tags.IsSneakCallout = true
    end

    self.sneakCallout = sneakCallout
end

---Sets a value in the message metadata to indicate that zombie attraction has already occurred.
function MessageInfo:setMetadataAttractedZombies()
    self:_setMetadataValue('attractedZombies', true)
end

---Sets the faction in the message metadata.
---@param faction string
---@return boolean success
function MessageInfo:setMetadataFaction(faction)
    return self:_setMetadataValue('faction', faction)
end

---Sets the language in the message metadata.
---@param language string
---@return boolean success
function MessageInfo:setMetadataLanguage(language)
    return self:_setMetadataValue('language', language)
end

---Sets the color to use for the author name in the message metadata.
---@param color omi.ColorTable
function MessageInfo:setMetadataNameColor(color)
    self:_setMetadataValue('nameColor', utils.color.toHexString(color))
end

---Sets a value in the message metadata to indicate the message has already been suppressed for the radio.
---@param suppressed boolean
---@return boolean success
function MessageInfo:setMetadataRadioSuppressed(suppressed)
    return self:_setMetadataValue('suppressedRadio', suppressed)
end

---Sets a value in the message metadata to indicate the result of range checking.
---@param result omichat.MessageInfo.Metadata.RangeResult
---@return boolean success
function MessageInfo:setMetadataRangeResult(result)
    return self:_setMetadataValue('rangeResult', result)
end

---Sets the color to use for the recipient name in the message metadata.
---@param color omi.ColorTable
function MessageInfo:setMetadataRecipientNameColor(color)
    self:_setMetadataValue('recipientNameColor', utils.color.toHexString(color))
end

---Updates the stream and associated information to act as if the message was sent on another stream.
---@param stream omichat.Stream
---@param options omichat.Args.MessageInfo.SetStream?
function MessageInfo:setStream(stream, options)
    if stream == self.stream then
        return
    end

    options = options or {}

    local name = stream:getName()
    self.stream = stream
    self.meta.stream = name
    self.tokens.stream = name

    local chatType = options.chatType or stream:getChatType()
    if chatType then
        self.chatType = chatType
        self.titleID = API.chatTypeToTitleID(chatType)
    end

    if not self.format or options.forceFormat then
        self.format = stream:getChatFormat()
    end

    if stream:isChatStream() then
        self.options.color = nil
    end

    if options.noTagUpdate then
        return
    end

    local streamTags = stream:getTags()
    if options.overwriteTags then
        self.tokens.tags = nil
        self.tags = streamTags
    else
        for k in pairs(streamTags) do
            self.tags[k] = true
        end
    end
end

---Sets the string ID used for the message chat tag.
---@param titleID string
function MessageInfo:setTitleID(titleID)
    self.titleID = titleID
end

---Sets the range within which the message should attract zombies.
---A `nil` value indicates that the message should not attract zombies.
---@param range integer?
function MessageInfo:setZombieAttractionRange(range)
    self.zombieAttractRange = range
end

---Determines whether a message should attract zombies for a given user.
---@param username string
---@return boolean
function MessageInfo:shouldAttractZombies(username)
    local range = self.zombieAttractRange
    if not range or self.author ~= username or self.meta.attractedZombies then
        return false
    end

    return self.message:isShouldAttractZombies()
end

---Returns whether language processing should be skipped.
---@return boolean
function MessageInfo:shouldSkipLanguageProcessing()
    return self.skipLanguage
end

---Sets the message to not process roleplay languages.
function MessageInfo:skipLanguageProcessing()
    self.skipLanguage = true
end

---Syncs tags between the token table and the cache.
function MessageInfo:syncTags()
    local tagSet
    local existingTags = self.tokens.tags
    if utils.isinstance(existingTags, MultiMap) then
        ---@cast existingTags omi.MultiMap
        tagSet = existingTags:toValueSet()
    else
        tagSet = {}
    end

    for k in pairs(tagSet) do
        self.tags[k] = true
    end

    self.tokens.tags = MultiMap.fromSet(self.tags)
end

---Checks whether overhead radio messages were already suppressed for this message.
---@return boolean
function MessageInfo:wasRadioSuppressed()
    return self.meta.suppressedRadio == true
end


---Decodes information encoded in the message's tag.
---@return omichat.MessageInfo.Metadata
---@protected
function MessageInfo:_decodeMetadata()
    return self.decodeMessageTag(self.message:getCustomTag(), self.meta)
end

---Sets a key in the message's metadata.
---@param key string
---@param value unknown
---@return boolean success
---@protected
function MessageInfo:_setMetadataValue(key, value)
    local message = self.message
    local tag = message:getCustomTag()

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
    message:setCustomTag(encodedTag or tag)

    self:_decodeMetadata() -- update metadata cache
    return encodedTag ~= nil
end

---Reads the stream information from the metadata or the message content.
---@protected
function MessageInfo:_setupStreamInfo()
    local message = self.message

    local meta = self.meta
    self.stream = self.stream or (meta.stream and API.getChatStreamByName(meta.stream))
    self.stream = self.stream or self.getMessageStream(message, self.chatType)

    self.originalStream = self.originalStream or (meta.originalStream and API.getChatStreamByName(meta.originalStream))

    if not self.originalStream and self.stream and self.stream:isRadioStream() then
        self.originalStream = self.getMessageStream(message, self.chatType, true)
    end

    if self.stream then
        self:_setMetadataValue('stream', self.stream:getName())
    end

    if self.originalStream then
        self:_setMetadataValue('originalStream', self.originalStream:getName())
    end

    self.tags = self.stream and self.stream:getTags() or {}
end


---Creates a new message information object.
---@param message omichat.Message
---@return omichat.MessageInfo
function MessageInfo:new(message)
    local this = setmetatable({}, self) ---@cast this omichat.MessageInfo

    this.meta = {}
    this.context = {}
    this.message = message
    this.chatType = self.getMessageChatType(message)
    this.author = message:getAuthor() or ''
    this.datetime = tostring(message:getDatetime())
    this.loudCallout = false
    this.sneakCallout = false

    this:_decodeMetadata()

    if utils.isinstance(message, MimicMessage) then
        ---@cast message omi.chat.MimicMessage
        this.rawText = message:getTextWithPrefixBase()
        this.titleID = message:getTitleID()
    else
        -- `getText` doesn't handle color & image formatting.
        -- would just use that otherwise
        ---@cast message ChatMessage
        local chat = message:getChat()
        this.rawText = _getTextWithPrefix(message)
        this.titleID = _getChatTitleID(chat)
    end

    this:_setupStreamInfo()

    local instance = ISChat.instance
    local formatter = API.getFormatter('adminIcon')
    local displayAsAdmin = formatter and formatter:isMatch(message:getText())

    this.tokens = {
        admin = displayAsAdmin and '1' or nil,
        stream = this.stream and this.stream:getName() or this.chatType,
        author = utils.escapeRichText(this.author),
        authorRaw = this.author,
        name = this.meta.name or utils.escapeRichText(this.author),
        nameRaw = this.meta.name or utils.escapeRichText(this.author),
        tags = MultiMap.fromSet(this.tags),
        originalTags = MultiMap.fromSet(this.originalStream and this.originalStream:getTags()),
    }

    this.options = {
        font = instance and instance.chatFont or 'medium',
        showTitle = instance and instance.showTitle or false,
        showTimestamp = instance and instance.showTimestamp or false,
    }

    return this
end


API.MessageInfo = MessageInfo
return MessageInfo
