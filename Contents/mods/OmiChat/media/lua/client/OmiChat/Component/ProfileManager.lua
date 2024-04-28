local ISLabel = ISLabel
local ISPanelJoypad = ISPanelJoypad

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local ContentPanel = require 'OmiChat/Component/ProfileManager/ContentPanel'
local utils = OmiChat.utils
local Option = OmiChat.Option

---UI element for managing player preference profiles.
---@class omichat.ProfileManager : ISPanelJoypad
---@field current omichat.PlayerProfile?
---@field profiles omichat.PlayerProfile[]
---@field profileNameControl omichat.ValidatedTextEntry
---@field nicknameControl omichat.ValidatedTextEntry?
---@field colorControls table<string, omichat.ValidatedColorEntry>
---@field calloutControls table<string, omichat.ValidatedTextEntry>
local ProfileManager = ISPanelJoypad:derive('ProfileManager')

local textManager = getTextManager()
local FONT_H_LARGE = textManager:getFontHeight(UIFont.Large)
local FONT_H_MEDIUM = textManager:getFontHeight(UIFont.Medium)
local FONT_H_SMALL = textManager:getFontHeight(UIFont.Small)


---Creates a copy of a player profile.
---@param profile omichat.PlayerProfile
---@return omichat.PlayerProfile
local function cloneProfile(profile)
    ---@type omichat.PlayerProfile
    local clone = {
        name = profile.name,
        chatNickname = profile.chatNickname,
        callouts = utils.copy(profile.callouts),
        sneakcallouts = utils.copy(profile.sneakcallouts),
        colors = {},
    }

    for k, v in pairs(profile.colors) do
        clone.colors[k] = utils.copy(v)
    end

    return clone
end

---Clones a list of player profiles.
---@param profiles omichat.PlayerProfile[]
---@return omichat.PlayerProfile[]
local function cloneProfiles(profiles)
    local result = {}
    for i = 1, #profiles do
        result[i] = cloneProfile(profiles[i])
    end

    return result
end


---Adds a profile to the listbox.
---@param profile omichat.PlayerProfile
function ProfileManager:addListboxItem(profile)
    local item = self.listbox:addItem(profile.name, profile)
    self:updateListboxText(item.itemindex, profile.name)
end

---Creates the panel used to display profile content.
---@return omichat.ProfileManagerContent
function ProfileManager:createContentPanel()
    local listbox = self.listbox
    local x = listbox:getRight() + 24
    local w = self.width - listbox:getRight() - 48
    local panel = ContentPanel:new(x, listbox:getY(), w, listbox:getHeight())

    panel:initialise()
    panel:instantiate()
    panel:setAnchorRight(true)
    panel:setAnchorBottom(true)
    panel:setScrollChildren(true)
    panel:addScrollBars()

    return panel
end

