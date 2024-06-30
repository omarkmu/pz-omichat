local ISPanelJoypad = ISPanelJoypad

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
local utils = OmiChat.utils

---UI element for displaying the admin mod data manager.
---@class omichat.ModDataManager : ISPanelJoypad
---@field listbox ISScrollingListBox
---@field elements omichat.UserModData[]
---@field columnList string[]
---@field columnDisplay table<string, string>
---@field columnWidth table<string, integer>
---@field headerH integer
---@field titleW integer
---@field activeModifyPanel omichat.ModDataEditor?
---@field closeBtn ISButton
---@field refreshBtn ISButton
---@field modifyBtn ISButton
---@field addBtn ISButton
---@field deleteBtn ISButton
local ModDataManager = ISPanelJoypad:derive('ModDataManager')

local textManager = getTextManager()


---Called when the delete button is clicked.
---Prompts for confirmation.
function ModDataManager:confirmDeleteItem()
    local item, idx = self:getSelectedItem()
    if not item then
        return
    end

    utils.createModal(getText('IGUI_DbViewer_DeleteConfirm'), self, self.onConfirmDelete, item, idx)
end

---Creates the children of the mod data manager.
function ModDataManager:createChildren()
    ISPanelJoypad.createChildren(self)
    self.headerH = textManager:getFontHeight(self.headerFont)

    local titleH = textManager:getFontHeight(UIFont.Medium) + 10
    local btnW = 100
    local padBottom = 10
    local padBtn = 5
    local btnH = math.max(25, textManager:getFontHeight(UIFont.Small) + 6)
    local btnY = self.height - btnH - padBottom

    local closeX = self.width - btnW - padBtn * 2
    local closeText = getText('IGUI_CraftUI_Close')
    self.closeBtn = ISButton:new(closeX, btnY, btnW, btnH, closeText, self, self.destroy)
    self.closeBtn.internal = 'CLOSE'
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.borderColor = self.buttonBorderColor
    self:addChild(self.closeBtn)

    local refreshX = closeX - btnW - padBtn
    local refreshText = getText('IGUI_DbViewer_Refresh')
    self.refreshBtn = ISButton:new(refreshX, btnY, btnW, btnH, refreshText, self, self.refresh)
    self.refreshBtn.internal = 'REFRESH'
    self.refreshBtn:initialise()
    self.refreshBtn:instantiate()
    self.refreshBtn.borderColor = self.buttonBorderColor
    self:addChild(self.refreshBtn)

    local modifyText = getText('IGUI_DbViewer_Modify')
    self.modifyBtn = ISButton:new(padBtn * 2, btnY, btnW, btnH, modifyText, self, self.onModifyClick)
    self.modifyBtn.internal = 'MODIFY'
    self.modifyBtn:initialise()
    self.modifyBtn:instantiate()
    self.modifyBtn.enable = false
    self.modifyBtn.borderColor = self.buttonBorderColor
    self:addChild(self.modifyBtn)

    local addText = getText('UI_OmiChat_ProfileManager_AddButton')
    self.addBtn = ISButton:new(self.modifyBtn:getRight() + padBtn, btnY, btnW, btnH, addText, self, self.onAddClick)
    self.addBtn.internal = 'ADD'
    self.addBtn:initialise()
    self.addBtn:instantiate()
    self.addBtn.borderColor = self.buttonBorderColor
    self:addChild(self.addBtn)

    local deleteText = getText('IGUI_DbViewer_Delete')
    local deleteX = self.addBtn:getRight() + padBtn
    self.deleteBtn = ISButton:new(deleteX, btnY, btnW, btnH, deleteText, self, self.confirmDeleteItem)
    self.deleteBtn.internal = 'DELETE'
    self.deleteBtn:initialise()
    self.deleteBtn:instantiate()
    self.deleteBtn.borderColor = self.buttonBorderColor
    self.deleteBtn.enable = false
    self:addChild(self.deleteBtn)

    local listboxY = self.headerH + titleH + 5
    local listboxH = self.height - listboxY - btnH - padBottom * 2
    self.listbox = ISScrollingListBox:new(10, listboxY, self.width - 20, listboxH)
    self.listbox:initialise()
    self.listbox:instantiate()
    self.listbox.selected = 0
    self.listbox.doDrawItem = utils.bind(self.drawItem, self)
    self.listbox.drawBorder = true
    self.listbox.joypadParent = self
    self.listbox.parent = self
    self:addChild(self.listbox)

    self:refresh()
