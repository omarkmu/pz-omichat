---Handles searching.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client
local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local utils = API.utils


---@class omichat.api.client.search
local Search = {}
Search._customSuggesterTypes = {}


---@type omichat.search.PerkInfo[]
local perkList = {}; do
    local perkArrayList = PerkFactory.PerkList
    for i = 0, perkArrayList:size() - 1 do
        local perk = perkArrayList:get(i) ---@cast perk Perk
        if perk:getParent() ~= Perks.None then
            perkList[#perkList + 1] = {
                perk = perk,
                name = perk:getName():lower(),
                id = perk:getId():lower(),
            }
        end
    end

    table.sort(perkList, function(a, b) return not string.sort(a.name, b.name) end)
end


---Reads an arguments spec from a suggestion spec.
---@param spec omichat.SuggestSpec
---@param idx integer
---@return omichat.SuggestArgSpecTable?
function Search.getSuggesterArgumentSpec(spec, idx)
    local argSpec = spec[idx]
    if type(argSpec) == 'string' then
        argSpec = { type = argSpec }
    end

    if not argSpec or argSpec.type == '?' then
        return
    end

    return argSpec
end

---Retrieves the search callback for a suggester argument type.
---@param argType string
---@return omichat.SuggestSearchCallback?
function Search.getSuggesterTypeCallback(argType)
    return Search._customSuggesterTypes[argType]
end

---Retrieves a suggestion spec given the current input.
---@param input string
---@return omichat.SuggestSpec?
function Search.getSuggestionSpec(input)
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

---Searches for a roleplay language with loose matching.
---@param input string
---@param languages string[]
---@return string?
function Search.matchLanguage(input, languages)
    ---@type omichat.SearchContext
    local ctx = {
        terminateOnExact = true,
        searchDisplay = true,
        search = input,
        display = utils.getTranslatedLanguageName,
    }

    local searchResult = Search.strings(ctx, languages)
    if searchResult.exact then
        return searchResult.exact.value
    end

    local result = searchResult.results[1]
    if result then
        return result.value
    end
end

---Collects online usernames based on a search string.
---@param ctxOrSearch omichat.SearchContext | string Context for the search.
---@param includeSelf boolean? If true, player 1's username will be included in the search.
---@return omichat.SearchResults
function Search.onlineUsernames(ctxOrSearch, includeSelf)
    local ctx = Search._buildContext(ctxOrSearch)
    local player = getSpecificPlayer(0)
    local ownUsername = player and player:getUsername()

    local exact
    for _, item in API.data.iteratePlayerCache() do
        local result = Search._playerUsername(item, ctx, ownUsername, includeSelf)
        if result and result.exact then
            exact = result
            if ctx.terminateOnExact then
                break
            end
        end
    end

    return {
        exact = exact,
        results = utils.append(ctx.startsWith, ctx.contains),
    }
end

---Collects perk IDs based on a search string.
---@param ctxOrSearch omichat.SearchContext | string
---@return omichat.SearchResults
function Search.perks(ctxOrSearch)
    local ctx = Search._buildContext(ctxOrSearch)
    ctx.display = ctx.display or Search._getPerkDisplay
    ctx.mapValue = Search._mapPerkToId

    local exact
    for i = 1, #perkList do
        local info = perkList[i]
        local result = Search._internal(ctx, info.id, info.perk, info.name)
        if result and result.exact and ctx.terminateOnExact then
            exact = result
            break
        end
    end

    return {
        exact = exact,
        results = utils.append(ctx.startsWith, ctx.contains),
    }
end

