---Handles formatting and processing of chat messages.
---@namespace omichat
---@diagnostic disable: access-invisible

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local MultiMap = utils.MultiMap
local config = API.Configuration

local abs = math.abs
local concat = table.concat
local getPlayerFaction = Faction.getPlayerFaction
local hasSafehouse = SafeHouse.hasSafehouse

local FONT_MEDIUM = UIFont.Medium
local LIGHT_GRAY = Color.lightGray

local _ChatMessage = __classmetatables[ChatMessage.class].__index
local _ServerChatMessage = __classmetatables[ServerChatMessage.class].__index
local _ChatBase = __classmetatables[ChatBase.class].__index ---@type any
local _getChatType = _ChatBase.getType

local DATA_START = string.char(config.SIGNAL_DATA_START)
local IGNORE_QUOTE = string.char(config.SIGNAL_IGNORE) .. '"'
local DATA_PATTERN = '%s*' .. DATA_START .. '({.+})%s*$'
local commandContextTypes = {
    ['omichat.card'] = true,
    ['omichat.flip'] = true,
    ['omichat.roll'] = true,
}


---@class api.client.messages
local Messages = {}

---Contains functions for formatting and processing chat messages.
API.messages = Messages

---Associates color names to color tables.
---@private
Messages._colors = utils.color.getNamed(true)


---Extends tokens and tags based on the context table.
---@param args Args.AddContextData
function Messages.addContextData(args)
    local tokens = args.tokens
    local tags = args.tags
    if args.isEcho then
        tokens.echo = '1'
        tags.IsEchoMessage = true

        local echoTags = config.EchoMessages.Tags
        for i = 1, #echoTags do
            tags[echoTags[i]] = true
        end
    end

    local ctx = args.context
    if not ctx or not ctx.type then
        return
    end

    if ctx.type == 'omichat.callout' then
        tokens.callout = '1'
        tags.IsCallout = true

        if ctx.sneak then
            tokens.sneakCallout = '1'
            tags.IsSneakCallout = true
        end
    elseif ctx.type == 'omichat.card' then
        utils.extend(tags, API._cardCommand:getTags())

        if args.addCommandTokens then
            tokens.card = utils.getTranslatedCardName(ctx.card, ctx.suit)
        end
    elseif ctx.type == 'omichat.flip' then
        utils.extend(tags, API._flipCommand:getTags())

        if args.addCommandTokens then
            tokens.heads = ctx.heads == true
        end
    elseif ctx.type == 'omichat.roll' then
        utils.extend(tags, API._rollCommand:getTags())

        if args.addCommandTokens then
            tokens.roll = ctx.roll
            tokens.sides = ctx.sides
        end
    end
end

---Builds a message data object to encode in a message.
---@param args Args.BuildMessageData
function Messages.buildData(args)
    local stream = args.stream

    local language
    local currentLanguage = stream:isAllowLanguages() and API.player.getCurrentLanguage()
    if currentLanguage and currentLanguage ~= API.language.getDefault() then
        language = currentLanguage
    end

    ---@type MessageData
    local data = {
        id = args.player:getOnlineID(),
        stream = stream:getName(),
    }

    data.language = language
    data.echoType = args.echoType
    data.ctx = args.context
    data.useAdminIcon = API.player.isChatAdmin() and API.preferences.getShowAdminIcon() or nil
    data.useNarrative = config.NarrativeStyle.Enable and stream:canUseNarrativeStyle() or nil

    return data
end

---Decodes information encoded in message text.
---@param message Message The message to decode information from.
---@return MessageData? data The encoded message data, or `nil` if data could not be found.
---@return string text The message text, without the encoded data.
function Messages.decodeData(message)
    local text = message:getText()

    local start, _, encoded = text:find(DATA_PATTERN)
    if not encoded then
        return nil, text
    end

    local _, decoded = utils.json.tryDecode(encoded)
    if type(decoded) ~= 'table' then
        return nil, text
    end

    return decoded, text:sub(1, (start or 1) - 1)
