--#region Common

---@class omichat.api.shared
---@field protected _key 'omichat'
---@field protected _configKey 'omichat.settings'

---@class omichat.CallbackInfo
---@field target unknown
---@field callback function
---@field args table

---@class omichat.FormatterInfo
---@field name string The name of the formatter.
---@field id integer The formatter's ID.
---@field formatter omichat.MetaFormatter The formatter.

---@class omichat.MetaFormatterOptions
---@field format string? The format string to use.
---@field defaultName string? The name of the default to use for the `$Default()` function.

---@class omichat.ModData
---@field version integer
---@field players table<string, omichat.PlayerModData>

---@class omichat.PlayerModData
---@field username string
---@field nickname string?
---@field icon string?
---@field languages string[]?
---@field languageSlots integer?
---@field currentLanguage string?
---@field status string?

---@class omichat.PlayerCacheData : omi.PlayerCacheData, omichat.PlayerModData

---@class omichat.utils.InterpolatorCacheData
---@field text string
---@field interpolator omichat.Interpolator

---@class omichat.Interpolator
---@field private _cache omi.Cache<omichat.utils.InterpolatorCacheData> (static)
---@field private _noEntityCache omi.Cache<omichat.utils.InterpolatorCacheData> (static)
---@field private _registered table<string, function> (static)

---@class omichat.MetaFormatter
---@field protected _id integer
---@field protected _formatString string
---@field protected _idPrefix string
---@field protected _idSuffix string
---@field protected _defaultName string

---@class omichat.VanillaCommand
---@field name string The name of the command.
---@field helpText string The string ID of the command's help text.
---@field access integer Access requirements to use the command.
---@field helpTextArgs string[]? Arguments to supply to the command's help text.
---@field suggestSpec omichat.SuggestSpec? Spec for suggestions.


---@alias omichat.ChatTypeString
---| 'general'
---| 'whisper'
---| 'say'
---| 'shout'
---| 'faction'
---| 'safehouse'
---| 'radio'
---| 'admin'
---| 'server'

---@alias omichat.MenuTypeString
---| 'trade'
---| 'medical'
---| 'mini_scoreboard'
---| 'search_player'
---| 'typing'

---@alias omichat.CalloutCategory
---| 'callouts'
---| 'sneakcallouts'

---@see omichat.api.client.format.get
---@alias omichat.FormatterName
---| 'callout'
---| 'sneakCallout'
---| 'language'
---| 'overheadFinal'
---| 'adminIcon'
---| 'narrative'
---| 'onlineID'
---| 'echo'
---| 'mention'

---@alias omichat.ModDataField
---| 'all'
---| 'nickname'
---| 'languages'
---| 'languageSlots'
---| 'currentLanguage'
---| 'icon'
---| 'status'

--#endregion

--#region Data

---@class omichat.api.shared.data
---@field protected _version integer
---@field protected _modData omichat.ModData?
---@field protected _playerCache omi.PlayerCache

--#endregion

--#region Requests

---Request to add or remove a user-defined configuration preset.
---@class omichat.request.AddOrRemovePreset
---@field type 'ADD' | 'DELETE' The operation to complete.
---@field name string The name of the preset.
---@field values table? The configuration values.

---Request to clear mod data for a username.
---@class omichat.request.ClearModData
---@field username string

---Request to execute a command on the server.
---@class omichat.request.Command
---@field name omichat.request.CommandName The name of the command.
---@field text string The command text, excluding the command itself.

---Request to update global mod data fields on the server.
---@class omichat.request.ModDataUpdate
---@field target string The target username.
---@field field omichat.ModDataField The field to update.
---@field fromCommand boolean? Whether this request was created from a command.
---@field value unknown? The value to set on the field.

---Response to a request for mod data.
---@class omichat.request.ModDataListResponse
---@field list omichat.PlayerModData[] The request list of player data.

---Request to report the result of drawing a card on the client.
---@class omichat.request.ReportDrawCard
---@field name string? The name of the player who drew the card, if called for a global message.
---@field card integer The card number, in [1, 13].
---@field suit integer The suit number, in [1, 4].

---Request to report the result of flipping a coin on the client.
---@class omichat.request.ReportFlipCoin
---@field heads boolean True if the result of the flip was heads.

---Request to report the result of rolling dice on the client.
---@class omichat.request.ReportRoll
---@field roll integer The value of the dice roll.
---@field sides integer The number of sides on the dice that was rolled.

---Request to display a message on the client.
---@class omichat.request.ShowMessage
---@field text string? The message text.
---@field stringID string? The string ID of a message to translate.
---@field args string[]? Arguments for message translation.
---@field serverAlert boolean? Whether this should be treated as a server alert.

