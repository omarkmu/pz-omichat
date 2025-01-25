---UI element for choosing an icon.

local icons = require 'OmiChat/Definition/IconLists'
local utils = require 'OmiChat/utils'
local pairs = pairs
local getText = getText
local getTextManager = getTextManager
local _render = ISPanel.render


---@class omichat.IconPicker : ISPanel
local IconPicker = ISPanel:derive('IconPicker')


---Builds a table containing information about the current icons.
---@return table
function IconPicker:buildIconList()
    if self.includeDefaults and not self._preparedIcons then
        IconPicker._prepareIcons()
        self._preparedIcons = true
    end

    local categoryOrder = {}
    local iconsByCategory = {}
    for i = 1, #self.categoryOrder do
        local cat = self.categoryOrder[i]
        categoryOrder[#categoryOrder + 1] = cat
        iconsByCategory[cat] = {
            category = cat,
            list = {},
        }
    end

    if self.includeDefaults then
        for i = 1, #icons[1] do
            local cat = icons[1][i]
            if not iconsByCategory[cat] then
                categoryOrder[#categoryOrder + 1] = cat
                iconsByCategory[cat] = {
                    category = cat,
                    list = {},
                }
            end

            local info = iconsByCategory[cat]
            for j = 1, #icons[cat] do
                local icon = icons[cat][j]
                local textureName = utils.getTextureNameFromIcon(icon)
                local texture = textureName and getTexture(textureName)

                if not self.exclude[icon] and textureName and texture then
                    info.list[#info.list + 1] = {
                        name = icon,
                        texture = texture,
                        textureName = textureName,
                    }
                end
            end
        end
    end

    for i = 1, #self.icons do
        local icon = self.icons[i]
        local cat = icon.category or 'Miscellaneous'
        local name = icon.name
        local textureName = icon.textureName

        if not iconsByCategory[cat] then
            categoryOrder[#categoryOrder + 1] = cat
            iconsByCategory[cat] = {
                category = cat,
                list = {},
            }
        end

        local info = iconsByCategory[cat]
        local texture = getTexture(textureName)
        if not self.exclude[name] and textureName and texture then
            info.list[#info.list + 1] = {
                name = name,
                textureName = textureName,
                texture = texture,
            }
        end
    end

    local result = {}

    for i = 1, #categoryOrder do
        local cat = categoryOrder[i]
        if self.includeUnknownAsMiscellaneous or cat ~= 'Miscellaneous' then
            result[#result + 1] = iconsByCategory[cat]
        end
    end

    return result
end

---Initializes the icon picker, setting up its icons.
function IconPicker:initialise()
    ISPanel.initialise(self)
    self:updateIcons()
end

---Returns the row and column in the icon picker given an x and y position.
---This only returns grid positions of valid icon positions; an x and y
---outside of the bounds or over a category will return `nil`.
---@param x number
---@param y number
---@return integer?
---@return integer?
---@return table?
function IconPicker:getGridCoordinates(x, y)
    local absX = x - self:getXScroll()
    local absY = y - self:getYScroll()
    if absY <= self.padSize or absX <= self.padSize then
        return
    end

    if x >= self.buttonSize * self.columns + self.padSize * 2 then
        return
    end

    local row = math.ceil((y - self.padSize) / self.buttonSize)
    local column = math.ceil((x - self.padSize) / self.buttonSize)
    local selected = type(self._rowContents[row]) == 'table' and self._rowContents[row][column]

    if not selected then
        return
    end

    return row, column, selected
end

---Returns the row and column in the icon picker that's being hovered over.
---If no icon is being hovered, returns `nil`.
---@return integer?
---@return integer?
---@return table?
function IconPicker:getMouseCoordinates()
    if not self:isMouseOver() then
        return
    end

    local x = self:getMouseX()
    local y = self:getMouseY()

    return self:getGridCoordinates(x, y)
end

---Fires when a mouse down occurs in the icon picker.
---This handles selecting an icon and calling onclick.
---@param x number
---@param y number
function IconPicker:onMouseDown(x, y)
    local _, _, selected = self:getGridCoordinates(x, y)
    if not selected then
        return
    end

    selected = selected.name
    if self.onclick then
        self.onclick(self.target, selected, utils.getTextureNameFromIcon(selected))
    end
end

---Fires when a mouse wheel occurs in the icon picker.
---@param delta number
---@return boolean
function IconPicker:onMouseWheel(delta)
    self:setYScroll(self:getYScroll() - delta * self.scrollMultiplier)
    return true
end

---Renders the icon picker.
function IconPicker:render()
    _render(self)

    self:setStencilRect(0, 0, self.width, self.height)

    local hoverRow, hoverCol = self:getMouseCoordinates()
    if hoverRow and hoverCol then
        local size = self.buttonSize
        local x = self.padSize + (hoverCol - 1) * size
        local y = self.padSize + (hoverRow - 1) * size
        self:drawRect(x, y, size, size, 0.5, 1, 1, 1)
    end

    local maxRow = 0
    for row = 1, #self._rowContents do
        local value = self._rowContents[row]
        if type(value) == 'string' then
            local textHeight = getTextManager():MeasureStringY(self.categoryFont, value)
            local centerDelta = (self.buttonSize - textHeight) / 2
            local catY = self.padSize + (row - 1) * self.buttonSize + centerDelta
            self:drawTextCentre(value, self.width / 2, catY, 1, 1, 1, 1, self.categoryFont)
        else
            for col = 1, #value do
                local icon = value[col]
                local texture = icon.texture
                if not texture then
                    icon.texture = getTexture(icon.textureName)
                    texture = icon.texture
                end

                local size = self.buttonSize
                local x = self.padSize + (col - 1) * size
                local y = self.padSize + (row - 1) * size
                self:drawTextureScaledAspect(texture, x, y, size, size, 1)
            end
        end

        maxRow = row
    end

    self:clearStencilRect()
    self:setScrollHeight(self.padSize * 2 + maxRow * self.buttonSize)
end

---Updates icon information.
function IconPicker:updateIcons()
    local iconInfo = self:buildIconList()
    local contents = {}

    local row = 0
    for i = 1, #iconInfo do
        local info = iconInfo[i]
        if #info.list > 0 then
            row = row + 1
            contents[row] = getText('UI_OmiChat_IconCat_' .. info.category)

            local rowIcons = {}
            for j = 1, #info.list do
                local icon = info.list[j]
                if j % self.columns == 1 then
                    row = row + 1
                    rowIcons = {}
                    contents[row] = rowIcons
                end

                rowIcons[#rowIcons + 1] = icon
            end
        end
    end

    self._rowContents = contents
end


---Prepares icons for the icon picker.
---@private
function IconPicker._prepareIcons()
    local known = {}
    for i, t in pairs(icons) do
        -- skip the order table
        if i ~= 1 then
            for _, icon in pairs(t) do
                known[icon] = true
            end
        end
    end

    local categoryOrder = icons[1]
    for icon in utils.iterateIcons() do
        if not known[icon] then
            -- include unknown icons in misc category
            if not icons.Miscellaneous then
                icons.Miscellaneous = {}
                categoryOrder[#categoryOrder + 1] = 'Miscellaneous'
            end

            local list = icons.Miscellaneous
            list[#list + 1] = icon
        end
    end
end


---Creates a new icon picker.
---@param x number
---@param y number
---@param target table?
---@param onclick function?
---@return omichat.IconPicker
function IconPicker:new(x, y, target, onclick)
    local columns = 15
    local buttonSize = 24
    local borderSize = 12
    local height = 300
    local width = columns * buttonSize + borderSize * 2

    local this = ISPanel:new(x, y, width, height) ---@cast this omichat.IconPicker

    this.includeDefaults = true
    this.includeUnknownAsMiscellaneous = false
    this.backgroundColor.a = 1
    this.borderColor.a = 0.5
    this.columns = columns
    this.buttonSize = buttonSize
    this.padSize = borderSize
    this.scrollMultiplier = buttonSize * 2
    this.target = target
    this.onclick = onclick
    this.categoryFont = UIFont.Medium
    this.icons = {}
    this.exclude = {}
    this.categoryOrder = {}
    this._rowContents = {}
    this._preparedIcons = false

    this:addScrollBars()
    this:setWidth(width + this.vscroll.width)
    this.vscroll:setX(width - this.vscroll.width)
    this.vscroll.background = false
    this.vscroll.borderColor.a = 0.5

    setmetatable(this, self)
    self.__index = self

    return this
end


return IconPicker
