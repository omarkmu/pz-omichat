--#region Common

---@class omichat.api.client
---@field utils omichat.utils.client
---@field private _commandStreams omichat.CommandStream[]
---@field private _emotes table<string, string | omichat.EmoteHandler>
---@field private _chatFormatters table<integer, omichat.MetaFormatter>
---@field private _metadataFormatters table<omichat.FormatterName, omichat.MetaFormatter>
---@field private _transformers omichat.MessageTransformer[]
---@field private _suggesters omichat.Suggester[]
---@field private _typingInfo table<string, omichat.TypingInformation>
---@field private _serverStream omichat.ChatStream
---@field private _radioStream omichat.ChatStream
---@field private _discordStream omichat.ChatStream
---@field private _cardCommand omichat.CommandStream
---@field private _flipCommand omichat.CommandStream
---@field private _rollCommand omichat.CommandStream

---@class omichat.utils.client : omichat.utils
---@field ui omi.ui
---@field lib omi.client

---@class omichat.api.client.callbacks
---@field protected _infoUpdateCounter integer


---@class omichat.MessageTransformer
---@field name string? The name of the transformer.
---@field transform fun(self: table, info: omichat.MessageInfo): true? Performs message transformation.
---@field priority integer? The priority of the transformer. Higher numbers will run first.


---@alias omichat.ChatCommandCategory 'chat' | 'rp' | 'other'

---@alias omichat.ChatFont 'small' | 'medium' | 'large'

---@alias omichat.Message ChatMessage | omi.chat.MimicMessage

---@alias omichat.EmoteHandler fun(player: IsoPlayer, emote: string)

--#endregion

--#region Chat

---@class omichat.api.client.chat
---@field private _wasTyping boolean The typing status from the previous update.
---@field private _isTyping boolean Whether the local player is currently typing.

---@class omichat.ChatTab
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
---@field lastChatCommand string The last command input in the chat tab.

---@class omichat.TypingInformation
---@field display string
---@field lastUpdate integer

---@class omichat.Args.UseStream : omichat.Args.UseStream.Partial
---@field stream omichat.Stream

---@class omichat.Args.UseStream.Partial
---@field text string
---@field formatStream omichat.Stream?
---@field playSignedEmote boolean?
---@field echoType integer?
---@field formatter omichat.MetaFormatter?
---@field tokens table?
---@field extraTags string[]?
---@field allowInvisible boolean?

---@class omichat.ISChat : ISChat
---@field instance omichat.ISChat? The ISChat instance.
---@field focused boolean Whether the chat is currently focused.
---@field showTitle boolean Whether chat type titles should display.
---@field showTimestamp boolean Whether timestamps should display.
---@field chatFont omichat.ChatFont The current font of the chat.
---@field chatText omichat.ChatTab The current chat tab.
---@field tabs omichat.ChatTab[] List of available chat tabs.
---@field allChatStreams (omichat.ChatStream | omichat.StreamTable)[] List of all available chat streams.
---@field defaultTabStream table<integer, omichat.ChatStream?> An association of 1-indexed tab IDs to default streams.
---@field gearButton ISButton The settings button.
---@field textEntry omi.ui.TextEntry The text entry UI element.
---@field currentTabID integer The 1-indexed tab ID of the current tab.
---@field tabCnt integer The number of available tabs.
---@field infoButton omi.ui.Button The info button.
---@field activeProfilesPanel omichat.ProfileManager?
---@field activeConfigurationPanel omi.forms.Form?
---@field activeLanguageModal omi.ui.Dialog?
---@field activeColorModal omi.ui.Dialog?
---@field activePlayerDataPanel omichat.PlayerDataManager

--#endregion

--#region Interpolation

---@class omichat.MessageSegment
---@field type 'quote' | 'action'
---@field text string

---@class omichat.Args.GetMessageSegments
---@field startInAction boolean? If `true`, start reading as an action instead of a quote.
---@field hasInternalQuote boolean? If `true`, the message has an internal quote. This makes the first quote encountered not end an initial quote segment.
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
---@field hasInternalQuote boolean?

--#endregion

--#region Format

---@class omichat.Args.FormatChat
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

