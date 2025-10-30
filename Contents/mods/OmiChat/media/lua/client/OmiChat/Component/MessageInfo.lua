---@namespace omichat
---Helper for building information about a chat message.

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
local instanceof = instanceof
local getZomboidRadio = getZomboidRadio


---@class MessageInfo : omi.Class
---@field message Message The message object.
---@field tokens table<string, any> Token substitution values.
---@field context table Table for arbitrary context data.
---@field content? string The message content to display in chat. Set by transformers.
---@field rawText string The raw text of the message. This should not be modified.
---@field chatType omi.ChatTypeString The chat type of the message's chat.
---@field format? string The format string to use for the message. Set by transformers.
---@field default? string The name of the default to use for the `$Default()` function.
---@field stream? Stream The source stream of the message.
---@field originalStream? Stream The original stream of a radio message.
---@field author string The username of the message author.
---@field titleID string The string ID of the chat type's tag.
---@field zombieAttractRange? number The range at which the message will be heard by zombies.
---@field tags omi.SetTable<string> A set of tags to add to the message tokens.
---@field meta MessageMetadata Metadata attached to the message.
---@field private usePerceivedText? boolean Flag for whether the message text should be replaced by the "perception range" text.
---@field private useUnknownLanguageText? boolean Flag for whether the message text should be replaced by the unknown language text.
---@field private overheadText? string The text to show overhead instead of the message text.
---@field private doFullOverhead? boolean Flag for whether the replacement overhead text should also use the overhead prefix and final formats.
---@field private hidden boolean Flag for whether the message has been hidden both in chat and overhead.
---@field private loudCallout boolean Flag for whether the message is a regular callout.
---@field private sneakCallout boolean Flag for whether the message is a sneak callout.
---@field private datetime string A string representing the date and time the message was sent.
---@field private skipLanguage boolean Flag for whether language processing should skipped.
---@field private tag? string The result of the `FormatTag` option.
---@field private timestamp? string The result of the `FormatTimestamp` option.
---@field private language? string The result of the `FormatLanguage` option.
---@field private showTitle boolean Flag for whether the message will include the chat type tag.
---@field private showTimestamp boolean Flag for whether the message will include a timestamp.
---@field private font ChatFont The font size of the message.
---@field private color? omi.ColorTable<integer> The message color.
local MessageInfo = utils.lib.class()


local _ChatBase = __classmetatables[ChatBase.class].__index
local _ChatMessage = __classmetatables[ChatMessage.class].__index

