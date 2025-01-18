---Client extension API.

---@class omichat.api.client
local API = require 'OmiChat/API/Client/Core'


---Inserts a chat stream relative to another.
---If the other chat stream isn't found, inserts at the end.
---@param stream omichat.ChatStream
---@param other omichat.ChatStream?
---@param value integer The relative index.
---@return omichat.ChatStream
local function insertStreamRelative(stream, other, value)
    if not other then
        return API.addStream(stream)
    end

    local pos = #ISChat.allChatStreams + 1
    for i = 1, #ISChat.allChatStreams do
        local chatStream = ISChat.allChatStreams[i]
        if chatStream == other then
            pos = i + value
            break
        end
    end

    table.insert(ISChat.allChatStreams, pos, stream)

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
                    pos = j + value
                    break
                end
            end

            table.insert(tab.chatStreams, pos, stream)
        end
    end

    return stream
end

---Sorts table items by priority.
---Not stable sorting.
---@param tab table
local function prioritySort(tab)
    table.sort(tab, function(a, b)
        local aPri = a.priority or 1
        local bPri = b.priority or 1

        return aPri > bPri
    end)
end

---Removes an element from a table, shifting subsequent elements.
---@param tab table
---@param target unknown
---@return boolean
local function remove(tab, target)
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


---Registers a new button for the chat.
---@param button ISButton
---@return ISButton
function API.addCustomButton(button)
    API._customButtons[#API._customButtons + 1] = button

    API.updateButtons()
    return button
end

---Adds information about a command that can be triggered from chat.
---@param stream omichat.CommandStream
function API.addCommand(stream)
    API._commandStreams[#API._commandStreams + 1] = stream
end

---Adds an emote that is playable from chat with the .emote syntax.
---@param name string The name of the emote, as it can be used from chat.
---@param emote (string | omichat.EmoteHandler) The string or handler to associate with the emote.
function API.addEmote(name, emote)
    if type(emote) ~= 'function' then
        emote = tostring(emote)
    end

    API._emotes[name] = emote
end

---Adds a message transformer which can act on message information to modify display or behavior.
---@param transformer omichat.MessageTransformer
function API.addMessageTransformer(transformer)
    API._transformers[#API._transformers + 1] = transformer
    prioritySort(API._transformers)
end

---Adds a handler for adding setting context menu options.
---@param category omichat.SettingCategory
---@param callback omichat.SettingHandlerCallback
function API.addSettingHandler(category, callback)
    local tab = API._settingHandlers[category]
    if tab then
        tab[#tab + 1] = callback
    end
end

---Adds a chat stream.
---@param stream omichat.ChatStream
---@return omichat.ChatStream
function API.addStream(stream)
    ISChat.allChatStreams[#ISChat.allChatStreams + 1] = stream

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
function API.addStreamAfter(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 1)
end

---Adds a chat stream before an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
---@return omichat.ChatStream
function API.addStreamBefore(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 0)
end

---Adds a suggester which can suggest inputs to the player.
---@param suggester omichat.Suggester
function API.addSuggester(suggester)
    API._suggesters[#API._suggesters + 1] = suggester
    prioritySort(API._suggesters)
end

---Registers an argument type for suggester specs.
---@param argType string
---@param callback omichat.SuggestSearchCallback
function API.addSuggesterArgType(argType, callback)
    API._customSuggesterArgTypes[argType] = callback
end

---Removes a registered custom button.
---This does not remove the button from the chat.
---@param button ISButton
function API.removeCustomButton(button)
    local pos
    for i = 1, #API._customButtons do
        if API._customButtons[i] == button then
            pos = i
            break
        end
    end

    if pos then
        table.remove(API._customButtons, pos)
    end
end

---Removes a stream from the list of available chat commands.
---@param stream omichat.CommandStream
function API.removeCommand(stream)
    remove(API._commandStreams, stream)
end

---Removes an emote from the registry.
---@param name string
function API.removeEmote(name)
    API._emotes[name] = nil
end

---Removes a message transformer.
---@param transformer omichat.MessageTransformer
function API.removeMessageTransformer(transformer)
    remove(API._transformers, transformer)
end

---Removes the first message transformer with the provided name.
---@param name string
function API.removeMessageTransformerByName(name)
    local target
    for i = 1, #API._transformers do
        local transformer = API._transformers[i]
        if transformer.name and transformer.name == name then
            target = i
            break
        end
    end

    if target then
        table.remove(API._transformers, target)
    end
end

---Removes a handler for adding setting context menu options.
---@param category omichat.SettingCategory
---@param callback omichat.SettingHandlerCallback
function API.removeSettingHandler(category, callback)
    local tab = API._settingHandlers[category]
    if tab then
        remove(tab, callback)
    end
end

---Removes a stream from the list of available chat streams.
---@param stream omichat.ChatStream
function API.removeStream(stream)
    if not stream then
        return
    end

    -- remove from all streams table
    remove(ISChat.allChatStreams, stream)

    -- remove from tab streams
    local tabs = ISChat.instance and ISChat.instance.tabs
    if tabs then
        remove(tabs, stream)
    end
end

---Removes a suggester.
---@param suggester omichat.Suggester
function API.removeSuggester(suggester)
    remove(API._suggesters, suggester)
end

---Removes an argument type for suggester specs.
---@param argType string
function API.removeSuggesterArgType(argType)
    API._customSuggesterArgTypes[argType] = nil
end

---Removes the first suggester with the provided name.
---@param name string
function API.removeSuggesterByName(name)
    local target
    for i = 1, #API._suggesters do
        local suggester = API._suggesters[i]
        if suggester.name and suggester.name == name then
            target = i
            break
        end
    end

    if target then
        table.remove(API._suggesters, target)
    end
end
