---UI element for managing player preference profiles.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local config = API.Configuration
local utils = API.utils
local UI = utils.ui


---@class omichat.ProfileManager : omi.ui.Panel
local ProfileManager = UI.Panel:derive('ProfileManager')

local textManager = getTextManager()

local CONTROL_FONT = UIFont.Medium
local FONT_H_LARGE = textManager:getFontHeight(UIFont.Large)
local FONT_H_MEDIUM = textManager:getFontHeight(UIFont.Medium)
local FONT_H_SMALL = textManager:getFontHeight(UIFont.Small)
local LABEL_H = FONT_H_MEDIUM + 4
local CONTENT_PAD_X = 20
local CONTENT_PAD_Y = 10
local CONTROL_PAD_Y = 5
local SECTION_PAD_Y = 20


---Creates a copy of a player profile.
---@param profile omichat.PlayerProfile
---@return omichat.PlayerProfile
---@private
function ProfileManager._cloneProfile(profile)
    ---@type omichat.PlayerProfile
    local clone = {
        name = profile.name,
        chatNickname = profile.chatNickname,
        callouts = utils.copy(profile.callouts),
        sneakcallouts = utils.copy(profile.sneakcallouts),
        colors = utils.deepcopy(profile.colors),
    }

    return clone
end

---Clones a list of player profiles.
---@param profiles omichat.PlayerProfile[]
---@param markIndices boolean?
---@return omichat.PlayerProfile[]
---@private
function ProfileManager._cloneProfiles(profiles, markIndices)
    local result = {}
    for i = 1, #profiles do
        result[i] = ProfileManager._cloneProfile(profiles[i])

        if markIndices then
            result[i]._originalIndex = i
        end
    end

    return result
end

---Validation function for custom callout text.
---@param entry omi.ui.TextEntry
---@param text string
---@return boolean
---@private
function ProfileManager._validateCustomCalloutText(entry, text)
    local lines = utils.getLines(text)
    if not lines then
        return true
    end

    local maxShouts = config.MAX_CUSTOM_SHOUTS
    if #lines > maxShouts then
        entry:setValidateTooltipText(getText('UI_OmiChat_Error_TooManyShouts', tostring(maxShouts)))
        return false
    end

    local maxLen = config.MAX_CUSTOM_SHOUT_LEN
    for i = 1, #lines do
        if #lines[i] > maxLen then
            entry:setValidateTooltipText(getText('UI_OmiChat_Error_TooLongShout', tostring(maxLen)))
            return false
        end
    end

    return true
end


---Adds a new profile to the manager.
function ProfileManager:addProfile()
    local idx = #self.profiles + 1
    if idx > config.MAX_PROFILES then
        return
    end

    local profile = {
        name = getText('UI_OmiChat_ProfileManager_DefaultProfileName', idx),
        colors = {},
        callouts = {},
        sneakcallouts = {},
    }

    self.profiles[idx] = profile

    self:_addListboxItem(profile)
    self:_updateUIState(false, idx)
end

