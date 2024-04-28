local TextEntry = require 'OmiChat/Component/ValidatedTextEntry'
local ColorEntry = require 'OmiChat/Component/ValidatedColorEntry'
local OmiChat = require 'OmiChatClient'
local Option = OmiChat.Option

local ISLabel = ISLabel
local ISChat = ISChat ---@cast ISChat omichat.ISChat

---Content panel for profile manager.
---@class omichat.ProfileManagerContent : ISPanelJoypad
local ContentPanel = ISPanelJoypad:derive('ProfileManagerContent')

local textManager = getTextManager()
local FONT = UIFont.Medium
local FONT_H = textManager:getFontHeight(FONT)
local FONT_H_SMALL = textManager:getFontHeight(FONT)
local PAD_X = 20
local PAD_Y = 10
local CONTROL_PAD_Y = 5
local SECTION_PAD_Y = 20
local LABEL_H = FONT_H + 4


---Adds the label and control elements.
---@param manager omichat.ProfileManager
function ContentPanel:addControls(manager)
    local controlW = self.width / 2 - PAD_X * 2

    -- profile name
    local nameText = getText('UI_OmiChat_ProfileManager_Label_ProfileName')
    local nameLabel = ISLabel:new(PAD_X, PAD_Y, LABEL_H, nameText, 1, 1, 1, 1, FONT, true)
    nameLabel:initialise()

    local nameControlY = nameLabel.y + nameLabel.height
    local nameControl = TextEntry:new {
        x = PAD_X,
        y = nameControlY,
        w = controlW,
        h = LABEL_H,
        font = FONT,
        minLength = 1,
        maxLength = 50,
    }

    nameControl:setOnChange(manager, manager.onProfileNameChange, nameControl)
    nameControl:initialise()

    manager.profileNameControl = nameControl
    self:addChild(nameLabel)
    self:addChild(nameControl)

    local startY = nameControl.y + nameControl.height + CONTROL_PAD_Y

    -- chat nickname
    if Option:isNicknameEnabled() then
        local nicknameText = getText('UI_OmiChat_ProfileManager_Label_Nickname')
        local nicknameLabel = ISLabel:new(PAD_X, startY, LABEL_H, nicknameText, 1, 1, 1, 1, FONT, true)
        nicknameLabel:initialise()

        local nicknameControlY = nicknameLabel.y + nicknameLabel.height
        local nicknameControl = TextEntry:new {
            x = PAD_X,
            y = nicknameControlY,
            w = controlW,
            h = LABEL_H,
            font = FONT,
            tooltipText = getText('UI_OmiChat_ProfileManager_Tooltip_Nickname'),
        }

        nicknameControl:setValidateFunction(nicknameControl, OmiChat.validateNicknameText)
        nicknameControl:setOnChange(manager, manager.onNicknameChange, nicknameControl)
        nicknameControl:initialise()

        manager.nicknameControl = nicknameControl
        self:addChild(nicknameLabel)
        self:addChild(nicknameControl)

        startY = nicknameControl.y + nicknameControl.height + CONTROL_PAD_Y
    end

    self:createButtons(manager)

    -- colors
    local nextY = startY + SECTION_PAD_Y
    local maxY = nextY

    manager.colorControls, maxY = self:createColorControls(manager, nextY)

    -- callouts
    if Option.EnableCustomShouts then
        manager.calloutControls, maxY = self:createCalloutControls(manager, maxY + SECTION_PAD_Y)
    else
        manager.calloutControls = {}
    end

    self:setScrollHeight(maxY + PAD_Y)
end

---Adds buttons to the content panel.
---@param manager omichat.ProfileManager
function ContentPanel:createButtons(manager)
    local btnX = self.width / 2
    local btnWidth = self.width / 4 - PAD_X * 2
    local btnHgt = math.max(25, FONT_H_SMALL + 6)
    local btnY = PAD_Y + LABEL_H

    local deleteText = getText('UI_OmiChat_ProfileManager_DeleteButton')
    local deleteBtn = ISButton:new(btnX, btnY, btnWidth, btnHgt, deleteText, manager, manager.deleteProfile)
    deleteBtn.borderColor.a = 0.5
    deleteBtn.internal = 'DELETE'
    deleteBtn:initialise()
    deleteBtn:instantiate()

    local copyText = getText('UI_OmiChat_ProfileManager_CopyButton')
    local copyX = btnX + btnWidth + PAD_X
    local copyBtn = ISButton:new(copyX, btnY, btnWidth, btnHgt, copyText, manager, manager.copyFromCurrent)
    copyBtn.borderColor.a = 0.5
    copyBtn.internal = 'COPY'
    copyBtn:initialise()
    copyBtn:instantiate()

    manager.deleteButton = deleteBtn
    manager.copyButton = copyBtn

    self:addChild(deleteBtn)
    self:addChild(copyBtn)
