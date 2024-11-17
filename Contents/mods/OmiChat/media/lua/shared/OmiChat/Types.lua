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

---@alias omichat.ModDataField
---| 'all'
---| 'nicknames'
---| 'nameColors'
---| 'languages'
---| 'languageSlots'
---| 'currentLanguage'
---| 'icons'

---@alias omichat.AdminOption
---| 'ShowIcon'
---| 'KnowAllLanguages'
---| 'IgnoreMessageRange'

---@class omichat.StreamSearchOptions
---@field excludeChatStreams boolean? Whether to exclude chat streams from the search.
---@field excludeCommandStreams boolean? Whether to exclude custom command streams from the search.
---@field includeVanillaCommandStreams boolean? Whether to include vanilla command streams in the search.

---@class omichat.SearchContext
---@field search string The string to search for.
---@field terminateOnExact boolean? If true, exact matches will terminate the search.
---@field max integer? The maximum search results to return.
---@field searchDisplay boolean? If true, the display string will be searched as well.
---@field filter (fun(value: unknown, args: string[]): boolean)|nil Filter function for results.
---@field display (fun(value: unknown, str: string): string?)|nil Function to retrieve display strings for results.
---@field args table? Argument for the filter function.

---@class omichat.SearchResult
---@field value string
---@field exact boolean
---@field display string?

---@class omichat.SearchResults
---@field results omichat.SearchResult[]
---@field exact omichat.SearchResult?

---@class omichat.CallbackInfo
---@field target unknown
---@field callback function
---@field args table

---@class omichat.LanguageInfoStore
---@field languageCount integer
---@field availableLanguages string
---@field signedLanguages string
---@field idToLanguage table<integer, string>
---@field languageToID table<string, integer>
---@field languageIsSignedMap table<string, boolean>

---@class omichat.CustomStreamInfo
---@field name string The name of the custom stream.
---@field formatID integer The constant ID to use for message formatting.
---@field colorOpt string The name of the option used to determine message color.
---@field rangeOpt string The name of the option used to determine message range.
---@field chatFormatOpt string The name of the option used for the chat format.
---@field overheadFormatOpt string The name of the option used for the overhead format.
---@field chatTypes table<omichat.ChatTypeString, true?> Chat types for which this stream is enabled.
---@field streamAlias string? An alias to use for determining color and range.
---@field autoColorOption false? Whether to automatically add a color option for this stream.
---@field defaultRangeOpt string? The option used for the default message range. Defaults to `RangeSay`.
---@field titleID string? The string ID to use for chat tags associated with this stream.

---@class omichat.FormatterInfo
---@field name string The name of the formatter.
---@field formatID integer The formatter's ID.
---@field overheadFormatOpt string? The name of the option used for the overhead format.

---Options for initializing formatters.
---@class omichat.MetaFormatterOptions
---@field format string The format string to use.

---Global mod data.
---@class omichat.ModData
---@field version integer The current mod data version.
---@field nicknames table<string, string> Map of usernames to chat nicknames.
---@field nameColors table<string, string> Map of usernames to chat color strings.
---@field icons table<string, string> Map of usernames to chat icons.
---@field languages table<string, string[]> Map of usernames to roleplay languages.
---@field languageSlots table<string, integer> Map of usernames to roleplay language slots.
---@field currentLanguage table<string, string> Map of usernames to currently selected roleplay languages.

---Global mod data associated with a username.
---@class omichat.UserModData
---@field username string
---@field nickname string?
---@field nameColor string?
---@field icon string?
---@field languages string[]?
---@field languageSlots integer?
---@field currentLanguage string?

---@class omichat.utils.InterpolatorCacheItem
---@field interpolator omichat.Interpolator
---@field lastAccess number

---@class omichat.utils.PlayerCacheItem
---@field username string
---@field forename string
---@field surname string
---@field onlineID number
---@field speechColor omi.ColorTable

---@class omichat.utils
---@field private _interpolatorCache table<string, omichat.utils.InterpolatorCacheItem>
---@field private _playerCacheByUsername table<string, omichat.utils.PlayerCacheItem>
---@field private _playerCacheByOnlineID table<string, omichat.utils.PlayerCacheItem>

---Request to clear mod data for a username.
---@class omichat.request.ClearModData
---@field username string

---Request to update global mod data fields on the server.
---@class omichat.request.ModDataUpdate
---@field target string The target username.
---@field field omichat.ModDataField The field to update.
---@field fromCommand boolean? Whether this request was created from a command.
---@field value unknown? The value to set on the field.

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

---Request to update client information about typing.
---@class omichat.request.UpdateTyping
---@field username string Whether the target player is typing.
---@field typing boolean Whether the target player is typing.

---Request to handle a command on the server.
---@class omichat.request.Command
---@field command string The command text, excluding the command itself.

---Request to update the player cache.
---@class omichat.request.UpdatePlayerCache
---@field items omichat.utils.PlayerCacheItem[]