---Creates the children of the profile manager.
function ProfileManager:createChildren()
    local titleText = getText('UI_OmiChat_ProfileManager_Title')
    local titleWidth = textManager:MeasureStringX(UIFont.Large, titleText)
    local titleH = FONT_H_LARGE

    local padX = 24
    local btnW = 100
    local btnH = math.max(25, FONT_H_SMALL + 6)
    local btnY = self.height - 10 - btnH

    UI.label {
        parent = self,
        text = titleText,
        x = (self.width - titleWidth) * 0.5,
        y = 10,
        h = titleH,
        font = UIFont.Large,
    }

    self.listbox = UI.listBox {
        parent = self,
        x = padX,
        y = titleH + 20,
        w = math.min(100, self.width / 4),
        h = self.height - btnH - titleH - 40,
        drawBorder = true,
        anchorLeft = true,
        anchorRight = false,
        anchorTop = true,
        anchorBottom = true,
        font = UIFont.Small,
        itemPadY = 4,
        target = self,
        onMouseDown = self._updateControlState,
    }

    self.closeBtn = UI.button {
        parent = self,
        x = self.width - btnW - padX,
        y = btnY,
        w = btnW,
        h = btnH,
        minWidth = btnW,
        anchorLeft = false,
        anchorTop = false,
        anchorRight = false,
        anchorBottom = true,
        internal = 'CLOSE',
        text = getText('IGUI_CraftUI_Close'),
        target = self,
        onClick = self.destroy,
        setWidthToText = true,
    }

    self.saveBtn = UI.button {
        parent = self,
        x = 0,
        y = btnY,
        w = btnW,
        h = btnH,
        minWidth = btnW,
        anchorLeft = false,
        anchorTop = false,
        anchorRight = false,
        anchorBottom = true,
        internal = 'SAVE',
        text = getText('IGUI_RadioSave'),
        target = self,
        onClick = self.onSave,
        setWidthToText = true,
    }

    self.createBtn = UI.button {
        parent = self,
        w = btnW,
        h = btnH,
        minWidth = btnW,
        anchorLeft = true,
        anchorTop = true,
        anchorRight = true,
        anchorBottom = true,
        internal = 'CREATE',
        text = self.createText,
        target = self,
        onClick = self.addProfile,
        setWidthToText = true,
    }

    self.emptyLabel = UI.label {
        parent = self,
        h = FONT_H_MEDIUM,
        text = getText('UI_OmiChat_ProfileManager_Empty'),
        font = UIFont.Medium,
        left = false,
    }

    self.contentPanel = UI.panel {
        parent = self,
        x = self.listbox:getRight() + padX,
        y = self.listbox:getY(),
        w = self.width - self.listbox:getRight() - padX * 2,
        h = self.listbox:getHeight(),
        anchorRight = true,
        anchorBottom = true,
        scrollChildren = true,
        addVerticalScrollbar = true,
        handleScrolling = true,
    }

    self.closeBtn:setX(self.width - self.closeBtn.width - padX)
    self.saveBtn:setX(self.closeBtn.x - self.saveBtn.width - padX)

    self.createBtn.borderColor.a = 0.5
    self.createBtn:setX((self.width - self.createBtn.width) * 0.5)
    self.createBtn:setY((self.height - self.createBtn.height) * 0.5)

    self.emptyLabel:setX((self.width - self.emptyLabel.width) * 0.5)
    self.emptyLabel:setY((self.height - self.emptyLabel.height) * 0.5 - self.createBtn.height)

    self:_addControls()
    self:_updateUIState(true)
end

---Deletes the currently selected profile.
function ProfileManager:deleteProfile()
    local idx = self.listbox.selected
    local item = self.listbox:removeItemByIndex(idx)
    if not item or not item.item then
        return
    end

    local data = item.item
    if not self.deletedCurrentProfile and data._originalIndex then
        self.deletedCurrentProfile = data._originalIndex == API.preferences.getCurrentProfileIndex()
    end

    table.remove(self.profiles, idx)
    self:_updateUIState(true, idx)
end

---Duplicates the currently selected profile.
function ProfileManager:duplicateProfile()
    local newIdx = #self.profiles + 1
    if newIdx > config.MAX_PROFILES then
        return
    end

    local item = self.listbox:getSelectedItem()
    if not item then
        return
    end

    local profile = ProfileManager._cloneProfile(item)
    profile.name = getText('UI_OmiChat_ProfileManager_DefaultProfileName', newIdx)

    self.profiles[newIdx] = profile
    self:_addListboxItem(profile)
    self:_updateUIState(true, newIdx)
end

---Callback for callout update.
---@param entry omi.ui.TextEntry
---@param category omichat.CalloutCategory
function ProfileManager:onCalloutsChange(entry, category)
    local profile = self.current
    if not profile then
        return
    end

    local lines = utils.getLines(entry:getInternalText(), config.MAX_CUSTOM_SHOUT_LEN)
    if lines and category == 'sneakcallouts' then
        for i = 1, #lines do
            lines[i] = lines[i]:lower()
        end
    end

    profile[category] = lines or {}
