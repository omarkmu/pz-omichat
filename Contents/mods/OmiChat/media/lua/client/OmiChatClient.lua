---Provides client API access to OmiChat.
---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
OmiChat._commandStreams = require 'OmiChat/Definition/CommandStreams'
OmiChat._suggesters = require 'OmiChat/Definition/Suggesters'
OmiChat._transformers = require 'OmiChat/Definition/Transformers'

require 'OmiChat/API/ClientChat'
require 'OmiChat/API/ClientData'
require 'OmiChat/API/ClientCommands'
require 'OmiChat/API/ClientExtension'
require 'OmiChat/API/ClientFormat'
require 'OmiChat/API/ClientSearch'

Events.OnGameStart.Add(OmiChat._onGameStart)
Events.OnCreatePlayer.Add(OmiChat._onCreatePlayer)
Events.OnPlayerDeath.Add(OmiChat._onPlayerDeath)
Events.OnServerCommand.Add(OmiChat._onServerCommand)
Events.OnReceiveGlobalModData.Add(OmiChat._onReceiveGlobalModData)

return OmiChat


---@alias omichat.ChatCommandType 'chat' | 'rp' | 'other'
---@alias omichat.ChatFont 'small' | 'medium' | 'large'
---@alias omichat.SettingCategory 'basic' | 'chat_customization' | 'character_customization' | 'language' | 'admin' | 'main'
---@alias omichat.SettingHandlerCallback fun(submenu: ISContextMenu)
---@alias omichat.Message ChatMessage | omichat.MimicMessage

---@alias omichat.SuggestionType
---| 'online-username'
---| 'online-username-with-self'
---| 'language'
---| 'known-language'
---| 'perk'
---| 'option'
---| '?'

---@alias omichat.SuggestArgSpec omichat.SuggestArgSpecTable | omichat.SuggestionType | string
---@alias omichat.SuggestSpec omichat.SuggestArgSpec[]
---@alias omichat.SuggestSearchCallback fun(ctx: omichat.SearchContext | string, spec: omichat.SuggestArgSpec): omichat.SearchResults?

---@class omichat.SuggestArgSpecTable
---@field type omichat.SuggestionType | string The type of the argument.
---@field prefix string? A prefix to apply to the suggestion result.
---@field suffix string? A suffix to apply to the suggestion result.
---@field options string[]? String options for the `string` suggestion type.
---@field searchDisplay boolean? If true, the display string will be used for determining suggestions.
---@field filter (fun(result: unknown, args: string[]): boolean)|nil Filter function for results.
---@field display (fun(value: unknown, str: string): string?)|nil Function to retrieve display strings for results.

---Metadata that can be attached to a message.
---@class omichat.MessageMetadata
---@field language string? The roleplay language in which the message was sent.
---@field name string? The name of the author when this message was sent.
---@field icon string? The user's icon when this message was sent.
---@field adminIcon string? The admin icon when this message was sent, if it was enabled.
---@field nameColor omichat.ColorTable? The name color of the author when this message was sent.
---@field recipientNameColor omichat.ColorTable? The name color of the recipient when this message was sent.
---@field suppressed boolean? Whether the overhead text for this message has already been suppressed.

---Options for how to format a message in chat.
---@class omichat.MessageFormatOptions
---@field showTitle boolean Whether the message will include the chat type tag.
---@field showTimestamp boolean Whether the message will include a timestamp.
---@field useDefaultChatColor boolean Whether the default color associated with the chat type will be used if no color is specified.
---@field font omichat.ChatFont The font size of the message.
---@field color omichat.ColorTable? The message color.

---Information used during message transformation and formatting.
---@class omichat.MessageInfo
---@field message omichat.Message The message object.
---@field attractRange integer? The range at which the message will be heard by zombies.
---@field content string? The message content to display in chat. Set by transformers.
---@field format string? The string format to use for the message. Set by transformers.
---@field tag string? The result of the `FormatTag` option.
---@field timestamp string? The result of the `FormatTimestamp` option.
---@field language string? The result of the `FormatLanguage` option.
---@field textColor Color The message's default text color.
---@field meta omichat.MessageMetadata Metadata attached to the message.
---@field rawText string The raw text of the message. This should not be modified.
---@field author string The username of the message author.
---@field titleID string The string ID of the chat type's tag.
---@field chatType omichat.ChatTypeString The chat type of the message's chat.
---@field context table Table for arbitrary context data.
---@field tokens table<string, unknown> Token substitution values.
---@field formatOptions omichat.MessageFormatOptions Formatting options to apply to the message.

---A suggestion that can display to the player.
---@class omichat.Suggestion
---@field type string Deprecated (unused); will be removed in version 2.0. Suggestion category.
---@field display string The text that will display in the menu.
---@field suggestion string Text that will replace the input text if the suggestion is selected.

---Information used during suggestion building.
---@class omichat.SuggestionInfo
---@field input string The current input text.
---@field context table Table for arbitrary context data.
---@field suggestions omichat.Suggestion[] The current list of suggestions.

---Transforms messages based on context and format strings.
---@class omichat.MessageTransformer
---@field name string? The name of the transformer.
---@field transform fun(self: table, info: omichat.MessageInfo): true? Performs message transformation.
---@field priority integer? The priority of the transformer. Higher numbers will run first.

