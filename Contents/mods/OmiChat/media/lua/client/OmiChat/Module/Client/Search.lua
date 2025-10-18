---Handles searching.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client
local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

local utils = API.utils
local sort = table.sort
local getTexture = getTexture
local ISChat = ISChat


---Contains functions for performing searches.
---@class omichat.api.client.search
---@field private _customSuggesterTypes table<string, omichat.SuggestSearchCallback> Associates names to custom suggestion spec argument type handlers.
---@field private _perkList omichat.search.PerkInfo[]? Lazy-loaded list with information about perks.
---@field private _iconList omichat.search.IconInfo[]? Lazy-loaded list with information about icons.
local Search = {}

Search._customSuggesterTypes = {}


---Converts search results to a list of suggestions to use for a suggest box.
---@param search omichat.SearchResults The results of the search.
---@param allowExact boolean? Flag for whether an exact match should be ignored. Unless this is `true`, an empty table will be returned if there's an exact match.
---@return omi.ui.SuggestBox.Suggestion[] suggestions
function Search.getSuggestions(search, allowExact)
    if search.exact and not allowExact then
        return {}
    end

    local suggestions = {} ---@type omi.ui.SuggestBox.Suggestion[]
    for i = 1, #search.results do
        local result = search.results[i]
        suggestions[#suggestions + 1] = {
            text = result.display,
            content = result.value,
            texture = result.texture,
        }
    end

    return suggestions
end

---Gets an argument spec table from a list of argument specs.
---@param spec omichat.SuggestArgSpec[] The list of argument specs.
---@param idx integer The index of the spec to retrieve.
---@return omichat.SuggestArgSpecTable? argSpec
function Search.getSuggestionArgumentSpec(spec, idx)
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
---@param argType string The name of the suggester argument type.
---@return omichat.SuggestSearchCallback? callback
function Search.getSuggestionTypeCallback(argType)
    return Search._customSuggesterTypes[argType]
end

---Retrieves a suggestion spec given the current input.
---@param input string The input text.
---@return omichat.SuggestArgSpec[]? spec A list of argument specs, or `nil` if no spec matches the input.
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

---Searches for an icon by texture name or chat alias.
---@param ctxOrSearch omichat.SearchContext | string A search string or a table with options for the search.
---@return omichat.SearchResults results
function Search.icons(ctxOrSearch)
    local ctx = Search._buildContext(ctxOrSearch)
    ctx.display = ctx.display or Search._getIconDisplay
    ctx.mapValue = ctx.mapValue or Search._getIconDisplay
    ctx.mapTexture = ctx.mapTexture or Search._getIconTexture

    local icons = Search._buildIconList()
    for i = 1, #icons do
        local info = icons[i]
        Search._internal(ctx, info.alias, info)

        if ctx.isTerminated then
            break
        end
    end

    return Search._collectResults(ctx)
end

---Searches either the language list or the current player's known languages for a string.
---@param ctxOrSearch omichat.SearchContext | string A search string or a table with options for the search.
---@param onlyKnown boolean? Flag for whether only the current player's known languages should be searched.
---@return omichat.SearchResults results
function Search.languages(ctxOrSearch, onlyKnown)
    local ctx = Search._buildContext(ctxOrSearch)
    ctx.display = ctx.display or utils.getTranslatedLanguageName
    ctx.searchDisplay = ctx.searchDisplay ~= false

    local list = onlyKnown and API.player.getLanguages() or API.language.getList()

    for i = 1, #list do
        Search._internal(ctx, list[i])

        if ctx.isTerminated then
            break
        end
    end

    return Search._collectResults(ctx)
end

