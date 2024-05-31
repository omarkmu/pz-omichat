local utils = require 'OmiChat/util'
local Keyboard = Keyboard
local KEY_UP = Keyboard.KEY_UP
local KEY_DOWN = Keyboard.KEY_DOWN
local KEY_RETURN = Keyboard.KEY_RETURN

---@class omichat.ValidatedTextEntry : ISUIElement
---@field width number
---@field height number
---@field minLength integer?
---@field maxLength integer?
---@field fontHgt integer?
---@field tooltipText string? The tooltip text to use when the input is valid.
---@field validateTooltipText string? The tooltip text to use when the input is invalid.
---@field requireNumber boolean
---@field requireValue boolean If true, the text entry will not be valid if empty.
---@field minValue number?
---@field maxValue number?
---@field protected changeCb omichat.CallbackInfo?
---@field protected focusGainCb omichat.CallbackInfo?
---@field protected focusLossCb omichat.CallbackInfo?
---@field protected keyCb omichat.CallbackInfo?
---@field protected validateCb omichat.CallbackInfo?
---@field protected wasFocused boolean
---@field protected font UIFont? Used only during initialization.
---@field protected maxLines integer? Used only during initialization.
---@field protected text string
---@field protected entry ISTextEntryBox
---@field protected widthRatio number
---@field protected heightRatio number
---@field protected javaObject UIElement
local TextEntry = ISUIElement:derive('ValidatedTextEntry')

---@class omichat.ValidatedTextEntryArgs
---@field x integer
---@field y integer
---@field w integer
---@field h integer
---@field minLength integer?
---@field maxLength integer?
---@field maxLines integer?
---@field tooltipText string?
---@field text string?
---@field font UIFont?
---@field requireNumber boolean?
---@field requireValue boolean?
---@field minValue number?
---@field maxValue number?
---@field anchorTop boolean?
---@field anchorBottom boolean?
---@field anchorLeft boolean?
---@field anchorRight boolean?


---`onCommandEntered` handler for the text entry.
---@param entry ISTextEntryBox
local function onEntryCommandEntered(entry)
    local parent = entry.parent ---@type omichat.ValidatedTextEntry
    if not parent or not parent.onCommandEntered then
        return
    end

    parent.onCommandEntered(parent)
end

---`onOtherKey` handler for the text entry.
---@param entry ISTextEntryBox
---@param key integer
local function onEntryOtherKey(entry, key)
    local parent = entry.parent ---@type omichat.ValidatedTextEntry
    if not parent or not parent.onOtherKey then
        return
    end

    parent.onOtherKey(parent, key)
end

---`onPressDown` handler for the text entry.
---@param entry ISTextEntryBox
local function onEntryPressDown(entry)
    local parent = entry.parent ---@type omichat.ValidatedTextEntry
    if not parent or not parent.onPressDown then
        return
    end

    parent.onPressDown(parent)
end

---`onPressUp` handler for the text entry.
---@param entry ISTextEntryBox
local function onEntryPressUp(entry)
    local parent = entry.parent ---@type omichat.ValidatedTextEntry
    if not parent or not parent.onPressUp then
        return
    end

    parent.onPressUp(parent)
end

---`onTextChange` handler for the text entry.
---@param entry ISTextEntryBox
local function onEntryTextChange(entry)
    local parent = entry.parent ---@type omichat.ValidatedTextEntry
    if not parent or not parent.onTextChange then
        return
    end

    parent.onTextChange(parent)
end


---Clears the text entry input.
---@param notify boolean? If true, this will trigger onTextChange.
function TextEntry:clear(notify)
    if notify then
        -- clear notifies already
        self.entry:clear()
        return
    end

    self:setText('', notify)
end

---Removes the text entry from the UI.
function TextEntry:destroy()
    if not self.javaObject then
        return
    end

    local parent = self.javaObject:getParent()
    if parent then
        parent:RemoveChild(self.javaObject)
    else
        self:removeFromUIManager()
    end
end

---Focuses the entry.
---@param notify boolean? If true, this will trigger the focus gain callback.
function TextEntry:focus(notify)
    self.entry:focus()

    if notify then
        utils.triggerCallback(self.focusGainCb)
    end
end

---Gets the current cursor position of the text entry.
---This returns the position on the current line.
---@return integer
function TextEntry:getCursorPos()
    return self.entry:getCursorPos()
end

