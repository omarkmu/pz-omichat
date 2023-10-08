---Handles chat overrides.

local OmiChat = require 'OmiChat/API/Client'
local customStreamData = require 'OmiChat/Data/CustomStreams'


---@class omichat.ISChat
local ISChat = ISChat
local utils = OmiChat.utils
local Option = OmiChat.Option
local SuggesterBox = OmiChat.SuggesterBox
local getText = getText
local getTextOrNull = getTextOrNull

local _addLineInChat = ISChat.addLineInChat
local _onCommandEntered = ISChat.onCommandEntered
local _onGearButtonClick = ISChat.onGearButtonClick
local _logChatCommand = ISChat.logChatCommand
local _createChildren = ISChat.createChildren
local _focus = ISChat.focus
local _unfocus = ISChat.unfocus
local _close = ISChat.close
local _onMouseDown = ISChat.onMouseDown
local _onPressDown = ISChat.onPressDown
local _onPressUp = ISChat.onPressUp
local _onOtherKey = ISChat.onOtherKey
local _onTextChange = ISChat.onTextChange
local _onInfo = ISChat.onInfo

local _ChatMessage = __classmetatables[ChatMessage.class].__index
local _ServerChatMessage = __classmetatables[ServerChatMessage.class].__index


---Attempts to set the current text with the currently selected suggester box item.
---@return boolean didSet
local function tryInputSuggestedItem()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    local visible = suggesterBox and suggesterBox:isVisible()
    if not instance or not suggesterBox or not visible then
        return false
    end

    local item = suggesterBox:getSelectedItem()
    if item then
        instance:onSuggesterSelect(item)
        return true
    end

    return false
end


---Override to enable custom formatting.
_ChatMessage.getTextWithPrefix = OmiChat.buildMessageText
_ServerChatMessage.getTextWithPrefix = OmiChat.buildMessageText


---Override to add information to chat messages and remove blank lines.
---@param message omichat.Message
---@param tabID integer
function ISChat.addLineInChat(message, tabID)
    if not message then
        return
    end

    local mtIndex = (getmetatable(message) or {}).__index
    if mtIndex == _ChatMessage or mtIndex == _ServerChatMessage or utils.isinstance(message, OmiChat.MimicMessage) then
        message:setCustomTag(OmiChat.encodeMessageTag(message))

        -- necessary to process transforms so we know whether this message should be added to chat
        local info = OmiChat.buildMessageInfo(message, true)
        if info and not message:isShowInChat() then
            return
        end
    end

    local s, e = pcall(_addLineInChat, message, tabID)
    if not s then
        print(('[OmiChat] error while adding message %s: %s'):format(tostring(message), e))
        return
    end
end

---Override to unfocus on close.
function ISChat:close()
    _close(self)

    if not self.locked then
        self:unfocus()
    end
end

---Override to add custom components.
function ISChat:createChildren()
    _createChildren(self)

    local th = self:titleBarHeight()
    self.infoButton = ISButton:new(self.gearButton:getX() - th / 2 - th, 0, th, th, '', self, self.onInfo)
    self.infoButton.anchorRight = true
    self.infoButton.anchorLeft = false
    self.infoButton:initialise()
    self.infoButton.borderColor.a = 0.0
    self.infoButton.backgroundColor.a = 0.0
    self.infoButton.backgroundColorMouseOver.a = 0
    self.infoButton:setImage(self.infoBtn)
    self.infoButton:setUIName('chat info button')
    self:addChild(self.infoButton)
    self.infoButton:setVisible(false)

    self.suggesterBox = SuggesterBox:new(0, 0, 0, 0)
    self.suggesterBox:setOnMouseDownFunction(self, self.onSuggesterSelect)
    self.suggesterBox:setAlwaysOnTop(true)
    self.suggesterBox:setUIName('chat suggester box')
    self.suggesterBox:addToUIManager()
    self.suggesterBox:setVisible(false)

    OmiChat.updateState()
