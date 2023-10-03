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

---A field in the global mod data table.
---@alias omichat.ModDataField
---| 'nicknames'
---| 'nameColors'

---A table containing color values in [0, 255].
---@class omichat.ColorTable
---@field r integer
---@field g integer
---@field b integer

---@class ModDataUpdateRequest
---@field target string
---@field field omichat.ModDataField
---@field value unknown?

---Mod data fields.
---@class omichat.ModData
---@field version integer
---@field nicknames table<string, string>
---@field nameColors table<string, string>