---@class omichat.FormatResult
---@field text string
---@field error string?
---@field allowLanguage boolean?

--#endregion

--#region MessageInfo

---@class omichat.MessageInfo
---@field message omichat.Message The message object.
---@field tokens table<string, unknown> Token substitution values.
---@field context table Table for arbitrary context data.
---@field content string? The message content to display in chat. Set by transformers.
---@field rawText string The raw text of the message. This should not be modified.
---@field chatType omichat.ChatTypeString The chat type of the message's chat.
---@field format string? The format string to use for the message. Set by transformers.
---@field default string? The name of the default to use for the `$Default()` function.
---@field stream omichat.Stream? The source stream of the message.
---@field originalStream omichat.Stream? The original stream of a radio message.
---@field author string The username of the message author.
---@field zombieAttractRange integer? The range at which the message will be heard by zombies.
---@field tags omi.SimpleSet A set of tags to add to the message tokens.
---@field protected usePerceivedText boolean? Whether the message text should be replaced by the "perception range" text.
---@field protected useUnknownLanguageText boolean? Whether the message text should be replaced by the unknown language text.
---@field protected overheadText string? The text to show overhead instead of the message text.
---@field protected doFullOverhead boolean? If `true`, the replacement overhead text will also use the overhead prefix and final formats.
---@field protected hidden boolean Whether the message has been hidden in chat and overhead.
---@field protected loudCallout boolean Whether the message is a non-sneak callout.
---@field protected sneakCallout boolean Whether the message is a sneak callout.
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
---@field suppressedRadio boolean? Whether the overhead text for this message has already been suppressed on radio.
---@field stream string? The name of the stream the message was sent over.
---@field originalStream string? The name of the original stream a radio message was sent over.
---@field faction string? The name of the faction to which the message was sent.
---@field rangeResult omichat.MessageInfo.Metadata.RangeResult? The result of range checking.
---@field languageResult omichat.MessageInfo.Metadata.LanguageResult? The result of language checking.
---@field attractedZombies boolean? Whether the message has already attracted zombies.
---@field displayedOverhead boolean? Whether the replacement overhead text has already displayed.
---@field mentions omichat.MessageInfo.Metadata.Mention[]? The results of formatting mentions.

---@class omichat.MessageInfo.Metadata.Mention
---@field color string
---@field name string?

---@class omichat.Args.MessageInfo.SetStream
---@field chatType omichat.ChatTypeString? The chat type to set alongside the stream. Defaults to the stream's chat type.
---@field forceFormat boolean? If `true`, the format will be set to the chat's format regardless of whether it's already set.
---@field noTagUpdate boolean? If `true`, the tags won't be updated to include the target stream's tags.
---@field overwriteTags boolean? If `true`, the previous tags will be overwritten with the tags from the target stream, instead of merging.


---@alias omichat.MessageInfo.Metadata.LanguageResult 'known-language' | 'unknown-language'

---@alias omichat.MessageInfo.Metadata.RangeResult 'in-range' | 'out-of-range' | 'in-perception-range'

--#endregion

--#region Mod Data Manager

---@class omichat.PlayerDataManager
---@field listbox omi.ui.ListBox
---@field elements omichat.PlayerModData[]
---@field columnList string[]
---@field columnDisplay table<string, string>
---@field columnWidth table<string, integer>
---@field headerH integer
---@field titleW integer
---@field buttonBorderColor omi.ColorTableRGBA
---@field listHeaderColor omi.ColorTableRGBA
---@field headerFont UIFont
---@field listFont UIFont
---@field titleText string
---@field activeEditorPanel omichat.PlayerDataEditor?
---@field activeDialog omi.ui.Dialog?
---@field closeBtn omi.ui.Button
---@field refreshBtn omi.ui.Button
---@field modifyBtn omi.ui.Button
---@field addBtn omi.ui.Button
---@field deleteBtn omi.ui.Button

---@class omichat.Args.PlayerDataManager : omi.ui.Args.Panel


