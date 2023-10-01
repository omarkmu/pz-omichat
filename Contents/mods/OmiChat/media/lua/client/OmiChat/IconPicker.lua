---UI element for choosing an icon.
---@class omichat.IconPicker : ISPanel
---@field includeDefaults boolean
---@field includeUnknownAsMiscellaneous boolean
---@field borderSize integer
---@field buttonSize integer
---@field backgroundColor table
---@field borderColor table
---@field columns integer
---@field scrollMultiplier integer
---@field target table?
---@field onclick function?
---@field categoryFont UIFont
---@field icons table
---@field exclude table
---@field categoryOrder table
---@field protected _rowContents table
local IconPicker = ISPanel:derive('IconPicker')

local icons = require 'OmiChat/IconLists'

local pairs = pairs
local ipairs = ipairs
local getText = getText
local getTextManager = getTextManager
local ISPanel_render = ISPanel.render

local loadedIcons = false
local iconToTextureNameMap = {} ---@type table<string, string>


---Collects valid icons and builds a map of icon names to texture names.
local function loadIcons(picker)
    local known = {}
    for i, t in pairs(icons) do
		-- skip the order table
		if i ~= 1 then
			for _, icon in pairs(t) do
				known[icon] = true
			end
		end
    end

    local dest = HashMap.new()
    Texture.collectAllIcons(HashMap.new(), dest)

	iconToTextureNameMap = transformIntoKahluaTable(dest)
	if picker.includeUnknownAsMiscellaneous then
		local categoryOrder = icons[1]
		for icon in pairs(iconToTextureNameMap) do
			if not known[icon] then
				-- include unknown icons in misc category
				if not icons.miscellaneous then
					icons.miscellaneous = {}
					categoryOrder[#categoryOrder+1] = 'miscellaneous'
				end

				local list = icons.miscellaneous
				list[#list+1] = icon
			end
		end
	end

	-- special case for 'music'
	iconToTextureNameMap.music = 'Icon_music_notes'

	loadedIcons = true
end


---Returns the row and column in the icon picker given an x and y position.
---This only returns grid positions of valid icon positions; an x and y
---outside of the bounds or over a category will return nil.
---@param x number
---@param y number
---@return integer?
---@return integer?
---@return table?
function IconPicker:getGridCoordinates(x, y)
	local absX = x - self:getXScroll()
	local absY = y - self:getYScroll()
	if absY <= self.borderSize or absX <= self.borderSize then
		return
	end

	if x >= self.buttonSize * self.columns + self.borderSize * 2 then
		return
	end

	local row = math.ceil((y - self.borderSize) / self.buttonSize)
	local column = math.ceil((x - self.borderSize) / self.buttonSize)
	local selected = type(self._rowContents[row]) == 'table' and self._rowContents[row][column]

	if not selected then
		return
	end

	return row, column, selected
end

---Returns the row and column in the icon picker that's being hovered over.
---If no icon is being hovered, returns nil.
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

---Builds a table containing information about the current icons.
---@return table
function IconPicker:buildIconList()
	if self.includeDefaults and not loadedIcons then
		loadIcons(self)
	end

	local categoryOrder = {}
	local iconsByCategory = {}
	for _, cat in ipairs(self.categoryOrder) do
		categoryOrder[#categoryOrder+1] = cat
		iconsByCategory[cat] = {
			category = cat,
			list = {},
		}
	end

	if self.includeDefaults then
		for _, cat in ipairs(icons[1]) do
			if not iconsByCategory[cat] then
				categoryOrder[#categoryOrder+1] = cat
				iconsByCategory[cat] = {
					category = cat,
					list = {},
				}
			end

			local info = iconsByCategory[cat]
			for _, icon in ipairs(icons[cat]) do
				local textureName = iconToTextureNameMap[icon]

				if not self.exclude[icon] and textureName and getTexture(textureName) then
					info.list[#info.list + 1] = {
						name = icon,
						textureName = textureName,
					}
				end
			end
		end
	end

	for _, icon in ipairs(self.icons) do
		local cat = icon.category
		local name = icon.name
		local textureName = icon.textureName

		if not iconsByCategory[cat] then
			categoryOrder[#categoryOrder+1] = cat
			iconsByCategory[cat] = {
				category = cat,
				list = {}
			}
		end

		local info = iconsByCategory[cat]
		if not self.exclude[name] and textureName and getTexture(textureName) then
			info.list[#info.list + 1] = {
				name = name,
				textureName = textureName,
			}
		end
	end

	local result = {}

	for _, cat in ipairs(categoryOrder) do
		result[#result+1] = iconsByCategory[cat]
	end

    return result
end

---Updates icon information.
function IconPicker:updateIcons()
	local iconInfo = self:buildIconList()
	local contents = {}

	local row = 0
	for _, info in ipairs(iconInfo) do
		if #info.list > 0 then
			row = row + 1
			contents[row] = 'UI_OmiChat_icon_cat_' .. info.category

			local rowIcons = {}
			for i, icon in ipairs(info.list) do
				if i % self.columns == 1 then
					row = row + 1
					rowIcons = {}
					contents[row] = rowIcons
				end

				rowIcons[#rowIcons+1] = icon
			end
		end
	end

	self._rowContents = contents
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
		self.onclick(self.target, selected, iconToTextureNameMap[selected])
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
    ISPanel_render(self)

	self:setStencilRect(0, 0, self.width, self.height)

	local hoverRow, hoverCol = self:getMouseCoordinates()
	if hoverRow and hoverCol then
		local size = self.buttonSize
		local x = self.borderSize + (hoverCol - 1) * size
		local y = self.borderSize + (hoverRow - 1) * size
		self:drawRect(x, y, size, size, 0.5, 1, 1, 1)
	end

	local maxRow = 0
	for row, value in ipairs(self._rowContents) do
		if type(value) == 'string' then
			local catName = getText(value)
			local textHeight = getTextManager():MeasureStringY(self.categoryFont, catName)
			local centerDelta = (self.buttonSize - textHeight) / 2
			local catY = self.borderSize + (row - 1) * self.buttonSize + centerDelta
			self:drawTextCentre(catName, self.width / 2, catY, 1, 1, 1, 1, self.categoryFont)
		else
			for col, icon in ipairs(value) do
				local size = self.buttonSize
				local x = self.borderSize + (col - 1) * size
				local y = self.borderSize + (row - 1) * size
				self:drawTextureScaledAspect(getTexture(icon.textureName), x, y, size, size, 1)
			end
		end

		maxRow = row
	end

	self:clearStencilRect()
	self:setScrollHeight(self.borderSize * 2 + maxRow * self.buttonSize)
end

---Initializes the icon picker, setting up its icons.
function IconPicker:initialise()
	ISPanel.initialise(self)
	self:updateIcons()
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

    local o = ISPanel:new(x, y, width, height)
	---@cast o omichat.IconPicker

	o.includeDefaults = true
	o.includeUnknownAsMiscellaneous = false
	o.backgroundColor.a = 1
	o.borderColor.a = 0.5
    o.columns = columns
    o.buttonSize = buttonSize
    o.borderSize = borderSize
	o.scrollMultiplier = buttonSize * 2
	o.target = target
	o.onclick = onclick
	o.categoryFont = UIFont.Medium
    o.icons = {}
	o.exclude = {}
	o.categoryOrder = {}
	o._rowContents = {}

	o:addScrollBars()
	o:setWidth(width + o.vscroll.width)
	o.vscroll:setX(width - o.vscroll.width)
	o.vscroll.background = false
	o.vscroll.borderColor.a = 0.5

    setmetatable(o, self)
	self.__index = self

    return o
end


return IconPicker