---Collects commands based on a search string.
---@param ctxOrSearch omichat.SearchContext | string
---@param options omichat.StreamSearchOptions
---@return omichat.SearchResults
function Search.streams(ctxOrSearch, options)
    local ctx = Search._buildContext(ctxOrSearch)

    ctx.searchForStartsWith = '/' .. ctx.search
    ctx.display = ctx.display or Search._mapToValue
    ctx.filter = ctx.filter or Search._filterStream

    local exact
    local streamList = Search._buildStreamList(options)
    for i = 1, #streamList do
        local result
        local stream = streamList[i]
        if utils.isinstance(stream, API.Stream) then
            ---@cast stream omichat.Stream
            ctx.caseInsensitive = stream:isCaseInsensitive()
            result = Search._internal(ctx, stream:getCommand(), stream, stream:getShortCommand())

            if not result then
                for alias in stream:aliases() do
                    result = Search._internal(ctx, alias, stream)
                    if result then
                        break
                    end
                end
            end
        else
            ---@cast stream omichat.VanillaCommand
            ctx.caseInsensitive = true
            result = Search._internal(ctx, '/' .. stream.name .. ' ', stream)
        end

        if result and result.exact and ctx.terminateOnExact then
            exact = result
            break
        end
    end

    local seen = {}
    if exact then
        seen[exact.display] = true
    end

    local results = {}
    local streamResults = utils.append(ctx.startsWith, ctx.contains)
    for i = 1, #streamResults do
        local result = streamResults[i]
        local stream = result.value
        local command = result.display

        if command and (result == exact or not seen[command]) then
            result.value = command
            result.display = Search._getStreamDisplay(stream, command)

            results[#results + 1] = result
            seen[command] = true
        end
    end

    return {
        exact = exact,
        results = results,
    }
end

---Collects results from a list of strings based on a search string.
---@param ctxOrSearch omichat.SearchContext | string Context for the search.
---@param list string[] The list of strings to search.
---@return omichat.SearchResults
function Search.strings(ctxOrSearch, list)
    local ctx = Search._buildContext(ctxOrSearch)

    local exact
    for i = 1, #list do
        local result = Search._internal(ctx, list[i])
        if result and result.exact then
            exact = result
            if ctx.terminateOnExact then
                break
            end
        end
    end

    ---@type omichat.SearchResults
    return {
        exact = exact,
        results = utils.append(ctx.startsWith, ctx.contains),
    }
end


---Creates internal context given search context.
---@param ctx omichat.SearchContext | string
---@return omichat.search.InternalSearchContext
---@private
function Search._buildContext(ctx)
    if type(ctx) == 'string' then
        ctx = { search = ctx }
    end

    ---@type omichat.search.InternalSearchContext
    return {
        search = utils.trim(ctx.search:lower()),
        display = ctx.display,
        filter = ctx.filter,
        max = ctx.max,
        args = ctx.args or {},
        searchDisplay = ctx.searchDisplay,
        terminateOnExact = ctx.terminateOnExact,
        startsWith = {},
        contains = {},
    }
end

---Builds a list of streams to search.
---@param options omichat.StreamSearchOptions
---@return (omichat.Stream | omichat.VanillaCommand)[]
---@private
function Search._buildStreamList(options)
    local list = {}
    if not options.excludeChatStreams then
        for stream in API.streams.chatStreams() do
            list[#list + 1] = stream
        end
    end

    if not options.excludeCommandStreams then
        for i = 1, #API._commandStreams do
            list[#list + 1] = API._commandStreams[i]
        end
    end

    if options.includeVanillaCommandStreams then
        for i = 1, #vanillaCommands do
            list[#list + 1] = vanillaCommands[i]
        end
    end

    return list
end

---Performs a string search.
---@param ctx omichat.search.InternalSearchContext Search context.
---@param primary string Primary string to search.
---@param value unknown? Object to use as the result value instead of `primary`.
---@param ... string Secondary strings to search.
---@return omichat.search.InternalSearchResult?
---@private
function Search._internal(ctx, primary, value, ...)
    if value == nil then
        value = primary
    end

    if ctx.filter and not ctx.filter(value, ctx.args) then
        return
    end

    local search = ctx.search
    local mapValue = ctx.mapValue
    local strings = { primary, ... }
    local compare = {}

    if ctx.caseInsensitive then
        search = search:lower()
    end

    ---@type omichat.search.InternalSearchResult?
    local result

    -- check for exact match
    if #search > 0 then
        for i = 1, #strings do
            local str = strings[i]
            local lower = str:lower()
            local match = lower == search

            local display
            if not match and ctx.searchDisplay then
                display = ctx.display and ctx.display(value, str) or nil
                match = display ~= nil and display:lower() == search
            end

            if match then
                result = {
                    value = mapValue and mapValue(value, str) or value,
                    display = ctx.display and ctx.display(value, str) or nil,
                    exact = true,
                }

                ctx.startsWith[#ctx.startsWith + 1] = result
                return result
            end

            compare[i] = lower
        end
    end

    if ctx.max and #ctx.startsWith + #ctx.contains >= ctx.max then
        -- exceeded maximum
        return
    end

    if #search == 0 then
        -- no search → include all
        result = {
            value = mapValue and mapValue(value, primary) or value,
            display = ctx.display and ctx.display(value, primary) or nil,
            exact = false,
        }

        ctx.startsWith[#ctx.startsWith + 1] = result
        return result
    end

    for i = 1, #strings do
        local str = strings[i]
        local swSearch = ctx.searchForStartsWith or search
        local match = utils.startsWith(compare[i], swSearch)
        if not match and ctx.searchDisplay then
            local display = ctx.display and ctx.display(value, str) or nil
            if display and utils.startsWith(display:lower(), swSearch) then
                match = true
            end
        end

        if match then
            result = {
                value = mapValue and mapValue(value, str) or value,
                display = ctx.display and ctx.display(value, str) or nil,
                exact = false,
            }

            ctx.startsWith[#ctx.startsWith + 1] = result
            return result
        end
    end

    for i = 1, #strings do
        local str = strings[i]
        local ctSearch = ctx.searchForContains or search
        local match = utils.contains(compare[i], ctSearch)
        if not match and ctx.searchDisplay then
            local display = ctx.display and ctx.display(value, str) or nil
            if display and utils.contains(display:lower(), ctSearch) then
                match = true
            end
        end

        if match then
            result = {
                value = mapValue and mapValue(value, str) or value,
                display = ctx.display and ctx.display(value, str) or nil,
                exact = false,
            }

            ctx.contains[#ctx.contains + 1] = result
            return result
        end
    end
end

---Filter function for streams.
---@param stream omichat.Stream | omichat.VanillaCommand
---@return boolean
---@private
function Search._filterStream(stream)
    if utils.isinstance(stream, API.Stream) then
        ---@cast stream omichat.Stream
        local tabID = ISChat.instance.currentTabID
        return stream:isTabID(tabID) and stream:isEnabled()
    end

    local accessLevel = utils.getEffectiveAccessLevel()
    if not accessLevel then
        return false
    end

    ---@cast stream omichat.VanillaCommand
    return utils.hasAccess(stream.access, accessLevel)
end

---Display function for perks.
---@param perk Perk
---@return string
---@private
function Search._getPerkDisplay(perk)
    return perk:getName() .. ' (' .. perk:getParent():getName() .. ')'
end

---Display function for streams.
---@param stream omichat.Stream | omichat.VanillaCommand
---@param command string
---@return string
---@private
function Search._getStreamDisplay(stream, command)
    if not utils.isinstance(stream, API.Stream) then
        return command
    end

    ---@cast stream omichat.Stream
    local streamCommand = utils.trim(stream:getCommand())

    command = utils.trim(command)
    if command ~= streamCommand then
        return command .. ' [' .. streamCommand .. ']'
    end

    return command
end

---Search map function that returns the string value.
---@param _ unknown
---@param command string
---@return string
---@private
function Search._mapToValue(_, command)
    return command
end

---Returns the ID of a perk.
---@param perk Perk
---@return string
---@private
function Search._mapPerkToId(perk)
    return perk:getId()
end

---Checks whether a player should be included in the username search.
---@param player IsoPlayer | omi.PlayerCacheData
---@param ctx omichat.search.InternalSearchContext
---@param ownUsername string
---@param includeSelf boolean?
---@return omichat.search.InternalSearchResult?
---@private
function Search._playerUsername(player, ctx, ownUsername, includeSelf)
    local username
    if player.getUsername then
        ---@cast player IsoPlayer
        username = player:getUsername()
    else
        username = player.username
    end

    if username and (includeSelf or username ~= ownUsername) then
        return Search._internal(ctx, username)
    end
end


API.search = Search
return Search
