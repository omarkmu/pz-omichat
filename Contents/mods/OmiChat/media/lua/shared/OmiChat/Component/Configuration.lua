local utils = require 'OmiChat/utils'
local base = utils.configuration.ConfigurationHelper


---Contains mod configuration and enables updating it.
---@class omichat.ConfigurationHelper : omi.ConfigurationHelper, omichat.Configuration
local Configuration = utils.configuration {
    schema = require 'OmiChat/Component/Configuration/Schema',
    filename = 'omichat_server.json',
    logger = utils.log,
    init = function(self)
        -- server should load from file
        if not isClient() and self:loadFile() then
            self:saveFile()
            return
        end

        -- client should load defaults; will ultimately be received from server
        self:loadDefaults()
    end,
}

---Returns the schema of the configuration.
---@return omichat.ConfigurationSchema
function Configuration:getSchema()
    local schema = base.getSchema(self) ---@cast schema omichat.ConfigurationSchema
    return schema
end

---Returns the current configuration as a simple table.
---@return omichat.Configuration
function Configuration:getValues()
    return base.getValues(self)
end

---Gets sanitized configuration values that are prepared for saving.
---@return omichat.Configuration
function Configuration:getValuesForSave()
    return base.getValuesForSave(self)
end


Configuration:init()
return Configuration
