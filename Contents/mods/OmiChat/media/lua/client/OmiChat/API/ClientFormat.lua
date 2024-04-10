---Client API functionality related to formatting, encoding, and decoding chat messages.

local getTexture = getTexture
local format = string.format
local concat = table.concat
local match = string.match
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
require 'OmiChat/Component/MimicMessage'

local utils = OmiChat.utils
local config = OmiChat.config
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
    tokens.input = tokens.input or input
    tokens.chatType = tokens.chatType or stream:getChatType()
    tokens.stream = tokens.stream or stream:getIdentifier()

    local original = input
    if not utils.testPredicate(Option.PredicateUseNarrativeStyle, tokens) then
        return input
    end

    local dialogueTag
    local patt = utils.trim(Option.PatternNarrativeCustomTag)
    if patt ~= '' then
        local internal, prefix, suffix = utils.getInternalText(input)

        local success, tag, remainder = pcall(match, internal, patt)
        if success and tag and remainder then
            dialogueTag = tostring(tag)
            tokens.input = prefix .. tostring(remainder) .. suffix
        elseif not success then
            utils.logError('invalid string pattern set for PatternNarrativeCustomTag')
        end
    end

    input = utils.interpolate(Option.FilterNarrativeStyle, tokens)
    if input == '' then
        return original
    end

    local seed = input
    dialogueTag = dialogueTag or utils.interpolate(Option.FormatNarrativeDialogueTag, tokens, seed)
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

    dialogueTag = utils.wrapStringArgument(dialogueTag, config.NARRATIVE_TAG)
    input = utils.wrapStringArgument(prefix .. input .. suffix, config.NARRATIVE_TEXT)
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

    if shouldUseNameColor(info) then
        local hasNameColor = meta.nameColor or Option.EnableSpeechColorAsDefaultNameColor
        local hasRecipientNameColor = meta.recipientNameColor or Option.EnableSpeechColorAsDefaultNameColor
        if hasNameColor then
            local colorToUse = meta.nameColor or Option:getDefaultColor('name', message:getAuthor())
            local nameColor = utils.toChatColor(colorToUse, true)

            if nameColor ~= '' then
                utils.addMessageTagValue(message, 'ocNameColor', utils.colorToHexString(colorToUse))
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

        if hasRecipientNameColor and info.tokens.recipient then
            local colorToUse = meta.recipientNameColor or Option:getDefaultColor('name', info.tokens.recipient)
            meta.recipientNameColor = colorToUse
            local nameColor = utils.toChatColor(colorToUse, true)

            if nameColor ~= '' then
                utils.addMessageTagValue(message, 'ocRecipientNameColor', utils.colorToHexString(colorToUse))
                info.tokens.recipientName = concat {
                    nameColor,
                    info.tokens.recipientName,
                    ' <POPRGB> ',
                }
                info.tokens.recipient = concat {
                    nameColor,
                    info.tokens.recipient,
                    ' <POPRGB> ',
                }
            end
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
    local displayAsAdmin = OmiChat.getFormatter('adminIcon'):isMatch(message:getText())

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
            admin = displayAsAdmin and '1' or nil,
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
    local tokens = {
        admin = info.tokens.admin,
        chatType = info.chatType,
        echo = info.tokens.echo,
        stream = info.tokens.stream,
        icon = info.tokens.icon,
        iconRaw = info.tokens.iconRaw,
        language = info.language,
        timestamp = info.timestamp,
        tag = info.tag,
        content = utils.interpolate(info.format, info.tokens, seed),
    }

    tokens.prefix = utils.trim(utils.interpolate(Option.FormatChatPrefix, tokens, seed))

    return concat {
        utils.toChatColor(info.formatOptions.color),
        '<SIZE:', info.formatOptions.font or 'medium', '> ',
        utils.interpolate(Option.ChatFormatFull, tokens, seed),
    }
end

---Returns the roleplay language encoded in message content.
---@param message omichat.Message | string A message object or string to read.
---@return string?
function OmiChat.decodeLanguage(message)
    if type(message) ~= 'string' then
        message = message:getText()
    end

    local formatter = OmiChat.getFormatter('language')
    message = formatter:read(message)
    if not message then
        return
    end

    local languageId = utils.decodeInvisibleInt(message)
    if not languageId or languageId < 1 or languageId > OmiChat.config:maxDefinedLanguages() then
        return
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
        recipientNameColor = utils.stringToColor(decoded.ocRecipientNameColor),
        icon = decoded.ocIcon,
        adminIcon = decoded.ocAdminIcon,
    }
end

---Encodes the provided text with information about the given roleplay language.
---@param text string The text to encode.
---@param language string The language to encode.
---@return string text
---@return string? language
function OmiChat.encodeLanguage(text, language)
    local langId = OmiChat.getRoleplayLanguageID(language)
    if not langId or #utils.trim(text) == 0 then
        return text
    end

    local encoded = utils.encodeInvisibleInt(langId) .. text
    return OmiChat.getFormatter('language'):format(encoded)
