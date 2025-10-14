---Suggesters for input content.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local concat = table.concat
local format = string.format
local ISChat = ISChat ---@cast ISChat omichat.ISChat

local MAX_RESULTS = 30
local MAX_SEARCH = 100


---Gets the current stream from the chat input.
---@param input string
---@return omichat.Stream?
local function getStreamFromInput(input)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local currentTabID = instance.currentTabID
    local stream = API.streams.chatCommandToStream(input)
    if not stream then
        if utils.startsWith(input, '/') then
            return
        end

        local default = API.streams.getDefaultTabStream(currentTabID)
        if not default then
            return
        end

        stream = default
    end

    if not stream:isTabID(currentTabID) or not stream:isEnabled() then
        return
    end

    return stream
end


---@type omichat.Suggester[]
return {
    {
        -- Provides suggestions for command names.
        name = 'commands',
        priority = 100,
        suggest = function(_, info)
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
        end,
    },
    {
        -- Provides suggestions based on a stream's suggestion spec.
        name = 'spec-suggestions',
        priority = 90,
        suggest = function(_, info)
            local spec = API.search.getSuggestionSpec(info.input)
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

            local argSpec = API.search.getSuggestionArgumentSpec(spec, idx)
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

            local search ---@type omichat.SearchResults
            local argType = argSpec.type
            local applyQuotes = true

            ---@type omichat.SearchContext
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
            elseif argType == 'option' and argSpec.options then
                search = API.search.strings(ctx, argSpec.options)
            else
                local callback = API.search.getSuggestionTypeCallback(argType)
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
        end,
    },
    {
        -- Provides suggestions for emote animation shortcuts.
        name = 'emotes',
        priority = 80,
        suggest = function(_, info)
            if not config.Macros.AllowEmotes then
                return
            end

            local stream = getStreamFromInput(info.input)
            if not stream or not stream:isAllowEmotes() then
                return
            end

            local existingEmote = API.chat.getEmoteFromCommand(info.input)
            if existingEmote then
                return
            end

            local start, _, whitespace, period, text = info.input:find('(%s*)()%.([%w_]*)$')
            if not start or (start ~= 1 and #whitespace == 0) then
                -- require whitespace unless the emote is at the start
                return
            end

            local keys = {}
            for k in pairs(API._emotes) do
                keys[#keys + 1] = k
            end

            local search = API.search.strings({
                search = text,
                terminateOnExact = true,
                maxSearch = MAX_SEARCH,
                maxResults = MAX_RESULTS,
            }, keys)

            if search.exact then
                return
            end

            local prefix = info.input:sub(1, period)
            local results = search.results
            for i = 1, #results do
                local emote = results[i].value
                info.suggestions[#info.suggestions + 1] = {
                    text = '.' .. emote,
                    content = prefix .. emote,
                }
            end
        end,
    },
    {
        -- Provides suggestions for mentions.
        name = 'mentions',
        priority = 70,
        suggest = function(_, info)
            if not config.Mentions.Enable then
                return
            end

            local stream = getStreamFromInput(info.input) --[[@as omichat.ChatStream?]]
            if not stream or not stream:isAllowMentions() or stream:isCommandStream() then
                return
            end

            local prefix, text = info.input:match('(.*)@([%w_]*)$')
            if not prefix or not text then
                return
            end

            local range = config.Mentions.Range
            local isRanged = stream:isRanged()
            local chatType = stream:getChatType()

            local search = API.search.onlineUsernamesByChatName(text, chatType, true)
            local results = search.results
            for i = 1, #results do
                local username = results[i].value

                local outOfRange = false
                if isRanged and range > 0 then
                    local dist = API.player.getDistanceFrom(utils.getPlayerByUsername(username))

                    if not dist or dist > range then
                        outOfRange = true
                    end
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
        end,
    },
}
