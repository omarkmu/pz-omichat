---Handles operations on chat streams.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration
local ISChat = ISChat --[[@as omichat.ISChat]]


---@class api.client.streams
local Streams = {}

---Contains functions for retrieving and operating on streams.
API.streams = Streams


---Associates tags to chat streams that include them.
---@type table<string, ChatStream[]>
---@private
Streams._tagToChatStreams = {}

---Set of default streams included in vanilla.
---@private
Streams._DEFAULT_STREAMS = {
    say = true,
    yell = true,
    whisper = true,
    faction = true,
    safehouse = true,
    general = true,
    admin = true,
}


---Retrieves a stream given a chat command.
---@param input string The input text.
---@param options Args.ChatCommandToStream? Options for retrieving the stream.
---@return Stream? stream The stream matching the input.
---@return string remainder The text following the command in the input.
---@return string? command The command or short command that was used.
---@return Stream? disabledStream The disabled stream, if one was found.
function Streams.chatCommandToStream(input, options)
    if not input or input == '' then
        return nil, ''
    end

    options = options or {}
    local enabledOnly = options.enabledOnly

    local disabledCommand
    local foundStream
    local chatCommand
    local remainder = input

    local iterator
    if options.commandsOnly then
        iterator = Streams.commandStreams()
    elseif options.chatsOnly then
        iterator = Streams.chatStreams()
    else
        iterator = Streams.iter()
    end

    for stream in iterator do
        local matchedCommand, remainderText = stream:checkMatch(input)
        if matchedCommand and (not enabledOnly or stream:isEnabled()) then
            foundStream = stream
            remainder = remainderText
            chatCommand = matchedCommand
            disabledCommand = nil
            break
        elseif matchedCommand then
            disabledCommand = stream
        end
    end

    return foundStream, remainder, chatCommand, disabledCommand
end

---Retrieves a stream name given a chat command.
---@param command string A chat stream's command, including a leading slash.
---@param options Args.ChatCommandToStream? Options for retrieving the stream.
---@return string? name The name of the chat stream, or `nil` if not found.
function Streams.chatCommandToStreamName(command, options)
    local stream = Streams.chatCommandToStream(command, options)
    if stream then
        return stream:getName()
    end
end

---Returns an iterator over chat streams.
---@return fun(): ChatStream? iterator
function Streams.chatStreams()
    local i = 0
    return function()
        while i < #ISChat.allChatStreams do
            i = i + 1
            local stream = ISChat.allChatStreams[i]
            if stream and utils.isinstance(stream, API.ChatStream) then
                return stream
            end
        end
    end
end

---Returns an iterator over command streams.
---@return fun(): CommandStream? iterator
function Streams.commandStreams()
    local i = 0
    return function()
        while i < #API._commandStreams do
            i = i + 1
            return API._commandStreams[i]
        end
    end
end

---Cycles to the next chat stream.
---This is used with `onSwitchStream`.
---@param target string? The name of a target stream to switch to instead of the next stream.
---@return string command The command of the new current stream.
function Streams.cycle(target)
    local instance = ISChat.instance
    if not instance then
        return ''
    end

    local curChatText = instance.chatText
    local chatStreams = curChatText.chatStreams

    local targetID
    local streamID = curChatText.streamID

    for _ = 0, #chatStreams do
        streamID = streamID % #chatStreams + 1
        local stream = chatStreams[streamID]
        if utils.isinstance(stream, API.ChatStream) then
            if not target or stream:getName() == target then
                if stream:isEnabled() then
                    targetID = streamID
                    break
                end
            end
        end
    end

    if targetID then
        curChatText.streamID = targetID
    end

    local curStream = chatStreams[curChatText.streamID]
    if utils.isinstance(curStream, API.ChatStream) then
        return curStream:getCommand()
    else
        return curStream and curStream.command or ''
    end
end

---Returns the first enabled chat stream with the given tag.
---@param tag string The tag to query for.
---@param excludeTags string[]? Tags to exclude. If a stream includes one of these tags, it will not be returned.
---@return ChatStream? stream
function Streams.firstChatStreamWithTag(tag, excludeTags)
    local list = Streams._tagToChatStreams[tag]
    if not list then
        return
    end

    if not excludeTags then
        return list[1]
    end

    for i = 1, #list do
        local stream = list[i]
        if not stream:hasAnyTags(excludeTags) then
            return stream
        end
    end
end

---Returns the first enabled chat stream with all of the given tags.
---@param tags string[] Tags to query for.
---@param excludeTags string[]? Tags to exclude. If a stream includes one of these tags, it will not be returned.
---@return ChatStream? stream
function Streams.firstChatStreamWithTags(tags, excludeTags)
    excludeTags = excludeTags or {}
    for stream in Streams.chatStreams() do
        if stream:isEnabled() and not stream:hasAnyTags(excludeTags) and stream:hasTags(tags) then
            return stream
        end
    end
