---Client extension API.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'


---Inserts a chat stream relative to another.
---If the other chat stream isn't found, inserts at the end.
---@param stream omichat.ChatStream
---@param other omichat.ChatStream?
---@param value integer The relative index.
---@return omichat.ChatStream
local function insertStreamRelative(stream, other, value)
    if not other then
        return OmiChat.addStream(stream)
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
        if stream.tabID == tab.tabID + 1 then
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
function OmiChat.addCustomButton(button)
    OmiChat._customButtons[#OmiChat._customButtons + 1] = button

    OmiChat.updateButtons()
    return button
end

---Adds information about a command that can be triggered from chat.
---@param stream omichat.CommandStream
function OmiChat.addCommand(stream)
    if not stream.omichat then
        stream.omichat = {}
    end

    stream.omichat.isCommand = true
    OmiChat._commandStreams[#OmiChat._commandStreams + 1] = stream
end

---Adds an emote that is playable from chat with the .emote syntax.
---@param name string The name of the emote, as it can be used from chat.
---@param emote string The string to associate with the emote.
function OmiChat.addEmote(name, emote)
    OmiChat._emotes[name] = tostring(emote)
end

---Adds a message transformer which can act on message information to modify display or behavior.
---@param transformer omichat.MessageTransformer
function OmiChat.addMessageTransformer(transformer)
    OmiChat._transformers[#OmiChat._transformers + 1] = transformer
    prioritySort(OmiChat._transformers)
end

---Adds a handler for adding setting context menu options.
---@param category omichat.SettingCategory
---@param callback omichat.SettingHandlerCallback
function OmiChat.addSettingHandler(category, callback)
    local tab = OmiChat._settingHandlers[category]
    if tab then
        tab[#tab + 1] = callback
    end
end

---Adds a chat stream.
---@param stream omichat.ChatStream
---@return omichat.ChatStream
function OmiChat.addStream(stream)
    ISChat.allChatStreams[#ISChat.allChatStreams + 1] = stream

    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for i = 1, #tabs do
        local tab = tabs[i]
        if stream.tabID == tab.tabID + 1 then
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
function OmiChat.addStreamAfter(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 1)
end

---Adds a chat stream before an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
---@return omichat.ChatStream
function OmiChat.addStreamBefore(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 0)
end

---Adds a suggester which can suggest inputs to the player.
---@param suggester omichat.Suggester
function OmiChat.addSuggester(suggester)
    OmiChat._suggesters[#OmiChat._suggesters + 1] = suggester
    prioritySort(OmiChat._suggesters)
end

---Registers an argument type for suggester specs.
---@param argType string
---@param callback omichat.SuggestSearchCallback
function OmiChat.addSuggesterArgType(argType, callback)
    OmiChat._customSuggesterArgTypes[argType] = callback
end

---Removes a registered custom button.
---This does not remove the button from the chat.
---@param button ISButton
function OmiChat.removeCustomButton(button)
    local pos
    for i = 1, #OmiChat._customButtons do
        if OmiChat._customButtons[i] == button then
            pos = i
            break
        end
    end

    if pos then
        table.remove(OmiChat._customButtons, pos)
    end
end

---Removes a stream from the list of available chat commands.
---@param stream omichat.CommandStream
function OmiChat.removeCommand(stream)
    remove(OmiChat._commandStreams, stream)
end

---Removes an emote from the registry.
---@param name string
function OmiChat.removeEmote(name)
    OmiChat._emotes[name] = nil
end

---Removes a message transformer.
---@param transformer omichat.MessageTransformer
function OmiChat.removeMessageTransformer(transformer)
    remove(OmiChat._transformers, transformer)
end

---Removes the first message transformer with the provided name.
---@param name string
function OmiChat.removeMessageTransformerByName(name)
    local target
    for i = 1, #OmiChat._transformers do
        local transformer = OmiChat._transformers[i]
        if transformer.name and transformer.name == name then
            target = i
            break
        end
    end

    if target then
        table.remove(OmiChat._transformers, target)
    end
end

---Removes a handler for adding setting context menu options.
---@param category omichat.SettingCategory
---@param callback omichat.SettingHandlerCallback
function OmiChat.removeSettingHandler(category, callback)
    local tab = OmiChat._settingHandlers[category]
    if tab then
        remove(tab, callback)
    end
end

---Removes a stream from the list of available chat streams.
---@param stream omichat.ChatStream
function OmiChat.removeStream(stream)
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
function OmiChat.removeSuggester(suggester)
    remove(OmiChat._suggesters, suggester)
end

---Removes an argument type for suggester specs.
---@param argType string
function OmiChat.removeSuggesterArgType(argType)
    OmiChat._customSuggesterArgTypes[argType] = nil
end

---Removes the first suggester with the provided name.
---@param name string
function OmiChat.removeSuggesterByName(name)
    local target
    for i = 1, #OmiChat._suggesters do
        local suggester = OmiChat._suggesters[i]
        if suggester.name and suggester.name == name then
            target = i
            break
        end
    end

    if target then
        table.remove(OmiChat._suggesters, target)
    end
end
