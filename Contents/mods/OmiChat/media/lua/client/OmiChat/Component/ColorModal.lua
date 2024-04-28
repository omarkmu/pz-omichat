local utils = require 'OmiChat/util'
local ColorEntry = require 'OmiChat/Component/ValidatedColorEntry'
local floor = math.floor

---Modal for color selection.
---Includes a text field for RGB input and a color picker.
---@class omichat.ColorModal : ISTextBox
---@field currentColor ColorInfo
---@field defaultColor omichat.ColorTable The default color to set on the modal during initialization.
---@field emptyColor omichat.ColorTable The color that will be used if the entry is blank.
---@field entry ISTextEntryBox
---@field minValue integer The minimum RGB value of each color component.
---@field maxValue integer The maximum RGB value of each color component.
---@field requireValue boolean If true, the text entry will not be valid if empty.
---@field font UIFont The font of the entry.
local ColorModal = ISTextBox:derive('ColorModal')


---Removes the color modal and the associated color picker.
function ColorModal:destroy()
    self.colorPicker:setVisible(false)
    self.colorPicker:removeSelf()
    ISTextBox.destroy(self)
end

---Gets a color table for the current text, or `nil` if the color is not valid.
---@return omichat.ColorTable?
function ColorModal:getColorTable()
    local result = utils.tryStringToColor(self.entry:getInternalText(), self.minValue, self.maxValue)
    return result.value
end

---Sets up the color modal.
function ColorModal:initialise()
    ISTextBox.initialise(self)

    if not self.validateFunc then
        self:setValidateFunction(self, ColorModal.validate)
    end

    self.colorBtn.onclick = self.onColorPicker
    self.colorPicker.onMouseDownOutside = ColorModal.onColorPickerMouseDownOutside
    self:enableColorPicker()

    self.entry.onTextChange = utils.bind(self.onTextChange, self)

    self:selectColor({
        r = self.defaultColor.r / 255,
        g = self.defaultColor.g / 255,
        b = self.defaultColor.b / 255,
    })

    if self.minValue ~= 0 or self.maxValue ~= 255 then
        self:updateColorPickerColors()
    end
end

---Handler for when the color picker button is clicked.
---@param button ISButton
function ColorModal:onColorPicker(button)
    self.colorPicker:setInitialColor(self.currentColor)
    ISTextBox.onColorPicker(self, button)
    self.colorPicker.pickedFunc = self.selectColor
end

---Callback for when a mouse click occurs outside of the color picker.
---Hides the provided color picker.
---@param colorPicker ISColorPicker
function ColorModal.onColorPickerMouseDownOutside(colorPicker)
    colorPicker:setVisible(false)
end

---Modifies the color picker to match the input text.
---@param entry ISTextEntryBox
function ColorModal:onTextChange(entry)
    local text = entry:getInternalText()

    local color
    if not self.requireValue and #utils.trim(text) == 0 then
        color = self.emptyColor
    else
        local result = utils.tryStringToColor(text, self.minValue, self.maxValue)
        color = result.value
        if not color then
            return
        end
    end

    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255

    self.currentColor = ColorInfo.new(r, g, b, 1)
    self.colorBtn.backgroundColor = { r = r, g = g, b = b, a = 1 }
end

---Sets the color that is used when the input is empty.
---@param emptyColor omichat.ColorTable
function ColorModal:setEmptyColor(emptyColor)
    self.emptyColor = emptyColor
end

---Sets the maximum value of color components.
---@param val integer A number in the range [0, 255].
function ColorModal:setMaxValue(val)
    self.maxValue = val
end

---Sets the minimum value of color components.
---@param val integer A number in the range [0, 255].
function ColorModal:setMinValue(val)
    self.minValue = val
end

---Handler for when a color option in the color picker is clicked.
---@param color omichat.DecimalColorTable
function ColorModal:selectColor(color)
    color = utils.clampDecimalColor(color, self.minValue / 255, self.maxValue / 255)

    self.currentColor = ColorInfo.new(color.r, color.g, color.b, 1)
    self.colorBtn.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }
    self.colorPicker:setVisible(false)

    self.entry:setText(utils.colorToRGBString({
        r = floor(color.r * 255),
        g = floor(color.g * 255),
        b = floor(color.b * 255),
    }))
end

---Updates the color picker's colors based on the set minimum and maximum values.
function ColorModal:updateColorPickerColors()
    ---@diagnostic disable-next-line: param-type-mismatch
    ColorEntry.updateColorPickerColors(self)
end

---Validates text input.
---@param text string
---@return boolean
function ColorModal:validate(text)
    text = text or ''
    if #utils.trim(text) == 0 and not self.requireValue then
        return true
    end

    local result = utils.tryStringToColor(text, self.minValue, self.maxValue)
    if result.error then
        self:setValidateTooltipText(result.error)
    end

    return result.success
end

---Creates a new color modal.
---@param x number
---@param y number
---@param width number
---@param height number
---@param text string
---@param defaultColor omichat.ColorTable?
---@param target table?
---@param onclick function?
---@param player integer?
---@param ... any
---@return omichat.ColorModal
function ColorModal:new(x, y, width, height, text, defaultColor, target, onclick, player, ...)
    if player then
        if x == 0 then
            x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
        end

        if y == 0 then
            y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2
        end
    end

    local o = ISTextBox:new(x, y, width, height, text, '', target, onclick, player, ...)

    ---@cast o omichat.ColorModal
    o.defaultColor = defaultColor or { r = 255, g = 255, b = 255 }
    o.emptyColor = o.defaultColor
    o.font = UIFont.Medium
    o.minValue = 0
    o.maxValue = 255
    o.requireValue = false

    setmetatable(o, self)
    self.__index = self

    return o
end


return ColorModal
