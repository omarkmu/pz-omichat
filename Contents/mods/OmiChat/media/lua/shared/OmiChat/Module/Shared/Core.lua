---Base shared API.

local utils = require 'OmiChat/utils'
local config = require 'OmiChat/Component/Configuration'
local MetaFormatter = require 'OmiChat/Component/MetaFormatter'


---@class omichat.api.shared
local API = {}
API._key = 'omichat'
API._configKey = 'omichat.settings'

API.Configuration = config
API.MetaFormatter = MetaFormatter
API.utils = utils


return API
