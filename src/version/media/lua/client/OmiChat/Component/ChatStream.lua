---Stream for sending chat messages.
---@namespace omichat

local Stream = require 'OmiChat/Component/Stream'
local defaultStreamData = require 'OmiChat/Definition/DefaultStreamData'
local utils = require 'OmiChat/Utils'

local getTextVanilla = getText
local checkPlayerCanUseChat = checkPlayerCanUseChat


---@class ChatStream : Stream
---@field protected allowBuffs boolean Flag for whether the stream can apply buffs when it's used.
---@field protected allowLanguages boolean Flag for whether the stream should allow messages to be sent using roleplay languages.
---@field protected allowTypingIndicator boolean Flag for whether typing on the stream triggers a typing indicator.
---@field protected attractZombies boolean Flag for whether the stream can attract zombies.
---@field protected chatType omi.ChatTypeString The chat type that stream messages are sent over.
---@field protected defaultColor omi.ColorTable<integer> The default color for messages on the stream.
---@field protected range integer The range of the chat stream.
---@field protected rangeSigned integer The range of the chat stream when used with a signed language.
---@field protected tabID integer The 1-indexed tab ID of the tab in which this stream is available.
---@field protected useNarrativeStyle boolean Flag for whether the stream should apply narrative style (if narrative style is enabled).
---@field protected verticalRange integer The vertical range of the chat stream.
---@field protected verticalRangeSigned integer The vertical range of the chat stream when used with a signed language.
---@field protected perceptionRange integer The perception range of the chat stream.
---@field protected perceptionRangeSigned integer The perception range of the chat stream, for signed languages.
---@field protected chatFormat? string The format to use for chat messages sent from this stream.
---@field protected overheadFormat? string The format to use for overhead messages sent from this stream.
---@field protected roleSet omi.SetTable<string>? Roles that allow using the stream.
---@field protected streamType string? The predefined stream type of the stream.
local ChatStream = Stream:derive('ChatStream')


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
---@param def Configuration.StreamDefinition The definition to check.
---@return boolean valid
function ChatStream.isValidDefinition(def)
    if not def.Stream or def.Stream == 'custom' then
        local name = def.Name and def.Name:lower() or ''
        return not utils.isNilOrWhitespace(name) and not ChatStream.isReservedName(name)
    end

    return not utils.isNilOrWhitespace(def.Stream)
end

