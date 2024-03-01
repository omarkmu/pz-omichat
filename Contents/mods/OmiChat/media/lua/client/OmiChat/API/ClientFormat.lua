---Client API functionality related to formatting, encoding, and decoding chat messages.

local getTexture = getTexture
local format = string.format
local concat = table.concat
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
require 'OmiChat/Component/MimicMessage'

local utils = OmiChat.utils
local Option = OmiChat.Option
local MimicMessage = OmiChat.MimicMessage

local _ChatMessage = __classmetatables[ChatMessage.class].__index
local _ChatBase = __classmetatables[ChatBase.class].__index

local _getTextWithPrefix = _ChatMessage.getTextWithPrefix
local _getChatTitleID = _ChatBase.getTitleID
local _getChatType = _ChatBase.getType

local overheadChatTypes = {
    say = true,
    shout = true,
    radio = true,
}


---Returns whether name colors should be used given message info.
---@param info omichat.MessageInfo
---@return boolean
local function shouldUseNameColor(info)
    if not OmiChat.getNameColorsEnabled() then
        return false
    end

    local tokens = {
        author = info.tokens.author,
        authorRaw = info.tokens.authorRaw,
        chatType = info.chatType,
        name = info.tokens.name,
        nameRaw = info.tokens.nameRaw,
        stream = info.tokens.stream,
    }

    return utils.testPredicate(Option.PredicateUseNameColor, tokens, tostring(info.message:getDatetime()))
end

---Applies the narrative style given an input and stream.
---@param input string
---@param stream omichat.StreamInfo
---@param tokens table?
---@return string
local function applyNarrativeStyle(input, stream, tokens)
    tokens = tokens and utils.copy(tokens) or {}
    tokens.input = input
    tokens.chatType = stream:getChatType()
    tokens.stream = stream:getIdentifier()

    if not utils.testPredicate(Option.PredicateUseNarrativeStyle, tokens) then
        return input
    end

    local original = input
    input = utils.interpolate(Option.FilterNarrativeStyle, tokens)
    if input == '' then
        return original
    end

    local seed = getTimestampMs()
    local dialogueTag = utils.interpolate(Option.FormatNarrativeDialogueTag, tokens, seed)
    if dialogueTag == '' then
        return original
    end

    local prefix, suffix
    input, prefix, suffix = utils.getInternalText(input) -- get the actual end, not an invisible character
    if not input:match('%p$') then
        local punctuation = utils.interpolate(Option.FormatNarrativePunctuation, tokens, seed)
        if punctuation then
            input = input .. punctuation
        end
    end

    dialogueTag = utils.wrapStringArgument(dialogueTag, 21)
    input = utils.wrapStringArgument(concat { prefix, input, suffix }, 22)
    local combined = format('%s, "%s"', dialogueTag, input)

    local formatter = OmiChat.getFormatter('narrative')
    return formatter:format(combined)
end


