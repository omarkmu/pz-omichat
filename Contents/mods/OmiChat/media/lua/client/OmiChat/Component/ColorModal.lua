local utils = require 'OmiChat/util'
local min = math.min
local max = math.max
local floor = math.floor

---Modal for color selection.
---Includes a text field for RGB input and a color picker.
---@class omichat.ColorModal : ISTextBox
---@field defaultColor omichat.ColorTable
---@field emptyColor omichat.ColorTable
---@field minimumValue integer
---@field maximumValue integer
---@field requireValue boolean
local ColorModal = ISTextBox:derive('ColorModal')


---Clamps the RGB color values in `color` to within the provided range.
---@param color omichat.ColorTable
---@param minVal integer
---@param maxVal integer
---@return omichat.ColorTable
local function clamp(color, minVal, maxVal)
    minVal = minVal / 255
    maxVal = maxVal / 255

    return {
        r = min(max(color.r, minVal), maxVal),
        g = min(max(color.g, minVal), maxVal),
        b = min(max(color.b, minVal), maxVal),
    }
end


---Removes the color modal and the associated color picker.
function ColorModal:destroy()
    self.colorPicker:setVisible(false)
    self.colorPicker:removeSelf()
    ISTextBox.destroy(self)
end

---Gets a color table for the current text, or `nil` if the color is not valid.
---@return omichat.ColorTable?
function ColorModal:getColorTable()
    local result = utils.tryStringToColor(self.entry:getText(), self.minimumValue, self.maximumValue)
    return result.value
end

---Modifies the color picker to match the input text.
---@param entry ISTextEntryBox
function ColorModal:onTextChange(entry)
    local text = entry:getInternalText()

    local color
    if not self.requireValue and #utils.trim(text) == 0 then
        color = self.emptyColor
    else
        local result = utils.tryStringToColor(text, self.minimumValue, self.maximumValue)
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

---Sets up the color modal.
function ColorModal:initialise()
    ISTextBox.initialise(self)

    self:setValidateFunction(self, self.validate)
    self.colorBtn.onclick = self.onColorPicker
    self.colorPicker.onMouseDownOutside = ColorModal.onColorPickerMouseDownOutside
    self:enableColorPicker()

    self.entry.onTextChange = utils.bind(self.onTextChange, self)

    self:selectColor({
        r = self.defaultColor.r / 255,
        g = self.defaultColor.g / 255,
        b = self.defaultColor.b / 255
    })

    if self.minimumValue ~= 0 or self.maximumValue ~= 255 then
        self:updateColorPickerColors()
    end
end

---Sets the color that is used when the input is empty.
---@param emptyColor omichat.ColorTable
function ColorModal:setEmptyColor(emptyColor)
    self.emptyColor = emptyColor
end

---Sets the maximum value of color components.
---@param val integer A number in the range [0, 255].
function ColorModal:setMaxValue(val)
    self.maximumValue = val
end

---Sets the minimum value of color components.
---@param val integer A number in the range [0, 255].
function ColorModal:setMinValue(val)
    self.minimumValue = val
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

---Handler for when a color option in the color picker is clicked.
---@param color omichat.ColorTable
function ColorModal:selectColor(color)
    color = clamp(color, self.minimumValue, self.maximumValue)

    self.currentColor = ColorInfo.new(color.r, color.g, color.b, 1)
    self.colorBtn.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }
    self.colorPicker:setVisible(false)

    self.entry:setText(utils.colorToRGBString({
        r = floor(color.r * 255),
        g = floor(color.g * 255),
        b = floor(color.b * 255),
    }))
end

---Updates the color picker's colors based on the set minimum
---and maximum values.
function ColorModal:updateColorPickerColors()
    local columns = 18
    local rows = 12

    local minVal = self.minimumValue
    local maxVal = self.maximumValue

    local colors = {}
    local delta = floor((maxVal - minVal) / 5)

    --#region modified code from ISColorPicker

    local i = 0
    local newColor = Color.new(1, 1, 1, 1)
    for red = minVal, maxVal, delta do
        for green = minVal, maxVal, delta do
            for blue = minVal, maxVal, delta do
                local col = i % columns
				local row = floor(i / columns)
				if row % 2 == 0 then row = row / 2 else row = floor(row / 2) + 6 end

                ---@diagnostic disable-next-line: redundant-parameter
				newColor:set(red / 255, green / 255, blue / 255, 1.0)
				colors[col + row * columns + 1] = {
                    r = newColor:getRedFloat(),
                    g = newColor:getGreenFloat(),
                    b = newColor:getBlueFloat()
                }

				i = i + 1
            end
        end
    end

    --#endregion

    self.colorPicker:setColors(colors, columns, rows)
end

---Validates text input.
---@param text string
---@return boolean
function ColorModal:validate(text)
    text = text or ''
    if #utils.trim(text) == 0 and not self.requireValue then
        return true
    end

    local result = utils.tryStringToColor(text, self.minimumValue, self.maximumValue)
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
---@param defaultColor omichat.ColorTable
---@param target table?
---@param onclick function
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

    o.defaultColor = defaultColor or {r=255,g=255,b=255}
    o.emptyColor = o.defaultColor
    o.minimumValue = 0
    o.maximumValue = 255
    o.requireValue = false

    setmetatable(o, self)
    self.__index = self

    ---@cast o omichat.ColorModal
    return o
end


return ColorModal
