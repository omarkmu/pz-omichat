---Provides client API access to OmiChat.
---Includes utilities for interfacing with the chat and extending mod functionality.
---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Base'

require 'OmiChat/API/Data'
require 'OmiChat/API/Chat'

---Function to retrieve a playable emote string given an emote name.
---@alias omichat.EmoteGetter fun(emoteName: string): string?

---Categories for custom callouts.
---@alias omichat.CalloutCategory 'callouts' | 'sneakcallouts'

---Categories for colors that can be customized by players.
---@alias omichat.ColorCategory
---| omichat.CustomStreamName
---| 'general'
---| 'say'
---| 'shout'
---| 'faction'
---| 'safehouse'
---| 'radio'
---| 'admin'
---| 'server'
---| 'private'
---| 'discord'
---| 'name'
---| 'speech'

---Valid values for the chat's font.
---@alias omichat.ChatFont 'small' | 'medium' | 'large'


---Metadata that can be attached to a message.
---@class omichat.MessageMetadata
---@field name string?
---@field nameColor omichat.ColorTable?

---Options for how to format a message in chat.
---@class omichat.MessageFormatOptions
---@field showInChat boolean
---@field showTitle boolean
---@field showTimestamp boolean
---@field useChatColor boolean
---@field useNameColor boolean
---@field stripColors boolean
---@field font omichat.ChatFont
---@field color omichat.ColorTable?

---Information used during message transformation and formatting.
---@class omichat.MessageInfo
---@field message ChatMessage
---@field content string? The message content to display in chat. Set by transformers.
---@field format string? The string format to use for the message. Set by transformers.
---@field tag string?
---@field timestamp string?
---@field textColor Color The message's default text color.
---@field meta omichat.MessageMetadata
---@field rawText string The raw text of the message.
---@field author string The username of the message author.
---@field titleID string The string ID of the chat type's tag.
---@field chatType omichat.ChatTypeString The chat type of the message's chat.
---@field context table Table for arbitrary context data.
---@field substitutions table<string, any> Message substitution values.
---@field formatOptions omichat.MessageFormatOptions

---Transforms messages based on context and format strings.
---@class omichat.MessageTransformer
---@field name string?
---@field transform fun(self: table, info: omichat.MessageInfo): true?
---@field priority integer?

---Description of the `omichat` field on stream tables.
---@class omichat.BaseStreamConfig
---@field context table?
---@field isCommand boolean? Field added to signify that a stream is a command.
---@field isEnabled (fun(self: table): boolean)? Returns a boolean representing whether the stream is enabled.
---@field onUse fun(self: table, command: string)? Callback triggered when the stream is used.
---@field allowEmotes boolean? Whether to allow emotes on this stream. Defaults to true for non-commands and false for commands.
---@field allowEmojiPicker boolean? Whether to enable the emoji button for this stream. Defaults to false.
---@field allowRetain boolean? Whether to allow retaining this stream's command for subsequent inputs. Defaults to true for non-commands and false for commands.

---Description of the `omichat` field on chat stream tables.
---@class omichat.ChatStreamConfig : omichat.BaseStreamConfig

---Description of the `omichat` field on command stream tables.
---@class omichat.CommandStreamConfig : omichat.BaseStreamConfig
---@field helpText string? Summary of the command's purpose. Displays when the /help command is used.
---@field onHelp fun(self: table)? Callback triggered when /help is used with this command.

---Base stream object for chat and command streams.
---@class omichat.BaseStream
---@field name string
---@field command string
---@field shortCommand string?
---@field omichat omichat.ChatStreamConfig?

---A stream used for communicating in chat.
---@class omichat.ChatStream : omichat.BaseStream
---@field tabID integer

---A stream used to invoke a command in chat.
---@class omichat.CommandStream : omichat.BaseStream
---@field omichat omichat.CommandStreamConfig

---Player preferences.
---@class omichat.PlayerPreferences
---@field showNameColors boolean
---@field callouts string[]
---@field sneakcallouts string[]
---@field colors table<omichat.ColorCategory, omichat.ColorTable>

return OmiChat