end

---Override to correct the chat stream and enable the icon button on focus.
function ISChat:focus()
    _focus(self)

    local text = ISChat.instance.textEntry:getInternalText()
    OmiChat.updateCustomComponents(text)

    -- correct the stream ID to the current stream
    local currentStreamName = OmiChat.chatCommandToStreamName(text)
    if currentStreamName then
        OmiChat.cycleStream(currentStreamName)
    end
end

---Override to avoid adding sequential duplicates to the history log.
---@param command string
function ISChat:logChatCommand(command)
    local log = self.chatText.log
    self.chatText.logIndex = 0
    if log[1] == command then
        return
    end

    _logChatCommand(self, command)
end

---Override to support custom commands and emote shortcuts.
function ISChat:onCommandEntered()
    if tryInputSuggestedItem() then
        OmiChat.updateCustomComponents()
        return
    end

    local instance = ISChat.instance ---@cast instance omichat.ISChat
    local input = instance.textEntry:getText()
    local stream, command, chatCommand = OmiChat.chatCommandToStream(input)

    local useCallback
    local callbackStream

    local shouldHandle = false
    local allowEmotes = false
    local allowRetain = true
    local isDefault = false

    if not stream then
        -- process emotes for streamless messages unless there's a leading slash
        local isCommand = utils.startsWith(input, '/')
        allowEmotes = not isCommand
        command = input

        local default = ISChat.defaultTabStream[instance.currentTabID]
        if not isCommand and default then
            stream = default
            isDefault = true
        end
    end

    if stream then
        if stream.tabID and instance.currentTabID ~= stream.tabID then
            -- wrong chat tab
            showWrongChatTabMessage(instance.currentTabID - 1, stream.tabID - 1, chatCommand or '')
            stream = nil
            allowEmotes = false
            shouldHandle = true
        elseif stream.omichat then
            local isEnabled = stream.omichat.isEnabled
            if isEnabled and not isEnabled(stream) then
                stream = nil
            else
                shouldHandle = true
                allowEmotes = true

                useCallback = stream.omichat.onUse
                callbackStream = stream

                if stream.omichat.allowEmotes ~= nil then
                    allowEmotes = stream.omichat.allowEmotes
                elseif stream.omichat.isCommand then
                    allowEmotes = false
                end

                if stream.omichat.allowRetain ~= nil then
                    allowRetain = stream.omichat.allowRetain
                elseif stream.omichat.isCommand then
                    allowRetain = false
                end
            end
        end

        if isDefault then
            stream = nil
        end
    end

    -- handle emotes specified with .emote
    if allowEmotes and Option.EnableEmotes then
        local emoteToPlay, start, finish = OmiChat.getEmoteFromCommand(command)
        if emoteToPlay then
            -- remove the emote text
            shouldHandle = true
            command = utils.trim(command:sub(1, start - 1) .. command:sub(finish + 1))

            local player = getSpecificPlayer(0)
            if player then
                player:playEmote(emoteToPlay)
            end
        end
    end

    if allowRetain and stream then
        -- fix the switching functionality by updating to the used stream
        OmiChat.cycleStream(stream.name)
    end

    if not shouldHandle then
        -- no special handling, pass to original function
        return _onCommandEntered(self)
    end

    instance:unfocus()
    instance:logChatCommand(input)
    OmiChat.scrollToBottom()

    if allowRetain and stream then
        instance.chatText.lastChatCommand = chatCommand
    elseif stream then
        -- if the used stream shouldn't be set as the last, cycle to the previous command
        local lastChatStream = OmiChat.chatCommandToStreamName(instance.chatText.lastChatCommand)
        if lastChatStream then
            OmiChat.cycleStream(lastChatStream)
        end
    end

    if callbackStream and useCallback then
        useCallback(callbackStream, command)
    end

    doKeyPress(false)
    instance.timerTextEntry = 20
end

