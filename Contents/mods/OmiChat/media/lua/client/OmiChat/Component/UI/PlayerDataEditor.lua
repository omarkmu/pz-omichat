---UI element for the player data editor admin utility.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration
local UI = utils.ui

local textManager = getTextManager()
local getAttr = utils.getAttr
local getText = utils.getText

local PAD_Y = 10
local FIELD_X = 20
local FONT_MEDIUM = UIFont.Medium
local FIELD_FONT = FONT_MEDIUM
local TITLE_FONT = FONT_MEDIUM
local FONT_H_MEDIUM = textManager:getFontHeight(FONT_MEDIUM)
local BTN_H = math.max(25, textManager:getFontHeight(UIFont.Small) + 6)
local LABEL_H = FONT_H_MEDIUM + 4


---@class PlayerDataEditor : omi.Panel
---@field item PlayerData The player data for editing.
---@field saveItem PlayerData The input player data item.
---@field nicknameEntry omi.TextEntry The entry for the player nickname.
---@field usernameEntry omi.TextEntry The entry for the player username.
---@field iconEntry omi.TextEntry The entry for the player icon.
---@field currentLangEntry omi.TextEntry The entry for the player's current language.
---@field languageListEntry omi.ListEntry The list entry for the player's known languages.
---@field statusEntry omi.TextEntry The entry for the player's status.
---@field languageSlotsEntry omi.TextEntry The entry for the player's language slots.
---@field languageSuggestBox omi.SuggestBox The suggest box for languages, for the language list entry.
---@field iconSuggestBox omi.SuggestBox The icon suggest box, for the icon entry.
---@field buttonBorderColor omi.ColorTableRGBA<number> The border color used for buttons.
---@field saveBtn omi.Button The save button.
---@field closeBtn omi.Button The close button.
---@field isAdd boolean Flag for whether the editor is for adding new data, rather than editing existing data.
---@field languageFilter? function Filter function for the language suggest box.
---@field protected callbacks PlayerDataEditor.Callbacks Container for callbacks.
local PlayerDataEditor = UI.Panel:derive('PlayerDataEditor')


---Checks all fields for validity.
---@return boolean canSubmit
function PlayerDataEditor:canSubmit()
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

---Adds the children of the editor.
function PlayerDataEditor:createChildren()
    local btnW = 100

    local titleH = FONT_H_MEDIUM
    local titleText = getAttr('player-data-manager', 'editor-title')
    local titleWidth = textManager:MeasureStringX(TITLE_FONT, titleText)

    UI.label {
        parent = self,
        x = self.width / 2 - titleWidth / 2,
        y = 10,
        h = titleH,
        text = titleText,
        font = TITLE_FONT,
    }

    local closeX = self.width - btnW - FIELD_X
    local saveX = closeX - btnW - FIELD_X * 0.5

    -- fields
    local y
    local item = self.item
    local text = getAttr('player-data-manager', 'column-username')
    y, self.usernameEntry = self:_createEntry('text', titleH + 20, text, item.username)

    if self.isAdd then
        self.usernameEntry:setRequireValue(true)
    else
        self.usernameEntry:setEditable(false)
    end

    text = getAttr('player-data-manager', 'column-nickname')
    y, self.nicknameEntry = self:_createEntry('text', y + PAD_Y, text, item.nickname)
    self.nicknameEntry:setValidateFunction(self.nicknameEntry, API.chat.validateNameEntry)

    text = getAttr('player-data-manager', 'column-status')
    y, self.statusEntry = self:_createEntry('text', y + PAD_Y, text, item.status)
    self.statusEntry:setValidateFunction(self.statusEntry, API.chat.validateStatusEntry)

    text = getAttr('player-data-manager', 'column-icon')
    y, self.iconEntry = self:_createEntry('text', y + PAD_Y, text, item.icon)
    self.iconEntry:setValidateFunction(self, self._validateIconText, self.iconEntry)

    text = getAttr('player-data-manager', 'column-currentLanguage')
    y, self.currentLangEntry = self:_createEntry('text', y + PAD_Y, text, item.currentLanguage)
    self.currentLangEntry:setValidateFunction(self, self._validateLanguageText, self.currentLangEntry, true)

    text = getAttr('player-data-manager', 'column-languageSlots')
    y, self.languageSlotsEntry = self:_createEntry('number', y + PAD_Y, text, item.languageSlots, 0,
        config.MAX_LANGUAGE_SLOTS)

    y = self:_createLabel(y + PAD_Y, getAttr('player-data-manager', 'column-languages'))

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
        onChange = self._onUpdateLanguageList,
    }

    self.languageSuggestBox = UI.suggestBox {
        entry = self.languageListEntry.entry,
        suggestOnEnter = true,
        openUpwards = true,
        refocusOverScrollbar = true,
        target = self,
        populate = self._populateLanguageSuggest,
    }

    self.iconSuggestBox = UI.suggestBox {
        entry = self.iconEntry,
        suggestOnEnter = true,
        refocusOverScrollbar = true,
        target = self,
        populate = self._populateIconSuggest,
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
        text = getText('.btn-close'),
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
        text = getText('.btn-save'),
        borderColor = utils.copy(self.buttonBorderColor),
        target = self,
        onClick = self.onSave,
    }
