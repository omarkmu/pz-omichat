---Handles chat overrides.
---@namespace omichat

local API = require 'OmiChat/Client'

local ISChat = ISChat --[[@as omichat.ISChat]]

local utils = API.utils
local config = API.Configuration
local UI = utils.ui

local _addLineInChat = ISChat.addLineInChat
local _onCommandEntered = ISChat.onCommandEntered
local _logChatCommand = ISChat.logChatCommand
local _createChildren = ISChat.createChildren
local _focus = ISChat.focus
local _unfocus = ISChat.unfocus
local _close = ISChat.close
local _onMouseDown = ISChat.onMouseDown
local _onTabAdded = ISChat.onTabAdded
local _onTabRemoved = ISChat.onTabRemoved
local _update = ISChat.update
local _render = ISChat.render
local _setDrawFrame = ISChat.setDrawFrame
local _onActivateView = ISChat.onActivateView

local _ChatMessage = __classmetatables[ChatMessage.class].__index
local _ServerChatMessage = __classmetatables[ServerChatMessage.class].__index


---Override to enable custom formatting.
_ChatMessage.getTextWithPrefix = API.messages.getTextWithPrefix
_ServerChatMessage.getTextWithPrefix = API.messages.getTextWithPrefix


---Override to add information to chat messages and remove blank lines.
---@param message table The new chat message.
---@param tabID integer 0-indexed tab ID.
function ISChat.addLineInChat(message, tabID)
    if not message then
        return
    end

    local player = getSpecificPlayer(0) ---@type IsoPlayer?

    local soundRange
    local info ---@type MessageInfo?
    if API.messages.isManaged(message) then
        -- ignore empty messages
        if message:getText():trim() == '' then
            return
        end

        local username = player and player:getUsername()
        if config:compatChatBubbleEnabled() and message:getText():match('%[img=media/textures/bubble%d%.png%]') then
            return
        end

        API.messages.encodeInitialMetadata(message)

        -- necessary to process so we know whether the message should be added to chat
        info = API.messages.process(message)
        if not message:isShowInChat() then
            return
        end

        if username and info:shouldAttractZombies(username) then
            soundRange = info.zombieAttractRange
        end
    end

    local s, e = pcall(_addLineInChat, message, tabID)
    if not s then
        utils.log.error('Error while adding message %s: %s', message, e)
        return
    end

    if player and soundRange and soundRange > 0 then
        ---@diagnostic disable-next-line: param-type-not-match
        addSound(player, player:getX(), player:getY(), player:getZ(), soundRange, soundRange)

        if info then
            info.meta:set('attractedZombies', true)
        end
    end
end

---Override to unfocus on close.
function ISChat:close()
    if config.General.AlwaysShowChat then
        return
    end

    _close(self)

    if not self.locked then
        self:unfocus()
        API.chat.updateTypingStatus(true)
    end
end

---Override to add custom components.
function ISChat:createChildren()
    _createChildren(self)
    API.ui._createChildren(self) ---@diagnostic disable-line: invisible
    API.chat.updateState()
end

---Override to use the extended rich text panel.
---@return ChatTab
function ISChat:createTab()
    local y = self:titleBarHeight() + self.btnHeight + self.inset * 2

    ---@type omi.ui.InitArgs.RichTextPanel
    local args = {
        x = 0,
        y = y,
        w = self:getWidth(),
        h = self.textEntry:getY() - y,
        autosetheight = false,
        visible = false,
        background = false,
        anchorBottom = true,
        anchorLeft = true,
        anchorTop = true,
        anchorRight = true,
        addVerticalScrollbar = true,
        invisibleScrollbars = true,
        clip = true,
        maxLines = 500,
        marginTop = 2,
        marginBottom = 0,
        logger = utils.log,
    }

    local tab = API.ChatTab:new(args)

    tab:initialise()
    tab:instantiate()
    UI.init(tab, args)

    tab.onRightMouseUp = ISChat.onRightMouseUp
    tab.onRightMouseDown = ISChat.onRightMouseDown
    tab.onMouseUp = ISChat.onMouseUp
    tab.onMouseDown = ISChat.onMouseDown ---@diagnostic disable-line: preferred-local-alias
    tab.render = ISChat.render_chatText

    tab:ignoreHeightChange()
    return tab
end

---Override to correct the chat stream and enable the icon button on focus.
function ISChat:focus()
    local instance = ISChat.instance
    if not instance or API.player.isDeadOrUnavailable() then
        return
    end

    _focus(self)

    API.ui.updateComponents()

    -- correct the stream ID to the current stream
    local text = instance.textEntry:getInternalText()
    local currentStreamName = API.streams.chatCommandToStreamName(text)
    if currentStreamName then
        API.streams.cycle(currentStreamName)
    end
end

---Override to avoid adding sequential duplicates to the history log.
---@param command string The command to add to the history log.
function ISChat:logChatCommand(command)
    if self.chatText.log[1] == command then
        self.chatText.logIndex = 0
        return
    end

    _logChatCommand(self, command)
end

---Override to correct info text on tab panel activation.
function ISChat:onActivateView()
    _onActivateView(self)
    API.ui.updateInfoText()
end

