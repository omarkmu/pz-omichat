---Override to correct info text on tab panel activation.

require 'ISUI/ISTabPanel'
local API = require 'OmiChat/Client'

---@class omichat.ISTabPanel : ISTabPanel
local ISTabPanel = ISTabPanel

local ISTabPanel_activateView = ISTabPanel.activateView


---Override to correct info text when changing tabs.
---@param viewName string
function ISTabPanel:activateView(viewName)
    ISTabPanel_activateView(self, viewName)

    local instance = ISChat.instance
    if instance and self:getParent() == instance then
        API.ui.updateInfoText()
    end
end