---Creates the children of the profile manager.
function ProfileManager:createChildren()
    local titleText = getText('UI_OmiChat_ProfileManager_Title')
    local titleWidth = textManager:MeasureStringX(UIFont.Large, titleText)
    local titleX = self.width / 2 - titleWidth / 2
    local titleH = FONT_H_LARGE
    local title = ISLabel:new(titleX, 10, titleH, titleText, 1, 1, 1, 1, UIFont.Large, true)
    title:initialise()
    title:instantiate()

    local btnWidth = 100
    local btnHgt = math.max(25, FONT_H_SMALL + 6)
    local btnY = self.height - 10 - btnHgt

    local listboxY = titleH + 20
    local listboxW = math.min(100, self.width / 4)
    local listboxH = self.height - btnHgt - titleH - 40
    local listbox = ISScrollingListBox:new(24, listboxY, listboxW, listboxH)
    listbox.drawBorder = true
    listbox:setAnchorLeft(true)
    listbox:setAnchorRight(false)
    listbox:setAnchorTop(true)
    listbox:setAnchorBottom(true)
    listbox:setFont(UIFont.Small, 4)
    listbox:setOnMouseDownFunction(self, self.updateControlState)

    local closeX = self.width - 124
    local closeText = getText('IGUI_CraftUI_Close')
    local closeButton = ISButton:new(closeX, btnY, btnWidth, btnHgt, closeText, self, self.destroy)
    closeButton.internal = 'CLOSE'
    closeButton.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    closeButton:initialise()
    closeButton:instantiate()
    closeButton:setAnchorLeft(false)
    closeButton:setAnchorTop(false)
    closeButton:setAnchorRight(false)
    closeButton:setAnchorBottom(true)

    local saveText = getText('IGUI_RadioSave')
    local saveButton = ISButton:new(0, btnY, btnWidth, btnHgt, saveText, self, self.onSave)
    saveButton.internal = 'SAVE'
    saveButton.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    saveButton:initialise()
    saveButton:instantiate()
    saveButton:setAnchorLeft(false)
    saveButton:setAnchorTop(false)
    saveButton:setAnchorRight(false)
    saveButton:setAnchorBottom(true)
    saveButton:setWidthToTitle(btnWidth)
    saveButton:setX(closeButton.x - 20 - saveButton.width)

    local createText = getText('UI_OmiChat_ProfileManager_CreateButton')
    local createButton = ISButton:new(0, 0, btnWidth, btnHgt, createText, self, self.addProfile)
    createButton.internal = 'CREATE'
    createButton.borderColor = { r = 1, g = 1, b = 1, a = 0.1 }
    createButton:initialise()
    createButton:instantiate()
    createButton:setAnchorLeft(true)
    createButton:setAnchorTop(true)
    createButton:setAnchorRight(true)
    createButton:setAnchorBottom(true)
    createButton:setWidthToTitle(btnWidth)
    createButton:setX(self.width / 2 - createButton.width / 2)
    createButton:setY(self.height / 2 - createButton.height / 2)

    local emptyText = getText('UI_OmiChat_ProfileManager_Empty')
    local emptyLabel = ISLabel:new(0, 0, FONT_H_MEDIUM, emptyText, 1, 1, 1, 1, UIFont.Medium, false)
    emptyLabel:initialise()
    emptyLabel:setX(self.width / 2 - emptyLabel.width / 2)
    emptyLabel:setY(self.height / 2 - emptyLabel.height / 2 - createButton.height)

    self.listbox = listbox
    self.createButton = createButton
    self.closeButton = closeButton
    self.saveButton = saveButton
    self.emptyLabel = emptyLabel

    self.contentPanel = self:createContentPanel()
    self.contentPanel:addControls(self)

    self:addChild(title)
    self:addChild(listbox)
    self:addChild(closeButton)
    self:addChild(saveButton)
    self:addChild(createButton)
    self:addChild(emptyLabel)
    self:addChild(self.contentPanel)
    self:updateUIState(true)
end

---Removes the panel from the UI.
function ProfileManager:destroy()
    self:removeFromUIManager()
end

---Adds a new profile to the manager.
function ProfileManager:addProfile()
    local idx = #self.profiles + 1
    if idx > 20 then
        return
    end

    local profile = {
        name = getText('UI_OmiChat_ProfileManager_DefaultProfileName', idx),
        colors = {},
        callouts = {},
        sneakcallouts = {},
    }

    self.profiles[idx] = profile

    self:addListboxItem(profile)
    self:updateUIState(nil, idx)
end

---Deletes the currently selected profile.
function ProfileManager:deleteProfile()
    local idx = self.listbox.selected
    if not self.listbox:removeItemByIndex(idx) then
        return
    end

    table.remove(self.profiles, idx)
    self:updateUIState(true, idx)
end

---Copies the current settings into the current profile.
function ProfileManager:copyFromCurrent()
    local idx = self.listbox.selected
    local profile = self.profiles[idx]
    if not profile then
        return
    end

    local prefs = OmiChat.getPlayerPreferences()
    profile.callouts = utils.copy(prefs.callouts)
    profile.sneakcallouts = utils.copy(prefs.sneakcallouts)
    profile.colors = utils.copy(prefs.colors)

    profile.colors.speech = OmiChat.getSpeechColor() ---@diagnostic disable-line: assign-type-mismatch

    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if username then
        local nameColor = OmiChat.getNameColor(username)
        profile.colors.name = nameColor ---@diagnostic disable-line: assign-type-mismatch
    end

    self:updateControlState(true)
end

---Callback for callout update.
---@param entry omichat.ValidatedTextEntry
---@param category omichat.CalloutCategory
function ProfileManager:onCalloutsChange(entry, category)
    local profile = self.current
    if not profile then
        return
    end

    local maxLen = Option.CustomShoutMaxLength > 0 and Option.CustomShoutMaxLength or nil
    local lines = utils.getLines(entry:getInternalText(), maxLen)
    if lines and category == 'sneakcallouts' then
        for i = 1, #lines do
            lines[i] = lines[i]:lower()
        end
    end

    profile[category] = lines or {}
end

---Callback for color update.
---@param entry omichat.ValidatedColorEntry
---@param category omichat.ColorCategory
function ProfileManager:onColorChange(entry, category)
    local profile = self.current
    local color = entry:getColorTable()
    if profile and color then
        profile.colors[category] = utils.copy(color)
    elseif profile then
        profile.colors[category] = nil
    end

    local nameControl = self.colorControls.name
    if nameControl and Option.EnableSpeechColorAsDefaultNameColor and category == 'speech' then
        nameControl:setEmptyColor(color or entry:getEmptyColor())
    end
