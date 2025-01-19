---@alias omichat.ChatCommandType 'chat' | 'rp' | 'other'
---@alias omichat.ChatFont 'small' | 'medium' | 'large'

---@alias omichat.SettingCategory
---| 'basic'
---| 'customization'
---| 'language'
---| 'admin'
---| 'suggestions'
---| 'main'

---@alias omichat.SettingHandlerCallback fun(submenu: ISContextMenu)
---@alias omichat.Message ChatMessage | omi.chat.MimicMessage

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
---@alias omichat.EmoteHandler fun(player: IsoPlayer, emote: string)

---@class omichat.SuggestArgSpecTable
---@field type omichat.SuggestionType | string The type of the argument.
---@field prefix string? A prefix to apply to the suggestion result.
---@field suffix string? A suffix to apply to the suggestion result.
---@field options string[]? String options for the `string` suggestion type.
---@field searchDisplay boolean? If true, the display string will be used for determining suggestions.
---@field filter (fun(result: unknown, args: string[]): boolean)? Filter function for results.
---@field display (fun(value: unknown, str: string): string?)? Function to retrieve display strings for results.

---@class omichat.MessageInfo
---@field message omichat.Message The message object.
---@field tokens table<string, unknown> Token substitution values.
---@field context table Table for arbitrary context data.
---@field content string? The message content to display in chat. Set by transformers.
---@field rawText string The raw text of the message. This should not be modified.
---@field chatType omichat.ChatTypeString The chat type of the message's chat.
---@field format string? The format string to use for the message. Set by transformers.
---@field stream omichat.Stream? The source stream of the message.
---@field originalStream omichat.Stream? The original stream of a radio message.
---@field author string The username of the message author.
---@field zombieAttractRange integer? The range at which the message will be heard by zombies.
---@field protected callout boolean? Whether the stream is a callout.
---@field protected sneakCallout boolean? Whether the stream is a sneak callout.
---@field protected datetime string A string representing the date and time the message was sent.
---@field protected options omichat.MessageInfo.FormatOptions Formatting options to apply to the message.
---@field protected skipLanguage boolean If `true`, language processing will skipped.
---@field protected tag string? The result of the `FormatTag` option.
---@field protected timestamp string? The result of the `FormatTimestamp` option.
---@field protected language string? The result of the `FormatLanguage` option.
---@field protected titleID string The string ID of the chat type's tag.
---@field protected meta omichat.MessageInfo.Metadata Metadata attached to the message.

---@class omichat.MessageInfo.FormatOptions
---@field showTitle boolean Whether the message will include the chat type tag.
---@field showTimestamp boolean Whether the message will include a timestamp.
---@field font omichat.ChatFont The font size of the message.
---@field color omi.ColorTable? The message color.

---@class omichat.MessageInfo.Metadata
---@field language string? The roleplay language in which the message was sent.
---@field name string? The name of the author when this message was sent.
---@field icon string? The user's icon when this message was sent.
---@field adminIcon string? The admin icon when this message was sent, if it was enabled.
---@field nameColor omi.ColorTable? The name color of the author when this message was sent.
---@field recipientNameColor omi.ColorTable? The name color of the recipient when this message was sent.
---@field suppressed boolean? Whether the overhead text for this message has already been suppressed.
---@field stream string? The name of the stream the message was sent over.
---@field originalStream string? The name of the original stream a radio message was sent over.

---A suggestion that can display to the player.
---@class omichat.Suggestion
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
---@class omichat.SendArgs : omichat.SendArgsPartial
---@field stream omichat.Stream

---@class omichat.SendArgsPartial
---@field text string
---@field formatStream omichat.Stream?
---@field playSignedEmote boolean?
---@field echoType integer?
---@field formatter omichat.MetaFormatter?
---@field tokens table?
---@field extraTags string[]?

---Argument table passed to `formatForChat`.
---@class omichat.FormatArgs
---@field text string
---@field stream omichat.ChatStream
---@field formatStream omichat.Stream?
---@field chatType omichat.ChatTypeString
---@field language string?
---@field echoType integer?
---@field formatter omichat.MetaFormatter?
---@field name string?
---@field username string?
---@field tokens table?
---@field extraTags string[]?

---Result of `formatForChat`.
---@see omichat.api.client.formatForChat
---@class omichat.FormatResult
---@field text string
---@field error string?
---@field allowLanguage boolean?

---Typing information record.
---@class omichat.TypingInformation
---@field display string
---@field lastUpdate integer

---Player preference profile.
---@class omichat.PlayerProfile
---@field name string
---@field chatNickname string? Nickname to use in chat alongside a profile.
---@field callouts string[] Custom callouts.
---@field sneakcallouts string[] Custom sneak callouts.
---@field colors table<string, omi.ColorTable> Custom chat colors.

