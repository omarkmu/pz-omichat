---Handles extension of mod functionality.
---@namespace omichat
---@diagnostic disable: access-invisible

---@class(partial) api.shared
local API = require 'OmiChat/Module/Shared/Core'

---@class(partial) api.client
local API_C = API

local config = API.Configuration
local utils = API.utils

local IS_CLIENT = not isServer()


---@class(partial) api.shared.extension
local Extension = {}

---Contains functions for extending mod functionality.
API.extension = Extension


---Adds a new custom preset.
---@param name string The name of the preset.
---@param values table The configuration values.
---@param doRequest boolean? Flag for whether the preset should be sent to the server. This has no effect if used on the server.
---@return ConfigurationPreset preset The newly added preset object.
function Extension.addCustomPreset(name, values, doRequest)
    local schema = config:getSchema()
    local readValues = schema:read({ source = values }) ---@type Configuration
    local preset = config.Preset:new({
        name = name,
        isCustom = true,
        values = readValues,
    })

    config:_addCustomPreset(preset)

    if not IS_CLIENT then
        Extension._writePresets()
    elseif doRequest then
        API_C.request.addPreset(name, values)
    end

    return preset
end

---@param type HookType The type of hook to add.
---@param callback function The hook callback function.
---@diagnostic disable-next-line: duplicate-set-field
function Extension.addHook(type, callback)
    local cbList = API.hooks._callbacks[type]
    if not cbList or utils.includes(cbList, callback) then
        return
    end

    cbList[#cbList + 1] = callback
    API.hooks.has[type] = true
end

---Adds a function that should be available to all interpolator patterns.
---@param name string The name of the new interpolation function.
---@param func omi.InterpolatorFunction The function to execute when the interpolation function is used.
function Extension.registerInterpolatorFunction(name, func)
    utils.lib.interpolate.register(name, func)
end

---Removes a custom preset.
---@param name string The name of the preset.
---@param doRequest boolean? Flag for whether the removal should be sent to the server. This has no effect if used on the server.
function Extension.removeCustomPreset(name, doRequest)
    config:_removeCustomPreset(name)

    if not IS_CLIENT then
        Extension._writePresets()
    elseif doRequest then
        API_C.request.removePreset(name)
    end
end

---Removes a hook of the given type.
---@param type HookType The type of hook to remove.
---@param callback function The hook callback function.
function Extension.removeHook(type, callback)
    local cbList = API.hooks._callbacks[type]
    if not cbList then
        return
    end

    Extension._remove(cbList, callback)
    if #cbList == 0 then
        API.hooks.has[type] = nil
    end
end


---Removes an element from a table, shifting subsequent elements.
---@param tab table
---@param target any
---@return boolean
---@protected
function Extension._remove(tab, target)
    if target == nil then
        return false
    end

    local i = 1
    local found = false
    while i <= #tab and not found do
        found = tab[i] == target
        i = i + 1
    end

    if found then
        while i <= #tab do
            tab[i - 1] = tab[i]
            i = i + 1
        end

        tab[#tab] = nil
    end

    return found
end

---Removes an element from a table by name, shifting subsequent elements.
---@param tab table[]
---@param name string
---@return boolean
---@protected
function Extension._removeByName(tab, name)
    if name == nil then
        return false
    end

    local i = 1
    local found = false
    while i <= #tab and not found do
        found = tab[i] ~= nil and tab[i].name == name
        i = i + 1
    end

    if found then
        while i <= #tab do
            tab[i - 1] = tab[i]
            i = i + 1
        end

        tab[#tab] = nil
    end

    return found
end

---Writes the presets list to a file.
---@protected
function Extension._writePresets()
    pcall(function()
        local list = config:getCustomPresetsForSave()
        local obj = { list = list }

        local outFile = getFileWriter(config._presetFilename, true, false)
        outFile:write(utils.json.encode(obj))
        outFile:close()
    end)
end


return Extension
