---Base stream type.
---@namespace omichat

local utils = require 'OmiChat/Utils'
local config = require 'OmiChat/Component/Configuration'
local API ---@type api.client?

local isempty = table.isempty


---@class Stream : omi.Class
---@field protected callbacks Stream.Callbacks Container for callbacks.
---@field protected name string The name of the stream.
---@field protected command string The stream command, with a trailing space.
---@field protected shortCommand? string An optional short stream command, with a trailing space.
---@field protected disabled? boolean Flag for whether the stream should always be treated as not enabled.
---@field protected aliasesList string[] Additional aliases for the stream.
---@field protected category StreamCategory The stream category, used to determine whether input should be retained.
---@field protected allowMentions boolean Flag for whether to allow mentions on this stream.
---@field protected suggestSpec? SuggestArgSpec[] Spec to use for suggestions.
---@field protected tags omi.SetTable<string> A set of tags for the stream.
---@field protected autoTags omi.SetTable<string> A set of tags to always include on the stream.
---@field protected isChat boolean Flag for whether this is a chat stream.
---@field protected isCommand boolean Flag for whether this is a command stream.
---@field protected noTags boolean Flag for whether the stream has an empty tags table.
---@field protected defaultOnDisabled boolean Flag for whether the stream should defer to default handling when disabled.
local Stream = utils.class('Stream')


---Converts a string into a command by ensuring it starts with `/` and has a trailing whitespace.
---@param str? string The string to convert.
---@return string command
---@private
function Stream._stringToCommand(str)
    str = utils.trim(str or '')
    if not utils.startsWith(str, '/') then
        str = '/' .. str
    end

    if not utils.endsWith(str, ' ') then
        str = str .. ' '
    end

    return str
end


---Returns an iterator over the stream's aliases.
---@return fun(): string? iterator
function Stream:aliases()
    local aliases = self.aliasesList
    local i = 0
    return function()
        i = i + 1
        return aliases[i]
    end
end

---Returns whether the chat stream uses name colors when available.
---@return boolean canUse
function Stream:canUseNameColors()
    return self.tags.UseNameColor == true
end

