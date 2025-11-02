---Handles chat manipulation.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration

local concat = table.concat
local getText = getText
local getTimestampMs = getTimestampMs
local ISChat = ISChat --[[@as omichat.ISChat]]
local signEmoteRand = newrandom()

local _ChatBase = __classmetatables[ChatBase.class].__index
local _getChatType = _ChatBase.getType

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

---Returns the chat type of a chat message.
---@param message Message The message to retrieve the chat type of.
---@return omi.ChatTypeString chatType
function Chat.getMessageChatType(message)
    if utils.isinstance(message, API.MimicMessage) then
        ---@cast message omi.MimicMessage
        return message:getChatType()
    end

    ---@cast message ChatMessage
    return tostring(_getChatType(message:getChat())) --[[@as omi.ChatTypeString]]
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

    local player = getSpecificPlayer(0)
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
    local stream = args and args.stream --[[@as ChatStream]]
    if not args or not stream or not utils.isinstance(stream, API.ChatStream) then
        return
    end

    local text = args.text or ''
    if not args.allowInvisible then
        text = utils.removeInvisible(text)
    end

    text = utils.trim(text)

    local prefix = ''
    local chatType = stream:getChatType()
    if chatType == 'whisper' then
        -- don't apply formatting to the username
        local m1, m2 = text:match('^("[^"]*%s+[^"]*"%s)(.+)$')
        if not m1 then
            m1, m2 = text:match('^([^"]%S*%s)(.+)$')
        end

        if not m1 or not m2 then
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
    local currentLanguage = API.player.getCurrentLanguage()
    if currentLanguage and currentLanguage ~= API.language.getDefault() then
        language = currentLanguage
    end

    local initialText = text
    local formatResult = API.format.chat {
        text = text,
        stream = stream,
        language = language,
        chatType = chatType,
        echoType = args.echoType,
        formatStream = args.formatStream,
        formatter = args.formatter,
        tokens = args.tokens,
        extraTags = args.extraTags,
    }

    text = formatResult.text
    if text == '' then
        if formatResult.error then
            Chat.addInfoMessage(formatResult.error)
        end

        return
    end

    local processResult
    local process = Chat.raw[chatType] or Chat.raw.say
    if process then
        processResult = process(prefix .. text)

        local instance = ISChat.instance
        if instance and processResult and chatType == 'whisper' and API.preferences.getRetainCommand(stream:getCategory()) then
            local chatText = instance.chatText
            chatText.lastChatCommand = chatText.lastChatCommand .. tostring(processResult) .. ' '
        end
    end

    local isSigned = formatResult.allowLanguage and language and API.language.isSigned(language)
    if isSigned and args.playSignedEmote and API.preferences.getSignEmotesEnabled() then
        local player = getSpecificPlayer(0)
        if player then
            player:playEmote(Chat.getSignLanguageEmote(initialText))
        end
    end

    if config.Buffs.Enable and stream:isAllowBuffs() then
        API.player.applyBuff()
    end

    local echoType = Chat._echoTypes[chatType]
    if config.EchoMessages.Enable and echoType then
        local echoStream = API.streams.firstChatStreamWithTag('EchoTarget')
        if not echoStream or Chat._echoTypes[echoStream:getChatType()] or not echoStream:isEnabled() then
            return processResult
        end

        echoStream:onUse({
            echoType = echoType,
            text = initialText,
            formatter = API._metadataFormatters.echo,
            extraTags = config.EchoMessages.Tags,
        })
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
            range = stream:getRange()
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


---Adds an info message to chat that displays the available streams, when an unavailable stream is used.
---@param stream Stream
---@private
function Chat._addDisabledStreamMessage(stream)
    local disabledCommand = utils.trim(stream:getCommand())
    local msg = { getText('UI_chat_chat_disabled_msg', disabledCommand) }

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
---@param tab ChatTab
---@private
function Chat._checkLastCommand(tab)
    local lastChatCommand = tab.lastChatCommand
    if not lastChatCommand or lastChatCommand == '' then
        return
    end

    local stream = API.streams.chatCommandToStream(lastChatCommand)
    local commandCategory = stream and stream:getCategory() or 'other'
    if not API.preferences.getRetainCommand(commandCategory) then
        tab.lastChatCommand = ''
    end
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
---@field formatStream? Stream The stream to use to format the input text. Defaults to `stream`.
---@field formatter? MetaFormatter A formatter to use to format the input. If not given, the formatter from `formatStream` or `stream` is used.
---@field playSignedEmote? boolean Flag for whether a random emote should be played for a signed language.
---@field echoType? integer The echo type identifier, if this is an echo message.
---@field tokens? table Initial tokens to pass to interpolation strings.
---@field extraTags? string[] Additional tags to include in the tags token.
---@field allowInvisible? boolean Flag for whether invisible characters should not be removed from the input.

---@class Args.Send : Args.Send.Partial, Args.UseStream


---@class TypingInformation
---@field display string The display name to use for the typing player.
---@field lastUpdate integer The timestamp in milliseconds of the last update of this information.

---@class SuggestionInfo
---@field input string The current input text.
---@field context table Table for arbitrary context data.
---@field suggestions omi.ui.SuggestBox.Suggestion[] The current list of suggestions.

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
