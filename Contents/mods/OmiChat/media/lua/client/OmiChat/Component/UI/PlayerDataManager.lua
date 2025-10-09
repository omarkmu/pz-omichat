---UI element for the player data manager admin utility.

local Editor = require 'OmiChat/Component/UI/PlayerDataEditor'
local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client
local utils = API.utils
local UI = utils.ui

local max = math.max
local min = math.min
local isAdmin = isAdmin
local textManager = getTextManager()

local COLUMNS = {
    'username',
    'nickname',
    'status',
    'icon',
    'currentLanguage',
    'languageSlots',
    'languages',
}


---@class omichat.PlayerDataManager : omi.ui.Panel
local PlayerDataManager = UI.Panel:derive('PlayerDataManager')


---Creates the children of the mod data manager.
function PlayerDataManager:createChildren()
    self.headerH = textManager:getFontHeight(self.headerFont)

    local titleH = textManager:getFontHeight(UIFont.Medium) + 10
    local btnW = 100
    local padBottom = 10
    local padBtn = 5
    local btnH = max(25, textManager:getFontHeight(UIFont.Small) + 6)
    local btnY = self.height - btnH - padBottom

    local listboxY = self.headerH + titleH + 5
    self.listbox = UI.listBox {
        parent = self,
        x = 10,
        y = listboxY,
        w = self.width - 20,
        h = self.height - listboxY - btnH - padBottom * 2,
        selected = 0,
        target = self,
        draw = self.drawItem,
        drawBorder = true,
        joypadParent = self,
    }

    self.modifyBtn = UI.button {
        parent = self,
        enable = false,
        x = padBtn * 2,
        y = btnY,
        w = btnW,
        h = btnH,
        internal = 'MODIFY',
        text = getText('IGUI_DbViewer_Modify'),
        target = self,
        onClick = self.onModifyClick,
        borderColor = self.buttonBorderColor,
    }

    self.addBtn = UI.button {
        parent = self,
        x = self.modifyBtn:getRight() + padBtn,
        y = btnY,
        w = btnW,
        h = btnH,
        internal = 'ADD',
        text = getText('UI_OmiChat_ProfileManager_AddButton'),
        target = self,
        onClick = self.onAddClick,
        borderColor = self.buttonBorderColor,
    }

    self.deleteBtn = UI.button {
        parent = self,
        enable = false,
        x = self.addBtn:getRight() + padBtn,
        y = btnY,
        w = btnW,
        h = btnH,
        internal = 'DELETE',
        text = getText('IGUI_DbViewer_Delete'),
        target = self,
        onClick = self.onDeleteClick,
        borderColor = self.buttonBorderColor,
    }

    self.closeBtn = UI.button {
        parent = self,
        x = self.width - btnW - padBtn * 2,
        y = btnY,
        w = btnW,
        h = btnH,
        text = getText('IGUI_CraftUI_Close'),
        target = self,
        onClick = self.destroy,
        borderColor = self.buttonBorderColor,
    }

    self.refreshBtn = UI.button {
        parent = self,
        x = self.closeBtn:getX() - btnW - padBtn,
        y = btnY,
        w = btnW,
        h = btnH,
        text = getText('IGUI_DbViewer_Refresh'),
        target = self,
        onClick = self.refresh,
        borderColor = self.buttonBorderColor,
    }

    self:refresh()
end

---Renders an item in the data list.
---@param listbox omi.ui.ListBox
---@param y number
---@param item table
---@param alt boolean
---@return number
function PlayerDataManager:drawItem(y, item, alt, listbox)
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
---@return omichat.PlayerModData? item
---@return integer? index
function PlayerDataManager:getSelectedItem()
    local listbox = self.listbox
    local item = listbox:getSelectedItem()
    if not item then
        return
    end

    return item.data, listbox.selected
end

---Called when the add button is clicked.
function PlayerDataManager:onAddClick()
    self:openEditPanel({ username = '' }, true)
end

---Performs deletion of a mod data row.
---Called after clicking yes on the deletion confirmation prompt.
---@param button omi.ui.Args.Dialog.Click
---@param item omichat.PlayerModData
---@param idx integer
function PlayerDataManager:onConfirmDelete(button, item, idx)
    if button.internal ~= 'YES' then
        return
    end

    local username = item.username
    API.request.clearData(username)

    self.listbox:removeItemByIndex(idx)
    if #self.listbox.items > 0 then
        self.listbox.selected = max(1, idx - 1)
    end

    self:refresh()
end

