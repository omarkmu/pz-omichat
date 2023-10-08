---Provides API access to OmiChat.
---@class omichat.api.shared
return require 'OmiChat/API/Shared'


---Chat types.
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

---Categories for custom callouts.
---@alias omichat.CalloutCategory
---| 'callouts'
---| 'sneakcallouts'

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

---A field in the global mod data table.
---@alias omichat.ModDataField
---| 'nicknames'
---| 'nameColors'


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
---@field nicknames table<string, string> Association of usernames to chat nicknames.
---@field nameColors table<string, string> Association of usernames to chat color strings.

---Request to update global mod data fields on the server.
---@class omichat.request.ModDataUpdate
---@field target string The target username.
---@field field omichat.ModDataField The field to update.
---@field fromCommand boolean? Whether this request was created from a command.
---@field value unknown? The value to set on the field.

---Request to report the result of drawing a card on the client.
---@class omichat.request.ReportDrawCard
---@field card string The name of the card that was drawn.

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
