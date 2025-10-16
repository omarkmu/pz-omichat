---Handles chat manipulation.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration

local concat = table.concat
local getText = getText
local getTimestampMs = getTimestampMs
local ISChat = ISChat --[[@as omichat.ISChat]]


---@class omichat.api.client.chat
local Chat = {}
Chat._isTyping = false
Chat._wasTyping = false
Chat._lastTypingUpdate = getTimestampMs()

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


---Adds an info message to chat that displays only for the local user.
---@param text string
---@param serverAlert boolean?
---@param tabID integer? The 1-indexed ID of the chat tab to send the message on. Defaults to the current chat tab.
function Chat.addInfoMessage(text, serverAlert, tabID)
    utils.lib.chat.addInfoMessage(text, serverAlert, tabID)
end

---Returns a playable emote given an emote name.
---Returns `nil` if there is not an emote associated with the emote name.
---@param emote string
---@return (string | omichat.EmoteHandler)?
function Chat.getEmote(emote)
    return API._emotes[emote]
end

---Returns the first emote found from an emote shortcut in the provided text.
---@param text string
---@return (string | omichat.EmoteHandler)? emoteOrHandler
---@return integer? start
---@return integer? finish
---@return string? inputEmote
function Chat.getEmoteFromCommand(text)
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

        local emoteToPlay = emote and Chat.getEmote(emote:lower())
        if emoteToPlay then
            return emoteToPlay, start, finish, emote:lower()
        end

        startPos = finish + 1
    end
end

