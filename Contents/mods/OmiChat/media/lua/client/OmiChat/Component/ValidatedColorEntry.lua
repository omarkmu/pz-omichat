local ColorModal = require 'OmiChat/Component/ColorModal'

---@class omichat.ValidatedColorEntry : omichat.ColorModal
local ColorEntry = ColorModal:derive('ValidatedColorEntry')


---Clears the text entry box.
function ColorEntry:clear()
    self.entry:setText('')
    self:onTextChange(self.entry)
end

---Override to limit the UI to only the input field.
function ColorEntry:initialise()
    ColorModal.initialise(self)
    self.yes:setVisible(false)
    self.no:setVisible(false)
    self.entry:setX(0)
    self.entry:setWidth(self.width - self.colorBtn.width - 5)
    self.colorBtn:setX(self.entry:getWidth() + 5)

    if not self.entry.borderColorEnabled then
        self.entry.borderColorEnabled = {
            r = self.borderColor.r,
            g = self.borderColor.g,
            b = self.borderColor.b,
            a = self.borderColor.a,
        }
    end
end

---Callback for text entry change.
---@param entry ISTextEntryBox
function ColorEntry:onTextChange(entry)
    ColorModal.onTextChange(self, entry)

    if self.onchange then
        self.onchange(self.target, self, self.param1, self.param2, self.param3, self.param4)
    end
end

---Override to validate entry content before rendering.
function ColorEntry:prerender()
    self:updateBorder()
end

---Handler for when a color option in the color picker is clicked.
---@param color omichat.ColorTable
function ColorEntry:selectColor(color)
    ColorModal.selectColor(self, color)

    if self.onchange then
        self.onchange(self.target, self, self.param1, self.param2, self.param3, self.param4)
    end
end

---Sets a callback function to be called on color change.
---@param f fun(target: unknown, self: omichat.ValidatedColorEntry, ...)
function ColorEntry:setOnChange(f)
    self.onchange = f
end

---Sets the tooltip of the entry box.
---@param text string?
function ColorEntry:setValidateTooltipText(text)
    ColorModal.setValidateTooltipText(self, text)
    self.entry.tooltip = text
end

---Updates the border color based on the current validation state.
function ColorEntry:updateBorder()
    local entry = self.entry
    if self:validate(entry:getInternalText()) then
        entry.tooltip = self.tooltipValid
        entry.borderColor = entry.borderColorEnabled
    else
        entry.tooltip = self.validateTooltipText
        entry.borderColor = entry.borderColorDisabled or { r = 0.7, g = 0.1, b = 0.1, a = 0.7 }
    end
end

---Tests the validation function.
---@param text string?
---@return boolean valid
function ColorEntry:validate(text)
    if not text then
        text = self.entry:getInternalText()
    end

    if not self.validateFunc then
        return true
    elseif self.validateFunc == ColorModal.validate then
        return ColorModal.validate(self, text)
    end

    if not ColorModal.validate(self, text) then
        return false
    end

    local args = self.validateArgs
    return not not self.validateFunc(self.validateTarget, text, args[1], args[2])
end

---Creates a new color entry box.
---@param x number
---@param y number
---@param width number
---@param height number
---@param defaultColor omichat.ColorTable?
---@param target table?
---@param onclick function?
---@param player integer?
---@param ... unknown
---@return omichat.ValidatedColorEntry
function ColorEntry:new(x, y, width, height, defaultColor, target, onclick, player, ...)
    local o = ColorModal.new(self, x, y, width, height, '', defaultColor, target, onclick, player, ...)

    ---@cast o omichat.ValidatedColorEntry
    return o
end


return ColorEntry
