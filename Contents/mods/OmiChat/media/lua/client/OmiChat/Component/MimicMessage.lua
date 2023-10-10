local lib = require 'OmiChat/lib'
local OmiChat = require 'OmiChat/API/Client'

local utils = OmiChat.utils
local format = string.format
local concat = table.concat
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---Fake ChatMessage object for creating messages in chat.
---@class omichat.MimicMessage : omi.Class
---@field private _scramble boolean
---@field private _overHeadSpeech boolean
---@field private _showInChat boolean
---@field private _fromDiscord boolean
---@field private _richText boolean
---@field private _serverAlert boolean
---@field private _radioChannel integer
---@field private _local boolean
---@field private _shouldAttractZombies boolean
---@field private _serverAuthor boolean
---@field private _showAuthor boolean
---@field private _datetime LocalDateTime | Date
---@field private _text string
---@field private _author string
---@field private _textColor Color
---@field private _customTag string
---@field private _customColor boolean
---@field private _chatType string
---@field private _chatID integer
---@field private _titleID string
---@field private _recipientName string?
local MimicMessage = lib.class()


---Returns the author of the message.
---@return string
function MimicMessage:getAuthor()
    return self._author
end

---Returns `nil`. Included for completeness of the `ChatMessage` interface.
---@deprecated
function MimicMessage:getChat() end

---Returns the chat ID of the message.
---@return integer
function MimicMessage:getChatID()
    return self._chatID
end

---Returns the chat type of the message.
---@return string
function MimicMessage:getChatType()
    return self._chatType
end

---Returns the custom tag of the message.
---@return string
function MimicMessage:getCustomTag()
    return self._customTag
end

---Returns the time at which the message was sent.
---@return LocalDateTime | Date
function MimicMessage:getDatetime()
    return self._datetime
end

---Returns a string representing the datetime of the message.
---@return string
function MimicMessage:getDatetimeStr()
    -- the vanilla implementation returns the time when *retrieving* this,
    -- which may be inaccurate. this returns a proper timestamp, but is unused.

    local str = tostring(self._datetime)
    return str:match('%d+:%d+') or ''
end

