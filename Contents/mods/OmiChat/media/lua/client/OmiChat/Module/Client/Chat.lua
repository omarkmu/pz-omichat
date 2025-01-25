---Handles chat manipulation.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local getTimestampMs = getTimestampMs
local ISChat = ISChat ---@cast ISChat omichat.ISChat


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
---@return omichat.Suggestion[]
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

---Sends a message on the given stream.
---@param args omichat.Args.Send?
---@return string?
function Chat.send(args)
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

        local useCallback = echoStream:getUseCallback() or Chat.send
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
---@param args string | omichat.Args.Send.Partial
function Chat.sendAdmin(args)
    Chat.send(Chat._transformSendArgs(args, 'admin'))
end

---Sends a /faction message, formatted according to configuration.
---@param args string | omichat.Args.Send.Partial
function Chat.sendFaction(args)
    Chat.send(Chat._transformSendArgs(args, 'faction'))
end

---Sends an /all message, formatted according to configuration.
---@param args string | omichat.Args.Send.Partial
function Chat.sendGeneral(args)
    Chat.send(Chat._transformSendArgs(args, 'general'))
end

---Sends a /pm message, formatted according to configuration.
---@param args string | omichat.Args.Send.Partial
---@return string
function Chat.sendPM(args)
    return Chat.send(Chat._transformSendArgs(args, 'private')) or ''
end

---Sends a /safehouse message, formatted according to configuration.
---@param args string | omichat.Args.Send.Partial
function Chat.sendSafehouse(args)
    Chat.send(Chat._transformSendArgs(args, 'safehouse'))
end

---Sends a /say message, formatted according to configuration.
---@param args string | omichat.Args.Send.Partial
function Chat.sendSay(args)
    Chat.send(Chat._transformSendArgs(args, 'say'))
end

---Sends a /yell message, formatted according to configuration.
---@param args string | omichat.Args.Send.Partial
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
    local suggesterBox = API.ui.suggesterBox
    local visible = suggesterBox and suggesterBox:isVisible()
    if not instance or not suggesterBox or not visible then
        return false
    end

    local item = suggesterBox:getSelectedItem()
    if item then
        API.callback.onSuggesterSelect(instance, item)
        return true
    end

    return false
end

---Updates chat state to match configuration.
---@param redraw boolean? If true, chat messages will be redrawn.
function Chat.updateState(redraw)
    API.streams.update()

    if not ISChat.instance then
        return
    end

    API.preferences.get()

    local username = API.player.getUsername()
    if username then
        API.data.refreshLanguageInfo(username)
    end

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
---@param args string | omichat.Args.Send.Partial
---@param streamName string
---@return omichat.Args.Send?
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

    args = utils.copy(args) ---@cast args omichat.Args.Send
    args.stream = stream

    return args
end


API.chat = Chat
return Chat
