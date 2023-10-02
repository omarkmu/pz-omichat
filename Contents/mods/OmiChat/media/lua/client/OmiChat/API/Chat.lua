local utils = require 'OmiChat/util'
local IconPicker = require 'OmiChat/IconPicker'
local customStreamData = require 'OmiChat/CustomStreamData'

local format = string.format
local concat = table.concat
local pairs = pairs
local ipairs = ipairs
local getText = getText

---@class omichat.ISChat
local ISChat = ISChat


---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Base'
local Option = OmiChat.Option
local IconPicker = OmiChat.IconPicker

local streamDefs = require 'OmiChat/API/Streams'
local streamOverrides = streamDefs.streamOverrides
local customStreams = streamDefs.customStreams


---Fake server message.
local InfoMessage = {
    isServerAlert = function() return false end,
    getText = function(self) return self.text end,
    getTextWithPrefix = function(self)
        local instance = ISChat.instance

        local tag
        if instance.showTitle then
            tag = utils.interpolate(Option.FormatTag, {
                chatType = 'server',
                stream = 'server',
                tag = getText('UI_chat_server_chat_title_id'),
            })
        end

        return concat {
            utils.toChatColor(OmiChat.getColorTable('server')),
            '<SIZE:', instance.chatFont or 'medium', '> ',
            tag or '',
            utils.interpolate(Option.ChatFormatServer, { message = self.text })
        }
    end,
    new = function(self, text, isServerAlert)
        return setmetatable({
            text = tostring(text),
            isServerAlert = isServerAlert
        }, self)
    end,
}
InfoMessage.__index = InfoMessage


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
    for i, chatStream in ipairs(ISChat.allChatStreams) do
        if chatStream == other then
            pos = i + value
            break
        end
    end

    table.insert(ISChat.allChatStreams, pos, stream)

    local tabs = ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for _, tab in ipairs(tabs) do
        if stream.tabID == tab.tabID + 1 then
            pos = #tab.chatStreams + 1
            for i, chatStream in ipairs(tab.chatStreams) do
                if chatStream == other then
                    pos = i + value
                    break
                end
            end

            table.insert(tab.chatStreams, pos, stream)
        end
    end

    return stream
end

---Creates or removes the emoji button and picker from the chat box based on sandbox options.
local function updateEmojiComponents()
    local add = Option.EnableIconPicker
    local instance = ISChat.instance

    local epIncludeMisc = instance.emojiPicker and instance.emojiPicker.includeUnknownAsMiscellaneous
    local includeMisc = Option.EnableMiscellaneousIcons
    if instance.emojiPicker and epIncludeMisc ~= includeMisc then
        instance.emojiPicker.includeUnknownAsMiscellaneous = includeMisc
        instance.emojiPicker:updateIcons()
    end

    if add and instance.emojiButton then
        return
    end

    if not add and not instance.emojiButton then
        return
    end

    if add then
        local size = math.floor(instance.textEntry.height * 0.75)
        instance.emojiButton = ISButton:new(
            instance.width - size * 1.25 - 2.5,
            instance.textEntry.y + instance.textEntry.height * 0.5 - size * 0.5 + 1,
            size,
            size,
            '',
            instance,
            ISChat.onEmojiButtonClick
        )

        instance.textEntry.width = instance.textEntry.width - size * 1.5
        instance.textEntry.javaObject:setWidth(instance.textEntry.width)

        instance.emojiButton.anchorRight = true
        instance.emojiButton.anchorBottom = true
        instance.emojiButton.anchorLeft = false
        instance.emojiButton.anchorTop = false

        instance.emojiButton:initialise()
        instance.emojiButton.borderColor.a = 0
        instance.emojiButton.backgroundColor.a = 0
        instance.emojiButton.backgroundColorMouseOver.a = 0
        instance.emojiButton:setImage(getTexture('Item_PlushSpiffo'))
        instance.emojiButton:setTextureRGBA(0.3, 0.3, 0.3, 1)
        instance.emojiButton:setUIName('chat emoji button')
        instance:addChild(instance.emojiButton)

        instance.emojiButton:bringToTop()

        instance.emojiPicker = IconPicker:new(0, 0, instance, ISChat.onEmojiClick)
        instance.emojiPicker.exclude = OmiChat._iconsToExclude
        instance.emojiPicker.includeUnknownAsMiscellaneous = OmiChat.Option.EnableMiscellaneousIcons

        instance.emojiPicker:initialise()
        instance.emojiPicker:addToUIManager()
        instance.emojiPicker:setVisible(false)

        return
    end

    instance.textEntry.width = instance:getWidth() - instance.inset * 2
    instance.textEntry.javaObject:setWidth(instance.textEntry.width)

    instance:removeChild(instance.emojiButton)
    instance.emojiButton:setVisible(false)
    instance.emojiButton:removeFromUIManager()
    instance.emojiButton = nil

    if instance.emojiPicker then
        instance.emojiPicker:setVisible(false)
        instance.emojiPicker:removeFromUIManager()
        instance.emojiPicker = nil
    end
