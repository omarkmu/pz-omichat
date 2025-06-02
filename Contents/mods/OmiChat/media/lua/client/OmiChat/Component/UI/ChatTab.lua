---UI element for the chat rich text panel.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client
local RichTextPanel = API.utils.ui.RichTextPanel

---@class omichat.ChatTab
local ChatTab = RichTextPanel:derive('OmiChatTab')


---Creates a new chat tab panel.
---@param args omi.ui.InitArgs.RichTextPanel
---@return omichat.ChatTab
function ChatTab:new(args)
    local this = RichTextPanel.new(self, args) ---@cast this omichat.ChatTab

    this.tabID = 0
    this.streamID = 0
    this.logIndex = 0

    this.lastChatCommand = ''
    this.tabTitle = ''
    this.log = {}
    this.chatTextLines = {}
    this.chatMessages = {}
    this.chatStreams = {}

    return this
end


API.ChatTab = ChatTab
return ChatTab