---Request to roll dice on the server.
---@class omichat.request.RollDice
---@field sides integer The number of sides on the dice to roll.

---Request to notify other players about typing status.
---@class omichat.request.Typing
---@field typing boolean Whether the source player is typing.
---@field range integer? Optional range to limit notifications to.
---@field chatType omichat.ChatTypeString? The chat type of the stream on which the player is typing.

---Request to update the configuration.
---@class omichat.request.UpdateConfiguration
---@field values omichat.Configuration The new configuration values.

---Request to update client information about typing.
---@class omichat.request.UpdateTyping
---@field username string Whether the target player is typing.
---@field typing boolean Whether the target player is typing.

---Request to update the player cache.
---@class omichat.request.UpdatePlayerCache
---@field items omichat.PlayerCacheData[]

---Request to update the user-defined configuration presets.
---@class omichat.request.UpdatePresets
---@field list omichat.Configuration.PresetTable[] The new values.

---@alias omichat.request.CommandName
---| 'addLanguage'
---| 'clearNames'
---| 'resetIcon'
---| 'resetLanguages'
---| 'resetName'
---| 'setIcon'
---| 'setLanguageSlots'
---| 'setName'

--#endregion

--#region Configuration

---@class omichat.ConfigurationHelper
---@field protected _enabledMods table<string, boolean>
---@field protected _idToLanguage omichat.LanguageRecord[]
---@field protected _nameToLanguage table<string, omichat.LanguageRecord>
---@field protected _languageNameList string[]
---@field protected _languageAllowSet omi.SimpleSet
---@field protected _languageBlockSet omi.SimpleSet
---@field protected _formatterInfo table<integer, omichat.FormatterInfo>
---@field protected _presetFilename string
---@field protected _presets table<string, omichat.ConfigurationPreset> Table containing built-in presets.
---@field protected _presetList omichat.ConfigurationPreset[] List containing presets in presentation order.
---@field protected _customPresets table<string, omichat.ConfigurationPreset> Table containing user-defined presets.
---@field protected _variables table<string, string> Table containing arbitrary variables.

---@class omichat.LanguageRecord : omichat.Configuration.LanguageDefinition
---@field ID integer


---@class omichat.Configuration
---@field General omichat.Configuration.General
---@field Buffs omichat.Configuration.Buffs
---@field Callouts omichat.Configuration.Callouts
---@field Commands omichat.Configuration.Commands
---@field Compatibility omichat.Configuration.Compatibility
---@field Customization omichat.Configuration.Customization
---@field Discord omichat.Configuration.Discord
---@field Format omichat.Configuration.Format
---@field EchoMessages omichat.Configuration.EchoMessages
---@field Language omichat.Configuration.Language
---@field Macros omichat.Configuration.Macros
---@field Mentions omichat.Configuration.Mentions
---@field NarrativeStyle omichat.Configuration.NarrativeStyle
---@field Radio omichat.Configuration.Radio
---@field ServerMessages omichat.Configuration.ServerMessages
---@field Streams omichat.Configuration.Streams
---@field TypingIndicator omichat.Configuration.TypingIndicator
---@field ZombieAttraction omichat.Configuration.ZombieAttraction

---@class omichat.Configuration.General
---@field Preset string
---@field AlwaysShowChat boolean
---@field CaseInsensitiveChatStreams boolean
---@field MinimumCommandAccessLevel integer
---@field AdminIcon string
---@field ClearOnDeath omichat.Configuration.General.ClearOnDeath
---@field InfoText string
---@field Variables string[]

---@class omichat.Configuration.General.ClearOnDeath
---@field Icon boolean?
---@field Languages boolean?
---@field Nickname boolean?
---@field Status boolean?

---@class omichat.Configuration.Buffs
---@field Enable boolean
---@field Cooldown integer
---@field Boredom number
---@field Unhappiness number
---@field Hunger number
---@field Thirst number
---@field Fatigue number
---@field CigaretteStress number

---@class omichat.Configuration.Callouts
---@field Range integer
---@field SneakRange integer
---@field Format string
---@field SneakFormat string

---@class omichat.Configuration.Commands
---@field Name omichat.Configuration.Commands.Name
---@field Status omichat.Configuration.Commands.Status
---@field Card omichat.Configuration.Commands.ItemCommand
---@field Roll omichat.Configuration.Commands.ItemCommand
---@field Flip omichat.Configuration.Commands.ItemCommand

---@class omichat.Configuration.Commands.Name
---@field Mode omichat.Configuration.Commands.Name.Mode

