local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'
local config = require 'OmiChat/config'
local Option = require 'OmiChat/Component/Options'


---Stream wrapper for easier retrieval of stream info and mod configuration data.
---@class omichat.StreamInfo : omi.Class
---@field protected _stream omichat.Stream
local StreamInfo = lib.class()


---Returns an iterator over the stream's aliases.
function StreamInfo:aliases()
    local aliases = self:config().aliases or {}
    local i = 0
    return function()
        i = i + 1
        return aliases[i]
    end
end

---Returns the chat command and command remainder if the stream is a match.
---@param command string
---@return string?
---@return string
function StreamInfo:checkMatch(command)
    local isCmdStream = self:isCommand()
    local fullCommand = self:getCommand()
    local shortCommand = self:getShortCommand()

    local commandCompare = command
    local fullCompare = fullCommand
    local shortCompare = shortCommand
    if isCmdStream then
        -- command streams are case-insensitive
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
        local aliasCompare = isCmdStream and alias:lower() or alias
        if utils.startsWith(commandCompare, aliasCompare) then
            return alias, command:sub(#alias)
        end
    end

    return nil, command
end

---Returns the stream's OmiChat configuration, or an empty table.
---@return omichat.ChatStreamConfig | omichat.CommandStreamConfig
function StreamInfo:config()
    return self._stream.omichat or {}
end

---Returns the chat type associated with the stream.
function StreamInfo:getChatType()
    return self:config().chatType or 'say'
end

---Returns the stream's main command.
---@return string
function StreamInfo:getCommand()
    return self:getStream().command
end

---Returns the command type of the stream.
---@return omichat.ChatCommandType
function StreamInfo:getCommandType()
    return self:config().commandType or 'other'
end

---Returns the name of the formatter the stream uses.
---@return string?
function StreamInfo:getFormatterName()
    return self:config().formatter
end

---Returns the callback to use when the /help command is used with the stream.
---@return fun(self: omichat.StreamInfo)?
function StreamInfo:getHelpCallback()
    return self:config().onHelp
end

---Returns the help text for the command stream.
---@return string
function StreamInfo:getHelpText()
    local id = self:getHelpTextStringID()
    if not id then
        return ''
    end

    return getText(id)
end

---Returns the string ID for the command stream's help text.
---@return string?
function StreamInfo:getHelpTextStringID()
    return self:config().helpText
end

---Gets the identifier of the stream.
---@return string
function StreamInfo:getIdentifier()
    return self:config().streamIdentifier or self:getName()
end

---Gets the name of the stream.
---@return string
function StreamInfo:getName()
    return self:getStream().name
end

---Gets the stream's short command.
---@return string?
function StreamInfo:getShortCommand()
    return self:getStream().shortCommand
end

---Returns the raw stream table.
---@return omichat.Stream
function StreamInfo:getStream()
    return self._stream
end

---Gets the 1-indexed tab ID of the stream.
---For command streams, this returns `nil`.
---@return integer?
function StreamInfo:getTabID()
    if self:isCommand() then
        return
    end

    return self:getStream().tabID
end

---Gets the callback to use when the stream is used.
---@return fun(ctx: omichat.SendArgs)?
function StreamInfo:getUseCallback()
    return self:config().onUse
end

---Returns whether the stream allows emotes.
---@return boolean
function StreamInfo:isAllowEmotes()
    local allowEmotes = self:config().allowEmotes
    if allowEmotes ~= nil then
        return allowEmotes
    end

    -- emotes only work via /say or /yell
    local chatType = self:getChatType()
    if chatType ~= 'say' and chatType ~= 'shout' then
        return false
    end

    -- default to false for commands, true for chat streams
    return not self:isCommand()
end

---Returns whether the stream allows the icon picker.
---@return boolean
function StreamInfo:isAllowIconPicker()
    return self:config().allowIconPicker or false
end

---Returns whether this object represents a command stream.
---@return boolean
function StreamInfo:isCommand()
    return self:config().isCommand or false
end

---Returns whether the stream is enabled.
---@return boolean
function StreamInfo:isEnabled()
    local tokens = { stream = self:getIdentifier() }
    if not utils.testPredicate(Option.PredicateEnableStream, tokens) then
        return false
    end

    local cfg = self:config()
    local isEnabled = cfg.isEnabled
    if isEnabled then
        return isEnabled(self)
    end

    local cmd = cfg.isEnabledCommand
    if cmd then
        return checkPlayerCanUseChat(cmd)
    end

    local info = config:getCustomStreamInfo(self:getName())
    if not info then
        return true
    end

    local value = Option[info.chatFormatOpt]
    return value and value ~= ''
end

---Checks the stream's tab ID against a given tab ID.
---If the stream has no tab ID, returns `true`.
---@param otherTabID integer
---@return boolean
function StreamInfo:isTabID(otherTabID)
    local tabID = self:getTabID()
    if not tabID then
        return true
    end

    return tabID == otherTabID
end

---Calls the help callback, if one exists.
function StreamInfo:onHelp()
    local helpCallback = self:getHelpCallback()
    if helpCallback then
        helpCallback(self)
    end
end

---Returns the suggest spec for the stream.
---@return omichat.SuggestSpec?
function StreamInfo:suggestSpec()
    local streamConfig = self:config()
    if streamConfig.suggestSpec then
        return streamConfig.suggestSpec
    end

    if streamConfig.suggestUsernames then
        return { streamConfig.suggestOwnUsername and 'online-username-with-self' or 'online-username' }
    end
end

---Returns whether usernames should be suggested for commands.
---@return boolean
---@deprecated This will be removed in version 2.0. Use `suggestSpec` instead.
function StreamInfo:suggestUsernames()
    return self:config().suggestUsernames or false
end

---Returns whether the player's own username should be suggested for commands.
---@return boolean
---@deprecated This will be removed in version 2.0. Use `suggestSpec` instead.
function StreamInfo:suggestOwnUsername()
    return self:config().suggestOwnUsername or false
end

---Returns the result of the validator, if one is configured. Otherwise, returns true.
---@param input string
---@return boolean
function StreamInfo:validate(input)
    local validator = self:config().validator
    if validator then
        return validator(self, input)
    end

    return true
end


---Creates a new stream info object.
---@param stream omichat.Stream
---@return omichat.StreamInfo
function StreamInfo:new(stream)
    ---@type omichat.StreamInfo
    local this = setmetatable({}, self)

    this._stream = stream

    return this
end


return StreamInfo
