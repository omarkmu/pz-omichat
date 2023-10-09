---Client API functionality related to manipulating the chat.

local MimicMessage = require 'OmiChat/Component/MimicMessage'

local format = string.format
local concat = table.concat
local getText = getText
local min = math.min
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
OmiChat.MimicMessage = MimicMessage


local utils = OmiChat.utils
local config = OmiChat.config
local Option = OmiChat.Option
local IconPicker = OmiChat.IconPicker

local _ChatBase = __classmetatables[ChatBase.class].__index
local _ChatMessage = __classmetatables[ChatMessage.class].__index

-- can't call directly on ChatBase subclasses, so have to grab these like this
local _getTextWithPrefix = _ChatMessage.getTextWithPrefix
local _getChatTitleID = _ChatBase.getTitleID
local _getChatType = _ChatBase.getType


---Creates a built-in formatter and assigns a constant ID.
---@param fmt string
---@param id integer
local function createFormatter(fmt, id)
    -- not using `new` directly to avoid automatic ID assignment
    ---@type omichat.MetaFormatter
    local formatter = setmetatable({}, OmiChat.MetaFormatter)

    formatter:init({ format = fmt })
    formatter:setID(id)

    return formatter
end

---Inserts a chat stream relative to another.
---If the other chat stream isn't found, inserts at the end.
---@param stream omichat.ChatStream
---@param other omichat.ChatStream?
---@param value integer The relative index.
---@return omichat.ChatStream
local function insertStreamRelative(stream, other, value)
    if not other then
        return OmiChat.addStream(stream)
    end

    local pos = #ISChat.allChatStreams + 1
    for i = 1, #ISChat.allChatStreams do
        local chatStream = ISChat.allChatStreams[i]
        if chatStream == other then
            pos = i + value
            break
        end
    end

    table.insert(ISChat.allChatStreams, pos, stream)

    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for i = 1, #tabs do
        local tab = tabs[i]
        if stream.tabID == tab.tabID + 1 then
            pos = #tab.chatStreams + 1
            for j = 1, #tab.chatStreams do
                if tab.chatStreams[i] == other then
                    pos = j + value
                    break
                end
            end

            table.insert(tab.chatStreams, pos, stream)
        end
    end

    return stream
end

---Sorts table items by priority.
---Not stable sorting.
---@param tab table
local function prioritySort(tab)
    table.sort(tab, function(a, b)
        local aPri = a.priority or 1
        local bPri = b.priority or 1

        return aPri > bPri
    end)
end

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
        local optName = config:getOverheadFormatOption(name)
        local opt = optName and Option[optName] or '$1'
        if OmiChat._formatters[name] then
            OmiChat._formatters[name]:setFormatString(opt)
        else
            OmiChat._formatters[name] = createFormatter(opt, info.formatID)
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