---Suggests message content based on text input.
---@class omichat.Suggester
---@field name string? The name of the suggester.
---@field suggest fun(self: table, info: omichat.SuggestionInfo) Performs suggestion.
---@field priority integer? The priority of the suggester. Higher numbers will run first.

---Context for sending chat messages.
---@class omichat.SendArgs
---@field text string
---@field icon string?
---@field command string? Deprecated. Contains the same information as `text`.
---@field streamName string?
---@field stream omichat.StreamInfo?
---@field playSignedEmote boolean?
---@field isEcho boolean?
---@field formatterName omichat.FormatterName?
---@field tokens table?

---Argument table passed to `formatForChat`.
---@see omichat.api.client.formatForChat
---@class omichat.FormatArgs
---@field text string
---@field icon string?
---@field language string?
---@field isEcho boolean?
---@field formatterName omichat.FormatterName?
---@field stream string?
---@field chatType omichat.ChatTypeString
---@field name string?
---@field username string?
---@field tokens table?

---Result of `formatForChat`.
---@see omichat.api.client.formatForChat
---@class omichat.FormatResult
---@field text string
---@field error string?
---@field allowLanguage boolean?

---@class omichat.BaseStreamConfig
---@field aliases string[]? Additional aliases for the command.
---@field commandType omichat.ChatCommandType? The command type used to determine whether input should be retained.
---@field chatType string? The chat type associated with the stream.
---@field isCommand boolean? Indicates that the stream is a command.
---@field suggestUsernames boolean? Deprecated; will be removed in version 2.0. Use `suggestSpec` instead.
---@field suggestOwnUsername boolean? Deprecated; will be removed in version 2.0. Use `suggestSpec` instead.
---@field suggestSpec omichat.SuggestSpec? The spec for suggestions to the stream.
---@field isEnabled (fun(self: omichat.StreamInfo): boolean)? Returns a boolean representing whether the stream is enabled.
---@field onUse fun(ctx: omichat.SendArgs)? Callback triggered when the stream is used.
---@field allowEmotes boolean? Whether to allow emotes on this stream. Defaults to true for non-commands and false for commands.
---@field allowIconPicker boolean? Whether to enable the icon button for this stream. Defaults to false.
---@field streamIdentifier string? The stream identifier tied to this stream. Used for format strings and determining roleplay language. Defaults to stream name.
---@field validator (fun(self: omichat.StreamInfo, input: string): boolean)?

---@class omichat.ChatStreamConfig : omichat.BaseStreamConfig
---@field isLocalWhisper boolean?
---@field isEnabledCommand string? The command to pass to checkPlayerCanUseChat to determine whether the stream is enabled.
---@field formatter string?

---@class omichat.CommandStreamConfig : omichat.BaseStreamConfig
---@field helpText string? String ID of a summary of the command's purpose. Displays when the /help command is used.
---@field onHelp fun(self: omichat.StreamInfo)? Callback triggered when /help is used with this command.

---@class omichat.BaseStream
---@field name string The name of the stream.
---@field command string The stream command, with a trailing space.
---@field shortCommand string? An optional short stream command, with a trailing space.

---A stream used for communicating in chat.
---@class omichat.ChatStream : omichat.BaseStream
---@field omichat omichat.ChatStreamConfig? Additional configuration options.
---@field tabID integer The tab ID of the tab in which this stream is available (1-indexed).

---A stream used to invoke a command in chat.
---@class omichat.CommandStream : omichat.BaseStream
---@field omichat omichat.CommandStreamConfig Additional configuration options.

---@alias omichat.Stream
---| omichat.ChatStream
---| omichat.CommandStream

---Player preferences.
---@class omichat.PlayerPreferences
---@field HIGHER_VERSION boolean Flag that's set when the preferences file had a higher verson than the current version, to avoid bad overwrites.
---@field showNameColors boolean Whether name colors are enabled.
---@field useSuggester boolean Whether suggestions are enabled.
---@field useSignEmotes boolean Whether signed roleplay languages should play a random emote.
---@field callouts string[] Custom callouts.
---@field sneakcallouts string[] Custom sneak callouts.
---@field colors table<omichat.ColorCategory, omichat.ColorTable> Custom chat colors.
---@field retainChatInput boolean Whether to retain chat input for chat streams.
---@field retainRPInput boolean Whether to retain chat input for roleplay streams (/me).
---@field retainOtherInput boolean Whether to retain other chat input.
---@field adminShowIcon boolean Whether the admin icon should display in chat.
---@field adminKnowLanguages boolean Whether all languages should be treated as known.
---@field adminIgnoreRange boolean Whether message range should be ignored.

---Description of a chat tab object.
---@class omichat.ChatTab : ISRichTextPanel
---@field parent omichat.ISChat The parent chat.
---@field logIndex integer The current index in the tab's input history.
---@field tabID integer The tab ID of this tab (0-indexed).
---@field text string The current rich text of the chat tab.
---@field chatStreams omichat.ChatStream[] Chat streams available in this tab.
---@field chatTextLines string[] An array of rich text strings of the current messages.
---@field chatMessages omichat.Message[] Current chat messages.
---@field log string[] The input history of this tab.
---@field tabTitle string The title of this tab.
---@field streamID integer The stream ID of the current stream.