---Applies format options from a message information table.
---This mutates `info`.
---@param info omichat.MessageInfo
---@return boolean success If false, the information table is invalid.
function OmiChat.applyFormatOptions(info)
    local msg = info.content
    if not msg or not info.format then
        return false
    end

    local meta = info.meta
    local options = info.formatOptions
    local message = info.message
    local dt = tostring(info.message:getDatetime())
    local seed = dt

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
            info.timestamp = utils.interpolate(Option.FormatTimestamp, {
                chatType = info.chatType,
                stream = info.tokens.stream,
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
            }, seed)
        end
    end

    info.language = utils.interpolate(Option.FormatLanguage, {
        chatType = info.chatType,
        stream = info.tokens.stream,
        languageRaw = info.tokens.languageRaw,
        language = info.tokens.language,
        unknownLanguage = info.tokens.unknownLanguage,
    })

    if options.showTitle then
        info.tag = utils.interpolate(Option.FormatTag, {
            chatType = info.chatType,
            stream = info.tokens.stream,
            tag = getText(info.titleID),
        }, seed)
    end

    local icon = utils.interpolate(Option.FormatIcon, {
        chatType = info.chatType,
        stream = info.tokens.stream,
        icon = meta.icon,
        adminIcon = meta.adminIcon,
    }, seed)

    if icon and getTexture(icon) then
        local size = 14
        if options.font == 'small' then
            size = 12
        elseif options.font == 'large' then
            size = 16
        end

        info.tokens.iconRaw = icon
        info.tokens.icon = string.format(' <IMAGE:%s,%d,%d> ', icon, size + 1, size)
    end

    local hasNameColor = meta.nameColor or Option.EnableSpeechColorAsDefaultNameColor
    if hasNameColor and shouldUseNameColor(info) then
        local colorToUse = meta.nameColor or Option:getDefaultColor('name', message:getAuthor())
        local nameColor = utils.toChatColor(colorToUse, true)

        if nameColor ~= '' then
            info.tokens.name = concat {
                nameColor,
                info.tokens.name,
                ' <POPRGB> ',
            }
            info.tokens.author = concat {
                nameColor,
                info.tokens.author,
                ' <POPRGB> ',
            }
        end
    end

    msg = utils.trim(msg)
    if not options.color then
        local color
        if options.useDefaultChatColor then
            if message:isFromDiscord() then
                color = OmiChat.getColorOrDefault('discord')
            else
                color = OmiChat.getColorOrDefault(info.chatType)
            end
        end

        options.color = color or {
            r = info.textColor:getRed(),
            g = info.textColor:getGreen(),
            b = info.textColor:getBlue(),
        }
    end

    info.tokens.message = msg
    return true
end

---Applies chat styles to a stream's input.
---@param input string
---@param stream omichat.StreamInfo
---@param tokens table?
---@return string
function OmiChat.applyStyles(input, stream, tokens)
    return applyNarrativeStyle(input, stream, tokens)
end

---Applies message transforms.
---@param info omichat.MessageInfo
function OmiChat.applyTransforms(info)
    for i = 1, #OmiChat._transformers do
        local transformer = OmiChat._transformers[i]
        if transformer.transform and transformer:transform(info) == true then
            break
        end
    end
end

---Applies message transforms and format options to a message.
---Returns information about the parsed message.
---If building the message fails, `nil` is returned and the original
---text is returned instead.
---@see omichat.api.client.buildMessageText
---@see omichat.api.client.buildMessageTextFromInfo
---@param message omichat.Message
---@param skipFormatting boolean?
---@return omichat.MessageInfo?
---@return string
function OmiChat.buildMessageInfo(message, skipFormatting)
    local instance = ISChat.instance or {}

    local text
    local titleID
    if utils.isinstance(message, MimicMessage) then
        ---@cast message omichat.MimicMessage
        text = message:getTextWithPrefixBase()
        titleID = message:getTitleID()
    else
        -- `getText` doesn't handle color & image formatting.
        -- would just use that otherwise
        ---@cast message ChatMessage
        local chat = message:getChat()
        text = _getTextWithPrefix(message)
        titleID = _getChatTitleID(chat)
    end

    local chatType = OmiChat.getMessageChatType(message)
    local author = message:getAuthor() or ''
    local textColor = message:getTextColor()
    local meta = OmiChat.decodeMessageTag(message:getCustomTag())

    local streamName = chatType
    if chatType == 'whisper' then
        streamName = 'private'
    elseif message:isFromDiscord() then
        streamName = 'discord'
    end

    ---@type omichat.MessageInfo
    local info = {
        message = message,
        meta = meta,
        rawText = text,
        author = author,
        titleID = titleID,
        chatType = chatType,
        textColor = textColor,

        context = {},
        tokens = {
            stream = streamName,
            author = utils.escapeRichText(author),
            authorRaw = author,
            name = meta.name or utils.escapeRichText(author),
            nameRaw = meta.name or utils.escapeRichText(author),
        },
        formatOptions = {
            font = instance.chatFont,
            showTitle = instance.showTitle,
            showTimestamp = instance.showTimestamp,
            useDefaultChatColor = true,
        },
    }

    OmiChat.applyTransforms(info)
    if not skipFormatting and not OmiChat.applyFormatOptions(info) then
        return nil, text
    end

    return info, text
