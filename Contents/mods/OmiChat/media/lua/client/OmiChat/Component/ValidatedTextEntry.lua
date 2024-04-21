---@class omichat.ValidatedTextEntry : ISTextEntryBox
---@field target unknown
---@field changeTarget unknown?
---@field changeArgs table?
---@field minLength integer?
---@field maxLength integer?
---@field tooltipValid string?
local TextEntry = ISTextEntryBox:derive('ValidatedTextEntry')


---Event handler for text changes.
function TextEntry:onTextChange()
    if not self.changeFunc then
        return
    end

    local args = self.changeArgs or {}
    self.changeFunc(self.changeTarget, self, args[1], args[2])
end

---Validates the text entry before render.
function TextEntry:prerender()
    local isValid = self:validate()
    if isValid then
        self.tooltip = self.tooltipValid
    else
        self.tooltip = self.validateTooltipText
    end

    self:setValid(isValid)
    ISTextEntryBox.prerender(self)
end

---Sets a callback function to be called on text change.
---@param target unknown
---@param f fun(target: unknown, self: omichat.ValidatedTextEntry, ...)
---@param arg1 unknown?
---@param arg2 unknown?
function TextEntry:setOnChange(target, f, arg1, arg2)
    self.changeTarget = target
    self.changeFunc = f
    self.changeArgs = { arg1, arg2 }
end

---Sets the function called to validate the text entry.
---@param target unknown
---@param func fun(target: unknown, text: string, ...)
---@param arg1 unknown?
---@param arg2 unknown?
function TextEntry:setValidateFunction(target, func, arg1, arg2)
    self.validateTarget = target
    self.validateFunc = func
    self.validateArgs = { arg1, arg2 }
end

---Sets the tooltip used when validation fails.
---@param text string
function TextEntry:setValidateTooltipText(text)
    self.validateTooltipText = text
end

---Validates the input text.
---@param text string? Text to validate. Defaults to the current input.
---@return boolean valid
function TextEntry:validate(text)
    if not text then
        text = self:getInternalText()
    end

    local args = self.validateArgs or {}
    if self.validateFunc and not self.validateFunc(self.validateTarget, text, args[1], args[2]) then
        return false
    end

    if self.minLength and #text < self.minLength then
        self:setValidateTooltipText(getText('UI_OmiChat_Error_LengthMin', self.minLength))
        return false
    elseif self.maxLength and #text > self.maxLength then
        self:setValidateTooltipText(getText('UI_OmiChat_Error_LengthMax', self.maxLength))
        return false
    end

    return true
end

---Creates a new validated text entry.
---@param title string
---@param x number
---@param y number
---@param width number
---@param height number
---@param font UIFont?
---@return omichat.ValidatedTextEntry
function TextEntry:new(title, x, y, width, height, font)
    local o = ISTextEntryBox.new(self, title, x, y, width, height)

    if font then
        o.font = font
    end

    ---@cast o omichat.ValidatedTextEntry
    return o
end


return TextEntry
