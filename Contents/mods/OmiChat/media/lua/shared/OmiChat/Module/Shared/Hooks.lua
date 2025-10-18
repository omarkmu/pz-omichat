---@namespace omichat
---Handles operations related to managing hooks of mod functionality.

---@class(partial) api.shared
local API = require 'OmiChat/Module/Shared/Core'


---Contains functions for handling hooks.
---@class(partial) api.shared.hooks
local Hooks = {}

---Associates hook types to a boolean indicating whether there are active hooks.
---@type omi.SetTable<HookType>
Hooks.has = {}

---Associates hook types to lists of callback functions.
---@protected
Hooks._callbacks = {
    ---@type Hook.Command[]
    cardCommand = {},

    ---@type Hook.CommandEnabled[]
    cardCommandEnabled = {},

    ---@type Hook.Command[]
    flipCommand = {},

    ---@type Hook.CommandEnabled[]
    flipCommandEnabled = {},

    ---@type Hook.PerceptionRange[]
    perceptionRange = {},

    ---@type Hook.Command[]
    rollCommand = {},

    ---@type Hook.CommandEnabled[]
    rollCommandEnabled = {},
}


---Applies hooks for the `/card` command.
---@param args Args.UseStream Arguments for the hook callback.
---@return boolean handled `True` if the command was handled by a hook. Otherwise, `false`.
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
---@return boolean? enabled `True` or `false` to enable or disable the command. If the return value is `nil`, existing logic is used.
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
---@param args Args.UseStream Arguments for the hook callback.
---@return boolean handled `True` if the command was handled by a hook. Otherwise, `false`.
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
---@return boolean? enabled `True` or `false` to enable or disable the command. If the return value is `nil`, existing logic is used.
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
---@param args Args.ApplyHook.PerceptionRange Arguments for the hook callback.
---@return integer range The perception range value to use.
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
---@param args Args.UseStream Arguments for the hook callback.
---@return boolean handled `True` if the command was handled by a hook. Otherwise, `false`.
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
---@return boolean? enabled `True` or `false` to enable or disable the command. If the return value is `nil`, existing logic is used.
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


--#region Type Definition

---@class Args.ApplyHook.PerceptionRange
---@field range integer The current value for the range.
---@field player IsoPlayer The local player.
---@field distance number The distance between the players.
---@field author IsoPlayer The author of the message being tested for perception.
---@field isSigned boolean Flag for whether the message was sent in a signed language.

---@class Args.Hook.PerceptionRange : Args.ApplyHook.PerceptionRange
---@field originalRange integer The original value, before applying any hooks.


---@alias Hook.Command fun(args: Args.UseStream): boolean?

---@alias Hook.CommandEnabled fun(): boolean?

---@alias Hook.PerceptionRange fun(args: Args.Hook.PerceptionRange): integer?


---@alias HookType
---| 'cardCommand'
---| 'cardCommandEnabled'
---| 'flipCommand'
---| 'flipCommandEnabled'
---| 'perceptionRange'
---| 'rollCommand'
---| 'rollCommandEnabled'

--#endregion