end

---Callback for nickname update.
---@param entry omichat.ValidatedTextEntry
function ProfileManager:onNicknameChange(entry)
    local text = entry:getInternalText()
    text = utils.trim(text)

    local valid, filtered
    if #text == 0 then
        valid = false
    else
        valid, filtered = OmiChat.validateNicknameText(entry, text)
        if filtered and text ~= filtered then
            entry:setText(filtered)
        end
    end

    local profile = self.current
    if profile then
        profile.chatNickname = valid and filtered or nil
    end
end

---Callback for profile name update.
---@param entry omichat.ValidatedTextEntry
function ProfileManager:onProfileNameChange(entry)
    local text = entry:getInternalText()
    text = utils.trim(text)
    if #text == 0 then
        text = getText('UI_OmiChat_ProfileManager_DefaultProfileName', self.listbox.selected)
    elseif #text >= 50 then
        text = text:sub(1, 50)
    end

    local profile = self.current
    if profile then
        profile.name = text
    end

    self:updateListboxText(self.listbox.selected, text)
    self:updateUIState()
end

---Callback for apply changes button.
function ProfileManager:onSave()
    OmiChat.setProfiles(cloneProfiles(self.profiles))
    self:removeFromUIManager()
end

---Updates the state of controls.
---@param force boolean?
function ProfileManager:updateControlState(force)
    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()

    local selectedProfile = self.profiles[self.listbox.selected]
    if not selectedProfile then
        return
    end

    if not force and selectedProfile == self.current then
        return
    end

    self.current = selectedProfile
    self.profileNameControl:setText(self.current.name)

    if self.nicknameControl then
        self.nicknameControl:setText(self.current.chatNickname)
    end

    for k, control in pairs(self.colorControls) do
        local defaultColor = Option:getDefaultColor(k, username)
        control:setEmptyColor(defaultColor)

        local color = self.current.colors[k]
        if color then
            control:selectColor(color)
        else
            control:clear(true)
        end
    end

    for k, control in pairs(self.calloutControls) do
        local shouts = self.current[k]
        local text = shouts and table.concat(shouts, '\n') or ''
        control:setText(text)
    end
end

---Updates the listbox item at the given index to use the given text.
---@param idx integer
---@param text string
function ProfileManager:updateListboxText(idx, text)
    text = utils.trim(text)
    local item = self.listbox.items[idx]
    if not item then
        return
    end

    item.text = text
    local width = textManager:MeasureStringX(self.listbox.font, text) + 16
    if width >= self.listbox:getWidth() then
        item.tooltip = text
    else
        item.tooltip = nil
    end
end

---Updates the state of the UI based on the number of available profiles.
---@param resetItems boolean?
---@param selectIdx integer?
function ProfileManager:updateUIState(resetItems, selectIdx)
    local panel = self.contentPanel
    local listbox = self.listbox
    local emptyLabel = self.emptyLabel
    local createButton = self.createButton

    if resetItems then
        listbox:clear()
        for i = 1, #self.profiles do
            self:addListboxItem(self.profiles[i])
        end
    end

    if selectIdx and #self.listbox.items > 0 then
        self.listbox.selected = math.min(selectIdx, #self.listbox.items)
    end

    if #self.profiles == 0 then
        panel:setVisible(false)
        listbox:setVisible(false)
        emptyLabel:setVisible(true)
        createButton:setTitle(getText('UI_OmiChat_ProfileManager_CreateButton'))
        createButton:setX(self.width / 2 - createButton.width / 2)
        createButton:setY(self.height / 2 - createButton.height / 2)
        return
    end

    panel:setVisible(true)
    listbox:setVisible(true)
    emptyLabel:setVisible(false)
    createButton:setTitle(getText('UI_OmiChat_ProfileManager_AddButton'))
    createButton:setX(listbox.x + (listbox.width - createButton.width) / 2)
    createButton:setY(self.height - 10 - math.max(25, FONT_H_SMALL + 6))
    self:updateControlState()
end

---Creates a new panel for managing profiles.
---@param x number
---@param y number
---@param width number
---@param height number
---@param profiles omichat.PlayerProfile[]
---@return omichat.ProfileManager
function ProfileManager:new(x, y, width, height, profiles)
    local this = ISPanelJoypad.new(self, x, y, width, height)
    ---@cast this omichat.ProfileManager

    setmetatable(this, self)
    self.__index = self

    this.anchorLeft = true
    this.anchorRight = false
    this.anchorTop = true
    this.anchorBottom = false
    this.moveWithMouse = true
    this.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    this.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    this.profiles = cloneProfiles(profiles)
    this.colorControls = {}
    this.calloutControls = {}

    return this
end


OmiChat.ProfileManager = ProfileManager
return ProfileManager