---Returns whether text entry input is forced to uppercase.
---@return boolean
function TextEntry:getForceUpperCase()
    return self.entry.javaObject:getForceUpperCase()
end

---Gets the alpha of the text entry frame.
---@return number
function TextEntry:getFrameAlpha()
    return self.entry:getFrameAlpha()
end

---Gets the current internal text of the input.
---@return string
function TextEntry:getInternalText()
    return self.entry:getInternalText()
end

---Gets the current text of the input.
---@return string
function TextEntry:getText()
    return self.entry:getText()
end

---Gets the maximum lines of the text entry.
---@return integer
function TextEntry:getMaxLines()
    return self.entry:getMaxLines()
end

---Returns the maximum text length, used for validation.
---@return integer?
function TextEntry:getMaxLength()
    return self.maxLength
end

---Gets the enforced maximum length of the entry.
---@return integer
function TextEntry:getMaxTextLength()
    return self.entry.javaObject:getMaxTextLength()
end

---Returns the maximum numeric value of the input.
---@return number?
function TextEntry:getMaxValue()
    return self.maxValue
end

---Returns the minimum text length, used for validation.
---@return integer?
function TextEntry:getMinLength()
    return self.minLength
end

---Returns the minimum numeric value of the input.
---@return number?
function TextEntry:getMinValue()
    return self.minValue
end

---Returns whether the entry requires numeric input.
---@return boolean
function TextEntry:getRequireNumber()
    return self.requireNumber
end

---Returns the tooltip text used when the input is valid.
---@return string?
function TextEntry:getTooltipText()
    return self.tooltipText
end

---Returns the tooltip text used when the input is invalid.
---@return string?
function TextEntry:getValidateTooltipText()
    return self.validateTooltipText
end

---Sets that the entry should ignore the first input.
function TextEntry:ignoreFirstInput()
    self.entry:ignoreFirstInput()
end

---Performs initialization.
function TextEntry:initialise()
    ISUIElement.initialise(self)

    self.fontHgt = getTextManager():getFontHeight(self.font)

    local maxLines = self.maxLines or 1

    local entry = ISTextEntryBox:new(self.text, 0, 0, self.width, self.height)
    entry.anchorRight = true
    entry.anchorBottom = true
    entry.font = self.font
    entry.onPressUp = onEntryPressUp
    entry.onPressDown = onEntryPressDown
    entry.onCommandEntered = onEntryCommandEntered
    entry.onOtherKey = onEntryOtherKey
    entry.onTextChange = onEntryTextChange
    entry:initialise()
    entry:instantiate()
    entry:setMaxLines(maxLines)
    entry:setMultipleLine(maxLines > 1)

    self.entry = entry
    self:addChild(entry)
end

---Returns whether the entry is currently editable.
---@return boolean
function TextEntry:isEditable()
    return self.entry:isEditable()
end

---Returns whether the entry currently has focus.
---@return boolean
function TextEntry:isFocused()
    return self.entry:isFocused()
end

---Returns whether entry input is masked.
---@return boolean
function TextEntry:isMasked()
    return self.entry.javaObject:isMasked()
end

---Returns whether the entry is multiline.
---@return boolean
function TextEntry:isMultipleLine()
    return self.entry:isMultipleLine()
end

---Returns whether the text in the entry can be selected.
---@return boolean
function TextEntry:isSelectable()
    return self.entry:isSelectable()
end

---Called when `Enter` is pressed while focused.
function TextEntry:onCommandEntered()
    utils.triggerCallback(self.keyCb, KEY_RETURN)
end

---Called when `Tab` or `Escape` is pressed while focused.
---@param key integer
function TextEntry:onOtherKey(key)
    utils.triggerCallback(self.keyCb, key)
end

---Called when `Down` is pressed while focused.
function TextEntry:onPressDown()
    utils.triggerCallback(self.keyCb, KEY_DOWN)
end

---Called when `Up` is pressed while focused.
function TextEntry:onPressUp()
    utils.triggerCallback(self.keyCb, KEY_UP)
end

---Called when the entry is resized.
function TextEntry:onResize()
    if not self.entry then
        return
    end

    self.entry:setX(0)
    self.entry:setY(0)
    self.entry:setWidth(self.width * self.widthRatio)
    self.entry:setHeight(self.height * self.heightRatio)
end

---Runs when text is changed in the entry.
function TextEntry:onTextChange()
    utils.triggerCallback(self.changeCb)
end