end

---Callback for color update.
---@param entry omi.ui.ColorEntry
---@param category string
function ProfileManager:onColorChange(entry, category)
    local profile = self.current
    local color = entry:getColor()
    if profile and color then
        profile.colors[category] = utils.copy(color)
    elseif profile then
        profile.colors[category] = nil
    end
end

---Callback for nickname update.
---@param entry omi.ui.TextEntry
function ProfileManager:onNicknameChange(entry)
    local text = entry:getInternalText()
    text = utils.trim(text)

    local valid, filtered
    if #text == 0 then
        valid = false
    else
        valid, filtered = API.format.validateName(entry, text)
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
---@param entry omi.ui.TextEntry
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

    self:_updateListboxText(self.listbox.selected, text)
    self:_updateUIState()
end

---Callback for apply changes button.
function ProfileManager:onSave()
    API.preferences.setProfiles(ProfileManager._cloneProfiles(self.profiles))

    if self.deletedCurrentProfile then
        API.preferences.switchToDefaultProfile()
    else
        API.preferences.refreshProfile()
    end

    API.ui.redraw()
    self:removeFromUIManager()
end


---Adds the label and control elements.
---@protected
function ProfileManager:_addControls()
    local panel = self.contentPanel
    local controlW = panel.width * 0.5 - CONTENT_PAD_X * 2
    local startY = CONTENT_PAD_Y

    -- profile name
    local nameLabel = UI.label {
        parent = panel,
        x = CONTENT_PAD_X,
        y = CONTENT_PAD_Y,
        h = LABEL_H,
        text = getText('UI_OmiChat_ProfileManager_Label_ProfileName'),
        font = CONTROL_FONT,
    }

    local nameControl = UI.textEntry {
        parent = panel,
        x = CONTENT_PAD_X,
        y = nameLabel:getBottom(),
        w = controlW,
        h = LABEL_H,
        font = CONTROL_FONT,
        minLength = 1,
        maxLength = 50,
    }

    nameControl:setOnChange(self, self.onProfileNameChange, nameControl)
    self.profileNameControl = nameControl

    startY = nameControl:getBottom() + CONTROL_PAD_Y

    -- chat nickname
    if config:isNicknameEnabled() then
        local nicknameLabel = UI.label {
            parent = panel,
            x = CONTENT_PAD_X,
            y = startY,
            h = LABEL_H,
            text = getText('UI_OmiChat_ProfileManager_Label_Nickname'),
            font = CONTROL_FONT,
        }

        local nicknameControl = UI.textEntry {
            parent = panel,
            x = CONTENT_PAD_X,
            y = nicknameLabel:getBottom(),
            w = controlW,
            h = LABEL_H,
            font = CONTROL_FONT,
            tooltip = getText('UI_OmiChat_ProfileManager_Tooltip_Nickname'),
        }

        nicknameControl:setValidateFunction(nicknameControl, API.format.validateName)
        nicknameControl:setOnChange(self, self.onNicknameChange, nicknameControl)

        self.nicknameControl = nicknameControl
        startY = nicknameControl:getBottom() + CONTROL_PAD_Y
    end

    -- colors
    local maxY = startY + SECTION_PAD_Y
    self.colorControls, maxY = self:_createColorControls(maxY)

    -- callouts
    if config:isCustomShoutsEnabled() then
        self.calloutControls, maxY = self:_createCalloutControls(maxY + SECTION_PAD_Y)
    end

    panel:setScrollHeight(maxY + CONTENT_PAD_Y)
    self:_createButtons()
end

---Adds a profile to the listbox.
---@param profile omichat.PlayerProfile
---@protected
function ProfileManager:_addListboxItem(profile)
    local item = self.listbox:addItem(profile.name, profile)
    self:_updateListboxText(item.itemindex, profile.name)
