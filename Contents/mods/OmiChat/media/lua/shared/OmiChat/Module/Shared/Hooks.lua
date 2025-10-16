---Handles operations related to managing hooks of mod functionality.

---@class omichat.api.shared
local API = require 'OmiChat/Module/Shared/Core'


---@class omichat.api.shared.hooks
local Hooks = {}
Hooks.has = {}
Hooks._callbacks = {
    cardCommand = {},
    cardCommandEnabled = {},
    flipCommand = {},
    flipCommandEnabled = {},
    perceptionRange = {},
    rollCommand = {},
    rollCommandEnabled = {},
}


---Applies hooks for the `/card` command.
---@param args omichat.Args.UseStream
---@return boolean handled
function Hooks.cardCommand(args)
    local list = Hooks._callbacks.cardCommand
    for i = 1, #list do
        local callback = list[i]
        if callback(args) then
            return true
        end
    end

    return false
end

---Applies hooks for checking whether the `/card` command is enabled.
---@return boolean? enabled
function Hooks.cardCommandEnabled()
    local list = Hooks._callbacks.cardCommandEnabled
    for i = 1, #list do
        local callback = list[i]
        local isEnabled = callback()
        if isEnabled then
            return true
        elseif isEnabled == false then
            return false
        end
    end
end

---Applies hooks for the `/flip` command.
---@param args omichat.Args.UseStream
---@return boolean handled
function Hooks.flipCommand(args)
    local list = Hooks._callbacks.flipCommand
    for i = 1, #list do
        local callback = list[i]
        if callback(args) then
            return true
        end
    end

    return false
end

---Applies hooks for checking whether the `/flip` command is enabled.
---@return boolean? enabled
function Hooks.flipCommandEnabled()
    local list = Hooks._callbacks.flipCommandEnabled
    for i = 1, #list do
        local callback = list[i]
        local isEnabled = callback()
        if isEnabled then
            return true
        elseif isEnabled == false then
            return false
        end
    end
end

---Applies modifications to perception range from hooks.
---@param args omichat.Args.ApplyHook.PerceptionRange
---@return integer
function Hooks.perceptionRange(args)
    local value = args.range
    local list = Hooks._callbacks.perceptionRange
    for i = 1, #list do
        local callback = list[i]
        local result = callback({
            range = value,
            originalRange = args.range,
            distance = args.distance,
            player = args.player,
            author = args.author,
            isSigned = args.isSigned,
        })

        value = result or value
    end

    return value
end

---Applies hooks for the `/roll` command.
---@param args omichat.Args.UseStream
---@return boolean handled
function Hooks.rollCommand(args)
    local list = Hooks._callbacks.rollCommand
    for i = 1, #list do
        local callback = list[i]
        if callback(args) then
            return true
        end
    end

    return false
end

---Applies hooks for checking whether the `/roll` command is enabled.
---@return boolean? enabled
function Hooks.rollCommandEnabled()
    local list = Hooks._callbacks.rollCommandEnabled
    for i = 1, #list do
        local callback = list[i]
        local isEnabled = callback()
        if isEnabled then
            return true
        elseif isEnabled == false then
            return false
        end
    end
end


API.hooks = Hooks
return Hooks