end

---Creates or updates built-in formatters.
local function updateFormatters()
    for fmtName, info in pairs(customStreamData) do
        local opt = Option[info.overheadFormatOpt]
        if OmiChat._formatters[fmtName] then
            OmiChat._formatters[fmtName]:setFormatString(opt)
        else
            OmiChat._formatters[fmtName] = createFormatter(opt, info.formatID)
        end
    end
end

---Updates streams based on sandbox options.
local function updateStreams()
    -- grab references to insert new streams before default /whisper
    local private, whisper
    local custom = {}
    for _, stream in ipairs(ISChat.allChatStreams) do
        if stream.omichat then
            if stream.name == 'private' then
                private = stream
            elseif stream.name == 'whisper' then
                if stream.omichat.context and stream.omichat.context.ocIsLocalWhisper then
                    whisper = stream
                else
                    private = stream
                end
            elseif customStreamData[stream.name] then
                custom[stream.name] = stream
            end
        elseif stream.name == 'whisper' then
            private = stream
            private.omichat = streamOverrides.private
        elseif streamOverrides[stream.name] then
            stream.omichat = streamOverrides[stream.name]
        end
    end

    if not custom.me then
        custom.me = OmiChat.addStreamBefore(customStreams.me, private)
    end

    if not custom.looc then
        OmiChat.addStreamAfter(customStreams.looc, custom.me)
    end

    if not custom.doloud then
        OmiChat.addStreamAfter(customStreams.doloud, custom.me)
    end

    if not custom.doquiet then
        OmiChat.addStreamAfter(customStreams.doquiet, custom.me)
    end

    if not custom['do'] then
        OmiChat.addStreamAfter(customStreams['do'], custom.me)
    end

    if not custom.meloud then
        OmiChat.addStreamAfter(customStreams.meloud, custom.me)
    end

    if not custom.mequiet then
        OmiChat.addStreamAfter(customStreams.mequiet, custom.me)
    end

    local useLocalWhisper = OmiChat.isCustomStreamEnabled('whisper')
    if useLocalWhisper and not whisper then
        if private then
            -- modify /whisper to be /pm
            private.name = 'private'
            private.command = '/pm '
            private.shortCommand = '/pm '
        end

        -- add custom /whisper
        OmiChat.addStreamBefore(customStreams.whisper, custom.me or private)
    elseif not useLocalWhisper and whisper then
        if private then
            -- revert /pm to /whisper
            private.name = 'whisper'
            private.command = '/whisper '
            private.shortCommand = '/w '
        end

        -- remove custom /whisper
        OmiChat.removeStream(whisper)
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

