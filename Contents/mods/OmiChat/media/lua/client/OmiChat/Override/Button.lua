---Overrides for custom buttons.

require 'ISUI/ISButton'
local OmiChat = require 'OmiChatClient'

---@class omichat.ISButton : ISButton
local ISButton = ISButton

local ISButton_setVisible = ISButton.setVisible


---Override to update custom buttons when a chat button's visibility changes.
---@param bVisible boolean
function ISButton:setVisible(bVisible)
    ISButton_setVisible(self, bVisible)

    local instance = ISChat.instance
    if instance and self:getParent() == instance then
        OmiChat.updateButtons()
    end
end
