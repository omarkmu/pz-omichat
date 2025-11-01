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

    -- server loads from mod data
    if not isClient() then
        local loadSuccess = config:loadModData()
        if loadSuccess then
            config:saveModData()
        end

        config:updateFormatters()
        API_S.request.sendConfiguration()
        return
    end

    -- client loads default settings; will ultimately be received from server
    config:updateFormatters()
end


Events.OnInitGlobalModData.Add(API._onInitGlobalModData)
