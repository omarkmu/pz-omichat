---Handles suggesting text based on input.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'
local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local utils = API.utils
local config = API.Configuration
local concat = table.concat
local format = string.format

local ISChat = ISChat
local MAX_RESULTS = 30
local MAX_SEARCH = 100


---@class api.client.suggestion
local Suggestion = {}

---Contains functions for determining suggestions from input.
API.suggestion = Suggestion


---Associates names to custom suggestion spec argument type handlers.
---@type table<string, fun(ctx: SearchContext | string, spec: SuggestArgSpec): SearchResults?>
---@private
Suggestion._customArgTypes = {}


---Gets an argument spec table from a list of argument specs.
---@param spec SuggestArgSpec[] The list of argument specs.
---@param idx integer The index of the spec to retrieve.
---@return SuggestArgSpecTable? argSpec
function Suggestion.getArgSpec(spec, idx)
    local argSpec = spec[idx]
    if type(argSpec) == 'string' then
        argSpec = { type = argSpec }
    end

    ---@cast argSpec SuggestArgSpecTable?
    if not argSpec or argSpec.type == '?' then
        return
    end

    return argSpec
end

---Retrieves the search callback for a suggester argument type.
---@param argType string The name of the suggester argument type.
---@return (fun(ctx: SearchContext | string, spec: SuggestArgSpec): SearchResults?)? callback
function Suggestion.getArgTypeCallback(argType)
    return Suggestion._customArgTypes[argType]
end

---Suggests text based on the provided chat input text.
---@param text string The input text.
---@return omi.ui.SuggestBox.Suggestion[] suggestions A list of text suggestions.
function Suggestion.getChatSuggestions(text)
    if not text or text == '' then
        return {}
    end

    ---@type SuggestionInfo
    local info = {
        input = text,
        context = {},
        suggestions = {},
    }

    if API.hooks.has.chatSuggestions and API.hooks.chatSuggestions(info) then
        return info.suggestions
    end

    Suggestion._suggestCommands(info)
    Suggestion._suggestFromSpec(info)
    Suggestion._suggestEmotes(info)
    Suggestion._suggestMentions(info)

    return info.suggestions
end

---Retrieves a suggestion spec given the current input.
---@param input string The input text.
---@return SuggestArgSpec[]? spec A list of argument specs, or `nil` if no spec matches the input.
function Suggestion.getSpec(input)
    local stream = API.streams.chatCommandToStream(input, { enabledOnly = true })
    if stream then
        return stream:getSuggestSpec()
    end

    local accessLevel = utils.getEffectiveAccessLevel()
    if not accessLevel then
        return
    end

    -- vanilla command specs
    for i = 1, #vanillaCommands do
        local commandInfo = vanillaCommands[i]
        if utils.hasAccess(commandInfo.access, accessLevel) then
            local vanillaCommand = '/' .. commandInfo.name .. ' '
            if commandInfo.suggestSpec and utils.startsWith(input:lower(), vanillaCommand) then
                return commandInfo.suggestSpec
            end
        end
    end
end


---Gets the current stream from the chat input.
---@param input string
---@return Stream?
---@private
function Suggestion._getStreamFromInput(input)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local currentTabID = instance.currentTabID
    local stream = API.streams.chatCommandToStream(input, { enabledOnly = true })
    if not stream then
        if utils.startsWith(input, '/') then
            return
        end

        local default = API.streams.getDefaultTabStream(currentTabID)
        if not default or not default:isEnabled() then
            return
        end

        stream = default
    end

    if not stream:isTabID(currentTabID) then
        return
    end

    return stream
end

---Provides suggestions for command names.
---This includes chat commands, non-chat commands, vanilla commands, and unmanaged commands.
---@param info SuggestionInfo
---@private
function Suggestion._suggestCommands(info)
    local instance = ISChat.instance
    if not instance then
        return
    end

    if API.streams.chatCommandToStream(info.input) then
        -- already have a stream
        return
    end

    local command = info.input:match('^/(%S+)$')
    if not command then
        return
    end

    local search = API.search.streams({
        search = command,
        terminateOnExact = true,
        maxSearch = MAX_SEARCH,
        maxResults = MAX_RESULTS,
        includeVanillaCommandStreams = true,
        includeUnmanagedChatStreams = true,
    })

    for i = 1, #search.results do
        local result = search.results[i]
        local value = result.value

        info.suggestions[#info.suggestions + 1] = {
            text = result.display or value,
            content = value,
        }
    end
end

