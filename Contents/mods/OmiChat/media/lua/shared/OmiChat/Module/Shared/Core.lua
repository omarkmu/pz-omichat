---Base shared API.

local utils = require 'OmiChat/utils'
local config = require 'OmiChat/Component/Configuration'
local MetaFormatter = require 'OmiChat/Component/MetaFormatter'


---@class omichat.api.shared
local API = {}
API._key = 'omichat'

API.Configuration = config
API.MetaFormatter = MetaFormatter
API.utils = utils


return API
