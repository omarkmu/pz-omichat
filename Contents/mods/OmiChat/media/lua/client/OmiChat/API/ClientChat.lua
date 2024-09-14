---Client API functionality related to manipulating the chat.

local lib = require 'OmiChat/lib'
local getTexture = getTexture
local min = math.min
local max = math.max
local sort = table.sort
local concat = table.concat
local getTimestampMs = getTimestampMs
local ISChat = ISChat ---@cast ISChat omichat.ISChat
local MultiMap = lib.interpolate.MultiMap


---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
require 'OmiChat/Component/MimicMessage'

---Contains raw chat functions, to send without formatting.
OmiChat.raw = {
    say = processSayMessage,
    shout = processShoutMessage,
    whisper = proceedPM,
    general = processGeneralMessage,
    safehouse = processSafehouseMessage,
    faction = proceedFactionMessage,
    admin = processAdminChatMessage,
}

local vanillaStreamConfigs = require 'OmiChat/Definition/VanillaStreams'
local customChatStreams = require 'OmiChat/Definition/CustomStreams'

local utils = OmiChat.utils
local config = OmiChat.config
local Option = OmiChat.Option
local IconPicker = OmiChat.IconPicker
local StreamInfo = OmiChat.StreamInfo
local MimicMessage = OmiChat.MimicMessage


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
        iconPicker.exclude = OmiChat._iconsToExclude
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
---@param args string | omichat.SendArgs
---@param streamIdentifier string
---@return omichat.SendArgs?
local function transformSendArgs(args, streamIdentifier)
    local stream = OmiChat.getChatStreamByIdentifier(streamIdentifier)
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

    args = utils.copy(args)
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
    if lastBuff and (now - lastBuff) / 60000 < Option.BuffCooldown then
        return
    end

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()

    stats:setHunger(stats:getHunger() - 0.04)
    stats:setThirst(stats:getThirst() - 0.04)
    stats:setFatigue(stats:getFatigue() - 0.1)
    stats:setStressFromCigarettes(stats:getStressFromCigarettes() - 0.25)
    bodyDamage:setBoredomLevel(bodyDamage:getBoredomLevel() - 50)
    bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - 50)
    modData.ocLastBuff = now
end

