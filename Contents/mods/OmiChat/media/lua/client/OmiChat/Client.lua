---Client API.

---@class omichat.api.client
local API = require 'OmiChat/Module/Client/Core'
API._commandStreams = require 'OmiChat/Definition/Commands'
API._suggesters = require 'OmiChat/Definition/Suggesters'
API._transformers = require 'OmiChat/Definition/Transformers'

require 'OmiChat/Module/Client/Callbacks'
require 'OmiChat/Module/Client/Chat'
require 'OmiChat/Module/Client/Extension'
require 'OmiChat/Module/Client/Format'
require 'OmiChat/Module/Client/Player'
require 'OmiChat/Module/Client/Preferences'
require 'OmiChat/Module/Client/Request'
require 'OmiChat/Module/Client/RequestHandlers'
require 'OmiChat/Module/Client/Search'
require 'OmiChat/Module/Client/UI'
require 'OmiChat/Module/Client/ClientEvents'

return API