---@class omichat.PlayerDataEditor
---@field protected callbacks omichat.PlayerDataEditor.Callbacks
---@field item omichat.PlayerModData
---@field saveItem omichat.PlayerModData
---@field nicknameEntry omi.ui.TextEntry
---@field usernameEntry omi.ui.TextEntry
---@field iconEntry omi.ui.TextEntry
---@field currentLangEntry omi.ui.TextEntry
---@field languageListEntry omi.ui.ListEntry
---@field statusEntry omi.ui.TextEntry
---@field languageSlotsEntry omi.ui.TextEntry
---@field languageSuggestBox omi.ui.SuggestBox
---@field iconSuggestBox omi.ui.SuggestBox
---@field buttonBorderColor omi.ColorTableRGBA
---@field saveBtn omi.ui.Button
---@field closeBtn omi.ui.Button
---@field isAdd boolean
---@field languageFilter function?

---@class omichat.PlayerDataEditor.Callbacks : omi.ui.Panel.Callbacks
---@field onSave omi.CallbackInfo?

---@class omichat.Args.PlayerDataEditor : omi.ui.Args.Panel
---@field item omichat.PlayerModData The original data to be edited.
---@field isAdd boolean? If `true`, the editor is for adding user data rather than editing existing data.
---@field onSave function? A function to call when saving the data.
---@field onSaveArgs table? Arguments for `onSave`.
---@field onSaveTarget unknown? The first argument to pass to the `onSave` callback.

--#endregion

--#region Preferences

---@class omichat.api.client.preferences
---@field private _prefs omichat.PlayerPreferences The loaded player preferences.
---@field private _filename string The filename from which preferences are loaded.
---@field private _version integer The current preferences file version.

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

---@class omichat.PlayerProfile
---@field name string The name of the profile.
---@field chatNickname string? Nickname to use in chat alongside a profile.
---@field callouts string[] Custom callouts.
---@field sneakcallouts string[] Custom sneak callouts.
---@field colors table<string, omi.ColorTable> Custom chat colors.

---@class omichat.ProfileManager
---@field current omichat.PlayerProfile? The profile being edited.
---@field profiles omichat.PlayerProfile[] The list of profiles.
---@field profileNameControl omi.ui.TextEntry The control for setting a profile name.
---@field nicknameControl omi.ui.TextEntry? The control for setting a nickname to use when switching to a profile.
---@field colorControls table<string, omi.ui.ColorEntry> Associates color options to controls.
---@field calloutControls table<string, omi.ui.TextEntry> Associates callout types to controls.
---@field createBtn omi.ui.Button The button to add a new profile.
---@field deleteBtn omi.ui.Button The button to delete the current profile.
---@field duplicateBtn omi.ui.Button The button to duplicate the current profile.
---@field emptyLabel omi.ui.Label The label to display when there are no profiles.
---@field addText string The text for the create button in the non-empty state.
---@field createText string The text for the create button in the empty state.

---@class omichat.Args.ProfileManager : omi.ui.Args.Panel
---@field profiles omichat.PlayerProfile[]


---@alias omichat.AdminOption
---| 'ShowIcon'
---| 'KnowAllLanguages'
---| 'IgnoreMessageRange'

--#endregion

--#region Search

---@class omichat.api.client.search
---@field private _customSuggesterTypes table<string, omichat.SuggestSearchCallback>
---@field private _perkList omichat.search.PerkInfo[]?
---@field private _iconList omichat.search.IconInfo[]?


---@class omichat.SearchContext
---@field search string The string to search for.
---@field terminateOnExact boolean? If true, exact matches will terminate the search.
---@field maxResults integer? The maximum number of search results to return.
---@field maxSearch integer? The maximum number of elements to search before terminating.
---@field searchDisplay boolean? If true, the display string will be searched as well.
---@field filter (fun(value: unknown, args: string[]): boolean)? Filter function for results.
---@field display (fun(value: unknown, searchString: string): string?)? Function to retrieve display strings for results.
---@field args string[]? Argument for the filter function.
---@field isTerminated boolean? Whether the search should stop.
---@field exactInternal omichat.search.InternalSearchResult? The last exact match for the internal search.
---@field exact omichat.SearchResult? The last exact match for the search.

---@class omichat.SearchResult
---@field value string
---@field exact boolean
---@field display string?
---@field texture Texture?