---@alias omichat.Configuration.Commands.Name.Mode
---| 'Disable'
---| 'Nickname'
---| 'Forename'
---| 'Fullname'
---| 'Forename_Plus_Nickname'
---| 'Fullname_Plus_Nickname'

---@class omichat.Configuration.Commands.Status
---@field Enable boolean
---@field Range number

---@class omichat.Configuration.Commands.ItemCommand
---@field Global boolean
---@field Format string
---@field OverheadFormat string
---@field Items string[]
---@field Tags string[]

---@class omichat.Configuration.Compatibility
---@field ApplyOverrides boolean
---@field BuffyCharacterBios omi.schema.CompatibilityValue
---@field BuffyRPGSystem omi.schema.CompatibilityValue
---@field ChatBubble omi.schema.CompatibilityValue
---@field SearchPlayers omi.schema.CompatibilityValue
---@field TrueActionsDancing omi.schema.CompatibilityValue

---@class omichat.Configuration.Customization
---@field AllowCustomShouts boolean
---@field EnableNameColors boolean
---@field EnableCharacterCustomization boolean
---@field CleanEffects omi.SimpleSet

---@class omichat.Configuration.Discord
---@field ShowColorOption 'Yes' | 'No' | 'Respect_Server_Setting'
---@field ChatFormat string
---@field DefaultColor omi.ColorTable
---@field Tags string[]

---@class omichat.Configuration.EchoMessages
---@field Enable boolean
---@field ChatFormat string
---@field OverheadFormat string
---@field Tags string[]

---@class omichat.Configuration.Format
---@field Chat omichat.Configuration.Format.Chat
---@field Component omichat.Configuration.Format.Component
---@field Filter omichat.Configuration.Format.Filter
---@field MenuName omichat.Configuration.Format.MenuName
---@field PerceptionRange omichat.Configuration.Format.PerceptionRange
---@field Overhead omichat.Configuration.Format.Overhead

---@class omichat.Configuration.Format.Chat
---@field Final string
---@field Prefix string

---@class omichat.Configuration.Format.Component
---@field Name string
---@field Tag string
---@field Timestamp string
---@field Icon string
---@field Language string
---@field EmbeddedAction string
---@field EmbeddedQuote string

---@class omichat.Configuration.Format.Filter
---@field Name string
---@field Status string
---@field ChatInput string

---@class omichat.Configuration.Format.MenuName
---@field Trade string
---@field Medical string
---@field SearchPlayer string
---@field Typing string
---@field MiniScoreboard string

---@class omichat.Configuration.Format.PerceptionRange
---@field Chat string
---@field Overhead string

---@class omichat.Configuration.Format.Overhead
---@field Final string
---@field Prefix string

---@class omichat.Configuration.Language
---@field DefaultSlots integer
---@field InterpretationRolls integer
---@field InterpretationChance integer
---@field SelfAddAllowlist string[]
---@field SelfAddBlocklist string[]
---@field UnknownLanguageChat string
---@field UnknownLanguageRadio string
---@field UnknownLanguageOverhead string
---@field UseDefaultList boolean
---@field List omichat.Configuration.LanguageDefinition[]

---@class omichat.Configuration.LanguageDefinition
---@field Name string
---@field Signed boolean?

---@class omichat.Configuration.Macros
---@field AllowEmotes boolean

---@class omichat.Configuration.Mentions
---@field Enable boolean
---@field AlwaysUseNameColors boolean
---@field Range integer
---@field Format string
---@field ChatFormat string

---@class omichat.Configuration.NarrativeStyle
---@field Enable boolean
---@field OverheadContentFormat string
---@field ChatContentFormat string
---@field DialogueTagFormat string
---@field InputFilter string

---@class omichat.Configuration.Radio
---@field ChatFormat string
---@field DefaultColor omi.ColorTable
---@field Tags string[]

---@class omichat.Configuration.ServerMessages
---@field ChatFormat string
---@field DefaultColor omi.ColorTable
---@field Tags string[]

---@class omichat.Configuration.Streams
---@field UseDefaultList boolean
---@field GlobalTags string[]
---@field List omichat.Configuration.StreamDefinition[]

---@class omichat.Configuration.StreamDefinition
---@field Enable boolean?
---@field Stream string?
---@field ChatType string?
---@field CommandType string?
---@field Name string?
---@field Command string?
---@field ShortCommand string?
---@field DefaultColor omi.ColorTable?
---@field Aliases string[]?
---@field Tags string[]?
---@field OverheadFormat string?
---@field ChatFormat string?
---@field Range integer?
---@field VerticalRange integer?
---@field PerceptionRange integer?
---@field PerceptionRangeSigned integer?
---@field AllowBuffs boolean?
---@field AllowEmotes boolean?
---@field AllowMentions boolean?
---@field AllowLanguages boolean?
---@field AllowTypingIndicator boolean?
---@field AttractZombies boolean?
---@field UseNarrativeStyle boolean?

