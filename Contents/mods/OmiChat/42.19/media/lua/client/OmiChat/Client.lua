---Client API.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'

---List of available command streams.
---@type CommandStream[]
---@private
API._commandStreams = require 'OmiChat/Component/ChatCommands'


require 'OmiChat/Module/Client/Callbacks'
require 'OmiChat/Module/Client/Chat'
require 'OmiChat/Module/Client/Extension'
require 'OmiChat/Module/Client/Messages'
require 'OmiChat/Module/Client/Player'
require 'OmiChat/Module/Client/Preferences'
require 'OmiChat/Module/Client/Request'
require 'OmiChat/Module/Client/Search'
require 'OmiChat/Module/Client/Streams'
require 'OmiChat/Module/Client/Suggestion'
require 'OmiChat/Module/Client/UI'
require 'OmiChat/Module/Client/ClientEvents'


return API