---@class omichat.SearchResults
---@field results omichat.SearchResult[]
---@field exact omichat.SearchResult?

---@class omichat.search.InternalSearchContext : omichat.SearchContext
---@field searchForStartsWith string?
---@field searchForContains string?
---@field startsWith omichat.search.InternalSearchResult[]
---@field contains omichat.search.InternalSearchResult[]
---@field mapValue (fun(value: unknown, searchString: string): string)?
---@field mapTexture (fun(value: unknown, searchString: string): Texture)?
---@field caseSensitive boolean?
---@field args string[]

---@class omichat.search.InternalSearchResult
---@field exact boolean
---@field raw unknown
---@field display string?
---@field searchString string
---@field value string?

---@class omichat.search.PerkInfo
---@field perk Perk
---@field name string
---@field id string

---@class omichat.search.IconInfo
---@field name string
---@field alias string

---@class omichat.search.PlayerInfo
---@field name string
---@field username string

---@class omichat.StreamSearchOptions
---@field excludeChatStreams boolean? Whether to exclude chat streams from the search.
---@field excludeCommandStreams boolean? Whether to exclude custom command streams from the search.
---@field includeUnmanagedChatStreams boolean? Whether to include unmanaged stream tables in the search.
---@field includeVanillaCommandStreams boolean? Whether to include vanilla command streams in the search.

---@class omichat.Args.StreamSearch : omichat.StreamSearchOptions, omichat.SearchContext

--#endregion

--#region StatusManager

---@class omichat.StatusManager
---@field private _enabled boolean
---@field private _displayByUsername table<string, omichat.StatusDisplay>

---@class omichat.StatusDisplay
---@field target IsoPlayer
---@field mouseOver boolean
---@field protected text string?
---@field protected font UIFont
---@field protected targetUsername string
---@field protected drawObject TextDrawObject
---@field protected shouldHide boolean

--#endregion

--#region Streams

---@class omichat.api.client.streams
---@field private _tagToChatStreams table<string, omichat.ChatStream[]> Map associating tags to chat streams that include them.


---@class omichat.Stream
---@field protected callbacks omichat.Stream.Callbacks Container for callbacks.
---@field protected name string The name of the stream.
---@field protected command string The stream command, with a trailing space.
---@field protected shortCommand string? An optional short stream command, with a trailing space.
---@field protected disabled boolean? If `true`, the stream will always be treated as not enabled.
---@field protected aliasesList string[] Additional aliases for the stream.
---@field protected commandType omichat.ChatCommandCategory The command type used to determine whether input should be retained.
---@field protected chatFormat string? The format to use for chat messages sent from this stream.
---@field protected overheadFormat string? The format to use for overhead messages sent from this stream.
---@field protected formatter omichat.MetaFormatter? The formatter to use for this stream.
---@field protected allowEmotes boolean Whether to allow emotes on this stream.
---@field protected allowMentions boolean Whether to allow mentions on this stream.
---@field protected suggestSpec omichat.SuggestSpec? Spec to use for suggestions.
---@field protected tags omi.SimpleSet A set of tags for the stream.
---@field protected autoTags omi.SimpleSet A set of tags to always include on the stream.
---@field protected isChat boolean Whether this is a chat stream.
---@field protected isCommand boolean Whether this is a command stream.
---@field protected noTags boolean True if the stream has an empty tags table.
---@field protected defaultOnDisabled boolean Whether the stream should defer to default handling when disabled.

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
---@field commandType omichat.ChatCommandCategory? The command type used to determine whether input should be retained.
---@field isEnabled omichat.Stream.Callback.IsEnabled? Invoked to check whether the stream should be treated as enabled.
---@field overheadFormat string? The overhead format to use for the stream.
---@field chatFormat string? The format to use for the stream in chat.
---@field onUse omichat.Stream.Callback.OnUse? Invoked when the stream is used.
---@field onUseDisabled omichat.Stream.Callback.OnUseDisabled? Invoked when the stream is used while disabled.
---@field allowEmotes boolean? Whether to allow emotes on this stream.
---@field allowMentions boolean? Whether to allow mentions on this stream.
---@field suggestSpec omichat.SuggestSpec? Spec to use for suggestions.
---@field formatter omichat.MetaFormatter? The formatter to use for this stream.
---@field tags string[]? Tags for the stream.
---@field autoTags string[]? Tags which should always be included on the stream.
---@field defaultOnDisabled boolean? Whether the stream should defer to default handling when disabled. Defaults to `true`.


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
---@field protected perceptionRange integer The perception range of the chat stream.
---@field protected perceptionRangeSigned integer The perception range of the chat stream, for signed languages.

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
---@field perceptionRange integer? The perception range of the chat stream.
---@field perceptionRangeSigned integer? The perception range of the chat stream, for signed languages.
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


