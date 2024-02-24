local lib = require 'OmiChat/lib'


---Stream wrapper for easier retrieval of stream info and mod configuration data.
---@class omichat.StreamInfo : omi.Class
---@field protected _stream omichat.Stream
local StreamInfo = lib.class()


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

---Returns the context table of the stream.
---@return table?
function StreamInfo:getContext()
    return self:config().context
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
---@return fun(ctx: omichat.UseCallbackContext)?
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

    -- default to false for commands
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
    local config = self:config()
    if not config.isEnabled then
        return true
    end

    return config.isEnabled(self)
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
