---Chat overrides and extensions.

local OmiChat = require 'OmiChatClient'
local customStreamData = require 'OmiChat/CustomStreamData'

local utils = OmiChat.utils
local Option = OmiChat.Option
local ColorModal = OmiChat.ColorModal
local SuggesterBox = OmiChat.SuggesterBox
local getText = getText
local getTextOrNull = getTextOrNull
local max = math.max
local min = math.min
local concat = table.concat

---Extended fields for ISChat.
---@class omichat.ISChat : ISChat
---@field instance omichat.ISChat?
---@field allChatStreams omichat.ChatStream[]
---@field defaultTabStream table<integer, omichat.ChatStream?>
---@field iconButton ISButton?
---@field iconPicker omichat.IconPicker?
---@field suggesterBox omichat.SuggesterBox?
local ISChat = ISChat


-- references for overrides
local _addLineInChat = ISChat.addLineInChat
local _onCommandEntered = ISChat.onCommandEntered
local _onGearButtonClick = ISChat.onGearButtonClick
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
local _IsoPlayer = __classmetatables[IsoPlayer.class].__index
local _Callout = _IsoPlayer.Callout

_ChatMessage.getTextWithPrefix = OmiChat.buildMessageText
_ServerChatMessage.getTextWithPrefix = OmiChat.buildMessageText


---Gets the command associated with a color category.
---@param cat omichat.ColorCategory
---@return string?
local function getColorCatStreamCommand(cat)
    if cat == 'private' then
        return OmiChat.isCustomStreamEnabled('whisper') and '/pm' or '/whisper'
    end

    if cat == 'general' then
        return '/all'
    end

    if cat == 'shout' then
        return '/yell'
    end

    return '/' .. cat
end