---Adds a message transformer which can act on message information
---to modify display or behavior.
---@param transformer omichat.MessageTransformer
function OmiChat.addMessageTransform(transformer)
    OmiChat._transformers[#OmiChat._transformers+1] = transformer

    -- not stable sorting
    table.sort(OmiChat._transformers, function(a, b)
        local aPri = a.priority or 1
        local bPri = b.priority or 1

        return aPri > bPri
    end)
end

---Adds a chat stream.
---@param stream omichat.ChatStream
---@return omichat.ChatStream
function OmiChat.addStream(stream)
    ISChat.allChatStreams[#ISChat.allChatStreams+1] = stream

    local tabs = ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for _, tab in ipairs(tabs) do
        if stream.tabID == tab.tabID + 1 then
            tab.chatStreams[#tab.chatStreams+1] = stream
        end
    end

    return stream
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
        local hour, minute = tostring(message:getDatetime()):match('[^T]*T(%d%d):(%d%d)')

        hour = tonumber(hour)
        minute = tonumber(minute)

        if hour and minute then
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
        if options.useChatColor then
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
    for _, transformer in ipairs(OmiChat._transformers) do
        if transformer.transform and transformer:transform(info) == true then
            break
        end
    end
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
    for _, chatText in ipairs(ISChat.instance.tabs) do
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

---Gets a named formatter.
---@param name omichat.CustomStreamName
---@return omichat.MetaFormatter
function OmiChat.getFormatter(name)
    return OmiChat._formatters[name]
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

---Removes a stream from the list of available chat streams.
---@param stream omichat.ChatStream
function OmiChat.removeStream(stream)
    if not stream then
        return
    end

    -- remove from all streams table
    remove(ISChat.allChatStreams, stream)

    -- remove from tab streams
    local tabs = ISChat.instance.tabs
    if tabs then
        remove(tabs, stream)
    end
end

---Removes a message transformer.
---@param transformer omichat.MessageTransformer
function OmiChat.removeMessageTransform(transformer)
    remove(OmiChat._transformers, transformer)
end

---Removes the first message transformer with the provided name.
---@param name string
function OmiChat.removeMessageTransformByName(name)
    local target
    for i, v in ipairs(OmiChat._transformers) do
        if v.name and v.name == name then
            target = i
            break
        end
    end

    if target then
        table.remove(OmiChat._transformers, target)
    end
end

---Redraws the current chat messages.
---@param doScroll boolean? Whether the chat should also be scrolled to the bottom. Defaults to true.
function OmiChat.redrawMessages(doScroll)
    for _, chatText in ipairs(ISChat.instance.tabs) do
        local newText = {}
        local newLines = {}

        for i, msg in ipairs(chatText.chatMessages) do
            local text = msg:getTextWithPrefix()

            newText[#newText+1] = text
            newLines[#newLines+1] = text .. ' <LINE> '

            if i ~= #chatText.chatMessages then
                newText[#newText+1] = ' <LINE> '
            end
        end

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
    if not ISChat.instance.tabs then
        return
    end

    for _, tab in ipairs(ISChat.instance.tabs) do
        tab:setYScroll(-tab:getScrollHeight())
    end
end

---Sets the scroll position of all chat tabs to the top.
function OmiChat.scrollToTop()
    if not ISChat.instance.tabs then
        return
    end

    for _, tab in ipairs(ISChat.instance.tabs) do
        tab:setYScroll(0)
    end
end

---Sets the icons that should be excluded by the icon picker.
---This does not update the icon picker icons. 
---@see omichat.IconPicker.updateIcons
---@param icons table<string, true>?
function OmiChat.setIconsToExclude(icons)
    OmiChat._iconsToExclude = icons or {}
end

---Adds an info message to chat.
---This displays only for the local user.
---@param text string
function OmiChat.showInfoMessage(text)
    ISChat.addLineInChat(InfoMessage:new(text), ISChat.instance.currentTabID - 1)
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
    updateEmojiComponents()

    if redraw then
        -- some sandbox vars affect how messages are drawn
        OmiChat.redrawMessages(false)
    end
end


return OmiChat
