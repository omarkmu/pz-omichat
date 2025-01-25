---Server API.

if isClient() then return end


---@class omichat.api.server
local API = require 'OmiChat/Module/Server/Core'

require 'OmiChat/Module/Server/Data'
require 'OmiChat/Module/Server/Request'
require 'OmiChat/Module/Server/RequestHandlers'
require 'OmiChat/Module/Server/ServerEvents'

return API