---Returns the non-empty lines of a string.
---If there are no non-empty lines, returns nil.
---@param text string
---@param maxLen integer?
---@return string[]?
local function getLines(text, maxLen)
    if not text then
        return
    end

    local lines = {}
    for line in text:gmatch('[^\n]+\n?') do
        line = utils.trim(line)
        if maxLen and #line > maxLen then
            lines[#lines+1] = line:sub(1, maxLen)
        elseif #line > 0 then
            lines[#lines+1] = line
        end
    end

    if #lines == 0 then
        return
    end

    return lines
end

---Sets whether the icon picker button is enabled.
---This also hides the icon picker if the button is disabled.
---@param enable boolean?
local function setIconButtonEnabled(enable)
    local instance = ISChat.instance
    local iconButton = instance and instance.iconButton
    if not instance or not iconButton then
        return
    end

    local value = enable and 0.8 or 0.3
    iconButton:setTextureRGBA(value, value, value, 1)
    iconButton.enable = enable

    local iconPicker = instance.iconPicker
    if not enable and iconPicker then
        iconPicker:setVisible(false)
    end
end

---Sets whether the suggester box should show.
---@param show boolean
local function setShowSuggesterBox(show)
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox then
        suggesterBox:setVisible(show)
    end
end

---Attempts to set the current text with the currently selected suggester box item.
---@return boolean didSet
local function tryEnterSuggestedItem()
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

---Enables or disables the icon picker based on the current input.
---@param text string? The current text entry text.
local function updateIconComponents(text)
    local instance = ISChat.instance
    if not instance or not instance.iconButton then
        return
    end

    text = text or instance.textEntry:getInternalText()
    local stream = OmiChat.chatCommandToStream(text)

    if not stream then
        stream = ISChat.defaultTabStream[instance.currentTabID]
    end

    local enable = false
    if stream and stream.omichat and stream.omichat.allowIconPicker ~= nil then
        -- enable icon button for custom chats where appropriate
        enable = stream.omichat.allowIconPicker
    end

    setIconButtonEnabled(enable)
end

---Shows or hides the suggester based on the current input.
---@param text string? The current text entry text.
local function updateSuggesterComponent(text)
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if not instance or not suggesterBox then
        return
    end

    if not OmiChat.getUseSuggester() then
        suggesterBox:setVisible(false)
        return
    end

    text = text or instance.textEntry:getInternalText()
    local suggestions = OmiChat.getSuggestions(text)
    if #suggestions == 0 then
        suggesterBox:setVisible(false)
        return
    end

    suggesterBox:setSuggestions(suggestions)
    if #suggestions > 0 then
        suggesterBox:setWidth(instance:getWidth())
        suggesterBox:setHeight(suggesterBox.itemheight * math.min(#suggestions, 5))
        suggesterBox:setX(instance:getX())
        suggesterBox:setY(instance:getY() + instance.textEntry:getY() - suggesterBox.height)
        suggesterBox:setVisible(true)
        suggesterBox:bringToTop()

        if suggesterBox.vscroll then
            suggesterBox.vscroll:setHeight(suggesterBox.height)
        end
    else
        suggesterBox:setVisible(false)
    end
end

---Updates custom chat components.
---@param text string? The current text entry text.
local function updateComponents(text)
    local instance = ISChat.instance
    if not instance then
        return
    end

    text = text or instance.textEntry:getInternalText()

    updateIconComponents(text)
    updateSuggesterComponent(text)
end


---Override to enable custom callouts.
---@param playEmote boolean
function _IsoPlayer:Callout(playEmote)
    if getCore():getGameMode() == 'Tutorial' then
        return _Callout(self, playEmote)
    end

    local isSneaking = self:isSneaking()
    local range = isSneaking and 6 or 30

    local shouts
    if isSneaking and Option.EnableCustomSneakShouts then
        shouts = OmiChat.getCustomShouts('sneakcallouts')
    elseif not isSneaking and Option.EnableCustomShouts then
        shouts = OmiChat.getCustomShouts('callouts')
    end

    if not shouts or #shouts == 0 then
        return _Callout(self, playEmote)
    end

    -- this doesn't set .callOut, so minor boredom reduction will occur from shouting
    -- already possible to use chat for that purpose, so this isn't really problematic
    addSound(self, self:getX(), self:getY(), self:getY(), range, range)

    local shoutMax = Option.MaximumCustomShouts > 0 and min(#shouts, Option.MaximumCustomShouts) or #shouts

    local shout = shouts[ZombRand(1, shoutMax + 1)]
    if isSneaking then
        shout = shout:lower()
    else
        shout = shout:upper()
    end

    processShoutMessage(shout)

    if playEmote then
        self:playEmote('shout')
    end
end


---Event handler for color picker selection.
---@param target omichat.ISChat
---@param button table
---@param category omichat.ColorCategory The color category that has been changed.
function ISChat.onCustomColorMenuClick(target, button, category)
    if button.internal == 'OK' then
        OmiChat.changeColor(category, button.parent:getColorTable())

        if category ~= 'name' and category ~= 'speech' then
            OmiChat.redrawMessages()
        end
    end
end

---Event handler for color menu initialization.
---@param target omichat.ISChat
---@param category omichat.ColorCategory The target color category.
function ISChat.onCustomColorMenu(target, category)
    if target.activeColorModal then
        target.activeColorModal:destroy()
    end

    local color = OmiChat.getColorTable(category)
    local text = getTextOrNull('UI_OmiChat_context_color_desc_' .. category)
    if not text then
        local catName = getTextOrNull('UI_OmiChat_context_message_type_' .. category) or getColorCatStreamCommand(category)
        text = getText('UI_OmiChat_context_color_desc', catName)
    end

    local width = max(450, getTextManager():MeasureStringX(UIFont.Small, text) + 60)
    local modal = ColorModal:new(0, 0, width, 250, text, color, target, ISChat.onCustomColorMenuClick, 0, category)

    modal:setMinValue(category == 'speech' and 48 or 0)
    modal:setEmptyColor(Option:getDefaultColor(category))
    modal:initialise()
    modal:addToUIManager()

    target.activeColorModal = modal
end

---Validation function for custom callout menu.
---@param target ISTextBox
---@param text string
---@return boolean
function ISChat.validateCustomCalloutText(target, text)
    local lines = getLines(text)
    if not lines then
        return true
    end

    if #lines > Option.MaximumCustomShouts then
        target:setValidateTooltipText(getText('UI_OmiChat_error_too_many_shouts', tostring(Option.MaximumCustomShouts)))
        return false
    end

    for _, line in pairs(lines) do
        if #line > Option.CustomShoutMaxLength then
            target:setValidateTooltipText(getText('UI_OmiChat_error_shout_too_long', tostring(Option.CustomShoutMaxLength)))
            return false
        end
    end

    return true
end

---Event handler for accepting the custom callout dialog.
---@param target omichat.ISChat
---@param button table
---@param category omichat.CalloutCategory
function ISChat.onCustomCalloutClick(target, button, category)
    if button.internal ~= 'OK' then
        return
    end

    local maxLen = Option.CustomShoutMaxLength > 0 and Option.CustomShoutMaxLength or nil
    local lines = getLines(button.parent.entry:getText(), maxLen)
    if not lines then
        lines = nil
    end

    if lines and category == 'sneakcallouts' then
        for i = 1, #lines do
            lines[i] = lines[i]:lower()
        end
    end

    OmiChat.setCustomShouts(lines, category)
end

---Event handler for custom callout menu initialization.
---@param target omichat.ISChat
---@param category omichat.CalloutCategory
function ISChat.onCustomCalloutMenu(target, category)
    if target.activeCalloutModal then
        target.activeCalloutModal:destroy()
    end

    local shouts = OmiChat.getCustomShouts(category)
    local defaultText = shouts and concat(shouts, '\n') or ''

    local numLines = Option.MaximumCustomShouts
    if numLines <= 0 then
        numLines = Option:getDefault('MaximumCustomShouts') or 1
    elseif numLines > 20 then
        numLines = 20
    end

    local textManager = getTextManager()
    local boxHeight = 4 + textManager:getFontHeight(UIFont.Medium) * numLines

    local desc = getText('UI_OmiChat_context_set_custom_callouts_desc')

    local width = 500
    local height = boxHeight + 100
    local x = getPlayerScreenLeft(0) + (getPlayerScreenWidth(0) - width) / 2
    local y = getPlayerScreenTop(0) + (getPlayerScreenHeight(0) - height) / 2
    local modal = ISTextBox:new(x, y, width, height, desc, defaultText, target, ISChat.onCustomCalloutClick, 0, category)

    modal:setValidateFunction(modal, ISChat.validateCustomCalloutText)
    modal:setMultipleLine(numLines > 1)
    modal:setNumberOfLines(numLines)
    modal:initialise()

    modal.entry:setMaxLines(numLines)
    if category == 'callouts' then
        modal.entry:setForceUpperCase(true)
    end

    modal:addToUIManager()
    target.activeCalloutModal = modal
end

---Event handler for toggling showing name colors.
---@param target omichat.ISChat
function ISChat.onToggleShowNameColor(target)
    OmiChat.setNameColorEnabled(not OmiChat.getNameColorsEnabled())
    OmiChat.redrawMessages()
end

---Event handler for toggling using the suggester.
---@param target omichat.ISChat
function ISChat.onToggleUseSuggester(target)
    OmiChat.setUseSuggester(not OmiChat.getUseSuggester())
    updateSuggesterComponent()
end

---Event handler for icon button click.
---@param target omichat.ISChat
---@return boolean
function ISChat.onIconButtonClick(target)
    local iconPicker = target.iconPicker
    if not ISChat.focused or not iconPicker then
        return false
    end

    local yDelta = 0
    local height = target:getHeight()
    local pickerHeight = iconPicker:getHeight()
    if height > pickerHeight then
        yDelta = height - pickerHeight
    end

    local x = target:getX() + target:getWidth()
    local y = target:getY() + yDelta

    -- avoid covering the button
    if x + iconPicker:getWidth() >= getPlayerScreenWidth(0) then
        y = y - target.textEntry:getHeight() - target.inset * 2 - 5

        if y <= 0 then
            y = target:getHeight()
        end
    end

    iconPicker:setX(x)
    iconPicker:setY(y)
    iconPicker:bringToTop()
    iconPicker:setVisible(not iconPicker:isVisible())
    setShowSuggesterBox(false)

    return true
end

---Event handler for icon picker selection.
---@param target omichat.ISChat
---@param icon string The icon that was selected.
function ISChat.onIconClick(target, icon)
    if not ISChat.focused then
        target:focus()
    elseif not ISChat.instance.textEntry:isFocused() then
        ISChat.instance.textEntry:focus()
    end

    local text = target.textEntry:getInternalText()

    local addSpace = #text > 0 and text:sub(-1) ~= ' '
    target.textEntry:setText(concat { text, addSpace and ' *' or '*', icon, '*' })
    updateSuggesterComponent()
end

---Event handler for clicking on the info button.
function ISChat:onInfo()
    setShowSuggesterBox(false)

    local text = OmiChat.getInfoText()
    self:setInfo(text)

    if text == '' and self.infoRichText then
        self.infoRichText:removeFromUIManager()
        return
    end

    _onInfo(self)
end

---Event handler for selecting a suggestion.
---@param suggestion omichat.Suggestion
function ISChat:onSuggesterSelect(suggestion)
    local entry = ISChat.instance.textEntry

    setShowSuggesterBox(false)
    entry:setText(suggestion.suggestion)
    updateSuggesterComponent()
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
    updateComponents(text)

    -- correct the stream ID to the current stream
    local currentStreamName = OmiChat.chatCommandToStreamName(text)
    if currentStreamName then
        OmiChat.cycleStream(currentStreamName)
    end
end

---Override to hide icon picker and disable button on unfocus.
function ISChat:unfocus()
    _unfocus(self)
    setShowSuggesterBox(false)
    setIconButtonEnabled(false)
end

---Override to unfocus on close.
function ISChat:close()
    _close(self)

    if not self.locked then
        self:unfocus()
    end
end

---Override to improve performance of text refresh.
function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    OmiChat.redrawMessages()
end

---Override to add additional settings.
function ISChat:onGearButtonClick()
    _onGearButtonClick(self)
    setShowSuggesterBox(false)

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
                name = getText('UI_OmiChat_context_submenu_color', getColorCatStreamCommand(category))
            end

            colorSubMenu:addOption(name, ISChat.instance, ISChat.onCustomColorMenu, category)
        end
    elseif #colorOpts == 1 then
        local category = colorOpts[1]

        local name = getTextOrNull('UI_OmiChat_context_color_' .. category)
        if not name then
            name = getText('UI_OmiChat_context_color', getColorCatStreamCommand(category))
        end

        context:insertOptionBefore(subMenuName, name, ISChat.instance, ISChat.onCustomColorMenu, category)
    end
end

---Override to support custom commands and emote shortcuts.
function ISChat:onCommandEntered()
    if tryEnterSuggestedItem() then
        updateComponents()
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
    ISChat.instance.timerTextEntry = 20
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
    setShowSuggesterBox(false)

    if not handled or not iconPicker or not iconPicker:isVisible() then
        return handled
    end

    local name = target:getUIName()
    if name == ISChat.textPanelName or name == ISChat.textEntryName then
        iconPicker:setVisible(false)
    end

    return handled
end

---Override to control custom components and allow switching to custom streams.
function ISChat.onSwitchStream()
    if not ISChat.focused or not ISChat.instance then
        return
    end

    local text
    if not tryEnterSuggestedItem() then
        text = OmiChat.cycleStream()
        local entry = ISChat.instance.textEntry
        entry:setText(text)
    end

    updateComponents(text)
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
    updateComponents()
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
    updateComponents()
end

---Override to update custom components.
function ISChat:onOtherKey(key)
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox and suggesterBox:isVisible() and key == Keyboard.KEY_ESCAPE then
        setShowSuggesterBox(false)
    else
        _onOtherKey(self, key)
    end
end

---Override to update custom components.
function ISChat.onTextChange()
    _onTextChange()
    updateComponents()
end

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
        if info and not info.formatOptions.showInChat then
            return
        end
    end

    local s, e = pcall(_addLineInChat, message, tabID)
    if not s then
        print(('[OmiChat] error while adding message %s: %s'):format(tostring(message), e))
        return
    end
end


return OmiChat
