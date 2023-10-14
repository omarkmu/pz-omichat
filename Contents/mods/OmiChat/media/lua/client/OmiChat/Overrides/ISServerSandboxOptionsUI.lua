---Handles overriding the server settings screen to customize the sandbox settings page.
require 'ISUI/AdminPanel/ISServerSandboxOptionsUI'

local max = math.max


---@class omichat.ISServerSandboxOptionsUI : ISServerSandboxOptionsUI
local ISServerSandboxOptionsUI = ISServerSandboxOptionsUI

local _createPanel = ISServerSandboxOptionsUI.createPanel

---Override to correct label and control positions.
---@param page table
---@return ISPanel
function ISServerSandboxOptionsUI:createPanel(page)
    local panel = _createPanel(self, page)
    if page.name ~= getText('Sandbox_OmiChat') then
        return panel
    end

    local translatedToName = {}
    for i = 1, #page.settings do
        local setting = page.settings[i]
        translatedToName[setting.translatedName] = setting.name
    end

    local labels = {}
    for _, child in pairs(panel:getChildren()) do
        local isLabel = child.Type == 'ISLabel'
        local name = isLabel and translatedToName[child.name]
        if name then
            labels[name] = child
        end
    end

    local y = 12
    for i = 1, #panel.settingNames do
        local name = panel.settingNames[i]

        local label = labels[name]
        local control = panel.controls[name]

        if not label or not control then
            break
        end

        label.keepOnScreen = false
        control.keepOnScreen = false

        label:setY(y)
        control:setY(y)

        y = y + max(label:getHeight(), control:getHeight()) + 6
    end

    panel:setScrollHeight(y)
    return panel
end