end

---Checks whether the input language list contains the given language.
---@param language string The name of the language to check.
---@return boolean hasLanguage
function PlayerDataEditor:hasLanguage(language)
    local langs = self.item.languages
    if not langs then
        return false
    end

    return utils.includes(langs, language)
end

---Checks whether the given language is a valid entry for the language list.
---@param language string The name of the language to check.
---@return boolean valid
function PlayerDataEditor:isLanguageValid(language)
    language = utils.trim(language)
    if #language == 0 then
        return true
    end

    local listEntry = self.languageListEntry
    local entry = listEntry.entry
    if #listEntry.listbox.items >= config.MAX_LANGUAGE_SLOTS then
        entry:setValidateTooltipText(getText('error-add-language-full', { username = self.item.username }))
        return false
    end

    return self:_validateLanguageText(language, entry, false)
end

---Called when the save button is clicked.
function PlayerDataEditor:onSave()
    if not self:canSubmit() then
        self:destroy()
        return
    end

    local item = self.saveItem
    local icon = self:_getEntryValue(self.iconEntry)
    local slots = self:_getEntryValue(self.languageSlotsEntry)
    if icon and not getTexture(icon) then
        icon = utils.getTextureNameFromIcon(icon)
    end

    local username
    if self.isAdd then
        username = self:_getEntryValue(self.usernameEntry)
        if not username then
            return
        end

        item.username = username
    else
        username = item.username
    end

    item.icon = icon
    item.currentLanguage = self:_getEntryValue(self.currentLangEntry)
    item.languageSlots = slots and tonumber(slots)
    item.nickname = self:_getEntryValue(self.nicknameEntry)
    item.status = self:_getEntryValue(self.statusEntry)
    item.languages = self.languageListEntry:getValue()

    API.request.setPlayerData(username, item)

    utils.callback.invoke(self.callbacks.onSave)

    self:destroy()
end

---Sets a callback to be called when the save button is pressed.
---@param target any? The first argument to pass to the `callback` functon.
---@param callback function? The callback function.
---@param ...any Additional arguments for the `callback` function.
function PlayerDataEditor:setOnSave(target, callback, ...)
    self.callbacks.onSave = utils.callback(target, callback, ...)
end

---Updates the validation state of the save button.
function PlayerDataEditor:update()
    self.saveBtn:setEnable(self:canSubmit())
end


---Helper for creating an editor entry field.
---@param type 'text' | 'number'
---@param y number
---@param labelText string
---@param default any?
---@param min number?
---@param max number?
---@return number newY
---@return omi.TextEntry entry
---@private
function PlayerDataEditor:_createEntry(type, y, labelText, default, min, max)
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
---@return number newY
---@return omi.Label label
---@private
function PlayerDataEditor:_createLabel(y, labelText)
    local label = UI.label {
        parent = self,
        x = FIELD_X,
        y = y,
        h = LABEL_H,
        text = labelText,
        font = FIELD_FONT,
    }

    return label:getBottom(), label