---Player preferences.
---@class omichat.PlayerPreferences
---@field HIGHER_VERSION boolean Flag that's set when the preferences file had a higher verson than the current version, to avoid bad overwrites.
---@field showNameColors boolean Whether name colors are enabled.
---@field useSuggester boolean Whether suggestions are enabled.
---@field useSignEmotes boolean Whether signed roleplay languages should play a random emote.
---@field showTyping boolean Whether typing indicators should be shown and sent.
---@field suggestOnEnter boolean Whether suggestions should be entered when pressing Enter.
---@field suggestOnTab boolean Whether suggestions should be entered when pressing Tab.
---@field retainChatInput boolean Whether to retain chat input for chat streams.
---@field retainRPInput boolean Whether to retain chat input for roleplay streams (/me).
---@field retainOtherInput boolean Whether to retain other chat input.
---@field adminShowIcon boolean Whether the admin icon should display in chat.
---@field adminKnowLanguages boolean Whether all languages should be treated as known.
---@field adminIgnoreRange boolean Whether message range should be ignored.
---@field profileIndex integer The index of the current profile.
---@field profiles omichat.PlayerProfile[] List of chat profiles.

---Description of a chat tab object.
---@class omichat.ChatTab : ISRichTextPanel
---@field parent omichat.ISChat The parent chat.
---@field logIndex integer The current index in the tab's input history.
---@field tabID integer The tab ID of this tab (0-indexed).
---@field text string The current rich text of the chat tab.
---@field chatStreams (omichat.ChatStream | omichat.StreamTable)[] Chat streams available in this tab.
---@field chatTextLines string[] An array of rich text strings of the current messages.
---@field chatMessages omichat.Message[] Current chat messages.
---@field log string[] The input history of this tab.
---@field tabTitle string The title of this tab.
---@field streamID integer The stream ID of the current stream.

---@class omichat.MessageSegment
---@field type 'quote' | 'action'
---@field text string

---@class omichat.Args.StreamRetrieval
---@field enabledOnly boolean? If `true`, only enabled streams will be returned.

---@class omichat.Args.ChatCommandToStream : omichat.Args.StreamRetrieval
---@field commandsOnly boolean? If `true`, only command streams will be checked.
---@field chatsOnly boolean? If `true`, only chat streams will be checked.

---@class omichat.Args.MessageInfo.SetStream
---@field chatType omichat.ChatTypeString? The chat type to set alongside the stream. Defaults to the stream's chat type.
---@field forceFormat boolean? If `true`, the format will be set to the chat's format regardless of whether it's already set.
---@field noTagUpdate boolean? If `true`, the tags won't be updated to include the target stream's tags.
---@field overwriteTags boolean? If `true`, the previous tags will be overwritten with the tags from the target stream, instead of merging.

---@class omichat.Args.GetMessageSegments
---@field startInAction boolean? If `true`, start reading as an action instead of a quote.
---@field optionalActionAsterisk boolean? If `true`, the asterisk for actions will be considered optional.
---@field onlyFirstSegment boolean? If `true`, only the first segment will be returned.

---@class omichat.Args.PerformSharedOperations
---@field interpolator omichat.Interpolator
---@field options omi.MultiMap
---@field tags omi.SimpleSet
---@field input string
---@field autoQuote boolean?
---@field doCapitalize boolean?
---@field doPunctuate boolean?
---@field applyCase boolean?
---@field applyEmbeddedActions boolean?
---@field applyEmbeddedQuotes boolean?
---@field doColorActions boolean?
---@field doColorQuotes boolean?
---@field doReplaceAsterisks boolean?
---@field doAutoQuotes boolean?

--#region Streams

---@class omichat.Stream
---@field private __api omichat.api.client (static) Reference to the API.
---@field protected callbacks omichat.Stream.Callbacks Container for callbacks.
---@field protected name string The name of the stream.
---@field protected command string The stream command, with a trailing space.
---@field protected shortCommand string? An optional short stream command, with a trailing space.
---@field protected disabled boolean? If `true`, the stream will always be treated as not enabled.
---@field protected aliasesList string[] Additional aliases for the stream.
---@field protected commandType omichat.ChatCommandType The command type used to determine whether input should be retained.
---@field protected chatFormat string? The format to use for chat messages sent from this stream.
---@field protected overheadFormat string? The format to use for overhead messages sent from this stream.
---@field protected formatter omichat.MetaFormatter? The formatter to use for this stream.
---@field protected allowEmotes boolean Whether to allow emotes on this stream.
---@field protected suggestSpec omichat.SuggestSpec? Spec to use for suggestions.
---@field protected tags omi.SimpleSet A set of tags for the stream.
---@field protected autoTags omi.SimpleSet A set of tags to always include on the stream.
---@field protected isChat boolean Whether this is a chat stream.
---@field protected isCommand boolean Whether this is a command stream.
---@field protected noTags boolean True if the stream has an empty tags table.

