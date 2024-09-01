local TextEntry = require 'OmiChat/Component/ValidatedTextEntry'
local utils = require 'OmiChat/util'
local floor = math.floor
local ISColorPicker = utils.getBaseColorPicker(ISColorPicker)

---@class omichat.ValidatedColorEntry : omichat.ValidatedTextEntry
---@field defaultColor omichat.ColorTable The default color to set on the modal during initialization.
---@field emptyColor omichat.ColorTable The color that will be used if the entry is blank.
---@field minValue integer The minimum RGB value of each color component.
---@field maxValue integer The maximum RGB value of each color component.
---@field currentColor ColorInfo
---@field colorBtn ISButton?
---@field colorPicker ISColorPicker?
local ColorEntry = TextEntry:derive('ValidatedColorEntry')

---@class omichat.ValidatedColorEntryArgs : omichat.ValidatedTextEntryArgs
---@field minValue integer?
---@field maxValue integer?
---@field defaultColor omichat.ColorTable?
---@field emptyColor omichat.ColorTable?


---Callback for when a mouse click occurs outside of the color picker.
---Hides the provided color picker.
---@param colorPicker ISColorPicker
local function onColorPickerMouseDownOutside(colorPicker)
    colorPicker:setVisible(false)
end


---Removes the color entry and its components.
function ColorEntry:destroy()
    self.colorPicker:setVisible(false)
    self.colorPicker:removeSelf()

    TextEntry.destroy(self)
end

---Gets a color table for the current text, or `nil` if the color is not valid.
---@return omichat.ColorTable?
function ColorEntry:getColorTable()
    local result = utils.tryStringToColor(self:getInternalText(), self.minValue, self.maxValue)
    return result.value
end

---Returns the color used when the entry is empty.
---@return omichat.ColorTable
function ColorEntry:getEmptyColor()
    return self.emptyColor
end

---Returns the maximum value of color components.
---@return integer
function ColorEntry:getMaxValue()
    return self.maxValue
end

---Returns the minimum value of color components.
---@return integer
function ColorEntry:getMinValue()
    return self.minValue
end

---Initializes the entry.
function ColorEntry:initialise()
    TextEntry.initialise(self)
    local btnPadding = 5 * (self.fontHgt / getTextManager():getFontHeight(UIFont.Medium))

    local btnSize = self.fontHgt + 4
    local entryW = self.width - btnSize - btnPadding
    self.entry:setWidth(entryW)
    self.widthRatio = entryW / self.width

    self.colorBtn = ISButton:new(entryW + btnPadding, 0, btnSize, btnSize, '', self, self.onColorPicker)
    self.colorBtn.anchorLeft = false
    self.colorBtn.anchorRight = true
    self.colorBtn:initialise()
    self.colorBtn.backgroundColor = { r = 1, g = 1, b = 1, a = 1 }
    self:addChild(self.colorBtn)

    self.colorPicker = ISColorPicker:new(0, 0)
    self.colorPicker:initialise()
    self.colorPicker.pickedTarget = self
    self.colorPicker.resetFocusTo = self
    self.colorPicker:setInitialColor(self.currentColor)
    self.colorPicker:addToUIManager()
    self.colorPicker.otherFct = true
    self.colorPicker.parent = self
    self.colorPicker.onMouseDownOutside = onColorPickerMouseDownOutside
    self.colorPicker:setVisible(false)

    if self.minValue ~= 0 or self.maxValue ~= 255 then
        self:updateColorPickerColors()
    end

    self:updateColor()
end

---Called when the color entry text changes.
function ColorEntry:onTextChange()
    self:updateColor()
    TextEntry.onTextChange(self)
end

---Updates the current color of the entry, and updates the text to match.
---@param color omichat.ColorTable Color table with values in [0, 255].
function ColorEntry:selectColor(color)
    self:selectDecimalColor({
        r = color.r / 255,
        g = color.g / 255,
        b = color.b / 255,
    })
end

