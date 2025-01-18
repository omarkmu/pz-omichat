local Stream = require 'OmiChat/Component/Stream'


---@class omichat.CommandStream : omichat.Stream
local CommandStream = Stream:derive()


---Returns the callback to use when `/help` is used on the stream.
---@return omichat.Stream.Callback.OnHelp?
function CommandStream:getHelpCallback()
    return self.callbacks.onHelp
end

---Retrieves help text for the stream, or `nil` if none is defined.
---@return string?
function CommandStream:getHelpText()
    local id = self:getHelpTextStringID()
    if id then
        return getText(id)
    end
end

---Gets the string ID used to retrieve help text for the stream.
---@return string?
function CommandStream:getHelpTextStringID()
    return self.helpTextID
end

---Handler for when `/help` is used on the stream.
function CommandStream:onHelp()
    local helpCallback = self:getHelpCallback()
    if helpCallback then
        helpCallback(self)
    end
end

---Creates a new command stream.
---@param args omichat.Args.CommandStream
---@return omichat.CommandStream
function CommandStream:new(args)
    local this = Stream.new(self, args) ---@cast this omichat.CommandStream

    this.isCommand = true
    this.helpTextID = args.helpTextID
    this.callbacks.onHelp = args.onHelp

    return this
end


return CommandStream
