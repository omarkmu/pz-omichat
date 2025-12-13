---Server event handlers.
---@namespace omichat

if isClient() then return end

---@class(partial) api.server
local API = require 'OmiChat/Module/Server/Core'


---Event handler for initializing global mod data.
---Used for loading configuration.
---@protected
function API._onInitGlobalModData()
    local config = API.Configuration
    if config:loadModData() then
        config:saveModData()
    end
end


Events.OnInitGlobalModData.Add(API._onInitGlobalModData)