local _getChatTitleID = _ChatBase.getTitleID
local _getTextWithPrefix = _ChatMessage.getTextWithPrefix


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
            tag = getText(self.titleID),
            tags = self.tokens.tags,
            originalTags = self.tokens.originalTags,
        }, seed)
    end

    local icon = utils.interpolateNamed('Icon', config.Format.Component.Icon, {
        chatType = chatType,
        stream = self.tokens.stream,
        buffyRoll = self.tokens.buffyRoll,
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

    content = utils.trim(content)
    if not self.color then
        local color
        if stream then
            color = API.player.getColorOrDefault(stream:getName())
        end

        self.color = color or self:getOriginalColor()
    end

    self.tokens.input = content
    return true
end

---Runs transformers on the message.
---@param transformers MessageTransformer[]
function MessageInfo:applyTransforms(transformers)
    for i = 1, #transformers do
        local transformer = transformers[i]
        if transformer.transform and transformer:transform(self) == true then
            break
        end

        -- message is hidden; stop processing transforms
        if self.hidden then
            break
        end
    end

    if self.usePerceivedText then
        self:_applyPerceivedText()
    elseif self.useUnknownLanguageText then
        self:_applyUnknownLanguageText()
    end

    if self.tags.HideOverhead or (self.overheadText and not self.meta.displayedOverhead) then
        self.message:setOverHeadSpeech(false)
    end

    self:_avoidEmptyMessages()
    if self.chatType == 'radio' then
        self:_applyRadioStormFix()
        self:_suppressRadioOverhead()
    end

    -- show the modified message
    self:_showReplacementOverheadText()
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
    local input = utils.interpolateNamed(self.default or 'Chat', inputFormat, self.tokens, seed)
    if input == '' then
        self:hide()
        return
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
        buffyRoll = self.tokens.buffyRoll,
        buffyCrit = self.tokens.buffyCrit,
        buffyCritRaw = self.tokens.buffyCritRaw,
        tags = self.tokens.tags,
        originalTags = self.tokens.originalTags,
        input = input,
    }

    tokens.prefix = utils.trim(utils.interpolateNamed('ChatPrefix', config.Format.Chat.Prefix, tokens, seed))

    local color = utils.color.toRichText(self.color)
    local size = ' <SIZE:' .. (self.font or 'medium') .. '> '
    local content = utils.interpolateNamed('ChatFinal', config.Format.Chat.Final, tokens, seed)

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

---Gets the username of the author of the message.
---If there is no author, returns the empty string.
---@return string
function MessageInfo:getAuthor()
    return self.author
end

---Returns the chat type of the message.
---@return omi.ChatTypeString
function MessageInfo:getChatType()
    return self.chatType
end

---Returns the explicitly set color for the message to use.
---If a format color was not set, returns `nil`.
---@return omi.ColorTable<integer>?
function MessageInfo:getColor()
    return self.color
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

---Gets the text to use as the language indicator in chat.
---@return string?
function MessageInfo:getLanguageText()
    return self.language
end

---Returns metadata about the message.
---@return MessageMetadata
function MessageInfo:getMetadata()
    return self.meta
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

---Gets the original stream a radio message was sent over, if it was able to be decoded.
---@return Stream?
function MessageInfo:getOriginalStream()
    return self.originalStream
end

---Gets tokens to use for an overhead format.
---@return table
function MessageInfo:getOverheadTokens()
    self:syncTags()

    local tokens = utils.copy(self.tokens)
    tokens.chatType = self.chatType
    tokens.username = self.author
    tokens.stream = self.stream and self.stream:getName()

    return tokens
end

---Gets the raw message text, without modifications.
---@return string
function MessageInfo:getRawText()
    return self.rawText
end

---Gets the stream the message was sent over, if it was able to be decoded.
---@return Stream?
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
    self.hidden = true
end

---Sets the message to not show in chat.
function MessageInfo:hideInChat()
    self.message:setShowInChat(false)
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
---@param color omi.ColorTable<integer>
function MessageInfo:setColor(color)
    self.color = color
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

---Sets the text to show overhead for this message.
---@param text string?
---@param doFullFormatting boolean?
function MessageInfo:setOverheadText(text, doFullFormatting)
    self.overheadText = text
    self.doFullOverhead = doFullFormatting

    if not text then
        self:hideOverhead()
    end
end

---Updates the stream and associated information to act as if the message was sent on another stream.
---@param stream Stream
---@param options Args.MessageInfo.SetStream?
function MessageInfo:setStream(stream, options)
    options = options or {}

    local name = stream:getName()
    self.stream = stream
    self.meta.stream = name
    self.tokens.stream = name

    local chatType = options.chatType or stream:getChatType()
    if chatType then
        self.chatType = chatType
        self.titleID = API.ui.chatTypeToTitleID(chatType)
    end

    if not self.format or options.forceFormat then
        self.default = nil
        self.format = stream:getChatFormat()
    end

    if stream:isChatStream() then
        self.color = nil
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

---Sets a flag to use the text for a message in perception range.
---@param usePerceived boolean
function MessageInfo:setUsePerceivedText(usePerceived)
    self.usePerceivedText = usePerceived
end

---Sets a flag to use the text for a message with an unknown language.
---@param useUnknownLanguage boolean
function MessageInfo:setUseUnknownLanguageText(useUnknownLanguage)
    self.useUnknownLanguageText = useUnknownLanguage
end

---Determines whether a message should attract zombies for a given user.
---@param username string
---@return boolean
function MessageInfo:shouldAttractZombies(username)
    if self.loudCallout or self.sneakCallout then
        return false
    end

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

---Sets the message to not process roleplay languages.
function MessageInfo:skipLanguageProcessing()
    self.skipLanguage = true
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

    for k in pairs(tagSet) do
        self.tags[k] = true
    end

    self.tokens.tags = MultiMap.fromSet(self.tags)
end


---Applies the changes to show the out-of-range perceived text.
---@private
function MessageInfo:_applyPerceivedText()
    self.format = config.Format.PerceptionRange.Chat
    self.default = 'PerceptionRangeChat'
    self.tags.IsPerceptionRange = true

    self:syncTags() -- sync tags for overhead format

    local overhead = utils.interpolateNamed(
        'PerceptionRangeOverhead',
        config.Format.PerceptionRange.Overhead,
        self:getOverheadTokens()
    )

    if overhead ~= '' then
        self:setOverheadText(overhead, true)
    else
        self:hideOverhead()
    end

    local targetStream = self:_getActionStream()
    if targetStream then
        self:setStream(targetStream)
    end
end

---Applies a partial fix to scrambling that occurs on radios during storms.
---@private
function MessageInfo:_applyRadioStormFix()
    local text = self.content or self.rawText
    if self.chatType ~= 'radio' or not config.NarrativeStyle.Enable or not text:match('&lt;[bfws]zzt&gt;') then
        return
    end

    -- avoid duplicate name when radios scramble narrative style messages during storms
    -- this is not ideal, but for now it will have to do
    local author = self.author
    if author and author ~= '' then
        text = text:gsub(utils.escape(author), '')
    end

    if self.tokens.nameRaw then
        text = text:gsub(utils.escape(self.tokens.nameRaw), '')
    end

    self.content = text
end

---Applies the changes to use the unknown language format.
---@private
function MessageInfo:_applyUnknownLanguageText()
    local chatType = self.chatType
    if chatType == 'radio' then
        self.format = config.Language.UnknownLanguageRadio
        self.default = 'UnknownLanguageChat'
        return
    end

    self.default = 'UnknownLanguageChat'
    self.format = config.Language.UnknownLanguageChat
    self.tags.IsUnknownLanguage = true

    if chatType ~= 'say' and chatType ~= 'shout' then
        return
    end

    if self.message:isOverHeadSpeech() then
        self:syncTags() -- sync tags for overhead format

        local overhead = utils.interpolateNamed(
            'UnknownLanguageOverhead',
            config.Language.UnknownLanguageOverhead,
            self:getOverheadTokens()
        )

        if overhead ~= '' then
            self:setOverheadText(overhead, true)
        else
            self:hideOverhead()
        end
    end

    local targetStream = self:_getActionStream()
    if targetStream then
        local stream = self.stream
        if stream and stream:hasTag('Action') then
            self.tags.IsActionUnknownLanguage = true
        end

        self:setStream(targetStream)
    end
end

---Avoids empty messages by checking for invisible character-only messages.
---@private
function MessageInfo:_avoidEmptyMessages()
    local text = utils.trim(utils.removeInvisible(self.content or self.rawText))
    if #text == 0 then
        self:hide()
    end
end

---Gets the best action stream to use for displaying a message.
---@return ChatStream? stream
---@private
function MessageInfo:_getActionStream()
    local targetTags
    if self.sneakCallout or self.tags.Quiet then
        targetTags = { 'Quiet', 'Whisper' }
    elseif self.loudCallout or self.tags.Loud then
        targetTags = { 'Loud' }
    end

    local streams = API.streams.getChatStreamsWithTag('Action', { 'NoName' })

    local targetStream
    if targetTags then
        for i = 1, #streams do
            local stream = streams[i]
            if stream:hasAnyTags(targetTags) then
                targetStream = stream
                break
            end
        end
    end

    return targetStream or streams[1]
end

---Determines the source stream of a message based on encoded information.
---@param skipRadio boolean?
---@return Stream? stream
---@private
function MessageInfo:_getMessageStream(skipRadio)
    if self.chatType == 'server' then
        return API.streams.getServerStream()
    elseif self.chatType == 'radio' and not skipRadio then
        return API.streams.getRadioStream()
    elseif self.message:isFromDiscord() then
        return API.streams.getDiscordStream()
    end

    local text = self.message:getText()
    for stream in API.streams.iter() do
        local formatter = stream:getFormatter()
        local isMatch = formatter and formatter:isMatch(text)
        if isMatch then
            return stream
        end
    end
end

---Reads the stream information from the metadata or the message content.
---@private
function MessageInfo:_setupStreamInfo()
    local meta = self.meta
    self.stream = self.stream or (meta.stream and API.streams.getChatStream(meta.stream)) or self:_getMessageStream()
    self.originalStream = self.originalStream or (meta.originalStream and API.streams.getChatStream(meta.originalStream))

    if not self.originalStream and self.stream and self.stream:isRadioStream() then
        self.originalStream = self:_getMessageStream(true)
    end

    if self.stream then
        meta:set('stream', self.stream:getName())
    end

    if self.originalStream then
        meta:set('originalStream', self.originalStream:getName())
    end

    self.tags = self.stream and self.stream:getTags() or {}
end

---Displays text overhead that has been designated as the replacement for the overhead text.
---@private
function MessageInfo:_showReplacementOverheadText()
    local overheadText = self.overheadText
    if not overheadText or self.hidden or self.meta.displayedOverhead then
        return
    end

    self.meta:set('displayedOverhead', true)

    local authorPlayer = utils.getPlayerByUsername(self.author)
    if not authorPlayer then
        return
    end

    if self.doFullOverhead then
        local formatter = API._metadataFormatters.overheadFinal
        local overheadFormat = formatter and formatter:getFormatString()
        if overheadFormat then
            local tokens = self:getOverheadTokens()
            tokens.input = overheadText
            tokens.prefix = utils.trimleft(
                utils.interpolateNamed('OverheadPrefix', config.Format.Overhead.Prefix, tokens)
            )

            overheadText = utils.interpolateNamed('OverheadFinal', overheadFormat, tokens)
        end
    end

    if utils.trim(overheadText) == '' then
        return
    end

    local range = self.stream and self.stream:getRange()
    if not range then
        range = self.chatType == 'shout' and 60 or 30
    end

    local color = authorPlayer:getSpeakColour()
    local r, g, b = color:getR(), color:getG(), color:getB()
    authorPlayer:addLineChatElement(
        overheadText, r, g, b,
        UIFont.Medium, range, 'default',
        true, true, true, true, false, true
    )
end

---Handles suppression of overhead radio messages.
---@private
function MessageInfo:_suppressRadioOverhead()
    -- the message showing overhead is hardcoded for radio messages,
    -- so, if it shouldn't show overhead, we have to suppress it by overwriting with empty messages
    if self.chatType ~= 'radio' or self.message:isOverHeadSpeech() then
        return
    end

    if self.meta.suppressedRadio then
        -- we've done this already (redrawing)
        return
    end

    self.meta:set('suppressedRadio', true) -- avoid doing this again

    -- push the message up with blank text
    local player = getSpecificPlayer(0)
    if player then
        for _ = 1, 5 do
            player:Say(' ')
        end
    end

    local zomboidRadio = getZomboidRadio()
    if not zomboidRadio then
        return
    end

    -- do the same thing for radios
    local radioChannel = self.message:getRadioChannel()
    local devices = zomboidRadio:getDevices()
    for i = 0, devices:size() - 1 do
        local device = devices:get(i) ---@cast device IsoWaveSignal
        local deviceData = device and device:getDeviceData()
        if deviceData and instanceof(device, 'IsoRadio') then
            local canTransmit = not deviceData:isPlayingMedia() and not deviceData:isNoTransmit()
            local hasSayLine = canTransmit and device.getSayLine and device:getSayLine()
            if hasSayLine and deviceData:getChannel() == radioChannel then
                for _ = 1, 5 do
                    device:Say(' ')
                end
            end
        end
    end
end


---Creates a new message information object.
---@param message Message The message to create an information object for.
---@return MessageInfo info
function MessageInfo:new(message)
    local this = setmetatable({}, self) --[[@as MessageInfo]]
    local instance = ISChat.instance

    this.context = {}
    this.meta = Metadata:new(message)
    this.message = message
    this.chatType = API.chat.getMessageChatType(message)
    this.author = message:getAuthor() or ''
    this.datetime = tostring(message:getDatetime())
    this.loudCallout = false
    this.sneakCallout = false
    this.hidden = false
    this.font = instance and instance.chatFont or 'medium'
    this.showTitle = instance and instance.showTitle or false
    this.showTimestamp = instance and instance.showTimestamp or false

    if utils.isinstance(message, MimicMessage) then
        this.rawText = message:getTextWithPrefixBase()
        this.titleID = message:getTitleID()
    else
        -- `getText` doesn't handle color & image formatting.
        -- would just use that otherwise
        local chat = message:getChat()
        this.rawText = _getTextWithPrefix(message)
        this.titleID = _getChatTitleID(chat)
    end

    this:_setupStreamInfo()

    local formatter = API.format.get('adminIcon')
    local displayAsAdmin = formatter and formatter:isMatch(message:getText())

    this.tokens = {
        admin = displayAsAdmin and '1' or nil,
        stream = this.stream and this.stream:getName() or this.chatType,
        chatType = this.chatType,
        author = utils.escapeRichText(this.author),
        authorRaw = this.author,
        name = this.meta.name or utils.escapeRichText(this.author),
        nameRaw = this.meta.name or utils.escapeRichText(this.author),
        tags = MultiMap.fromSet(this.tags),
        originalTags = MultiMap.fromSet(this.originalStream and this.originalStream:getTags()),
    }

    return this
end


API.MessageInfo = MessageInfo
return MessageInfo

--#region Type Definitions

---@class Args.MessageInfo.SetStream
---@field chatType? omi.ChatTypeString The chat type to set alongside the stream. Defaults to the stream's chat type.
---@field forceFormat? boolean Flag for if the format should be set to the chat's format regardless of whether it's already set.
---@field noTagUpdate? boolean Flag for whether the tags shouldn't be updated to include the target stream's tags.
---@field overwriteTags? boolean Flag for whether the previous tags should be overwritten with the tags from the target stream, instead of merging.

--#endregion