---@class omichat.Stream.Callbacks
---@field isEnabled omichat.Stream.Callback.IsEnabled? Invoked to check whether the stream should be treated as enabled.
---@field onUse omichat.Stream.Callback.OnUse? Invoked when the stream is used.
---@field onUseDisabled omichat.Stream.Callback.OnUseDisabled? Invoked when the stream is used while disabled.

---@class omichat.Args.Stream
---@field name string The name of the stream.
---@field command string? The stream command, with a trailing space. Defaults to `/` + `name`.
---@field shortCommand string? An optional short stream command, with a trailing space.
---@field aliases string[]? Additional aliases for the stream.
---@field disabled boolean? If `true`, the stream will always be treated as not enabled.
---@field commandType omichat.ChatCommandType? The command type used to determine whether input should be retained.
---@field isEnabled omichat.Stream.Callback.IsEnabled? Invoked to check whether the stream should be treated as enabled.
---@field overheadFormat string? The overhead format to use for the stream.
---@field chatFormat string? The format to use for the stream in chat.
---@field onUse omichat.Stream.Callback.OnUse? Invoked when the stream is used.
---@field onUseDisabled omichat.Stream.Callback.OnUseDisabled? Invoked when the stream is used while disabled.
---@field allowEmotes boolean? Whether to allow emotes on this stream.
---@field suggestSpec omichat.SuggestSpec? Spec to use for suggestions.
---@field formatter omichat.MetaFormatter? The formatter to use for this stream.
---@field tags string[]? Tags for the stream.
---@field autoTags string[]? Tags which should always be included on the stream.


---@class omichat.ChatStream
---@field protected allowBuffs boolean Whether the stream can apply buffs when it's used.
---@field protected allowLanguages boolean Whether the stream allows messages to be sent using roleplay languages.
---@field protected allowTypingIndicator boolean Whether typing on the stream triggers a typing indicator.
---@field protected attractZombies boolean Whether the stream can attract zombies.
---@field protected chatFormat string? The format to use for chat messages.
---@field protected chatType omichat.ChatTypeString The chat type that stream messages are sent over.
---@field protected defaultColor omi.ColorTable The default color for messages on the stream.
---@field protected range integer The range of the chat stream.
---@field protected tabID integer The tab ID of the tab in which this stream is available (1-indexed).
---@field protected useNarrativeStyle boolean Whether the stream should apply narrative style if it's enabled.
---@field protected verticalRange integer The vertical range of the chat stream.

---@class omichat.Args.ChatStream : omichat.Args.Stream
---@field defaultColor omi.ColorTable? The default color for messages on the stream.
---@field allowBuffs boolean? Whether the stream can apply buffs when it's used.
---@field allowLanguages boolean? Whether the stream allows messages to be sent using roleplay languages.
---@field allowTypingIndicator boolean? Whether typing on the stream triggers a typing indicator.
---@field attractZombies boolean? Whether the stream can attract zombies.
---@field chatFormat string? The format to use for chat messages.
---@field useNarrativeStyle boolean? Whether the stream should apply narrative style if it's enabled.
---@field chatType omichat.ChatTypeString? The chat type that stream messages are sent over.
---@field range integer? The range of the chat stream.
---@field verticalRange integer? The vertical range of the chat stream.
---@field tabID integer? The tab ID of the tab in which this stream is available (1-indexed).


---@class omichat.CommandStream
---@field protected callbacks omichat.CommandStream.Callbacks Container for callbacks.
---@field protected helpTextID string? String ID for a help message for the stream.

---@class omichat.CommandStream.Callbacks : omichat.Stream.Callbacks
---@field onHelp omichat.Stream.Callback.OnHelp? Invoked when the `/help` command is used.

---@class omichat.Args.CommandStream : omichat.Args.Stream
---@field helpTextID string? String ID for a help message for the stream.
---@field onHelp omichat.Stream.Callback.OnHelp? Invoked when the `/help` command is used.


---@class omichat.StreamTable
---@field name string The name of the stream.
---@field command string The stream command, with a trailing space.
---@field tabID integer The tab ID of the tab in which this stream is available (1-indexed).
---@field shortCommand string? An optional short stream command, with a trailing space.


---@alias omichat.Stream.Callback.IsEnabled fun(self: omichat.Stream): boolean

---@alias omichat.Stream.Callback.OnUse fun(ctx: omichat.SendArgs) Callback triggered when the stream is used.

---@alias omichat.Stream.Callback.OnUseDisabled fun(self: omichat.Stream) Callback triggered when attempting to use a disabled stream.

---@alias omichat.Stream.Callback.OnHelp fun(self: omichat.Stream) Callback triggered when /help is used.

--#endregion