end

---Retrieves a chat or command stream given its name.
---@param name string The name of the stream to retrieve.
---@return Stream? stream
function Streams.get(name)
    for stream in Streams.iter() do
        if name == stream:getName() then
            return stream
        end
    end
end

---Retrieves a chat stream given its name.
---@param name string The name of the stream to retrieve.
---@param options Args.StreamRetrieval? Options for retrieving the stream.
---@return ChatStream? stream
function Streams.getChatStream(name, options)
    if name == 'server' then
        return API._serverStream
    elseif name == 'radio' then
        return API._radioStream
    elseif name == 'discord' then
        return API._discordStream
    end

    options = options or {}
    for stream in Streams.chatStreams() do
        if name == stream:getName() and (not options.enabledOnly or stream:isEnabled()) then
            return stream
        end
    end
end

---Returns enabled chat streams with the given tag.
---@param tag string The tag to query for.
---@param excludeTags string[]? Tags to exclude. If a stream includes one of these tags, it will not be included.
---@return ChatStream[] streams
function Streams.getChatStreamsWithTag(tag, excludeTags)
    local list = Streams._tagToChatStreams[tag]
    if not list then
        return {}
    end

    if not excludeTags then
        return utils.copyList(list)
    end

    local matches = {}
    for i = 1, #list do
        local stream = list[i]
        if not stream:hasAnyTags(excludeTags) then
            matches[#matches + 1] = stream
        end
    end

    return matches
end

---Returns enabled chat streams with all of the given tags.
---@param tags string[] Tags to query for.
---@param excludeTags string[]? Tags to exclude. If a stream includes one of these tags, it will not be included.
---@return ChatStream[] streams
function Streams.getChatStreamsWithTags(tags, excludeTags)
    excludeTags = excludeTags or {}
    local streams = {}

    for stream in Streams.chatStreams() do
        if stream:isEnabled() and not stream:hasAnyTags(excludeTags) and stream:hasTags(tags) then
            streams[#streams + 1] = stream
        end
    end

    return streams
end

---Retrieves a command stream given its name.
---@param name string The name of the stream to retrieve.
---@return CommandStream? stream
function Streams.getCommandStream(name)
    for i = 1, #API._commandStreams do
        local stream = API._commandStreams[i]
        if stream:getName() == name then
            return stream
        end
    end
end

---Returns the default chat stream for a given tab ID.
---@param tabID integer The 1-indexed tab ID to retrieve a default stream for.
---@return ChatStream? stream
function Streams.getDefaultTabStream(tabID)
    local default = ISChat.defaultTabStream[tabID]
    if default and utils.isinstance(default, API.ChatStream) then
        return default
    end
end

---Gets the special stream for incoming Discord messages.
---This stream should not be used for sending messages.
---@return ChatStream stream
function Streams.getDiscordStream()
    return API._discordStream
end

---Gets the display command associated with a chat stream.
---If the stream does not exist, this defaults to prefixing a forward slash.
---@param name string The name of the stream.
---@return string command
function Streams.getDisplayCommand(name)
    local stream = Streams.getChatStream(name)
    if stream then
        return stream:getCommand()
    end

    return '/' .. name
end

---Gets the special stream for incoming radio messages.
---This stream should not be used for sending messages.
---@return ChatStream
function Streams.getRadioStream()
    return API._radioStream
end

---Gets the special stream for imcoming server messages.
---This stream should not be used for sending messages.
---@return ChatStream
function Streams.getServerStream()
    return API._serverStream
end

---Returns an iterator over chat and command streams.
---@return fun(): Stream? iterator
function Streams.iter()
    local i = 0
    local numChat = #ISChat.allChatStreams
    local numCommands = #API._commandStreams

    return function()
        while i <= numChat + numCommands do
            i = i + 1
            local stream
            if i <= numChat then
                stream = ISChat.allChatStreams[i]
            else
                stream = API._commandStreams[i - numChat]
            end

            if utils.isinstance(stream, API.Stream) then
                ---@cast stream Stream
                return stream
            end
        end
    end
end

---Updates streams and formatters based on configuration.
function Streams.update()
    Streams._updateCommandStreams()
    Streams._updateChatStreams()
    Streams._updateOverrides()
end

---Updates the tag cache for chat streams.
function Streams.updateTagCache()
    Streams._tagToChatStreams = {}

    for stream in Streams.chatStreams() do
        local tags = stream:getTags()

        for tag in pairs(tags) do
            local list = Streams._tagToChatStreams[tag]
            if not list then
                list = {}
                Streams._tagToChatStreams[tag] = list
            end

            list[#list + 1] = stream
        end
    end
end


---Updates chat streams based on configuration options.
---@private
function Streams._updateChatStreams()
    -- collect existing streams
    local existingStreams = {} ---@type table<string, ChatStream>
    for stream in Streams.chatStreams() do
        existingStreams[stream:getName()] = stream
    end

    -- create stream objects
    local seen = {}
    local streams = {} ---@type ChatStream[]

    local globalTags = config.Streams.GlobalTags
    for def in config:chatStreams() do
        local stream = API.ChatStream.fromDefinition(def, globalTags)
        local name = stream and stream:getName()
        if stream and name and not seen[name] then
            seen[name] = true

            -- stream already exists → update
            local existing = existingStreams[name]
            if existing then
                existing:copyFrom(stream)
                stream = existing
            end

            streams[#streams + 1] = stream
            if #streams == config.MAX_CHAT_STREAMS then
                break
            end
        end
    end

    -- keep unknown streams for compatibility with other mods that add commands
    local unmanagedStreams = {} ---@type StreamTable[]
    for i = 1, #ISChat.allChatStreams do
        local stream = ISChat.allChatStreams[i] --[[@as StreamTable]]
        if not seen[stream.name] and not Streams._DEFAULT_STREAMS[stream.name] and not utils.isinstance(stream, API.Stream) then
            unmanagedStreams[#unmanagedStreams + 1] = stream
        end
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

        local tab = tabs[ tabID --[[@as any]] ]
        if tab then
            tab.chatStreams[#tab.chatStreams + 1] = stream
        end
    end

    -- add back unmanaged streams
    for i = 1, #unmanagedStreams do
        local stream = unmanagedStreams[i]
        ISChat.allChatStreams[#ISChat.allChatStreams + 1] = stream

        if stream.tabID and tabs[stream.tabID] then
            local tabStreams = tabs[stream.tabID].chatStreams
            tabStreams[#tabStreams + 1] = stream
        end
    end

    -- update special stream types
    local special = {
        { API._discordStream, config.Discord },
        { API._radioStream, config.Radio },
        { API._serverStream, config.ServerMessages },
    }

    for i = 1, #special do
        local info = special[i] ---@cast info -?
        local stream = info[1]
        local streamConfig = info[2]

        stream:setOverheadFormat(streamConfig.OverheadFormat)
        stream:setChatFormat(streamConfig.ChatFormat)
        stream:setDefaultColor(streamConfig.DefaultColor --[[@as any]])
        stream:setTags(streamConfig.Tags)
    end

    -- cycle if current stream is now unavailable
    local instance = ISChat.instance
    local chatText = instance and instance.chatText
    if chatText then
        local lastStream = Streams.chatCommandToStream(chatText.lastChatCommand)
        if not lastStream or not lastStream:isEnabled() then
            chatText.lastChatCommand = Streams.cycle()
        end
    end

    Streams.updateTagCache()
end

---Updates command stream information.
---@private
function Streams._updateCommandStreams()
    local commands = config.Commands

    API._cardCommand:setTags(commands.Card.Tags)
    API._flipCommand:setTags(commands.Flip.Tags)
    API._rollCommand:setTags(commands.Roll.Tags)
end

---Updates overrides to chat functions based on configuration options.
---@private
function Streams._updateOverrides()
    local override = {}
    if config.Compatibility.ApplyOverrides then
        local replacements = {
            say = API.chat.sendSay,
            shout = API.chat.sendShout,
            whisper = API.chat.sendPM,
            general = API.chat.sendGeneral,
            safehouse = API.chat.sendSafehouse,
            faction = API.chat.sendFaction,
        }

        local names = {
            shout = 'yell',
            whisper = 'private',
        }

        for key, func in pairs(replacements) do
            local name = names[key] or key
            local stream = Streams.get(name)
            if stream and stream:isEnabled() then
                override[key] = func
            end
        end
    end

    local raw = API.chat.raw
    processSayMessage = override.say or raw.say
    processShoutMessage = override.shout or raw.shout
    proceedPM = override.whisper or raw.whisper
    processGeneralMessage = override.general or raw.general
    processSafehouseMessage = override.safehouse or raw.safehouse
    proceedFactionMessage = override.faction or raw.faction
    processAdminChatMessage = override.admin or raw.admin
end


return Streams

--#region Type Definitions

---@class Args.StreamRetrieval
---@field enabledOnly boolean? Flag for whether only enabled streams should be returned.

---@class Args.ChatCommandToStream : Args.StreamRetrieval
---@field commandsOnly boolean? Flag for whether only command streams should be checked.
---@field chatsOnly boolean? Flag for whether only chat streams should be checked.


---@class StreamTable
---@field name string The name of the stream.
---@field command string The stream command, with a trailing space.
---@field tabID integer The tab ID of the tab in which this stream is available (1-indexed).
---@field shortCommand string? An optional short stream command, with a trailing space.

--#endregion
