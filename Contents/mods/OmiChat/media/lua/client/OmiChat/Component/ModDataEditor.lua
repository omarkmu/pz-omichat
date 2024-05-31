local ISPanelJoypad = ISPanelJoypad
local Keyboard = Keyboard

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
local utils = OmiChat.utils
local config = OmiChat.config
local TextEntry = OmiChat.ValidatedTextEntry
local ColorEntry = OmiChat.ValidatedColorEntry
local SuggesterBox = OmiChat.SuggesterBox

---UI element for displaying the mod data editor for the mod data manager.
---@class omichat.ModDataEditor : ISPanelJoypad
---@field item omichat.UserModData
---@field saveItem omichat.UserModData
---@field nicknameEntry omichat.ValidatedTextEntry
---@field usernameEntry omichat.ValidatedTextEntry
---@field nameColorEntry omichat.ValidatedColorEntry
---@field iconEntry omichat.ValidatedTextEntry
---@field currentLangEntry omichat.ValidatedTextEntry
---@field languageEntry omichat.ValidatedTextEntry
---@field languageSlotsEntry omichat.ValidatedTextEntry
---@field languageListbox ISScrollingListBox
---@field langSuggester omichat.SuggesterBox
---@field addLangBtn ISButton
---@field deleteLangBtn ISButton
---@field saveBtn ISButton
---@field closeBtn ISButton
---@field isAdd boolean
---@field onsave function?
---@field target unknown
local ModDataEditor = ISPanelJoypad:derive('ModDataEditor')

local textManager = getTextManager()
local FONT_H_MEDIUM = textManager:getFontHeight(UIFont.Medium)
local LABEL_H = FONT_H_MEDIUM + 4
local FIELD_FONT = UIFont.Medium
local FIELD_X = 20
local PAD_Y = 10
local BTN_H = math.max(25, textManager:getFontHeight(UIFont.Small) + 6)


