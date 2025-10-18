---Stream for sending chat messages.

local Stream = require 'OmiChat/Component/Stream'
local defaultStreamData = require 'OmiChat/Definition/DefaultStreamData'
local utils = require 'OmiChat/Utils'

local checkPlayerCanUseChat = checkPlayerCanUseChat


---@class omichat.ChatStream : omichat.Stream
---@field protected allowBuffs boolean Flag for whether the stream can apply buffs when it's used.
---@field protected allowLanguages boolean Flag for whether the stream should allow messages to be sent using roleplay languages.
---@field protected allowTypingIndicator boolean Flag for whether typing on the stream triggers a typing indicator.
---@field protected attractZombies boolean Flag for whether the stream can attract zombies.
---@field protected chatFormat string? The format to use for chat messages.
---@field protected chatType omi.ChatTypeString The chat type that stream messages are sent over.
---@field protected defaultColor omi.ColorTable The default color for messages on the stream.
---@field protected range integer The range of the chat stream.
---@field protected tabID integer The 1-indexed tab ID of the tab in which this stream is available.
---@field protected useNarrativeStyle boolean Flag for whether the stream should apply narrative style (if narrative style is enabled).
---@field protected verticalRange integer The vertical range of the chat stream.
---@field protected perceptionRange integer The perception range of the chat stream.
---@field protected perceptionRangeSigned integer The perception range of the chat stream, for signed languages.
local ChatStream = Stream:derive()


---Associates chat types to commands used to check whether they're enabled.
---@private
ChatStream._checkCommands = {
    general = '/all',
    whisper = '/w',
    say = '/s',
    shout = '/y',
    faction = '/f',
    safehouse = '/sh',
    admin = '/a',
}

---Set of reserved chat names that do not have default data.
---@private
ChatStream._otherReservedNames = {
    server = true,
    radio = true,
    speech = true,
    discord = true,
}


---Returns whether a string is the name of a built-in stream.
---@param name string The name to check.
---@return boolean isReserved
function ChatStream.isReservedName(name)
    if defaultStreamData[name] or ChatStream._otherReservedNames[name] then
        return true
    end

    return false
end

---Checks whether a stream definition is valid.
---@param def omichat.Configuration.StreamDefinition The definition to check.
---@return boolean valid
function ChatStream.isValidDefinition(def)
    if not def.Stream or def.Stream == 'custom' then
        local name = def.Name and def.Name:lower() or ''
        return not utils.isNilOrWhitespace(name) and not ChatStream.isReservedName(name)
    end

    return not utils.isNilOrWhitespace(def.Stream)
end

---Creates a chat stream given a stream definition, if it's valid.
---@param def omichat.Configuration.StreamDefinition The definition to use.
---@param additionalTags string[]? Extra tags to add to the created stream.
---@return omichat.ChatStream? stream
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
        category = def.Category,
        disabled = def.Enable == false,
        range = def.Range,
        verticalRange = def.VerticalRange,
        perceptionRange = def.PerceptionRange,
        perceptionRangeSigned = def.PerceptionRangeSigned,
        allowBuffs = def.AllowBuffs,
        allowEmotes = def.AllowEmotes,
        allowMentions = def.AllowMentions,
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
---@return boolean canAttractZombies
function ChatStream:canAttractZombies()
    return self.attractZombies
end

---Returns whether the chat stream uses narrative style when it's enabled.
---@return boolean canUse
function ChatStream:canUseNarrativeStyle()
    return self.useNarrativeStyle
end

---Checks whether the local player can use this stream.
---@return boolean canUse
function ChatStream:checkPlayerCanUse()
    local chatType = self:getChatType()
    local command = ChatStream._checkCommands[chatType]
    if command and not checkPlayerCanUseChat(command) then
        return false
    end

    return true
end

---Returns whether the stream applies buffs.
---@return boolean allowed
function ChatStream:isAllowBuffs()
    return self.allowBuffs
