---Chat overrides and extensions.

local OmiChat = require 'OmiChatClient'
local utils = OmiChat.utils
local Option = OmiChat.Option
local ColorModal = OmiChat.ColorModal


--#region definitions

local table = table
local math = math
local concat = table.concat
local split = luautils.split

---Extended fields for ISChat.
---@class omichat.ISChat : ISChat
---@field instance omichat.ISChat
---@field emojiPicker omichat.IconPicker
---@field emojiButton ISButton
---@field allChatStreams omichat.ChatStream[]
---@field defaultTabStream table<integer, omichat.ChatStream?>
local ISChat = ISChat

local getText = getText
local getTextOrNull = getTextOrNull

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
local _onTextChange = ISChat.onTextChange

local _ChatBase = __classmetatables[ChatBase.class].__index
local _ChatMessage = __classmetatables[ChatMessage.class].__index
local _ServerChatMessage = __classmetatables[ServerChatMessage.class].__index
local _IsoPlayer = __classmetatables[IsoPlayer.class].__index

local _Callout = _IsoPlayer.Callout
local _getTextWithPrefix = _ChatMessage.getTextWithPrefix

-- can't call directly on ChatBase subclasses, so have to grab these like this
local getTitleID = _ChatBase.getTitleID
local getType = _ChatBase.getType

-- color categories that aren't associated with a usable chat stream
local noStream = {
    radio = true,
    server = true,
    discord = true,
    -- name and speech colors are not chat colors
    name = true,
    speech = true,
}

OmiChat.setIconsToExclude({
    -- shadowed by colors
    thistle = true,
    salmon = true,
    tomato = true,
    orange = true,

    -- doesn't work/often not included by collectAllIcons
    boilersuitblue = true,
    boilersuitred = true,
    glovesleatherbrown = true,
    jumpsuitprisonkhaki = true,
    jumpsuitprisonorange = true,
    jacketgreen = true,
    jacketlongblack = true,
    jacketlongbrown = true,
    jacketvarsity_alpha = true,
    jacketvarsity_ky = true,
    shirtdenimblue = true,
    shirtdenimlightblue = true,
    shirtdenimlightblack = true,
    shirtlumberjackblue = true,
    shirtlumberjackgreen = true,
    shirtlumberjackgrey = true,
    shirtlumberjackred = true,
    shirtlumberjackyellow = true,
    shirtscrubsblue = true,
    shirtscrubsgreen = true,
    shortsathleticblue = true,
    shortsathleticgreen = true,
    shortsathleticred = true,
    shortsathleticyellow = true,
    shortsdenimblack = true,
    shortslongathleticgreen = true,
    tshirtathleticblue = true,
    tshirtathleticred = true,
    tshirtathleticyellow = true,
    tshirtathleticgreen = true,
    trousersscrubsblue = true,
    trousersscrubsgreen = true,

    -- visually identical to other icons
    tz_mayonnaisefullrotten = true,
    tz_mayonnaisehalf = true,
    tz_mayonnaisehalfrotten = true,
    tz_remouladefullrotten = true,
    tz_remouladehalf = true,
    tz_remouladehalfrotten = true,
    glovecompartment = true,
    truckbed = true,
    fishcatfishcooked = true,
    fishcatfishoverdone = true,
    fishcrappiecooked = true,
    fishpanfishcooked = true,
    fishpanfishoverdone = true,
    fishperchcooked = true,
    fishperchoverdone = true,
    fishpikecooked = true,
    fishpikeoverdone = true,
    fishtroutcooked = true,
    fishtroutoverdone = true,
    tvdinnerburnt = true,
    tvdinnerrotten = true,

    -- shows up overhead as text
    composter = true,
    clothingdryer = true,
    clothingwasher = true,
    mailbox = true,
    mannequin = true,
    toolcabinet = true,
})


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

---Encodes message information, including chat name and colors.
---@param author string The username of the message author.
---@param chatType omichat.ChatTypeString The chat type of the chat in which the message was sent.
---@return string
local function encodeTag(author, chatType)
    if not author then
        return ''
    end

    local color = OmiChat.getNameColorInChat(author)
    return utils.kvp.encode {
        n = OmiChat.getNameInChat(author, chatType),
        cn = color and utils.colorToHexString(color) or nil
    }
end

---Decodes message information.
---@param tag string The encoded message tag.
---@return table
local function decodeTag(tag)
    if not tag then
        return {}
    end

    local values = utils.kvp.decode(tag)
    return {
        name = values.n,
        nameColor = utils.stringToColor(values.cn),
    }
end

---onTextChange handler which forces lowercase text.
---Used in sneak callout customization modal.
---@param entry ISTextEntryBox
local function forceLowercase(entry)
    entry:setText(entry:getInternalText():lower())
end