---@class omichat.Configuration.TypingIndicator
---@field Enable boolean
---@field Format string

---@class omichat.Configuration.ZombieAttraction
---@field ChatRangeMultiplier number
---@field CalloutRange integer
---@field SneakCalloutRange integer


---@class omichat.ConfigurationPreset
---@field protected _name string
---@field protected _isCustom boolean
---@field protected _values omichat.Configuration
---@field protected _getLanguages omichat.Callback.ConfigurationPreset.GetLanguages?
---@field protected _getStreams omichat.Callback.ConfigurationPreset.GetStreams?
---@field protected _getValues omichat.Callback.ConfigurationPreset.GetValues?

---@class omichat.Configuration.PresetTable
---@field name string The name of the preset.
---@field values table The configuration values.

---@class omichat.Args.ConfigurationPreset
---@field name string
---@field isCustom boolean?
---@field values omichat.Configuration?
---@field getLanguages omichat.Callback.ConfigurationPreset.GetLanguages?
---@field getStreams omichat.Callback.ConfigurationPreset.GetStreams?
---@field getValues omichat.Callback.ConfigurationPreset.GetValues?

---@class omichat.Args.ConfigurationPreset.Buffs
---@field Enable boolean?

---@class omichat.Args.ConfigurationPreset.Callouts
---@field Range integer?
---@field SneakRange integer?

---@class omichat.Args.ConfigurationPreset.Commands
---@field NameMode omichat.Configuration.Commands.Name.Mode?
---@field EnableStatus boolean?
---@field GlobalCommands boolean?

---@class omichat.Args.ConfigurationPreset.Customization
---@field Enable boolean?
---@field CleanEffects string[]?

---@class omichat.Args.ConfigurationPreset.Discord
---@field Tags string[]?

---@class omichat.Args.ConfigurationPreset.Echo
---@field Enable boolean?
---@field Tags string[]?

---@class omichat.Args.ConfigurationPreset.General
---@field Name string
---@field AdminIcon string?
---@field CaseInsensitiveChatStreams boolean?
---@field ClearOnDeath omichat.Configuration.General.ClearOnDeath?
---@field Variables string[]?

---@class omichat.Args.ConfigurationPreset.Language
---@field UseDefaultList boolean?
---@field List omichat.Configuration.LanguageDefinition[]?

---@class omichat.Args.ConfigurationPreset.Macros
---@field AllowEmotes boolean?

---@class omichat.Args.ConfigurationPreset.Mentions
---@field Enable boolean?
---@field Range integer?

---@class omichat.Args.ConfigurationPreset.NarrativeStyle
---@field Enable boolean?

---@class omichat.Args.ConfigurationPreset.Radio
---@field Tags string[]?

---@class omichat.Args.ConfigurationPreset.ServerMessages
---@field Tags string[]?

---@class omichat.Args.ConfigurationPreset.TypingIndicator
---@field Enable boolean?

---@class omichat.Args.ConfigurationPreset.ZombieAttraction
---@field ChatRangeMultiplier number?
---@field CalloutRange integer?
---@field SneakCalloutRange integer?


---@class omichat.ConfigurationFormState
---@field activePresetDialog omi.ui.Dialog?
---@field activeFormatStringDialog omi.ui.Dialog?

---@class omichat.FormatData
---@field tokenDescription string?
---@field optionDescription string?
---@field tokens (omichat.FormatDataTranslation | string)[]?
---@field options (omichat.FormatDataTranslation | string)[]?
---@field canSetError boolean?

---@class omichat.FormatDataTranslation
---@field name string
---@field id string


---@alias omichat.PresetString 'Default' | 'Buffy' | 'Vanilla'

---@alias omichat.Callback.ConfigurationPreset.GetStreams fun(self: omichat.ConfigurationPreset, schema: omichat.ConfigurationSchema): omichat.Configuration.StreamDefinition[]

---@alias omichat.Callback.ConfigurationPreset.GetLanguages fun(self: omichat.ConfigurationPreset, schema: omichat.ConfigurationSchema): omichat.Configuration.LanguageDefinition[]

---@alias omichat.Callback.ConfigurationPreset.GetValues fun(self: omichat.ConfigurationPreset, schema: omichat.ConfigurationSchema): omichat.Configuration

--#endregion