end

---Returns whether the stream allows messages to be sent using roleplay languages.
---@return boolean allowed
function ChatStream:isAllowLanguages()
    return self.allowLanguages
end

---Returns whether typing on the stream triggers a typing indicator.
---@return boolean allowed
function ChatStream:isAllowTypingIndicator()
    return self.allowTypingIndicator
end

---Returns whether the chat stream is a ranged chat stream.
---@return boolean isRanged
function ChatStream:isRanged()
    local chatType = self.chatType
    return chatType == 'say' or chatType == 'shout'
end

---Returns the chat type that stream messages are sent over.
---@return omi.ChatTypeString chatType
function ChatStream:getChatType()
    return self.chatType
end

---Returns the default color to use for the stream.
---@return omi.ColorTable defaultColor
function ChatStream:getDefaultColor()
    if self.defaultColor then
        return utils.copy(self.defaultColor)
    end

    return { r = 255, g = 255, b = 255 }
end

---Returns the perception range of the stream if it's a ranged stream.
---@return integer? perceptionRange
function ChatStream:getPerceptionRange()
    if not self:isRanged() then
        return
    end

    return self.perceptionRange
end

---Returns the range of the stream if it's a ranged stream.
---@return integer? range
function ChatStream:getRange()
    if not self:isRanged() then
        return
    end

    return self.range
end

---Returns the signed perception range of the stream if it's a ranged stream.
---@return integer? signedPerceptionRange
function ChatStream:getSignedPerceptionRange()
    if not self:isRanged() then
        return
    end

    return self.perceptionRangeSigned
end

---Gets the 1-indexed tab ID of the stream.
---@return integer tabID
function ChatStream:getTabID()
    return self.tabID
end

---Returns the vertical range of the stream if it's a ranged stream.
---@return integer? verticalRange
function ChatStream:getVerticalRange()
    if not self:isRanged() then
        return
    end

    return self.verticalRange
end

---Sets the format string used for the chat format of the stream.
---@param format string The format string to use.
function ChatStream:setChatFormat(format)
    self.chatFormat = format
end

---Sets the default color for the stream.
---@param color omi.ColorTable The color table to set as the default color.
function ChatStream:setDefaultColor(color)
    self.defaultColor = utils.copy(color)
end


---Creates a new chat stream.
---@param args omichat.Args.ChatStream Arguments for creation of the stream.
---@return omichat.ChatStream stream
function ChatStream:new(args)
    local this = Stream.new(self, args) --[[@as omichat.ChatStream]]

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
    this.perceptionRangeSigned = args.perceptionRangeSigned or 0
    this.defaultColor = args.defaultColor and utils.copy(args.defaultColor) or { r = 255, g = 255, b = 255 }

    return this
end


return ChatStream



--#region Type Definitions

---@class omichat.Args.ChatStream : omichat.Args.Stream
---@field defaultColor omi.ColorTable? The default color for messages on the stream.
---@field allowBuffs boolean? Flag for whether the stream can apply buffs when it's used.
---@field allowLanguages boolean? Flag for whether the stream allows messages to be sent using roleplay languages.
---@field allowTypingIndicator boolean? Flag for whether typing on the stream triggers a typing indicator.
---@field attractZombies boolean? Flag for whether the stream can attract zombies.
---@field chatFormat string? The format to use for chat messages.
---@field useNarrativeStyle boolean? Flag for whether the stream should apply narrative style if it's enabled.
---@field chatType omi.ChatTypeString? The chat type that stream messages are sent over.
---@field range integer? The range of the chat stream.
---@field verticalRange integer? The vertical range of the chat stream.
---@field perceptionRange integer? The perception range of the chat stream.
---@field perceptionRangeSigned integer? The perception range of the chat stream, for signed languages.
---@field tabID integer? The 1-indexed tab ID of the tab in which this stream is available.

--#endregion
