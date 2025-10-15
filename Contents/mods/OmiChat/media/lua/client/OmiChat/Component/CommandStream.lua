---Stream for sending commands in chat.

local Stream = require 'OmiChat/Component/Stream'
local utils = require 'OmiChat/utils'

local API ---@type omichat.api.client?


---@class omichat.CommandStream : omichat.Stream
local CommandStream = Stream:derive()


---Retrieves help text for the stream, or `nil` if none is defined.
---@return string?
function CommandStream:getHelpText()
    if self.helpTextID then
        return getText(self.helpTextID)
    end
end

---Gets the string ID used to retrieve help text for the stream.
---@return string?
function CommandStream:getHelpTextStringID()
    return self.helpTextID
end

---Handler for when `/help` is used on the stream.
---@return boolean success Indicates whether the command was handled.
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
---@param args omichat.Args.CommandStream
---@return omichat.CommandStream
function CommandStream:new(args)
    local this = Stream.new(self, args) ---@cast this omichat.CommandStream

    this.isCommand = true
    this.allowMentions = args.allowMentions or false
    this.helpTextID = args.helpTextID

    this.callbacks.onHelp = args.onHelp

    return this
end


return CommandStream