---Removes an element from a table, shifting subsequent elements.
---@param tab table
---@param target unknown
---@return boolean
local function remove(tab, target)
    if target == nil then
        return false
    end

    local i = 1
    local found = false
    while i <= #tab and not found do
        found = tab[i] == target
        i = i + 1
    end

    if found then
        while i <= #tab do
            tab[i - 1] = tab[i]
            i = i + 1
        end

        tab[#tab] = nil
    end

    return found
end

---Returns whether name colors should be used given message info.
---@param info omichat.MessageInfo
---@return boolean
local function shouldUseNameColor(info)
    if not OmiChat.getNameColorsEnabled() then
        return false
    end

    local pred = Option.PredicateUseNameColor
    if pred == '' then
        return false
    end

    local tokens = utils.copy(info.substitutions)
    tokens.chatType = info.chatType

    return utils.interpolate(pred, tokens) ~= ''
end


---Adds information about a command that can be triggered from chat.
---@param stream omichat.CommandStream
function OmiChat.addCommand(stream)
    if not stream.omichat then
        stream.omichat = {}
    end

    stream.omichat.isCommand = true
    OmiChat._commandStreams[#OmiChat._commandStreams+1] = stream
end

---Adds an emote that is playable from chat with the .emote syntax.
---@param name string The name of the emote, as it can be used from chat.
---@param emoteOrGetter string | omichat.EmoteGetter The string to associate with the emote, or a function which retrieves one.
function OmiChat.addEmote(name, emoteOrGetter)
    if type(emoteOrGetter) == 'function' then
        OmiChat._emotes[name] = emoteOrGetter
    elseif emoteOrGetter then
        OmiChat._emotes[name] = tostring(emoteOrGetter)
    end
end

---Adds a message transformer which can act on message information to modify display or behavior.
---@param transformer omichat.MessageTransformer
function OmiChat.addMessageTransformer(transformer)
    OmiChat._transformers[#OmiChat._transformers+1] = transformer
    prioritySort(OmiChat._transformers)
end

---Adds a chat stream.
---@param stream omichat.ChatStream
---@return omichat.ChatStream
function OmiChat.addStream(stream)
    ISChat.allChatStreams[#ISChat.allChatStreams+1] = stream

    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for i = 1, #tabs do
        local tab = tabs[i]
        if stream.tabID == tab.tabID + 1 then
            tab.chatStreams[#tab.chatStreams+1] = stream
        end
    end

    return stream
end

---Adds a suggester which can suggest inputs to the player.
---@param suggester omichat.Suggester
function OmiChat.addSuggester(suggester)
    OmiChat._suggesters[#OmiChat._suggesters+1] = suggester
    prioritySort(OmiChat._suggesters)
end

---Adds a chat stream after an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
function OmiChat.addStreamAfter(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 1)
end

---Adds a chat stream before an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
function OmiChat.addStreamBefore(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 0)
end

---Applies format options from a message information table.
---This mutates `info`.
---@param info omichat.MessageInfo
---@return boolean success If false, the information table is invalid.
function OmiChat.applyFormatOptions(info)
    local meta = info.meta
    local options = info.formatOptions
    local message = info.message

    local msg = info.content
    if not msg or not info.format then
        return false
    end

    if options.showTimestamp then
        local hour, minute, second = tostring(message:getDatetime()):match('(%d%d):(%d%d):(%d%d)')

        hour = tonumber(hour)
        minute = tonumber(minute)
        second = tonumber(second)

        if hour and minute and second then
            local hour12 = hour % 12
            if hour12 == 0 then
                hour12 = 12
            end

            local ampm = hour < 12 and 'am' or 'pm'
            info.timestamp = utils.interpolate(Option.FormatTimestamp, {
                chatType = info.chatType,
                stream = info.substitutions.stream,
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
                hourFormatPref = getCore():getOptionClock24Hour() and 24 or 12,
            })
        end
    end

    if options.showTitle then
        info.tag = utils.interpolate(Option.FormatTag, {
            chatType = info.chatType,
            stream = info.substitutions.stream,
            tag = getText(info.titleID),
        })
    end

    if options.stripColors then
        msg = msg:gsub('<RGB:%d%.%d+,%d%.%d+,%d%.%d+>', '')
    end

    local selectedColor = Option.EnableSetNameColor and meta.nameColor
    local hasNameColor = selectedColor or Option.EnableSpeechColorAsDefaultNameColor
    if hasNameColor and shouldUseNameColor(info) then
        local colorToUse = selectedColor or Option:getDefaultColor('name', message:getAuthor())
        local nameColor = utils.toChatColor(colorToUse, true)

        if nameColor ~= '' then
            info.substitutions.name = concat {
                nameColor,
                info.substitutions.name,
                ' <POPRGB> '
            }
            info.substitutions.author = concat {
                nameColor,
                info.substitutions.author,
                ' <POPRGB> '
            }
        end
    end

    msg = utils.trim(msg)
    if not options.color then
        local color
        if options.useDefaultChatColor then
            if message:isFromDiscord() then
                color = OmiChat.getColorTable('discord')
            else
                color = OmiChat.getColorTable(info.chatType)
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
            stripColors = false,
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

    return concat {
        utils.toChatColor(info.formatOptions.color),
        '<SIZE:', info.formatOptions.font or 'medium', '> ',
        utils.interpolate(Option.ChatFormatFull, {
            chatType = info.chatType,
            stream = info.substitutions.stream,
            timestamp = info.timestamp or '',
            tag = info.tag or '',
            content = utils.interpolate(info.format, info.substitutions)
        }),
    }
end

---Determines stream information given a chat command.
---@param command string The input text.
---@param includeCommands boolean? If true, commands should be included. Defaults to true.
---@return (omichat.ChatStream | omichat.CommandStream)? #The stream.
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

        if chatCommand then
            chatStream = stream
            break
        end

        i = i + 1
    end

    return chatStream, command, chatCommand
end

---Retrieves a stream name given a chat command.
---@param command string A chat stream's command, with the leading slash.
---@param includeCommands boolean? If true, commands should be included.
---@return string? #The name of the chat stream, or nil if not found.
function OmiChat.chatCommandToStreamName(command, includeCommands)
    local stream = OmiChat.chatCommandToStream(command, includeCommands)
    if stream then
        return stream.name
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
                local isEnabled = stream.omichat.isEnabled
                if not isEnabled or isEnabled(stream) then
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
    if not tag then
        return {}
    end

    local decoded = utils.kvp.decode(tag)
    return {
        name = decoded.ocName,
        nameColor = utils.stringToColor(decoded.ocNameColor),
    }
end

---Encodes message information including chat name and colors into a string.
---@param message omichat.Message
---@return string
function OmiChat.encodeMessageTag(message)
    local author = message:getAuthor()
    if not author then
        return ''
    end

    local color = OmiChat.getNameColorInChat(author)
    local chatType = OmiChat.getMessageChatType(message)
    return utils.kvp.encode {
        ocName = OmiChat.getNameInChat(author, chatType),
        ocNameColor = color and utils.colorToHexString(color) or nil,
    }
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

---Returns a color table associated with the current player,
---or the default color table if there isn't one.
---@param category omichat.ColorCategory
---@return omichat.ColorTable
function OmiChat.getColorTable(category)
    return OmiChat.getColor(category) or Option:getDefaultColor(category)
end

---Returns a playable emote given an emote name.
---Returns nil if there is not an emote associated with the emote name.
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
---@return string
function OmiChat.getInfoText()
    local player = getSpecificPlayer(0)
    if not player then
        return ''
    end

    local name = OmiChat.getNameInChat(player:getUsername(), 'say')
    local tokens = name and OmiChat.getPlayerSubstitutions(player)
    if not name or not tokens then
        return ''
    end

    tokens.name = name
    return utils.interpolate(Option.FormatInfo, tokens)
end

---Returns the chat type of a chat message.
---@param message omichat.Message
function OmiChat.getMessageChatType(message)
    if utils.isinstance(message, MimicMessage) then
        ---@cast message omichat.MimicMessage
        return message:getChatType()
    end

    ---@cast message ChatMessage
    local chat = message:getChat()
    return tostring(_getChatType(chat))
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

---Removes a stream from the list of available chat commands.
---@param stream omichat.CommandStream
function OmiChat.removeCommand(stream)
    if not stream then
        return
    end

    remove(OmiChat._commandStreams, stream)
end

---Removes an emote from the registry.
---@param name string
function OmiChat.removeEmote(name)
    OmiChat._emotes[name] = nil
end

---Removes a message transformer.
---@param transformer omichat.MessageTransformer
function OmiChat.removeMessageTransformer(transformer)
    remove(OmiChat._transformers, transformer)
end

---Removes the first message transformer with the provided name.
---@param name string
function OmiChat.removeMessageTransformerByName(name)
    local target
    for i = 1, #OmiChat._transformers do
        local transformer = OmiChat._transformers[i]
        if transformer.name and transformer.name == name then
            target = i
            break
        end
    end

    if target then
        table.remove(OmiChat._transformers, target)
    end
end

---Removes a stream from the list of available chat streams.
---@param stream omichat.ChatStream
function OmiChat.removeStream(stream)
    if not stream then
        return
    end

    -- remove from all streams table
    remove(ISChat.allChatStreams, stream)

    -- remove from tab streams
    local tabs = ISChat.instance and ISChat.instance.tabs
    if tabs then
        remove(tabs, stream)
    end
end

---Removes a suggester.
---@param suggester omichat.Suggester
function OmiChat.removeSuggester(suggester)
    remove(OmiChat._suggesters, suggester)
end

---Removes the first suggester with the provided name.
---@param name string
function OmiChat.removeSuggesterByName(name)
    local target
    for i = 1, #OmiChat._suggesters do
        local suggester = OmiChat._suggesters[i]
        if suggester.name and suggester.name == name then
            target = i
            break
        end
    end

    if target then
        table.remove(OmiChat._suggesters, target)
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
        local newText = {}
        local newLines = {}

        for j = 1, #chatText.chatMessages do
            local msg = chatText.chatMessages[j]
            local text = msg:getTextWithPrefix()

            newText[#newText+1] = text
            newLines[#newLines+1] = text .. ' <LINE> '
            newText[#newText+1] = ' <LINE> '
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
        stream = ISChat.defaultTabStream[instance.currentTabID]
    end

    local enable = false
    if stream and stream.omichat and stream.omichat.allowIconPicker ~= nil then
        -- enable icon button for custom chats where appropriate
        enable = stream.omichat.allowIconPicker
    end

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

    ISChat.instance:setInfo(OmiChat.getInfoText())

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
    if #suggestions > 0 then
        suggesterBox:setWidth(instance:getWidth())
        suggesterBox:setHeight(suggesterBox.itemheight * min(#suggestions, 5))
        suggesterBox:setX(instance:getX())
        suggesterBox:setY(instance:getY() + instance.textEntry:getY() - suggesterBox.height)
        suggesterBox:setVisible(true)
        suggesterBox:bringToTop()

        if suggesterBox.vscroll then
            suggesterBox.vscroll:setHeight(suggesterBox.height)
        end
    else
        suggesterBox:setVisible(false)
    end
end