end

---Adds buttons to the content panel.
---@protected
function ProfileManager:_createButtons()
    local panel = self.contentPanel
    local btnX = panel.width * 0.5
    local btnW = panel.width * 0.25 - CONTENT_PAD_X * 2
    local btnH = math.max(25, FONT_H_SMALL + 6)
    local btnY = CONTENT_PAD_Y + LABEL_H

    self.deleteBtn = UI.button {
        parent = panel,
        x = btnX,
        y = btnY,
        w = btnW,
        h = btnH,
        internal = 'DELETE',
        text = getText('UI_OmiChat_ProfileManager_DeleteButton'),
        target = self,
        onClick = self.deleteProfile,
        setWidthToText = true,
    }

    self.duplicateBtn = UI.button {
        parent = panel,
        x = self.deleteBtn:getRight() + CONTENT_PAD_X,
        y = btnY,
        w = btnW,
        h = btnH,
        internal = 'DUPLICATE',
        text = getText('UI_OmiChat_ProfileManager_DuplicateButton'),
        target = self,
        onClick = self.duplicateProfile,
        setWidthToText = true,
    }

    self.deleteBtn.borderColor.a = 0.5
    self.duplicateBtn.borderColor.a = 0.5
end

---Creates the labels and controls for callout text.
---@param startY number
---@return table<string, omi.ui.TextEntry> controls
---@return number maxY
---@protected
function ProfileManager:_createCalloutControls(startY)
    local panel = self.contentPanel
    local numLines = config.MAX_CUSTOM_SHOUTS * 0.5

    local controls = {}
    local nextY = startY

    local categories = { 'callouts', 'sneakcallouts' }
    for i = 1, #categories do
        local category = categories[i]
        local calloutText
        if category == 'callouts' then
            calloutText = getText('UI_OmiChat_ProfileManager_Label_Callouts')
        else
            calloutText = getText('UI_OmiChat_ProfileManager_Label_SneakCallouts')
        end

        local label = UI.label {
            parent = panel,
            x = CONTENT_PAD_X,
            y = nextY,
            h = LABEL_H,
            text = calloutText,
            font = CONTROL_FONT,
        }

        local control = UI.textEntry {
            parent = panel,
            x = CONTENT_PAD_X,
            y = label:getBottom(),
            w = panel.width - CONTENT_PAD_X * 2,
            h = FONT_H_MEDIUM * numLines + 4,
            font = CONTROL_FONT,
            tooltip = getText('UI_OmiChat_ProfileManager_Tooltip_Callouts'),
            maxLines = numLines,
            forceUppercase = category == 'callouts',
        }

        control:setValidateFunction(control, self._validateCustomCalloutText)
        control:setOnChange(self, self.onCalloutsChange, control, category)

        controls[category] = control
        nextY = control:getBottom() + CONTROL_PAD_Y
    end

    return controls, nextY
end

