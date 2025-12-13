---Server API.
---@namespace omichat

if isClient() then return end


---@class(partial) api.server
local API = require 'OmiChat/Module/Server/Core'

require 'OmiChat/Module/Server/Data'
require 'OmiChat/Module/Server/Commands'
require 'OmiChat/Module/Server/Request'

require 'OmiChat/Module/Server/ServerEvents'

return API
