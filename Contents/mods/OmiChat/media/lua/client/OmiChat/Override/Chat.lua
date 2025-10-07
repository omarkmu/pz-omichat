---Handles chat overrides.

local API = require 'OmiChat/Client'

local ISChat = ISChat ---@class omichat.ISChat

local utils = API.utils
local config = API.Configuration
local UI = utils.ui
local getText = getText
local concat = table.concat

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

local _ChatMessage = __classmetatables[ChatMessage.class].__index
local _ServerChatMessage = __classmetatables[ServerChatMessage.class].__index


---Override to enable custom formatting.
_ChatMessage.getTextWithPrefix = API.format.buildMessageText
_ServerChatMessage.getTextWithPrefix = API.format.buildMessageText


---Override to add information to chat messages and remove blank lines.
---@param message omichat.Message The new chat message.
---@param tabID integer 0-indexed tab ID.
function ISChat.addLineInChat(message, tabID)
    if not message then
        return
    end

    local info ---@type omichat.MessageInfo?
    local soundRange
    local player = getSpecificPlayer(0)

    local mtIndex = (getmetatable(message) or {}).__index
    if mtIndex == _ChatMessage or mtIndex == _ServerChatMessage or utils.isinstance(message, API.MimicMessage) then
        local username = player and player:getUsername()
        local chatType = API.MessageInfo.getMessageChatType(message)

        if chatType == 'radio' then
            local formatter = API.format.get('onlineID')
            if formatter then
                local value = formatter:read(message:getText())
                local onlineID = value and utils.decodeInvisibleInt(value)
                local authorPlayer = onlineID and API.data.getPlayerInfoByOnlineID(onlineID)
                if authorPlayer then
                    message:setAuthor(authorPlayer.username)
                elseif username and message:getAuthor() == username then
                    -- if we can't find the author, clear instead of attributing to the local player
                    message:setAuthor('')
                end
            end
        end

        if config:compatChatBubbleEnabled() and message:getText():match('%[img=media/textures/bubble%d%.png%]') then
            return
        end

        if not API.MessageInfo.hasEncodedMetadata(message) then
            API.MessageInfo.encodeMessageTag(message)
        end

        -- necessary to process transforms so we know whether this message should be added to chat
        info = API.format.buildMessageInfo(message, true)
        if info then
            if not message:isShowInChat() then
                return
            end

            if info:shouldAttractZombies(username) then
                soundRange = info:getZombieAttractionRange()
            end
        end
    end

    local s, e = pcall(_addLineInChat, message, tabID)
    if not s then
        utils.log.error('Error while adding message %s: %s', tostring(message), tostring(e))
        return
    end

    if player and soundRange and soundRange > 0 then
        addSound(player, player:getX(), player:getY(), player:getZ(), soundRange, soundRange)

        if info then
            info:setMetadataAttractedZombies()
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
    API.ui.createChildren(self)
    API.chat.updateState()
end

---Override to use the extended rich text panel.
---@return omichat.ChatTab
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
    tab.onMouseDown = ISChat.onMouseDown
    tab.render = ISChat.render_chatText

    tab:ignoreHeightChange()
    return tab
end

---Override to correct the chat stream and enable the icon button on focus.
function ISChat:focus()
    if API.player.isDeadOrUnavailable() then
        return
    end

    _focus(self)

    local text = ISChat.instance.textEntry:getInternalText()
    API.ui.updateCustomComponents(text)

    -- correct the stream ID to the current stream
    local currentStreamName = API.streams.chatCommandToStreamName(text)
    if currentStreamName then
        API.streams.cycle(currentStreamName)
    end
end

---Override to avoid adding sequential duplicates to the history log.
---@param command string
function ISChat:logChatCommand(command)
    if self.chatText.log[1] == command then
        self.chatText.logIndex = 0
        return
    end

    _logChatCommand(self, command)
end