---Creates the labels and controls for chat colors.
---@param startY number
---@return table<string, omi.ui.ColorEntry> controls
---@return number maxY
---@protected
function ProfileManager:_createColorControls(startY)
    local panel = self.contentPanel
    local controls = {}

    local nextY = startY
    local maxY = startY

    local availableColorOpts = API.ui.getColorOptions()
    local splitIdx = math.ceil(#availableColorOpts * 0.5)
    local controlW = panel.width * 0.5 - CONTENT_PAD_X * 2

    for i = 1, #availableColorOpts do
        local opt = availableColorOpts[i]
        local displayCommand = API.streams.getDisplayCommand(opt)
        local labelText = getTextOrNull('UI_OmiChat_ContextColor_' .. opt)
        if not labelText then
            labelText = getText('UI_OmiChat_ContextColor', displayCommand)
        end

        local leftCol = i <= splitIdx
        local x = leftCol and CONTENT_PAD_X or (controlW + CONTENT_PAD_X * 2)

        local tooltip = getTextOrNull('UI_OmiChat_ProfileManager_Tooltip_Color_' .. opt)
        if not tooltip then
            local optName = getTextOrNull('UI_OmiChat_ContextMessageType_' .. opt) or displayCommand
            tooltip = getText('UI_OmiChat_ProfileManager_Tooltip_Color', optName)
        end

        local label = UI.label {
            parent = panel,
            x = x,
            y = nextY,
            h = LABEL_H,
            text = labelText,
            font = CONTROL_FONT,
        }

        local control = UI.colorEntry {
            parent = panel,
            text = '',
            x = x,
            y = label:getBottom(),
            w = controlW,
            h = LABEL_H,
            font = CONTROL_FONT,
            minValue = opt == 'speech' and 48 or 0,
            tooltip = tooltip,
        }

        control:setOnChange(self, self.onColorChange, control, opt)

        nextY = control:getBottom() + CONTROL_PAD_Y
        maxY = math.max(maxY, nextY)
        if i == splitIdx then
            nextY = startY
        end

        controls[opt] = control
    end

    return controls, maxY
end

---Updates the state of controls.
---@protected
function ProfileManager:_updateControlState()
    local selectedProfile = self.profiles[self.listbox.selected]
    if not selectedProfile then
        return
    end

    self.current = selectedProfile
    self.profileNameControl:setText(self.current.name)

    if self.nicknameControl then
        self.nicknameControl:setText(self.current.chatNickname)
    end

    for k, control in pairs(self.colorControls) do
        control:setEmptyColor(API.player.getDefaultColor(k))

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
---@protected
function ProfileManager:_updateListboxText(idx, text)
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
---@protected
function ProfileManager:_updateUIState(resetItems, selectIdx)
    local panel = self.contentPanel
    local listbox = self.listbox
    local emptyLabel = self.emptyLabel
    local createBtn = self.createBtn
    local dupBtn = self.duplicateBtn

    if resetItems then
        listbox:clear()
        for i = 1, #self.profiles do
            self:_addListboxItem(self.profiles[i])
        end
    end

    if selectIdx and #self.listbox.items > 0 then
        self.listbox.selected = math.min(selectIdx, #self.listbox.items)
    end

    local addEnabled = #self.profiles < config.MAX_PROFILES
    local addTooltip = not addEnabled and getText('UI_OmiChat_ProfileManager_MaxProfiles') or nil
    createBtn:setEnable(addEnabled)
    createBtn:setTooltip(addTooltip)

    if dupBtn then
        dupBtn:setEnable(addEnabled)
        dupBtn:setTooltip(addTooltip)
    end

    if #self.profiles == 0 then
        panel:setVisible(false)
        listbox:setVisible(false)
        emptyLabel:setVisible(true)
        createBtn:setTitle(self.createText)
        createBtn:setX((self.width - createBtn.width) * 0.5)
        createBtn:setY((self.height - createBtn.height) * 0.5)
        return
    end

    panel:setVisible(true)
    listbox:setVisible(true)
    emptyLabel:setVisible(false)
    createBtn:setTitle(self.addText)
    createBtn:setX(listbox.x + (listbox.width - createBtn.width) * 0.5)
    createBtn:setY(self.height - 10 - math.max(25, FONT_H_SMALL + 6))
    self:_updateControlState()
end


---Creates a new panel for managing profiles.
---@param args omichat.Args.ProfileManager
---@return omichat.ProfileManager
function ProfileManager:new(args)
    local this = UI.Panel.new(self, args) --[[@as omichat.ProfileManager]]

    this.moveWithMouse = true
    this.deletedCurrentProfile = false
    this.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    this.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    this.profiles = ProfileManager._cloneProfiles(args.profiles, true)
    this.colorControls = {}
    this.calloutControls = {}

    this.addText = getText('UI_OmiChat_ProfileManager_AddButton')
    this.createText = getText('UI_OmiChat_ProfileManager_CreateButton')

    return this
end


API.ProfileManager = ProfileManager
return ProfileManager