---Creates a chat stream given a stream definition, if it's valid.
---@param def Configuration.StreamDefinition The definition to use.
---@param additionalTags string[]? Extra tags to add to the created stream.
---@return ChatStream? stream
function ChatStream.fromDefinition(def, additionalTags)
    if not ChatStream.isValidDefinition(def) then
        return
    end

    local streamType = def.Stream ~= 'custom' and def.Stream or nil
    local name = (not def.Stream or def.Stream == 'custom') and def.Name or def.Stream
    if not name then
        return
    end

    return ChatStream:new {
        name = utils.trim(name):lower(),
        streamType = streamType,
        command = def.Command,
        shortCommand = def.ShortCommand,
        tabID = def.ChatType == 'admin' and 2 or 1,
        aliases = def.Aliases,
        roles = def.Roles,
        chatType = def.ChatType,
        category = def.Category,
        disabled = def.Enable == false,
        range = def.Range,
        rangeSigned = def.RangeSigned,
        verticalRange = def.VerticalRange,
        verticalRangeSigned = def.VerticalRangeSigned,
        perceptionRange = def.PerceptionRange,
        perceptionRangeSigned = def.PerceptionRangeSigned,
        allowBuffs = def.AllowBuffs,
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
---@param ignoreRoles boolean? Flag for whether roles should be ignored for the check.
---@return boolean canUse
function ChatStream:checkPlayerCanUse(ignoreRoles)
    local chatType = self:getChatType()
    local command = ChatStream._checkCommands[chatType]
    if command and not checkPlayerCanUseChat(command) then
        return false
    end

    local roles = self.roleSet
    if ignoreRoles or not roles then
        return true
    end

    local player = utils.getAPI().player.get()
    if not player then
        return false
    end

    local role = player:getRole():getName()
    return roles[role] ~= nil
end

---Copies all settings from another stream into this stream.
---@param other ChatStream
function ChatStream:copyFrom(other)
    Stream.copyFrom(self, other)
    self.allowBuffs = other.allowBuffs
    self.allowLanguages = other.allowLanguages
    self.allowTypingIndicator = other.allowTypingIndicator
    self.attractZombies = other.attractZombies
    self.useNarrativeStyle = other.useNarrativeStyle
    self.chatType = other.chatType
    self.range = other.range
    self.rangeSigned = other.rangeSigned
    self.verticalRange = other.verticalRange
    self.verticalRangeSigned = other.verticalRangeSigned
    self.tabID = other.tabID
    self.perceptionRange = other.perceptionRange
    self.perceptionRangeSigned = other.perceptionRangeSigned
    self.defaultColor = utils.color.copy(other.defaultColor)
    self.overheadFormat = other.overheadFormat
    self.chatFormat = other.chatFormat
    self.roleSet = other.roleSet and utils.copy(other.roleSet)
end

---Returns the format string used for chat content on the stream.
---@return string? formatString
function ChatStream:getChatFormat()
    return self.chatFormat
end

---Returns the chat type that stream messages are sent over.
---@return omi.ChatTypeString chatType
function ChatStream:getChatType()
    return self.chatType
end

---Returns the default color to use for the stream.
---@return omi.ColorTable<integer> defaultColor
function ChatStream:getDefaultColor()
    return utils.color.copy(self.defaultColor)
end

---Returns the format string used for overhead content from the stream.
---@return string? formatString
function ChatStream:getOverheadFormat()
    return self.overheadFormat
end

---Returns the perception range of the stream if it's a ranged stream.
---@param isSigned boolean? Flag for whether the signed range should be retrieved. Defaults to `false`.
---@return integer? perceptionRange
function ChatStream:getPerceptionRange(isSigned)
    if not self:isRanged() then
        return
    end

    if isSigned then
        return self.perceptionRangeSigned
    end

    return self.perceptionRange
end

---Returns the range of the stream if it's a ranged stream.
---@param isSigned boolean? Flag for whether the signed range should be retrieved. Defaults to `false`.
---@return integer? range
function ChatStream:getRange(isSigned)
    if not self:isRanged() then
        return
    end

    if isSigned and self.rangeSigned ~= 0 then
        return self.rangeSigned
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

---Returns the predefined stream type of the stream.
---@return string? streamType
function ChatStream:getStreamType()
    return self.streamType
end

---Gets the 1-indexed tab ID of the stream.
---@return integer tabID
function ChatStream:getTabID()
    return self.tabID
end

---Returns the vertical range of the stream if it's a ranged stream.
---@param isSigned boolean? Flag for whether the signed range should be retrieved. Defaults to `false`.
---@return integer? verticalRange
function ChatStream:getVerticalRange(isSigned)
    if not self:isRanged() then
        return
    end

    if isSigned and self.verticalRangeSigned ~= 0 then
        return self.verticalRangeSigned
    end

    return self.verticalRange
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

---Checks the stream's tab ID against a given tab ID.
---@param otherTabID integer The tab ID to match against.
---@return boolean isMatch `True` if the tab ID is a match. Otherwise, `false`.
function ChatStream:isTabID(otherTabID)
    return self:getTabID() == otherTabID
end

---Sets the format string used for the chat format of the stream.
---@param format string The format string to use.
function ChatStream:setChatFormat(format)
    self.chatFormat = format
end

---Sets the default color for the stream.
---@param color omi.ColorTable<integer> The color table to set as the default color.
function ChatStream:setDefaultColor(color)
    self.defaultColor = utils.copy(color)
end

---Sets the format string used for the overhead format of the stream.
---@param format string? The format string to use.
function ChatStream:setOverheadFormat(format)
    self.overheadFormat = format
end

---Validates stream input.
---@param input string The input text.
---@return boolean valid Flag for whether the input text is valid for the stream.
---@return string? message A translated error message to report to the player.
function ChatStream:validate(input)
    if self:getChatType() ~= 'whisper' then
        return true
    end

    -- vanilla regex is /("[^"]*\s+[^"]*"|[^"]\S*)\s(.+)/
    if input:match('^"[^"]*%s+[^"]*"%s.+$') or input:match('^[^"]%S*%s.+$') then
        return true
    end

    return false, getTextVanilla('IGUI_Commands_Whisper')
end


---Creates a new chat stream.
---@param args Args.ChatStream Arguments for creation of the stream.
---@return ChatStream stream
function ChatStream:new(args)
    local this = utils.new(self, Stream.new, args)

    this.isChat = true
    this.allowLanguages = args.allowLanguages or false
    this.allowTypingIndicator = args.allowTypingIndicator or false
    this.attractZombies = args.attractZombies or false
    this.allowBuffs = args.allowBuffs or false
    this.useNarrativeStyle = args.useNarrativeStyle or false
    this.chatType = args.chatType or 'say'
    this.range = args.range or (this.chatType == 'shout' and 60 or 30)
    this.rangeSigned = args.rangeSigned or 0
    this.tabID = args.tabID or 1
    this.verticalRange = args.verticalRange or 2
    this.verticalRangeSigned = args.verticalRangeSigned or 1
    this.perceptionRange = args.perceptionRange or 0
    this.perceptionRangeSigned = args.perceptionRangeSigned or 0
    this.defaultColor = utils.color.default(args.defaultColor, 255, 255, 255)
    this.streamType = args.streamType

    if args.roles and #args.roles > 0 then
        this.roleSet = utils.set.table(args.roles)
    end

    if utils.notNilOrWhitespace(args.overheadFormat) then
        this.overheadFormat = utils.trim(args.overheadFormat)
    end

    if utils.notNilOrWhitespace(args.chatFormat) then
        this.chatFormat = utils.trim(args.chatFormat)
    end

    return this
end


return ChatStream

--#region Type Definitions

---@class Args.ChatStream : Args.Stream
---@field defaultColor? omi.ColorTable<integer> The default color for messages on the stream.
---@field allowBuffs? boolean Flag for whether the stream can apply buffs when it's used.
---@field allowLanguages? boolean Flag for whether the stream allows messages to be sent using roleplay languages.
---@field allowTypingIndicator? boolean Flag for whether typing on the stream triggers a typing indicator.
---@field attractZombies? boolean Flag for whether the stream can attract zombies.
---@field chatFormat? string The format to use for chat messages.
---@field useNarrativeStyle? boolean Flag for whether the stream should apply narrative style if it's enabled.
---@field chatType? omi.ChatTypeString The chat type that stream messages are sent over.
---@field range? integer The range of the chat stream.
---@field rangeSigned? integer The range of the chat stream, when used with a signed language.
---@field verticalRange? integer The vertical range of the chat stream.
---@field verticalRangeSigned? integer The vertical range of the chat stream, when used with a signed language.
---@field perceptionRange? integer The perception range of the chat stream.
---@field perceptionRangeSigned? integer The perception range of the chat stream, for signed languages.
---@field tabID? integer The 1-indexed tab ID of the tab in which this stream is available.
---@field chatFormat? string The format to use for the stream in chat.
---@field overheadFormat? string The overhead format to use for the stream.
---@field roles? string[] A list of roles that allow using the stream. An empty list means there is no limit based on roles.
---@field streamType string? The predefined stream type of the stream.

--#endregion