end

---Builds the prefixed text for a message.
---@param message omichat.Message
---@return string
function OmiChat.buildMessageText(message)
    local info, original = OmiChat.buildMessageInfo(message)
    local result = info and OmiChat.buildMessageTextFromInfo(info)
    return result or original
end

---Builds the prefixed text for a message from message information.
---@param info omichat.MessageInfo
---@return string?
function OmiChat.buildMessageTextFromInfo(info)
    if not info or not info.format then
        return
    end

    local seed = tostring(info.message:getDatetime())
    return concat {
        utils.toChatColor(info.formatOptions.color),
        '<SIZE:', info.formatOptions.font or 'medium', '> ',
        utils.interpolate(Option.ChatFormatFull, {
            chatType = info.chatType,
            stream = info.tokens.stream,
            icon = info.tokens.icon,
            iconRaw = info.tokens.iconRaw,
            language = info.language,
            timestamp = info.timestamp,
            tag = info.tag,
            content = utils.interpolate(info.format, info.tokens, seed),
        }, seed),
    }
end

---Returns the roleplay language encoded in message content.
---@param message omichat.Message
---@return string?
function OmiChat.decodeLanguage(message)
    local text = message:getText()
    local formatter = OmiChat.getFormatter('language')

    local languageId = 1
    if formatter:isMatch(text) then
        -- found a language → decode it. transformer will handle cleanup
        text = formatter:read(text)
        local encodedId = utils.decodeInvisibleCharacter(text)
        if encodedId >= 1 and encodedId <= 32 then
            languageId = encodedId
        end
    end

    return OmiChat.getRoleplayLanguageFromID(languageId)
end

---Decodes message metadata from an encoded tag.
---@param tag string
---@return omichat.MessageMetadata
function OmiChat.decodeMessageTag(tag)
    if not tag or tag == '' then
        return {}
    end

    local _, decoded = utils.json.tryDecode(tag)
    if type(decoded) ~= 'table' then
        return {}
    end

    return {
        suppressed = decoded.ocSuppressed,
        language = decoded.ocLanguage,
        name = decoded.ocName,
        nameColor = utils.stringToColor(decoded.ocNameColor),
        icon = decoded.ocIcon,
        adminIcon = decoded.ocAdminIcon,
    }
end

---Encodes the provided text with information about the current roleplay language.
---@param text string The text to encode.
---@param playEmoteForSigned boolean If true, this will play a random emote for signed languages.
---@return string text
---@return string? language
function OmiChat.encodeLanguage(text, playEmoteForSigned)
    local currentLanguage = OmiChat.getCurrentRoleplayLanguage()
    local langId = currentLanguage and OmiChat.getRoleplayLanguageID(currentLanguage)
    if not currentLanguage or not langId or currentLanguage == OmiChat.getDefaultRoleplayLanguage() then
        return text
    end

    local trimmed = utils.trimleft(text)
    if #trimmed == 0 then
        -- avoid creating empty messages
        return ''
    end

    local encoded = utils.encodeInvisibleCharacter(langId) .. trimmed
    local formatted = OmiChat.getFormatter('language'):format(encoded)

    playEmoteForSigned = playEmoteForSigned and OmiChat.getSignEmotesEnabled()
    if playEmoteForSigned and OmiChat.isRoleplayLanguageSigned(currentLanguage) then
        local player = getSpecificPlayer(0)
        if player then
            player:playEmote(OmiChat.getSignLanguageEmote(text))
        end
    end

    return formatted, currentLanguage
