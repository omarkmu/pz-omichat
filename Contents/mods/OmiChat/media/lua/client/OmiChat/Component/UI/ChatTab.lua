---UI element for the chat rich text panel.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client
local UI = API.utils.ui

---@class omichat.ChatTab : omi.ui.RichTextPanel
---@field parent omichat.ISChat The parent chat.
---@field logIndex integer The current index in the tab's input history.
---@field tabID integer The 0-indexed tab ID of this tab.
---@field text string The current rich text of the chat tab.
---@field chatStreams (omichat.ChatStream | omichat.StreamTable)[] Chat streams available in this tab.
---@field chatTextLines string[] An array of rich text strings of the current messages.
---@field chatMessages omichat.Message[] Current chat messages.
---@field log string[] The input history of this tab.
---@field tabTitle string The title of this tab.
---@field streamID integer The stream ID of the current stream.
---@field lastChatCommand string The last command input in the chat tab.
local ChatTab = UI.RichTextPanel:derive('ChatTab')


---Creates a new chat tab panel.
---@param args omi.ui.InitArgs.RichTextPanel Arguments for creation of the chat tab.
---@return omichat.ChatTab tab
function ChatTab:new(args)
    local this = UI.RichTextPanel.new(self, args) --[[@as omichat.ChatTab]]

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