---Applies message transforms and format options to a message.
---This does not build the final string; if a string is returned,
---it's the original message text.
---@param message ChatMessage
---@return string | omichat.MessageInfo
local function processTransforms(message)
    local instance = ISChat.instance or {}

    -- :getText() doesn't handle color & image formatting.
    -- would just use that otherwise
    local text = _getTextWithPrefix(message)

    local chat = message:getChat()
    local author = message:getAuthor() or ''
    local textColor = message:getTextColor()
    local meta = decodeTag(message:getCustomTag())

    ---@type omichat.MessageInfo
    local info = {
        message = message,
        meta = meta,
        rawText = text,
        author = author,
        titleID = getTitleID(chat),
        chatType = tostring(getType(chat)),
        textColor = textColor,

        context = {},
        substitutions = {
            author = utils.escapeRichText(author),
            authorRaw = author,
            name = utils.escapeRichText(meta.name or author),
            nameRaw = utils.escapeRichText(meta.name or author),
        },
        formatOptions = {
            font = instance.chatFont,
            showInChat = true,
            showTitle = instance.showTitle,
            showTimestamp = instance.showTimestamp,
            useChatColor = Option.AllowSetChatColors,
            useNameColor = Option.UseSpeechColorAsDefaultNameColor or (Option.AllowSetNameColor and meta.nameColor),
            stripColors = false,
        },
    }

    OmiChat.applyTransforms(info)
    if not OmiChat.applyFormatOptions(info) then
        return text
    end

    return info
end

---Gets the command associated with a color category.
---@param cat omichat.ColorCategory
---@return string?
local function getColorCatStreamCommand(cat)
    if noStream[cat] then
        return
    end

    if cat == 'private' then
        return Option.UseLocalWhisper and '/private' or '/whisper'
    end

    if cat == 'general' then
        return '/all'
    end

    if cat == 'shout' then
        return '/yell'
    end

    return '/' .. cat
end

---Sets whether the emoji button is enabled.
---This also hides the emoji picker if the button is disabled.
---@param enable boolean?
local function setEmojiButtonEnabled(enable)
    local chat = ISChat.instance
    if not chat.emojiButton then
        return
    end

    local value = enable and 0.8 or 0.3
    chat.emojiButton:setTextureRGBA(value, value, value, 1)
    chat.emojiButton.enable = enable

    if not enable and chat.emojiPicker then
        chat.emojiPicker:setVisible(false)
    end
end

---Enables or disables the emoji picker based on the current input.
---@param text string? The current text entry text.
local function updateEmojiComponents(text)
    local chat = ISChat.instance
    if not chat.emojiButton then
        return
    end

    text = text or chat.textEntry:getInternalText()
    local stream = OmiChat.chatCommandToStream(text)

    if not stream then
        stream = ISChat.defaultTabStream[chat.currentTabID]
    end

    local enable = false
    if stream and stream.omichat and stream.omichat.allowEmojiPicker ~= nil then
        -- enable emoji button for custom chats where appropriate
        enable = stream.omichat.allowEmojiPicker
    end

    setEmojiButtonEnabled(enable)
end

--#endregion

--#region handler functions

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

    local width = math.max(450, getTextManager():MeasureStringX(UIFont.Small, text) + 60)
    local modal = ColorModal:new(0, 0, width, 250, text, color, target, ISChat.onCustomColorMenuClick, 0, category)

    local minVal = Option.MinimumColorValue
    local maxVal = Option.MaximumColorValue
    if minVal > maxVal then
        local temp = minVal
        minVal = maxVal
        maxVal = temp
    end

    modal:setMinValue(minVal)
    modal:setMaxValue(maxVal)
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

---Event handler for custom callout click.
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
        modal.entry:setForceUpperCase(Option.UppercaseCustomShouts)
    elseif Option.LowercaseCustomSneakShouts then
        modal.entry.onTextChange = forceLowercase
    end

    modal:addToUIManager()
    target.activeCalloutModal = modal
end

---Event handler for toggling name colors.
---@param target omichat.ISChat
function ISChat.onToggleShowNameColor(target)
    OmiChat.setNameColorEnabled(not OmiChat.getNameColorsEnabled())
    OmiChat.redrawMessages()
end

---Event handler for emoji button click.
---@param target omichat.ISChat
---@return boolean
function ISChat.onEmojiButtonClick(target)
    if not ISChat.focused or not target.emojiPicker then
        return false
    end

    local yDelta = 0
    local height = target:getHeight()
    local pickerHeight = target.emojiPicker:getHeight()
    if height > pickerHeight then
        yDelta = height - pickerHeight
    end

    local x = target:getX() + target:getWidth()
    local y = target:getY() + yDelta

    -- avoid covering the button
    if x + target.emojiPicker:getWidth() >= getPlayerScreenWidth(0) then
        y = y - target.textEntry:getHeight() - target.inset * 2 - 5

        if y <= 0 then
            y = target:getHeight()
        end
    end

    target.emojiPicker:setX(x)
    target.emojiPicker:setY(y)
    target.emojiPicker:bringToTop()
    target.emojiPicker:setVisible(not target.emojiPicker:isVisible())

    return true