---Updates the current color of the entry, and updates the text to match.
---@param color omichat.DecimalColorTable Color table with values in [0, 1].
function ColorEntry:selectDecimalColor(color)
    color = utils.clampDecimalColor(color, self.minValue / 255, self.maxValue / 255)

    self.currentColor = ColorInfo.new(color.r, color.g, color.b, 1)

    if self.colorBtn then
        self.colorBtn.backgroundColor = { r = color.r, g = color.g, b = color.b, a = 1 }
    end

    if self.colorPicker then
        self.colorPicker:setVisible(false)
    end

    local text = utils.colorToRGBString {
        r = floor(color.r * 255),
        g = floor(color.g * 255),
        b = floor(color.b * 255),
    }

    self:setText(text, true)
end

---Sets the color that is used when the input is empty.
---@param emptyColor omichat.ColorTable
function ColorEntry:setEmptyColor(emptyColor)
    self.emptyColor = emptyColor
    self:updateColor()
end

---Sets the maximum value of color components.
---@param val integer A number in the range [0, 255].
function ColorEntry:setMaxValue(val)
    self.maxValue = val
end

---Sets the minimum value of color components.
---@param val integer A number in the range [0, 255].
function ColorEntry:setMinValue(val)
    self.minValue = val
end

---Sets the current text of the entry.
---@param text string The text to set on the entry.
---@param notifyChanged boolean? Whether this should trigger onTextChange. Defaults to `true`.
function ColorEntry:setText(text, notifyChanged)
    TextEntry.setText(self, text, utils.default(notifyChanged, true))
end

---Handler for when the button to open the color picker is clicked.
---@param button ISButton
---@diagnostic disable-next-line: unused-local
function ColorEntry:onColorPicker(button)
    local colorBtn = self.colorBtn
    if not colorBtn then
        return
    end

    self.colorPicker:setInitialColor(self.currentColor)
    self.colorPicker:setX(colorBtn:getAbsoluteX() + colorBtn:getWidth())
    self.colorPicker:setY(colorBtn:getAbsoluteY())
    self.colorPicker.pickedFunc = self.selectDecimalColor
    self.colorPicker:setVisible(true)
    self.colorPicker:bringToTop()
end

---Tests the validation function.
---@param text string?
---@return boolean valid
function ColorEntry:validate(text)
    if not text then
        text = self:getInternalText()
    end

    if not TextEntry.validate(self, text) then
        return false
    end

    if #utils.trim(text) == 0 then
        return true
    end

    local result = utils.tryStringToColor(text, self.minValue, self.maxValue)
    if result.error then
        self:setValidateTooltipText(result.error)
    end

    return result.success
end

---Updates the color picker button to match the color specified in the input.
function ColorEntry:updateColor()
    local text = self:getInternalText()

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
    if self.colorBtn then
        self.colorBtn.backgroundColor = { r = r, g = g, b = b, a = 1 }
    end
end

---Updates the color picker's colors based on the set minimum and maximum values.
function ColorEntry:updateColorPickerColors()
    local columns = 18
    local rows = 12

    local colors = {}
    local minVal = self.minValue
    local maxVal = self.maxValue
    local delta = math.max(1, floor((maxVal - minVal) / 5))

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
                    b = newColor:getBlueFloat(),
                }

                i = i + 1
            end
        end
    end

    --#endregion

    if self.colorPicker then
        self.colorPicker:setColors(colors, columns, rows)
    end
end

---Creates a new color entry box.
---@param args omichat.ValidatedColorEntryArgs
---@return omichat.ValidatedColorEntry
function ColorEntry:new(args)
    local this = TextEntry.new(self, args) ---@cast this omichat.ValidatedColorEntry

    local defaultColor = args.defaultColor
    if not args.text and defaultColor then
        this.text = utils.colorToRGBString(args.defaultColor)
    end

    if defaultColor then
        this.currentColor = ColorInfo.new(defaultColor.r, defaultColor.g, defaultColor.b, 1)
    else
        this.currentColor = ColorInfo.new(1, 1, 1, 1)
    end

    this.defaultColor = defaultColor or { r = 255, g = 255, b = 255 }
    this.emptyColor = args.emptyColor or this.defaultColor

    this.minValue = this.minValue or 0
    this.maxValue = this.maxValue or 255

    return this
end


return ColorEntry