---Gets an emote meant to simulate sign language based on the given text.
---@param text string
---@return string
function Chat.getSignLanguageEmote(text)
    -- same text should map to same 'sign'
    local rand = newrandom()
    rand:seed(utils.trim(text:lower()))

    return signLanguageEmotes[rand:random(1, #signLanguageEmotes)]
end

---Suggests text based on the provided input text.
---@param text string
---@return omi.ui.SuggestBox.Suggestion[]
function Chat.getSuggestions(text)
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
function Chat.isTyping()
    return Chat._isTyping
end

---Processes a chat command.
---@param args omichat.Args.ProcessCommand
---@return boolean handled
---@return boolean? shouldRetainText
function Chat.processCommand(args)
    local input = args.input
    local instance = ISChat.instance

    if not instance or not input then
        return false
    end

    local stream, command, chatCommand, disabledStream = API.streams.chatCommandToStream(input, { enabledOnly = true })
    local streamToUse ---@type omichat.Stream?

    local commandType = 'other'
    local isHandled = false
    local allowEmotes = false
    local isDefault = false

    if not stream then
        -- process emotes for streamless messages unless there's a leading slash
        local isCommand = utils.startsWith(input, '/')
        allowEmotes = not isCommand
        command = input

        local default = API.streams.getDefaultTabStream(instance.currentTabID)
        if not isCommand and default then
            stream = default
            allowEmotes = not isCommand and default:isAllowEmotes()
            isDefault = true
        end
    end

    if stream then
        isHandled = true

        if not stream:isTabID(instance.currentTabID) then
            -- wrong chat tab
            showWrongChatTabMessage(instance.currentTabID - 1, stream:getTabID() - 1, chatCommand or '')
            stream = nil
            allowEmotes = false
        else
            streamToUse = stream
            allowEmotes = not isDefault and stream:isAllowEmotes() or allowEmotes
            commandType = stream:getCommandType()
        end

        if isDefault then
            stream = nil
        end
    end

    -- handle emotes specified with .emote
    local playedEmote
    if allowEmotes and config:isEmoteMacroEnabled() then
        local emoteToPlay, start, finish, emote = API.chat.getEmoteFromCommand(command)
        if emoteToPlay then
            -- remove the emote text
            isHandled = true
            playedEmote = true
            command = utils.trim(command:sub(1, start - 1) .. command:sub(finish + 1))

            local player = getSpecificPlayer(0)
            if player then
                if type(emoteToPlay) == 'string' then
                    player:playEmote(emoteToPlay)
                else
                    ---@cast emote string
                    emoteToPlay(player, emote)
                end
            end
        end
    end

    -- fix the switching functionality by updating to the used stream
    local shouldRetain = API.preferences.getRetainCommand(commandType)
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

---Sends a message on the given stream.
---@param args omichat.Args.UseStream?
---@return string?
function Chat.send(args)
    local stream = args and args.stream --[[@as omichat.ChatStream]]
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
    local currentLanguage = API.player.getCurrentLanguage()
    if currentLanguage and currentLanguage ~= API.language.getDefault() then
        language = currentLanguage
    end

    local initialText = text
    local formatResult = API.format.chat {
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
            Chat.addInfoMessage(formatResult.error)
        end

        return
    end

    local processResult
    local process = Chat.raw[chatType] or Chat.raw.say
    if process then
        processResult = process(prefix .. text)
        if processResult and chatType == 'whisper' and API.preferences.getRetainCommand(stream:getCommandType()) then
            local chatText = ISChat.instance.chatText
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

    local echoType = echoTypes[chatType]
    if config.EchoMessages.Enable and echoType then
        local echoStream = API.streams.firstChatStreamWithTag('EchoTarget')
        if not echoStream or echoTypes[echoStream:getChatType()] or not echoStream:isEnabled() then
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
---@param args string | omichat.Args.UseStream.Partial
function Chat.sendAdmin(args)
    Chat.send(Chat._transformSendArgs(args, 'admin'))
end

---Sends a /faction message, formatted according to configuration.
---@param args string | omichat.Args.UseStream.Partial
function Chat.sendFaction(args)
    Chat.send(Chat._transformSendArgs(args, 'faction'))
end

---Sends an /all message, formatted according to configuration.
---@param args string | omichat.Args.UseStream.Partial
function Chat.sendGeneral(args)
    Chat.send(Chat._transformSendArgs(args, 'general'))
end

---Sends a /pm message, formatted according to configuration.
---@param args string | omichat.Args.UseStream.Partial
---@return string
function Chat.sendPM(args)
    return Chat.send(Chat._transformSendArgs(args, 'private')) or ''
end

---Sends a /safehouse message, formatted according to configuration.
---@param args string | omichat.Args.UseStream.Partial
function Chat.sendSafehouse(args)
    Chat.send(Chat._transformSendArgs(args, 'safehouse'))
end

---Sends a /say message, formatted according to configuration.
---@param args string | omichat.Args.UseStream.Partial
function Chat.sendSay(args)
    Chat.send(Chat._transformSendArgs(args, 'say'))
end

---Sends a /yell message, formatted according to configuration.
---@param args string | omichat.Args.UseStream.Partial
function Chat.sendShout(args)
    Chat.send(Chat._transformSendArgs(args, 'yell'))
end

---Sets whether the player is currently typing.
---@param isTyping boolean
function Chat.setTyping(isTyping)
    Chat._isTyping = isTyping
end

---Checks whether the chat input should be reset to a slash based on the current input.
---@param prefix string?
---@param text string
---@param internalText string
---@return string?
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
---@param redraw boolean? If true, chat messages will be redrawn.
function Chat.updateState(redraw)
    API.streams.update()

    if not ISChat.instance then
        return
    end

    API.preferences.get()
    API.ui.updateState(redraw)
end

---Updates the typing status based on the current input.
---@param skipTimer boolean?
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

        ---@cast stream omichat.ChatStream?
        if not stream and not utils.startsWith(trimmed, '/') then
            stream = API.streams.getDefaultTabStream(instance.currentTabID)
        end

        if not stream or not stream:isAllowTypingIndicator() then
            isTyping = false
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
---@param stream omichat.Stream
---@private
function Chat._addDisabledStreamMessage(stream)
    local disabledCommand = utils.trim(stream:getCommand())
    local msg = { getText('UI_chat_chat_disabled_msg', disabledCommand) }

    for i = 1, #ISChat.allChatStreams do
        local availableStream = ISChat.allChatStreams[i]

        local availableCommand
        if utils.isinstance(availableStream, API.ChatStream) then
            ---@cast availableStream omichat.ChatStream
            if availableStream:isEnabled() then
                availableCommand = availableStream:getCommand()
            end
        else
            ---@cast availableStream omichat.StreamTable
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
---@param tab omichat.ChatTab
---@private
function Chat._checkLastCommand(tab)
    local lastChatCommand = tab.lastChatCommand
    if not lastChatCommand or lastChatCommand == '' then
        return
    end

    local stream = API.streams.chatCommandToStream(lastChatCommand)
    local commandType = stream and stream:getCommandType() or 'other'
    if not API.preferences.getRetainCommand(commandType) then
        tab.lastChatCommand = ''
    end
end

---Builds send arguments for the given stream.
---@param args string | omichat.Args.UseStream.Partial
---@param streamName string
---@return omichat.Args.UseStream?
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

    args = utils.copy(args) --[[@as omichat.Args.UseStream]]
    args.stream = stream

    return args
end


API.chat = Chat
return Chat