end

---Filter function for languages in the language list entry.
---@private
function PlayerDataEditor:_filterLanguages(text)
    return not self:hasLanguage(text)
end

---Gets the computed value of an entry.
---@param entry omi.TextEntry
---@return string? value
---@private
function PlayerDataEditor:_getEntryValue(entry)
    local value = utils.trim(entry:getInternalText())
    if #value == 0 then
        return
    end

    return value
end

---Called when the language list entry is updated.
---@param entry omi.ListEntry
---@private
function PlayerDataEditor:_onUpdateLanguageList(entry)
    self.item.languages = entry:getValue()
end

---Populates suggestions for the icon auto-suggest box.
---@param suggestBox omi.SuggestBox
---@param text string
---@private
function PlayerDataEditor:_populateIconSuggest(suggestBox, text)
    local search = API.search.icons {
        search = text,
        terminateOnExact = true,
        maxResults = 50,
    }

    API.search.populateSuggestions(suggestBox, search)
end

---Populates suggestions for the language auto-suggest box.
---@param suggestBox omi.SuggestBox
---@param text string
---@private
function PlayerDataEditor:_populateLanguageSuggest(suggestBox, text)
    local search = API.search.languages {
        search = text,
        terminateOnExact = true,
        maxResults = 50,
        filter = self.languageFilter,
    }

    API.search.populateSuggestions(suggestBox, search)
end

---Text entry validator for icons.
---@param text string
---@param entry omi.TextEntry
---@return boolean valid
---@private
function PlayerDataEditor:_validateIconText(text, entry)
    if #text == 0 then
        return true
    end

    if utils.getTextureNameFromIcon(text) or getTexture(text) then
        return true
    end

    entry:setValidateTooltipText(getText('info-icon-unknown', { name = text }))
    return false
end

---Text entry validator for roleplay language names.
---@param text string
---@param entry omi.TextEntry
---@param expectKnown boolean?
---@return boolean valid
---@private
function PlayerDataEditor:_validateLanguageText(text, entry, expectKnown)
    if #text == 0 then
        return true
    end

    if not API.language.exists(text) then
        entry:setValidateTooltipText(getText('error-add-language-not-configured', { language = text }))
        return false
    end

    if expectKnown ~= nil and self:hasLanguage(text) ~= expectKnown then
        local username = self.usernameEntry:getInternalText()
        local err = expectKnown and 'error-language-unknown' or 'error-add-language-known'
        entry:setValidateTooltipText(getText(err, { username = username, language = text }))
        return false
    end

    return true
end


---Creates a new player data editor popup.
---@param args Args.PlayerDataEditor Arguments for creation of the editor.
---@return PlayerDataEditor editor
function PlayerDataEditor:new(args)
    local this = UI.new(self, UI.Panel.new, args)

    local itemCopy = utils.copy(args.item)
    itemCopy.languages = itemCopy.languages and utils.copy(itemCopy.languages) or nil

    this.saveItem = args.item
    this.item = itemCopy
    this.moveWithMouse = true
    this.buttonBorderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0.5 }
    this.languageFilter = utils.bind(this._filterLanguages, this)
    this.isAdd = args.isAdd or false
    this.backgroundColor.a = 0.9

    this:setOnSave(args.onSaveTarget or args.target, args.onSave, unpack(args.onSaveArgs or {}))
    return this
end


return PlayerDataEditor

--#region Type Definitions

---@class Args.PlayerDataEditor : omi.Args.Panel
---@field item PlayerData The original data to be edited.
---@field isAdd? boolean Flag for whether the editor is for adding user data, rather than editing existing data.
---@field onSave? omi.UICallback Invoked when saving the player data.
---@field onSaveArgs? table Arguments for `onSave`.
---@field onSaveTarget? any The first argument to pass to the `onSave` callback.

---@class PlayerDataEditor.Callbacks : omi.Panel.Callbacks
---@field onSave? omi.CallbackInfo Invoked when saving the player data.

--#endregion
