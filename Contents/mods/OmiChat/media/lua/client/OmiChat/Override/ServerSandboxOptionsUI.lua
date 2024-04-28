---Handles overriding the server settings screen to customize the sandbox settings page.

local OmiChat = require 'OmiChatClient'
local layout = require 'OmiChat/Definition/OptionLayout'
local utils = OmiChat.utils
local Option = OmiChat.Option
local ColorEntry = OmiChat.ValidatedColorEntry

---@class omichat.ISServerSandboxOptionsUI : ISServerSandboxOptionsUI
local ISServerSandboxOptionsUI = ISServerSandboxOptionsUI

local _createPanel = ISServerSandboxOptionsUI.createPanel

---Transforms the sandbox option panel.
---@param panel ISPanel Panel containing controls.
---@param page table Settings table.
---@param parent ISPanelJoypad
---@return ISPanel
local function transformPanel(panel, page, parent)
    local settingByName = {}
    local translatedToName = {}
    for i = 1, #page.settings do
        local setting = page.settings[i]
        translatedToName[setting.translatedName] = setting.name
        settingByName[setting.name] = setting
    end

    local labels = {}
    for _, child in pairs(panel:getChildren()) do
        local name = child.Type == 'ISLabel' and translatedToName[child.name]
        if name then
            labels[name] = child
        end
    end

    local controlFont = UIFont.Small
    local headingFont = UIFont.Medium

    local txtMgr = getTextManager()
    local fontH = txtMgr:getFontHeight(controlFont)
    local controlPadY = fontH + 4
    local headingH = txtMgr:getFontHeight(headingFont)
    local settingX = 20
    local nextY = 12

    for i = 1, #layout do
        local el = layout[i]

        local padY = 0
        if type(el) == 'string' then
            local name = 'OmiChat.' .. el
            local control = panel.controls[name]
            local label = labels[name]
            local setting = settingByName[name]
            if control and label and setting then
                label.keepOnScreen = false
                control.keepOnScreen = false

                if setting.type == 'checkbox' then
                    control:setX(settingX)
                    control:setY(nextY)
                    label:setX(settingX + control.boxSize + 5)
                    label:setY(nextY + 1)
                    padY = controlPadY + 8
                elseif utils.startsWith(el, 'Color') then
                    label:setY(nextY)
                    label:setX(settingX)

                    local oldControl = control
                    control = ColorEntry:new {
                        x = settingX,
                        y = nextY + label:getHeight(),
                        w = control.width,
                        h = control.height,
                        font = controlFont,
                        emptyColor = Option:getOptionDefaultColor(el),
                        tooltipText = oldControl.tooltip,
                        anchorRight = false,
                        anchorBottom = false,
                    }

                    control:initialise()

                    panel:addChild(control)
                    padY = label:getHeight() + control:getHeight() + 8

                    panel.controls[name] = control
                    parent.controls[name] = control
                    panel:removeChild(oldControl)
                else
                    label:setY(nextY)
                    label:setX(settingX)
                    control:setX(settingX)
                    control:setY(nextY + label:getHeight())

                    -- special case
                    if el == 'FormatInfo' then
                        control:setMultipleLine(true)
                        control:setMaxLines(50)
                        control:addScrollBars()
                        control:setHeight(fontH * 10 + 8)
                    end

                    padY = label:getHeight() + control:getHeight() + 8
                    if setting.type == 'string' and not setting.onlyNumbers then
                        control:setWidth(panel.MAX_WIDTH - settingX * 2)
                    end
                end
            end
        elseif el.type == 'heading' then
            local text = el.text
            if i > 1 then
                nextY = nextY + 16
            end

            local headingX = panel.MAX_WIDTH / 2 - txtMgr:MeasureStringX(headingFont, text) / 2
            local headingLabel = ISLabel:new(headingX, nextY, headingH, text, 1, 1, 1, 1, headingFont, true)
            panel:addChild(headingLabel)
            padY = headingH + 8
        elseif el.type == 'padding' then
            padY = el.pad or 16
        end

        nextY = nextY + padY
    end

    -- fix text drawing over scrollbar
    if panel.vscroll then
        panel.vscroll.doSetStencil = false
    end

    panel:setScrollHeight(nextY + 8)
    return panel
end

---Override to improve the admin sandbox options menu.
---@param page table
---@return ISPanel
function ISServerSandboxOptionsUI:createPanel(page)
    if page.name ~= getText('Sandbox_OmiChat') then
        return _createPanel(self, page)
    end

    if isDebugEnabled() then
        for i = 1, #page.settings do
            local setting = page.settings[i]
            local name = setting.name:sub((setting.name:find('%.') or 0) + 1)
            local tooltip = setting.tooltip
            local tooltipExtra = 'Option=' .. name

            if tooltip then
                setting.tooltip = tooltip .. ' <LINE> ' .. tooltipExtra
            else
                setting.tooltip = tooltipExtra
            end
        end
    end

    local panel = _createPanel(self, page)
    return transformPanel(panel, page, self)
end
