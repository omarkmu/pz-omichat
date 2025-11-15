---UI element for the player data manager admin utility.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'
local Editor = require 'OmiChat/Component/UI/PlayerDataEditor'

local utils = API.utils
local UI = utils.ui
local getAttr = utils.getAttr
local getText = utils.getText

local max = math.max
local min = math.min
local isAdmin = isAdmin
local textManager = getTextManager()

local FONT_SMALL = UIFont.Small
local FONT_MEDIUM = UIFont.Medium


---@class PlayerDataManager : omi.ui.Panel
---@field listbox omi.ui.ListBox The listbox used to display player data rows.
---@field elements PlayerData[] The player data received from the server.
---@field columnList string[] The list of columns to display.
---@field columnDisplay table<string, string> Associates column names to display strings for column headers.
---@field columnWidth table<string, integer> Associates column names to computed column widths.
---@field columnSizes table<string, integer> Associates column names to the base column sizes.
---@field headerH integer The height of the header font.
---@field titleW integer The width of the title text.
---@field buttonBorderColor omi.ColorTableRGBA<number> The color used for button borders.
---@field listHeaderColor omi.ColorTableRGBA<number> The color used for the list header text.
---@field headerFont UIFont The font used for list header text.
---@field listFont UIFont The font used for list items.
---@field titleText string The text displayed as the manager title.
---@field activeEditorPanel? PlayerDataEditor The active data editor element.
---@field activeDialog? omi.ui.Dialog The active dialog.
---@field addBtn omi.ui.Button The button used to add a new data item.
---@field closeBtn omi.ui.Button The button used to close the panel.
---@field deleteBtn omi.ui.Button The button used to delete a data item.
---@field refreshBtn omi.ui.Button The button used to request a refresh items from the server.
---@field modifyBtn omi.ui.Button The button used to open an editor panel.
local PlayerDataManager = UI.Panel:derive('PlayerDataManager')

---List of player data columns to display.
---@private
PlayerDataManager._COLUMNS = {
    'username',
    'nickname',
    'status',
    'icon',
    'currentLanguage',
    'languageSlots',
    'languages',
}


---Creates the children of the player data manager.
function PlayerDataManager:createChildren()
    self.headerH = textManager:getFontHeight(self.headerFont)

    local titleH = textManager:getFontHeight(FONT_MEDIUM) + 10
    local btnW = 100
    local padBottom = 10
    local padBtn = 5
    local btnH = max(25, textManager:getFontHeight(FONT_SMALL) + 6)
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
        text = getText('.btn-modify'),
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
        text = getText('.btn-add'),
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
        text = getText('.btn-delete'),
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
        text = getText('.btn-close'),
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
        text = getText('.btn-refresh'),
        target = self,
        onClick = self.refresh,
        borderColor = self.buttonBorderColor,
    }

    self:refresh()
end

---Renders an item in the data list.
---@param listbox omi.ui.ListBox The listbox to render an item within.
---@param y number The current Y position.
---@param item omi.ui.ListBoxItem The item to render.
---@param alt boolean Flag for whether the alternating color should be used.
---@return number newY The new Y position.
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
    local borderDelta = listbox.drawBorder and 1 or 0 ---@type number
    local stencilX = borderDelta
    local stencilX2 = listbox.width - borderDelta
    local stencilY = borderDelta
    local stencilY2 = listbox.height - borderDelta
    if listbox:isVScrollBarVisible() then ---@cast listbox.vscroll -?
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
        local data = item.item
        if data then
            local textAlpha = data.empty[colName] and 0.4 or 0.9

            listbox:setStencilRect(x - 10, stencilY, colW - 10, stencilY2 - stencilY)
            listbox:drawText(data.display[colName], x, y + 2, 1, 1, 1, textAlpha, listbox.font)
            listbox:drawRect(x - 10, y - 1, 1, listbox.itemheight, 1, borderColor.r, borderColor.g, borderColor.b)
            listbox:clearStencilRect()
        end

        x = x + colW
    end

    listbox:setStencilRect(stencilX, stencilY, stencilW, stencilH)
    return y + listbox.itemheight
