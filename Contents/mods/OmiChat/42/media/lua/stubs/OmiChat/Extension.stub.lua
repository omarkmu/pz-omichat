---Type stub to describe the overloads of `Extension.addHook`.
---@namespace omichat
---@meta

---@class(partial) api.shared.extension
local Extension = {}


---Adds a hook that runs after building message information.
---@param type 'afterBuildMessage'
---@param callback fun(info: MessageInfo) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook that runs before building message information.
---@param type 'beforeBuildMessage'
---@param callback fun(info: MessageInfo) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook for building message content.
---@param type 'buildMessage'
---@param callback fun(info: MessageInfo): boolean? The hook callback function. If this returns `true`, building will stop.
function Extension.addHook(type, callback) end

---Adds a hook for the `/card` command.
---@param type 'cardCommand'
---@param callback fun(args: Args.UseStream): boolean? The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/card` command is enabled.
---@param type 'cardCommandEnabled'
---@param callback fun(): boolean? The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for adding settings to the context menu.
---@param type 'chatSettingsMenu'
---@param callback fun(category: string, submenu: ISContextMenu) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook for getting text suggestions for chat.
---@param type 'chatSuggestions'
---@param callback fun(info: SuggestionInfo) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook for the `/flip` command.
---@param type 'flipCommand'
---@param callback fun(args: Args.UseStream): boolean? The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/flip` command is enabled.
---@param type 'flipCommandEnabled'
---@param callback fun(): boolean? The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end

---Adds a hook for determining a message's base text.
---@param type 'getMessageText'
---@param callback fun(args: Args.Hook.GetMessageText): string?, string? The hook callback function. Returns the message and the name to use with the message.
function Extension.addHook(type, callback) end

---Adds a hook for building initial message information for a command.
---@param type 'initCommandMessage'
---@param callback fun(info: MessageInfo) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook for processing macros.
---@param type 'macro'
---@param callback fun(text: string, playedEmote: boolean): ProcessMacroResults? The hook callback function. Returns the results of processing.
function Extension.addHook(type, callback) end

---Adds a hook for determining the perception range.
---@param type 'perceptionRange'
---@param callback fun(args: Args.Hook.PerceptionRange): integer? The hook callback function. Returns the range to use.
function Extension.addHook(type, callback) end

---Adds a hook for a mouse action in a rich text panel.
---@param type 'richTextAction'
---@param callback fun(name: string, action: omi.RichTextActionType) The hook callback function.
function Extension.addHook(type, callback) end

---Adds a hook for the `/roll` command.
---@param type 'rollCommand'
---@param callback fun(args: Args.UseStream): boolean? The hook callback function. If this returns `true`, the original command handling will not run.
function Extension.addHook(type, callback) end

---Adds a hook for checking whether the `/roll` command is enabled.
---@param type 'rollCommandEnabled'
---@param callback fun(): boolean? The hook callback function. If this returns `nil`, the original checks will run.
function Extension.addHook(type, callback) end
