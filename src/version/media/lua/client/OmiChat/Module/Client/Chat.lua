---Handles chat manipulation.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'

local utils = API.utils
local config = API.Configuration
local MultiMap = utils.MultiMap

local concat = table.concat
local getTextVanilla = getText
local getText = utils.getText
local getTimestampMs = getTimestampMs
local ISChat = ISChat --[[@as omichat.ISChat]]
local signEmoteRand = newrandom()

---@class api.client.chat
local Chat = {}

---Contains functions related to manipulating the chat.
API.chat = Chat

--#region Static Fields

---Contains raw chat functions for sending without formatting.
Chat.raw = {
    say = processSayMessage,
    shout = processShoutMessage,
    whisper = proceedPM,
    general = processGeneralMessage,
    safehouse = processSafehouseMessage,
    faction = proceedFactionMessage,
    admin = processAdminChatMessage,
}

---Flag for whether the local player is currently typing.
---@private
Chat._isTyping = false

---The typing status from the previous update.
---@private
Chat._wasTyping = false

---The timestamp of the last update of the typing status update.
---@private
Chat._lastTypingUpdate = getTimestampMs()

---Maps chat types to echo type IDs.
---@private
Chat._echoTypes = {
    faction = 1,
    safehouse = 2,
}

---List of emote names used for simulating sign language.
---@private
Chat._signLanguageEmotes = {
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

--#endregion


---Adds an info message to chat that displays only for the local user.
---@param text string The rich text content of the message.
---@param serverAlert boolean? Flag for whether the message should be treated as a server alert.
---@param tabID integer? The 1-indexed ID of the chat tab to send the message on. Defaults to the current chat tab.
function Chat.addInfoMessage(text, serverAlert, tabID)
    utils.lib.chat.addInfoMessage(text, serverAlert, tabID)
end

---Clears the current chat messages.
---@param tabID integer? The 0-indexed ID of the tab to clear. If `nil`, all tabs are cleared.
function Chat.clear(tabID)
    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return
    end

    for i = 1, #tabs do
        local chatText = tabs[i]

        if not tabID or chatText.tabID == tabID then
            chatText.chatMessages = {}
            chatText.chatTextLines = {}
            chatText.text = ''
            chatText:paginate()
        end
    end
end

---Gets a playable emote by name.
---@param name string The name of the emote.
---@return ChatEmote? emote An emote handler, or `nil` if there's no such emote.
function Chat.getEmote(name)
    return API._emotes[name]
end

---Gets a list of enabled emote names.
---@return string[] list
function Chat.getEmoteNames()
    local list = {}
    for i = 1, #API._emoteList do
        local name = API._emoteList[i]
        local emote = API._emotes[name]
        if emote and emote:isEnabled() then
            list[#list + 1] = name
        end
    end

    return list
end

---Returns the first enabled emote found from an emote macro in the provided text.
---@param command string The command to read.
---@return ChatEmote? emote An emote handler, or `nil` if no enabled emote could be found.
---@return integer? start The start position of the emote in the text.
---@return integer? stop The end position of the emote in the text.
---@return string? emoteText The emote name from the text.
function Chat.getEmoteFromCommand(command)
    local startPos = 1
    while startPos < #command do
        local macro = Chat.getNextMacroText(command, startPos)
        if not macro then
            return
        end

        local text = macro.text:lower()
        local emote = Chat.getEmote(text)
        if emote and emote:isEnabled() then
            return emote, macro.start, macro.stop, text
        end

        startPos = macro.stop + 1
    end
end

---Returns the next macro text found in a command, at or after the given start position.
---@param command string The command text to search.
---@param startPos integer? The start position. Defaults to `1`.
---@return MacroTextResult? result
function Chat.getNextMacroText(command, startPos)
    startPos = startPos or 1
    local start, stop, whitespace, text = command:find('(%s*)!([%w_]+)', startPos)
    if not start or not stop or not text then
        return
    end

    -- require leading whitespace unless the macro is at the start
    if start ~= 1 and #whitespace == 0 then
        return
    end

    return {
        start = start,
        stop = stop,
        text = text,
    }
end

---Gets an emote meant to simulate sign language based on the given text.
---@param text string The text to use for retrieval.
---@return string emote An emote name.
function Chat.getSignLanguageEmote(text)
    -- same text should map to same 'sign'
    signEmoteRand:seed(utils.trim(text:lower()))

    local idx = signEmoteRand:random(1, #Chat._signLanguageEmotes) --[[@as integer]]
    return Chat._signLanguageEmotes[idx] --[[@as string]]
end

---Returns whether the player is currently typing.
---@return boolean typing
function Chat.isTyping()
    return Chat._isTyping
end

---Processes a chat command.
---@param args Args.ProcessCommand Arguments for processing the command.
---@return boolean handled
---@return boolean? shouldRetainText
function Chat.processCommand(args)
    local input = args.input
    local instance = ISChat.instance

    if not instance or not input then
        return false
    end

    local stream, command, chatCommand, disabledStream = API.streams.chatCommandToStream(input, { enabledOnly = true })
    local streamToUse ---@type Stream?

    local commandCategory = 'other' ---@type StreamCategory
    local isHandled = false
    local processMacros = false
    local isDefault = false

    if not stream then
        -- process macros for streamless messages unless there's a leading slash
        local isCommand = utils.startsWith(input, '/')
        processMacros = not isCommand
        command = input

        local default = API.streams.getDefaultTabStream(instance.currentTabID)
        if not isCommand and default then
            stream = default
            isDefault = true
        end
    end

    if stream then
        isHandled = true

        if not stream:isTabID(instance.currentTabID) then
            -- wrong chat tab
            showWrongChatTabMessage(instance.currentTabID - 1, stream:getTabID() - 1, chatCommand or '')
            stream = nil
            processMacros = false
        else
            streamToUse = stream
            processMacros = stream:isChatStream()
            commandCategory = stream:getCategory()
        end

        if isDefault then
            stream = nil
        end
    end

    local playedEmote
    if processMacros then
        local macroResult = Chat.processMacros(command)
        command = macroResult.text or command
        playedEmote = macroResult.playedEmote
    end

    -- fix the switching functionality by updating to the used stream
    local shouldRetain = API.preferences.getRetainCommand(commandCategory)
    if shouldRetain and stream then
        API.streams.cycle(stream:getName())
    end

    if streamToUse then
        local success, err = streamToUse:validate(command)
        if err then
            API.chat.addInfoMessage(err)
        end

        if not success then
            isHandled = true
            streamToUse = nil
        end
    end

    -- not handled and no stream → signal not handled
    if not isHandled and not disabledStream then
        return false, shouldRetain
    end

    if disabledStream and not disabledStream:onUseDisabled(command) then
        if disabledStream:isChatStream() then
            -- show default disabled message for chat streams, if not handled
            Chat._addDisabledStreamMessage(disabledStream)
        elseif not isHandled then
            -- no `onUseDisabled` handler for command → default handling
            return false, shouldRetain
        end
    end

    instance:unfocus()
    instance:logChatCommand(input)
    API.ui.scrollToBottom()

    if stream then
        if shouldRetain then
            instance.chatText.lastChatCommand = chatCommand or ''
        else
            -- if the used stream shouldn't be set as the last, cycle to the previous command
            local lastChatStream = API.streams.chatCommandToStreamName(instance.chatText.lastChatCommand)
            if lastChatStream then
                API.streams.cycle(lastChatStream)
            end
        end
    end

    if streamToUse then
        streamToUse:onUse({
            text = command,
            playSignedEmote = not playedEmote,
        })
    end

    doKeyPress(false)
    instance.timerTextEntry = 20

    return true
end

---Processes macros in an input string.
---@param text string The input text.
---@return ProcessMacroResults results
function Chat.processMacros(text)
    if not config.Macros.Enable then
        return {}
    end

    local playedEmote = false
    local hookResult = API.hooks.has.macro and API.hooks.macro(text)
    if hookResult then
        text = hookResult.text or text
        playedEmote = hookResult.playedEmote or false
    end

    if playedEmote or not config.Macros.BuiltIn.Emote then
        return { text = text, playedEmote = playedEmote }
    end

    local player = API.player.get()
    if not player then
        return { text = text }
    end

    local emote, start, stop, emoteName = API.chat.getEmoteFromCommand(text)
    if not emote then
        return { text = text }
    end

    ---@cast start -?
    ---@cast stop -?
    ---@cast emoteName -?

    emote:play(player, emoteName)

    return {
        playedEmote = true,
        text = utils.trim(text:sub(1, start - 1) .. text:sub(stop + 1)),
    }
end

---Sends a message on the given stream.
---@param args Args.Send? Arguments for sending the command.
---@return string? result For private messages, the username of the target when sending is successful. Otherwise, `nil`.
function Chat.send(args)
    local instance = ISChat.instance
    local player = API.player.get()
    if not player or not instance then
        return
    end

    local stream = args and args.stream
    if not args or not stream then
        return
    end

    ---@type string?
    local text
    text = utils.trim(utils.removeInvisible(args.text or ''))

    local prefix = ''
    local chatType = stream:getChatType()
    if chatType == 'whisper' then
        -- don't apply filtering to the username
        local m1, m2 = text:match('^("[^"]*%s+[^"]*"%s)(.+)$')
        if not m1 then
            m1, m2 = text:match('^([^"]%S*%s)(.+)$')
        end

        if not m1 or not m2 then
            -- not a valid whisper chat
            return
        end

        prefix = m1
        text = utils.trim(m2)
    end

    if not args.allowEmpty and #text == 0 then
        return
    end

    local tokens = Chat._getFilterTokens(text, stream, args, player, chatType)
    if not tokens then
        return
    end

    local messageData = API.messages.buildData({
        player = player,
        stream = stream,
        echoType = args.echoType,
        context = args.context,
    })

    local language = messageData.language
    tokens.language = language

    local initialText = tokens.input
    text = Chat._filterInput(tokens)
    if not text or (not args.allowEmpty and #text == 0) then
        return
    end

    if messageData.useNarrative then
        tokens.input = text
        text = Chat._filterInput(tokens, 'FilterNarrativeInput', config.NarrativeStyle.InputFilter)
        if not text or (not args.allowEmpty and #text == 0) then
            return
        end
    end

    local process = Chat.raw[chatType] or Chat.raw.say
    local processResult = process(prefix .. text .. API.messages.encodeData(messageData))
    if processResult and chatType == 'whisper' and API.preferences.getRetainCommand(stream:getCategory()) then
        local chatText = instance.chatText
        chatText.lastChatCommand = chatText.lastChatCommand .. tostring(processResult) .. ' '
    end

    local isSigned = language and API.language.isSigned(language)
    if player and isSigned and args.playSignedEmote and API.preferences.getSignEmotesEnabled() then
        player:playEmote(Chat.getSignLanguageEmote(initialText))
    end

    if config.Buffs.Enable and stream:isAllowBuffs() then
        API.request.applyBuff()
    end

    local echoType = Chat._echoTypes[chatType]
    if echoType and config.EchoMessages.Enable then
        Chat._sendEcho(initialText, echoType)
    end

    return processResult
end

---Sends an /admin message, formatted according to configuration.
---@param args string | Args.Send.Partial Arguments for sending the command.
function Chat.sendAdmin(args)
    Chat.send(Chat._transformSendArgs(args, 'admin'))
end

---Sends a /faction message, formatted according to configuration.
---@param args string | Args.Send.Partial Arguments for sending the command.
function Chat.sendFaction(args)
    Chat.send(Chat._transformSendArgs(args, 'faction'))
end

---Sends an /all message, formatted according to configuration.
---@param args string | Args.Send.Partial Arguments for sending the command.
function Chat.sendGeneral(args)
    Chat.send(Chat._transformSendArgs(args, 'general'))
end

---Sends a /pm message, formatted according to configuration.
---@param args string | Args.Send.Partial Arguments for sending the command.
---@return string username The username of the target user, or the empty string if sending failed.
function Chat.sendPM(args)
    return Chat.send(Chat._transformSendArgs(args, 'private')) or ''
end

---Sends a /safehouse message, formatted according to configuration.
---@param args string | Args.Send.Partial Arguments for sending the command.
function Chat.sendSafehouse(args)
    Chat.send(Chat._transformSendArgs(args, 'safehouse'))
end

---Sends a /say message, formatted according to configuration.
---@param args string | Args.Send.Partial Arguments for sending the command.
function Chat.sendSay(args)
    Chat.send(Chat._transformSendArgs(args, 'say'))
end

---Sends a /yell message, formatted according to configuration.
---@param args string | Args.Send.Partial Arguments for sending the command.
function Chat.sendShout(args)
    Chat.send(Chat._transformSendArgs(args, 'yell'))
end

---Sets whether the player is currently typing.
---@param isTyping boolean Flag for whether the player is typing.
function Chat.setTyping(isTyping)
    Chat._isTyping = isTyping
end

---Checks whether the chat input should be reset to a slash based on the current input.
---@param prefix string? The command to check for prefixing the input.
---@param text string The current entry text.
---@param internalText string The recent internal entry text.
---@return string? matchedPrefix
function Chat.shouldResetText(prefix, text, internalText)
    if not prefix or not utils.startsWith(internalText, prefix) then
        return
    end

    if #text:sub(#prefix + 1, #text) <= 5 and utils.endsWith(internalText, '/') then
        return prefix
    end
end

---Attempts to set the current text with the currently selected suggester box item.
---@return boolean success
function Chat.tryInputSuggestion()
    local instance = ISChat.instance
    local suggesterBox = API.ui.suggestBox
    local visible = suggesterBox and suggesterBox:isVisible()
    if not instance or not suggesterBox or not visible then
        return false
    end

    return suggesterBox:insertSelected()
end

---Updates chat state to match configuration.
---@param redraw boolean? Flag for whether chat messages should be redrawn.
function Chat.updateState(redraw)
    API.streams.update()

    if not ISChat.instance then
        return
    end

    API.preferences.get()
    API.ui.updateState(redraw)

    local tabs = ISChat.instance.tabs or {}
    for i = 1, #tabs do
        Chat._checkLastCommand(tabs[i])
    end
end

---Updates the typing status based on the current input.
---@param skipTimer boolean? Flag for whether the timer for typing updates should be ignored.
function Chat.updateTypingStatus(skipTimer)
    if not config.TypingIndicator.Enable or not API.preferences.getShowTyping() then
        if Chat._wasTyping then
            Chat._wasTyping = false
            Chat._isTyping = false
            API.request.updateTypingStatus()
        end

        return
    end

    local instance = ISChat.instance
    local entry = instance and instance.textEntry
    if not entry or not instance then
        return
    end

    local now = getTimestampMs()
    if not skipTimer and now - Chat._lastTypingUpdate <= 1000 then
        return
    end

    local range
    local chatType
    local isTyping = entry:isFocused() and instance.currentTabID == 1
    if isTyping then
        local text = entry:getInternalText()
        local trimmed = text:trim()
        local stream = API.streams.chatCommandToStream(text, { chatsOnly = true, enabledOnly = true })

        ---@cast stream ChatStream?
        if not stream and not utils.startsWith(trimmed, '/') then
            stream = API.streams.getDefaultTabStream(instance.currentTabID)
        end

        if not stream or not stream:isAllowTypingIndicator() then
            isTyping = false
        else
            local lang = API.player.getCurrentLanguage()
            range = stream:getRange(lang and API.language.isSigned(lang))
            chatType = stream:getChatType()
        end
    end

    Chat._lastTypingUpdate = now
    Chat._isTyping = isTyping
    if isTyping or Chat._wasTyping then
        Chat._wasTyping = isTyping

        API.request.updateTypingStatus(range, chatType)
    end
end

---Text entry validator that validates against the nickname filter.
---@param entry omi.TextEntry The entry to validate.
---@param text string The text to validate. Defaults to the entry text.
---@return boolean valid Flag for whether the name is valid.
---@return string? nickname The filtered name. Guaranteed if `valid` is `true`.
function Chat.validateNameEntry(entry, text)
    if not text then
        text = entry:getInternalText()
    end

    text = utils.trim(text)
    if #text == 0 then
        return true
    end

    local tokens = {
        target = 'nickname',
        input = text,
        error = '',
        errorID = '',
    }

    local nickname = utils.interpolateNamed('FilterName', config.Format.Filter.Name, tokens)
    local err = utils.extractError(tokens)
    if not err and not utils.isNilOrWhitespace(nickname) then
        return true, nickname
    end

    entry:setValidateTooltipText(err or getText('error-invalid-name', { name = utils.escapeRichText(text) }))
    return false
end

---Text entry validator that validates against the status filter.
---@param entry omi.TextEntry The entry to validate.
---@param text string The text to validate.
---@return boolean valid Flag for whether the text is valid.
---@return string? status The filtered status. Guaranteed if `valid` is `true`.
function Chat.validateStatusEntry(entry, text)
    if not text then
        text = entry:getInternalText()
    end

    text = utils.trim(text)
    if #text == 0 then
        return true
    end

    local tokens = {
        input = text,
        error = '',
        errorID = '',
    }

    local status = utils.interpolateNamed('FilterStatus', config.Format.Filter.Status, tokens)
    local err = utils.extractError(tokens)
    if not err and not utils.isNilOrWhitespace(status) then
        return true, status
    end

    entry:setValidateTooltipText(err or getText('error-invalid-status', { status = utils.escapeRichText(text) }))
    return false
end


---Adds an info message to chat that displays the available streams, when an unavailable stream is used.
---@param stream Stream
---@private
function Chat._addDisabledStreamMessage(stream)
    local disabledCommand = utils.trim(stream:getCommand())
    local msg = { getTextVanilla('UI_chat_chat_disabled_msg', disabledCommand) }

    for i = 1, #ISChat.allChatStreams do
        local availableStream = ISChat.allChatStreams[i]

        local availableCommand
        if utils.isinstance(availableStream, API.ChatStream) then
            if availableStream:isEnabled() then
                availableCommand = availableStream:getCommand()
            end
        else
            availableCommand = availableStream.command
        end

        if availableCommand then
            msg[#msg + 1] = '* '
            msg[#msg + 1] = utils.trim(availableCommand)
            msg[#msg + 1] = ' <LINE> '
        end
    end

    if #msg > 1 then
        msg[#msg] = nil
        API.chat.addInfoMessage(concat(msg))
    end
end

---Clears the last chat command for a tab based on retain options.
---This also sets the last chat command to the default stream, if there has not been any input yet.
---@param tab ChatTab
---@private
function Chat._checkLastCommand(tab)
    local lastChatCommand = tab.lastChatCommand
    if not lastChatCommand or lastChatCommand == '' then
        return
    end

    local stream = API.streams.chatCommandToStream(lastChatCommand)
    if #tab.log == 0 then
        local defaultStream = API.streams.getDefaultTabStream(tab.tabID + 1)
        if defaultStream and defaultStream ~= stream and defaultStream:isEnabled() then
            tab.lastChatCommand = API.streams.cycle(defaultStream:getName())
        end

        return
    end

    local commandCategory = stream and stream:getCategory() or 'other'
    if not API.preferences.getRetainCommand(commandCategory) then
        tab.lastChatCommand = ''
    end
end

---Passes text through an input filter.
---@param tokens table Tokens to provide to the filter.
---@param filterName string? The name of the filter to apply. Defaults to `FilterChatInput`.
---@param filterString string? The filter interpolation string. Defaults to the chat input filter.
---@return string? filteredText The text returned from the filter.
---@private
function Chat._filterInput(tokens, filterName, filterString)
    filterName = filterName or 'FilterChatInput'
    filterString = filterString or config.Format.Filter.ChatInput

    local result = utils.interpolateNamed(filterName, filterString, tokens)
    local err = utils.extractError(tokens)
    if err then
        if err then
            Chat.addInfoMessage(err)
        end

        return nil
    end

    return result
end

---Sends an echo message to the configured echo target stream.
---@param text string
---@param echoType integer
---@private
function Chat._sendEcho(text, echoType)
    local echoStream = API.streams.firstChatStreamWithTag('EchoTarget')
    if not echoStream then
        utils.log.warn.once('No stream defined for echo messages; add the `EchoTarget` tag to a stream')
        return
    end

    if not echoStream:isEnabled() then
        utils.log.warn.once('Echo target stream is disabled')
        return
    end

    if Chat._echoTypes[echoStream:getChatType()] then
        utils.log.warn.once('Invalid echo target stream; echo target cannot be faction or safehouse')
        return
    end

    echoStream:onUse({
        text = text,
        echoType = echoType,
    })
end

---Gets an initial token table for filtering an outgoing chat message.
---For private messages, this also returns the recipient string from the command.
---@param text string
---@param stream ChatStream
---@param args Args.Send
---@param player IsoPlayer
---@param chatType omi.ChatTypeString
---@return table? tokens
---@private
function Chat._getFilterTokens(text, stream, args, player, chatType)
    local tokens = {}
    local username = player:getUsername()

    tokens.error = ''
    tokens.errorID = ''
    tokens.chatType = chatType
    tokens.input = text
    tokens.username = username
    tokens.name = username and API.data.getNameInChat(username, chatType)
    tokens.stream = stream:getName()

    local tags = stream:getTags()
    API.messages.addContextData({
        tokens = tokens,
        tags = tags,
        context = args.context,
        isEcho = args.echoType ~= nil,
    })

    tokens.tags = MultiMap.fromSet(tags)
    return tokens
end

---Builds send arguments for the given stream.
---@param args string | Args.Send.Partial
---@param streamName string
---@return Args.Send?
---@private
function Chat._transformSendArgs(args, streamName)
    local stream = API.streams.getChatStream(streamName)
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

    args = utils.copy(args) --[[@as Args.Send]]
    args.stream = stream

    return args
end


return Chat

--#region Type Definitions

---@class Args.ProcessCommand
---@field input string The input text.

---@class Args.UseStream.Partial
---@field text string The text passed to the command, excluding the command name.
---@field stream? Stream The stream being used.

---@class Args.UseStream : Args.UseStream.Partial
---@field stream Stream The stream being used.

---@class Args.Send.Partial : Args.UseStream.Partial
---@field playSignedEmote? boolean Flag for whether a random emote should be played for a signed language.
---@field echoType? integer The echo type identifier, if this is an echo message.
---@field allowEmpty? boolean Flag for whether empty messages should be allowed.
---@field context? table Arbitrary context data.

---@class Args.Send : Args.Send.Partial, Args.UseStream
---@field stream ChatStream The stream being used.


---@class TypingInformation
---@field display string The display name to use for the typing player.
---@field lastUpdate integer The timestamp in milliseconds of the last update of this information.

---@class SuggestionInfo
---@field input string The current input text.
---@field context table Table for arbitrary context data.
---@field suggestions omi.SuggestBox.Suggestion[] The current list of suggestions.

---@class MacroTextResult
---@field start integer The start position of the macro in the text.
---@field stop integer The end position of the macro in the text.
---@field text string The macro text.

---@class ProcessMacroResults
---@field text? string The processed text.
---@field playedEmote? boolean Flag for whether an emote was played.

---@alias ChatFont 'small' | 'medium' | 'large'

---@alias Message ChatMessage | omi.MimicMessage

--#endregion