---Helper for creating an editor field.
---@param self omichat.ModDataEditor
---@param cls unknown
---@param y number
---@param labelText string
---@param default unknown
---@return number
---@return unknown
local function createField(self, cls, y, labelText, default)
    local controlW = self.width - FIELD_X * 2

    local label = ISLabel:new(FIELD_X, y, LABEL_H, labelText, 1, 1, 1, 1, FIELD_FONT, true)
    self:addChild(label)

    y = label.y + label.height
    local entry
    if cls == TextEntry then
        entry = TextEntry:new {
            x = FIELD_X,
            y = y,
            w = controlW,
            h = LABEL_H,
            text = default,
            font = FIELD_FONT,
        }
    elseif cls == ColorEntry then
        entry = ColorEntry:new {
            x = FIELD_X,
            y = y,
            w = controlW,
            h = LABEL_H,
            defaultColor = default,
        }
    else
        default = default or {}
        entry = ISScrollingListBox:new(FIELD_X, y, controlW, LABEL_H)
        entry:setFont(FIELD_FONT)
        entry:setHeight(entry.itemheight * math.max(1, math.min(#default, 5)))
        entry:setWidth(controlW)
        for i = 1, #default do
            entry:addItem(default[i], default[i])
        end
    end

    entry:initialise()
    self:addChild(entry)

    return entry.y + entry.height, entry
end


---Called when the add language button is clicked.
---Adds the current input language to the language list.
function ModDataEditor:addLanguage()
    local language = utils.trim(self.languageEntry:getInternalText())
    if not self:isLanguageValidForAdd(language) then
        return
    end

    local list = self.item.languages
    if not list then
        list = {}
        self.item.languages = list
    end

    list[#list + 1] = language
    self:updateLanguageList()
end

---Checks all fields for validity.
---@return boolean
function ModDataEditor:canSubmit()
    local fields = {
        self.usernameEntry,
        self.nicknameEntry,
        self.nameColorEntry,
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
    local titleX = self.width / 2 - titleWidth / 2
    local title = ISLabel:new(titleX, 10, titleH, titleText, 1, 1, 1, 1, UIFont.Medium, true)
    title:initialise()
    title:instantiate()
    self:addChild(title)

    local closeX = self.width - btnW - FIELD_X
    local closeText = getText('IGUI_CraftUI_Close')
    self.closeBtn = ISButton:new(closeX, btnY, btnW, BTN_H, closeText, self, self.destroy)
    self.closeBtn.anchorTop = false
    self.closeBtn.anchorBottom = true
    self.closeBtn.internal = 'CLOSE'
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self.closeBtn.borderColor = utils.copy(self.buttonBorderColor)
    self:addChild(self.closeBtn)

    local saveX = self.closeBtn.x - btnW - FIELD_X * 0.5
    local saveText = getText('IGUI_RadioSave')
    self.saveBtn = ISButton:new(saveX, btnY, btnW, BTN_H, saveText, self, self.onSave)
    self.saveBtn.anchorTop = false
    self.saveBtn.anchorBottom = true
    self.saveBtn.internal = 'SAVE'
    self.saveBtn:initialise()
    self.saveBtn:instantiate()
    self.saveBtn.borderColor = utils.copy(self.buttonBorderColor)
    self:addChild(self.saveBtn)

    -- fields
    local y
    local item = self.item
    local text = getText('UI_OmiChat_ModDataManager_Column_username')
    y, self.usernameEntry = createField(self, TextEntry, titleH + 20, text, item.username)

    if self.isAdd then
        self.usernameEntry:setRequireValue(true)
    else
        self.usernameEntry:setEditable(false)
    end

    text = getText('UI_OmiChat_ModDataManager_Column_nickname')
    y, self.nicknameEntry = createField(self, TextEntry, y + PAD_Y, text, item.nickname)
    self.nicknameEntry:setValidateFunction(self.nicknameEntry, OmiChat.validateNicknameText)

    text = getText('UI_OmiChat_ModDataManager_Column_nameColor')
    y, self.nameColorEntry = createField(self, ColorEntry, y + PAD_Y, text, utils.stringToColor(item.nameColor))

    text = getText('UI_OmiChat_ModDataManager_Column_icon')
    y, self.iconEntry = createField(self, TextEntry, y + PAD_Y, text, item.icon)
    self.iconEntry:setValidateFunction(self, self.validateIconText, self.iconEntry)

    text = getText('UI_OmiChat_ModDataManager_Column_currentLanguage')
    y, self.currentLangEntry = createField(self, TextEntry, y + PAD_Y, text, item.currentLanguage)
    self.currentLangEntry:setValidateFunction(self, self.validateLanguageText, self.currentLangEntry, true)

    text = getText('UI_OmiChat_ModDataManager_Column_languageSlots')
    y, self.languageSlotsEntry = createField(self, TextEntry, y + PAD_Y, text, item.languageSlots)
    self.languageSlotsEntry:setOnlyNumbers(true)
    self.languageSlotsEntry:setMinValue(0)
    self.languageSlotsEntry:setMaxValue(config:maxLanguageSlots())

    text = getText('UI_OmiChat_ModDataManager_Column_languages')
    y, self.languageListbox = createField(self, ISScrollingListBox, y + PAD_Y, text, item.languages)
    self.languageListbox:setOnMouseDownFunction(self, self.onLanguageListboxSelect)

    -- language input field
    self.languageEntry = TextEntry:new {
        x = FIELD_X,
        y = y + PAD_Y,
        w = self.width - FIELD_X * 2,
        h = LABEL_H,
        font = FIELD_FONT,
    }

    self.languageEntry:initialise()
    self.languageEntry:setOnChange(self, self.updateSuggester)
    self.languageEntry:setOnFocusGained(self, self.updateSuggester)
    self.languageEntry:setOnFocusLost(self, self.onLanguageEntryFocusLost)
    self.languageEntry:setOnKey(self, self.handleLangEntryKey)
    self:addChild(self.languageEntry)

    local addText = getText('UI_OmiChat_ProfileManager_AddButton')
    self.addLangBtn = ISButton:new(saveX, self.languageEntry.y, btnW, BTN_H, addText, self, self.addLanguage)
    self.addLangBtn.internal = 'ADD LANGUAGE'
    self.addLangBtn:initialise()
    self.addLangBtn:instantiate()
    self.addLangBtn.borderColor = utils.copy(self.buttonBorderColor)
    self:addChild(self.addLangBtn)

    local deleteText = getText('IGUI_DbViewer_Delete')
    self.deleteLangBtn = ISButton:new(closeX, self.languageEntry.y, btnW, BTN_H, deleteText, self, self.removeLanguage)
    self.deleteLangBtn.internal = 'DELETE LANGUAGE'
    self.deleteLangBtn:initialise()
    self.deleteLangBtn:instantiate()
    self.deleteLangBtn.borderColor = utils.copy(self.buttonBorderColor)
    self:addChild(self.deleteLangBtn)

    self.langSuggester = SuggesterBox:new(0, 0, 0, 0)
    self.langSuggester:setOnMouseDownFunction(self, self.onLanguageSuggesterSelect)
    self.langSuggester:setAlwaysOnTop(true)
    self.langSuggester:setUIName('chat suggester box')
    self.langSuggester:addToUIManager()
    self.langSuggester:setVisible(false)

    self.languageEntry:setWidth(saveX - FIELD_X * 1.5)

    y = self.languageEntry:getBottom() + PAD_Y + BTN_H + 10
    self:setHeight(math.max(self:getHeight(), y))
    self:update()
end

---Removes the mod data editor and its children from the UI.
function ModDataEditor:destroy()
    if self.langSuggester then
        self.langSuggester:removeFromUIManager()
    end

    self:removeFromUIManager()
end

---Gets the computed value of an entry.
---@param entry omichat.ValidatedTextEntry
---@return string?
function ModDataEditor:getEntryValue(entry)
    local value = utils.trim(entry:getInternalText())
    if #value == 0 then
        return
    end

    return value
end

---Handles a keypress within the language entry.
---@param key number
function ModDataEditor:handleLangEntryKey(key)
    if not self.langSuggester:isVisible() then
        return
    end

    if key == Keyboard.KEY_UP then
        self.langSuggester:selectPrevious()
        return
    elseif key == Keyboard.KEY_DOWN then
        self.langSuggester:selectNext()
        return
    end

    if key ~= Keyboard.KEY_TAB and key ~= Keyboard.KEY_RETURN then
        return
    end


    local item = self.langSuggester:getSelectedItem()
    if not item then
        return
    end

    self.languageEntry:setText(item.suggestion)
    self.langSuggester:setVisible(false)
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

    if self.item.languages and #self.item.languages >= config:maxLanguageSlots() then
        return false, getText('UI_OmiChat_Error_AddLanguageFull', self.item.username)
    end

    if not self:validateLanguageText(self.languageEntry, false) then
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
        if not OmiChat.isConfiguredRoleplayLanguage(language) then
            return false, getText('UI_OmiChat_Error_AddLanguageNotConfigured', language)
        end

        return false, getText('UI_OmiChat_Error_LanguageUnknown', self.item.username, language)
    end

    return true
end

---Called when the language entry loses focus.
function ModDataEditor:onLanguageEntryFocusLost()
    if self.langSuggester:isMouseOverScrollBar() then
        self.languageEntry:focus()
    else
        self.langSuggester:setVisible(false)
    end
end

---Called when a language is selected in the listbox.
---@param language string
function ModDataEditor:onLanguageListboxSelect(language)
    self.languageEntry:setText(language)
end

---Called when a suggestion is selected in the language suggester.
---@param suggestion omichat.Suggestion
function ModDataEditor:onLanguageSuggesterSelect(suggestion)
    self.languageEntry:setText(suggestion.suggestion)
    self.langSuggester:setVisible(false)
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
    item.nameColor = self:getEntryValue(self.nameColorEntry)
    item.nickname = self:getEntryValue(self.nicknameEntry)
    item.languages = self.item.languages

    OmiChat.setModData(username, item)

    if self.onsave then
        self.onsave(self.target)
    end

    self:destroy()
end

---Called when the removes language button is clicked.
---Removes the current input language from the language list.
function ModDataEditor:removeLanguage()
    local language = utils.trim(self.languageEntry:getInternalText())
    if not self:isLanguageValidForRemove(language) then
        return
    end

    local list = self.item.languages
    if not list then
        return
    end

    local idx
    for i = 1, #list do
        if list[i] == language then
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

---Updates the valid state of the buttons.
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

---Updates the language suggester based on the input.
function ModDataEditor:updateSuggester()
    local suggester = self.langSuggester

    local input = self.languageEntry:getInternalText()
    ---@type omichat.SearchContext
    local ctx = {
        searchDisplay = true,
        search = input,
        display = utils.getTranslatedLanguageName,
        max = 50,
    }

    local search = OmiChat.searchStrings(ctx, OmiChat.getConfiguredRoleplayLanguages())
    if #search.results == 1 and OmiChat.isConfiguredRoleplayLanguage(input) then
        suggester:setVisible(false)
        return
    end

    local suggestions = {}
    for i = 1, #search.results do
        local result = search.results[i]
        suggestions[#suggestions + 1] = {
            suggestion = result.value,
            display = result.display,
        }
    end

    if #suggestions == 0 then
        suggester:setVisible(false)
        return
    end

    local langEntry = self.languageEntry
    suggester:setSuggestions(suggestions)
    suggester:setWidth(langEntry.width)
    suggester:setHeight(suggester.itemheight * math.min(#suggestions, 5))
    suggester:setX(langEntry:getAbsoluteX())
    suggester:setY(langEntry:getAbsoluteY() - suggester.height)
    suggester:setVisible(true)
    suggester:bringToTop()

    if suggester.vscroll then
        suggester.vscroll:setHeight(suggester.height)
    end
end

---Text entry validator for icons.
---@param entry omichat.ValidatedTextEntry
---@return boolean
function ModDataEditor:validateIconText(entry)
    local text = utils.trim(entry:getInternalText())
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
---@param entry omichat.ValidatedTextEntry
---@param expectKnown boolean?
---@return boolean
function ModDataEditor:validateLanguageText(entry, expectKnown)
    local text = utils.trim(entry:getInternalText())
    if #text == 0 then
        return true
    end

    if not OmiChat.isConfiguredRoleplayLanguage(text) then
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


---Creates a new mod data editor popup.
---@param x number
---@param y number
---@param width number
---@param height number
---@param item omichat.UserModData
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


OmiChat.ModDataEditor = ModDataEditor
return ModDataEditor
