---Handles operations on chat streams.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local MetaFormatter = API.MetaFormatter


---@class omichat.api.client.streams
local Streams = {}
Streams._tagToChatStreams = {}


---Determines stream information given a chat command.
---@param command string The input text.
---@param options omichat.Args.ChatCommandToStream? Options for retrieving the stream.
---@return omichat.Stream? stream
---@return string #The text following the command in the input.
---@return string? #The command or short command that was used.
---@return omichat.Stream? #Information about the disabled stream.
function Streams.chatCommandToStream(command, options)
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
        iterator = Streams.commandStreams()
    elseif options.chatsOnly then
        iterator = Streams.chatStreams()
    else
        iterator = Streams.iter()
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
function Streams.chatCommandToStreamName(command, options)
    local stream = Streams.chatCommandToStream(command, options)
    if stream then
        return stream:getName()
    end
end

---Returns an iterator over chat streams.
---@return fun(): omichat.ChatStream?
function Streams.chatStreams()
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

---Returns an iterator over command streams.
---@return fun(): omichat.CommandStream?
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
---This is used with onSwitchStream.
---@param target string? The name of a target stream to switch to instead of the next stream.
---@return string #The command of the new current stream.
function Streams.cycle(target)
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

---Returns the first enabled chat stream with the given tag.
---@param tag string
---@param excludeTags string[]?
---@return omichat.ChatStream?
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
---@param tags string[]
---@param excludeTags string[]?
---@return omichat.ChatStream?
function Streams.firstChatStreamWithTags(tags, excludeTags)
    excludeTags = excludeTags or {}
    for stream in Streams.chatStreams() do
        if stream:isEnabled() and not stream:hasAnyTags(excludeTags) and stream:hasTags(tags) then
            return stream
        end
    end
end

---Returns the first enabled chat stream without the given tag.
---@param excludeTag string
---@return omichat.ChatStream?
function Streams.firstChatStreamWithoutTag(excludeTag)
    return Streams.firstChatStreamWithTags({}, { excludeTag })
end

---Returns the first enabled chat stream without any of the given tags.
---@param excludeTags string[]
---@return omichat.ChatStream?
function Streams.firstChatStreamWithoutTags(excludeTags)
    return Streams.firstChatStreamWithTags({}, excludeTags)
end

---Retrieves a chat or command stream given its name.
---@param name string
---@return omichat.Stream?
function Streams.get(name)
    for stream in Streams.iter() do
        if name == stream:getName() then
            return stream
        end
    end
end

---Retrieves a chat stream given its name.
---@param name string
---@param options omichat.Args.StreamRetrieval?
---@return omichat.ChatStream?
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
---@param tag string
---@param excludeTags string[]?
---@return omichat.ChatStream[]
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
---@param tags string[]
---@param excludeTags string[]?
---@return omichat.ChatStream[]
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

---Returns enabled chat streams without the given tag.
---@param excludeTag string
---@return omichat.ChatStream[]
function Streams.getChatStreamsWithoutTag(excludeTag)
    return Streams.getChatStreamsWithTags({}, { excludeTag })
end

---Returns enabled chat streams without any of the given tags.
---@param excludeTags string[]
---@return omichat.ChatStream[]
function Streams.getChatStreamsWithoutTags(excludeTags)
    return Streams.getChatStreamsWithTags({}, excludeTags)
end

---Retrieves a command stream given its name.
---@param name string
---@return omichat.CommandStream?
function Streams.getCommandStream(name)
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
function Streams.getDefaultTabStream(tabID)
    local default = ISChat.defaultTabStream[tabID]
    if default and utils.isinstance(default, API.ChatStream) then
        return default
    end
end

---Gets a special stream intended to represent Discord messages.
---This stream should not be used for sending messages.
function Streams.getDiscordStream()
    return API._discordStream
end

---Gets the display command associated with a chat stream.
---If the stream does not exist, this defaults to prefixing a forward slash.
---@param name string
---@return string
function Streams.getDisplayCommand(name)
    local stream = Streams.getChatStream(name)
    if stream then
        return stream:getCommand()
    end

    return '/' .. name
end

---Gets a special stream intended to represent radio messages.
---This stream should not be used for sending messages.
function Streams.getRadioStream()
    return API._radioStream
end

---Gets a special stream intended to represent server messages.
---This stream should not be used for sending messages.
function Streams.getServerStream()
    return API._serverStream
end

---Returns an iterator over chat and command streams.
---@return fun(): omichat.Stream?
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
                ---@cast stream omichat.Stream
                return stream
            end
        end
    end
end

---Updates streams and formatters based on configuration.
function Streams.update()
    Streams._updateFormatters()
    Streams._updateChatStreams()
    Streams._updateOverrides()
end

---Updates the tag cache for chat streams.
function Streams.updateTagCache()
    Streams._tagToChatStreams = {}

    for stream in Streams.chatStreams() do
        local tags = stream:getTags()

        for tag in pairs(tags) do
            if not Streams._tagToChatStreams[tag] then
                Streams._tagToChatStreams[tag] = {}
            end

            local list = Streams._tagToChatStreams[tag]
            list[#list + 1] = stream
        end
    end
end


---Creates or updates metadata formatters.
---@private
function Streams._updateFormatters()
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

        stream:_setTags(info[3]) ---@diagnostic disable-line:invisible
        if formatter then
            formatter:setFormatString(info[2])
        end
    end
end

---Updates chat streams based on configuration options.
---@private
function Streams._updateChatStreams()
    -- collect existing stream formatters
    local existingFormatters = {} ---@type table<string, omichat.MetaFormatter>
    for stream in Streams.chatStreams() do
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

    -- stream IDs must increase in order so players' streams all match
    -- if that's not the case, "recycle" — reallocate all stream formatters and clear old messages
    if needsRecycle then
        utils.log.info('Recycling chat streams')

        toCreate = streams -- update all streams' formatters
        API.ui.clear()     -- clear so old messages don't use the wrong format

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
            formatter = MetaFormatter:new(id)
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
        stream:_setTags(streamConfig.Tags) ---@diagnostic disable-line:invisible
    end

    -- cycle if current stream is now unavailable
    local instance = ISChat.instance
    local chatText = instance and instance.chatText
    if not chatText then
        return
    end

    local lastStream = Streams.chatCommandToStream(chatText.lastChatCommand)
    if lastStream and not lastStream:checkPlayerCanUse() then
        chatText.lastChatCommand = Streams.cycle()
    end

    Streams.updateTagCache()
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


API.streams = Streams
return Streams
