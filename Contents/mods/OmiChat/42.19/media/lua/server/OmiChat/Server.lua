---Server API.
---@namespace omichat

if isClient() then return end


---@class(partial) api.server
local API = require 'OmiChat/Module/Core/Server'

require 'OmiChat/Module/Server/Data'
require 'OmiChat/Module/Server/Commands'
require 'OmiChat/Module/Server/Customization'
require 'OmiChat/Module/Server/Request'

return API
