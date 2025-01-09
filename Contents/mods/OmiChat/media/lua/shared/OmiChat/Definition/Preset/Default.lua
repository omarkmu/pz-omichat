---Default preset.

local Preset = require 'OmiChat/Component/Configuration/Preset'


-- the default values are defined by the schema, so the default preset is empty
return Preset:new({ name = 'Default' })
