---Client API functionality related to searching.

local vanillaCommands = require 'OmiChat/Definition/VanillaCommandList'

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local utils = OmiChat.utils
local StreamInfo = OmiChat.StreamInfo

---@class omichat.search.InternalSearchContext : omichat.SearchContext
---@field search string
---@field searchForStartsWith string?
---@field searchForContains string?
---@field startsWith omichat.search.InternalSearchResult[]
---@field contains omichat.search.InternalSearchResult[]
---@field mapValue (fun(value: unknown, str: string): unknown)?
---@field caseInsensitive boolean?
---@field args table

---@class omichat.search.InternalSearchResult : omichat.SearchResult
---@field value unknown


---@type Perk[]
local perkList = {}; do
    local perkArrayList = PerkFactory.PerkList
    for i = 0, perkArrayList:size() - 1 do
        local perk = perkArrayList:get(i) ---@cast perk Perk
        if perk:getParent() ~= Perks.None then
            perkList[#perkList + 1] = perk
        end
    end

    table.sort(perkList, function(a, b) return not string.sort(a:getName(), b:getName()) end)
end


---Builds a list of streams to search.
---@param options omichat.StreamSearchOptions
---@return (omichat.StreamInfo | omichat.VanillaCommand)
local function buildStreamList(options)
    local list = {}
    if not options.excludeChatStreams then
        for i = 1, #ISChat.allChatStreams do
            list[#list + 1] = StreamInfo:new(ISChat.allChatStreams[i])
        end
    end

    if not options.excludeCommandStreams then
        for i = 1, #OmiChat._commandStreams do
            list[#list + 1] = StreamInfo:new(OmiChat._commandStreams[i])
        end
    end

    if options.includeVanillaCommandStreams then
        for i = 1, #vanillaCommands do
            list[#list + 1] = vanillaCommands[i]
        end
    end

    return list
end

---Filter function for streams.
---@param stream omichat.StreamInfo | omichat.VanillaCommand
---@return boolean
local function filterStream(stream)
    if utils.isinstance(stream, StreamInfo) then
        ---@cast stream omichat.StreamInfo
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
local function getPerkDisplay(perk)
    return perk:getName() .. ' (' .. perk:getParent():getName() .. ')'
end

---Display function for streams.
---@param stream omichat.StreamInfo | omichat.VanillaCommand
---@param command string
---@return string
local function getStreamDisplay(stream, command)
    if not utils.isinstance(stream, StreamInfo) then
        return command
    end

    ---@cast stream omichat.StreamInfo
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
local function mapToCommand(_, command)
    return command
end

---Returns the ID of a perk.
---@param perk Perk
---@return string
local function mapPerkToId(perk)
    return perk:getId()
end


---Creates internal context given search context.
---@param ctx omichat.SearchContext | string
---@return omichat.search.InternalSearchContext
---@private
function OmiChat.buildInternalSearchContext(ctx)
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
        collectResults = true,
    }
end

---Internal string search.
---@param ctx omichat.search.InternalSearchContext Search context.
---@param primary string Primary string to search.
---@param value unknown? Object to use as the result value instead of `primary`.
---@param ... string Secondary strings to search.
---@return omichat.search.InternalSearchResult?
---@private
function OmiChat.searchInternal(ctx, primary, value, ...)
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

---Collects online usernames based on a search string.
---If there's an exact match, no results are returned.
---@param ctxOrSearch omichat.SearchContext | string Context for the search.
---@param includeSelf boolean? If true, player 1's username will be included in the search.
---@return omichat.SearchResults
function OmiChat.searchOnlineUsernames(ctxOrSearch, includeSelf)
    local ctx = OmiChat.buildInternalSearchContext(ctxOrSearch)
    local onlinePlayers = getOnlinePlayers()
    local player = getSpecificPlayer(0)
    local ownUsername = player and player:getUsername()

    local exact
    for i = 0, onlinePlayers:size() - 1 do
        local onlinePlayer = onlinePlayers:get(i)
        local user = onlinePlayer and onlinePlayer:getUsername()
        if user and (includeSelf or user ~= ownUsername) then
            local result = OmiChat.searchInternal(ctx, user)
            if result and result.exact then
                exact = result
                if ctx.terminateOnExact then
                    break
                end
            end
        end
    end

    return {
        exact = exact,
        results = utils.extend(ctx.startsWith, ctx.contains),
    }
end

---Collects perk IDs based on a search string.
---@param ctxOrSearch omichat.SearchContext | string
---@return omichat.SearchResults
function OmiChat.searchPerks(ctxOrSearch)
    local ctx = OmiChat.buildInternalSearchContext(ctxOrSearch)
    ctx.display = ctx.display or getPerkDisplay
    ctx.mapValue = mapPerkToId

    local exact
    for i = 1, #perkList do
        local perk = perkList[i]
        local name = perk:getName():lower()
        local id = perk:getId():lower()
        local result = OmiChat.searchInternal(ctx, id, perk, name)
        if result and result.exact and ctx.terminateOnExact then
            exact = result
            break
        end
    end

    return {
        exact = exact,
        results = utils.extend(ctx.startsWith, ctx.contains),
    }
end

---Collects commands based on a search string.
---@param ctxOrSearch omichat.SearchContext | string
---@param options omichat.StreamSearchOptions
---@return omichat.SearchResults
function OmiChat.searchStreams(ctxOrSearch, options)
    local ctx = OmiChat.buildInternalSearchContext(ctxOrSearch)

    ctx.searchForStartsWith = '/' .. ctx.search
    ctx.display = ctx.display or mapToCommand
    ctx.filter = ctx.filter or filterStream

    local exact
    local streamList = buildStreamList(options)
    for i = 1, #streamList do
        local result
        local stream = streamList[i]
        if utils.isinstance(stream, StreamInfo) then
            ---@cast stream omichat.StreamInfo
            ctx.caseInsensitive = stream:isCaseInsensitive()
            result = OmiChat.searchInternal(ctx, stream:getCommand(), stream, stream:getShortCommand())

            if not result then
                for alias in stream:aliases() do
                    result = OmiChat.searchInternal(ctx, alias, stream)
                    if result then
                        break
                    end
                end
            end
        else
            ---@cast stream omichat.VanillaCommand
            ctx.caseInsensitive = true
            result = OmiChat.searchInternal(ctx, '/' .. stream.name .. ' ', stream)
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
    local streamResults = utils.extend(ctx.startsWith, ctx.contains)
    for i = 1, #streamResults do
        local result = streamResults[i]
        local stream = result.value
        local command = result.display

        if command and (result == exact or not seen[command]) then
            result.value = command
            ---@diagnostic disable-next-line: param-type-mismatch
            result.display = getStreamDisplay(stream, command)

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
---If there's an exact match, no results are returned.
---@param ctxOrSearch omichat.SearchContext | string Context for the search.
---@param list string[] The list of strings to search.
---@return omichat.SearchResults
function OmiChat.searchStrings(ctxOrSearch, list)
    local ctx = OmiChat.buildInternalSearchContext(ctxOrSearch)

    local exact
    for i = 1, #list do
        local result = OmiChat.searchInternal(ctx, list[i])
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
        results = utils.extend(ctx.startsWith, ctx.contains),
    }
end
