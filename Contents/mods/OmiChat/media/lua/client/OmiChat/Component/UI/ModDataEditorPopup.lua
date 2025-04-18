---UI element for the mod data editor.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local UI = utils.ui

local ISPanelJoypad = ISPanelJoypad
local textManager = getTextManager()


---@class omichat.ModDataEditor : ISPanelJoypad
local ModDataEditor = ISPanelJoypad:derive('ModDataEditor')


local PAD_Y = 10
local FIELD_X = 20
local FIELD_FONT = UIFont.Medium
local FONT_H_MEDIUM = textManager:getFontHeight(UIFont.Medium)
local BTN_H = math.max(25, textManager:getFontHeight(UIFont.Small) + 6)
local LABEL_H = FONT_H_MEDIUM + 4


---Called when the add language button is clicked.
---Adds the current input language to the language list.
function ModDataEditor:addLanguage()
    local lang = utils.trim(self.languageEntry:getInternalText())
    if not self:isLanguageValidForAdd(lang) then
        return
    end

    local list = self.item.languages
    if not list then
        list = {}
        self.item.languages = list
    end

    list[#list + 1] = lang
    self:updateLanguageList()
end

---Checks all fields for validity.
---@return boolean
function ModDataEditor:canSubmit()
    local fields = {
        self.usernameEntry,
        self.nicknameEntry,
        self.statusEntry,
        self.iconEntry,
        self.currentLangEntry,
        self.languageSlotsEntry,
    }

    for _, field in pairs(fields) do
        if not field:validate() then
            return false
        end
    end

    return true
end

---Adds the children of the mod data editor.
function ModDataEditor:createChildren()
    local btnW = 100
    local btnY = self.height - 10 - BTN_H

    local titleH = FONT_H_MEDIUM
    local titleText = getText('UI_OmiChat_ModDataManager_EditorTitle')
    local titleWidth = textManager:MeasureStringX(UIFont.Medium, titleText)

    UI.label {
        parent = self,
        x = self.width / 2 - titleWidth / 2,
        y = 10,
        h = titleH,
        text = titleText,
        font = UIFont.Medium,
    }

    local closeX = self.width - btnW - FIELD_X
    self.closeBtn = UI.button {
        parent = self,
        internal = 'CLOSE',
        x = closeX,
        y = btnY,
        w = btnW,
        h = BTN_H,
        text = getText('IGUI_CraftUI_Close'),
        borderColor = utils.copy(self.buttonBorderColor),
        target = self,
        onClick = self.destroy,
        anchorTop = false,
        anchorBottom = true,
    }

    local saveX = self.closeBtn.x - btnW - FIELD_X * 0.5
    self.saveBtn = UI.button {
        parent = self,
        internal = 'SAVE',
        x = saveX,
        y = btnY,
        w = btnW,
        h = BTN_H,
        text = getText('IGUI_RadioSave'),
        borderColor = utils.copy(self.buttonBorderColor),
        target = self,
        onClick = self.onSave,
        anchorTop = false,
        anchorBottom = true,
    }

    -- fields
    local y
    local item = self.item
    local text = getText('UI_OmiChat_ModDataManager_Column_username')
    y, self.usernameEntry = self:_createField('text', titleH + 20, text, item.username)

    if self.isAdd then
        self.usernameEntry:setRequireValue(true)
    else
        self.usernameEntry:setEditable(false)
    end

    text = getText('UI_OmiChat_ModDataManager_Column_nickname')
    y, self.nicknameEntry = self:_createField('text', y + PAD_Y, text, item.nickname)
    self.nicknameEntry:setValidateFunction(self.nicknameEntry, API.format.validateName)

    text = getText('UI_OmiChat_ModDataManager_Column_status')
    y, self.statusEntry = self:_createField('text', y + PAD_Y, text, item.status)
    self.statusEntry:setValidateFunction(self.statusEntry, API.format.validateStatus)

    text = getText('UI_OmiChat_ModDataManager_Column_icon')
    y, self.iconEntry = self:_createField('text', y + PAD_Y, text, item.icon)
    self.iconEntry:setValidateFunction(self, self.validateIconText, self.iconEntry)

    text = getText('UI_OmiChat_ModDataManager_Column_currentLanguage')
    y, self.currentLangEntry = self:_createField('text', y + PAD_Y, text, item.currentLanguage)
    self.currentLangEntry:setValidateFunction(self, self.validateLanguageText, self.currentLangEntry, true)

    text = getText('UI_OmiChat_ModDataManager_Column_languageSlots')
    y, self.languageSlotsEntry = self:_createField('number', y + PAD_Y, text, item.languageSlots, 0,
        config.MAX_LANGUAGE_SLOTS)

    text = getText('UI_OmiChat_ModDataManager_Column_languages')
    y, self.languageListbox = self:_createField('list', y + PAD_Y, text, item.languages)
    self.languageListbox:setOnMouseDownFunction(self, self.onLanguageListboxSelect)

    -- language input field
    self.languageEntry = UI.textEntry {
        parent = self,
        x = FIELD_X,
        y = y + PAD_Y,
        w = saveX - FIELD_X * 1.5,
        h = LABEL_H,
        font = FIELD_FONT,
    }

    self.langSuggestBox = UI.suggestBox {
        entry = self.languageEntry,
        suggestOnEnter = true,
        openUpwards = true,
        refocusOverScrollbar = true,
        target = self,
        populate = self.populateLanguageSuggest,
    }

    self.addLangBtn = UI.button {
        parent = self,
        internal = 'ADD LANGUAGE',
        x = saveX,
        y = self.languageEntry.y,
        w = btnW,
        h = BTN_H,
        text = getText('UI_OmiChat_ProfileManager_AddButton'),
        borderColor = utils.copy(self.buttonBorderColor),
        target = self,
        onClick = self.addLanguage,
    }

    self.deleteLangBtn = UI.button {
        parent = self,
        internal = 'DELETE LANGUAGE',
        x = closeX,
        y = self.languageEntry.y,
        w = btnW,
        h = BTN_H,
        text = getText('IGUI_DbViewer_Delete'),
        borderColor = utils.copy(self.buttonBorderColor),
        target = self,
        onClick = self.removeLanguage,
    }

    y = self.languageEntry:getBottom() + PAD_Y + BTN_H + 10
    self:setHeight(math.max(self:getHeight(), y))
    self:update()
end

---Removes the mod data editor and its children from the UI.
function ModDataEditor:destroy()
    if self.langSuggestBox then
        self.langSuggestBox:removeFromUIManager()
    end

    self:removeFromUIManager()
end

---Gets the computed value of an entry.
---@param entry omi.ui.TextEntry
---@return string?
function ModDataEditor:getEntryValue(entry)
    local value = utils.trim(entry:getInternalText())
    if #value == 0 then
        return
    end

    return value
end

---Checks whether the input language list contains the given language.
---@param language string
---@return boolean
function ModDataEditor:hasLanguage(language)
    local langs = self.item.languages
    if not langs then
        return false
    end

    for i = 1, #langs do
        if langs[i] == language then
            return true
        end
    end

    return false
end

---Checks whether the given language can be added to the language list.
---@param language string
---@return boolean valid
---@return string? error
function ModDataEditor:isLanguageValidForAdd(language)
    if #language == 0 then
        return false
    end

    if self.item.languages and #self.item.languages >= config.MAX_LANGUAGE_SLOTS then
        return false, getText('UI_OmiChat_Error_AddLanguageFull', self.item.username)
    end

    local lang = utils.trim(self.languageEntry:getInternalText())
    if not self:validateLanguageText(lang, self.languageEntry, false) then
        local tooltip = self.languageEntry:getValidateTooltipText()
        self.languageEntry:setValidateTooltipText()
        return false, tooltip
    end

    return true
end

---Checks whether the given language can be removed from the language list.
---@param language string
---@return boolean valid
---@return string? error
function ModDataEditor:isLanguageValidForRemove(language)
    if #language == 0 then
        return false
    end

    if not self:hasLanguage(language) then
        if not API.language.exists(language) then
            return false, getText('UI_OmiChat_Error_AddLanguageNotConfigured', language)
        end

        return false, getText('UI_OmiChat_Error_LanguageUnknown', self.item.username, language)
    end

    return true
end

---Called when a language is selected in the listbox.
---@param language string
function ModDataEditor:onLanguageListboxSelect(language)
    self.languageEntry:setText(language)
end

---Called when the save button is clicked.
function ModDataEditor:onSave()
    if not self:canSubmit() then
        self:destroy()
        return
    end

    local item = self.saveItem
    local icon = self:getEntryValue(self.iconEntry)
    local slots = self:getEntryValue(self.languageSlotsEntry)
    if icon and not getTexture(icon) then
        icon = utils.getTextureNameFromIcon(icon)
    end

    local username
    if self.isAdd then
        username = self:getEntryValue(self.usernameEntry)
        if not username then
            return
        end

        item.username = username
    else
        username = item.username
    end

    item.icon = icon
    item.currentLanguage = self:getEntryValue(self.currentLangEntry)
    item.languageSlots = slots and tonumber(slots)
    item.nickname = self:getEntryValue(self.nicknameEntry)
    item.status = self:getEntryValue(self.statusEntry)
    item.languages = self.item.languages

    API.request.setModData(username, item)

    if self.onsave then
        self.onsave(self.target)
    end

    self:destroy()
end

---Populates suggestions for the language auto-suggest box.
---@param suggestBox omi.ui.SuggestBox
---@param text string
function ModDataEditor:populateLanguageSuggest(suggestBox, text)
    ---@type omichat.SearchContext
    local ctx = {
        searchDisplay = true,
        search = text,
        display = utils.getTranslatedLanguageName,
        max = 50,
    }

    local search = API.search.strings(ctx, API.language.getList())
    if #search.results == 1 and API.language.exists(text) then
        suggestBox:setSuggestions({})
        return
    end

    local suggestions = {} ---@type omi.ui.SuggestBox.Suggestion[]
    for i = 1, #search.results do
        local result = search.results[i]
        suggestions[#suggestions + 1] = {
            text = result.display,
            content = result.value,
        }
    end

    suggestBox:setSuggestions(suggestions)
end

---Called when the remove language button is clicked.
---Removes the current input language from the language list.
function ModDataEditor:removeLanguage()
    local lang = utils.trim(self.languageEntry:getInternalText())
    if not self:isLanguageValidForRemove(lang) then
        return
    end

    local list = self.item.languages
    if not list then
        return
    end

    local idx
    for i = 1, #list do
        if list[i] == lang then
            idx = i
            break
        end
    end

    if not idx then
        return
    end

    table.remove(list, idx)
    self:updateLanguageList()
end

---Updates the validation state of the buttons.
function ModDataEditor:update()
    local lang = utils.trim(self.languageEntry:getInternalText())
    if #lang > 0 then
        local addBtnEnable, addTooltip = self:isLanguageValidForAdd(lang)
        self.addLangBtn:setEnable(addBtnEnable)
        self.addLangBtn:setTooltip(addTooltip)

        local deleteBtnEnable, deleteTooltip = self:isLanguageValidForRemove(lang)
        self.deleteLangBtn:setEnable(deleteBtnEnable)
        self.deleteLangBtn:setTooltip(deleteTooltip)
    else
        -- disable, but don't display as invalid
        self.addLangBtn:setEnable(true)
        self.addLangBtn:setTooltip()
        self.deleteLangBtn:setEnable(true)
        self.deleteLangBtn:setTooltip()

        self.addLangBtn.enable = false
        self.deleteLangBtn.enable = false
    end

    self.saveBtn:setEnable(self:canSubmit())
end

---Updates the listbox containing roleplay languages.
function ModDataEditor:updateLanguageList()
    local langs = self.item.languages or {}
    local listbox = self.languageListbox

    local idx = listbox.selected
    local oldCount = #listbox.items
    listbox:clear()

    for i = 1, #langs do
        listbox:addItem(langs[i], langs[i])
    end

    listbox:setHeight(listbox.itemheight * math.max(1, math.min(#langs, 5)))

    local y = listbox:getBottom() + PAD_Y
    self.languageEntry:setY(y)
    self.languageEntry:clear()
    self.addLangBtn:setY(y)
    self.deleteLangBtn:setY(y)

    local newCount = #listbox.items
    if newCount > 0 then
        if newCount < oldCount then
            listbox.selected = math.min(newCount, math.max(1, idx - 1))
        else
            listbox.selected = newCount
        end
    end

    y = self.languageEntry:getBottom() + PAD_Y + BTN_H + 10
    self:setHeight(math.max(self:getHeight(), y))
end

---Text entry validator for icons.
---@param text string
---@param entry omi.ui.TextEntry
---@return boolean
function ModDataEditor:validateIconText(text, entry)
    if #text == 0 then
        return true
    end

    local texture = getTexture(text)
    if texture then
        return true
    end

    local iconTexture = utils.getTextureNameFromIcon(text)
    if iconTexture then
        return true
    end

    entry:setValidateTooltipText(getText('UI_OmiChat_Info_IconUnknown', text))
    return false
end

---Text entry validator for roleplay language names.
---@param text string
---@param entry omi.ui.TextEntry
---@param expectKnown boolean?
---@return boolean
function ModDataEditor:validateLanguageText(text, entry, expectKnown)
    if #text == 0 then
        return true
    end

    if not API.language.exists(text) then
        entry:setValidateTooltipText(getText('UI_OmiChat_Error_AddLanguageNotConfigured', text))
        return false
    end

    if expectKnown ~= nil and self:hasLanguage(text) ~= expectKnown then
        local username = self.usernameEntry:getInternalText()
        local err = expectKnown and 'UI_OmiChat_Error_LanguageUnknown' or 'UI_OmiChat_Error_AddLanguageKnown'
        entry:setValidateTooltipText(getText(err, username, text))
        return false
    end

    return true
end


---Helper for creating an editor field.
---@param type 'text' | 'list' | 'number'
---@param y number
---@param labelText string
---@param default unknown?
---@param min number?
---@param max number?
---@return number
---@return unknown
---@protected
function ModDataEditor:_createField(type, y, labelText, default, min, max)
    local controlW = self.width - FIELD_X * 2

    local label = UI.label {
        parent = self,
        x = FIELD_X,
        y = y,
        h = LABEL_H,
        text = labelText,
        font = FIELD_FONT,
    }

    y = label.y + label.height

    local entry
    if type == 'list' then
        entry = UI.listBox {
            parent = self,
            x = FIELD_X,
            y = y,
            w = controlW,
            h = LABEL_H,
            font = FIELD_FONT,
            items = default,
            itemPadY = 0,
        }

        entry:setHeight(entry.itemheight * math.max(1, math.min(#default, 5)))
    else
        entry = UI.textEntry {
            parent = self,
            x = FIELD_X,
            y = y,
            w = controlW,
            h = LABEL_H,
            text = default,
            font = FIELD_FONT,
            textColorDisabled = { r = 1, g = 1, b = 1, a = 1 },
            minValue = min,
            maxValue = max,
            onlyNumbers = type == 'number',
        }
    end

    return entry.y + entry.height, entry
end


---Creates a new mod data editor popup.
---@param x number
---@param y number
---@param width number
---@param height number
---@param item omichat.PlayerModData
---@param target unknown?
---@param onsave function?
---@param isAdd boolean?
---@return omichat.ModDataEditor
function ModDataEditor:new(x, y, width, height, item, target, onsave, isAdd)
    local this = ISPanelJoypad.new(self, x, y, width, height)

    local itemCopy = utils.copy(item)
    itemCopy.languages = itemCopy.languages and utils.copy(itemCopy.languages) or nil

    ---@cast this omichat.ModDataEditor
    this.saveItem = item
    this.item = itemCopy
    this.moveWithMouse = true
    this.target = target
    this.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    this.onsave = onsave
    this.isAdd = isAdd or false
    this.backgroundColor.a = 0.9

    return this
end


return ModDataEditor