end

---Removes the mod data manager and its children from the UI.
function ModDataManager:destroy()
    if self.activeModifyPanel then
        self.activeModifyPanel:destroy()
    end

    self:removeFromUIManager()
end

---Renders an item in the data list.
---@param listbox ISScrollingListBox
---@param y number
---@param item table
---@param alt boolean
---@return number
function ModDataManager:drawItem(listbox, y, item, alt)
    local borderColor = listbox.borderColor
    local width = listbox:getWidth()

    if listbox.selected == item.index then
        listbox:drawRect(0, y, width, listbox.itemheight, 0.3, 0.7, 0.35, 0.15)
    end

    if alt then
        listbox:drawRect(0, y, width, listbox.itemheight, 0.3, 0.6, 0.5, 0.5)
    end

    listbox:drawRectBorder(0, y, width, listbox.itemheight, 0.9, borderColor.r, borderColor.g, borderColor.b)

    -- determine stencil for listbox stencil redrawing
    local borderDelta = listbox.drawBorder and 1 or 0
    local stencilX = borderDelta
    local stencilX2 = listbox.width - borderDelta
    local stencilY = borderDelta
    local stencilY2 = listbox.height - borderDelta
    if listbox:isVScrollBarVisible() then
        stencilX2 = listbox.vscroll.x + 3
    end

    if listbox.parent and listbox.parent:getScrollChildren() then
        stencilX = listbox.javaObject:clampToParentX(listbox:getAbsoluteX() + stencilX) - listbox:getAbsoluteX()
        stencilX2 = listbox.javaObject:clampToParentX(listbox:getAbsoluteX() + stencilX2) - listbox:getAbsoluteX()
        stencilY = listbox.javaObject:clampToParentY(listbox:getAbsoluteY() + stencilY) - listbox:getAbsoluteY()
        stencilY2 = listbox.javaObject:clampToParentY(listbox:getAbsoluteY() + stencilY2) - listbox:getAbsoluteY()
    end

    local stencilW = stencilX2 - stencilX
    local stencilH = stencilY2 - stencilY
    listbox:clearStencilRect()

    local x = 10
    for i = 1, #self.columnList do
        local colName = self.columnList[i]
        local colW = self.columnWidth[colName] or 200
        local textAlpha = item.item.empty[colName] and 0.4 or 0.9

        listbox:setStencilRect(x - 10, stencilY, colW - 10, stencilY2 - stencilY)
        listbox:drawText(item.item.display[colName], x, y + 2, 1, 1, 1, textAlpha, listbox.font)
        listbox:drawRect(x - 10, y - 1, 1, listbox.itemheight, 1, borderColor.r, borderColor.g, borderColor.b)
        listbox:clearStencilRect()

        x = x + colW
    end

    listbox:setStencilRect(stencilX, stencilY, stencilW, stencilH)
    return y + listbox.itemheight
end

---Returns the currently selected item, or `nil`.
---@return omichat.UserModData? item
---@return integer? index
function ModDataManager:getSelectedItem()
    local listbox = self.listbox
    local idx = listbox.selected
    local item = listbox.items[idx]
    if not item then
        return
    end

    return item.item.data, idx
end

---Called when the add button is clicked.
function ModDataManager:onAddClick()
    self:openEditPanel({ username = '' }, true)
end

---Performs deletion of a mod data row.
---Called after clicking yes on the deletion confirmation prompt.
---@param button ISButton
---@param item omichat.UserModData
---@param idx integer
function ModDataManager:onConfirmDelete(button, item, idx)
    if button.internal ~= 'YES' then
        return
    end

    OmiChat.clearModData(item.username)

    self.listbox:removeItemByIndex(idx)
    if #self.listbox.items > 0 then
        self.listbox.selected = math.max(1, idx - 1)
    end
end

---Called when the modify button is clicked.
function ModDataManager:onModifyClick()
    local item = self:getSelectedItem()
    self:openEditPanel(item)
end