end

---Encodes initial metadata for a message.
---This has no effect if the message already has metadata.
---@param message Message The message to encode.
function Messages.encodeInitialMetadata(message)
    local meta = API.MessageMetadata:new(message)

    -- don't encode over existing data
    if meta:isEmpty() then
        meta:encodeInitialData()
    end
end

---Encodes a message data table into a string.
---@param messageData MessageData
---@return string
function Messages.encodeData(messageData)
    return DATA_START .. utils.json.encode(messageData)
end

---Returns the chat type of a chat message.
---@param message Message The message to retrieve the chat type of.
---@return omi.ChatTypeString chatType
function Messages.getChatType(message)
    if utils.isinstance(message, API.MimicMessage) then
        ---@cast message omi.MimicMessage
        return message:getChatType()
    end

    ---@cast message ChatMessage
    return tostring(_getChatType(message:getChat())) --[[@as omi.ChatTypeString]]
end

---Gets the prefixed text for a message.
---@param message Message The message to retrieve text for.
---@return string text The built text. If text could not be built, this returns the original text.
function Messages.getTextWithPrefix(message)
    local info = Messages.process(message)
    return info:buildChatText()
end

---Checks that a message is a managed message type.
---Managed types include the vanilla chat messages and `MimicMessage`.
---@param message table
---@return TypeGuard<Message>
function Messages.isManaged(message)
    local mtIndex = (getmetatable(message) or {}).__index
    if mtIndex == _ChatMessage or mtIndex == _ServerChatMessage then
        return true
    end

    return utils.isinstance(message, API.MimicMessage)
end