---@class omichat.Args.StreamRetrieval
---@field enabledOnly boolean? If `true`, only enabled streams will be returned.

---@class omichat.Args.ChatCommandToStream : omichat.Args.StreamRetrieval
---@field commandsOnly boolean? If `true`, only command streams will be checked.
---@field chatsOnly boolean? If `true`, only chat streams will be checked.


---@alias omichat.Stream.Callback.IsEnabled fun(self: omichat.Stream): boolean

---@alias omichat.Stream.Callback.OnUse fun(ctx: omichat.Args.UseStream) Callback triggered when the stream is used.

---@alias omichat.Stream.Callback.OnUseDisabled fun(self: omichat.Stream, command: string) Callback triggered when attempting to use a disabled stream.

---@alias omichat.Stream.Callback.OnHelp fun(self: omichat.Stream) Callback triggered when /help is used.

--#endregion

--#region Suggestions

---@class omichat.Suggester
---@field name string? The name of the suggester.
---@field suggest fun(self: table, info: omichat.SuggestionInfo) Performs suggestion.
---@field priority integer? The priority of the suggester. Higher numbers will run first.

---@class omichat.SuggestionInfo
---@field input string The current input text.
---@field context table Table for arbitrary context data.
---@field suggestions omi.ui.SuggestBox.Suggestion[] The current list of suggestions.

---@class omichat.SuggestArgSpecTable
---@field type omichat.SuggestionType | string The type of the argument.
---@field prefix string? A prefix to apply to the suggestion result.
---@field suffix string? A suffix to apply to the suggestion result.
---@field options string[]? String options for the `option` suggestion type.
---@field searchDisplay boolean? If true, the display string will be used for determining suggestions.
---@field filter (fun(result: unknown, args: string[]): boolean)? Filter function for results.
---@field display (fun(value: unknown, str: string): string?)? Function to retrieve display strings for results.


---@alias omichat.SuggestSpec omichat.SuggestArgSpec[]

---@alias omichat.SuggestArgSpec omichat.SuggestArgSpecTable | omichat.SuggestionType | string

---@alias omichat.SuggestSearchCallback fun(ctx: omichat.SearchContext | string, spec: omichat.SuggestArgSpec): omichat.SearchResults?

---@alias omichat.SuggestionType
---| 'online-username'
---| 'online-username-with-self'
---| 'language'
---| 'known-language'
---| 'icon'
---| 'perk'
---| 'option'
---| '?'

--#endregion

--#region UI

---@class omichat.api.client.ui
---@field suggestBox omi.ui.SuggestBox? The auto-suggest box for the chat input.
---@field typingFont UIFont The font used for the typing indicator.
---@field typingFontHgt integer The height of the font used for the typing indicator.
---@field private _customButtons ISButton[] A list of custom buttons added to the chat window.
---@field private _actionHandlers table<string, omichat.RichTextAction> Handlers for rich text actions.
---@field private _typingDisplay string? The current display text for the typing indicator.
---@field private _settingHandlers table<omichat.SettingCategory, omichat.SettingHandler[]> Handlers for setting sections.


---@alias omichat.RichTextAction fun(name: string, action: omi.RichTextActionType, ...: string)

---@alias omichat.SettingHandler fun(submenu: ISContextMenu)

---@alias omichat.SettingCategory
---| 'basic'
---| 'customization'
---| 'language'
---| 'admin'
---| 'suggestions'
---| 'main'

--#endregion
