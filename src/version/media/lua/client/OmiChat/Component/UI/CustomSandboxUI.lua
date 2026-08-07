---Custom UI for the sandbox options menu.
---@namespace omichat

local API = require 'OmiChat/Module/Core/Client'

local utils = API.utils
local UI_LIB = utils.ui
local UI = API.ui
local getText = utils.getText
local getAttr = utils.getAttr

---@class CustomSandboxUI : omi.Panel
local CustomSandboxUI = UI_LIB.Panel:derive('CustomSandboxUI')

---Adds a button to open the configuration form.
function CustomSandboxUI:createChildren()
    local button = UI_LIB.button {
        parent = self,
        x = 20,
        y = 20,
        font = UIFont.Small,
        minWidth = 30,
        setWidthToText = true,
        text = getText('context-admin-open-settings'),
        tooltip = getAttr('context-admin-open-settings', 'sandbox-tooltip'),
        anchorLeft = true,
        anchorRight = true,
        anchorTop = true,
        anchorBottom = true,
        onClick = function() UI.openConfiguration() end,
    }

    button:setX((self.width - button:getWidth()) * 0.5)
    button:setY((self.height - button:getHeight()) * 0.5)
end


---Creates a new instance of the custom UI.
---@param x number
---@param y number
---@param w number
---@param h number
function CustomSandboxUI:new(x, y, w, h)
    return UI_LIB.new(self, UI_LIB.Panel.new, {
        x = x,
        y = y,
        w = w,
        h = h,
    })
end


return CustomSandboxUI