---Provides suggestions for emote macros.
---@param info SuggestionInfo
---@private
function Suggestion._suggestEmotes(info)
    if not config:isEmoteMacroEnabled() then
        return
    end

    local existingEmote = API.chat.getEmoteFromCommand(info.input)
    if existingEmote then
        return
    end

    local start, _, whitespace, mark, text = info.input:find('(%s*)()!([%w_]*)$')
    if not start or (start ~= 1 and #whitespace == 0) then
        -- require whitespace unless the emote is at the start
        return
    end

    local search = API.search.strings({
        search = text --[[@as string]],
        terminateOnExact = true,
        maxSearch = MAX_SEARCH,
        maxResults = MAX_RESULTS,
    }, API.chat.getEmoteNames())

    if search.exact then
        return
    end

    ---@cast mark -string, +integer
    local prefix = info.input:sub(1, mark)
    local results = search.results
    for i = 1, #results do
        local result = results[i]
        local emote = result.value

        info.suggestions[#info.suggestions + 1] = {
            text = '!' .. emote,
            content = prefix .. emote,
        }
    end
end

---Provides suggestions based on the command in use.
---@param info SuggestionInfo
---@private
function Suggestion._suggestFromSpec(info)
    local spec = Suggestion.getSpec(info.input)
    if not spec then
        return
    end

    local command = info.input
    local firstSpace = command:find(' ')
    if not firstSpace then
        return
    end

    local args, hasOpenQuote = utils.parseCommandArgs(command:sub(firstSpace + 1))

    local idx = #args
    if not hasOpenQuote and utils.endsWith(command, ' ') or idx == 0 then
        idx = idx + 1
    end

    local argSpec = Suggestion.getArgSpec(spec, idx)
    if not argSpec then
        return
    end

    local prefix, current
    if hasOpenQuote then
        prefix, current = command:match('(.+)"(.*)')
    else
        prefix, current = command:match('(.+%s)%s*(.*)')
    end

    if not prefix or not current then
        return
    end

    local search ---@type SearchResults
    local argType = argSpec.type
    local applyQuotes = true

    ---@type SearchContext
    local ctx = {
        search = current,
        terminateOnExact = true,
        filter = argSpec.filter,
        display = argSpec.display,
        searchDisplay = argSpec.searchDisplay,
        args = args,
        maxSearch = MAX_SEARCH,
        maxResults = MAX_RESULTS,
    }

    if argType == 'online-username' then
        search = API.search.onlineUsernames(ctx, false)
    elseif argType == 'online-username-with-self' then
        search = API.search.onlineUsernames(ctx, true)
    elseif argType == 'language' then
        search = API.search.languages(ctx, false)
    elseif argType == 'known-language' then
        search = API.search.languages(ctx, true)
    elseif argType == 'icon' then
        ctx.maxSearch = nil -- search all icons
        search = API.search.icons(ctx)
    elseif argType == 'perk' then
        search = API.search.perks(ctx)
        applyQuotes = false
    elseif argType == 'emote' then
        search = API.search.emotes(ctx)
    elseif argType == 'option' and argSpec.options then
        search = API.search.strings(ctx, argSpec.options)
    else
        local callback = Suggestion.getArgTypeCallback(argType)
        local cbResult = callback and callback(ctx, argSpec)
        if not cbResult then
            return
        end

        search = cbResult
    end

    if search.exact then
        return
    end

    prefix = prefix .. (argSpec.prefix or '')
    local suffix = argSpec.suffix or ' '

    for i = 1, #search.results do
        local result = search.results[i]
        local value = result.value
        local display = result.display or value

        if applyQuotes and utils.contains(value, ' ') then
            value = concat({ '"', value:gsub('"', '\\"'), '"' })
        end

        info.suggestions[#info.suggestions + 1] = {
            text = display,
            content = prefix .. value .. suffix,
            texture = result.texture,
        }
    end
end

---Provides suggestions for users to mention.
---@param info SuggestionInfo
---@private
function Suggestion._suggestMentions(info)
    if not config.Mentions.Enable then
        return
    end

    local stream = Suggestion._getStreamFromInput(info.input)
    if not stream or not stream:isAllowMentions() or not stream:isChatStream() then
        return
    end

    local prefix, text = info.input:match('(.*)@([%w_]*)$')
    if not prefix or not text then
        return
    end

    local range = config.Mentions.Range
    local isRanged = stream:isRanged()
    local chatType = stream:getChatType() --[[@as omi.ChatTypeString]]

    local search = API.search.onlineUsernamesByChatName(text, chatType, true)
    local results = search.results
    for i = 1, #results do
        local username = results[i].value

        local outOfRange = false
        if isRanged and range > 0 then
            outOfRange = not API.player.isWithinRange(range, utils.getPlayerByUsername(username))
        end

        local playerData = not outOfRange and API.data.getPlayerInfoByUsername(username, true)
        if playerData then
            local nickname = API.data.getNameInChat(username, chatType) or username
            local onlineID = playerData.onlineID
            local color = playerData.speechColor

            info.suggestions[#info.suggestions + 1] = {
                text = nickname,
                textColor = { r = color.r / 255, g = color.g / 255, b = color.b / 255, a = 1 },
                content = format('%s<@%03d:%s> ', prefix, onlineID, nickname),
            }
        end
    end
end


return Suggestion

--#region Type Definitions

---@class SuggestArgSpecTable
---@field type SuggestionType | string The type of the argument.
---@field prefix? string A prefix to apply to the suggestion result.
---@field suffix? string A suffix to apply to the suggestion result.
---@field options? string[] String options for the `option` suggestion type.
---@field searchDisplay? boolean Flag for whether the display string should be used for determining suggestions.
---@field filter? fun(result: any, args: string[]): boolean Filter function for results.
---@field display? fun(value: any, str: string): string? Function to retrieve display strings for results.


---@alias SuggestArgSpec SuggestArgSpecTable | SuggestionType | string

---@alias SuggestionType
---| 'online-username'
---| 'online-username-with-self'
---| 'language'
---| 'known-language'
---| 'icon'
---| 'perk'
---| 'option'
---| 'emote'
---| '?'

--#endregion
