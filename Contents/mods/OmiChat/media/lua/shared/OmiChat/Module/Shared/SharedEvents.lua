---Shared event handlers.
---@namespace omichat

---@class(partial) api.shared
local API = require 'OmiChat/Module/Shared/Core'

---@class(partial) api.server
local API_S = API


---Event handler for initializing global mod data.
---@protected
function API._onInitGlobalModData()
    local config = API.Configuration

    -- server loads settings from mod data
    -- client loads default settings; will ultimately be received from server
    if not isClient() then
        if config:loadModData() then
            config:saveModData()
        end

        API_S.request.sendConfiguration()
        return
    end
end


Events.OnInitGlobalModData.Add(API._onInitGlobalModData)
