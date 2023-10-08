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


---A table containing color values in [0, 255].
---@class omichat.ColorTable
---@field r integer
---@field g integer
---@field b integer

---Global mod data.
---@class omichat.ModData
---@field version integer
---@field nicknames table<string, string>
---@field nameColors table<string, string>

---Request to update global mod data fields on the server.
---@class omichat.request.ModDataUpdate
---@field target string
---@field field omichat.ModDataField
---@field fromCommand boolean?
---@field value unknown?

---Request to report the result of drawing a card on the client.
---@class omichat.request.ReportDrawCard
---@field card string

---Request to report the result of rolling dice on the client.
---@class omichat.request.ReportRoll
---@field roll integer
---@field sides integer

---Request to display a message on the client.
---@class omichat.request.ShowMessage
---@field text string?
---@field stringID string?
---@field args string[]?
---@field serverAlert boolean?

---Request to roll dice on the server.
---@class omichat.request.RollDice
---@field sides integer

---Request to handle a command on the server.
---@class omichat.request.Command
---@field command string
