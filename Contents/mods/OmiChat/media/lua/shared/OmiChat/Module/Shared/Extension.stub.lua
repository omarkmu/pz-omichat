---@meta

---@class omichat.api.shared.extension
local Extension = {}

---Adds a hook for the `/card` command.
---@param type 'cardCommand'
---@param callback omichat.Hook.Command The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/card` command is enabled.
---@param type 'cardCommandEnabled'
---@param callback omichat.Hook.CommandEnabled The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for the `/flip` command.
---@param type 'flipCommand'
---@param callback omichat.Hook.Command The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/flip` command is enabled.
---@param type 'flipCommandEnabled'
---@param callback omichat.Hook.CommandEnabled The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for determining the perception range.
---@param type 'perceptionRange'
---@param callback omichat.Hook.PerceptionRange The hook callback function. Returns the range to use.
function Extension.addHook(type, callback) end

---Adds a hook for the `/roll` command.
---@param type 'rollCommand'
---@param callback omichat.Hook.Command The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/roll` command is enabled.
---@param type 'rollCommandEnabled'
---@param callback omichat.Hook.CommandEnabled The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end