---Override to support custom commands and macros.
function ISChat:onCommandEntered()
    local instance = ISChat.instance
    if not instance or API.player.isDeadOrUnavailable() then
        return
    end

    local input = instance.textEntry:getText()
    local handled, shouldRetain = API.chat.processCommand({ input = input })
    if handled then
        return
    end

    _onCommandEntered(self)

    if shouldRetain then
        instance.chatText.lastChatCommand = input:sub(1, input:find(' ') or #input)
    end
end

---Override to add additional settings and reorganize existing ones.
function ISChat:onGearButtonClick()
    if API.player.isDeadOrUnavailable() then
        -- avoid errors from clicking the button after dying
        return
    end

    API.ui.hideSuggestBox()
    API.ui.showSettingsContextMenu()
end

---Override to handle custom info text.
function ISChat:onInfo()
    API.ui.hideSuggestBox()
    API.ui.toggleInfo()
end

---Override to hide components on text panel or entry click.
---@param target ISUIElement The target element.
---@param x number The X position of the click.
---@param y number The Y position of the click.
---@return boolean handled
function ISChat.onMouseDown(target, x, y)
    local handled = _onMouseDown(target, x, y)
    API.ui.hideSuggestBox()
    return handled
end

---Override to control custom components and allow switching to custom streams.
function ISChat.onSwitchStream()
    local instance = ISChat.instance
    if not ISChat.focused or not instance then
        return
    end

    if not API.preferences.getSuggestOnTab() or not API.chat.tryInputSuggestion() then
        local text = API.streams.cycle()
        local entry = instance.textEntry
        entry:setText(text)
    end

    API.ui.updateComponents()
end

---Override to respect retain options when creating chat tabs.
---@param tabTitle string The translated title of the tab.
---@param tabID integer 0-indexed tab ID.
function ISChat.onTabAdded(tabTitle, tabID)
    _onTabAdded(tabTitle, tabID)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local target
    for i = 1, #instance.tabs do
        if instance.tabs[i].tabID == tabID then
            target = instance.tabs[i]
            break
        end
    end

    if target then
        ---@diagnostic disable-next-line: invisible
        API.chat._checkLastCommand(target)
    end

    API.ui.updateChatPanelSize()
end

---Override to correct the chat panel sizes after removing a tab.
---@param tabTitle string The translated title of the tab.
---@param tabID integer 0-indexed tab ID.
function ISChat.onTabRemoved(tabTitle, tabID)
    _onTabRemoved(tabTitle, tabID)
    API.ui.updateChatPanelSize()
end

---Override to update custom components and include aliases in determination for resetting input.
function ISChat.onTextChange()
    local instance = ISChat.instance
    local chatText = instance and instance.chatText
    if not instance or not chatText or not chatText.lastChatCommand then
        API.ui.updateComponents()
        return
    end

    local entry = instance.textEntry
    local internalText = entry:getInternalText()
    if not utils.endsWith(internalText, '/') then
        API.ui.updateComponents()
        return
    end

    local text = entry:getText()
    if #text <= 6 then
        entry:setText('/')
        API.ui.updateComponents()
        return
    end

    for i = 1, #chatText.chatStreams do
        local prefix
        local stream = chatText.chatStreams[i]
        if utils.isinstance(stream, API.ChatStream) then
            local command = stream:getCommand()
            if command then
                prefix = API.chat.shouldResetText(command, text, internalText)
            end

            local shortCommand = not prefix and stream:getShortCommand()
            if shortCommand then
                prefix = API.chat.shouldResetText(shortCommand, text, internalText)
            end

            if not prefix then
                for alias in stream:aliases() do
                    prefix = API.chat.shouldResetText(alias, text, internalText)
                    if prefix then
                        break
                    end
                end
            end
        end

        if prefix and #text:sub(#prefix + 1, #text) <= 5 then
            entry:setText('/')
            break
        end
    end

    API.ui.updateComponents()
end

---Override to render the typing indicator.
function ISChat:render()
    _render(self)

    if self.currentTabID ~= 1 then
        return
    end

    local w = self:getWidth()
    local text = API.ui.getTypingDisplay(w)
    if not text then
        return
    end

    local x = 4
    local y = self.textEntry:getY() - API.ui.typingFontHgt - 3
    self:setStencilRect(0, 0, w, self:getHeight())
    self:drawText(text, x, y, 1, 1, 1, 1, API.ui.typingFont)
    self:clearStencilRect()
end

---Override to use the extended rich text panel rendering.
---@param tab ChatTab The chat tab to render.
function ISChat.render_chatText(tab)
    tab:setStencilRect(0, 0, tab.width, tab.height)
    API.ChatTab.render(tab)
    tab:clearStencilRect()
end

---Override to keep the close button hidden if the always show chat option is enabled.
---@param visible boolean Flag for whether the frame should be drawn.
function ISChat:setDrawFrame(visible)
    if not config.General.AlwaysShowChat then
        _setDrawFrame(self, visible)
        return
    end

    self.background = visible
    self.drawFrame = visible
end

---Override to hide suggest box and disable button on unfocus.
function ISChat:unfocus()
    _unfocus(self)
    API.ui.hideSuggestBox()
end

---Override to process typing indicators and update custom buttons.
function ISChat:update()
    _update(self)
    API.ui.updateTypingDisplay()
    API.chat.updateTypingStatus()
    API.ui.updateButtons()
end

---Override to improve performance of text refresh.
function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    API.ui.redraw()
end