---Searches for a roleplay language with loose matching.
---@param input string The input search string.
---@param languages string[]? The languages to search. Defaults to the current player's known languages.
---@return string? match The untranslated language name that matches the input.
function Search.matchLanguage(input, languages)
    languages = languages or API.player.getLanguages()

    ---@type omichat.SearchContext
    local ctx = {
        search = input,
        searchDisplay = true,
        terminateOnExact = true,
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
---@param ctxOrSearch omichat.SearchContext | string A search string or a table with options for the search.
---@param includeSelf boolean? Flag for whether player 1's username should be included in the search.
---@return omichat.SearchResults results
function Search.onlineUsernames(ctxOrSearch, includeSelf)
    local ctx = Search._buildContext(ctxOrSearch)
    local player = getSpecificPlayer(0)
    local ownUsername = player and player:getUsername()

    for _, item in API.data.iteratePlayerCache() do
        Search._playerUsername(item, ctx, ownUsername, includeSelf)

        if ctx.isTerminated then
            break
        end
    end

    return Search._collectResults(ctx)
end

---Collects usernames based on a search string by matching on chat names.
---@param ctxOrSearch omichat.SearchContext | string A search string or a table with options for the search.
---@param chatType string? The chat type to use names from. Defaults to `say`.
---@param includeSelf boolean? Flag for whether player 1's username should be included in the search.
---@param searchUsernames boolean? Flag for whether usernames should also be matched on.
---@return omichat.SearchResults results
function Search.onlineUsernamesByChatName(ctxOrSearch, chatType, includeSelf, searchUsernames)
    local ctx = Search._buildContext(ctxOrSearch)
    ctx.display = ctx.display or Search._mapPlayerInfoToName
    ctx.mapValue = ctx.mapValue or Search._mapPlayerInfoToUsername

    local player = getSpecificPlayer(0)
    local ownUsername = player and player:getUsername()
    chatType = chatType or 'say'

    for _, item in API.data.iteratePlayerCache() do
        Search._playerChatName(item, chatType, ctx, ownUsername, includeSelf, searchUsernames)

        if ctx.isTerminated then
            break
        end
    end

    return Search._collectResults(ctx)
end

---Collects perk IDs based on a search string.
---@param ctxOrSearch omichat.SearchContext | string A search string or a table with options for the search.
---@return omichat.SearchResults results
function Search.perks(ctxOrSearch)
    local ctx = Search._buildContext(ctxOrSearch)
    ctx.display = ctx.display or Search._getPerkDisplay
    ctx.mapValue = ctx.mapValue or Search._mapPerkToId

    local perkList = Search._buildPerkList()
    for i = 1, #perkList do
        local info = perkList[i]
        Search._internal(ctx, info.id, info.perk, info.name)

        if ctx.isTerminated then
            break
        end
    end

    return Search._collectResults(ctx)
end

---Populates a suggest box with search results.
---@param suggestBox omi.ui.SuggestBox The suggest box to populate.
---@param search omichat.SearchResults The results of the search.
---@param allowExact boolean? Flag for whether an exact match should be ignored. Unless this is `true`, suggestions will be cleared for an exact match.
function Search.populateSuggestions(suggestBox, search, allowExact)
    suggestBox:setSuggestions(Search.getSuggestions(search, allowExact))
end

---Collects stream commands based on a search string.
---@param argsOrSearch omichat.Args.StreamSearch | string A search string or a table with options for the search.
---@return omichat.SearchResults results
function Search.streams(argsOrSearch)
    local ctx = Search._buildContext(argsOrSearch)
    local options = type(argsOrSearch) == 'table' and argsOrSearch or {} --[[@as omichat.StreamSearchOptions]]

    ctx.searchForStartsWith = '/' .. ctx.search
    ctx.display = ctx.display or Search._mapToCompareString
    ctx.filter = ctx.filter or Search._filterStream

    local streamList = Search._buildStreamList(options)
    for i = 1, #streamList do
        local stream = streamList[i]
        if utils.isinstance(stream, API.Stream) then
            ---@cast stream omichat.Stream
            ctx.caseSensitive = not stream:isCaseInsensitive()

            if not Search._internal(ctx, stream:getCommand(), stream, stream:getShortCommand()) then
                for alias in stream:aliases() do
                    if Search._internal(ctx, alias, stream) then
                        break
                    end
                end
            end
        else
            ---@cast stream omichat.VanillaCommand | omichat.StreamTable
            ctx.caseSensitive = stream.tabID == nil
            Search._internal(ctx, stream.command or ('/' .. stream.name .. ' '), stream)
        end

        if ctx.isTerminated then
            break
        end
    end

    local seen = {}
    local results = {}
    local collected = Search._collectResults(ctx)
    for i = 1, #collected.results do
        local result = collected.results[i]
        local stream = result.value --[[@as omichat.Stream]]
        local command = result.display

        if command and (result == ctx.exactInternal or not seen[command]) then
            result.value = command
            result.display = Search._getStreamDisplay(stream, command)

            results[#results + 1] = result
            seen[command] = true
        end
    end

    collected.results = results
    return collected
end

---Collects results from a list of strings based on a search string.
---@param ctxOrSearch omichat.SearchContext | string A search string or a table with options for the search.
---@param list string[] The list of strings to search.
---@return omichat.SearchResults results
function Search.strings(ctxOrSearch, list)
    local ctx = Search._buildContext(ctxOrSearch)

    for i = 1, #list do
        Search._internal(ctx, list[i])

        if ctx.isTerminated then
            break
        end
    end

    return Search._collectResults(ctx)
end


---Builds internal search context.
---@param ctx omichat.SearchContext | string A search string or a table with options for the search.
---@return omichat.search.InternalSearchContext ctx
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
        maxResults = ctx.maxResults,
        maxSearch = ctx.maxSearch,
        args = ctx.args or {},
        searchDisplay = ctx.searchDisplay,
        terminateOnExact = ctx.terminateOnExact,
        startsWith = {},
        contains = {},
    }
end

---Builds a list of icons, or returns the cached list if already built.
---@return omichat.search.IconInfo[] iconList
---@private
function Search._buildIconList()
    if Search._iconList then
        return Search._iconList
    end

    local iconList = {} ---@type omichat.search.IconInfo[]
    for alias, name in utils.iterateIcons() do
        iconList[#iconList + 1] = {
            name = name,
            alias = alias,
        }
    end

    sort(iconList, function(a, b) return not string.sort(a.alias, b.alias) end)

    Search._iconList = iconList
    return iconList
end

---Builds a list of perks, or returns the cached list if already built.
---@return omichat.search.PerkInfo[] perkList
---@private
function Search._buildPerkList()
    if Search._perkList then
        return Search._perkList
    end

    local perkList = {} ---@type omichat.search.PerkInfo[]
    local perkArrayList = PerkFactory.PerkList
    for i = 0, perkArrayList:size() - 1 do
        local perk = perkArrayList:get(i) --[[@as Perk]]
        if perk:getParent() ~= Perks.None then
            perkList[#perkList + 1] = {
                perk = perk,
                name = perk:getName():lower(),
                id = perk:getId():lower(),
            }
        end
    end

    sort(perkList, function(a, b) return not string.sort(a.name, b.name) end)

    Search._perkList = perkList
    return perkList
end

---Builds a list of streams to search.
---@param options omichat.StreamSearchOptions
---@return (omichat.Stream | omichat.VanillaCommand | omichat.StreamTable)[] streamList
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

    if options.includeUnmanagedChatStreams then
        for i = 1, #ISChat.allChatStreams do
            local stream = ISChat.allChatStreams[i]
            if not utils.isinstance(stream, API.Stream) then
                list[#list + 1] = stream
            end
        end
    end

    return list
end

---Collects the search results.
---@param ctx omichat.search.InternalSearchContext
---@return omichat.SearchResults search
---@private
function Search._collectResults(ctx)
    local mergedResults = utils.append(ctx.startsWith, ctx.contains)
    if ctx.maxResults and #mergedResults > ctx.maxResults then
        for i = ctx.maxResults + 1, #mergedResults do
            mergedResults[i] = nil
        end
    end

    local mapValue = ctx.mapValue
    local mapDisplay = ctx.display
    local mapTexture = ctx.mapTexture

    local results = {} ---@type omichat.SearchResult[]
    for i = 1, #mergedResults do
        local internal = mergedResults[i]
        local raw = internal.raw
        local str = internal.compareString

        ---@type omichat.SearchResult
        local result = {
            exact = internal.exact,
            value = mapValue and mapValue(raw, str) or raw,
            display = internal.display or mapDisplay and mapDisplay(raw, str),
            texture = mapTexture and mapTexture(raw, str),
        }

        if result.exact then
            ctx.exact = result
        end

        results[#results + 1] = result
    end

    ---@type omichat.SearchResults
    return {
        exact = ctx.exact,
        results = results,
    }
end

---Filter function for streams.
---@param stream omichat.Stream | omichat.VanillaCommand
---@return boolean match
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

---Display function for icons.
---@param icon omichat.search.IconInfo
---@return string alias
---@private
function Search._getIconDisplay(icon)
    return icon.alias
end

---Returns the texture of an icon.
---@param icon omichat.search.PerkInfo
---@return Texture texture
---@private
function Search._getIconTexture(icon)
    return getTexture(icon.name)
end

---Display function for perks.
---@param perk Perk
---@return string display
---@private
function Search._getPerkDisplay(perk)
    return perk:getName() .. ' (' .. perk:getParent():getName() .. ')'
end

---Display function for streams.
---@param stream omichat.Stream | omichat.VanillaCommand
---@param command string
---@return string display
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

---Performs a string search.
---@param ctx omichat.search.InternalSearchContext Search context.
---@param primary string Primary string to search.
---@param value unknown? Object to use as the result value instead of `primary`.
---@param ... string Secondary strings to search.
---@return omichat.search.InternalSearchResult? result
---@private
function Search._internal(ctx, primary, value, ...)
    if value == nil then
        value = primary
    end

    if ctx.filter and not ctx.filter(value, ctx.args) then
        return
    end

    local search = ctx.search
    local mapDisplay = ctx.display
    local strings = { primary, ... }
    local compare = {}

    if not ctx.caseSensitive then
        search = search:lower()
    end

    local result ---@type omichat.search.InternalSearchResult?

    -- check for exact match
    if #search > 0 then
        for i = 1, #strings do
            local str = strings[i]
            local compareStr = ctx.caseSensitive and str or str:lower()
            local match = compareStr == search

            local display
            if not match and ctx.searchDisplay then
                display = mapDisplay and mapDisplay(value, str) or nil

                local displayCompare = display and (ctx.caseSensitive and display or display:lower())
                match = displayCompare == search
            end

            if match then
                if ctx.terminateOnExact then
                    ctx.isTerminated = true
                end

                result = {
                    raw = value,
                    compareString = str,
                    display = display,
                    exact = true,
                }

                ctx.exactInternal = result
                ctx.startsWith[#ctx.startsWith + 1] = result
                return result
            end

            compare[i] = compareStr
        end
    end

    -- check for max search limit
    if ctx.maxSearch and #ctx.startsWith + #ctx.contains >= ctx.maxSearch then
        ctx.isTerminated = true
        return
    end

    if #search == 0 then
        -- no search → include all
        result = {
            raw = value,
            compareString = primary,
            exact = false,
        }

        ctx.startsWith[#ctx.startsWith + 1] = result
        return result
    end

    for i = 1, #strings do
        local str = strings[i]
        local swSearch = ctx.searchForStartsWith or search
        local match = utils.startsWith(compare[i], swSearch)

        local display
        if not match and ctx.searchDisplay then
            display = mapDisplay and mapDisplay(value, str) or nil
            local displayCompare = display and (ctx.caseSensitive and display or display:lower())
            if displayCompare and utils.startsWith(displayCompare, swSearch) then
                match = true
            end
        end

        if match then
            result = {
                raw = value,
                compareString = str,
                display = display,
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

        local display
        if not match and ctx.searchDisplay then
            display = mapDisplay and mapDisplay(value, str) or nil
            local displayCompare = display and (ctx.caseSensitive and display or display:lower())
            if displayCompare and utils.contains(displayCompare, ctSearch) then
                match = true
            end
        end

        if match then
            result = {
                raw = value,
                compareString = str,
                display = display,
                exact = false,
            }

            ctx.contains[#ctx.contains + 1] = result
            return result
        end
    end
end

---Returns the ID of a perk.
---@param perk Perk
---@return string id
---@private
function Search._mapPerkToId(perk)
    return perk:getId()
end

---Returns the name of a player given an info table.
---@param player omichat.search.PlayerInfo
---@return string name
---@private
function Search._mapPlayerInfoToName(player)
    return player.name
end

---Returns the username of a player given an info table.
---@param player omichat.search.PlayerInfo
---@return string username
---@private
function Search._mapPlayerInfoToUsername(player)
    return player.username
end

---Search map function that returns the comparison value.
---@param _ unknown
---@param command string
---@return string command
---@private
function Search._mapToCompareString(_, command)
    return command
end

---Searches a player username for a string, if it should be included.
---@param player IsoPlayer | omichat.PlayerCacheData
---@param chatType string
---@param ctx omichat.search.InternalSearchContext
---@param ownUsername string
---@param includeSelf boolean?
---@param searchUsernames boolean?
---@return omichat.search.InternalSearchResult? result
---@private
function Search._playerChatName(player, chatType, ctx, ownUsername, includeSelf, searchUsernames)
    local username
    if player.getUsername then
        ---@cast player IsoPlayer
        username = player:getUsername()
    else
        username = player.username
    end

    if not includeSelf and username == ownUsername then
        return
    end

    local name = API.data.getPlayerNameInChat(player, chatType) or username

    ---@type omichat.search.PlayerInfo
    local info = {
        name = name,
        username = username,
    }

    return Search._internal(ctx, name, info, searchUsernames and username or nil)
end

---Searches a player username for a string, if it should be included.
---@param player IsoPlayer | omichat.PlayerCacheData
---@param ctx omichat.search.InternalSearchContext
---@param ownUsername string
---@param includeSelf boolean?
---@return omichat.search.InternalSearchResult? result
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


--#region Type Definitions

---@class omichat.SearchResult
---@field value string The string result of the search.
---@field exact boolean Whether the result is an exact match of the search text.
---@field display string? The display string to use for the search result.
---@field texture Texture? A texture to display alongside the search result.

---@class omichat.SearchResults
---@field results omichat.SearchResult[] The list of results.
---@field exact omichat.SearchResult? An exact match, if one was found.

---@class omichat.search.InternalSearchResult
---@field exact boolean Flag for whether the search result is an exact match.
---@field raw unknown The raw search result value.
---@field compareString string The comparison string that was matched on.
---@field display string? The display string to use for the search result.


---@class omichat.StreamSearchOptions
---@field excludeChatStreams boolean? Flag for whether to exclude chat streams from the search.
---@field excludeCommandStreams boolean? Flag for whether to exclude custom command streams from the search.
---@field includeUnmanagedChatStreams boolean? Flag for whether to include unmanaged stream tables in the search.
---@field includeVanillaCommandStreams boolean? Flag for whether to include vanilla command streams in the search.

---@class omichat.Args.StreamSearch : omichat.StreamSearchOptions, omichat.SearchContext


---@class omichat.SearchContext
---@field search string The string to search for.
---@field terminateOnExact boolean? If true, exact matches will terminate the search.
---@field maxResults integer? The maximum number of search results to return.
---@field maxSearch integer? The maximum number of elements to search before terminating.
---@field searchDisplay boolean? If true, the display string will be searched as well.
---@field filter omichat.SearchContext.Filter? Filter function for results.
---@field display omichat.SearchContext.MapString? Function to retrieve display strings for results.
---@field args string[]? Arguments for the `filter` function.
---@field isTerminated boolean? Flag for terminating the search.
---@field exact omichat.SearchResult? The last exact match for the search.

---@class omichat.search.InternalSearchContext : omichat.SearchContext
---@field searchForStartsWith string? The search to use for 'starts with' comparison. Defaults to the same string as `search`.
---@field searchForContains string? The search to use for 'contains' comparison. Defaults to the same string as `search`.
---@field startsWith omichat.search.InternalSearchResult[] Search results that start with the search text.
---@field contains omichat.search.InternalSearchResult[] Search results that contain the search text, but don't start with it.
---@field mapValue omichat.SearchContext.MapString? Callback to map search result values to strings.
---@field mapTexture omichat.SearchContext.MapTexture? Callback to map search result values to textures.
---@field caseSensitive boolean? Flag for whether the search should be case-sensitive. Defaults to `false`.
---@field exactInternal omichat.search.InternalSearchResult? The last exact match for the internal search.
---@field args string[] Arguments for the `filter` function.


---@class omichat.search.PerkInfo
---@field perk Perk The perk object.
---@field name string The name of the perk.
---@field id string The perk ID.

---@class omichat.search.IconInfo
---@field name string The texture name of the icon.
---@field alias string The chat alias of the icon.

---@class omichat.search.PlayerInfo
---@field name string The player's name in chat.
---@field username string The player's username.


---@class omichat.SuggestArgSpecTable
---@field type omichat.SuggestionType | string The type of the argument.
---@field prefix string? A prefix to apply to the suggestion result.
---@field suffix string? A suffix to apply to the suggestion result.
---@field options string[]? String options for the `option` suggestion type.
---@field searchDisplay boolean? If true, the display string will be used for determining suggestions.
---@field filter omichat.SuggestArgSpec.Filter? Filter function for results.
---@field display omichat.SuggestArgSpec.Display? Function to retrieve display strings for results.


---@alias omichat.SearchContext.MapString fun(value: unknown, comparisonString: string): string?

---@alias omichat.SearchContext.MapTexture fun(value: unknown, comparisonString: string): Texture?

---@alias omichat.SearchContext.Filter fun(value: unknown, args: string[]): boolean

---@alias omichat.SuggestArgSpec.Display fun(value: unknown, str: string): string?

---@alias omichat.SuggestArgSpec.Filter fun(result: unknown, args: string[]): boolean

---@alias omichat.SuggestSearchCallback fun(ctx: omichat.SearchContext | string, spec: omichat.SuggestArgSpec): omichat.SearchResults?


---@alias omichat.SuggestArgSpec omichat.SuggestArgSpecTable | omichat.SuggestionType | string

---@alias omichat.SuggestionType
---| 'online-username'
---| 'online-username-with-self'
---| 'language'
---| 'known-language'
---| 'icon'
---| 'perk'
---| 'option'
---| '?'

--#endregion
