local Stream = require 'OmiChat/Component/Stream'
local defaultStreamData = require 'OmiChat/Definition/DefaultStreamData'
local utils = require 'OmiChat/utils'

local checkPlayerCanUseChat = checkPlayerCanUseChat


---@class omichat.ChatStream : omichat.Stream
local ChatStream = Stream:derive()


---@type table<omichat.ChatTypeString, string>
local checkCommands = {
    general = '/all',
    whisper = '/w',
    say = '/s',
    shout = '/y',
    faction = '/f',
    safehouse = '/sh',
    admin = '/a',
}

local otherReservedNames = {
    server = true,
    radio = true,
    speech = true,
    discord = true,
}


---Returns whether a string is the name of a built-in stream.
---@static
---@param name string
---@return boolean
function ChatStream.isReservedName(name)
    if defaultStreamData[name] or otherReservedNames[name] then
        return true
    end

    return false
end

---Checks whether a stream definition is valid.
---@static
---@param def omichat.Configuration.StreamDefinition
---@return boolean
function ChatStream.isValidDefinition(def)
    if not def.Stream or def.Stream == 'custom' then
        local name = def.Name and def.Name:lower() or ''
        return not utils.isNilOrWhitespace(name) and not ChatStream.isReservedName(name)
    end

    return not utils.isNilOrWhitespace(def.Stream)
end

---Creates a chat stream given a stream definition, if it's valid.
---@static
---@param def omichat.Configuration.StreamDefinition
---@param additionalTags string[]?
---@return omichat.ChatStream?
function ChatStream.fromDefinition(def, additionalTags)
    if not ChatStream.isValidDefinition(def) then
        return
    end

    local name = (not def.Stream or def.Stream == 'custom') and def.Name or def.Stream
    if not name then
        return
    end

    return ChatStream:new {
        name = utils.trim(name):lower(),
        command = def.Command,
        shortCommand = def.ShortCommand,
        tabID = def.ChatType == 'admin' and 2 or 1,
        aliases = def.Aliases,
        chatType = def.ChatType,
        commandType = def.CommandType,
        disabled = def.Enable == false,
        range = def.Range,
        verticalRange = def.VerticalRange,
        perceptionRange = def.PerceptionRange,
        allowBuffs = def.AllowBuffs,
        allowEmotes = def.AllowEmotes,
        allowLanguages = def.AllowLanguages,
        allowTypingIndicator = def.AllowTypingIndicator,
        attractZombies = def.AttractZombies,
        defaultColor = def.DefaultColor,
        useNarrativeStyle = def.UseNarrativeStyle,
        chatFormat = def.ChatFormat,
        overheadFormat = def.OverheadFormat,
        tags = utils.append({}, def.Tags or {}, additionalTags or {}),
        suggestSpec = def.ChatType == 'whisper' and { 'online-username' } or nil,
    }
end


---Returns whether the stream can attract zombies.
---@return boolean
function ChatStream:canAttractZombies()
    return self.attractZombies
end

---Returns whether the chat stream uses narrative style when it's enabled.
---@return boolean
function ChatStream:canUseNarrativeStyle()
    return self.useNarrativeStyle
end

---Checks whether the local player can use this stream.
---@return boolean
function ChatStream:checkPlayerCanUse()
    if not Stream.checkPlayerCanUse(self) then
        return false
    end

    local chatType = self:getChatType()
    local command = checkCommands[chatType]
    if command and not checkPlayerCanUseChat(command) then
        return false
    end

    return true
end

---Returns whether the stream applies buffs.
---@return boolean
function ChatStream:isAllowBuffs()
    return self.allowBuffs
end

---Returns whether the stream allows emote macros.
---@return boolean
function ChatStream:isAllowEmotes()
    return self.allowEmotes
end

---Returns whether the stream allows messages to be sent using roleplay languages.
---@return boolean
function ChatStream:isAllowLanguages()
    return self.allowLanguages
end

---Returns whether typing on the stream triggers a typing indicator.
---@return boolean
function ChatStream:isAllowTypingIndicator()
    return self.allowTypingIndicator
end

---Returns whether the chat stream is a ranged chat stream.
---@return boolean
function ChatStream:isRanged()
    local chatType = self.chatType
    return chatType == 'say' or chatType == 'shout'
end

---Returns the chat type that stream messages are sent over.
---@return omichat.ChatTypeString
function ChatStream:getChatType()
    return self.chatType
end

---Returns the default color to use for the stream.
---@return omi.ColorTable
function ChatStream:getDefaultColor()
    if self.defaultColor then
        return utils.copy(self.defaultColor)
    end

    return { r = 255, g = 255, b = 255 }
end

---Returns the perception range of the stream if it's a ranged stream.
---@return integer?
function ChatStream:getPerceptionRange()
    if not self:isRanged() then
        return
    end

    return self.perceptionRange
end

---Returns the range of the stream if it's a ranged stream.
---@return integer?
function ChatStream:getRange()
    if not self:isRanged() then
        return
    end

    return self.range
end

---Gets the 1-indexed tab ID of the stream.
---@return integer
function ChatStream:getTabID()
    return self.tabID
end

---Returns the vertical range of the stream if it's a ranged stream.
---@return integer?
function ChatStream:getVerticalRange()
    if not self:isRanged() then
        return
    end

    return self.verticalRange
end

---Sets the format string used for the chat format of the stream.
---@param format string
function ChatStream:setChatFormat(format)
    self.chatFormat = format
end

---Sets the default color for the stream.
---@param color omi.ColorTable
function ChatStream:setDefaultColor(color)
    self.defaultColor = utils.copy(color)
end


---Creates a new chat stream.
---@param args omichat.Args.ChatStream
---@return omichat.ChatStream
function ChatStream:new(args)
    local this = Stream.new(self, args) ---@cast this omichat.ChatStream

    this.isChat = true
    this.allowLanguages = args.allowLanguages or false
    this.allowTypingIndicator = args.allowTypingIndicator or false
    this.attractZombies = args.attractZombies or false
    this.allowBuffs = args.allowBuffs or false
    this.useNarrativeStyle = args.useNarrativeStyle or false
    this.chatType = args.chatType or 'say'
    this.range = args.range or (this.chatType == 'shout' and 60 or 30)
    this.tabID = args.tabID or 1
    this.verticalRange = args.verticalRange or 2
    this.perceptionRange = args.perceptionRange or 0
    this.defaultColor = args.defaultColor and utils.copy(args.defaultColor) or { r = 255, g = 255, b = 255 }

    return this
end


return ChatStream