---Merges parsed segments into a single string.
---@param segments ParsedMessageSegment[] The segments to merge.
---@param forChat boolean? Flag for whether the result string should be formatted for chat.
---@param keepRichText boolean? Flag for whether chat rich text should be maintained
---@return string merged
function Messages.mergeSegments(segments, forChat, keepRichText)
    local parts = {}

    local openColor = false
    for i = 1, #segments do
        local segment = segments[i]

        if segment.type == 'text' then
            ---@cast segment ParsedMessage.TextSegment

            if forChat then
                -- handle spaces after colors
                local lastSegment = segments[i - 1] --[[@as ParsedMessage.ColorSegment?]]
                if lastSegment and lastSegment.color and segment.text:sub(1, 1) == ' ' then
                    parts[#parts + 1] = ' <SPACE> '
                end

                parts[#parts + 1] = keepRichText and segment.text or utils.escapeRichText(segment.text)
            else
                parts[#parts + 1] = segment.text:gsub('%[br/]', ''):gsub('%[cdt=', '')
            end
        elseif segment.type == 'mention' then
            ---@cast segment ParsedMessage.MentionSegment
            local text = segment.text
            if not forChat then
                text = text:gsub('%[br/]', ''):gsub('%[cdt=', '')
            end

            parts[#parts + 1] = text
        elseif segment.type == 'color' then
            ---@cast segment ParsedMessage.ColorSegment
            if openColor then
                parts[#parts + 1] = forChat and ' <POPRGB> ' or '[/]'
            end

            openColor = true
            if forChat then
                -- handle spaces before colors
                local lastSegment = segments[i - 1] --[[@as ParsedMessage.TextSegment?]]
                local text = lastSegment and lastSegment.text
                if text and text:sub(#text, #text) == ' ' then
                    parts[#parts + 1] = ' <SPACE> '
                end

                parts[#parts + 1] = utils.color.toRichText(segment.color, true)
            else
                parts[#parts + 1] = '[col='
                parts[#parts + 1] = utils.color.toRGBString(segment.color)
                parts[#parts + 1] = ']'
            end
        elseif segment.type == 'icon' then
            ---@cast segment ParsedMessage.IconSegment
            if openColor then
                parts[#parts + 1] = forChat and ' <POPRGB> ' or '[/]'
                openColor = false
            end

            if forChat then
                local name = utils.getTextureNameFromIcon(segment.icon)
                local texture = name and getTexture(name)
                if name and texture then
                    local w, h
                    if segment.icon == 'music' then
                        w = texture:getWidth() * 0.75
                        h = texture:getWidth() * 0.75
                    else
                        w = texture:getWidth() * 0.5
                        h = texture:getWidth() * 0.5
                    end

                    parts[#parts + 1] = ' <IMAGE:'
                    parts[#parts + 1] = name
                    parts[#parts + 1] = ','
                    parts[#parts + 1] = w
                    parts[#parts + 1] = ','
                    parts[#parts + 1] = h
                    parts[#parts + 1] = '> '
                end
            else
                local name = utils.getBBCodeNameFromIcon(segment.icon)
                if name then
                    parts[#parts + 1] = '[img='
                    parts[#parts + 1] = name
                    parts[#parts + 1] = ']'
                end
            end
        end
    end

    if openColor then
        parts[#parts + 1] = forChat and ' <POPRGB> ' or '[/]'
    end

    return concat(parts)
end

---Parses message text into a table of segments.
---@param text string The raw text of the message.
---@param textWithPrefix string The text of the message, including the prefix.
---@param chatType omi.ChatTypeString The type of chat the message was sent to.
---@return ParsedMessage
function Messages.parse(text, textWithPrefix, chatType)
    local segments = {} ---@type ParsedMessageSegment[]

    local chars = {}
    local testChars = {}
    local iconCount = 0

    local specialStartPos = #text
    local inSpecial = false

    local i = 1
    while i <= #text do
        local c = text:sub(i, i)
        if c == '*' then
            if not inSpecial then
                if #chars > 0 then
                    segments[#segments + 1] = {
                        type = 'text',
                        text = concat(chars),
                    }

                    chars = {}
                end

                inSpecial = true
                specialStartPos = i
            else
                local value = concat(testChars)
                local valueLower = value:lower()
                testChars = {}

                local texture = iconCount < 10 and utils.getTextureNameFromIcon(valueLower)
                local color = not texture and Messages._getColorFromText(valueLower)
                if texture then
                    segments[#segments + 1] = {
                        type = 'icon',
                        icon = valueLower,
                    }

                    iconCount = iconCount + 1
                    inSpecial = false
                elseif color then
                    segments[#segments + 1] = {
                        type = 'color',
                        color = color,
                    }

                    inSpecial = false
                else
                    -- see logic for unterminated asterisks below
                    i = #text
                end
            end
        elseif inSpecial then
            testChars[#testChars + 1] = c
        else
            local start, stop = text:find('^%s*<@%d+:.->%s*', i)
            if start and stop then
                if #chars > 0 then
                    segments[#segments + 1] = {
                        type = 'text',
                        text = concat(chars),
                    }

                    chars = {}
                end

                segments[#segments + 1] = {
                    type = 'mention',
                    text = text:sub(start, stop),
                }

                i = stop
            else
                chars[#chars + 1] = c
            end
        end

        -- rewind for unterminated asterisks;
        -- necessary to properly parse mentions
        if inSpecial and i == #text then
            i = specialStartPos
            inSpecial = false
            testChars = {}

            segments[#segments + 1] = {
                type = 'text',
                text = '*',
            }
        end

        i = i + 1
    end

    if #chars > 0 then
        segments[#segments + 1] = {
            type = 'text',
            text = concat(chars),
        }
    end

    local recipient
    local frequency
    if chatType == 'whisper' then
        recipient = textWithPrefix:match('%[to ([^%]]+)%]:')
    elseif chatType == 'radio' then
        frequency = textWithPrefix:match('Radio%s*%((%d+%.%d+)[^%)]+%)%s*:')
    end

    return {
        segments = segments,
        recipient = recipient,
        frequency = frequency,
    }
end

---Creates a message info object and applies transformations.
---@param message Message The message to build information for.
---@return MessageInfo info The message information.
function Messages.process(message)
    local info = API.MessageInfo:new(message)

    -- stream in metadata no longer exists → hide and quit
    if info.meta.stream then
        local hide = false
        if info.chatType == 'radio' then
            hide = info.originalStream == nil
        else
            hide = info.stream == nil
        end

        if hide then
            info:hide()
            return info
        end
    end

    info.chatText = API.messages.mergeSegments(info.parsed.segments, true, info.keepRichText)
    if info.doOverhead then
        info.overheadText = API.messages.mergeSegments(info.parsed.segments, false)
    end

    if info.stream then
        info.chatFormat = info.stream.chatFormat
        info.overheadFormat = info.stream.overheadFormat
    end

    info.tokens = Messages._buildTokens(info)
    API.messages.addContextData({
        tokens = info.tokens,
        tags = info.tags,
        context = info.meta.ctx,
        isEcho = info.meta.echoType ~= nil,
        addCommandTokens = true,
    })

    if API.hooks.has.beforeBuildMessage then
        info:syncTags()
        API.hooks.beforeBuildMessage(info)
    end

    local tokens = info.tokens
    local handled = API.hooks.has.buildMessage and API.hooks.buildMessage(info)
    if not handled and not info.hidden then
        Messages._build(info)
        info:syncTags()
    end

    if info.chatType == 'radio' then
        -- avoid outdated overhead text on radios
        Messages._suppressRadioOverhead(info)
    end

    if info.hidden then
        return info
    end

    if API.hooks.has.afterBuildMessage then
        API.hooks.afterBuildMessage(info)
        info:syncTags()
    end

    local targetStream
    if info.usePerceivedText then
        info.chatDefault = 'PerceptionRangeChat'
        info.chatFormat = config.Format.PerceptionRange.Chat
        info.tags.IsPerceptionRange = true

        if info.doOverhead then
            info.overheadDefault = 'PerceptionRangeOverhead'
            info.overheadFormat = config.Format.PerceptionRange.Overhead
        end

        targetStream = Messages._getActionStream(info)
    elseif info.useUnknownLanguageText then
        info.chatDefault = 'UnknownLanguageChat'
        info.tags.IsUnknownLanguage = true

        local chatType = info.chatType
        if chatType == 'radio' then
            info.doOverhead = false
            info.chatFormat = config.Language.UnknownLanguageRadio
        else
            info.chatFormat = config.Language.UnknownLanguageChat
            targetStream = Messages._getActionStream(info)
        end

        if info.doOverhead then
            info.overheadDefault = 'UnknownLanguageOverhead'
            info.overheadFormat = config.Language.UnknownLanguageOverhead
        end
    end

    if targetStream then
        info:setStream(targetStream)
    end

    if info.doOverhead and not info.tags.HideOverhead then
        if info.meta.narrative then
            info:syncTags()
            tokens.unstyled = info.overheadText
            tokens.input = info.overheadText
            info.overheadText = utils.interpolateNamed(
                'NarrativeOverheadContent',
                config.NarrativeStyle.OverheadContentFormat,
                tokens,
                tokens.input
            )
        end

        info.overheadText = Messages._formatMentions(info, false)
        Messages._showOverhead(info)
    end

    Messages._updateTokensForChat(info)

    if info.meta.narrative then
        info:syncTags()
        tokens.unstyled = info.chatText
        tokens.input = info.chatText
        info.chatText = utils.interpolateNamed(
            'NarrativeChatContent',
            config.NarrativeStyle.ChatContentFormat,
            tokens,
            tokens.input
        )
    end

    info.chatText = Messages._formatMentions(info, true)
    info:applyChatFormatting()

    return info
end

---Strips encoded data from the end of text.
---@param text string
function Messages.stripEncodedData(text)
    text = text:gsub(DATA_PATTERN, '')
    return text
end


---Applies transformations to a message based on configuration.
---@param info MessageInfo
---@private
function Messages._build(info)
    local player = API.player.get()
    local username = player and player:getUsername()

    local author = info.author
    local chatType = info.chatType
    local meta = info.meta
    local ctx = meta.ctx
    local ctxType = ctx and ctx.type or ''
    local echoType = meta.echoType
    local isRadio = chatType == 'radio'

    -- handle command messages
    local handled = API.hooks.has.initCommandMessage and API.hooks.initCommandMessage(info)
    if not handled and commandContextTypes[ctxType] then
        local overheadFmt
        if isRadio then
            info:hide()
        elseif ctxType == 'omichat.card' then
            overheadFmt = config.Commands.Card.OverheadFormat
        elseif ctxType == 'omichat.flip' then
            overheadFmt = config.Commands.Flip.OverheadFormat
        elseif ctxType == 'omichat.roll' then
            overheadFmt = config.Commands.Roll.OverheadFormat
        end

        info.chatText = ''
        if info.doOverhead then
            info.overheadText = ''
            info.overheadFormat = overheadFmt
        end
    end

    -- apply overhead callout formats
    if ctxType == 'omichat.callout' and info.doOverhead then
        local isSneak = ctx and ctx.sneak
        info.overheadFormat = isSneak and config.Callouts.SneakFormat or config.Callouts.Format
    end

    -- hide echo messages in chat if the player would have seen the original
    if echoType then
        info.chatFormat = config.EchoMessages.ChatFormat

        local shouldSuppress = author and username and author == username
        if username and not shouldSuppress then
            if echoType == 1 then -- faction
                local playerFaction = getPlayerFaction(username)
                shouldSuppress = playerFaction and (playerFaction:isOwner(author) or playerFaction:isMember(author))
            elseif echoType == 2 then -- safehouse
                local playerSafehouse = hasSafehouse(username)
                shouldSuppress = playerSafehouse and playerSafehouse:playerAllowed(author)
            end
        end

        if shouldSuppress then
            info:hideInChat()
        end
    end

    -- avoid attracting twice for callouts
    if info.tags.IsCallout or info.tags.IsSneakCallout then
        info.message:setShouldAttractZombies(false)
    end

    -- handle roleplay languages
    local language = meta.language
    if language then
        info.tokens.rawLanguage = language
        info.tokens.language = utils.getTranslatedLanguageName(language)

        -- hide signed messages sent over the radio
        if isRadio and API.language.isSigned(language) then
            info:hide()
        end

        local cached = meta.languageResult
        if cached == 'unknown-language' and not (API.player.isChatAdmin() and API.preferences.getUnderstandAllLanguages()) then
            info.tokens.unknownLanguage = language
            info.tags.IsUnknownLanguage = true
            info.useUnknownLanguageText = true
        elseif not cached then
            if not isRadio and author == username then
                -- everyone understands themselves
                meta:setLanguageResult('known-language')
            elseif language and API.player.knowsLanguage(language) then
                meta:setLanguageResult('known-language')
            else
                info.tokens.unknownLanguage = language
                info.tags.IsUnknownLanguage = true
                meta:setLanguageResult('unknown-language')
                info.useUnknownLanguageText = true
            end
        end
    end

    -- set up tokens for narrative style
    if meta.narrativeTag then
        info.tokens.narrativeStyle = '1'
        info.tokens.dialogueTag = meta.narrativeTag
        info.tags.IsNarrativeStyle = true
    elseif meta.narrative then
        info:syncTags()

        local input = info.rawText
        info.tokens.input = input
        info.tokens.narrativeStyle = '1'
        info.tags.IsNarrativeStyle = true

        local dialogueTagFormat = config.NarrativeStyle.DialogueTagFormat
        local dialogueTag = utils.interpolateNamed('NarrativeTag', dialogueTagFormat, info.tokens, input)
        if dialogueTag ~= '' then
            info.tokens.dialogueTag = dialogueTag
            meta:setNarrativeTag(dialogueTag)
        else
            info.tokens.narrativeStyle = nil
            info.tags.IsNarrativeStyle = nil
            meta:set('narrative', nil)
        end
    end

    if player and chatType == 'say' or chatType == 'shout' then
        Messages._checkRange(info, player)
    end

    if isRadio then
        Messages._checkTransmitRadio(info)
    end
end

---Builds the token table for the message.
---@param info MessageInfo
---@return table tokens
---@private
function Messages._buildTokens(info)
    local tokens = {
        admin = info.meta.adminIcon and '1' or nil,
        stream = info.stream and info.stream:getName() or info.chatType,
        chatType = info.chatType,
        author = info.author,
        rawAuthor = info.author,
        tags = MultiMap.fromSet(info.tags),
    }

    if info.originalStream then
        tokens.originalTags = MultiMap.fromSet(info.originalStream:getTags())
        tokens.originalStream = info.originalStream:getName()
    end

    tokens.name = info.meta.name or tokens.author
    tokens.rawName = tokens.name

    local chatType = info.chatType
    if chatType == 'faction' then
        tokens.faction = info.meta.faction
    elseif chatType == 'whisper' then
        local other = info.parsed.recipient

        if not other then
            tokens.incomingPM = '1'
            info.tags.IsIncomingPM = true
        else
            local recipientName = API.data.getNameInChat(other, 'whisper') or other

            tokens.recipient = other
            tokens.rawRecipient = other
            tokens.recipientName = recipientName
            tokens.rawRecipientName = recipientName
            tokens.outgoingPM = '1'
            info.tags.IsOutgoingPM = true
        end
    elseif chatType == 'radio' then
        local freq = info.parsed.frequency
        if freq then
            tokens.frequency = freq

            if not info.chatFormat then
                info.chatFormat = config.Radio.ChatFormat
            end
        end
    end

    return tokens
end

---Checks whether the player is in range to see a message.
---@param info MessageInfo
---@param player IsoPlayer?
---@private
function Messages._checkRange(info, player)
    local stream = info.stream
    if not stream then
        return
    end

    local cached = info.meta.rangeResult
    if cached == 'out-of-range' then
        info:hide()
        return
    elseif cached == 'in-perception-range' then
        info.usePerceivedText = true
        return
    elseif cached then
        return
    end

    local maxRange = info.chatType == 'shout' and 60 or 30
    local range = stream.range
    if info.tags.IsCallout then
        range = config.Callouts.Range
    elseif info.tags.IsSneakCallout then
        range = config.Callouts.SneakRange
    end

    range = range or maxRange

    if stream.attractZombies then
        info.zombieAttractRange = range * config.ZombieAttraction.ChatRangeMultiplier
    end

    if API.player.isChatAdmin() and API.preferences.getIgnoreMessageRange() then
        if not cached then
            info.meta:setRangeResult('in-range')
        end

        return
    end

    local author = utils.getPlayerByUsername(info.author)
    if not author or not player or author == player then
        -- players can hear themselves
        info.meta:setRangeResult('in-range')
        return
    end

    local outOfRange = false
    local zMax = stream.verticalRange or 2

    local dist
    if zMax > 0 and abs(author:getZ() - player:getZ()) >= zMax then
        outOfRange = true
    elseif range ~= maxRange then
        dist = API.player.getDistanceFrom(author, player)
        outOfRange = dist > range
    end

    if not outOfRange then
        info.meta:setRangeResult('in-range')
        return
    end

    -- out of range → check whether we should show text indicating that
    local language = info.tokens.rawLanguage
    local isSigned = language and API.language.isSigned(language)

    if dist and not info.tags.Action then
        range = isSigned and stream.perceptionRangeSigned or stream.perceptionRange
        if API.hooks.has.perceptionRange then
            range = API.hooks.perceptionRange({
                range = range,
                distance = dist,
                player = player,
                author = author,
                isSigned = isSigned or false,
            })
        end

        if dist <= range then
            info.usePerceivedText = true
            info.meta:setRangeResult('in-perception-range')
            return
        end
    end

    info:hide()
    info.meta:setRangeResult('out-of-range')
end

---Handles hiding messages sent over the radio.
---@param info MessageInfo
---@private
function Messages._checkTransmitRadio(info)
    local originalStream = info.originalStream
    local tags = originalStream and originalStream.tags
    if not tags then
        return
    end

    local canTransmit = true
    if tags.IsEchoMessage or tags.NoTransmitOverRadio then
        canTransmit = false
    else
        canTransmit = tags.TransmitOverRadio or (not tags.OOC and not tags.Action)
    end

    if not canTransmit then
        info:hide()
    end
end

---Formats mentions based on settings.
---@param info MessageInfo
---@param forChat boolean
---@return string
---@private
function Messages._formatMentions(info, forChat)
    local useColors = info:shouldUseMentionColors()
    local cached = info.meta.mentions

    local i = 1
    local mentions = {} ---@type MessageMetadata.Mention[]

    local text = forChat and info.chatText or info.overheadText
    text = text:gsub('%s*<@%d+:.->%s*', function(match)
        local leading, onlineID, name, trailing = match:match('(%s*)<@(%d+):(.-)>(%s*)')
        onlineID = utils.tointeger(onlineID)
        if not onlineID or not name then
            return match
        end

        local tokens = utils.copy(info.tokens)
        tokens.input = name
        tokens.onlineID = tostring(onlineID)

        if not forChat or not config.Mentions.Enable then
            local result = utils.interpolateNamed('MentionOverhead', config.Mentions.OverheadFormat, tokens)
            result = result:gsub('"', IGNORE_QUOTE)
            if utils.trim(result) == '' then
                result = name
            end

            return leading .. result .. trailing
        end

        local hoverName
        local color ---@type omi.ColorTable<integer>?
        if cached then
            local item = cached[i] or {}
            hoverName = item.name
            if item and item.color then
                color = utils.color.fromString(item.color)
            end

            i = i + 1
        else
            local playerData = onlineID and API.data.getPlayerInfoByOnlineID(onlineID)
            color = playerData and playerData.speechColor
            hoverName = playerData and API.data.getPlayerNameInChat(playerData, info.chatType)

            if hoverName then
                if utils.unescapeRichText(hoverName) ~= utils.unescapeRichText(name) then
                    hoverName = hoverName:gsub('"', IGNORE_QUOTE):gsub("(['\\])", '\\%1')
                else
                    hoverName = nil
                end
            end
        end

        local result = utils.interpolateNamed('MentionChat', config.Mentions.ChatFormat, tokens)
        if utils.trim(result) == '' then
            result = name
        else
            result = result:gsub('"', IGNORE_QUOTE)
        end

        if color and useColors then
            result = utils.color.toRichText(color, true) .. result .. ' <POPRGB> '
        end

        if hoverName then
            result = " <HOVER text='" .. utils.escapeRichText(hoverName) .. "'> " .. result .. ' </HOVER> '
        end

        if #leading > 0 then
            result = ' <SPACE> ' .. result
        end

        if #trailing > 0 then
            result = result .. ' <SPACE> '
        end

        if not cached then
            mentions[#mentions + 1] = {
                name = hoverName,
                color = color and utils.color.toHexString(color --[[@as any]]) or '',
            }
        end

        return result
    end)

    if forChat and not cached then
        info.meta:setMentions(mentions)
    end

    return text
end

---Gets the best action stream to use for displaying a message.
---@param info MessageInfo
---@return ChatStream? stream
---@private
function Messages._getActionStream(info)
    local targetTags
    if info.tags.IsSneakCallout or info.tags.Quiet then
        targetTags = { 'Quiet', 'Whisper' }
    elseif info.tags.IsCallout or info.tags.Loud then
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

---Gets a color table from a named or comma-delimited numbers.
---@return omi.ColorTable<integer>?
---@private
function Messages._getColorFromText(text)
    local named = Messages._colors[text]
    if named then
        return named
    end

    if #text > 11 then
        return
    end

    local parts = text:split(',')

    ---@type any
    local colorTable = {
        r = tonumber(parts[1]),
        g = tonumber(parts[2]),
        b = tonumber(parts[3]),
    }

    if utils.color.isValid(colorTable) then
        return colorTable --[[@as omi.ColorTable<integer>]]
    end
end

---Displays the overhead text for the message.
---@param info MessageInfo
---@private
function Messages._showOverhead(info)
    info.message:setOverHeadSpeech(false)
    info.meta:setDisplayedOverhead()

    local overheadPlayer = utils.getPlayerByUsername(info.meta.overheadAuthor or info.author)
    if not overheadPlayer then
        return
    end

    local range = info.stream and info.stream:getRange()
    if not range then
        range = info.chatType == 'shout' and 60 or 30
    end

    local text = info:buildOverheadText()
    if not text then
        return
    end

    local color = info.chatType == 'radio' and LIGHT_GRAY or overheadPlayer:getSpeakColour()
    overheadPlayer:addLineChatElement(
        utils.replaceEntities(text),
        color:getR(), color:getG(), color:getB(),
        FONT_MEDIUM, range, 'default',
        true, true, true, true, false, true
    )
end

---Handles suppression of overhead radio messages.
---@param info MessageInfo
---@private
function Messages._suppressRadioOverhead(info)
    if info.meta.suppressedRadio then
        -- we've done this already (redrawing)
        return
    end

    info.meta:set('suppressedRadio', true) -- avoid doing this again

    -- push the message up with blank text
    local player = API.player.get()
    if player then
        for _ = 1, 5 do
            player:Say(' ')
        end
    end

    -- do the same thing for radios
    local zomboidRadio = ZomboidRadio.getInstance()
    local radioChannel = info.message:getRadioChannel()
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

---Updates the token table to escape names for chat.
---@param info MessageInfo
---@private
function Messages._updateTokensForChat(info)
    local tokens = info.tokens
    tokens.input = info.chatText
    if tokens.author then
        tokens.author = utils.escapeRichText(tokens.author)
    end

    if tokens.name then
        tokens.name = utils.escapeRichText(tokens.name)
    end

    if tokens.recipientName then
        tokens.recipientName = utils.escapeRichText(tokens.recipientName)
    end
end

return Messages

--#region Type Definitions

---@class Args.AddContextData
---@field tokens table The token table to add elements to.
---@field tags omi.SetTable<string> The set of tags to extend.
---@field context? table Arbitary context data.
---@field isEcho? boolean Flag for whether this is an echo message.
---@field addCommandTokens? boolean Flag for whether command data tokens should be included.

---@class Args.BuildMessageData
---@field player IsoPlayer The player sending the message.
---@field stream ChatStream The stream to send the message on.
---@field echoType? integer The echo type of the stream, if this is an echo message.
---@field context? table Arbitrary context data.


---@class MessageData
---@field id integer The online ID of the player who sent the message.
---@field stream string The name of the stream the message was sent over.
---@field language? string The untranslated roleplay language of the message.
---@field echoType? integer The echo type identifier, if this is an echo message.
---@field ctx? table Arbitary context data.
---@field useAdminIcon? boolean Flag for whether the admin icon should be included.
---@field useNarrative? boolean Flag for whether narrative style should be applied.

---@class ParsedMessage
---@field segments ParsedMessageSegment[] Segments of the parsed message.
---@field frequency? string The frequency of a radio message.
---@field recipient? string The recipient of a private message.

---@class ParsedMessage.ColorSegment
---@field type 'color' The type of the segment.
---@field color omi.ColorTable<integer> The color to use.

---@class ParsedMessage.IconSegment
---@field type 'icon' The type of the segment.
---@field icon string The icon name

---@class ParsedMessage.TextSegment
---@field type 'text' The type of the segment.
---@field text string The parsed text.

---@class ParsedMessage.MentionSegment
---@field type 'mention' The type of the segment.
---@field text string The mention text.


---@alias ParsedMessageSegment
---| ParsedMessage.ColorSegment
---| ParsedMessage.IconSegment
---| ParsedMessage.TextSegment
---| ParsedMessage.MentionSegment

--#endregion