---Runs before each render.
function TextEntry:prerender()
    local isValid = self:validate()
    if isValid then
        self.entry.tooltip = self.tooltipText
    else
        self.entry.tooltip = self.validateTooltipText
    end

    self:setValid(isValid)
end

---Selects all text in the entry.
function TextEntry:selectAll()
    self.entry:selectAll()
end

---Sets whether the text entry has a clear button.
---@param hasButton boolean
function TextEntry:setClearButton(hasButton)
    self.entry:setClearButton(hasButton)
end

---Sets the current cursor position of the text entry.
---This sets the position on the current line.
---@param pos integer
function TextEntry:setCursorPos(pos)
    self.entry:setCursorPos(pos)
end

---Sets whether the entry can be edited.
---@param editable boolean
function TextEntry:setEditable(editable)
    self.entry.javaObject:setEditable(editable)
end

---Sets whether text entry input should be forced to be uppercase.
---@param forceUpperCase boolean
function TextEntry:setForceUpperCase(forceUpperCase)
    self.entry:setForceUpperCase(forceUpperCase)
end

---Sets the alpha of the text entry frame.
---@param alpha number
function TextEntry:setFrameAlpha(alpha)
    self.entry:setFrameAlpha(alpha)
end

---Sets whether the text entry has a frame.
---@param hasFrame boolean
function TextEntry:setHasFrame(hasFrame)
    self.entry:setHasFrame(hasFrame)
end

---Sets whether text entry input should be masked.
---@param masked boolean
function TextEntry:setMasked(masked)
    self.entry:setMasked(masked)
end

---Sets the maximum lines of the entry.
---@param maxLines integer
function TextEntry:setMaxLines(maxLines)
    self.entry:setMaxLines(maxLines)
end

---Sets the maximum length of the entry for validation.
---@param length number?
function TextEntry:setMaxLength(length)
    self.maxLength = length
end

---Sets the maximum length of the entry.
---This enforces the maximum, unlike `setMaxLength`.
---@param length number
function TextEntry:setMaxTextLength(length)
    self.entry:setMaxTextLength(length)
end

---Sets the maximum value of the input.
---@param val number?
function TextEntry:setMaxValue(val)
    self.maxValue = val
end

---Sets the minimum length of the entry for validation.
---@param length number?
function TextEntry:setMinLength(length)
    self.minLength = length
end

---Sets the minimum value of the input.
---@param val number
function TextEntry:setMinValue(val)
    self.minValue = val
end

---Sets whether the entry is multiline.
---@param multiple boolean
function TextEntry:setMultipleLine(multiple)
    self.entry:setMultipleLine(multiple)
end

---Sets whether the input requires a valid number.
---@param requireNumber boolean
function TextEntry:setRequireNumber(requireNumber)
    self.requireNumber = requireNumber
end

---Sets whether the input requires a value.
---@param requireValue boolean
function TextEntry:setRequireValue(requireValue)
    self.requireValue = requireValue
end

---Sets a callback function to be called on text change.
---@param target unknown
---@param f function?
---@param ... unknown
function TextEntry:setOnChange(target, f, ...)
    self.changeCb = utils.createCallback(target, f, ...)
end

---Sets a callback function to be called when focus is gained on the text entry.
---@param target unknown
---@param f function?
---@param ... unknown
function TextEntry:setOnFocusGained(target, f, ...)
    self.focusGainCb = utils.createCallback(target, f, ...)
end

---Sets a callback function to be called when focus is lost on the text entry.
---@param target unknown
---@param f function?
---@param ... unknown
function TextEntry:setOnFocusLost(target, f, ...)
    self.focusLossCb = utils.createCallback(target, f, ...)
end

---Sets a callback function to be called when Enter, Tab, Escape, Up, or Down or pressed.
---@param target unknown
---@param f fun(target: unknown, key: integer, ...)?
---@param ... unknown
function TextEntry:setOnKey(target, f, ...)
    self.keyCb = utils.createCallback(target, f, ...)
end

---Sets whether the input should accept only numbers.
---@param onlyNumbers boolean
function TextEntry:setOnlyNumbers(onlyNumbers)
    self:setRequireNumber(true)
    self.entry:setOnlyNumbers(onlyNumbers)
end

---Sets whether text in the entry can be selected.
---@param selectable boolean
function TextEntry:setSelectable(selectable)
    self.entry:setSelectable(selectable)
end

