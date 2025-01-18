---Client API functionality related to manipulating the chat.

local getTexture = getTexture
local min = math.min
local max = math.max
local sort = table.sort
local concat = table.concat
local getTimestampMs = getTimestampMs
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---@class omichat.api.client
local API = require 'OmiChat/API/Client/Core'

---Contains raw chat functions, to send without formatting.
API.raw = {
    say = processSayMessage,
    shout = processShoutMessage,
    whisper = proceedPM,
    general = processGeneralMessage,
    safehouse = processSafehouseMessage,
    faction = proceedFactionMessage,
    admin = processAdminChatMessage,
}

local utils = API.utils
local config = API.Configuration
local IconPicker = API.IconPicker
local MultiMap = utils.MultiMap


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
local echoTypes = {
    faction = 1,
    safehouse = 2,
}
local chatTypeTitleIDs = {
    general = 'UI_chat_general_chat_title_id',
    whisper = 'UI_chat_private_chat_title_id',
    say = 'UI_chat_local_chat_title_id',
    shout = 'UI_chat_local_chat_title_id',
    faction = 'UI_chat_faction_chat_title_id',
    safehouse = 'UI_chat_safehouse_chat_title_id',
    radio = 'UI_chat_radio_chat_title_id',
    admin = 'UI_chat_admin_chat_title_id',
    server = 'UI_chat_server_chat_title_id',
}

local wasTyping = false
local lastTypingUpdate = getTimestampMs()


---Creates or removes the icon button and picker from the chat box based on sandbox options.
local function addOrRemoveIconComponents()
    local instance = ISChat.instance
    if not instance then
        return
    end

    local add = false
    local iconPicker = instance.iconPicker
    local iconButton = instance.iconButton
    local epIncludeMisc = iconPicker and iconPicker.includeUnknownAsMiscellaneous
    local includeMisc = false
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
        iconPicker.exclude = API._iconsToExclude
        iconPicker.includeUnknownAsMiscellaneous = false

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

---Builds send arguments for the given stream.
---@param args string | omichat.SendArgsPartial
---@param streamName string
---@return omichat.SendArgs?
local function transformSendArgs(args, streamName)
    local stream = API.getChatStreamByName(streamName)
    if not stream then
        return
    end

    if type(args) == 'string' then
        return {
            text = args,
            stream = stream,
        }
    end

    if type(args) ~= 'table' then
        return
    end

    args = utils.copy(args) ---@cast args omichat.SendArgs
    args.stream = stream

    return args
end

---Applies a buff if the cooldown period has ended.
local function tryApplyBuff()
    local player = getSpecificPlayer(0)
    local modData = player and player:getModData()
    if not modData then
        return
    end

    local now = getTimestampMs()
    local lastBuff = modData and tonumber(modData.ocLastBuff)
    local buffConfig = config.Buffs
    if lastBuff and (now - lastBuff) / 60000 < buffConfig.Cooldown then
        return
    end

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    local cigaretteStressReduction = buffConfig.CigaretteStress * stats:getMaxStressFromCigarettes()

    stats:setHunger(stats:getHunger() - buffConfig.Hunger)
    stats:setThirst(stats:getThirst() - buffConfig.Thirst)
    stats:setFatigue(stats:getFatigue() - buffConfig.Fatigue)
    stats:setStressFromCigarettes(stats:getStressFromCigarettes() - cigaretteStressReduction)
    bodyDamage:setBoredomLevel(bodyDamage:getBoredomLevel() - buffConfig.Boredom * 100)
    bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - buffConfig.Unhappiness * 100)
    modData.ocLastBuff = now
end

---Creates or updates metadata formatters.
local function updateFormatters()
    config:updateFormatters()

    table.wipe(API._metadataFormatters)
    for info in config:formatters() do
        API._metadataFormatters[info.name] = info.formatter
    end

    local cmdConfig = config.Commands
    local commandsToUpdate = {
        { API._cardCommand, cmdConfig.Card.OverheadFormat, cmdConfig.Card.Tags },
        { API._flipCommand, cmdConfig.Flip.OverheadFormat, cmdConfig.Flip.Tags },
        { API._rollCommand, cmdConfig.Roll.OverheadFormat, cmdConfig.Roll.Tags },
    }

    for i = 1, #commandsToUpdate do
        local info = commandsToUpdate[i]
        local stream = info[1]
        local formatter = stream:getFormatter()

        stream:setTags(info[3])
        if formatter then
            formatter:setFormatString(info[2])
        end
    end
