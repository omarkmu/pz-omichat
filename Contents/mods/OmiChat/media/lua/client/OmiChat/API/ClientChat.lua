---Client API functionality related to manipulating the chat.

local MimicMessage = require 'OmiChat/Component/MimicMessage'

local getText = getText
local getTexture = getTexture
local min = math.min
local max = math.max
local format = string.format
local concat = table.concat
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
OmiChat.MimicMessage = MimicMessage


local utils = OmiChat.utils
local config = OmiChat.config
local Option = OmiChat.Option
local IconPicker = OmiChat.IconPicker
local StreamInfo = OmiChat.StreamInfo

local _ChatBase = __classmetatables[ChatBase.class].__index
local _ChatMessage = __classmetatables[ChatMessage.class].__index

-- can't call directly on ChatBase subclasses, so have to grab these like this
local _getTextWithPrefix = _ChatMessage.getTextWithPrefix
local _getChatTitleID = _ChatBase.getTitleID
local _getChatType = _ChatBase.getType

local signLanguageEmotes = {
    'yes',
    'no',
    'signalok',
    'wavehi',
    'wavehi02',
    'wavebye',
    'saluteformal',
    'salutecasual',
    'comehere',
    'comehere02',
    'followme',
    'thumbsup',
    'thumbsdown',
    'thankyou',
    'insult',
    'stop',
    'stop02',
    'shrug',
    'undecided',
    'freeze',
    'comefront',
}
local overheadChatTypes = {
    say = true,
    shout = true,
    radio = true,
}


---Creates or removes the icon button and picker from the chat box based on sandbox options.
local function addOrRemoveIconComponents()
    local instance = ISChat.instance
    if not instance then
        return
    end

    local add = Option.EnableIconPicker
    local iconPicker = instance.iconPicker
    local iconButton = instance.iconButton
    local epIncludeMisc = iconPicker and iconPicker.includeUnknownAsMiscellaneous
    local includeMisc = Option.EnableMiscellaneousIcons
    if iconPicker and epIncludeMisc ~= includeMisc then
        iconPicker.includeUnknownAsMiscellaneous = includeMisc
        iconPicker:updateIcons()
    end

    if add and iconButton then
        return
    end

    if not add and not iconButton then
        return
    end

    if add then
        local size = math.floor(instance.textEntry.height * 0.75)
        iconButton = ISButton:new(
            instance.width - size * 1.25 - 2.5,
            instance.textEntry.y + instance.textEntry.height * 0.5 - size * 0.5 + 1,
            size,
            size,
            '',
            instance,
            ISChat.onIconButtonClick
        )

        instance.textEntry.width = instance.textEntry.width - size * 1.5
        instance.textEntry.javaObject:setWidth(instance.textEntry.width)

        iconButton.anchorRight = true
        iconButton.anchorBottom = true
        iconButton.anchorLeft = false
        iconButton.anchorTop = false

        iconButton:initialise()
        iconButton.borderColor.a = 0
        iconButton.backgroundColor.a = 0
        iconButton.backgroundColorMouseOver.a = 0
        iconButton:setImage(getTexture('Item_PlushSpiffo'))
        iconButton:setTextureRGBA(0.3, 0.3, 0.3, 1)
        iconButton:setUIName('chat icon button')
        instance:addChild(iconButton)

        iconButton:bringToTop()

        iconPicker = IconPicker:new(0, 0, instance, ISChat.onIconClick)
        iconPicker.exclude = OmiChat._iconsToExclude
        iconPicker.includeUnknownAsMiscellaneous = OmiChat.Option.EnableMiscellaneousIcons

        iconPicker:initialise()
        iconPicker:addToUIManager()
        iconPicker:setVisible(false)

        instance.iconButton = iconButton
        instance.iconPicker = iconPicker

        return
    end

    instance.textEntry.width = instance:getWidth() - instance.inset * 2
    instance.textEntry.javaObject:setWidth(instance.textEntry.width)

    if iconButton then
        instance:removeChild(iconButton)
        iconButton:setVisible(false)
        iconButton:removeFromUIManager()
        iconButton = nil
    end

    if iconPicker then
        iconPicker:setVisible(false)
        iconPicker:removeFromUIManager()
        iconPicker = nil
    end
