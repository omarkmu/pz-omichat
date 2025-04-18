---Suggesters for input content.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local min = math.min
local concat = table.concat
local ISChat = ISChat ---@cast ISChat omichat.ISChat


local MAX_RESULTS = 50


---@type omichat.Suggester[]
return {
    {
        name = 'commands',
        priority = 15,
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
                max = MAX_RESULTS,
            }, { includeVanillaCommandStreams = true })

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
        name = 'spec-suggestions',
        priority = 10,
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

            local argSpec = API.search.getSuggesterArgumentSpec(spec, idx)
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
                max = MAX_RESULTS,
            }

            if argType == 'online-username' then
                search = API.search.onlineUsernames(ctx, false)
            elseif argType == 'online-username-with-self' then
                search = API.search.onlineUsernames(ctx, true)
            elseif argType == 'language' then
                ctx.display = ctx.display or utils.getTranslatedLanguageName
                ctx.searchDisplay = utils.default(ctx.searchDisplay, true)
                search = API.search.strings(ctx, API.language.getList())
            elseif argType == 'known-language' then
                ctx.display = ctx.display or utils.getTranslatedLanguageName
                ctx.searchDisplay = utils.default(ctx.searchDisplay, true)
                search = API.search.strings(ctx, API.player.getLanguages())
            elseif argType == 'perk' then
                search = API.search.perks(ctx)
                applyQuotes = false
            elseif argType == 'option' and argSpec.options then
                search = API.search.strings(ctx, argSpec.options)
            else
                local callback = API.search.getSuggesterTypeCallback(argType)
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

            for i = 1, min(#search.results, MAX_RESULTS) do
                local result = search.results[i]
                local value = result.value
                local display = result.display or value

                if applyQuotes and utils.contains(value, ' ') then
                    value = concat({ '"', value:gsub('"', '\\"'), '"' })
                end

                info.suggestions[#info.suggestions + 1] = {
                    text = display,
                    content = prefix .. value .. suffix,
                }
            end
        end,
    },
    {
        name = 'emotes',
        priority = 5,
        suggest = function(_, info)
            if not config.Macros.AllowEmotes then
                return
            end

            local instance = ISChat.instance
            if not instance then
                return
            end

            local currentTabID = instance.currentTabID
            local stream = API.streams.chatCommandToStream(info.input)
            if not stream then
                if utils.startsWith(info.input, '/') then
                    -- disallow for unknown commands
                    return
                end

                local default = API.streams.getDefaultTabStream(currentTabID)
                if not default then
                    return
                end

                stream = default
            end

            if not stream:isTabID(currentTabID) then
                return
            end

            if not stream:isEnabled() or not stream:isAllowEmotes() then
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

            local search = API.search.strings(text, keys)
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
}