---Called when the delete button is clicked.
---Prompts for confirmation.
function PlayerDataManager:onDeleteClick()
    local item, idx = self:getSelectedItem()
    if not item then
        return
    end

    if self.activeDialog then
        self.activeDialog:destroy()
    end

    self.activeDialog = UI.yesNoDialog {
        text = getText('IGUI_DbViewer_DeleteConfirm'),
        target = self,
        onClick = self.onConfirmDelete,
        onClickArgs = { item, idx },
    }

    self:removeOnDestroy(self.activeDialog)
end

---Called when the modify button is clicked.
function PlayerDataManager:onModifyClick()
    local item = self:getSelectedItem()
    self:openEditPanel(item)
end

---Called when a new mod data list is returned from the server.
---@param list omichat.PlayerModData[]
function PlayerDataManager:onUpdateList(list)
    if #self.elements == 0 and #list > 0 then
        self:setVisible(true)
    end

    local selected = self.listbox.selected or 1
    self.refreshBtn.enable = true
    self.elements = list

    self.headerH = textManager:getFontHeight(self.headerFont)
    self.listbox.font = self.listFont
    self.titleW = textManager:MeasureStringX(UIFont.Medium, self.titleText)
    self.listbox.itemheight = textManager:getFontHeight(self.listFont) + 4
    self.listbox:clear()

    local sizes = utils.copy(self.columnSizes)
    local emptyText = getText('UI_OmiChat_PlayerDataManager_NoData')
    for i = 1, #list do
        local el = list[i]
        local display = {}
        local empty = {}
        for j = 1, #COLUMNS do
            local colName = COLUMNS[j]
            local colValue = el[colName]

            local colType = type(colValue)
            if colType == 'table' then
                colType = 'string'
                colValue = table.concat(colValue, ', ')
            end

            if colType == 'string' and colValue ~= '' then
                display[colName] = colValue
            elseif colValue == nil or colValue == '' then
                empty[colName] = true
                display[colName] = emptyText
            else
                display[colName] = tostring(colValue)
            end

            local elSize = textManager:MeasureStringX(self.listFont, display[colName]) + 20
            sizes[colName] = max(min(elSize, 300), sizes[colName] or 0)
        end

        self.listbox:addItem(el.username, {
            data = el,
            display = display,
            empty = empty,
        })
    end

    self.listbox.selected = utils.clamp(selected, 1, #self.listbox.items)
    self.columnWidth = sizes
end

---Opens the edit panel with the given item.
---@param item omichat.PlayerModData? The item to edit.
---@param isAdd boolean? Whether this should be treated as an add rather than an edit.
function PlayerDataManager:openEditPanel(item, isAdd)
    if not item then
        return
    end

    if self.activeEditorPanel then
        self.activeEditorPanel:destroy()
    end

    self.activeEditorPanel = Editor:new {
        x = self.x + (self.width - 500) * 0.5,
        y = self.y + (self.height - 600) * 0.5,
        w = 500,
        h = 100,
        item = item,
        target = self,
        onSave = self.refresh,
        isAdd = isAdd,
    }

    self.activeEditorPanel:initialise()
    self.activeEditorPanel:addToUIManager()
    self:removeOnDestroy(self.activeEditorPanel)
end

---Requests a refresh of the list of mod data.
function PlayerDataManager:refresh()
    -- hide the menu before the initial refresh
    if #self.elements == 0 then
        self:setVisible(false)
    end

    self.refreshBtn.enable = false
    API.request.getDataList()
end

---Renders the table for the listbox items.
function PlayerDataManager:render()
    UI.Panel.render(self)

    self:drawText(self.titleText, (self.width - self.titleW) * 0.5, 10, 1, 1, 1, 1, UIFont.Medium)
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
function PlayerDataManager:update()
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
---@param args omichat.Args.PlayerDataManager
---@return omichat.PlayerDataManager
function PlayerDataManager:new(args)
    local this = UI.Panel.new(self, args) --[[@as omichat.PlayerDataManager]]

    this.titleText = getText('UI_OmiChat_PlayerDataManager_Title')
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

    this.columnList = COLUMNS
    this.columnDisplay = {}
    this.columnSizes = {}
    this.columnWidth = {}
    this.elements = {}

    for i = 1, #COLUMNS do
        local colName = COLUMNS[i]
        local colDisplay = getText('UI_OmiChat_PlayerDataManager_Column_' .. colName)

        this.columnDisplay[colName] = colDisplay
        this.columnSizes[colName] = textManager:MeasureStringX(this.headerFont, colDisplay) + 20
    end

    return this
end


API.PlayerDataManager = PlayerDataManager
return PlayerDataManager