end

---Creates or updates built-in formatters.
local function updateFormatters()
    for info in config:formatters() do
        local name = info.name
        local optName = config:getOverheadFormatOption(name) or info.overheadFormatOpt
        local fmt = optName and Option[optName] or '$1'
        if OmiChat._formatters[name] then
            OmiChat._formatters[name]:setFormatString(fmt)
        else
            OmiChat._formatters[name] = OmiChat.MetaFormatter:new(info.formatID, { format = fmt })
        end
    end
end

---Updates streams based on sandbox options.
local function updateStreams()
    local vanillaWhisper
    local exists = {}
    local streamConfigs = OmiChat._vanillaStreamConfigs

    for i = 1, #ISChat.allChatStreams do
        local stream = ISChat.allChatStreams[i]
        if stream.omichat then
            local data = config:getCustomStreamInfo(stream.name)
            if stream.name == 'private' then
                vanillaWhisper = stream
            elseif stream.name == 'whisper' then
                if stream.omichat.context and stream.omichat.context.ocIsLocalWhisper then
                    ---@cast data omichat.CustomStreamInfo
                    exists[data.name] = stream
                else
                    vanillaWhisper = stream
                end
            elseif data then
                exists[data.name] = stream
            end
        elseif stream.name == 'whisper' then
            vanillaWhisper = stream
            vanillaWhisper.omichat = streamConfigs.private
        elseif streamConfigs[stream.name] then
            stream.omichat = streamConfigs[stream.name]
        end
    end

    for data in config:chatStreams() do
        local stream = OmiChat._customChatStreams[data.name]
        if not exists[data.name] and stream then
            OmiChat.addStreamBefore(stream, vanillaWhisper)
        end
    end

    if not vanillaWhisper then
        return
    end

    local useLocalWhisper = OmiChat.isCustomStreamEnabled('whisper')
    if useLocalWhisper and vanillaWhisper.name == 'whisper' then
        -- modify /whisper to be /pm
        vanillaWhisper.name = 'private'
        vanillaWhisper.command = '/pm '
        vanillaWhisper.shortCommand = '/pm '
    elseif not useLocalWhisper and vanillaWhisper.name == 'private' then
        -- revert /pm to /whisper
        vanillaWhisper.name = 'whisper'
        vanillaWhisper.command = '/whisper '
        vanillaWhisper.shortCommand = '/w '
    end
end

