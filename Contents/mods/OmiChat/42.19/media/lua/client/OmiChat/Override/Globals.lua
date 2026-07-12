---Handles overrides of global functions.
---@namespace omichat

local chat = require 'OmiChat/Module/Client/Chat'
local streams = require 'OmiChat/Module/Client/Streams'
local config = require 'OmiChat/Component/Configuration'

-- avoid messing up Intellisense
---@type table<string, [function, string, string?]>
local overrideMap = {
    say = { chat.sendSay, 'processSayMessage' },
    shout = { chat.sendShout, 'processShoutMessage', 'yell' },
    whisper = { chat.sendPM, 'proceedPM', 'private' },
    general = { chat.sendGeneral, 'processGeneralMessage' },
    faction = { chat.sendFaction, 'proceedFactionMessage' },
    safehouse = { chat.sendSafehouse, 'processSafehouseMessage' },
    admin = { chat.sendAdmin, 'processAdminChatMessage' },
}

for name, opts in pairs(overrideMap) do
    local override = opts[1]
    local global = opts[2]
    local streamName = opts[3] or name
    local base = _G[global] --[[@as function]]

    _G[global] = function(...)
        local apply = config and config.Compatibility.ApplyOverrides
        if not apply then
            return base(...)
        end

        local stream = streams.get(streamName)
        if stream and not stream:isEnabled() then
            return base(...)
        end

        return override(...)
    end
end
