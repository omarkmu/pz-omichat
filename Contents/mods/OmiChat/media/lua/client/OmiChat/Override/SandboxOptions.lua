---Override to notify all clients after sandbox options have been updated via the admin menu.

local OmiChat = require 'OmiChat/API/Client'

local getTimestampMs = getTimestampMs
local _SandboxOptions = __classmetatables[SandboxOptions.class].__index
local _sendToServer = _SandboxOptions.sendToServer

---@type integer?
local scheduled


local sendUpdate
sendUpdate = function()
    local now = getTimestampMs()
    if now < (scheduled or now) then
        return
    end

    scheduled = nil
    OmiChat.dispatch('requestSandboxUpdate')
    Events.OnTick.Remove(sendUpdate)
end

function _SandboxOptions:sendToServer()
    _sendToServer(self)

    if not scheduled then
        -- 1s delay so the sandbox update has plenty of time to happen first
        scheduled = getTimestampMs() + 1000
        Events.OnTick.Add(sendUpdate)
    end
end
