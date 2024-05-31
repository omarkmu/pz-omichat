---Suggesters for input content.

local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local concat = table.concat
local min = math.min
local ISChat = ISChat ---@cast ISChat omichat.ISChat

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
local utils = OmiChat.utils
local MAX_RESULTS = 50


---Reads an arg spec from a suggest spec.
---@param spec omichat.SuggestSpec
---@param idx integer
---@return omichat.SuggestArgSpecTable?
local function getArgSpec(spec, idx)
    local argSpec = spec[idx]
    if type(argSpec) == 'string' then
        argSpec = { type = argSpec }
    end

    if not argSpec or argSpec.type == '?' then
        return
    end

    return argSpec
end

---Retrieves a suggestion spec given the current input.
---@param input string
---@return omichat.SuggestSpec?
local function getSuggestSpec(input)
    local stream = OmiChat.chatCommandToStream(input, true, true)
    if stream then
        return stream:suggestSpec()
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

            if OmiChat.chatCommandToStream(info.input) then
                -- already have a stream
                return
            end

            local command = info.input:match('^/(%S+)$')
            if not command then
                return
            end

            local search = OmiChat.searchStreams({
                search = command,
                terminateOnExact = true,
                max = MAX_RESULTS,
            }, { includeVanillaCommandStreams = true })

            for i = 1, #search.results do
                local result = search.results[i]
                local value = result.value

                info.suggestions[#info.suggestions + 1] = {
                    type = '',
                    display = result.display or value,
                    suggestion = value,
                }
            end
        end,
    },
    {
        name = 'spec-suggestions',
        priority = 10,
        suggest = function(_, info)
            local spec = getSuggestSpec(info.input)
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

            local argSpec = getArgSpec(spec, idx)
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
                search = OmiChat.searchOnlineUsernames(ctx)
            elseif argType == 'online-username-with-self' then
                search = OmiChat.searchOnlineUsernames(ctx, true)
            elseif argType == 'language' then
                ctx.display = ctx.display or utils.getTranslatedLanguageName
                ctx.searchDisplay = utils.default(ctx.searchDisplay, true)
                search = OmiChat.searchStrings(ctx, OmiChat.getConfiguredRoleplayLanguages())
            elseif argType == 'known-language' then
                ctx.display = ctx.display or utils.getTranslatedLanguageName
                ctx.searchDisplay = utils.default(ctx.searchDisplay, true)
                search = OmiChat.searchStrings(ctx, OmiChat.getRoleplayLanguages())
            elseif argType == 'perk' then
                search = OmiChat.searchPerks(ctx)
                applyQuotes = false
            elseif argType == 'option' and argSpec.options then
                search = OmiChat.searchStrings(ctx, argSpec.options)
            else
                local callback = OmiChat.getSuggesterArgTypeCallback(argType)
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
                    type = '',
                    display = display,
                    suggestion = prefix .. value .. suffix,
                }
            end
        end,
    },
    {
        name = 'emotes',
        priority = 5,
        suggest = function(_, info)
            local instance = ISChat.instance
            if not instance then
                return
            end

            local currentTabID = instance.currentTabID
            local stream = OmiChat.chatCommandToStream(info.input)
            if not stream then
                if utils.startsWith(info.input, '/') then
                    -- disallow for unknown commands
                    return
                end

                local default = OmiChat.getDefaultTabStream(currentTabID)
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

            local existingEmote = OmiChat.getEmoteFromCommand(info.input)
            if existingEmote then
                return
            end

            local start, _, whitespace, period, text = info.input:find('(%s*)()%.([%w_]*)$')
            if not start or (start ~= 1 and #whitespace == 0) then
                -- require whitespace unless the emote is at the start
                return
            end

            local keys = {}
            for k in pairs(OmiChat._emotes) do
                keys[#keys + 1] = k
            end

            local search = OmiChat.searchStrings(text, keys)
            if search.exact then
                return
            end

            local prefix = info.input:sub(1, period)
            local results = search.results
            for i = 1, #results do
                local emote = results[i].value
                info.suggestions[#info.suggestions + 1] = {
                    type = '',
                    display = '.' .. emote,
                    suggestion = prefix .. emote,
                }
            end
        end,
    },
}