end

---Encodes message information including chat name and colors into a string.
---@param message omichat.Message
---@return string
function OmiChat.encodeMessageTag(message)
    local author = message:getAuthor() ---@type string?
    if author == '' then
        author = nil
    end

    local text = message:getText()
    local useAdminIcon = OmiChat.getFormatter('adminIcon'):isMatch(text)

    local iconFormatter = OmiChat.getFormatter('messageIcon')
    local encodedIcon = iconFormatter:read(text)
    local icon = encodedIcon and utils.decodeInvisibleString(encodedIcon)

    if icon and not getTexture(icon) then
        icon = nil
    elseif icon then
        -- message-level icons suppress admin icon
        useAdminIcon = false
    end

    local color = author and OmiChat.getNameColorInChat(author)
    local success, encoded = utils.json.tryEncode {
        ocSuppressed = false,
        ocLanguage = OmiChat.decodeLanguage(message),
        ocName = OmiChat.getNameInChatRichText(author, OmiChat.getMessageChatType(message)),
        ocNameColor = color and utils.colorToHexString(color) or nil,
        ocIcon = icon or (author and OmiChat.getChatIcon(author)) or nil,
        ocAdminIcon = (author and useAdminIcon) and OmiChat.getAdminChatIcon(author) or nil,
    }

    if not success then
        return ''
    end

    return encoded
end

---Prepares text for sending to chat.
---@param args omichat.FormatArgs
---@return omichat.FormatResult
function OmiChat.formatForChat(args)
    local stream = args.stream or args.formatterName or args.chatType
    local username = args.username or utils.getPlayerUsername()
    local name = args.name or OmiChat.getNameInChat(username, args.chatType)
    local text, before, after = utils.getInternalText(args.text)

    local tokens = args.tokens and utils.copy(args.tokens) or {}
    tokens.chatType = args.chatType
    tokens.input = text
    tokens.username = username
    tokens.name = name
    tokens.stream = stream
    tokens.echo = args.isEcho and '1' or nil

    -- check language
    local language
    local allowLanguage = args.language and utils.testPredicate(Option.PredicateAllowLanguage, tokens)
    if allowLanguage then
        language = args.language
        tokens.languageRaw = language
        tokens.language = language and utils.getTranslatedLanguageName(language)
    end

    -- filter and check input
    tokens.input = utils.interpolate(Option.FilterChatInput, tokens)

    tokens.error = ''
    tokens.errorID = ''
    local allowInput = #tokens.input > 0 and utils.testPredicate(Option.PredicateAllowChatInput, tokens)
    local err = utils.extractError(tokens)

    if not allowInput or err then
        return {
            text = '',
            error = err,
        }
    end

    tokens.input = before .. tokens.input .. after

    -- apply styles
    local streamInfo = OmiChat.getChatStreamByIdentifier(stream)
    tokens.input = streamInfo and OmiChat.applyStyles(tokens.input, streamInfo, tokens) or tokens.input

    -- encode language
    if language then
        tokens.input = OmiChat.encodeLanguage(tokens.input, language)
    end

    -- apply format
    local formatterName = args.formatterName
    if not formatterName and overheadChatTypes[args.chatType] then
        formatterName = 'overheadOther'
    end

    local formatter = formatterName and OmiChat.getFormatter(formatterName)
    tokens.input = formatter and formatter:format(tokens.input, tokens) or tokens.input

    -- add indicator for admin icon
    if isAdmin() and OmiChat.getAdminOption('show_icon') then
        local adminIconFormatter = OmiChat.getFormatter('adminIcon')
        tokens.input = adminIconFormatter:wrap(tokens.input)
    end

    -- mark as echo message
    if args.isEcho then
        local echoFormatter = OmiChat.getFormatter('echo')
        tokens.input = echoFormatter:format(tokens.input, tokens)
    end

    -- apply full overhead format
    local overheadFormatter = OmiChat.getFormatter('overheadFull')
    tokens.prefix = utils.trimleft(utils.interpolate(Option.FormatOverheadPrefix, tokens))
    tokens.input = overheadFormatter:format(tokens.input, tokens)

    -- encode message icon
    if args.icon then
        local textureName
        if getTexture(args.icon) then
            textureName = args.icon
        else
            textureName = utils.getTextureNameFromIcon(args.icon)
        end

        if textureName then
            local iconFormatter = OmiChat.getFormatter('messageIcon')
            local encodedIcon = iconFormatter:wrap(utils.encodeInvisibleString(textureName))
            tokens.input = tokens.input .. encodedIcon
        end
    end

    -- encode online ID for radio
    local player = getSpecificPlayer(0)
    if player then
        local id = utils.encodeInvisibleInt(player:getOnlineID())
        tokens.input = OmiChat.getFormatter('onlineID'):format(id) .. tokens.input
    end

    return {
        text = tokens.input,
        allowLanguage = allowLanguage,
    }
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
