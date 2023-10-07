local lib = require 'OmiChat/lib'
local utils = require 'OmiChat/util'
local OmiChat = require 'OmiChat/API/Client'

local format = string.format
local concat = table.concat

---@class omichat.ISChat
local ISChat = ISChat


---Fake ChatMessage object for creating messages in chat.
---@class omichat.MimicMessage : omi.Class
---@field private scramble boolean
---@field private overHeadSpeech boolean
---@field private showInChat boolean
---@field private fromDiscord boolean
---@field private alreadyEscaped boolean
---@field private serverAlert boolean
---@field private radioChannel integer
---@field private _local boolean
---@field private shouldAttractZombies boolean
---@field private serverAuthor boolean
---@field private showAuthor boolean
---@field private datetime LocalDateTime | Date
---@field private text string
---@field private author string
---@field private textColor Color
---@field private customTag string
---@field private customColor boolean
---@field private chatType string
---@field private chatID integer
---@field private titleID string
---@field private recipientName string?
local MimicMessage = lib.class()


---@return boolean
function MimicMessage:getAlreadyEscaped()
    return self.alreadyEscaped
end

---@return string
function MimicMessage:getAuthor()
    return self.author
end

---@deprecated
function MimicMessage:getChat() end

---@return integer
function MimicMessage:getChatID()
    return self.chatID
end

function MimicMessage:getChatType()
    return self.chatType
end

---@return string
function MimicMessage:getCustomTag()
    return self.customTag
end

---@return LocalDateTime | Date
function MimicMessage:getDatetime()
    return self.datetime
end

---@return string
function MimicMessage:getDatetimeStr()
    local str = tostring(self.datetime)
    return str:match('%d+:%d+') or ''
end

---@return integer
function MimicMessage:getRadioChannel()
    return self.radioChannel
end

---@return string
function MimicMessage:getPrefix()
    local instance = ISChat.instance
    local isServer = self.chatType == 'server'
    if not instance then
        return ''
    end

    local color = self.textColor
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

---@return string?
function MimicMessage:getRecipientName()
    return self.recipientName
end

---@return string
function MimicMessage:getText()
    return self.text
end

---@return Color
function MimicMessage:getTextColor()
    return self.textColor
end

---@return string
function MimicMessage:getTextWithPrefix()
    return OmiChat.buildMessageText(self)
end

---@return string
function MimicMessage:getTextWithPrefixBase()
    return concat {
        self:getPrefix(),
        ' ',
        self:getTextWithReplacedParentheses()
    }
end

---@return string
function MimicMessage:getTextWithReplacedParentheses()
    if self:getAlreadyEscaped() then
        return self.text
    end

    return utils.escapeRichText(self.text)
end

---@return string
function MimicMessage:getTitleID()
    return self.titleID
end

---@return boolean
function MimicMessage:isCustomColor()
    return self.customColor
end

---@return boolean
function MimicMessage:isFromDiscord()
    return self.fromDiscord
end

---@return boolean
function MimicMessage:isLocal()
    return self._local
end

---@return boolean
function MimicMessage:isOverHeadSpeech()
    return self.overHeadSpeech
end

---@return boolean
function MimicMessage:isScramble()
    return self.scramble
end

---@return boolean
function MimicMessage:isServerAlert()
    return self.serverAlert
end

---@return boolean
function MimicMessage:isServerAuthor()
    return self.serverAuthor
end

---@return boolean
function MimicMessage:isShouldAttractZombies()
    return self.shouldAttractZombies
end

---@return boolean
function MimicMessage:isShowAuthor()
    return self.showAuthor
end

---@return boolean
function MimicMessage:isShowInChat()
    return self.showInChat
end

function MimicMessage:makeFromDiscord()
    self.fromDiscord = true
end

---@param escaped boolean
function MimicMessage:setAlreadyEscaped(escaped)
    self.alreadyEscaped = escaped
end

---@param author string
function MimicMessage:setAuthor(author)
    self.author = author
end

---@param customTag string
function MimicMessage:setCustomTag(customTag)
    self.customTag = customTag
end

---@param datetime LocalDateTime | Date
function MimicMessage:setDatetime(datetime)
    self.datetime = datetime
end

---@param chatID integer
function MimicMessage:setChatID(chatID)
    self.chatID = chatID
end

---@param chatType string
function MimicMessage:setChatType(chatType)
    self.chatType = chatType
end

---@param isLocal boolean
function MimicMessage:setLocal(isLocal)
    self._local = isLocal
end

---@param titleID string
function MimicMessage:setTitleID(titleID)
    self.titleID = titleID
end

---@param overHeadSpeech boolean
function MimicMessage:setOverHeadSpeech(overHeadSpeech)
    self.overHeadSpeech = overHeadSpeech
end

---@param radioChannel integer
function MimicMessage:setRadioChannel(radioChannel)
    self.radioChannel = radioChannel
end

---@param recipientName string?
function MimicMessage:setRecipientName(recipientName)
    self.recipientName = recipientName
end

---@param text string
function MimicMessage:setScrambledText(text)
    self.scramble = true
    self.text = text
end

---@param serverAlert boolean
function MimicMessage:setServerAlert(serverAlert)
    self.serverAlert = serverAlert
end

---@param serverAuthor boolean
function MimicMessage:setServerAuthor(serverAuthor)
    self.serverAuthor = serverAuthor
end

---@param shouldAttractZombies boolean
function MimicMessage:setShouldAttractZombies(shouldAttractZombies)
    self.shouldAttractZombies = shouldAttractZombies
end

---@param showInChat boolean
function MimicMessage:setShowInChat(showInChat)
    self.showInChat = showInChat
end

---@param text string
function MimicMessage:setText(text)
    self.text = text
end

---@param textColor Color
function MimicMessage:setTextColor(textColor)
    self.textColor = textColor
end

---Creates a new mimic message.
---@param text string
---@param datetime Date?
---@param textColor Color?
---@return omichat.MimicMessage
function MimicMessage:new(text, datetime, textColor)
    ---@type omichat.MimicMessage
    local this = setmetatable({}, self)

    this.scramble = false
    this.overHeadSpeech = true
    this.showInChat = true
    this.fromDiscord = false
    this.alreadyEscaped = false
    this.serverAlert = false
    this.radioChannel = -1
    this.chatID = -1
    this._local = false
    this.shouldAttractZombies = false
    this.serverAuthor = false
    this.showAuthor = false
    this.datetime = datetime or PZCalendar:getInstance():getTime()
    this.text = text
    this.textColor = textColor or Color.new(255, 255, 255)
    this.customColor = false
    this.author = ''
    this.customTag = ''
    this.chatType = ''
    this.titleID = ''

    return this
end

function MimicMessage.__tostring(self)
    return format('MimicMessage{author=\'%s\', text=\'%s\'}', self.author, self.text)
end


return MimicMessage