end

---Updates streams based on configuration options.
local function updateStreams()
    -- collect existing stream formatters
    local existingFormatters = {} ---@type table<string, omichat.MetaFormatter>
    for stream in API.chatStreams() do
        existingFormatters[stream:getName()] = stream:getFormatter()
    end

    -- create stream objects
    local seen = {}
    local streams = {} ---@type omichat.ChatStream[]
    local toCreate = {} ---@type omichat.ChatStream[]
    local toCreateIDs = {} ---@type integer[]

    local needsRecycle = false
    local nextID = config.MIN_CHAT_ID

    for def in config:chatStreams() do
        local stream = API.ChatStream.fromDefinition(def, config.Streams.GlobalTags)
        if stream and not seen[stream:getName()] then
            local name = stream:getName()

            seen[name] = true
            streams[#streams + 1] = stream

            local formatter = existingFormatters[name]
            if formatter then
                local id = formatter:getID()

                -- if the stream order has changed, we need to recycle
                if id ~= nextID then
                    needsRecycle = true
                else
                    formatter:setFormatString(stream:getOverheadFormat())
                    stream:setFormatter(formatter)
                end
            else
                toCreate[#toCreate + 1] = stream
                toCreateIDs[#toCreateIDs + 1] = nextID
            end

            nextID = nextID + 1
            if #streams == config.MAX_CHAT_STREAMS then
                break
            end
        end
    end

    -- streams IDs must increase in order so players' streams all match
    -- if that's not the case, "recycle" — reallocate all stream formatters and clear old messages
    if needsRecycle then
        utils.log.info('Recycling chat streams')

        toCreate = streams  -- update all streams' formatters
        API.clearMessages() -- clear so old messages don't use the wrong format

        for i = 1, #toCreate do
            toCreateIDs[i] = config.MIN_CHAT_ID + i - 1
        end
    end

    -- create and save formatters
    for i = 1, #toCreate do
        local stream = toCreate[i]
        local id = toCreateIDs[i]

        local formatter = API._chatFormatters[id]
        if not formatter then
            formatter = API.MetaFormatter:new(id)
            API._chatFormatters[id] = formatter
        end

        formatter:setFormatString(stream:getOverheadFormat())
        stream:setFormatter(formatter)
    end

    -- clear chat tables
    table.wipe(ISChat.allChatStreams)
    table.wipe(ISChat.defaultTabStream)

    local tabs = ISChat.instance and ISChat.instance.tabs or {}
    for i = 1, #tabs do
        table.wipe(tabs[i].chatStreams)
    end

    -- populate chat tables
    local defaultTabStreams = ISChat.defaultTabStream
    for i = 1, #streams do
        local stream = streams[i]
        local tabID = stream:getTabID()

        ISChat.allChatStreams[#ISChat.allChatStreams + 1] = stream
        if not defaultTabStreams[tabID] then
            defaultTabStreams[tabID] = stream
        end

        local tab = tabs[tabID]
        if tab then
            tab.chatStreams[#tab.chatStreams + 1] = stream
        end
    end

    -- update special stream types
    local special = {
        { API._discordStream, config.Discord },
        { API._radioStream, config.Radio },
        { API._serverStream, config.ServerMessages },
    }

    for i = 1, #special do
        local info = special[i]
        local stream = info[1]
        local streamConfig = info[2]

        stream:setChatFormat(streamConfig.ChatFormat)
        stream:setDefaultColor(streamConfig.DefaultColor)
        stream:setTags(streamConfig.Tags)
    end

    -- cycle if current stream is now unavailable
    local instance = ISChat.instance
    local chatText = instance and instance.chatText
    if not chatText then
        return
    end

    local lastStream = API.chatCommandToStream(chatText.lastChatCommand)
    if lastStream and not lastStream:checkPlayerCanUse() then
        chatText.lastChatCommand = API.cycleStream()
    end
end


---Adds an info message to chat that displays only for the local user.
---@param text string
---@param serverAlert boolean?
---@param tabID integer? The 1-indexed ID of the chat tab to send the message on. Defaults to the current chat tab.
function API.addInfoMessage(text, serverAlert, tabID)
    utils.lib.chat.addInfoMessage(text, serverAlert, tabID)
end

---Determines stream information given a chat command.
---@param command string The input text.
---@param options omichat.Args.ChatCommandToStream? Options for retrieving the stream.
---@return omichat.Stream? stream
---@return string #The text following the command in the input.
---@return string? #The command or short command that was used.
---@return omichat.Stream? #Information about the disabled stream.
function API.chatCommandToStream(command, options)
    if not command or command == '' then
        return nil, ''
    end

    options = options or {}
    local enabledOnly = options.enabledOnly

    local disabledCommand
    local foundStream
    local chatCommand
    local remainder

    local iterator
    if options.commandsOnly then
        iterator = API.commandStreams()
    elseif options.chatsOnly then
        iterator = API.chatStreams()
    else
        iterator = API.streams()
    end

    for stream in iterator do
        chatCommand, remainder = stream:checkMatch(command)
        if chatCommand and (not enabledOnly or stream:isEnabled()) then
            foundStream = stream
            command = remainder
            disabledCommand = nil
            break
        elseif chatCommand then
            disabledCommand = stream
        end
    end

    return foundStream, command, chatCommand, disabledCommand
end

---Retrieves a stream name given a chat command.
---@param command string A chat stream's command, with the leading slash.
---@param options omichat.Args.ChatCommandToStream? Options for retrieving the stream.
---@return string? #The name of the chat stream, or `nil` if not found.
function API.chatCommandToStreamName(command, options)
    local stream = API.chatCommandToStream(command, options)
    if stream then
        return stream:getName()
    end
end

---Returns an iterator over chat streams.
---@return fun(): omichat.ChatStream?
function API.chatStreams()
    local i = 0
    return function()
        while i < #ISChat.allChatStreams do
            i = i + 1
            local stream = ISChat.allChatStreams[i]
            if stream and utils.isinstance(stream, API.ChatStream) then
                ---@cast stream omichat.ChatStream
                return stream
            end
        end
    end
end

---Returns the associated title ID for a chat type.
---@param chatType omichat.ChatTypeString
---@return string
function API.chatTypeToTitleID(chatType)
    return chatTypeTitleIDs[chatType]
end

---Clears all of the current chat messages.
function API.clearMessages()
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

---Returns an iterator over command streams.
---@return fun(): omichat.CommandStream?
function API.commandStreams()
    local i = 0
    return function()
        while i < #API._commandStreams do
            i = i + 1
            return API._commandStreams[i]
        end
    end
end

---Cycles to the next chat stream.
---This is used with onSwitchStream.
---@param target string? The name of a target stream to switch to instead of the next stream.
---@return string #The command of the new current stream.
function API.cycleStream(target)
    local curChatText = ISChat.instance.chatText
    local chatStreams = curChatText.chatStreams

    local targetID
    local streamID = curChatText.streamID

    for _ = 0, #chatStreams do
        streamID = streamID % #chatStreams + 1
        local stream = chatStreams[streamID]
        if utils.isinstance(stream, API.ChatStream) then
            ---@cast stream omichat.ChatStream
            if not target or stream:getName() == target then
                if stream:checkPlayerCanUse() then
                    targetID = streamID
                    break
                end
            end
        end
    end

    if targetID then
        curChatText.streamID = targetID
    end

    local curStream = curChatText.chatStreams[curChatText.streamID]
    if utils.isinstance(curStream, API.ChatStream) then
        ---@cast curStream omichat.ChatStream
        return curStream:getCommand()
    else
        ---@cast curStream omichat.StreamTable
        return curStream.command
    end
end

---Retrieves a chat stream given its name.
---@param name string
---@param options omichat.Args.StreamRetrieval?
---@return omichat.ChatStream?
function API.getChatStreamByName(name, options)
    if name == 'server' then
        return API._serverStream
    elseif name == 'radio' then
        return API._radioStream
    elseif name == 'discord' then
        return API._discordStream
    end

    options = options or {}
    for stream in API.chatStreams() do
        if name == stream:getName() and (not options.enabledOnly or stream:isEnabled()) then
            return stream
        end
    end
end

---Returns enabled chat streams with the given tag.
---@param tag string
---@param excludeTags string[]?
---@return omichat.ChatStream[]
function API.getChatStreamsWithTag(tag, excludeTags)
    return API.getChatStreamsWithTags({ tag }, excludeTags)
end

---Returns enabled chat streams with the given tags.
---@param tags string[]
---@param excludeTags string[]?
---@return omichat.ChatStream[]
function API.getChatStreamsWithTags(tags, excludeTags)
    excludeTags = excludeTags or {}
    local streams = {}

    for stream in API.chatStreams() do
        if stream:isEnabled() and not stream:hasAnyTags(excludeTags) and stream:hasTags(tags) then
            streams[#streams + 1] = stream
        end
    end

    return streams
end

---Returns enabled chat streams without the given tag.
---@param excludeTag string
---@return omichat.ChatStream[]
function API.getChatStreamsWithoutTag(excludeTag)
    return API.getChatStreamsWithTags({}, { excludeTag })
end

---Returns enabled chat streams without the given tags.
---@param excludeTags string[]
---@return omichat.ChatStream[]
function API.getChatStreamsWithoutTags(excludeTags)
    return API.getChatStreamsWithTags({}, excludeTags)
end

---Determines the color options that should be enabled based on the server configuration.
---@param all boolean? If given, all possible color options will be returned instead.
---@return string[]
function API.getColorOptions(all)
    local colorOpts = {}

    colorOpts[#colorOpts + 1] = 'speech'
    colorOpts[#colorOpts + 1] = 'server'

    if all then
        colorOpts[#colorOpts + 1] = 'discord'
        colorOpts[#colorOpts + 1] = 'radio'
    else
        if config:canShowDiscordColorOption() then
            colorOpts[#colorOpts + 1] = 'discord'
        end

        -- need to check the option because checkPlayerCanUseChat checks for a radio item
        local allowedStreams = getServerOptions():getOption('ChatStreams'):split(',')
        for i = 1, #allowedStreams do
            if allowedStreams[i] == 'r' then
                colorOpts[#colorOpts + 1] = 'radio'
                break
            end
        end
    end

    for stream in API.chatStreams() do
        if all or stream:checkPlayerCanUse() then
            colorOpts[#colorOpts + 1] = stream:getName()
        end
    end

    return colorOpts
end

---Retrieves a command stream given its name.
---@param name string
---@return omichat.CommandStream?
function API.getCommandStreamByName(name)
    for i = 1, #API._commandStreams do
        local stream = API._commandStreams[i]
        if stream:getName() == name then
            return stream
        end
    end
end

---Returns information about the default stream for a given tab ID.
---@param tabID integer
---@return omichat.ChatStream?
function API.getDefaultTabStream(tabID)
    local default = ISChat.defaultTabStream[tabID]
    if default and utils.isinstance(default, API.ChatStream) then
        return default
    end
end

---Gets a special stream intended to represent Discord messages.
---This stream should not be used for sending messages.
function API.getDiscordStream()
    return API._discordStream
end

---Gets the display command associated with a stream.
---If the stream does not exist, this defaults to prefixing a forward slash.
---@param streamName string
---@return string
function API.getDisplayCommand(streamName)
    local stream = API.getChatStreamByName(streamName)
    if stream then
        return stream:getCommand()
    end

    return '/' .. streamName
end

---Returns a playable emote given an emote name.
---Returns `nil` if there is not an emote associated with the emote name.
---@param emote string
---@return (string | omichat.EmoteHandler)?
function API.getEmote(emote)
    return API._emotes[emote]
end

---Returns the first emote found from an emote shortcut in the provided text.
---@param text string
---@return (string | omichat.EmoteHandler)? emoteOrHandler
---@return integer? start
---@return integer? finish
---@return string? inputEmote
function API.getEmoteFromCommand(text)
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

        local emoteToPlay = emote and API.getEmote(emote:lower())
        if emoteToPlay then
            return emoteToPlay, start, finish, emote:lower()
        end

        startPos = finish + 1
    end
end

---Returns the first enabled chat stream with the given tag.
---@param tag string
---@param excludeTags string[]?
---@return omichat.ChatStream?
function API.getFirstChatStreamWithTag(tag, excludeTags)
    return API.getFirstChatStreamWithTags({ tag }, excludeTags)
end

---Returns the first enabled chat stream with the given tags.
---@param tags string[]
---@param excludeTags string[]?
---@return omichat.ChatStream?
function API.getFirstChatStreamWithTags(tags, excludeTags)
    excludeTags = excludeTags or {}
    for stream in API.chatStreams() do
        if stream:isEnabled() and not stream:hasAnyTags(excludeTags) and stream:hasTags(tags) then
            return stream
        end
    end
end

---Returns the first enabled chat stream without the given tag.
---@param excludeTag string
---@return omichat.ChatStream?
function API.getFirstChatStreamWithoutTag(excludeTag)
    return API.getFirstChatStreamWithTags({}, { excludeTag })
end

---Returns the first enabled chat stream without the given tags.
---@param excludeTags string[]
---@return omichat.ChatStream?
function API.getFirstChatStreamWithoutTags(excludeTags)
    return API.getFirstChatStreamWithTags({}, excludeTags)
end

---Gets the text that should display when clicking the info button.
---@param player IsoPlayer? The player to use to populate token values. If `nil`, this will be player 1.
---@return string
function API.getInfoRichText(player)
    player = player or getSpecificPlayer(0)
    if not player then
        return ''
    end

    local tokens = API.getPlayerSubstitutions(player)
    if not tokens then
        return ''
    end

    local name = API.getPlayerNameInChat(player, 'say')
    tokens.name = name and utils.escapeRichText(name) or ''
    return utils.interpolate(config.General.InfoText, tokens, player:getUsername())
end

---Returns the current leftmost button.
---@return ISButton?
function API.getLeftmostButton()
    if API._leftmostBtn then
        return API._leftmostBtn
    end

    local instance = ISChat.instance
    if instance then
        return instance.gearButton
    end
end

---Gets a special stream intended to represent radio messages.
---This stream should not be used for sending messages.
function API.getRadioStream()
    return API._radioStream
end

---Gets a special stream intended to represent server messages.
---This stream should not be used for sending messages.
function API.getServerStream()
    return API._serverStream
end

---Returns the list of custom setting handlers for a given category.
---@param category omichat.SettingCategory
---@return omichat.SettingHandlerCallback[]
function API.getSettingHandlers(category)
    return API._settingHandlers[category]
end

---Gets an emote meant to simulate sign language based on the given text.
---@param text string
---@return string
function API.getSignLanguageEmote(text)
    -- same text should map to same 'sign'
    local rand = newrandom()
    rand:seed(utils.trim(text:lower()))

    return signLanguageEmotes[rand:random(1, #signLanguageEmotes)]
end

---Retrieves a chat or command stream given its name.
---@param name string
---@return omichat.Stream?
function API.getStreamByName(name)
    for stream in API.streams() do
        if name == stream:getName() then
            return stream
        end
    end
end

---Retrieves the search callback for an argument type.
---@param argType string
---@return omichat.SuggestSearchCallback?
function API.getSuggesterArgTypeCallback(argType)
    return API._customSuggesterArgTypes[argType]
end

---Suggests text based on the provided input text.
---@param text string
---@return omichat.Suggestion[]
function API.getSuggestions(text)
    if not text or text == '' then
        return {}
    end

    ---@type omichat.SuggestionInfo
    local info = {
        input = text,
        context = {},
        suggestions = {},
    }

    for i = 1, #API._suggesters do
        local suggester = API._suggesters[i]
        if suggester.suggest then
            suggester:suggest(info)
        end
    end

    return info.suggestions
end

---Returns whether the player is currently typing.
---@return boolean
function API.getTyping()
    return API._isTyping
end

---Returns the current display string for the typing indicator.
---@param maxWidth integer?
---@return string?
function API.getTypingDisplay(maxWidth)
    local display = API._typingDisplay
    local txtMgr = getTextManager()

    if display and maxWidth and txtMgr:MeasureStringX(UIFont.Small, display) > maxWidth then
        display = utils.interpolate(config.TypingIndicator.Format, { alt = true })
    end

    return display
end

---Hides the suggester box if it's currently visible.
function API.hideSuggesterBox()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox then
        suggesterBox:setVisible(false)
    end
end

---Redraws the current chat messages.
---@param doScroll boolean? Whether the chat should also be scrolled to the bottom. Defaults to true.
function API.redrawMessages(doScroll)
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
            local message = messages[j]
            local text = message:getTextWithPrefix()

            if message:isShowInChat() then
                newText[#newText + 1] = text
                newLines[#newLines + 1] = text .. ' <LINE> '
            end
        end

        chatText.chatTextLines = newLines
        chatText.text = concat(newText, ' <LINE> ')

        chatText:paginate()
    end

    if doScroll ~= false then
        -- fix scroll position
        API.scrollToBottom()
    end
end

---Sets the scroll position of all chat tabs to the bottom.
function API.scrollToBottom()
    if not ISChat.instance or not ISChat.instance.tabs then
        return
    end

    for i = 1, #ISChat.instance.tabs do
        local tab = ISChat.instance.tabs[i]
        tab:setYScroll(-tab:getScrollHeight())
    end
end

---Sets the scroll position of all chat tabs to the top.
function API.scrollToTop()
    if not ISChat.instance or not ISChat.instance.tabs then
        return
    end

    for i = 1, #ISChat.instance.tabs do
        local tab = ISChat.instance.tabs[i]
        tab:setYScroll(0)
    end
end

---Sends a message on the given stream.
---@param args omichat.SendArgs?
---@return string?
function API.send(args)
    local stream = args and args.stream
    if not args or not stream or not utils.isinstance(stream, API.ChatStream) then
        return
    end

    ---@cast stream omichat.ChatStream

    local text = utils.trim(args.text or '')

    local prefix = ''
    local chatType = stream:getChatType()
    if chatType == 'whisper' then
        -- don't apply formatting to the username
        local m1, m2 = text:match('^("[^"]*%s+[^"]*"%s)(.+)$')
        if not m1 then
            m1, m2 = text:match('^([^"]%S*%s)(.+)$')
        end

        if not m1 then
            -- not a valid whisper chat
            return
        end

        prefix = m1
        text = m2
    end

    if #text == 0 then
        return
    end

    local language
    local currentLanguage = API.getCurrentRoleplayLanguage()
    if currentLanguage and currentLanguage ~= API.getDefaultRoleplayLanguage() then
        language = currentLanguage
    end

    local initialText = text
    local formatResult = API.formatForChat {
        text = text,
        language = language,
        chatType = chatType,
        echoType = args.echoType,
        stream = stream,
        formatStream = args.formatStream,
        formatter = args.formatter,
        playSignedEmote = args.playSignedEmote,
        tokens = args.tokens,
        extraTags = args.extraTags,
    }

    text = formatResult.text
    if text == '' then
        if formatResult.error then
            API.addInfoMessage(formatResult.error)
        end

        return
    end

    local processResult
    local process = API.raw[chatType] or API.raw.say
    if process then
        processResult = process(prefix .. text)
        if processResult and chatType == 'whisper' and API.getRetainCommand(stream:getCommandType()) then
            local chatText = ISChat.instance.chatText
            chatText.lastChatCommand = chatText.lastChatCommand .. tostring(processResult) .. ' '
        end
    end

    local isSigned = formatResult.allowLanguage and language and API.isRoleplayLanguageSigned(language)
    if isSigned and args.playSignedEmote and API.getSignEmotesEnabled() then
        local player = getSpecificPlayer(0)
        if player then
            player:playEmote(API.getSignLanguageEmote(initialText))
        end
    end

    if config.Buffs.Enable and stream:isAllowBuffs() then
        tryApplyBuff()
    end

    local echoType = echoTypes[chatType]
    if config.EchoMessages.Enable and echoType then
        local echoStream = API.getFirstChatStreamWithTag('EchoTarget')
        if not echoStream or echoTypes[echoStream:getChatType()] or not echoStream:isEnabled() then
            return processResult
        end

        local useCallback = echoStream:getUseCallback() or API.send
        useCallback {
            echoType = echoType,
            stream = echoStream,
            text = initialText,
            formatter = API._metadataFormatters.echo,
            extraTags = config.EchoMessages.Tags,
        }
    end

    return processResult
end

---Sends an /admin message, formatted according to configuration.
---@param args string | omichat.SendArgsPartial
function API.sendAdmin(args)
    API.send(transformSendArgs(args, 'admin'))
end

---Sends a /faction message, formatted according to configuration.
---@param args string | omichat.SendArgsPartial
function API.sendFaction(args)
    API.send(transformSendArgs(args, 'faction'))
end

---Sends an /all message, formatted according to configuration.
---@param args string | omichat.SendArgsPartial
function API.sendGeneral(args)
    API.send(transformSendArgs(args, 'general'))
end

---Sends a /pm message, formatted according to configuration.
---@param args string | omichat.SendArgsPartial
---@return string
function API.sendPM(args)
    return API.send(transformSendArgs(args, 'private')) or ''
end

---Sends a /safehouse message, formatted according to configuration.
---@param args string | omichat.SendArgsPartial
function API.sendSafehouse(args)
    API.send(transformSendArgs(args, 'safehouse'))
end

---Sends a /say message, formatted according to configuration.
---@param args string | omichat.SendArgsPartial
function API.sendSay(args)
    API.send(transformSendArgs(args, 'say'))
end

---Sends a /yell message, formatted according to configuration.
---@param args string | omichat.SendArgsPartial
function API.sendShout(args)
    API.send(transformSendArgs(args, 'yell'))
end

---Sets whether the icon picker button is enabled.
---If the button is disabled, the icon picker component will also be hidden.
---@param enable boolean?
function API.setIconButtonEnabled(enable)
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
function API.setIconsToExclude(icons)
    API._iconsToExclude = icons or {}
end

---Sets whether the player is currently typing.
---@param isTyping boolean
function API.setTyping(isTyping)
    API._isTyping = isTyping
end

---Returns an iterator over chat and command streams.
---@return fun(): omichat.Stream?
function API.streams()
    local i = 0
    local numStreams = #ISChat.allChatStreams
    local numCommands = #API._commandStreams

    return function()
        while i <= numStreams + numCommands do
            i = i + 1
            local stream
            if i <= numStreams then
                stream = ISChat.allChatStreams[i]
            else
                stream = API._commandStreams[i - numStreams]
            end

            if utils.isinstance(stream, API.Stream) then
                ---@cast stream omichat.Stream
                return stream
            end
        end
    end
end

---Updates the positions of custom buttons.
function API.updateButtons()
    local instance = ISChat.instance
    if not instance or not instance.gearButton then
        return
    end

    local th = instance:titleBarHeight()
    local lastBtn = instance.gearButton
    for i = 1, #API._customButtons do
        local btn = API._customButtons[i]
        if btn:getParent() ~= instance then
            instance:addChild(btn)
        end

        if btn:isVisible() then
            local pad = max(lastBtn:getWidth(), th)
            btn:setX(lastBtn:getX() - pad - pad / 2)
            lastBtn = btn
        end
    end

    API._leftmostBtn = lastBtn
end

---Updates the chat panel size based on the configured options.
function API.updateChatPanelSize()
    local instance = ISChat.instance
    if not instance then
        return
    end

    local oldTabCnt = instance.tabCnt
    if oldTabCnt == 1 then
        -- calcTabSize assumes calling before increment
        instance.tabCnt = 0
    end

    local size = instance:calcTabSize()
    instance.tabCnt = oldTabCnt

    local height = size.height
    if config.TypingIndicator.Enable and API.getShowTyping() then
        height = height - instance.typingFontHgt - 4
    end

    for i = 1, #instance.tabs do
        local tab = instance.tabs[i]
        if tab.tabID == 0 then
            tab:setHeight(height)
        end
    end
end

---Updates the visibility of the chat and close button based on the `Always Show Chat` option.
---@protected
function API.updateChatVisibility()
    local instance = ISChat.instance
    if not instance or not instance.closeButton then
        return
    end

    local closeBtn = ISChat.instance.closeButton
    local alwaysShowChat = config.General.AlwaysShowChat
    if closeBtn and closeBtn:isVisible() == alwaysShowChat then
        closeBtn:setVisible(not alwaysShowChat)
    end

    if alwaysShowChat then
        ISChat.instance:setVisible(true)
    end
end

---Updates the icon picker and suggester box based on the current input text.
---@param text string? The current text entry text. If omitted, the current text will be retrieved.
function API.updateCustomComponents(text)
    local instance = ISChat.instance
    if not instance then
        return
    end

    text = text or instance.textEntry:getInternalText()

    API.updateIconComponents(text)
    API.updateSuggesterComponent(text)
end

---Enables or disables the icon picker based on the current input.
---@param text string? The current text entry text.
function API.updateIconComponents(text)
    local instance = ISChat.instance
    if not instance or not instance.iconButton then
        return
    end

    text = text or instance.textEntry:getInternalText()
    local stream = API.chatCommandToStream(text)

    if not stream then
        stream = API.getDefaultTabStream(instance.currentTabID)
    end

    API.setIconButtonEnabled(false)
end

---Updates the info text to the configured value.
---@param player IsoPlayer?
function API.updateInfoText(player)
    local instance = ISChat.instance
    if not instance then
        return
    end

    instance:setInfo(API.getInfoRichText(player))
end

---Updates state to match sandbox variables.
---@param redraw boolean? If true, chat messages will be redrawn.
function API.updateState(redraw)
    updateFormatters()
    updateStreams()

    if not ISChat.instance then
        return
    end

    API.getPlayerPreferences()
    addOrRemoveIconComponents()
    API.updateChatPanelSize()
    API.updateInfoText()
    API.updateChatVisibility()
    API.updateButtons()

    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if username then
        API.refreshLanguageInfo(username)
    end

    if redraw then
        -- some sandbox vars affect how messages are drawn
        API.redrawMessages(false)
    end
end

---Shows or hides the suggester based on the current input.
---@param text string? The current text entry text. If omitted, the current text will be retrieved.
function API.updateSuggesterComponent(text)
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if not instance or not suggesterBox then
        return
    end

    if not API.getUseSuggester() then
        suggesterBox:setVisible(false)
        return
    end

    text = text or instance.textEntry:getInternalText()
    local suggestions = API.getSuggestions(text)
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

---Updates the display string for typing players based on the current typing information.
function API.updateTypingDisplay()
    if not config.TypingIndicator.Enable or not API.getShowTyping() then
        API._typingDisplay = nil
        return
    end

    local list = {}
    local inactive = {}

    local now = getTimestampMs()
    for username, info in pairs(API._typingInfo) do
        if now - info.lastUpdate >= 5000 then
            inactive[#inactive + 1] = username
        else
            list[#list + 1] = info.display
        end
    end

    for _, username in pairs(inactive) do
        API._typingInfo[username] = nil
    end

    if #list == 0 then
        API._typingDisplay = nil
        return
    end

    local entries = {}
    sort(list)
    for i = 1, #list do
        entries[#entries + 1] = {
            key = i,
            value = list[i],
        }
    end

    local tokens = {
        names = MultiMap:new(entries),
    }

    local text = utils.interpolate(config.TypingIndicator.Format, tokens) ---@type string?
    if text == '' then
        text = nil
    end

    API._typingDisplay = text
end

---Updates the typing status based on the current input.
---@param skipTimer boolean?
function API.updateTypingStatus(skipTimer)
    if not API.getShowTyping() then
        if wasTyping then
            wasTyping = false
            API.setTyping(false)
            API.sendTypingStatus()
        end

        return
    end

    local instance = ISChat.instance
    local entry = instance and instance.textEntry
    if not entry or not instance then
        return
    end

    local now = getTimestampMs()
    if not skipTimer and now - lastTypingUpdate <= 1000 then
        return
    end

    local range
    local chatType
    local isTyping = entry:isFocused() and instance.currentTabID == 1
    if isTyping then
        local text = entry:getInternalText()
        local trimmed = text:trim()
        local stream = API.chatCommandToStream(text, { chatsOnly = true, enabledOnly = true })

        ---@cast stream omichat.ChatStream?
        if not stream and not utils.startsWith(trimmed, '/') then
            stream = API.getDefaultTabStream(instance.currentTabID)
        end

        if not stream or not stream:isAllowTypingIndicator() then
            isTyping = false
        end
    end

    lastTypingUpdate = now
    API.setTyping(isTyping)
    if isTyping or wasTyping then
        wasTyping = isTyping

        API.sendTypingStatus(range, chatType)
    end
end
