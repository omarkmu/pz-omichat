---@meta
---@namespace omichat
---Type stub to describe the overloads of `Extension.addHook`.

---@class(partial) api.shared.extension
local Extension = {}


---Adds a hook that runs after decoding message content.
---@param type 'afterDecodeMessage'
---@param callback fun(info: MessageInfo) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook that runs before decoding message content.
---@param type 'beforeDecodeMessage'
---@param callback fun(info: MessageInfo) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook for the `/card` command.
---@param type 'cardCommand'
---@param callback fun(args: Args.UseStream): boolean? The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/card` command is enabled.
---@param type 'cardCommandEnabled'
---@param callback fun(): boolean? The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for getting text suggestions for chat.
---@param type 'chatSuggestions'
---@param callback fun(info: SuggestionInfo) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook for decoding command information from a chat message.
---@param type 'decodeCommand'
---@param callback fun(match: string, info: MessageInfo): boolean? The hook callback function. If this returns `true`, the original command decoding will not run.
function Extension.addHook(type, callback) end

---Adds a hook for decoding message content.
---@param type 'decodeMessage'
---@param callback fun(info: MessageInfo): boolean? The hook callback function. If this returns `true`, decoding will stop.
function Extension.addHook(type, callback) end

---Adds a hook for the `/flip` command.
---@param type 'flipCommand'
---@param callback fun(args: Args.UseStream): boolean? The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/flip` command is enabled.
---@param type 'flipCommandEnabled'
---@param callback fun(): boolean? The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for determining the perception range.
---@param type 'perceptionRange'
---@param callback fun(args: Args.Hook.PerceptionRange): integer? The hook callback function. Returns the range to use.
function Extension.addHook(type, callback) end

---Adds a hook for the `/roll` command.
---@param type 'rollCommand'
---@param callback fun(args: Args.UseStream): boolean? The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/roll` command is enabled.
---@param type 'rollCommandEnabled'
---@param callback fun(): boolean? The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end
