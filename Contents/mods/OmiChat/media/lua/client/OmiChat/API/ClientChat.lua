---Client API functionality related to manipulating the chat.

local getTexture = getTexture
local min = math.min
local max = math.max
local concat = table.concat
local ISChat = ISChat ---@cast ISChat omichat.ISChat


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
local echoChatTypes = {
    faction = true,
    safehouse = true,
}


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
            command = args,
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

    stats:setHunger(stats:getHunger() - 0.02)
    stats:setThirst(stats:getThirst() - 0.02)
    stats:setStressFromCigarettes(stats:getStressFromCigarettes() - 0.25)
    bodyDamage:setBoredomLevel(bodyDamage:getBoredomLevel() - 50)
    bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - 50)
    modData.ocLastBuff = now
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
---@param enabledOnly boolean? If true, only enabled streams will be returned. Defaults to false.
---@return omichat.StreamInfo? #Information about the stream.
---@return string #The text following the command in the input.
---@return string? #The command or short command that was used.
function OmiChat.chatCommandToStream(command, includeCommands, enabledOnly)
    if not command or command == '' then
        return nil, ''
    end

    if includeCommands == nil then
        includeCommands = true
    end

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
            break
        end

        i = i + 1
    end

    return streamInfo, command, chatCommand
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
    return OmiChat._emotes[emote]
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

---Gets the text that should display when clicking the info button.
---@param player IsoPlayer? The player to use to populate token values. If `nil`, this will be player 1.
---@return string
function OmiChat.getInfoRichText(player)
    player = player or getSpecificPlayer(0)
    if not player then
        return ''
    end

    local name = OmiChat.getPlayerNameInChat(player, 'say')
    local tokens = OmiChat.getPlayerSubstitutions(player)
    if not tokens then
        return ''
    end

    tokens.name = name and utils.escapeRichText(name) or ''
    return utils.interpolate(Option.FormatInfo, tokens, player:getUsername())
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

    local command = utils.trim(args.command)
    if #command == 0 then
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
        local m1, m2 = command:match('^("[^"]*%s+[^"]*"%s)(.+)$')
        if not m1 then
            m1, m2 = command:match('^([^"]%S*%s)(.+)$')
        end

        if not m1 then
            -- not a valid whisper chat
            return
        end

        prefix = m1
        command = m2
    end

    local echoCommand = command
    command = OmiChat.formatForChat {
        text = command,
        chatType = chatType,
        isEcho = args.isEcho,
        stream = stream:getIdentifier(),
        formatterName = args.formatterName or stream:getFormatterName(),
        playSignedEmote = args.playSignedEmote,
        tokens = args.tokens,
    }

    if command == '' then
        return
    end

    local result
    local process = OmiChat.raw[chatType] or OmiChat.raw.say
    if process then
        result = process(prefix .. command)
        if result and chatType == 'whisper' and OmiChat.getRetainCommand(stream:getCommandType()) then
            local chatText = ISChat.instance.chatText
            chatText.lastChatCommand = concat { chatText.lastChatCommand, tostring(result), ' ' }
        end
    end

    if utils.testPredicate(Option.PredicateApplyBuff, { stream = stream:getIdentifier() }) then
        tryApplyBuff()
    end

    if Option.ChatFormatEcho ~= '' and echoChatTypes[chatType] then
        local echoStream = OmiChat.getChatStreamByIdentifier('low')
        if not echoStream or not echoStream:isEnabled() then
            echoStream = OmiChat.getChatStreamByIdentifier('say')

            if not echoStream or not echoStream:isEnabled() then
                return result
            end
        end

        local useCallback = echoStream:getUseCallback() or OmiChat.send
        useCallback {
            isEcho = true,
            stream = echoStream,
            command = echoCommand,
        }
    end

    return result
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
    addOrRemoveIconComponents()
    OmiChat.updateInfoText()

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


proceedPM = OmiChat.sendPM
processSayMessage = OmiChat.sendSay
processShoutMessage = OmiChat.sendShout
processGeneralMessage = OmiChat.sendGeneral
proceedFactionMessage = OmiChat.sendFaction
processAdminChatMessage = OmiChat.sendAdmin
processSafehouseMessage = OmiChat.sendSafehouse