end

---Encodes message information including chat name and colors into a string.
---@param message omichat.Message
---@return string
function OmiChat.encodeMessageTag(message)
    local author = message:getAuthor() ---@type string?
    if author == '' then
        author = nil
    end

    local color = author and OmiChat.getNameColorInChat(author)
    local useAdminIcon = OmiChat.getFormatter('adminIcon'):isMatch(message:getText())
    local success, encoded = utils.json.tryEncode {
        ocSuppressed = false,
        ocLanguage = OmiChat.decodeLanguage(message),
        ocName = OmiChat.getNameInChatRichText(author, OmiChat.getMessageChatType(message)),
        ocNameColor = color and utils.colorToHexString(color) or nil,
        ocIcon = author and OmiChat.getChatIcon(author) or nil,
        ocAdminIcon = (author and useAdminIcon) and OmiChat.getAdminChatIcon(author) or nil,
    }

    if not success then
        return ''
    end

    return encoded
end

---Prepares text for sending to chat.
---@param args FormatArgs
---@return string
function OmiChat.formatForChat(args)
    local stream = args.stream or args.formatterName or args.chatType
    local username = args.username or utils.getPlayerUsername()
    local name = args.name or OmiChat.getNameInChat(username, args.chatType)

    local text = utils.interpolate(Option.FilterChatInput, {
        input = args.text,
        username = username,
        name = name,
        stream = stream,
    })

    if #utils.trim(text) == 0 then
        -- avoid empty messages
        return ''
    end

    local tokens = args.tokens and utils.copy(args.tokens) or {}

    -- apply styles
    local streamInfo = OmiChat.getChatStreamByIdentifier(stream)
    text = streamInfo and OmiChat.applyStyles(text, streamInfo, tokens) or text

    -- encode rp language
    local language
    if OmiChat.canUseRoleplayLanguage(stream, text) then
        text, language = OmiChat.encodeLanguage(text, args.playSignedEmote)
    end

    tokens.name = name
    tokens.username = username
    tokens.stream = stream
    tokens.languageRaw = language
    tokens.language = language and utils.getTranslatedLanguageName(language)

    -- apply format
    local formatterName = args.formatterName
    if not formatterName and overheadChatTypes[args.chatType] then
        formatterName = 'overheadOther'
    end

    local formatter = formatterName and OmiChat.getFormatter(formatterName)
    text = formatter and formatter:format(text, tokens) or text

    -- add indicator for admin icon
    if isAdmin() and OmiChat.getAdminOption('show_icon') then
        local adminIconFormatter = OmiChat.getFormatter('adminIcon')
        text = adminIconFormatter:wrap(text)
    end

    tokens.prefix = utils.trimleft(utils.interpolate(Option.FormatOverheadPrefix, tokens))

    -- mark as echo message
    if args.isEcho then
        local echoFormatter = OmiChat.getFormatter('echo')
        text = echoFormatter:format(text, tokens)
    end

    local overheadFormatter = OmiChat.getFormatter('overheadFull')
    text = overheadFormatter:format(text, tokens)

    -- encode online ID for radio
    local player = getSpecificPlayer(0)
    if player then
        local id = utils.encodeInvisibleInt(player:getOnlineID())
        text = OmiChat.getFormatter('onlineID'):format(id) .. text
    end

    return text
end

---Gets a named formatter.
---@param name omichat.FormatterName
---@return omichat.MetaFormatter
function OmiChat.getFormatter(name)
    return OmiChat._formatters[name]
end

---Returns the chat type of a chat message.
---@param message omichat.Message
---@return string
function OmiChat.getMessageChatType(message)
    if utils.isinstance(message, MimicMessage) then
        ---@cast message omichat.MimicMessage
        return message:getChatType()
    end

    ---@cast message ChatMessage
    return tostring(_getChatType(message:getChat()))
end
