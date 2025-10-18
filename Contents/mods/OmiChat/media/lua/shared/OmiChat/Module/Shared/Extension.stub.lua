---@meta
---@namespace omichat
---Type stub to describe the overloads of `Extension.addHook`.

---@class(partial) api.shared.extension
local Extension = {}

---Adds a hook for the `/card` command.
---@param type 'cardCommand'
---@param callback Hook.Command The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/card` command is enabled.
---@param type 'cardCommandEnabled'
---@param callback Hook.CommandEnabled The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for the `/flip` command.
---@param type 'flipCommand'
---@param callback Hook.Command The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/flip` command is enabled.
---@param type 'flipCommandEnabled'
---@param callback Hook.CommandEnabled The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for determining the perception range.
---@param type 'perceptionRange'
---@param callback Hook.PerceptionRange The hook callback function. Returns the range to use.
function Extension.addHook(type, callback) end

---Adds a hook for the `/roll` command.
---@param type 'rollCommand'
---@param callback Hook.Command The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/roll` command is enabled.
---@param type 'rollCommandEnabled'
---@param callback Hook.CommandEnabled The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end
