---@namespace omichat
---Client extension API.

local insert = table.insert
local sort = table.sort
local ISChat = ISChat --[[@as omichat.ISChat]]

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'


---Contains functions for extending mod functionality.
---@class api.client.extension : api.shared.extension
local Extension = API.extension


---Adds a command that can be triggered from chat.
---@param stream CommandStream
---@return CommandStream stream
function Extension.addCommand(stream)
    API._commandStreams[#API._commandStreams + 1] = stream
    return stream
end

---Registers a new button for the chat.
---The button will be automatically added to the chat window, to the left of other buttons.
---@param button ISButton
---@return ISButton
function Extension.addCustomButton(button)
    API.ui._customButtons[#API.ui._customButtons + 1] = button
    API.ui.updateButtons()

    return button
end

---Adds an emote that is playable from chat with the .emote syntax.
---@param name string The name of the emote, as it can be used from chat.
---@param emote (string | fun(player: IsoPlayer, emote: string)) The string or handler to associate with the emote.
function Extension.addEmote(name, emote)
    if type(emote) ~= 'function' then
        emote = tostring(emote)
    end

    API._emotes[name] = emote
end

---Adds a callback that can be triggered by clicking an action in a rich text panel.
---@param name string The name of the action.
---@param callback fun(name: string, action: omi.RichTextActionType, ...: string) The action callback.
function Extension.addRichTextAction(name, callback)
    API.ui._actionHandlers[name] = callback
end

---Adds a handler for adding setting context menu options.
---@param category SettingCategory The setting category to add to.
---@param callback fun(submenu: ISContextMenu) The setting handler callback.
function Extension.addSettingHandler(category, callback)
    local tab = API.ui._settingHandlers[category]
    if tab then
        tab[#tab + 1] = callback
    end
end

---Adds a chat stream.
---@param stream ChatStream The stream to add.
---@return ChatStream stream
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
---@param stream ChatStream The stream to add.
---@param otherStream ChatStream? The comparison stream.
---@return ChatStream stream
function Extension.addStreamAfter(stream, otherStream)
    return Extension._insertStreamRelative(stream, otherStream, 1)
end

---Adds a chat stream before an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream ChatStream The stream to add.
---@param otherStream ChatStream? The comparison stream.
---@return ChatStream stream
function Extension.addStreamBefore(stream, otherStream)
    return Extension._insertStreamRelative(stream, otherStream, 0)
end

---Registers an argument type for suggester specs.
---@param argType string The argument type.
---@param callback fun(ctx: SearchContext | string, spec: SuggestArgSpec): SearchResults? The suggestion callback.
function Extension.addSuggesterType(argType, callback)
    API.suggestion._customArgTypes[argType] = callback
end

---Removes a registered custom button.
---This does not remove the button from the chat.
---@param button ISButton The button to remove.
function Extension.removeCustomButton(button)
    Extension._remove(API.ui._customButtons, button)
end

---Removes a stream from the list of available commands.
---@param stream CommandStream The stream to remove.
function Extension.removeCommand(stream)
    Extension._remove(API._commandStreams, stream)
end

---Removes an emote from the registry.
---@param name string The name of the emote to remove.
function Extension.removeEmote(name)
    API._emotes[name] = nil
end

---Removes a rich text action handler.
---@param name string The name of the action to remove.
function Extension.removeRichTextAction(name)
    API.ui._actionHandlers[name] = nil
end

---Removes a handler for adding setting context menu options.
---@param category SettingCategory The setting category to remove from.
---@param callback fun(submenu: ISContextMenu) The setting handler callback to remove.
function Extension.removeSettingHandler(category, callback)
    local list = API.ui._settingHandlers[category]
    if list then
        Extension._remove(list, callback)
    end
end

---Removes a stream from the list of available chat streams.
---@param stream ChatStream The stream to remove.
function Extension.removeStream(stream)
    if not stream then
        return
    end

    -- remove from all streams table
    Extension._remove(ISChat.allChatStreams, stream)

    -- remove from tab streams
    local tabs = ISChat.instance and ISChat.instance.tabs
    if tabs then
        for i = 1, #tabs do
            Extension._remove(tabs[i].chatStreams, stream)
        end
    end
end

---Removes an argument type for suggester specs.
---@param argType string The argument type to remove.
function Extension.removeSuggesterType(argType)
    API.suggestion._customArgTypes[argType] = nil
end


---Inserts a chat stream relative to another.
---If the other chat stream isn't found, inserts at the end.
---@param stream ChatStream
---@param other ChatStream?
---@param relativeIndex integer The relative index.
---@return ChatStream
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


API.extension = Extension
return Extension