end

---Event handler for emoji picker selection.
---@param target omichat.ISChat
---@param icon string The emoji that was selected.
function ISChat.onEmojiClick(target, icon)
    if not ISChat.focused then
        target:focus()
    elseif not ISChat.instance.textEntry:isFocused() then
        ISChat.instance.textEntry:focus()
    end

    local text = target.textEntry:getInternalText()

    local addSpace = #text > 0 and text:sub(-1) ~= ' '
    target.textEntry:setText(concat { text, addSpace and ' *' or '*', icon, '*' })
end

--#endregion

--#region overrides

---Override to enable custom callouts.
---@param playEmote boolean
function _IsoPlayer:Callout(playEmote)
    if getCore():getGameMode() == 'Tutorial' then
        return _Callout(self, playEmote)
    end

    local shouts
    local range = 30
    local isSneaking = self:isSneaking()
    if isSneaking and Option.AllowCustomSneakShouts then
        range = 6
        shouts = OmiChat.getCustomShouts('sneakcallouts')
    elseif not isSneaking and Option.AllowCustomShouts then
        shouts = OmiChat.getCustomShouts('callouts')
    end

    if not shouts or #shouts == 0 then
        return _Callout(self, playEmote)
    end

    -- this doesn't set .callOut, so minor boredom reduction will occur from shouting
    -- already possible to use chat for that purpose, so this isn't really problematic
    addSound(self, self:getX(), self:getY(), self:getY(), range, range)

    local shoutMax = Option.MaximumCustomShouts > 0 and math.min(#shouts, Option.MaximumCustomShouts) or #shouts

    local shout = shouts[ZombRand(1, shoutMax + 1)]
    if not isSneaking and Option.UppercaseCustomShouts then
        shout = shout:upper()
    elseif isSneaking and Option.LowercaseCustomSneakShouts then
        shout = shout:lower()
    end

    processShoutMessage(shout)

    if playEmote then
        self:playEmote('shout')
    end
end

---Override to modify chat format.
---@return string
function _ChatMessage:getTextWithPrefix()
    local info = processTransforms(self)
    if type(info) == 'string' then
        return info
    end

    -- rebuild the string with the desired format
    return concat {
        utils.toChatColor(info.formatOptions.color),
        '<SIZE:', info.formatOptions.font or 'medium', '> ',
        info.timestamp or '',
        info.tag or '',
        utils.interpolate(info.format, info.substitutions),
    }
end

---Override also applies to ServerChatMessage.
_ServerChatMessage.getTextWithPrefix = _ChatMessage.getTextWithPrefix

---Override to add emoji button and picker.
function ISChat:createChildren()
    _createChildren(self)
    OmiChat.updateState()
end

---Override to correct the chat stream and enable the emoji button on focus.
function ISChat:focus()
    _focus(self)
    updateEmojiComponents()

    -- correct the stream ID to the current stream
    local currentStreamName = OmiChat.chatCommandToStreamName(ISChat.instance.textEntry:getInternalText())
    if currentStreamName then
        OmiChat.cycleStream(currentStreamName)
    end
end

---Override to hide emoji picker and disable button on unfocus.
function ISChat:unfocus()
    _unfocus(self)
    setEmojiButtonEnabled(false)

    if self.emojiPicker then
        self.emojiPicker:setVisible(false)
    end
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
    local showNameColorOption = Option.AllowSetNameColor or Option.UseSpeechColorAsDefaultNameColor

    local colorOpts = {}
    if Option.AllowSetNameColor then
        colorOpts[#colorOpts+1] = 'name'
    end
    if Option.AllowSetSpeechColor then
        colorOpts[#colorOpts+1] = 'speech'
    end

    if Option.AllowSetChatColors then
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

        if Option.UseLocalWhisper then
            colorOpts[#colorOpts+1] = 'whisper'
        elseif checkPlayerCanUseChat('/w') then
            colorOpts[#colorOpts+1] = 'private'
        end

        if checkPlayerCanUseChat('/y') then
            colorOpts[#colorOpts+1] = 'shout'
        end

        if Option.AllowMe then
            colorOpts[#colorOpts+1] = 'me'
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

        if Option.UseLocalWhisper and checkPlayerCanUseChat('/w') then
            colorOpts[#colorOpts+1] = 'private'
        end
    end

    local shoutOpts = {}
    if Option.AllowCustomShouts then
        shoutOpts[#shoutOpts+1] = 'callouts'
    end
    if Option.AllowCustomSneakShouts then
        shoutOpts[#shoutOpts+1] = 'sneakcallouts'
    end

    local subMenuName
    if #colorOpts > 0 or #shoutOpts > 0 or showNameColorOption then
        -- insert new options before the first submenu
        local firstSubMenu
        for _, opt in ipairs(context.options) do
            if opt.subOption and opt.subOption > 0 then
                firstSubMenu = opt
                break
            end
        end

        subMenuName = firstSubMenu and firstSubMenu.name or ''
    end

    if showNameColorOption then
        local nameColorOptionName
        if OmiChat.getNameColorsEnabled() then
            nameColorOptionName = getText('UI_OmiChat_context_disable_name_colors')
        else
            nameColorOptionName = getText('UI_OmiChat_context_enable_name_colors')
        end

        context:insertOptionBefore(subMenuName, nameColorOptionName, ISChat.instance, ISChat.onToggleShowNameColor)
    end

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

        local name = getText('UI_OmiChat_context_color_' .. category)
        if not name then
            name = getText('UI_OmiChat_context_color', getColorCatStreamCommand(category))
        end

        context:insertOptionBefore(subMenuName, name, ISChat.instance, ISChat.onCustomColorMenu, category)
    end
end

---Override to support custom commands and emote shortcuts.
function ISChat:onCommandEntered()
    local chat = ISChat.instance
    local input = chat.textEntry:getText()
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

        local default = ISChat.defaultTabStream[chat.currentTabID]
        if not isCommand and default then
            stream = default
            isDefault = true
        end
    end

    if stream then
        if stream.tabID and chat.currentTabID ~= stream.tabID then
            -- wrong chat tab
            showWrongChatTabMessage(chat.currentTabID - 1, stream.tabID - 1, chatCommand or '')
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
    if allowEmotes and Option.AllowEmotes then
        local start, finish, whitespace, emote = command:find('(%s*)%.([%w_]+)')
        if start and whitespace and start ~= 1 and #whitespace == 0 then
            -- require whitespace unless the emote is at the start
            emote = nil
        end

        local emoteToPlay = emote and OmiChat.getEmote(emote:lower())
        if type(emoteToPlay) == 'string' then
            -- remove the emote text and ignore subsequent emotes
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

    chat:unfocus()
    chat:logChatCommand(input)
    OmiChat.scrollToBottom()

    if allowRetain and stream then
        chat.chatText.lastChatCommand = chatCommand
    elseif stream then
        -- if the used stream shouldn't be set as the last, cycle to the previous command
        local lastChatStream = OmiChat.chatCommandToStreamName(chat.chatText.lastChatCommand)
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

---Override to hide emoji picker on text panel or entry click.
---@param target unknown
---@param x number
---@param y number
---@return boolean
function ISChat.onMouseDown(target, x, y)
    local handled = _onMouseDown(target, x, y)
    local instance = ISChat.instance

    if not handled or not instance.emojiPicker or not instance.emojiPicker:isVisible() then
        return handled
    end

    local name = target:getUIName()
    if name == ISChat.textPanelName or name == ISChat.textEntryName then
        instance.emojiPicker:setVisible(false)
    end

    return handled
end

---Override to allow switching to custom streams.
function ISChat.onSwitchStream()
    if not ISChat.focused then
        return
    end

    local entry = ISChat.instance.textEntry
    local parts = split(entry:getInternalText(), ' ')

    if #parts > 1 then
        local onlineUsers = getOnlinePlayers()
        for i = 0, onlineUsers:size() - 1 do
            local username = onlineUsers:get(i):getUsername()
            if username:lower():match(parts[#parts]:lower()) then
                parts[#parts] = username
                entry:setText(concat(parts, ' '))
                return
            end
        end
    end

    local text = OmiChat.cycleStream()
    entry:setText(text)
    updateEmojiComponents(text)
end

---Override to update emoji button.
function ISChat.onPressDown()
    _onPressDown()
    updateEmojiComponents()
end

---Override to update emoji button.
function ISChat.onPressUp()
    _onPressUp()
    updateEmojiComponents()
end

---Override to update emoji button.
function ISChat.onTextChange()
    _onTextChange()
    updateEmojiComponents()
end

---Override to add information to chat messages and remove blank lines.
---@param message ChatMessage
---@param tabID integer
function ISChat.addLineInChat(message, tabID)
    if not message then
        return
    end

    local mtIndex = (getmetatable(message) or {}).__index
    if mtIndex == _ChatMessage or mtIndex == _ServerChatMessage then
        local chatType = tostring(getType(message:getChat()))
        message:setCustomTag(encodeTag(message:getAuthor(), chatType))

        -- necessary to process transforms so we know whether this message should be added to chat
        local info = processTransforms(message)
        if type(info) == 'table' and not info.formatOptions.showInChat then
            return
        end
    end

    return _addLineInChat(message, tabID)
end

--#endregion


return OmiChat
