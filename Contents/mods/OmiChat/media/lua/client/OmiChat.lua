---Handles ISChat extensions.

local OmiChat = require 'OmiChatClient'
require 'OmiChat/Overrides/Chat'


local utils = OmiChat.utils
local Option = OmiChat.Option
local ColorModal = OmiChat.ColorModal
local getText = getText
local getTextOrNull = getTextOrNull
local max = math.max
local concat = table.concat


---Extended fields for ISChat.
---@class omichat.ISChat : ISChat
---@field instance omichat.ISChat? The ISChat instance.
---@field focused boolean Whether the chat is currently focused.
---@field showTitle boolean Whether chat type titles should display.
---@field showTimestamp boolean Whether timestamps should display.
---@field chatFont omichat.ChatFont The current font of the chat.
---@field chatText omichat.ChatTab The current chat tabs.
---@field tabs omichat.ChatTab[] List of available chat tabs.
---@field allChatStreams omichat.ChatStream[] List of all available chat streams.
---@field defaultTabStream table<integer, omichat.ChatStream?> An association of 1-indexed tab IDs to default streams.
---@field gearButton ISButton The settings button.
---@field textEntry ISTextEntryBox The text entry UI element.
---@field currentTabID integer The 1-indexed tab ID of the current tab.
---@field tabCnt integer The number of available tabs.
---@field iconButton ISButton? The icon button UI element.
---@field iconPicker omichat.IconPicker? The icon picker UI element.
---@field suggesterBox omichat.SuggesterBox? The suggester box UI element.
local ISChat = ISChat


---Returns the non-empty lines of a string.
---If there are no non-empty lines, returns `nil`.
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
            lines[#lines + 1] = line:sub(1, maxLen)
        elseif #line > 0 then
            lines[#lines + 1] = line
        end
    end

    if #lines == 0 then
        return
    end

    return lines
end


---Event handler for color picker selection.
---@param target omichat.ISChat
---@param button table
---@param category omichat.ColorCategory The color category that has been changed.
---@diagnostic disable-next-line: unused-local
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

    local color = OmiChat.getColorOrDefault(category)
    local text = getTextOrNull('UI_OmiChat_context_color_desc_' .. category)
    if not text then
        local catName = getTextOrNull('UI_OmiChat_context_message_type_' .. category) or
            OmiChat.getColorCategoryCommand(category)
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

    for i = 1, #lines do
        if #lines[i] > Option.CustomShoutMaxLength then
            target:setValidateTooltipText(getText('UI_OmiChat_error_shout_too_long',
                tostring(Option.CustomShoutMaxLength)))
            return false
        end
    end

    return true
end

---Event handler for accepting the custom callout dialog.
---@param target omichat.ISChat
---@param button table
---@param category omichat.CalloutCategory
---@diagnostic disable-next-line: unused-local
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

---Event handler for toggling command retaining.
---@param target omichat.ISChat
---@param type omichat.ChatCommandType
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleRetainCommand(target, type)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local value = not OmiChat.getRetainCommand(type)
    OmiChat.setRetainCommand(type, value)

    if value then
        -- don't need to clear the last command for enable
        return
    end

    -- check to see whether the last command should be cleared based on this change
    for i = 1, #instance.tabs do
        local chatText = instance.tabs[i]
        local lastChatCommand = chatText.lastChatCommand

        if lastChatCommand then
            local stream = OmiChat.chatCommandToStream(lastChatCommand, true)
            local commandType = (stream and stream.omichat and stream.omichat.commandType) or 'other'
            if commandType == type then
                chatText.lastChatCommand = ''
            end
        end
    end
end

---Event handler for toggling showing name colors.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleShowNameColor(target)
    OmiChat.setNameColorEnabled(not OmiChat.getNameColorsEnabled())
    OmiChat.redrawMessages()
end

---Event handler for toggling using the suggester.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleUseSuggester(target)
    OmiChat.setUseSuggester(not OmiChat.getUseSuggester())
    OmiChat.updateSuggesterComponent()
end

---Event handler for icon button click.
---@param target omichat.ISChat
---@return boolean
function ISChat.onIconButtonClick(target)
    local iconPicker = target.iconPicker
    if not ISChat.focused or not iconPicker then
        return false
    end

    local targetHeight = target:getHeight()
    local x = target:getX() + target:getWidth()
    local y = target:getY() + max(0, targetHeight - iconPicker:getHeight())

    -- avoid covering the button
    if x + iconPicker:getWidth() >= getPlayerScreenWidth(0) then
        y = y - target.textEntry:getHeight() - target.inset * 2 - 5

        if y <= 0 then
            y = targetHeight
        end
    end

    iconPicker:setX(x)
    iconPicker:setY(y)
    iconPicker:bringToTop()
    iconPicker:setVisible(not iconPicker:isVisible())
    OmiChat.hideSuggesterBox()

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
    OmiChat.updateSuggesterComponent()
end

---Event handler for selecting a suggestion.
---@param target omichat.ISChat
---@param suggestion omichat.Suggestion
---@diagnostic disable-next-line: unused-local
function ISChat.onSuggesterSelect(target, suggestion)
    local entry = ISChat.instance.textEntry

    OmiChat.hideSuggesterBox()
    entry:setText(suggestion.suggestion)
    OmiChat.updateSuggesterComponent()
end


return OmiChat
