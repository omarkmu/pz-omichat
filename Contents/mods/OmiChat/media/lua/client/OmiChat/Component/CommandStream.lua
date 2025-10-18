---Stream for sending commands in chat.

local Stream = require 'OmiChat/Component/Stream'
local utils = require 'OmiChat/Utils'

local API ---@type omichat.api.client?


---@class omichat.CommandStream : omichat.Stream
---@field protected callbacks omichat.CommandStream.Callbacks Container for callbacks.
---@field protected helpTextID string? String ID for a help message for the stream.
local CommandStream = Stream:derive()


---Returns the help text for the stream.
---@return string? helpText The help text, or `nil` if not defined.
function CommandStream:getHelpText()
    if self.helpTextID then
        return getText(self.helpTextID)
    end
end

---Gets the string ID for the stream's help text.
---@return string? stringID The help text string ID, or `nil` if not defined.
function CommandStream:getHelpTextStringID()
    return self.helpTextID
end

---Handler for when `/help` is used on the stream.
---@return boolean handled Indicates whether the command was handled.
function CommandStream:onHelp()
    local cb = self.callbacks.onHelp
    if cb then
        cb(self)
        return true
    end

    local helpText = self:getHelpText()
    if helpText then
        API = API or utils.getAPI()
        API.chat.addInfoMessage(helpText)
        return true
    end

    return false
end


---Creates a new command stream.
---@param args omichat.Args.CommandStream Arguments for creation of the stream.
---@return omichat.CommandStream stream
function CommandStream:new(args)
    local this = Stream.new(self, args) --[[@as omichat.CommandStream]]

    this.isCommand = true
    this.allowMentions = args.allowMentions or false
    this.helpTextID = args.helpTextID

    this.callbacks.onHelp = args.onHelp

    return this
end


return CommandStream


--#region Type Definitions

---@class omichat.CommandStream.Callbacks : omichat.Stream.Callbacks
---@field onHelp omichat.Stream.Callback.OnHelp? Invoked when the `/help` command is used.

---@class omichat.Args.CommandStream : omichat.Args.Stream
---@field helpTextID string? String ID for a help message.
---@field onHelp omichat.Stream.Callback.OnHelp? Invoked when the `/help` command is used.
---@field allowMentions boolean? Flag for whether mentions should be allowed on this stream. Defaults to `false`.


---@alias omichat.Stream.Callback.OnHelp fun(stream: omichat.CommandStream)

--#endregion