end

---Returns the currently selected item.
---@return PlayerData? item The data associated with the currently selected, or `nil` if there's no selection.
---@return integer? index The currently selected index.
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

---Performs deletion of a player data row.
---Called after clicking yes on the deletion confirmation prompt.
---@param args omi.ui.Args.Dialog.Click Arguments for dialog button click.
---@param item PlayerData The player data item.
---@param idx integer The index of the item to remove.
function PlayerDataManager:onConfirmDelete(args, item, idx)
    if args.internal ~= 'YES' then
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
---Creates a deletion confirmation prompt.
function PlayerDataManager:onDeleteClick()
    local item, idx = self:getSelectedItem()
    if not item then
        return
    end

    if self.activeDialog then
        self.activeDialog:destroy()
    end

    self.activeDialog = UI.yesNoDialog {
        text = getText('.dialog-confirm-delete'),
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

---Called when a new data list is returned from the server.
---@param list PlayerData[] The data received from the server.
function PlayerDataManager:onUpdateList(list)
    if #self.elements == 0 then
        self:setVisible(true)
    end

    local selected = self.listbox.selected or 1
    self.refreshBtn.enable = true
    self.elements = list

    self.headerH = textManager:getFontHeight(self.headerFont)
    self.listbox.font = self.listFont
    self.titleW = textManager:MeasureStringX(FONT_MEDIUM, self.titleText)
    self.listbox.itemheight = textManager:getFontHeight(self.listFont) + 4
    self.listbox:clear()

    local sizes = utils.copy(self.columnSizes)
    local emptyText = getAttr('player-data-manager', 'no-data')
    for i = 1, #list do
        local el = list[i]
        local display = {}
        local empty = {}
        for j = 1, #self.columnList do
            local colName = self.columnList[j]
            local colValue = el[colName]

            local colType = type(colValue)
            if colType == 'table' then ---@cast colValue table
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
---@param item PlayerData? The item to edit.
---@param isAdd boolean? Flag for whether this should be treated as an add rather than an edit.
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

---Requests a refresh of the list of player data.
function PlayerDataManager:refresh()
    -- hide the menu before the initial refresh
    if #self.elements == 0 then
        self:setVisible(false)
    end

    self.refreshBtn.enable = false
    API.request.getPlayerDataList()
end

---Renders the table for the listbox items.
function PlayerDataManager:render()
    UI.Panel.render(self)

    self:drawText(self.titleText, (self.width - self.titleW) * 0.5, 10, 1, 1, 1, 1, FONT_MEDIUM)
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


---Creates a new panel for managing player data.
---@param args omi.ui.Args.Panel Args for creating the element.
---@return PlayerDataManager manager
function PlayerDataManager:new(args)
    local this = UI.Panel.new(self, args) --[[@as PlayerDataManager]]

    this.titleText = getAttr('player-data-manager', 'title')
    this.anchorLeft = true
    this.anchorRight = false
    this.anchorTop = true
    this.anchorBottom = false
    this.moveWithMouse = true
    this.listFont = FONT_SMALL
    this.headerFont = FONT_MEDIUM
    this.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    this.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    this.listHeaderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0.4 }
    this.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }

    this.columnList = PlayerDataManager._COLUMNS
    this.columnDisplay = {}
    this.columnSizes = {}
    this.columnWidth = {}
    this.elements = {}

    for i = 1, #PlayerDataManager._COLUMNS do
        local colName = PlayerDataManager._COLUMNS[i]
        local colDisplay = getAttr('player-data-manager', 'column-' .. colName)

        this.columnDisplay[colName] = colDisplay
        this.columnSizes[colName] = textManager:MeasureStringX(this.headerFont, colDisplay) + 20
    end

    return this
end


return PlayerDataManager
