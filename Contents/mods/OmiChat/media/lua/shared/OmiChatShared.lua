---Provides API access to OmiChat.
---@class omichat.api.shared
local OmiChat = require 'OmiChat/API/Shared'

require 'OmiChat/API/SharedLanguages'
require 'OmiChat/Component/InterpolatorLibrary'

Events.EveryDays.Add(OmiChat.utils.cleanupCache)


return OmiChat


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
---| 'nicknames'
---| 'nameColors'
---| 'languages'
---| 'languageSlots'
---| 'currentLanguage'
---| 'icons'

---@alias omichat.AdminOption
---| 'show_icon'
---| 'know_all_languages'
---| 'ignore_message_range'


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
---@field convertToRadio true? Whether messages sent on this stream should show up in chat over the radio.
---@field chatTypes table<omichat.ChatTypeString, true?> Chat types for which this stream is enabled.
---@field streamAlias string? An alias to use for determining color and range.
---@field stripColors boolean? Whether to strip colors from messages sent via this stream.
---@field autoColorOption false? Whether to automatically add a color option for this stream.
---@field defaultRangeOpt string? The option used for the default message range. Defaults to `RangeSay`.
---@field titleID string? The string ID to use for chat tags associated with this stream.
---@field attractZombies true? Whether messages sent with this stream should attract zombies.
---@field ignoreLanguage true? Whether messages sent with this stream should be understood by everyone.

---@class omichat.FormatterInfo
---@field name string The name of the formatter.
---@field formatID integer The formatter's ID.
---@field overheadFormatOpt string? The name of the option used for the overhead format.

---Options for initializing formatters.
---@class omichat.MetaFormatterOptions
---@field format string The format string to use.

---A table containing color values in [0, 255].
---@class omichat.ColorTable
---@field r integer The red value.
---@field g integer The green value.
---@field b integer The blue value.

---A table containing color values in [0.0, 1.0].
---@class omichat.DecimalRGBColorTable
---@field r number The red value.
---@field g number The green value.
---@field b number The blue value.

---A table containing color values in [0.0, 1.0].
---@class omichat.DecimalRGBAColorTable : omichat.DecimalRGBColorTable
---@field a number The alpha value.

---Global mod data.
---@class omichat.ModData
---@field version integer The current mod data version.
---@field nicknames table<string, string> Map of usernames to chat nicknames.
---@field nameColors table<string, string> Map of usernames to chat color strings.
---@field icons table<string, string> Map of usernames to chat icons.
---@field languages table<string, string[]> Map of usernames to roleplay languages.
---@field languageSlots table<string, integer> Map of usernames to roleplay language slots.
---@field currentLanguage table<string, string> Map of usernames to currently selected roleplay languages.

---Player mod data.
---@class omichat.PlayerModData
---@field currentLanguage string?

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

---Request to handle a command on the server.
---@class omichat.request.Command
---@field command string The command text, excluding the command itself.
