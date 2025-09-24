---Handles extension of mod functionality.
---@diagnostic disable: invisible

local API = require 'OmiChat/Module/Shared/Core' ---@class omichat.api.shared
local API_C = API --[[@as omichat.api.client]]

local config = API.Configuration
local utils = API.utils

local IS_CLIENT = isClient()


---@class omichat.api.shared.extension
local Extension = {}


---Adds a user-defined preset.
---@param name string The name of the preset.
---@param values table The configuration values.
---@param doRequest boolean? Whether the preset should be sent to the server. Has no effect if used on the server.
---@return omichat.ConfigurationPreset
function Extension.addCustomPreset(name, values, doRequest)
    local schema = API.Configuration:getSchema()
    local readValues = schema:read({ source = values })
    local preset = API.Configuration.Preset:new({
        name = name,
        isCustom = true,
        values = readValues,
    })

    API.Configuration:_addCustomPreset(preset)

    if not IS_CLIENT then
        Extension._writePresets()
    elseif doRequest then
        API_C.request.addPreset(name, values)
    end

    return preset
end

---Adds a function that should be available to all interpolator patterns.
---@param name string
---@param func function
function Extension.registerInterpolatorFunction(name, func)
    utils.Interpolator.register(name, func)
end

---Removes a user-defined preset.
---@param name string The name of the preset.
---@param doRequest boolean? Whether the removal should be sent to the server. Has no effect if used on the server.
function Extension.removeCustomPreset(name, doRequest)
    API.Configuration:_removeCustomPreset(name)

    if not IS_CLIENT then
        Extension._writePresets()
    elseif doRequest then
        API_C.request.removePreset(name)
    end
end

---Writes the preset list to a file.
---@protected
function Extension._writePresets()
    pcall(function()
        local list = config:getCustomPresetsSimple()
        local obj = { list = list }

        local outFile = getFileWriter(config._presetFilename, true, false)
        outFile:write(utils.json.encode(obj))
        outFile:close()
    end)
end


API.extension = Extension
return Extension