---Override to add additional settings.
function ISChat:onGearButtonClick()
    _onGearButtonClick(self)
    OmiChat.hideSuggesterBox()

    -- grab and modify the context menu that the default onGearButtonClick creates
    local context = getPlayerContextMenu(0)
    if not context then
        return
    end

    -- sanity check that this is the chat context menu
    local checkOpt = context.options and context.options[1]
    if not checkOpt or checkOpt.target ~= ISChat.instance then
        return
    end

    -- for enabling/disabling name colors
    local showNameColorOption = Option.EnableSetNameColor or Option.EnableSpeechColorAsDefaultNameColor

    local colorOpts = {}
    local canUsePM = checkPlayerCanUseChat('/w')
    if Option.EnableSetNameColor then
        colorOpts[#colorOpts+1] = 'name'
    end
    if Option.EnableSetSpeechColor then
        colorOpts[#colorOpts+1] = 'speech'
    end

    colorOpts[#colorOpts+1] = 'server'

    if getServerOptions():getBoolean('DiscordEnable') then
        colorOpts[#colorOpts+1] = 'discord'
    end

    if checkPlayerCanUseChat('/r') then
        colorOpts[#colorOpts+1] = 'radio'
    end

    if checkPlayerCanUseChat('/s') then
        colorOpts[#colorOpts+1] = 'say'
    end

    if checkPlayerCanUseChat('/a') then
        colorOpts[#colorOpts+1] = 'admin'
    end

    if checkPlayerCanUseChat('/y') then
        colorOpts[#colorOpts+1] = 'shout'
    end

    local useLocalWhisper = OmiChat.isCustomStreamEnabled('whisper')
    if useLocalWhisper then
        colorOpts[#colorOpts+1] = 'whisper'
    elseif canUsePM then
        colorOpts[#colorOpts+1] = 'private'
    end

    for i = 1, #customStreamData.list do
        local streamInfo = customStreamData.list[i]
        local name = streamInfo.name
        if name ~= 'whisper' and streamInfo.allowColorCustomization ~= false and OmiChat.isCustomStreamEnabled(name) then
            colorOpts[#colorOpts+1] = name
        end
    end

    if checkPlayerCanUseChat('/all') then
        colorOpts[#colorOpts+1] = 'general'
    end

    if checkPlayerCanUseChat('/f') then
        colorOpts[#colorOpts+1] = 'faction'
    end

    if checkPlayerCanUseChat('/sh') then
        colorOpts[#colorOpts+1] = 'safehouse'
    end

    -- add renamed /pm at the end
    if useLocalWhisper and canUsePM then
        colorOpts[#colorOpts+1] = 'private'
    end

    local shoutOpts = {}
    if Option.EnableCustomShouts then
        shoutOpts[#shoutOpts+1] = 'callouts'
    end
    if Option.EnableCustomSneakShouts then
        shoutOpts[#shoutOpts+1] = 'sneakcallouts'
    end

    -- insert new options before the first submenu
    local firstSubMenu
    for _, opt in ipairs(context.options) do
        if opt.subOption and opt.subOption > 0 then
            firstSubMenu = opt
            break
        end
    end

    local subMenuName = firstSubMenu and firstSubMenu.name or ''

    if showNameColorOption then
        local nameColorOptionName
        if OmiChat.getNameColorsEnabled() then
            nameColorOptionName = getText('UI_OmiChat_context_disable_name_colors')
        else
            nameColorOptionName = getText('UI_OmiChat_context_enable_name_colors')
        end

        context:insertOptionBefore(subMenuName, nameColorOptionName, ISChat.instance, ISChat.onToggleShowNameColor)
    end

    local suggesterOptionName
    if OmiChat.getUseSuggester() then
        suggesterOptionName = getText('UI_OmiChat_context_disable_suggestions')
    else
        suggesterOptionName = getText('UI_OmiChat_context_enable_suggestions')
    end

    context:insertOptionBefore(subMenuName, suggesterOptionName, ISChat.instance, ISChat.onToggleUseSuggester)

    for _, shoutType in ipairs(shoutOpts) do
        local shoutOptionName = getText('UI_OmiChat_context_set_custom_' .. shoutType)
        context:insertOptionBefore(subMenuName, shoutOptionName, ISChat.instance, ISChat.onCustomCalloutMenu, shoutType)
    end

    if #colorOpts > 1 then
        local colorOptionName = getText('UI_OmiChat_context_colors_submenu_name')
        local colorOption = context:insertOptionBefore(subMenuName, colorOptionName, ISChat.instance)

        local colorSubMenu = context:getNew(context)
        context:addSubMenu(colorOption, colorSubMenu)

        for _, category in ipairs(colorOpts) do
            local name = getTextOrNull('UI_OmiChat_context_submenu_color_' .. category)
            if not name then
                name = getText('UI_OmiChat_context_submenu_color', OmiChat.getColorCategoryCommand(category))
            end

            colorSubMenu:addOption(name, ISChat.instance, ISChat.onCustomColorMenu, category)
        end
    elseif #colorOpts == 1 then
        local category = colorOpts[1]

        local name = getTextOrNull('UI_OmiChat_context_color_' .. category)
        if not name then
            name = getText('UI_OmiChat_context_color', OmiChat.getColorCategoryCommand(category))
        end

        context:insertOptionBefore(subMenuName, name, ISChat.instance, ISChat.onCustomColorMenu, category)
    end
end

---Override to handle custom info text.
function ISChat:onInfo()
    OmiChat.hideSuggesterBox()

    local text = OmiChat.getInfoText()
    self:setInfo(text)

    if text == '' and self.infoRichText then
        self.infoRichText:removeFromUIManager()
        return
    end

    _onInfo(self)
end

---Override to hide components on text panel or entry click.
---@param target unknown
---@param x number
---@param y number
---@return boolean
function ISChat.onMouseDown(target, x, y)
    local handled = _onMouseDown(target, x, y)
    local instance = ISChat.instance
    if not instance then
        return handled
    end

    local iconPicker = instance.iconPicker
    OmiChat.hideSuggesterBox()

    if not handled or not iconPicker or not iconPicker:isVisible() then
        return handled
    end

    local name = target:getUIName()
    if name == ISChat.textPanelName or name == ISChat.textEntryName then
        iconPicker:setVisible(false)
    end

    return handled
end

---Override to update custom components.
function ISChat:onOtherKey(key)
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox and suggesterBox:isVisible() and key == Keyboard.KEY_ESCAPE then
        OmiChat.hideSuggesterBox()
    else
        _onOtherKey(self, key)
    end
end

---Override to update custom components.
function ISChat.onPressDown()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox and suggesterBox:isVisible() then
        suggesterBox:selectNext()
        return
    end

    _onPressDown()
    OmiChat.updateCustomComponents()
end

---Override to update custom components.
function ISChat.onPressUp()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox and suggesterBox:isVisible() then
        suggesterBox:selectPrevious()
        return
    end

    _onPressUp()
    OmiChat.updateCustomComponents()
end

---Override to control custom components and allow switching to custom streams.
function ISChat.onSwitchStream()
    if not ISChat.focused or not ISChat.instance then
        return
    end

    local text
    if not tryInputSuggestedItem() then
        text = OmiChat.cycleStream()
        local entry = ISChat.instance.textEntry
        entry:setText(text)
    end

    OmiChat.updateCustomComponents(text)
end

---Override to update custom components.
function ISChat.onTextChange()
    _onTextChange()
    OmiChat.updateCustomComponents()
end

---Override to hide icon picker and disable button on unfocus.
function ISChat:unfocus()
    _unfocus(self)
    OmiChat.hideSuggesterBox()
    OmiChat.setIconButtonEnabled(false)
end

---Override to improve performance of text refresh.
function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    OmiChat.redrawMessages()
end
