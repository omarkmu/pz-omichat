---UI element for offerring text suggestions.
---@class omichat.SuggesterBox : ISScrollingListBox
---@field maximumVisibleItems integer The number of items to show without scrolling.
local SuggesterBox = ISScrollingListBox:derive('SuggesterBox')


---Gets the currently selected item.
---@return unknown?
function SuggesterBox:getSelectedItem()
    local selected = self.items[self.selected]
    if not selected then
        return
    end

    return selected.item
end

---Selects the next item in the list.
function SuggesterBox:selectNext()
    local selected = self.selected + 1
    if selected < 1 or selected > #self.items then
        selected = 1
    end

    self.selected = selected
    self:ensureVisible(selected)
end

---Selects the previous item in the list.
function SuggesterBox:selectPrevious()
    local selected = self.selected - 1
    if selected < 1 or selected > #self.items then
        selected = #self.items
    end

    self.selected = selected
    self:ensureVisible(selected)
end

---Populates the list with suggestions.
---@param suggestions omichat.Suggestion[]
function SuggesterBox:setSuggestions(suggestions)
    self:clear()
    self:setYScroll(0)
    if #suggestions == 0 then
        self:setVisible(false)
        return
    end

    for i = 1, #suggestions do
        local suggestion = suggestions[i]
        self:addItem(suggestion.display, suggestion)
    end

    self:setHeight(self.itemheight * math.min(#suggestions, self.maximumVisibleItems))
end

---Creates a suggester box.
---@param x number
---@param y number
---@param width number
---@param height number
---@return omichat.SuggesterBox
function SuggesterBox:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)

    ---@cast o omichat.SuggesterBox
    setmetatable(o, self)
    self.__index = self

    o.maximumVisibleItems = 5
    o:setFont(UIFont.Medium, 7)

    return o
end


return SuggesterBox
