---Shared event handlers.

local API = require 'OmiChat/Module/Shared/Core' ---@class omichat.api.shared
local API_S = API ---@class omichat.api.server


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


Events.EveryDays.Add(API.utils.Interpolator.cleanupCache)
Events.OnInitGlobalModData.Add(API._onInitGlobalModData)
