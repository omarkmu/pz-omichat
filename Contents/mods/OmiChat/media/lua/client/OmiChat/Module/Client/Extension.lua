---Client extension API.
---@diagnostic disable: invisible

local insert = table.insert
local sort = table.sort

---@class omichat.api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils

---@class omichat.api.client.extension : omichat.api.shared.extension
local Extension = API.extension


---Adds information about a command that can be triggered from chat.
---@param stream omichat.CommandStream
function Extension.addCommand(stream)
    API._commandStreams[#API._commandStreams + 1] = stream
end

---Registers a new button for the chat.
---@param button ISButton
---@return ISButton
function Extension.addCustomButton(button)
    API.ui._customButtons[#API.ui._customButtons + 1] = button

    API.ui.updateButtons()
    return button
end

---Adds an emote that is playable from chat with the .emote syntax.
---@param name string The name of the emote, as it can be used from chat.
---@param emote (string | omichat.EmoteHandler) The string or handler to associate with the emote.
function Extension.addEmote(name, emote)
    if type(emote) ~= 'function' then
        emote = tostring(emote)
    end

    API._emotes[name] = emote
end

---Adds a hook of the given type.
---@param type omichat.HookType
---@param callback function
---@overload fun(type: 'cardCommand', callback: omichat.Callback.Hook.Command)
---@overload fun(type: 'cardCommandEnabled', callback: omichat.Callback.Hook.CommandEnabled)
---@overload fun(type: 'flipCommand', callback: omichat.Callback.Hook.Command)
---@overload fun(type: 'flipCommandEnabled', callback: omichat.Callback.Hook.CommandEnabled)
---@overload fun(type: 'perceptionRange', callback: omichat.Callback.Hook.PerceptionRange)
---@overload fun(type: 'rollCommand', callback: omichat.Callback.Hook.Command)
---@overload fun(type: 'rollCommandEnabled', callback: omichat.Callback.Hook.CommandEnabled)
function Extension.addHook(type, callback)
    local cbList = API.hooks._callbacks[type]
    if not cbList or utils.includes(cbList, callback) then
        return
    end

    cbList[#cbList + 1] = callback
    API.hooks.has[type] = true
end

---Adds a message transformer which can act on message information to modify display or behavior.
---@param transformer omichat.MessageTransformer
function Extension.addMessageTransformer(transformer)
    API._transformers[#API._transformers + 1] = transformer
    sort(API._transformers, Extension._prioritySort)
end

---Adds a callback that can be triggered by clicking an action in a rich text panel.
---@param name string
---@param callback omichat.RichTextAction
function Extension.addRichTextAction(name, callback)
    API.ui._actionHandlers[name] = callback
end

---Adds a handler for adding setting context menu options.
---@param category omichat.SettingCategory
---@param callback omichat.SettingHandler
function Extension.addSettingHandler(category, callback)
    local tab = API.ui._settingHandlers[category]
    if tab then
        tab[#tab + 1] = callback
    end
end

---Adds a chat stream.
---@param stream omichat.ChatStream
---@return omichat.ChatStream
function Extension.addStream(stream)
    ISChat.allChatStreams[#ISChat.allChatStreams + 1] = stream
    API.streams.updateTagCache()

    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for i = 1, #tabs do
        local tab = tabs[i]
        if stream:getTabID() == tab.tabID + 1 then
            tab.chatStreams[#tab.chatStreams + 1] = stream
        end
    end

    return stream
end

---Adds a chat stream after an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
---@return omichat.ChatStream
function Extension.addStreamAfter(stream, otherStream)
    return Extension._insertStreamRelative(stream, otherStream, 1)
end

---Adds a chat stream before an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
---@return omichat.ChatStream
function Extension.addStreamBefore(stream, otherStream)
    return Extension._insertStreamRelative(stream, otherStream, 0)
end

---Adds a suggester which can suggest inputs to the player.
---@param suggester omichat.Suggester
function Extension.addSuggester(suggester)
    API._suggesters[#API._suggesters + 1] = suggester
    sort(API._suggesters, Extension._prioritySort)
end

---Registers an argument type for suggester specs.
---@param argType string
---@param callback omichat.SuggestSearchCallback
function Extension.addSuggesterType(argType, callback)
    API.search._customSuggesterTypes[argType] = callback
end

---Removes a registered custom button.
---This does not remove the button from the chat.
---@param button ISButton
function Extension.removeCustomButton(button)
    Extension._remove(API.ui._customButtons, button)
end

---Removes a stream from the list of available chat commands.
---@param stream omichat.CommandStream
function Extension.removeCommand(stream)
    Extension._remove(API._commandStreams, stream)
end

---Removes an emote from the registry.
---@param name string
function Extension.removeEmote(name)
    API._emotes[name] = nil
end

---Removes a hook of the given type.
---@param type omichat.HookType
---@param callback function
function Extension.removeHook(type, callback)
    local cbList = API.hooks._callbacks[type]
    if not cbList then
        return
    end

    Extension._remove(cbList, callback)
    if #cbList == 0 then
        API.hooks.has[type] = nil
    end
end

---Removes a message transformer.
---@param transformer omichat.MessageTransformer
function Extension.removeMessageTransformer(transformer)
    Extension._remove(API._transformers, transformer)
end

---Removes the first message transformer with the provided name.
---@param name string
function Extension.removeMessageTransformerByName(name)
    Extension._removeByName(API._transformers, name)
end

---Removes a rich text action handler.
---@param name string
function Extension.removeRichTextAction(name)
    API.ui._actionHandlers[name] = nil
end

---Removes a handler for adding setting context menu options.
---@param category omichat.SettingCategory
---@param callback omichat.SettingHandler
function Extension.removeSettingHandler(category, callback)
    local tab = API.ui._settingHandlers[category]
    if tab then
        Extension._remove(tab, callback)
    end
end

---Removes a stream from the list of available chat streams.
---@param stream omichat.ChatStream
function Extension.removeStream(stream)
    if not stream then
        return
    end

    -- remove from all streams table
    Extension._remove(ISChat.allChatStreams, stream)

    -- remove from tab streams
    local tabs = ISChat.instance and ISChat.instance.tabs
    if tabs then
        Extension._remove(tabs, stream)
    end
end

---Removes a suggester.
---@param suggester omichat.Suggester
function Extension.removeSuggester(suggester)
    Extension._remove(API._suggesters, suggester)
end

---Removes the first suggester with the provided name.
---@param name string
function Extension.removeSuggesterByName(name)
    Extension._removeByName(API._suggesters, name)
end

---Removes an argument type for suggester specs.
---@param argType string
function Extension.removeSuggesterType(argType)
    API.search._customSuggesterTypes[argType] = nil
end


---Inserts a chat stream relative to another.
---If the other chat stream isn't found, inserts at the end.
---@param stream omichat.ChatStream
---@param other omichat.ChatStream?
---@param relativeIndex integer The relative index.
---@return omichat.ChatStream
---@private
function Extension._insertStreamRelative(stream, other, relativeIndex)
    if not other then
        return Extension.addStream(stream)
    end

    local pos = #ISChat.allChatStreams + 1
    for i = 1, #ISChat.allChatStreams do
        local chatStream = ISChat.allChatStreams[i]
        if chatStream == other then
            pos = i + relativeIndex
            break
        end
    end

    insert(ISChat.allChatStreams, pos, stream)
    API.streams.updateTagCache()

    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for i = 1, #tabs do
        local tab = tabs[i]
        if stream:getTabID() == tab.tabID + 1 then
            pos = #tab.chatStreams + 1
            for j = 1, #tab.chatStreams do
                if tab.chatStreams[i] == other then
                    pos = j + relativeIndex
                    break
                end
            end

            insert(tab.chatStreams, pos, stream)
        end
    end

    return stream
end

---Sort function for sorting items by a priority field.
---@param a table
---@param b table
---@return boolean
---@private
function Extension._prioritySort(a, b)
    local aPri = a.priority or 1
    local bPri = b.priority or 1

    return aPri > bPri
end

---Removes an element from a table, shifting subsequent elements.
---@param tab table
---@param target unknown
---@return boolean
---@private
function Extension._remove(tab, target)
    if target == nil then
        return false
    end

    local i = 1
    local found = false
    while i <= #tab and not found do
        found = tab[i] == target
        i = i + 1
    end

    if found then
        while i <= #tab do
            tab[i - 1] = tab[i]
            i = i + 1
        end

        tab[#tab] = nil
    end

    return found
end

---Removes an element from a table by name, shifting subsequent elements.
---@param tab table[]
---@param name string
---@return boolean
---@private
function Extension._removeByName(tab, name)
    if name == nil then
        return false
    end

    local i = 1
    local found = false
    while i <= #tab and not found do
        found = tab[i].name == name
        i = i + 1
    end

    if found then
        while i <= #tab do
            tab[i - 1] = tab[i]
            i = i + 1
        end

        tab[#tab] = nil
    end

    return found
end


API.extension = Extension
return Extension