---Returns whether name colors should be used given message info.
---@param info omichat.MessageInfo
---@return boolean
local function shouldUseNameColor(info)
    if not OmiChat.getNameColorsEnabled() then
        return false
    end

    local tokens = {
        author = info.substitutions.author,
        authorRaw = info.substitutions.authorRaw,
        chatType = info.chatType,
        name = info.substitutions.name,
        nameRaw = info.substitutions.nameRaw,
        stream = info.substitutions.stream,
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
                stream = info.substitutions.stream,
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
        stream = info.substitutions.stream,
        languageRaw = info.substitutions.languageRaw,
        language = info.substitutions.language,
        unknownLanguage = info.substitutions.unknownLanguage,
    })

    if options.showTitle then
        info.tag = utils.interpolate(Option.FormatTag, {
            chatType = info.chatType,
            stream = info.substitutions.stream,
            tag = getText(info.titleID),
        }, seed)
    end

    local icon = utils.interpolate(Option.FormatIcon, {
        chatType = info.chatType,
        stream = info.substitutions.stream,
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

        info.substitutions.iconRaw = icon
        info.substitutions.icon = string.format(' <IMAGE:%s,%d,%d> ', icon, size + 1, size)
    end

    local hasNameColor = meta.nameColor or Option.EnableSpeechColorAsDefaultNameColor
    if hasNameColor and shouldUseNameColor(info) then
        local colorToUse = meta.nameColor or Option:getDefaultColor('name', message:getAuthor())
        local nameColor = utils.toChatColor(colorToUse, true)

        if nameColor ~= '' then
            info.substitutions.name = concat {
                nameColor,
                info.substitutions.name,
                ' <POPRGB> ',
            }
            info.substitutions.author = concat {
                nameColor,
                info.substitutions.author,
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

    info.substitutions.message = msg
    return true
end

---Applies overhead chat styles to a stream's input.
---@param input string
---@param stream omichat.StreamInfo
---@param tokens table?
---@return string
function OmiChat.applyOverheadStyles(input, stream, tokens)
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
        substitutions = {
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
            stream = info.substitutions.stream,
            icon = info.substitutions.icon,
            iconRaw = info.substitutions.iconRaw,
            language = info.language,
            timestamp = info.timestamp,
            tag = info.tag,
            content = utils.interpolate(info.format, info.substitutions, seed),
        }, seed),
    }
end

---Checks whether a given stream and message text can use roleplay languages.
---@param stream string
---@param text string
---@return boolean
function OmiChat.canUseRoleplayLanguage(stream, text)
    return utils.testPredicate(Option.PredicateAllowLanguage, {
        input = text,
        stream = stream,
    })
end

---Determines stream information given a chat command.
---@param command string The input text.
---@param includeCommands boolean? If true, commands should be included. Defaults to true.
---@return omichat.StreamInfo? #Information about the stream.
---@return string #The text following the command in the input.
---@return string? #The command or short command that was used.
function OmiChat.chatCommandToStream(command, includeCommands)
    if not command or command == '' then
        return nil, ''
    end

    if includeCommands == nil then
        includeCommands = true
    end

    local chatStream
    local chatCommand

    local i = 1
    local numStreams = #ISChat.allChatStreams
    local numCommands = #OmiChat._commandStreams
    while i <= numStreams + numCommands do
        local stream
        if i <= numStreams then
            stream = ISChat.allChatStreams[i]
        else
            if not includeCommands then
                break
            end

            stream = OmiChat._commandStreams[i - numStreams]
        end

        chatCommand = nil
        if utils.startsWith(command, stream.command) then
            chatCommand = stream.command
            command = command:sub(#chatCommand)
        elseif utils.startsWith(command, stream.shortCommand) then
            chatCommand = stream.shortCommand
            command = command:sub(#chatCommand)
        elseif stream.omichat and stream.omichat.isCommand and command == utils.trim(stream.command) then
            chatCommand = command
            command = ' '
        end

        local aliases = stream.omichat and stream.omichat.aliases
        if not chatCommand and aliases then
            for j = 1, #aliases do
                local aliasCommand = aliases[j]
                if utils.startsWith(command, aliasCommand) then
                    chatCommand = aliasCommand
                    command = command:sub(#chatCommand)
                    break
                end
            end
        end

        if chatCommand then
            chatStream = stream
            break
        end

        i = i + 1
    end

    local streamInfo
    if chatStream then
        streamInfo = StreamInfo:new(chatStream)
    end

    return streamInfo, command, chatCommand
end

---Retrieves a stream name given a chat command.
---@param command string A chat stream's command, with the leading slash.
---@param includeCommands boolean? If true, commands should be included.
---@return string? #The name of the chat stream, or `nil` if not found.
function OmiChat.chatCommandToStreamName(command, includeCommands)
    local stream = OmiChat.chatCommandToStream(command, includeCommands)
    if stream then
        return stream:getName()
    end
end

---Clears all of the current chat messages.
function OmiChat.clearMessages()
    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return
    end

    for i = 1, #tabs do
        local chatText = tabs[i]
        chatText.chatMessages = {}
        chatText.chatTextLines = {}
        chatText.text = ''
        chatText:paginate()
    end
end

---Cycles to the next chat stream.
---This is used with onSwitchStream.
---@param target string? The name of a target stream to switch to instead of the next stream.
---@return string #The command of the new current stream.
function OmiChat.cycleStream(target)
    local curChatText = ISChat.instance.chatText
    local chatStreams = curChatText.chatStreams

    local targetID
    local streamID = curChatText.streamID

    for _ = 0, #chatStreams do
        streamID = streamID % #chatStreams + 1
        local stream = chatStreams[streamID]

        if not target or stream.name == target then
            if stream.omichat then
                local info = StreamInfo:new(stream)
                if info:isEnabled() then
                    targetID = streamID
                    break
                end
            elseif checkPlayerCanUseChat(stream.command) then
                targetID = streamID
                break
            end
        end
    end

    if targetID then
        curChatText.streamID = targetID
    end

    return curChatText.chatStreams[curChatText.streamID].command
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
        ocLanguage = OmiChat.getMessageLanguage(message),
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
---@param args omichat.FormatForChatArgs
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

    -- apply overhead styles
    local streamInfo = OmiChat.getChatStreamByIdentifier(stream)
    text = streamInfo and OmiChat.applyOverheadStyles(text, streamInfo, tokens) or text

    -- encode rp language
    local language
    if OmiChat.canUseRoleplayLanguage(stream, text) then
        text, language = OmiChat.getLanguageEncodedText(text, args.playSignedEmote)
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

---Retrieves a stream given its identifier.
---@param identifier string
---@return omichat.StreamInfo?
function OmiChat.getChatStreamByIdentifier(identifier)
    for i = 1, #ISChat.allChatStreams do
        local info = StreamInfo:new(ISChat.allChatStreams[i])
        if info:getIdentifier() == identifier then
            return info
        end
    end
end

---Gets the command associated with a color category.
---@param cat omichat.ColorCategory
---@return string
function OmiChat.getColorCategoryCommand(cat)
    if cat == 'private' then
        return OmiChat.isCustomStreamEnabled('whisper') and '/pm' or '/whisper'
    end

    if cat == 'general' then
        return '/all'
    end

    if cat == 'shout' then
        return '/yell'
    end

    return '/' .. cat
end

---Returns information about the default stream for a given tab ID.
---@param tabID integer
---@return omichat.StreamInfo?
function OmiChat.getDefaultTabStream(tabID)
    local default = ISChat.defaultTabStream[tabID]
    if default then
        return StreamInfo:new(default)
    end
end

---Returns a playable emote given an emote name.
---Returns `nil` if there is not an emote associated with the emote name.
---@param emote string
---@return string?
function OmiChat.getEmote(emote)
    local value = OmiChat._emotes[emote]
    if type(value) == 'function' then
        return value(emote)
    end

    return value
end

---Returns the first emote found from an emote shortcut in the provided text.
---@param text string
---@return string? emote
---@return integer? start
---@return integer? finish
function OmiChat.getEmoteFromCommand(text)
    local startPos = 1
    while startPos < #text do
        local start, finish, whitespace, emote = text:find('(%s*)%.([%w_]+)', startPos)
        if not start then
            break
        end

        -- require whitespace unless the emote is at the start
        if start ~= 1 and #whitespace == 0 then
            emote = nil
        end

        local emoteToPlay = emote and OmiChat.getEmote(emote:lower())
        if type(emoteToPlay) == 'string' then
            return emoteToPlay, start, finish
        end

        startPos = finish + 1
    end
end

---Gets a named formatter.
---@param name omichat.FormatterName
---@return omichat.MetaFormatter
function OmiChat.getFormatter(name)
    return OmiChat._formatters[name]
end

---Gets the text that should display when clicking the info button.
---@param player IsoPlayer? The player to use to populate token values. If `nil`, this will be player 1.
---@return string
function OmiChat.getInfoRichText(player)
    player = player or getSpecificPlayer(0)
    if not player then
        return ''
    end

    local username = player:getUsername()
    local name = OmiChat.getNameInChatRichText(username, 'say')
    local tokens = name and OmiChat.getPlayerSubstitutions(player)
    if not name or not tokens then
        return ''
    end

    tokens.name = name
    return utils.interpolate(Option.FormatInfo, tokens, username)
end

---Encodes the provided text with information about the current roleplay language.
---@param text string The text to encode.
---@param playEmoteForSigned boolean If true, this will play a random emote for signed languages.
---@return string text
---@return string? language
function OmiChat.getLanguageEncodedText(text, playEmoteForSigned)
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

---Returns the roleplay language encoded in message content.
---@param message omichat.Message
---@return string?
function OmiChat.getMessageLanguage(message)
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

---Gets an emote meant to simulate sign language based on the given text.
---@param text string
---@return string
function OmiChat.getSignLanguageEmote(text)
    -- same text should map to same 'sign'
    local rand = newrandom()
    rand:seed(utils.trim(text:lower()))

    return signLanguageEmotes[rand:random(1, #signLanguageEmotes)]
end

---Suggests text based on the provided input text.
---@param text string
---@return omichat.Suggestion[]
function OmiChat.getSuggestions(text)
    if not text or text == '' then
        return {}
    end

    ---@type omichat.SuggestionInfo
    local info = {
        input = text,
        context = {},
        suggestions = {},
    }

    for i = 1, #OmiChat._suggesters do
        local suggester = OmiChat._suggesters[i]
        if suggester.suggest then
            suggester:suggest(info)
        end
    end

    return info.suggestions
end

---Hides the suggester box if it's currently visible.
function OmiChat.hideSuggesterBox()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox then
        suggesterBox:setVisible(false)
    end
end

---Returns an iterator over command stream info.
---@return fun(): omichat.StreamInfo?
function OmiChat.iterCommandStreams()
    local i = 0
    return function()
        i = i + 1
        local stream = OmiChat._commandStreams[i]
        if stream then
            return StreamInfo:new(stream)
        end
    end
end

---Redraws the current chat messages.
---@param doScroll boolean? Whether the chat should also be scrolled to the bottom. Defaults to true.
function OmiChat.redrawMessages(doScroll)
    if not ISChat.instance then
        return
    end

    for i = 1, #ISChat.instance.tabs do
        local chatText = ISChat.instance.tabs[i]
        local messages = chatText.chatMessages
        local newText = {}
        local newLines = {}

        local start = 1 + max(0, #messages - ISChat.maxLine - 1)
        for j = start, #messages do
            local text = messages[j]:getTextWithPrefix()

            newText[#newText + 1] = text
            newText[#newText + 1] = ' <LINE> '
            newLines[#newLines + 1] = text .. ' <LINE> '
        end

        newText[#newText] = nil
        chatText.chatTextLines = newLines
        chatText.text = concat(newText)

        chatText:paginate()
    end

    if doScroll ~= false then
        -- fix scroll position
        OmiChat.scrollToBottom()
    end
end

---Sets the scroll position of all chat tabs to the bottom.
function OmiChat.scrollToBottom()
    if not ISChat.instance or not ISChat.instance.tabs then
        return
    end

    for i = 1, #ISChat.instance.tabs do
        local tab = ISChat.instance.tabs[i]
        tab:setYScroll(-tab:getScrollHeight())
    end
end

---Sets the scroll position of all chat tabs to the top.
function OmiChat.scrollToTop()
    if not ISChat.instance or not ISChat.instance.tabs then
        return
    end

    for i = 1, #ISChat.instance.tabs do
        local tab = ISChat.instance.tabs[i]
        tab:setYScroll(0)
    end
end

---Sets whether the icon picker button is enabled.
---If the button is disabled, the icon picker component will also be hidden.
---@param enable boolean?
function OmiChat.setIconButtonEnabled(enable)
    local instance = ISChat.instance
    local iconButton = instance and instance.iconButton
    if not instance or not iconButton then
        return
    end

    local value = enable and 0.8 or 0.3
    iconButton:setTextureRGBA(value, value, value, 1)
    iconButton.enable = enable

    local iconPicker = instance.iconPicker
    if not enable and iconPicker then
        iconPicker:setVisible(false)
    end
end

---Sets the icons that should be excluded by the icon picker.
---This does not update the icon picker icons.
---@see omichat.IconPicker.updateIcons
---@param icons table<string, true>?
function OmiChat.setIconsToExclude(icons)
    OmiChat._iconsToExclude = icons or {}
end

---Adds an info message to chat that displays only for the local user.
---@param text string
---@param serverAlert boolean?
function OmiChat.showInfoMessage(text, serverAlert)
    local message = MimicMessage:new(text)
    message:setChatType('server')
    message:setTitleID('UI_chat_server_chat_title_id')
    message:setServerAlert(serverAlert or false)
    message:setIsRichText(true)

    ISChat.addLineInChat(message, ISChat.instance.currentTabID - 1)
end

---Updates the icon picker and suggester box based on the current input text.
---@param text string? The current text entry text. If omitted, the current text will be retrieved.
function OmiChat.updateCustomComponents(text)
    local instance = ISChat.instance
    if not instance then
        return
    end

    text = text or instance.textEntry:getInternalText()

    OmiChat.updateIconComponents(text)
    OmiChat.updateSuggesterComponent(text)
end

---Enables or disables the icon picker based on the current input.
---@param text string? The current text entry text.
function OmiChat.updateIconComponents(text)
    local instance = ISChat.instance
    if not instance or not instance.iconButton then
        return
    end

    text = text or instance.textEntry:getInternalText()
    local stream = OmiChat.chatCommandToStream(text)

    if not stream then
        stream = OmiChat.getDefaultTabStream(instance.currentTabID)
    end

    local enable = stream and stream:isAllowIconPicker() or false
    OmiChat.setIconButtonEnabled(enable)
end

---Updates state to match sandbox variables.
---@param redraw boolean? If true, chat messages will be redrawn.
function OmiChat.updateState(redraw)
    if not ISChat.instance then
        return
    end

    OmiChat.getPlayerPreferences()
    updateStreams()
    updateFormatters()
    addOrRemoveIconComponents()

    ISChat.instance:setInfo(OmiChat.getInfoRichText())

    if redraw then
        -- some sandbox vars affect how messages are drawn
        OmiChat.redrawMessages(false)
    end
end

---Shows or hides the suggester based on the current input.
---@param text string? The current text entry text. If omitted, the current text will be retrieved.
function OmiChat.updateSuggesterComponent(text)
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if not instance or not suggesterBox then
        return
    end

    if not OmiChat.getUseSuggester() then
        suggesterBox:setVisible(false)
        return
    end

    text = text or instance.textEntry:getInternalText()
    local suggestions = OmiChat.getSuggestions(text)
    if #suggestions == 0 then
        suggesterBox:setVisible(false)
        return
    end

    suggesterBox:setSuggestions(suggestions)
    suggesterBox:setWidth(instance:getWidth())
    suggesterBox:setHeight(suggesterBox.itemheight * min(#suggestions, 5))
    suggesterBox:setX(instance:getX())
    suggesterBox:setY(instance:getY() + instance.textEntry:getY() - suggesterBox.height)
    suggesterBox:setVisible(true)
    suggesterBox:bringToTop()

    if suggesterBox.vscroll then
        suggesterBox.vscroll:setHeight(suggesterBox.height)
    end
end
