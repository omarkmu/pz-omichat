---UI element for the chat rich text panel.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'
local UI = API.utils.ui

---@class ChatTab : omi.RichTextPanel
---@field parent omichat.ISChat The parent chat.
---@field logIndex integer The current index in the tab's input history.
---@field tabID integer The 0-indexed tab ID of this tab.
---@field text string The current rich text of the chat tab.
---@field chatStreams (ChatStream | StreamTable)[] Chat streams available in this tab.
---@field chatTextLines string[] An array of rich text strings of the current messages.
---@field chatMessages Message[] Current chat messages.
---@field log string[] The input history of this tab.
---@field tabTitle string The title of this tab.
---@field streamID integer The stream ID of the current stream.
---@field lastChatCommand string The last command input in the chat tab.
local ChatTab = UI.RichTextPanel:derive('ChatTab')

---UI element for the chat rich text panel.
API.ChatTab = ChatTab

---Creates a new chat tab panel.
---@param args omi.InitArgs.RichTextPanel Arguments for creation of the chat tab.
---@return ChatTab tab
function ChatTab:new(args)
    local this = UI.new(self, UI.RichTextPanel.new, args)

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


return ChatTab