---Sets the current text of the entry.
---@param text string The text to set on the entry.
---@param notify boolean? If true, this will trigger onTextChange.
function TextEntry:setText(text, notify)
    self.entry.javaObject:SetText(text or '')

    if notify then
        self:onTextChange()
    end
end

---Sets the tooltip used when text is valid.
---@param text string
function TextEntry:setTooltip(text)
    self.tooltipText = text and text:gsub('\\n', '\n') or nil
end

---Sets whether the current text is valid.
---@param valid boolean
function TextEntry:setValid(valid)
    self.entry.borderColor = valid and self.borderColorValid or self.borderColorInvalid
end

---Sets the function called to validate the text entry.
---@param target unknown
---@param f fun(target: unknown, text: string, ...)?
---@param ... unknown
function TextEntry:setValidateFunction(target, f, ...)
    self.validateCb = utils.createCallback(target, f, ...)
end

---Sets the tooltip used when validation fails.
---@param text string?
function TextEntry:setValidateTooltipText(text)
    self.validateTooltipText = text
end

---Releases focus from the entry.
---@param notify boolean? If true, this will trigger the focus loss callback.
function TextEntry:unfocus(notify)
    self.entry:unfocus()

    if notify then
        utils.triggerCallback(self.focusLossCb)
    end
end

---Called every 100ms.
function TextEntry:update()
    self:_checkFocus()
end

---Validates the input text.
---@param text string? Text to validate. Defaults to the current input.
---@return boolean valid
function TextEntry:validate(text)
    if not text then
        text = self:getInternalText()
    end

    if self.validateCb and not utils.triggerCallback(self.validateCb) then
        return false
    end

    if #utils.trim(text) == 0 then
        if self.requireValue then
            self:setValidateTooltipText(getText('UI_OmiChat_Error_RequireValue'))
            return false
        end

        return true
    end

    if self.minLength and #text < self.minLength then
        self:setValidateTooltipText(getText('UI_OmiChat_Error_LengthMin', self.minLength))
        return false
    elseif self.maxLength and #text > self.maxLength then
        self:setValidateTooltipText(getText('UI_OmiChat_Error_LengthMax', self.maxLength))
        return false
    end

    local num = tonumber(text)
    if num then
        if self.minValue and num < self.minValue then
            self:setValidateTooltipText(getText('UI_OmiChat_Error_ValueMin', tostring(self.minValue)))
            return false
        elseif self.maxValue and num > self.maxValue then
            self:setValidateTooltipText(getText('UI_OmiChat_Error_ValueMax', tostring(self.maxValue)))
            return false
        end
    elseif self.requireNumber then
        self:setValidateTooltipText(getText('UI_OmiChat_Error_RequireNumber'))
        return false
    end

    return true
end

---Checks for focus gain or loss.
---@protected
function TextEntry:_checkFocus()
    local isFocused = self.entry:isFocused()
    if isFocused == self.wasFocused then
        return
    end

    if isFocused then
        utils.triggerCallback(self.focusGainCb)
    else
        utils.triggerCallback(self.focusLossCb)
    end

    self.wasFocused = isFocused
end

---Creates a new validated text entry.
---@param args omichat.ValidatedTextEntryArgs
---@return omichat.ValidatedTextEntry
function TextEntry:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local w = args.w or 0
    local h = args.h or 0

    local this = ISUIElement.new(self, x, y, w, h)
    ---@cast this omichat.ValidatedTextEntry

    this.x = x
    this.y = y
    this.width = w
    this.height = h
    this.widthRatio = 1
    this.heightRatio = 1
    this.minLength = args.minLength
    this.maxLength = args.maxLength
    this.minValue = args.minValue
    this.maxValue = args.maxValue
    this.requireNumber = args.requireNumber or false
    this.requireValue = args.requireValue or false

    this.text = tostring(args.text or '')
    this.tooltipText = args.tooltipText
    this.font = args.font or UIFont.Medium
    this.borderColorValid = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    this.borderColorInvalid = { r = 0.7, g = 0.1, b = 0.1, a = 0.7 }
    this.maxLines = args.maxLines
    this.anchorBottom = utils.default(args.anchorBottom, this.anchorBottom)
    this.anchorTop = utils.default(args.anchorTop, this.anchorTop)
    this.anchorLeft = utils.default(args.anchorLeft, this.anchorTop)
    this.anchorRight = utils.default(args.anchorRight, this.anchorTop)

    return this
end


return TextEntry
