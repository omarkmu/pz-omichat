---Handles operations related to managing hooks.
---@namespace omichat

---@class(partial) api.shared
local API = require 'OmiChat/Module/Shared/Core'


---@class(partial) api.shared.hooks
local Hooks = {}

---Contains functions for handling hooks.
API.hooks = Hooks


---@enum HookType
Hooks.HookType = {
    afterBuildMessage = 'afterBuildMessage',
    beforeBuildMessage = 'beforeBuildMessage',
    buildMessage = 'buildMessage',
    cardCommand = 'cardCommand',
    cardCommandEnabled = 'cardCommandEnabled',
    chatSettingsMenu = 'chatSettingsMenu',
    chatSuggestions = 'chatSuggestions',
    flipCommand = 'flipCommand',
    flipCommandEnabled = 'flipCommandEnabled',
    initCommandMessage = 'initCommandMessage',
    macro = 'macro',
    perceptionRange = 'perceptionRange',
    richTextAction = 'richTextAction',
    rollCommand = 'rollCommand',
    rollCommandEnabled = 'rollCommandEnabled',
}

---Associates hook types to a boolean indicating whether there are active hooks.
---@type omi.SetTable<HookType>
Hooks.has = {}

---Associates hook types to lists of callback functions.
---@type table<HookType, function[]>
---@private
Hooks._callbacks = {}
for k in pairs(Hooks.HookType) do
    Hooks._callbacks[k] = {}
end


---Applies hooks for after message information is built.
---@param info MessageInfo Information about the message to transform.
function Hooks.afterBuildMessage(info)
    Hooks._handleEvent(Hooks._callbacks.afterBuildMessage, info)
end

---Applies hooks for before message information is built.
---@param info MessageInfo Information about the message to transform.
function Hooks.beforeBuildMessage(info)
    Hooks._handleEvent(Hooks._callbacks.beforeBuildMessage, info)
end

---Applies hooks for building message information.
---@param info MessageInfo Information about the message being transformed.
---@return boolean handled `True` if transformation handling should stop. Otherwise, `false`.
function Hooks.buildMessage(info)
    return Hooks._handle(Hooks._callbacks.buildMessage, info)
end

---Applies hooks for the `/card` command.
---@param args Args.UseStream Arguments for the hook callback.
---@return boolean handled `True` if the command was handled by a hook. Otherwise, `false`.
function Hooks.cardCommand(args)
    return Hooks._handle(Hooks._callbacks.cardCommand, args)
end

---Applies hooks for adding settings to the context menu.
---@param category SettingCategory
---@param submenu ISContextMenu
function Hooks.chatSettingsMenu(category, submenu)
    Hooks._handleEvent(Hooks._callbacks.chatSettingsMenu, category, submenu)
end

---Applies hooks for getting suggestions from chat input text.
---@param info SuggestionInfo Information about the suggestion.
---@return boolean handled `True` if the suggestions were handled by a hook. Otherwise, `false`.
function Hooks.chatSuggestions(info)
    return Hooks._handle(Hooks._callbacks.chatSuggestions, info)
end

---Applies hooks for checking whether the `/card` command is enabled.
---@return boolean? enabled `True` or `false` to enable or disable the command. If the return value is `nil`, existing logic is used.
function Hooks.cardCommandEnabled()
    return Hooks._handleBoolean(Hooks._callbacks.cardCommandEnabled)
end

---Applies hooks for the `/flip` command.
---@param args Args.UseStream Arguments for the hook callback.
---@return boolean handled `True` if the command was handled by a hook. Otherwise, `false`.
function Hooks.flipCommand(args)
    return Hooks._handle(Hooks._callbacks.flipCommand, args)
end

---Applies hooks for checking whether the `/flip` command is enabled.
---@return boolean? enabled `True` or `false` to enable or disable the command. If the return value is `nil`, existing logic is used.
function Hooks.flipCommandEnabled()
    return Hooks._handleBoolean(Hooks._callbacks.flipCommandEnabled)
end

---Applies hooks for building initial message information for a command.
---@param info MessageInfo Information about the message being transformed.
---@return boolean handled `True` if building initial information was handled by a hook. Otherwise, `false`.
function Hooks.initCommandMessage(info)
    return Hooks._handle(Hooks._callbacks.initCommandMessage, info)
end

---Applies hooks for applying macros.
---@param text string The input text.
---@return ProcessMacroResults results The results of macro processing from the hooks.
function Hooks.macro(text)
    local playedEmote = false
    local list = Hooks._callbacks.macro

    for i = 1, #list do
        local callback = list[i]
        local result = callback(text, playedEmote) --[[@as ProcessMacroResults?]]

        if result then
            text = result.text or text
            playedEmote = result.playedEmote or playedEmote
        end
    end

    return { text = text, playedEmote = playedEmote }
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

---Applies hooks for a rich text action.
---@param name string The name of the action.
---@param action omi.RichTextActionType The type of the action.
---@param ...any Additional arguments to pass to the action handler.
---@return boolean handled `True` if the action was handled by a hook. Otherwise, `false`.
function Hooks.richTextAction(name, action, ...)
    return Hooks._handle(Hooks._callbacks.richTextAction, name, action, ...)
end

---Applies hooks for the `/roll` command.
---@param args Args.UseStream Arguments for the hook callback.
---@return boolean handled `True` if the command was handled by a hook. Otherwise, `false`.
function Hooks.rollCommand(args)
    return Hooks._handle(Hooks._callbacks.rollCommand, args)
end

---Applies hooks for checking whether the `/roll` command is enabled.
---@return boolean? enabled `True` or `false` to enable or disable the command. If the return value is `nil`, existing logic is used.
function Hooks.rollCommandEnabled()
    return Hooks._handleBoolean(Hooks._callbacks.rollCommandEnabled)
end


---Handles a standard hook.
---@param list function[]
---@param ...any
---@return boolean handled
---@private
function Hooks._handle(list, ...)
    for i = 1, #list do
        local callback = list[i]
        if callback(...) then
            return true
        end
    end

    return false
end

---Handles a boolean-returning hook.
---@param list function[]
---@param ...any
---@return boolean result
---@private
function Hooks._handleBoolean(list, ...)
    for i = 1, #list do
        local callback = list[i]
        local result = callback()
        if result then
            return true
        elseif result == false then
            return false
        end
    end

    return false
end

---Handles an event hook.
---@param list function[]
---@param ...any
---@private
function Hooks._handleEvent(list, ...)
    for i = 1, #list do
        local callback = list[i]
        callback(...)
    end
end


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

--#endregion