---Returns the chat command and command remainder if the stream is a match.
---Checks whether the input text matches one of the stream commands.
---@param input string The input text.
---@return string? chatCommand The command that matched the input.
---@return string remainder The remaining input, without the command.
function Stream:checkMatch(input)
    local fullCommand = self:getCommand()
    local shortCommand = self:getShortCommand()

    local commandCompare = input
    local fullCompare = fullCommand
    local shortCompare = shortCommand
    local isCaseInsensitive = self:isCaseInsensitive()
    if isCaseInsensitive then
        commandCompare = input:lower()
        fullCompare = fullCommand:lower()
        shortCompare = shortCommand and shortCommand:lower()
    end

    if utils.startsWith(commandCompare, fullCompare) then
        return fullCommand, input:sub(#fullCommand)
    elseif shortCompare and utils.startsWith(commandCompare, shortCompare) then
        return shortCommand, input:sub(#shortCommand)
    elseif self:isCommandStream() and commandCompare == utils.trim(fullCompare) then
        -- commands can be entered with no trailing space
        return input, ' '
    end

    for alias in self:aliases() do
        local aliasCompare = isCaseInsensitive and alias:lower() or alias
        if utils.startsWith(commandCompare, aliasCompare) then
            return alias, input:sub(#alias)
        end
    end

    return nil, input
end

---Checks whether the local player can use this stream.
---@param ignoreRoles boolean? Flag for whether roles should be ignored for the check.
---@return boolean canUse
function Stream:checkPlayerCanUse(ignoreRoles)
    return true
end

---Checks whether the local player can customize this stream's colors.
---@return boolean canCustomize
function Stream:checkPlayerCanCustomize()
    return self:_isEnabled(self.tags.IgnoreRolesForCustomize)
end

---Copies all settings from another stream into this stream.
---@param other Stream
function Stream:copyFrom(other)
    self.name = other.name
    self.allowMentions = other.allowMentions
    self.disabled = other.disabled
    self.category = other.category
    self.aliasesList = utils.copyList(other.aliasesList)
    self.suggestSpec = other.suggestSpec and utils.copy(other.suggestSpec) or nil
    self.defaultOnDisabled = other.defaultOnDisabled
    self.autoTags = utils.copy(other.autoTags)
    self.command = other.command
    self.shortCommand = other.shortCommand
    self.callbacks = utils.copy(other.callbacks)

    self:setTags(utils.keys(other.tags))
end

---Returns whether the stream allows mentions.
---@return boolean isAllowed
function Stream:isAllowMentions()
    return self.allowMentions
end

---Returns whether the stream should be treated as case-insensitive.
---@return boolean isCaseInsensitive
function Stream:isCaseInsensitive()
    return config.General.CaseInsensitiveChatStreams or self:isCommandStream()
end

---Returns whether this is a chat stream.
---@return boolean isChat
---@return_cast self ChatStream
function Stream:isChatStream()
    return self.isChat
end

---Returns whether this is a command stream.
---@return boolean isCommand
---@return_cast self CommandStream
function Stream:isCommandStream()
    return self.isCommand
end

---Returns `true` if this is a special stream representing Discord messages.
---@return boolean isDiscord
---@return_cast self ChatStream
function Stream:isDiscordStream()
    return self:isChatStream() and self.name == 'discord'
end

---Returns whether the stream is enabled.
---@return boolean enabled
function Stream:isEnabled()
    return self:_isEnabled()
end

---Returns `true` if this is a special stream representing radio messages.
---@return boolean isRadio
---@return_cast self ChatStream
function Stream:isRadioStream()
    return self:isChatStream() and self.name == 'radio'
end

---Returns `true` if this is a special stream representing server messages.
---@return boolean isServer
---@return_cast self ChatStream
function Stream:isServerStream()
    return self:isChatStream() and self.name == 'server'
end

---Returns `true` if this is one of the special streams representing server, radio, or Discord messages.
---@return boolean isSpecial
---@return_cast self ChatStream
function Stream:isSpecialStream()
    if not self:isChatStream() then
        return false
    end

    return self.name == 'server' or self.name == 'radio' or self.name == 'discord'
end

---Checks the stream's tab ID against a given tab ID.
---@param otherTabID integer The tab ID to match against.
---@return boolean isMatch `True` if the tab ID is a match, or if the stream has no tab ID. Otherwise, `false`.
---@diagnostic disable-next-line: unused
function Stream:isTabID(otherTabID)
    return true
end

---Returns the category of the stream.
---Used to determine whether input should be retained.
---@return StreamCategory category
function Stream:getCategory()
    return self.category
end

---Returns the primary command of the stream.
---@return string command
function Stream:getCommand()
    return self.command
end

---Returns help text for the stream.
---@return string? helpText The help text, or `nil` if none is defined. For chat streams, this is always `nil`.
function Stream:getHelpText() end

---Returns the name of the stream.
---@return string name
function Stream:getName()
    return self.name
end

---Returns the short command of the stream.
---@return string? shortCommand
function Stream:getShortCommand()
    return self.shortCommand
end

---Returns the suggest spec for the stream.
---@return SuggestArgSpec[]? argSpecList
function Stream:getSuggestSpec()
    return self.suggestSpec
end

---Gets the 1-indexed tab ID of the stream.
---For non-chat streams, this returns `nil`.
---@return integer tabID The tab ID. For command streams, this is always `-1`.
function Stream:getTabID()
    return -1
end

---Gets the set of tags for the stream.
---@return omi.SetTable<string> tags
function Stream:getTags()
    return utils.copy(self.tags)
end

---Returns whether the stream is tagged with any of the given tags.
---@param tags string[] The list of tags to check for.
---@return boolean hasAnyTag
function Stream:hasAnyTags(tags)
    for i = 1, #tags do
        if self.tags[tags[i]] then
            return true
        end
    end

    return false
end

---Returns whether the stream has no tags.
---@return boolean noTags
function Stream:hasNoTags()
    return self.noTags
end

---Returns whether the stream is tagged with the given tag.
---@param tag string The tag to check for.
---@return boolean hasTag
function Stream:hasTag(tag)
    return self.tags[tag] ~= nil
end

---Returns whether the stream is tagged with all of the given tags.
---@param tags string[]
---@return boolean hasAllTags
function Stream:hasTags(tags)
    for i = 1, #tags do
        if not self.tags[tags[i]] then
            return false
        end
    end

    return true
end

---Handler for when `/help` is used on the stream.
---@return boolean handled Indicates whether the command was handled.
function Stream:onHelp()
    return false
end

---Handler for when the stream is used.
---@param args Args.UseStream.Partial | Args.Send.Partial Arguments for using the stream.
---The stream will be injected into the argument table as `stream`.
---@return boolean handled Indicates whether the command was handled.
function Stream:onUse(args)
    if not args.stream then
        args.stream = self
    end

    ---@cast args Args.UseStream
    local cb = self.callbacks.onUse
    if cb then
        cb(args)
        return true
    end

    if self.isChat then
        API = API or utils.getAPI()
        API.chat.send(args)
        return true
    end

    return false
end

---Handler for when the stream is used while disabled.
---@param command string The remainder text that was sent with the command.
---@return boolean handled Indicates whether the command was handled.
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

---Sets the tags included on the stream.
---The tag cache should **always** be updated after updating tags for a chat stream.
---@param tags string[] The new tags for the stream.
---@see api.client.streams.updateTagCache
function Stream:setTags(tags)
    self.tags = utils.set.table(tags)
    utils.extend(self.tags, self.autoTags)

    if self:isCommandStream() then
        self.tags.IsCommand = true
    end

    self.noTags = isempty(self.tags)
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
---@param input string The input text.
---@return boolean valid Flag for whether the input text is valid for the stream.
---@return string? message A translated error message to report to the player.
---@diagnostic disable-next-line: unused
function Stream:validate(input)
    return true
end


---Returns whether the stream is enabled.
---@param ignoreRoles boolean? Flag for whether roles should be ignored for the check.
---@return boolean enabled
---@protected
function Stream:_isEnabled(ignoreRoles)
    if self.disabled or not self:checkPlayerCanUse(ignoreRoles) then
        return false
    end

    if self.callbacks.isEnabled then
        return self.callbacks.isEnabled(self)
    end

    return true
end


---Creates a new stream.
---@param args Args.Stream Arguments for creation of the stream.
---@return Stream stream
function Stream:new(args)
    local this = utils.new(self)

    this.name = args.name
    this.allowMentions = args.allowMentions ~= false
    this.disabled = args.disabled or false
    this.category = args.category or 'other'
    this.aliasesList = utils.mapList(Stream._stringToCommand, args.aliases or {})
    this.suggestSpec = args.suggestSpec
    this.isChat = false
    this.isCommand = false
    this.defaultOnDisabled = args.defaultOnDisabled ~= false
    this.autoTags = utils.set.table(args.autoTags)
    this:setTags(args.tags or {})

    if not utils.isNilOrWhitespace(args.command) then
        this.command = Stream._stringToCommand(args.command)
    else
        this.command = Stream._stringToCommand(this.name)
    end

    if not utils.isNilOrWhitespace(args.shortCommand) then
        this.shortCommand = Stream._stringToCommand(args.shortCommand)
    end

    this.callbacks = {
        onUse = args.onUse,
        onUseDisabled = args.onUseDisabled,
        isEnabled = args.isEnabled,
    }

    return this
end


return Stream

--#region Type Definitions

---@class Args.Stream
---@field name string The name of the stream.
---@field command? string The stream command, with a trailing space. Defaults to `/` + `name`.
---@field shortCommand? string An optional short stream command, with a trailing space.
---@field aliases? string[] Additional aliases for the stream.
---@field disabled? boolean Flag for whtehr the stream should always be treated as not enabled. Defaults to `false`.
---@field category? StreamCategory The stream category, used to determine whether input should be retained.
---@field isEnabled? fun(stream: Stream): boolean Invoked to check whether the stream should be treated as enabled.
---@field onUse? fun(ctx: Args.UseStream) Invoked when the stream is used.
---@field onUseDisabled? fun(stream: Stream, command: string) Invoked when the stream is used while disabled.
---@field allowMentions? boolean Flag for whether mentions should be allowed on this stream. Defaults to `true`.
---@field suggestSpec? SuggestArgSpec[] Spec to use for suggestions.
---@field tags? string[] Tags for the stream.
---@field autoTags? string[] Tags which should always be included on the stream.
---@field defaultOnDisabled? boolean Flag for whether the stream should defer to default handling when disabled. Defaults to `true`.


---@class Stream.Callbacks
---@field isEnabled? fun(stream: Stream): boolean Invoked to check whether the stream should be treated as enabled.
---@field onUse? fun(ctx: Args.UseStream) Invoked when the stream is used.
---@field onUseDisabled? fun(stream: Stream, command: string) Invoked when the stream is used while disabled.


---@alias StreamCategory 'chat' | 'rp' | 'other'

--#endregion