end

---Creates the labels and controls for callout text.
---@param manager omichat.ProfileManager
---@param startY number
---@return table<string, omichat.ValidatedTextEntry>
---@return number
function ContentPanel:createCalloutControls(manager, startY)
    local numLines = Option.MaximumCustomShouts
    if numLines <= 0 then
        numLines = Option:getDefault('MaximumCustomShouts') or 1
    elseif numLines > 20 then
        numLines = 20
    end

    local controls = {}
    local nextY = startY
    local maxY = startY

    local categories = { 'callouts', 'sneakcallouts' }
    for i = 1, #categories do
        local category = categories[i]
        local calloutText
        if category == 'callouts' then
            calloutText = getText('UI_OmiChat_ProfileManager_Label_Callouts')
        else
            calloutText = getText('UI_OmiChat_ProfileManager_Label_SneakCallouts')
        end

        local label = ISLabel:new(PAD_X, nextY, LABEL_H, calloutText, 1, 1, 1, 1, FONT, true)
        label:initialise()
        self:addChild(label)

        local controlY = label.y + label.height
        local controlH = FONT_H * numLines + 4
        local control = TextEntry:new {
            x = PAD_X,
            y = controlY,
            w = self.width - PAD_X * 2,
            h = controlH,
            font = FONT,
            tooltipText = getText('UI_OmiChat_ProfileManager_Tooltip_Callouts'),
            maxLines = numLines,
        }

        control:setValidateFunction(control, ISChat.validateCustomCalloutText)
        control:setOnChange(manager, manager.onCalloutsChange, control, category)
        control:initialise()
        self:addChild(control)

        if category == 'callouts' then
            control:setForceUpperCase(true)
        end

        controls[category] = control
        nextY = control.y + control.height + CONTROL_PAD_Y
        maxY = math.max(maxY, nextY)
    end

    return controls, maxY
end

---Creates the labels and controls for chat colors.
---@param manager omichat.ProfileManager
---@param startY number
---@return table<string, omichat.ValidatedColorEntry> controls
---@return number maxY
function ContentPanel:createColorControls(manager, startY)
    local controls = {}

    local nextY = startY
    local maxY = nextY
    local columnTopY = nextY
    local availableColorOpts = OmiChat.getColorOptions()
    local splitIdx = math.ceil(#availableColorOpts / 2)
    local controlW = self.width / 2 - PAD_X * 2

    for i = 1, #availableColorOpts do
        local opt = availableColorOpts[i]
        local labelText = getTextOrNull('UI_OmiChat_ContextColor_' .. opt)
        if not labelText then
            labelText = getText('UI_OmiChat_ContextColor', OmiChat.getColorCategoryCommand(opt))
        end

        local leftCol = i <= splitIdx
        local x = leftCol and PAD_X or (controlW + PAD_X * 2)

        local tooltip = getTextOrNull('UI_OmiChat_ProfileManager_Tooltip_Color_' .. opt)
        if not tooltip then
            local optName = getTextOrNull('UI_OmiChat_ContextMessageType_' .. opt)
                or OmiChat.getColorCategoryCommand(opt)
            tooltip = getText('UI_OmiChat_ProfileManager_Tooltip_Color', optName)
        end

        local label = ISLabel:new(x, nextY, LABEL_H, labelText, 1, 1, 1, 1, FONT, true)
        local control = ColorEntry:new {
            text = '',
            x = x,
            y = label.y + label.height,
            w = controlW,
            h = LABEL_H,
            font = FONT,
            minValue = opt == 'speech' and 48 or 0,
            tooltipText = tooltip,
        }

        control:setOnChange(manager, manager.onColorChange, control, opt)
        control:initialise()

        nextY = control.y + control.height + CONTROL_PAD_Y
        maxY = math.max(maxY, nextY)
        if i == splitIdx then
            nextY = columnTopY
        end

        self:addChild(label)
        self:addChild(control)
        controls[opt] = control
    end

    return controls, maxY
end

---Event handler for mouse scroll.
---@param delta number
---@return boolean?
function ContentPanel:onMouseWheel(delta)
    if self:getScrollHeight() <= 0 then
        return
    end

    self:setYScroll(self:getYScroll() - (delta * 40))
    return true
end

---Prerender function to limit content to within the panel bounds.
function ContentPanel:prerender()
    ISPanelJoypad.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

---Render function to clear the stencil rect.
function ContentPanel:render()
    ISPanelJoypad.render(self)
    self:clearStencilRect()
end

---Creates the content panel.
---@param x any
---@param y any
---@param width any
---@param height any
---@return omichat.ProfileManagerContent
function ContentPanel:new(x, y, width, height)
    local o = ISPanelJoypad.new(self, x, y, width, height)

    ---@cast o omichat.ProfileManagerContent
    return o
end


return ContentPanel