---Override to support custom commands and emote shortcuts.
function ISChat:onCommandEntered()
    if API.player.isDeadOrUnavailable() then
        return
    end

    local instance = ISChat.instance ---@cast instance omichat.ISChat
    local input = instance.textEntry:getText()

    ---@type omichat.Stream?
    local stream, command, chatCommand, disabledStream = API.streams.chatCommandToStream(input, { enabledOnly = true })

    local useCallback
    local callbackStream

    local commandType = 'other'
    local shouldHandle = false
    local allowEmotes = false
    local isDefault = false

    if not stream then
        -- process emotes for streamless messages unless there's a leading slash
        local isCommand = utils.startsWith(input, '/')
        allowEmotes = not isCommand
        command = input

        local default = API.streams.getDefaultTabStream(instance.currentTabID)
        if not isCommand and default then
            stream = default
            allowEmotes = not isCommand and default:isAllowEmotes()
            isDefault = true
        end
    end

    if stream then
        ---@cast stream omichat.Stream
        shouldHandle = true

        if not stream:isTabID(instance.currentTabID) then
            -- wrong chat tab
            showWrongChatTabMessage(instance.currentTabID - 1, stream:getTabID() - 1, chatCommand or '')
            stream = nil
            allowEmotes = false
        else
            callbackStream = stream
            allowEmotes = not isDefault and stream:isAllowEmotes() or allowEmotes
            commandType = stream:getCommandType()

            useCallback = stream:getUseCallback()
            if not useCallback and stream:isChatStream() then
                useCallback = API.chat.send
            end
        end

        if isDefault then
            stream = nil
        end
    end

    -- handle emotes specified with .emote
    local playedEmote
    if allowEmotes and config:isEmoteMacroEnabled() then
        local emoteToPlay, start, finish, emote = API.chat.getEmoteFromCommand(command)
        if emoteToPlay then
            -- remove the emote text
            shouldHandle = true
            playedEmote = true
            command = utils.trim(command:sub(1, start - 1) .. command:sub(finish + 1))

            local player = getSpecificPlayer(0)
            if player then
                if type(emoteToPlay) == 'string' then
                    player:playEmote(emoteToPlay)
                else
                    ---@cast emote string
                    emoteToPlay(player, emote)
                end
            end
        end
    end

    local shouldRetain = API.preferences.getRetainCommand(commandType)
    if shouldRetain and stream then
        -- fix the switching functionality by updating to the used stream
        API.streams.cycle(stream:getName())
    end

    if callbackStream then
        ---@cast callbackStream omichat.Stream
        local success, err = callbackStream:validate(command)
        if err then
            API.chat.addInfoMessage(err)
        end

        if not success then
            shouldHandle = true
            callbackStream = nil
        end
    end

    if disabledStream then
        local onUseDisabled = disabledStream:getUseDisabledCallback()
        if onUseDisabled then
            onUseDisabled(disabledStream)
        elseif disabledStream:getCommandType() ~= 'chat' then
            API.chat.addInfoMessage('Unknown command ' .. command:sub(2))
        else
            local msg = { getText('UI_chat_chat_disabled_msg', utils.trim(disabledStream:getCommand())) }
            for i = 1, #ISChat.allChatStreams do
                local availableStream = ISChat.allChatStreams[i]

                local availableCommand
                if utils.isinstance(availableStream, API.ChatStream) then
                    ---@cast availableStream omichat.ChatStream
                    if availableStream:isEnabled() then
                        availableCommand = availableStream:getCommand()
                    end
                else
                    ---@cast availableStream omichat.StreamTable
                    availableCommand = availableStream.command
                end

                if availableCommand then
                    msg[#msg + 1] = '* '
                    msg[#msg + 1] = utils.trim(availableCommand)
                    msg[#msg + 1] = ' <LINE> '
                end
            end

            if #msg > 1 then
                msg[#msg] = nil
                API.chat.addInfoMessage(concat(msg))
            end
        end
    elseif not shouldHandle then
        -- no special handling, pass to original function
        _onCommandEntered(self)

        if shouldRetain then
            instance.chatText.lastChatCommand = command:sub(1, command:find(' ') or #command)
        end

        return
    end

    instance:unfocus()
    instance:logChatCommand(input)
    API.ui.scrollToBottom()

    if shouldRetain and stream then
        instance.chatText.lastChatCommand = chatCommand or ''
    elseif stream then
        -- if the used stream shouldn't be set as the last, cycle to the previous command
        local lastChatStream = API.streams.chatCommandToStreamName(instance.chatText.lastChatCommand)
        if lastChatStream then
            API.streams.cycle(lastChatStream)
        end
    end

    if callbackStream and useCallback then
        useCallback {
            text = command,
            stream = callbackStream,
            playSignedEmote = not playedEmote,
        }
    end

    doKeyPress(false)
    instance.timerTextEntry = 20
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

    local text = API.ui.getInfoRichText()
    self:setInfo(text)

    local infoDialog = self.infoRichText
    if text == '' then
        if infoDialog then
            infoDialog:removeFromUIManager()
        end

        return
    end

    if not infoDialog then
        local instance = ISChat.instance
        local screenW, screenH = UI.getScreenCenter(400, 300)
        infoDialog = UI.dialog {
            x = screenW,
            y = screenH,
            w = 600,
            h = 600,
            richText = true,
            text = self.infoText,
            alwaysOnTop = true,
            moveWithMouse = false,
            backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        }

        infoDialog.chatText:setOnUpdate(instance, API.callback.onInfoPanelUpdate)
        infoDialog:setHeightToContents()
        infoDialog:ignoreHeightChange()

        infoDialog:setY(getPlayerScreenTop(0) + (getPlayerScreenHeight(0) - infoDialog:getHeight()) * 0.5)

        self.infoRichText = infoDialog
        return
    end

    if infoDialog:isReallyVisible() then
        infoDialog:removeFromUIManager()
    else
        infoDialog:setVisible(true)
        infoDialog:addToUIManager()
    end
end

---Override to hide components on text panel or entry click.
---@param target ISUIElement
---@param x number
---@param y number
---@return boolean
function ISChat.onMouseDown(target, x, y)
    local handled = _onMouseDown(target, x, y)
    API.ui.hideSuggestBox()
    return handled
end

---Override to control custom components and allow switching to custom streams.
function ISChat.onSwitchStream()
    if not ISChat.focused or not ISChat.instance then
        return
    end

    local text
    if not (API.preferences.getSuggestOnTab() and API.chat.tryInputSuggestion()) then
        text = API.streams.cycle()
        local entry = ISChat.instance.textEntry
        entry:setText(text)
    end

    API.ui.updateCustomComponents(text)
end

---Override to respect retain options when creating chat tabs.
---@param tabTitle string
---@param tabID integer
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
---@param tabTitle string
---@param tabID integer
function ISChat.onTabRemoved(tabTitle, tabID)
    _onTabRemoved(tabTitle, tabID)
    API.ui.updateChatPanelSize()
end

---Override to update custom components and include aliases in determination for resetting input.
function ISChat.onTextChange()
    local instance = ISChat.instance
    local chatText = instance and instance.chatText
    if not instance or not chatText or not chatText.lastChatCommand then
        API.ui.updateCustomComponents()
        return
    end

    local entry = ISChat.instance.textEntry
    local internalText = entry:getInternalText()
    if not utils.endsWith(internalText, '/') then
        API.ui.updateCustomComponents()
        return
    end

    local text = entry:getText()
    if #text <= 6 then
        entry:setText('/')
        API.ui.updateCustomComponents()
        return
    end

    local shouldResetText = API.chat.shouldResetText

    for i = 1, #chatText.chatStreams do
        local prefix
        local stream = chatText.chatStreams[i]
        if utils.isinstance(stream, API.ChatStream) then
            ---@cast stream omichat.ChatStream

            local command = stream:getCommand()
            local shortCommand = stream:getCommand()
            if command then
                prefix = shouldResetText(command, text, internalText)
            end

            if not prefix and shortCommand then
                prefix = shouldResetText(shortCommand, text, internalText)
            end

            if not prefix then
                for alias in stream:aliases() do
                    prefix = shouldResetText(alias, text, internalText)
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

    API.ui.updateCustomComponents()
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
---@param self omichat.ChatTab
function ISChat.render_chatText(self)
    self:setStencilRect(0, 0, self.width, self.height)
    API.ChatTab.render(self)
    self:clearStencilRect()
end

---Override to keep the close button hidden if the always show chat option is enabled.
---@param visible boolean
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

---Override to process typing indicators.
function ISChat:update()
    _update(self)
    API.ui.updateTypingDisplay()
    API.chat.updateTypingStatus()
end

---Override to improve performance of text refresh.
function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    API.ui.redraw()
end