---Opens the edit panel with the given item.
---@param item omichat.UserModData? The item to edit.
---@param isAdd boolean? Whether this should be treated as an add rather than an edit.
function ModDataManager:openEditPanel(item, isAdd)
    if not item then
        return
    end

    if self.activeModifyPanel then
        self.activeModifyPanel:destroy()
    end

    local x = self.x + (self.width - 500) * 0.5
    local y = self.y + (self.height - 600) * 0.5
    self.activeModifyPanel = OmiChat.ModDataEditor:new(x, y, 500, 100, item, self, self.refresh, isAdd)
    self.activeModifyPanel:initialise()
    self.activeModifyPanel:addToUIManager()
end

---Refreshes the mod data information.
function ModDataManager:refresh()
    local elements, fields = OmiChat.getModDataList()
    self.elements = elements
    self.columnList = fields

    self.headerH = textManager:getFontHeight(self.headerFont)
    self.listbox.font = self.listFont
    self.titleW = textManager:MeasureStringX(UIFont.Medium, self.titleText)
    self.listbox.itemheight = textManager:getFontHeight(self.listFont) + 4
    self.listbox:clear()

    self.columnDisplay = {}
    local sizes = {}
    for i = 1, #fields do
        local colName = fields[i]
        local colDisplay = getText('UI_OmiChat_ModDataManager_Column_' .. colName)

        self.columnDisplay[colName] = colDisplay
        sizes[colName] = textManager:MeasureStringX(self.headerFont, colDisplay) + 20
    end

    local emptyText = getText('UI_OmiChat_ModDataManager_NoData')
    for i = 1, #elements do
        local el = elements[i]
        local display = {}
        local empty = {}
        for j = 1, #fields do
            local colName = fields[j]
            local colValue = el[colName]

            local tp = type(colValue)
            if tp == 'table' then
                colValue = table.concat(colValue, ', ')
            end

            if tp == 'string' and colValue ~= '' then
                display[colName] = colValue
            elseif colValue == nil or colValue == '' then
                empty[colName] = true
                display[colName] = emptyText
            else
                display[colName] = tostring(colValue)
            end

            local elSize = textManager:MeasureStringX(self.listFont, display[colName]) + 20
            sizes[colName] = math.max(math.min(elSize, 300), sizes[colName] or 0)
        end

        self.listbox:addItem(el.username, {
            data = el,
            display = display,
            empty = empty,
        })
    end

    self.columnWidth = sizes
end

---Renders the table for the listbox items.
function ModDataManager:render()
    ISPanelJoypad.render(self)

    self:drawText(self.titleText, self.width / 2 - self.titleW / 2, 10, 1, 1, 1, 1, UIFont.Medium)
    local listbox = self.listbox
    local borderC = self.borderColor
    local headerC = self.listHeaderColor

    -- draw header
    local headerY = listbox.y - self.headerH
    self:drawRectBorder(listbox.x, headerY, listbox.width, self.headerH + 1, 1, borderC.r, borderC.g, borderC.b)
    self:drawRect(listbox.x, headerY, listbox.width, self.headerH + 1, headerC.a, headerC.r, headerC.g, headerC.b)

    local x = 0
    for i = 1, #self.columnList do
        local col = self.columnList[i]

        -- column separator
        self:drawRect(listbox.x + x, headerY + 1, 1, self.headerH, 1, borderC.r, borderC.g, borderC.b)

        self:drawText(self.columnDisplay[col], listbox.x + x + 8, headerY + 2, 1, 1, 1, 1, self.headerFont)
        x = x + (self.columnWidth[col] or 200)
    end
end

---Checks for button enable state.
function ModDataManager:update()
    if not isAdmin() then
        self:destroy()
        return
    end

    local listbox = self.listbox
    local item = listbox.items[listbox.selected]
    local enableButtons = item ~= nil
    self.modifyBtn.enable = enableButtons
    self.deleteBtn.enable = enableButtons
end

---Creates a new panel for managing mod data.
---@param x number
---@param y number
---@param width number
---@param height number
---@return omichat.ModDataManager
function ModDataManager:new(x, y, width, height)
    local this = ISPanelJoypad.new(self, x, y, width, height)

    ---@cast this omichat.ModDataManager
    this.titleText = getText('UI_OmiChat_ModDataManager_Title')
    this.anchorLeft = true
    this.anchorRight = false
    this.anchorTop = true
    this.anchorBottom = false
    this.moveWithMouse = true
    this.listFont = UIFont.Small
    this.headerFont = UIFont.Medium
    this.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    this.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    this.listHeaderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.4 }
    this.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }

    return this
end


OmiChat.ModDataManager = ModDataManager
return ModDataManager
