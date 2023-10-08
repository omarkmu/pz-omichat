---Provides client API access to OmiChat.
---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

require 'OmiChat/API/Chat'
require 'OmiChat/API/ClientData'
require 'OmiChat/API/ClientDispatch'
require 'OmiChat/API/ClientCommands'

Events.OnGameStart.Add(OmiChat._onGameStart)
Events.OnCreatePlayer.Add(OmiChat._onCreatePlayer)
Events.OnServerCommand.Add(OmiChat._onServerCommand)
Events.OnReceiveGlobalModData.Add(OmiChat._onReceiveGlobalModData)

return OmiChat


---Function to retrieve a playable emote string given an emote name.
---@alias omichat.EmoteGetter fun(emoteName: string): string?

---Valid values for the chat's font.
---@alias omichat.ChatFont 'small' | 'medium' | 'large'

---A message type that the mod can handle.
---@alias omichat.Message ChatMessage | omichat.MimicMessage


---Metadata that can be attached to a message.
---@class omichat.MessageMetadata
---@field name string?
---@field nameColor omichat.ColorTable?

---Options for how to format a message in chat.
---@class omichat.MessageFormatOptions
---@field showInChat boolean
---@field showTitle boolean
---@field showTimestamp boolean
---@field useDefaultChatColor boolean
---@field stripColors boolean
---@field font omichat.ChatFont
---@field color omichat.ColorTable?

---Information used during message transformation and formatting.
---@class omichat.MessageInfo
---@field message omichat.Message
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
---@field substitutions table<string, unknown> Token substitution values.
---@field formatOptions omichat.MessageFormatOptions

---A suggestion that can display to the player.
---@class omichat.Suggestion
---@field type string
---@field display string
---@field suggestion string

---Information used during suggestion building.
---@class omichat.SuggestionInfo
---@field input string The current input text.
---@field context table Table for arbitrary context data.
---@field suggestions omichat.Suggestion[] The current list of suggestions.

---Transforms messages based on context and format strings.
---@class omichat.MessageTransformer
---@field name string?
---@field transform fun(self: table, info: omichat.MessageInfo): true?
---@field priority integer?

---Suggests message content based on text input.
---@class omichat.Suggester
---@field name string?
---@field suggest fun(self: table, info: omichat.SuggestionInfo)
---@field priority integer?

---Description of the `omichat` field on stream tables.
---@class omichat.BaseStreamConfig
---@field context table?
---@field isCommand boolean? Field added to signify that a stream is a command.
---@field isEnabled (fun(self: table): boolean)? Returns a boolean representing whether the stream is enabled.
---@field onUse fun(self: table, command: string)? Callback triggered when the stream is used.
---@field allowEmotes boolean? Whether to allow emotes on this stream. Defaults to true for non-commands and false for commands.
---@field allowIconPicker boolean? Whether to enable the icon button for this stream. Defaults to false.
---@field allowRetain boolean? Whether to allow retaining this stream's command for subsequent inputs. Defaults to true for non-commands and false for commands.

---Description of the `omichat` field on chat stream tables.
---@class omichat.ChatStreamConfig : omichat.BaseStreamConfig

---Description of the `omichat` field on command stream tables.
---@class omichat.CommandStreamConfig : omichat.BaseStreamConfig
---@field helpText string? String ID of the summary of the command's purpose. Displays when the /help command is used.
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
---@field useSuggester boolean
---@field callouts string[]
---@field sneakcallouts string[]
---@field colors table<omichat.ColorCategory, omichat.ColorTable>
