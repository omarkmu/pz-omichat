---Base stream type.

local utils = require 'OmiChat/utils'
local config = require 'OmiChat/Component/Configuration'
local API ---@type omichat.api.client?

local isempty = table.isempty


---@class omichat.Stream : omi.Class
local Stream = utils.lib.class()


---Converts a string into a command by ensuring it starts with `/` and has a trailing whitespace.
---@param str string
---@return string
---@private
function Stream._stringToCommand(str)
    str = utils.trim(str)
    if not utils.startsWith(str, '/') then
        str = '/' .. str
    end

    if not utils.endsWith(str, ' ') then
        str = str .. ' '
    end

    return str
end


---Returns an iterator over the stream's aliases.
---@return fun(): string?
function Stream:aliases()
    local aliases = self.aliasesList
    local i = 0
    return function()
        i = i + 1
        return aliases[i]
    end
end

---Returns whether the chat stream uses name colors when available.
---@return boolean
function Stream:canUseNameColors()
    return self.tags.UseNameColor == true
end

---Returns the chat command and command remainder if the stream is a match.
---@param command string
---@return string?
---@return string
function Stream:checkMatch(command)
    local isCmdStream = self:isCommandStream()
    local fullCommand = self:getCommand()
    local shortCommand = self:getShortCommand()

    local commandCompare = command
    local fullCompare = fullCommand
    local shortCompare = shortCommand
    local isCaseInsensitive = self:isCaseInsensitive()
    if isCaseInsensitive then
        -- case-insensitive matching
        commandCompare = command:lower()
        fullCompare = fullCommand:lower()
        shortCompare = shortCommand and shortCommand:lower()
    end

    if utils.startsWith(commandCompare, fullCompare) then
        return fullCommand, command:sub(#fullCommand)
    elseif shortCompare and utils.startsWith(commandCompare, shortCompare) then
        return shortCommand, command:sub(#shortCommand)
    elseif isCmdStream and commandCompare == utils.trim(fullCompare) then
        -- commands can be entered with no trailing space
        return command, ' '
    end

    for alias in self:aliases() do
        local aliasCompare = isCaseInsensitive and alias:lower() or alias
        if utils.startsWith(commandCompare, aliasCompare) then
            return alias, command:sub(#alias)
        end
    end

    return nil, command
end

---Checks whether the local player can use this stream.
---@return boolean
function Stream:checkPlayerCanUse()
    return true
end

---Returns whether the stream allows emote macros.
---@return boolean
function Stream:isAllowEmotes()
    return self.allowEmotes
end

---Returns whether the stream allows mentions.
---@return boolean
function Stream:isAllowMentions()
    return self.allowMentions
end

---Returns whether the stream should be treated as case-insensitive.
---@return boolean
function Stream:isCaseInsensitive()
    return config.General.CaseInsensitiveChatStreams or self:isCommandStream()
end

---Returns whether this is a chat stream.
---@return boolean
function Stream:isChatStream()
    return self.isChat
end

---Returns whether this is a command stream.
---@return boolean
function Stream:isCommandStream()
    return self.isCommand
end

---Returns `true` if this is a special stream representing Discord messages.
---@return boolean
function Stream:isDiscordStream()
    return self:isChatStream() and self.name == 'discord'
end

---Returns whether the stream is enabled.
---@return boolean
function Stream:isEnabled()
    if self.disabled or not self:checkPlayerCanUse() then
        return false
    end

    if self.callbacks.isEnabled then
        return self.callbacks.isEnabled(self)
    end

    return true
end

---Returns `true` if this is a special stream representing radio messages.
---@return boolean
function Stream:isRadioStream()
    return self:isChatStream() and self.name == 'radio'
end

---Returns `true` if this is a special stream representing server messages.
---@return boolean
function Stream:isServerStream()
    return self:isChatStream() and self.name == 'server'
end

---Returns `true` if this is one of the special streams representing server, radio, or Discord messages.
function Stream:isSpecialStream()
    if not self:isChatStream() then
        return false
    end

    return self.name == 'server' or self.name == 'radio' or self.name == 'discord'
end

---Checks the stream's tab ID against a given tab ID.
---If the stream has no tab ID, returns `true`.
---@param otherTabID integer
---@return boolean
function Stream:isTabID(otherTabID)
    local tabID = self:getTabID()
    if not tabID then
        return true
    end

    return tabID == otherTabID
end

---Returns the format string used for chat content from the stream.
---@return string?
function Stream:getChatFormat()
    return self.chatFormat
end

---Returns the chat type that stream messages are sent over.
---For command streams, this returns `nil`.
---@return omichat.ChatTypeString?
function Stream:getChatType() end

---Returns the primary command of the stream.
---@return string
function Stream:getCommand()
    return self.command
end

---Returns the command type of the stream.
---@return omichat.ChatCommandCategory
function Stream:getCommandType()
    return self.commandType
end

---Returns the formatter used to format the overhead text for messages sent on the stream.
---@return omichat.MetaFormatter?
function Stream:getFormatter()
    return self.formatter
end

---Retrieves help text for the stream, or `nil` if none is defined.
---Returns `nil` for chat streams.
---@return string?
function Stream:getHelpText() end

---Returns the name of the stream.
---@return string
function Stream:getName()
    return self.name
end

---Returns the format string used for overhead content from the stream.
---@return string?
function Stream:getOverheadFormat()
    return self.overheadFormat
end

---Returns the range of the stream if it's a ranged stream.
---@return integer?
function Stream:getRange() end

---Returns the short command of the stream.
---@return string?
function Stream:getShortCommand()
    return self.shortCommand
end

---Returns the suggest spec for the stream.
---@return omichat.SuggestSpec?
function Stream:getSuggestSpec()
    return self.suggestSpec
end

---Gets the 1-indexed tab ID of the stream.
---For non-chat streams, this returns `nil`.
---@return integer?
function Stream:getTabID() end

---Gets the set of tags for the stream.
---@return omi.SimpleSet
function Stream:getTags()
    return utils.copy(self.tags)
end

---Returns the vertical range of the stream if it's a ranged stream.
---@return integer?
function Stream:getVerticalRange() end

---Returns whether the stream is tagged with any of the given tags.
---@param tags string[]
---@return boolean
function Stream:hasAnyTags(tags)
    for i = 1, #tags do
        if self.tags[tags[i]] then
            return true
        end
    end

    return false
end

---Returns true if the stream has no tags.
function Stream:hasNoTags()
    return self.noTags
end

---Returns whether the stream is tagged with the given tag.
---@param tag string
---@return boolean
function Stream:hasTag(tag)
    return self.tags[tag] ~= nil
end

---Returns whether the stream is tagged with all of the given tags.
---@param tags string[]
---@return boolean
function Stream:hasTags(tags)
    for i = 1, #tags do
        if not self.tags[tags[i]] then
            return false
        end
    end

    return true
end

---Handler for when `/help` is used on the stream.
---@return boolean success Indicates whether the command was handled.
function Stream:onHelp()
    return false
end

---Handler for when the stream is used.
---@param ctx omichat.Args.Send.Partial
---@return boolean success Indicates whether the command was handled.
function Stream:onUse(ctx)
    ---@cast ctx omichat.Args.Send
    if not ctx.stream then
        ctx.stream = self
    end

    local cb = self.callbacks.onUse
    if cb then
        cb(ctx)
        return true
    end

    if self.isChat then
        API = API or utils.getAPI()
        API.chat.send(ctx)
        return true
    end

    return false
end

---Handler for when the stream is used while disabled.
---@param command string
---@return boolean success Indicates whether the command was handled.
function Stream:onUseDisabled(command)
    local cb = self.callbacks.onUseDisabled
    if cb then
        cb(self, command)
        return true
    end

    if not self.defaultOnDisabled then
        API = API or utils.getAPI()
        API.chat.addInfoMessage('Unknown command ' .. command:sub(2))
        return true
    end

    return false
end

---Sets the formatter used for the stream.
---@param formatter omichat.MetaFormatter
function Stream:setFormatter(formatter)
    self.formatter = formatter
end

---Displays help text for the stream, if it exists.
function Stream:showHelpText()
    local helpText = self:getHelpText()
    if helpText then
        API = API or utils.getAPI()
        API.chat.addInfoMessage(helpText)
    end
end

---Validates stream input.
---@param input string
---@return boolean success
---@return string? message
function Stream:validate(input)
    if self:getChatType() ~= 'whisper' then
        return true
    end

    -- vanilla regex is /("[^"]*\s+[^"]*"|[^"]\S*)\s(.+)/
    if input:match('^"[^"]*%s+[^"]*"%s.+$') or input:match('^[^"]%S*%s.+$') then
        return true
    end

    return false, getText('IGUI_Commands_Whisper')
end

---Sets the tags included on the stream.
---@param tags string[]
---@protected
function Stream:_setTags(tags)
    self.tags = utils.set.simple(tags)
    utils.extend(self.tags, self.autoTags)

    if self:isCommandStream() then
        self.tags.IsCommand = true
    end

    self.noTags = isempty(self.tags)
end


---Creates a new stream.
---@param args omichat.Args.Stream
---@return omichat.Stream
function Stream:new(args)
    local this = setmetatable({}, self) ---@cast this omichat.Stream

    this.name = args.name
    this.allowEmotes = args.allowEmotes or false
    this.allowMentions = args.allowMentions ~= false
    this.disabled = args.disabled or false
    this.commandType = 'other'
    this.aliasesList = utils.map(Stream._stringToCommand, args.aliases or {})
    this.suggestSpec = args.suggestSpec
    this.formatter = args.formatter
    this.isChat = false
    this.isCommand = false
    this.defaultOnDisabled = args.defaultOnDisabled ~= false
    this.autoTags = utils.set.simple(args.autoTags)
    this:_setTags(args.tags or {})

    if args.commandType then
        this.commandType = args.commandType
    end

    if not utils.isNilOrWhitespace(args.command) then
        this.command = Stream._stringToCommand(args.command)
    else
        this.command = Stream._stringToCommand(this.name)
    end

    if not utils.isNilOrWhitespace(args.shortCommand) then
        this.shortCommand = Stream._stringToCommand(args.shortCommand)
    end

    if not utils.isNilOrWhitespace(args.overheadFormat) then
        this.overheadFormat = utils.trim(args.overheadFormat)
    end

    if not utils.isNilOrWhitespace(args.chatFormat) then
        this.chatFormat = utils.trim(args.chatFormat)
    end

    this.callbacks = {
        onUse = args.onUse,
        onUseDisabled = args.onUseDisabled,
        isEnabled = args.isEnabled,
    }

    return this
end


return Stream
