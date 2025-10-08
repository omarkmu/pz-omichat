---UI element for the mod data editor.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local UI = utils.ui

local ISPanelJoypad = ISPanelJoypad
local textManager = getTextManager()


---@class omichat.ModDataEditor : ISPanelJoypad, omi.ui.Destroyable
local ModDataEditor = ISPanelJoypad:derive('ModDataEditor')
utils.extend(ModDataEditor, UI.mixin.Destroyable)


local PAD_Y = 10
local FIELD_X = 20
local FIELD_FONT = UIFont.Medium
local FONT_H_MEDIUM = textManager:getFontHeight(UIFont.Medium)
local BTN_H = math.max(25, textManager:getFontHeight(UIFont.Small) + 6)
local LABEL_H = FONT_H_MEDIUM + 4


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
    local saveX = closeX - btnW - FIELD_X * 0.5

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

    y = self:_createLabel(y + PAD_Y, getText('UI_OmiChat_ModDataManager_Column_languages'))

    self.languageListEntry = UI.listEntry {
        parent = self,
        x = FIELD_X,
        y = y,
        w = self.width - FIELD_X * 2,
        visibleItems = 4,
        itemPadY = 0,
        maxEntryWidth = saveX - FIELD_X * 1.5,
        items = item.languages,
        textEntry = {
            h = LABEL_H,
            font = FIELD_FONT,
            validateTarget = self,
            validate = self.isLanguageValid,
        },
        target = self,
        onChange = self.onUpdateLanguageList,
    }

    self.languageSuggestBox = UI.suggestBox {
        entry = self.languageListEntry.entry,
        suggestOnEnter = true,
        openUpwards = true,
        refocusOverScrollbar = true,
        target = self,
        populate = self.populateLanguageSuggest,
    }

    self.iconSuggestBox = UI.suggestBox {
        entry = self.iconEntry,
        suggestOnEnter = true,
        refocusOverScrollbar = true,
        target = self,
        populate = self.populateIconSuggest,
    }

    self:removeOnDestroy(self.languageSuggestBox)
    self:removeOnDestroy(self.iconSuggestBox)

    y = self.languageListEntry:getBottom() + PAD_Y
    self:setHeight(y + BTN_H + 10)

    local btnY = self.height - 10 - BTN_H
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
    }

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
    }
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

---Checks whether the given language is a valid entry for the language list.
---@param language string
---@return boolean valid
function ModDataEditor:isLanguageValid(language)
    language = utils.trim(language)
    if #language == 0 then
        return true
    end

    local listEntry = self.languageListEntry
    local entry = listEntry.entry
    if #listEntry.listbox.items >= config.MAX_LANGUAGE_SLOTS then
        entry:setValidateTooltipText(getText('UI_OmiChat_Error_AddLanguageFull', self.item.username))
        return false
    end

    return self:validateLanguageText(language, entry, false)
end

---Called when the language list entry is updated.
---@param entry omi.ui.ListEntry
function ModDataEditor:onUpdateLanguageList(entry)
    self.item.languages = entry:getValue()
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
    item.languages = self.languageListEntry:getValue()

    API.request.setPlayerData(username, item)

    if self.onsave then
        self.onsave(self.target)
    end

    self:destroy()
end

---Populates suggestions for the icon auto-suggest box.
---@param suggestBox omi.ui.SuggestBox
---@param text string
function ModDataEditor:populateIconSuggest(suggestBox, text)
    local search = API.search.icons {
        search = text,
        terminateOnExact = true,
        maxResults = 50,
    }

    API.search.populateSuggestions(suggestBox, search)
end

---Populates suggestions for the language auto-suggest box.
---@param suggestBox omi.ui.SuggestBox
---@param text string
function ModDataEditor:populateLanguageSuggest(suggestBox, text)
    local search = API.search.languages {
        search = text,
        terminateOnExact = true,
        maxResults = 50,
    }

    API.search.populateSuggestions(suggestBox, search)
end

---Updates the validation state of the save button.
function ModDataEditor:update()
    self.saveBtn:setEnable(self:canSubmit())
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
    y = self:_createLabel(y, labelText)

    local entry = UI.textEntry {
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

    return entry.y + entry.height, entry
end

---Helper for creating an editor label.
---@param y number
---@param labelText string
---@return number
---@return ISLabel
---@protected
function ModDataEditor:_createLabel(y, labelText)
    local label = UI.label {
        parent = self,
        x = FIELD_X,
        y = y,
        h = LABEL_H,
        text = labelText,
        font = FIELD_FONT,
    }

    return label.y + label.height, label
end


---Creates a new mod data editor popup.
---@param args omichat.Args.ModDataEditor
---@return omichat.ModDataEditor
function ModDataEditor:new(args)
    local x = args.x or 0
    local y = args.y or 0
    local width = args.w or 0
    local height = args.h or 0
    local this = ISPanelJoypad.new(self, x, y, width, height)

    local itemCopy = utils.copy(args.item)
    itemCopy.languages = itemCopy.languages and utils.copy(itemCopy.languages) or nil

    ---@cast this omichat.ModDataEditor
    this.saveItem = args.item
    this.item = itemCopy
    this.moveWithMouse = true
    this.target = args.target
    this.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    this.onsave = args.onSave
    this.isAdd = args.isAdd or false
    this.backgroundColor.a = 0.9

    return this
end


return ModDataEditor
