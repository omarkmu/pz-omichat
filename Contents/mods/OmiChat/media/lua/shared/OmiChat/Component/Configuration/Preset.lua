---Handles configuration presets.

local utils = require 'OmiChat/utils'


---@class omichat.ConfigurationPreset : omi.Class
local Preset = utils.lib.class()


---Returns the name of the preset.
---@return string
function Preset:getName()
    return self._name
end

---Gets the values associated with the preset.
---@param schema omichat.ConfigurationSchema
---@return omichat.Configuration
function Preset:getValues(schema)
    local values
    if self._getValues then
        values = self:_getValues(schema) or {}
    else
        values = utils.deepcopy(self._values)
    end

    if self._getLanguages then
        values.Language.List = self:_getLanguages(schema)
    end

    if self._getStreams then
        values.Streams.List = self:_getStreams(schema)
    end

    return values
end


---Creates a new configuration preset.
---@param args omichat.Args.ConfigurationPreset?
---@return omichat.ConfigurationPreset
function Preset:new(args)
    local this = setmetatable({}, self) ---@cast this omichat.ConfigurationPreset

    args = args or {}
    this._name = args.name
    this._values = args.values or {}
    this._getValues = args.getValues
    this._getLanguages = args.getLanguages
    this._getStreams = args.getStreams

    return this
end


return Preset