---Updates stream aliases.
local function updateAliases()
    -- clear all aliases
    local i = 1
    local numStreams = #ISChat.allChatStreams
    local numCommands = #OmiChat._commandStreams
    while i <= numStreams + numCommands do
        local stream
        if i <= numStreams then
            stream = ISChat.allChatStreams[i]
        else
            stream = OmiChat._commandStreams[i - numStreams]
        end

        if stream and stream.omichat and stream.omichat.aliases then
            table.wipe(stream.omichat.aliases)
        end

        i = i + 1
    end

    -- update aliases
    local configuredAliases = utils.interpolateRaw(Option.FormatAliases, {})

    ---@cast configuredAliases omi.interpolate.MultiMap
    if not utils.isinstance(configuredAliases, MultiMap) then
        return
    end

    local allAliases = {}
    for alias, identifier in configuredAliases:pairs() do
        alias = tostring(alias)
        identifier = tostring(identifier)
        if not allAliases[identifier] then
            allAliases[identifier] = {}
        end

        local list = allAliases[identifier]
        list[tostring(alias)] = true
    end

    for ident, tab in pairs(allAliases) do
        local info = OmiChat.getChatStreamByIdentifier(ident)
        local stream = info and info:getStream()
        if stream then
            if not stream.omichat then
                stream.omichat = {}
            end

            if not stream.omichat.aliases then
                stream.omichat.aliases = {}
            end

            local aliases = stream.omichat.aliases
            for k in pairs(tab) do
                aliases[#aliases + 1] = concat { '/', k, ' ' }
            end
        end
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

    for i = 1, #ISChat.allChatStreams do
        local stream = ISChat.allChatStreams[i]
        if stream.omichat then
            local data = config:getCustomStreamInfo(stream.name)
            if stream.name == 'private' then
                vanillaWhisper = stream
            elseif stream.name == 'whisper' then
                if stream.omichat.isLocalWhisper then
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
            vanillaWhisper.omichat = vanillaStreamConfigs.private
        elseif vanillaStreamConfigs[stream.name] then
            stream.omichat = vanillaStreamConfigs[stream.name]
        end
    end

    for data in config:chatStreams() do
        local stream = customChatStreams[data.name]
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


---Adds an info message to chat that displays only for the local user.
---@param text string
---@param serverAlert boolean?
function OmiChat.addInfoMessage(text, serverAlert)
    local message = MimicMessage:new(text)
    message:setChatType('server')
    message:setTitleID('UI_chat_server_chat_title_id')
    message:setServerAlert(serverAlert or false)
    message:setIsRichText(true)

    ISChat.addLineInChat(message, ISChat.instance.currentTabID - 1)
end

---Determines stream information given a chat command.
---@param command string The input text.
---@param includeCommands boolean? If true, commands should be included. Defaults to true.
---@param enabledOnly boolean? If true, only enabled streams will be returned. Defaults to false.
---@return omichat.StreamInfo? #Information about the stream.
---@return string #The text following the command in the input.
---@return string? #The command or short command that was used.
---@return omichat.StreamInfo? #Information about the disabled stream.
function OmiChat.chatCommandToStream(command, includeCommands, enabledOnly)
    if not command or command == '' then
        return nil, ''
    end

    if includeCommands == nil then
        includeCommands = true
    end

    local disabledCommand
    local streamInfo
    local chatCommand

    local i = 1
    local numStreams = #ISChat.allChatStreams
    local numCommands = #OmiChat._commandStreams
    while i <= numStreams + numCommands do
        local stream, checkCommand
        if i <= numStreams then
            stream = ISChat.allChatStreams[i]
        else
            if not includeCommands then
                break
            end

            stream = OmiChat._commandStreams[i - numStreams]
        end

        local info = StreamInfo:new(stream)
        chatCommand, checkCommand = info:checkMatch(command)
        if chatCommand and (not enabledOnly or info:isEnabled()) then
            streamInfo = info
            command = checkCommand
            disabledCommand = nil
            break
        elseif chatCommand then
            disabledCommand = info
        end

        i = i + 1
    end

    return streamInfo, command, chatCommand, disabledCommand
end

---Retrieves a stream name given a chat command.
---@param command string A chat stream's command, with the leading slash.
---@param includeCommands boolean? If true, commands should be included.
---@param enabledOnly boolean? If true, only enabled streams will be returned. Defaults to false.
---@return string? #The name of the chat stream, or `nil` if not found.
function OmiChat.chatCommandToStreamName(command, includeCommands, enabledOnly)
    local stream = OmiChat.chatCommandToStream(command, includeCommands, enabledOnly)
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

---Retrieves a stream given its identifier.
---@param identifier string
---@return omichat.StreamInfo?
function OmiChat.getChatStreamByIdentifier(identifier)
    for i = 1, #ISChat.allChatStreams do
        local stream = ISChat.allChatStreams[i]
        local id = stream.omichat and stream.omichat.streamIdentifier
        if not id then
            id = stream.name
        end

        if id == identifier then
            return StreamInfo:new(stream)
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

---Determines the color options that should be enabled based on the server configuration.
---@param all boolean? If given, all possible color options will be returned instead.
---@return omichat.ColorCategory[]
function OmiChat.getColorOptions(all)
    local colorOpts = {}
    local canUsePM = checkPlayerCanUseChat('/w')
    local useLocalWhisper = OmiChat.isCustomStreamEnabled('whisper')

    if all or Option.EnableSetNameColor then
        colorOpts[#colorOpts + 1] = 'name'
    end

    if all or Option.EnableSetSpeechColor then
        colorOpts[#colorOpts + 1] = 'speech'
    end

    colorOpts[#colorOpts + 1] = 'server'

    if all or Option:showDiscordColorOption() then
        colorOpts[#colorOpts + 1] = 'discord'
    end

    if all then
        colorOpts[#colorOpts + 1] = 'radio'
    else
        -- need to check the option because checkPlayerCanUseChat checks for a radio item
        local allowedStreams = getServerOptions():getOption('ChatStreams'):split(',')
        for i = 1, #allowedStreams do
            if allowedStreams[i] == 'r' then
                colorOpts[#colorOpts + 1] = 'radio'
                break
            end
        end
    end

    if all or checkPlayerCanUseChat('/a') then
        colorOpts[#colorOpts + 1] = 'admin'
    end

    if all or checkPlayerCanUseChat('/all') then
        colorOpts[#colorOpts + 1] = 'general'
    end

    if all or checkPlayerCanUseChat('/f') then
        colorOpts[#colorOpts + 1] = 'faction'
    end

    if all or checkPlayerCanUseChat('/sh') then
        colorOpts[#colorOpts + 1] = 'safehouse'
    end

    if all or (useLocalWhisper and canUsePM) then
        colorOpts[#colorOpts + 1] = 'private' -- /pm
    end

    if all or checkPlayerCanUseChat('/s') then
        colorOpts[#colorOpts + 1] = 'say'
    end

    if all or checkPlayerCanUseChat('/y') then
        colorOpts[#colorOpts + 1] = 'shout'
    end

    if not all and (not useLocalWhisper and canUsePM) then
        colorOpts[#colorOpts + 1] = 'private' -- /whisper
    end

    for info in config:chatStreams() do
        local name = info.name
        if info.autoColorOption ~= false and (all or OmiChat.isCustomStreamEnabled(name)) then
            colorOpts[#colorOpts + 1] = name
        end
    end

    return colorOpts
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
---@return (string | omichat.EmoteHandler)?
function OmiChat.getEmote(emote)
    return OmiChat._emotes[emote]
end

---Returns the first emote found from an emote shortcut in the provided text.
---@param text string
---@return (string | omichat.EmoteHandler)? emoteOrHandler
---@return integer? start
---@return integer? finish
---@return string? inputEmote
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
        if emoteToPlay then
            return emoteToPlay, start, finish, emote:lower()
        end

        startPos = finish + 1
    end
end

---Gets the text that should display when clicking the info button.
---@param player IsoPlayer? The player to use to populate token values. If `nil`, this will be player 1.
---@return string
function OmiChat.getInfoRichText(player)
    player = player or getSpecificPlayer(0)
    if not player then
        return ''
    end

    local tokens = OmiChat.getPlayerSubstitutions(player)
    if not tokens then
        return ''
    end

    local name = OmiChat.getPlayerNameInChat(player, 'say')
    tokens.name = name and utils.escapeRichText(name) or ''
    return utils.interpolate(Option.FormatInfo, tokens, player:getUsername())
end

---Returns the current leftmost button.
---@return ISButton?
function OmiChat.getLeftmostButton()
    if OmiChat._leftmostBtn then
        return OmiChat._leftmostBtn
    end

    local instance = ISChat.instance
    if instance then
        return instance.gearButton
    end
end

---Returns the list of custom setting handlers for a given category.
---@param category omichat.SettingCategory
---@return omichat.SettingHandlerCallback[]
function OmiChat.getSettingHandlers(category)
    return OmiChat._settingHandlers[category]
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

---Retrieves the search callback for an argument type.
---@param argType string
---@return omichat.SuggestSearchCallback?
function OmiChat.getSuggesterArgTypeCallback(argType)
    return OmiChat._customSuggesterArgTypes[argType]
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

---Returns whether the player is currently typing.
---@return boolean
function OmiChat.getTyping()
    return OmiChat._isTyping
end

---Returns the current display string for the typing indicator.
---@param maxWidth integer?
---@return string?
function OmiChat.getTypingDisplay(maxWidth)
    local display = OmiChat._typingDisplay
    local txtMgr = getTextManager()

    if display and maxWidth and txtMgr:MeasureStringX(UIFont.Small, display) > maxWidth then
        display = utils.interpolate(Option.FormatTyping, { alt = true })
    end

    return display
end

---Hides the suggester box if it's currently visible.
function OmiChat.hideSuggesterBox()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox then
        suggesterBox:setVisible(false)
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

---Sends a message on the given stream.
---@param args omichat.SendArgs?
---@return string?
function OmiChat.send(args)
    if not args then
        return
    end

    local text = utils.trim(args.command or args.text or '')
    if #text == 0 then
        return
    end

    local stream = args.stream
    if not stream then
        stream = OmiChat.getChatStreamByIdentifier('say')
        if not stream then
            return
        end
    end

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

    local language
    local currentLanguage = OmiChat.getCurrentRoleplayLanguage()
    if currentLanguage and currentLanguage ~= OmiChat.getDefaultRoleplayLanguage() then
        language = currentLanguage
    end

    local initialText = text
    local formatResult = OmiChat.formatForChat {
        text = text,
        language = language,
        chatType = chatType,
        icon = args.icon,
        isEcho = args.isEcho,
        echoType = args.echoType,
        stream = args.streamName or stream:getIdentifier(),
        formatterName = args.formatterName or stream:getFormatterName(),
        playSignedEmote = args.playSignedEmote,
        tokens = args.tokens,
    }

    text = formatResult.text
    if text == '' then
        if formatResult.error then
            OmiChat.addInfoMessage(formatResult.error)
        end

        return
    end

    local processResult
    local process = OmiChat.raw[chatType] or OmiChat.raw.say
    if process then
        processResult = process(prefix .. text)
        if processResult and chatType == 'whisper' and OmiChat.getRetainCommand(stream:getCommandType()) then
            local chatText = ISChat.instance.chatText
            chatText.lastChatCommand = concat { chatText.lastChatCommand, tostring(processResult), ' ' }
        end
    end

    local isSigned = formatResult.allowLanguage and language and OmiChat.isRoleplayLanguageSigned(language)
    if isSigned and args.playSignedEmote and OmiChat.getSignEmotesEnabled() then
        local player = getSpecificPlayer(0)
        if player then
            player:playEmote(OmiChat.getSignLanguageEmote(initialText))
        end
    end

    local username = utils.getPlayerUsername()
    local tokens = args.tokens and utils.copy(args.tokens) or {}
    tokens.chatType = chatType
    tokens.input = initialText
    tokens.username = username
    tokens.name = OmiChat.getNameInChat(username, chatType)
    tokens.stream = stream:getIdentifier()

    if utils.testPredicate(Option.PredicateApplyBuff, tokens) then
        tryApplyBuff()
    end

    local echoType = echoTypes[chatType]
    if Option.ChatFormatEcho ~= '' and echoType then
        local echoStream = OmiChat.getChatStreamByIdentifier('low')
        if not echoStream or not echoStream:isEnabled() then
            echoStream = OmiChat.getChatStreamByIdentifier('say')

            if not echoStream or not echoStream:isEnabled() then
                return processResult
            end
        end

        local useCallback = echoStream:getUseCallback() or OmiChat.send
        useCallback {
            isEcho = true,
            echoType = echoType,
            stream = echoStream,
            text = initialText,
            command = initialText,
            icon = args.icon,
        }
    end

    return processResult
end

---Sends an /admin message, formatted according to configuration.
---@param args string | omichat.SendArgs
function OmiChat.sendAdmin(args)
    OmiChat.send(transformSendArgs(args, 'admin'))
end

---Sends a /faction message, formatted according to configuration.
---@param args string | omichat.SendArgs
function OmiChat.sendFaction(args)
    OmiChat.send(transformSendArgs(args, 'faction'))
end

---Sends an /all message, formatted according to configuration.
---@param args string | omichat.SendArgs
function OmiChat.sendGeneral(args)
    OmiChat.send(transformSendArgs(args, 'general'))
end

---Sends a /pm message, formatted according to configuration.
---@param args string | omichat.SendArgs
---@return string
function OmiChat.sendPM(args)
    return OmiChat.send(transformSendArgs(args, 'private')) or ''
end

---Sends a /safehouse message, formatted according to configuration.
---@param args string | omichat.SendArgs
function OmiChat.sendSafehouse(args)
    OmiChat.send(transformSendArgs(args, 'safehouse'))
end

---Sends a /say message, formatted according to configuration.
---@param args string | omichat.SendArgs
function OmiChat.sendSay(args)
    OmiChat.send(transformSendArgs(args, 'say'))
end

---Sends a /yell message, formatted according to configuration.
---@param args string | omichat.SendArgs
function OmiChat.sendShout(args)
    OmiChat.send(transformSendArgs(args, 'shout'))
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

---Sets whether the player is currently typing.
---@param isTyping boolean
function OmiChat.setTyping(isTyping)
    OmiChat._isTyping = isTyping
end

---Updates the positions of custom buttons.
function OmiChat.updateButtons()
    local instance = ISChat.instance
    if not instance or not instance.gearButton then
        return
    end

    local th = instance:titleBarHeight()
    local lastBtn = instance.gearButton
    for i = 1, #OmiChat._customButtons do
        local btn = OmiChat._customButtons[i]
        if btn:getParent() ~= instance then
            instance:addChild(btn)
        end

        if btn:isVisible() then
            local pad = max(lastBtn:getWidth(), th)
            btn:setX(lastBtn:getX() - pad - pad / 2)
            lastBtn = btn
        end
    end

    OmiChat._leftmostBtn = lastBtn
end

---Updates the chat panel size based on the configured options.
function OmiChat.updateChatPanelSize()
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
    if Option.PredicateShowTypingIndicator ~= '' and OmiChat.getShowTyping() then
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
function OmiChat.updateChatVisibility()
    local instance = ISChat.instance
    if not instance or not instance.closeButton then
        return
    end

    local closeBtn = ISChat.instance.closeButton
    if closeBtn and closeBtn:isVisible() == Option.EnableAlwaysShowChat then
        closeBtn:setVisible(not Option.EnableAlwaysShowChat)
    end

    if Option.EnableAlwaysShowChat then
        ISChat.instance:setVisible(true)
    end
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

---Updates the info text to the configured value.
---@param player IsoPlayer?
function OmiChat.updateInfoText(player)
    local instance = ISChat.instance
    if not instance then
        return
    end

    instance:setInfo(OmiChat.getInfoRichText(player))
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
    updateAliases()
    addOrRemoveIconComponents()
    OmiChat.updateChatPanelSize()
    OmiChat.updateInfoText()
    OmiChat.updateChatVisibility()
    OmiChat.updateButtons()

    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if username then
        OmiChat.refreshLanguageInfo(username)
    end

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

---Updates the display string for typing players based on the current typing information.
function OmiChat.updateTypingDisplay()
    if not OmiChat.getShowTyping() then
        OmiChat._typingDisplay = nil
        return
    end

    local list = {}
    local inactive = {}

    local now = getTimestampMs()
    for username, info in pairs(OmiChat._typingInfo) do
        if now - info.lastUpdate >= 5000 then
            inactive[#inactive + 1] = username
        else
            list[#list + 1] = info.display
        end
    end

    for _, username in pairs(inactive) do
        OmiChat._typingInfo[username] = nil
    end

    if #list == 0 then
        OmiChat._typingDisplay = nil
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

    local text = utils.interpolate(Option.FormatTyping, tokens) ---@type string?
    if text == '' then
        text = nil
    end

    OmiChat._typingDisplay = text
end

---Updates the typing status based on the current input.
---@param skipTimer boolean?
function OmiChat.updateTypingStatus(skipTimer)
    if not OmiChat.getShowTyping() then
        if wasTyping then
            wasTyping = false
            OmiChat.setTyping(false)
            OmiChat.sendTypingStatus()
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
        local stream, command = OmiChat.chatCommandToStream(text, false, true)

        if not stream and not utils.startsWith(trimmed, '/') then
            stream = OmiChat.getDefaultTabStream(1)
            command = trimmed
        end

        local tokens
        if stream and #command:trim() > 0 and stream:isTabID(instance.currentTabID) then
            chatType = stream:getChatType()
            range = stream:getRange()
            tokens = {
                input = command,
                range = range,
                isRanged = range ~= nil,
                chatType = chatType,
                stream = stream:getIdentifier(),
            }
        end

        if not tokens or not utils.testPredicate(Option.PredicateShowTypingIndicator, tokens) then
            isTyping = false
        end
    end

    lastTypingUpdate = now
    OmiChat.setTyping(isTyping)
    if isTyping or wasTyping then
        wasTyping = isTyping

        OmiChat.sendTypingStatus(range, chatType)
    end
end