---Returns the message prefix.
---@return string
function MimicMessage:getPrefix()
    local instance = ISChat.instance
    if not instance then
        return ''
    end

    local isServer = self._chatType == 'server'
    local color = self._textColor
    local result = {
        utils.toChatColor({
            r = color:getRed(),
            g = color:getGreen(),
            b = color:getBlue(),
        }),
        '<SIZE:', instance.chatFont or 'medium', '> '
    }

    local addColon = not isServer
    local titleID = self:getTitleID()

    if instance.showTimestamp and not isServer then
        result[#result+1] = '['

        -- including the inaccurate time here like vanilla for consistency
        -- ultimately unused
        result[#result+1] = getHourMinute()

        result[#result+1] = ']'
    end

    if instance.showTitle and titleID then
        addColon = true
        result[#result+1] = '['
        result[#result+1] = getText(titleID)
        result[#result+1] = ']'
    end

    if (not isServer or not self:isServerAuthor()) and self:isShowAuthor() then
        addColon = true
        local recipName = self:getRecipientName()
        result[#result+1] = '['
        result[#result+1] = recipName and 'to ' or ''
        result[#result+1] = recipName or self:getAuthor()
        result[#result+1] = ']'
    end

    if addColon then
        result[#result+1] = ': '
    end

    return concat(result)
end

---Returns the radio channel on which the message was sent.
---@return integer
function MimicMessage:getRadioChannel()
    return self._radioChannel
end

---Returns the username of the private message recipient.
---@return string?
function MimicMessage:getRecipientName()
    return self._recipientName
end

---Returns the message text.
---@return string
function MimicMessage:getText()
    return self._text
end

---Returns the message text color.
---@return Color
function MimicMessage:getTextColor()
    return self._textColor
end

---Returns the formatted message text.
---@return string
function MimicMessage:getTextWithPrefix()
    return OmiChat.buildMessageText(self)
end

---Base implementation of `getTextWithPrefix`.
---This returns the equivalent of what the non-overriden `getTextWithPrefix`
---returns for `ChatMessage`.
---@return string
function MimicMessage:getTextWithPrefixBase()
    return concat {
        self:getPrefix(),
        ' ',
        self:getTextWithReplacedParentheses()
    }
end

---Returns the message text escaped for rich text.
---@return string
function MimicMessage:getTextWithReplacedParentheses()
    if self:isRichText() then
        return self._text
    end

    return utils.escapeRichText(self._text)
end

---Returns the title ID of the message.
---@return string
function MimicMessage:getTitleID()
    return self._titleID
end

---Returns whether the message has a custom color.
---@return boolean
function MimicMessage:isCustomColor()
    return self._customColor
end

---Returns whether the message is from Discord.
---@return boolean
function MimicMessage:isFromDiscord()
    return self._fromDiscord
end

---Returns whether the message is local.
---@return boolean
function MimicMessage:isLocal()
    return self._local
end

---Returns whether the message should display overhead.
---@return boolean
function MimicMessage:isOverHeadSpeech()
    return self._overHeadSpeech
end

---Returns `true` if the message content should be treated as rich text.
---@return boolean
function MimicMessage:isRichText()
    return self._richText
end

---Returns whether the message content is scrambled.
---@return boolean
function MimicMessage:isScramble()
    return self._scramble
end

---Returns whether the message is a server alert.
---@return boolean
function MimicMessage:isServerAlert()
    return self._serverAlert
end

---Returns whether the message was authored by the server.
---@return boolean
function MimicMessage:isServerAuthor()
    return self._serverAuthor
end

---Returns whether the message should attract zombies.
---@return boolean
function MimicMessage:isShouldAttractZombies()
    return self._shouldAttractZombies
end

---Returns whether the message should show its author.
---@return boolean
function MimicMessage:isShowAuthor()
    return self._showAuthor
end

---Returns whether the message should show in chat.
---@return boolean
function MimicMessage:isShowInChat()
    return self._showInChat
end

---Sets the message as being from Discord.
function MimicMessage:makeFromDiscord()
    self._fromDiscord = true
end

---Sets the message author.
---@param author string
function MimicMessage:setAuthor(author)
    self._author = author
end

---Sets the custom tag of the message.
---@param customTag string
function MimicMessage:setCustomTag(customTag)
    self._customTag = customTag
end

---Sets the datetime of the message.
---@param datetime LocalDateTime | Date
function MimicMessage:setDatetime(datetime)
    self._datetime = datetime
end

---Sets the ID of the associated chat for the message.
---@param chatID integer
function MimicMessage:setChatID(chatID)
    self._chatID = chatID
end

---Sets the chat type of the message.
---@param chatType string
function MimicMessage:setChatType(chatType)
    self._chatType = chatType
end

---Sets whether the message content should be treated as rich text.
---@param richText boolean
function MimicMessage:setIsRichText(richText)
    self._richText = richText
end

---Sets whether the message is local.
---@param isLocal boolean
function MimicMessage:setLocal(isLocal)
    self._local = isLocal
end

---Sets whether the message should display overhead.
---@param overHeadSpeech boolean
function MimicMessage:setOverHeadSpeech(overHeadSpeech)
    self._overHeadSpeech = overHeadSpeech
end

---Sets the radio channel of the message.
---@param radioChannel integer
function MimicMessage:setRadioChannel(radioChannel)
    self._radioChannel = radioChannel
end

---Sets the username of the private message recipient.
---@param recipientName string?
function MimicMessage:setRecipientName(recipientName)
    self._recipientName = recipientName
end

---Sets the text of the message and marks it as scrambled.
---@param text string
function MimicMessage:setScrambledText(text)
    self._scramble = true
    self._text = text
end

---Sets whether this message is a server alert.
---@param serverAlert boolean
function MimicMessage:setServerAlert(serverAlert)
    self._serverAlert = serverAlert
end

---Sets whether this message was authored by the server.
---@param serverAuthor boolean
function MimicMessage:setServerAuthor(serverAuthor)
    self._serverAuthor = serverAuthor
end

---Sets whether this message should attract zombies.
---@param shouldAttractZombies boolean
function MimicMessage:setShouldAttractZombies(shouldAttractZombies)
    self._shouldAttractZombies = shouldAttractZombies
end

---Sets whether this message should show in chat.
---@param showInChat boolean
function MimicMessage:setShowInChat(showInChat)
    self._showInChat = showInChat
end

---Sets the text of this message.
---@param text string
function MimicMessage:setText(text)
    self._text = text
end

---Sets the text color of this message.
---@param textColor Color
function MimicMessage:setTextColor(textColor)
    self._textColor = textColor
end

---Sets the title ID of the message.
---@param titleID string
function MimicMessage:setTitleID(titleID)
    self._titleID = titleID
end

---Creates a new mimic message.
---@param text string
---@param datetime Date?
---@param textColor Color?
---@return omichat.MimicMessage
function MimicMessage:new(text, datetime, textColor)
    ---@type omichat.MimicMessage
    local this = setmetatable({}, self)

    this._scramble = false
    this._overHeadSpeech = true
    this._showInChat = true
    this._fromDiscord = false
    this._richText = false
    this._serverAlert = false
    this._radioChannel = -1
    this._chatID = -1
    this._local = false
    this._shouldAttractZombies = false
    this._serverAuthor = false
    this._showAuthor = false
    this._datetime = datetime or PZCalendar:getInstance():getTime()
    this._text = text
    this._textColor = textColor or Color.new(255, 255, 255)
    this._customColor = false
    this._author = ''
    this._customTag = ''
    this._chatType = ''
    this._titleID = ''

    return this
end

---Converts the message to a debug string.
---@return string
function MimicMessage.__tostring(self)
    return format('MimicMessage{author=\'%s\', text=\'%s\'}', self._author, self._text)
end


return MimicMessage
