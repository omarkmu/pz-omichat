---Compatibility patch for True Actions Act 3 - Dancing.
---@namespace omichat
---@diagnostic disable: access-invisible

local API = require 'OmiChat/Client'
local utils = API.utils
local config = API.Configuration
local danceData = require 'OmiChat/Definition/TADDances'

local itemDances = danceData.itemDances
local recipeDances = danceData.recipeDances
local itemDanceByItemType = danceData.itemDanceByItemType

local getTextVanilla = getText
local getText = utils.getText
local pairs = pairs
local concat = table.concat
local sort = table.sort
local trim = utils.trim

---@class patch.TAD
---@field private _danceStream CommandStream The command stream for `/dance`.
local Patch = {}


---Applies the TAD patch.
function Patch.apply()
    API.extension.addEmotes(Patch.getEmotes())
    API.extension.addCommand(Patch._danceStream)
    API.extension.addSuggesterType('known-dance', Patch.searchKnownDances)
end

---Returns a list of available dances.
---@param player IsoPlayer The player to check.
---@param search string? If provided, the index of the dance with this emote in the result will be returned.
---@return patch.TAD.Dance[] danceList List of dances.
---@return integer? searchIdx Index of `search` in the list, if `search` was provided and found.
function Patch.getAvailableDances(player, search)
    local danceList, _, searchIdx = Patch.getAvailableItemDances(player, search)

    for _, dance in pairs(recipeDances) do
        if player:isRecipeKnown(dance.recipe) then
            danceList[#danceList + 1] = dance

            if search == dance.emote then
                searchIdx = #danceList
            end
        end
    end

    return danceList, searchIdx
end

---Retrieves help text that displays a list of currently available dances.
---@param player IsoPlayer
---@return string helpText
function Patch.getAvailableDanceHelpText(player)
    local dances = Patch.getAvailableDances(player)
    local parts = {}

    sort(dances, function(a, b)
        return a.name < b.name
    end)

    if #dances > 0 then
        parts[#parts + 1] = getText('info-available-dances')
    end

    for i = 1, #dances do
        parts[#parts + 1] = ' <LINE> * '
        parts[#parts + 1] = dances[i].name:gsub('_', ' ')
    end

    return concat(parts)
end

---Returns a list of available dances that are provided by inventory items.
---@param player IsoPlayer The player to check.
---@param search string? If provided, the index of the dance with this emote in the result will be returned.
---@return patch.TAD.Dance[] danceList List of dances.
---@return table<string, true> danceSet Set of dance names.
---@return integer? searchIdx Index of `search` in the list, if `search` was provided and found.
function Patch.getAvailableItemDances(player, search)
    local danceList = {}
    local danceSet = {}
    local searchIdx
    local items = player:getInventory():getItems()

    for i = 0, items:size() - 1 do
        local itemType = items:get(i):getFullType()
        local dance = itemDanceByItemType[itemType]
        if dance and not danceSet[dance.name] then
            danceList[#danceList + 1] = dance
            danceSet[dance.name] = true

            if search == dance.emote then
                searchIdx = #danceList
            end
        end
    end

    return danceList, danceSet, searchIdx
end

---Creates a table of emotes for each dance.
---@return table<string, ChatEmote> emotes
function Patch.getEmotes()
    local emotes = {}
    for k, v in pairs(itemDances) do
        emotes['dance_' .. k] = API.ChatEmote:new {
            emote = v.emote,
            isEnabled = function()
                if not Patch.isEnabled() then
                    return false
                end

                local player = API.player.get()
                if not player then
                    return false
                end

                return player:getInventory():getItemFromType(v.item) ~= nil
            end,
        }
    end

    for k, v in pairs(recipeDances) do
        emotes['dance_' .. k] = API.ChatEmote:new {
            emote = v.emote,
            isEnabled = function()
                if not Patch.isEnabled() then
                    return false
                end

                local player = API.player.get()
                if not player then
                    return false
                end

                return player:isRecipeKnown(v.recipe)
            end,
        }
    end

    emotes.dance = API.ChatEmote:new {
        isEnabled = Patch.isEnabled,
        onPlay = function(player)
            local dance = Patch.getRandomKnownDance(player)
            if dance then
                Patch.playEmote(dance.emote, player)
            end
        end,
    }

    return emotes
end

---Gets a random dance the player knows, or `nil` if the player doesn't know any.
---@return table?
function Patch.getRandomKnownDance(player)
    local dances, currentDanceIdx = Patch.getAvailableDances(player, player:getVariableString('emote'))

    local idx ---@type integer
    if currentDanceIdx then
        -- avoid doing the same dance
        idx = utils.randInt(1, #dances - 1)
        if idx == currentDanceIdx then
            idx = #dances
        end
    else
        idx = utils.randInt(1, #dances)
    end

    return dances[idx]
end

---Checks whether the compatibility patch is enabled.
---@return boolean enabled
function Patch.isEnabled()
    return config:compatTADEnabled()
end

---Plays a dance emote.
---@param emote string The dance emote to play.
---@param player IsoPlayer The player to play the emote on.
function Patch.playEmote(emote, player)
    player:setPrimaryHandItem(nil)
    player:setSecondaryHandItem(nil)
    player:playEmote(emote)
end

---Returns a dance emote given command input, or information
---used to display an error message.
---@param name string
---@param player IsoPlayer
---@return table
function Patch.processDanceCommand(name, player)
    name = trim(name or '')

    if name == 'list' then
        return { list = true }
    end

    -- get a random known dance
    if #name == 0 then
        local dance = Patch.getRandomKnownDance(player)
        if dance then
            return { emote = dance.emote }
        end

        return { noDances = true }
    end

    name = name:gsub(' ', '_'):lower()

    -- check known recipe dances

    local dance = recipeDances[name]
    if dance then
        if player:isRecipeKnown(dance.recipe) then
            return { emote = dance.emote }
        end

        return {
            unknownRecipe = true,
            name = getTextVanilla('IGUI_Emote_' .. dance.emote):gsub('\n', ' '),
        }
    end

    -- check special card dances
    local cardDance = itemDances[name]
    if cardDance then
        local _, dances = Patch.getAvailableItemDances(player)
        if dances[cardDance.name] then
            return { emote = cardDance.emote }
        end

        return {
            missingItem = true,
            name = getTextVanilla('IGUI_Emote_' .. cardDance.emote):gsub('\n', ' '),
        }
    end

    return { unknown = true }
end

---Searches known dances for the input.
---@param ctxOrSearch SearchContext | string
---@return SearchResults?
function Patch.searchKnownDances(ctxOrSearch)
    if not config:compatTADEnabled() then
        return
    end

    local player = API.player.get()
    if not player then
        return
    end


    local ctx = API.search._buildContext(ctxOrSearch)
    ctx.display = ctx.display or Patch._danceDisplay
    ctx.mapValue = Patch._mapDanceValue

    local dances = Patch.getAvailableDances(player)
    for i = 1, #dances do
        local dance = dances[i]
        local display = dance.display:gsub(' ', '_')

        API.search._internal(ctx, dance.name, dance, display)
        if ctx.isTerminated then
            break
        end
    end

    return API.search._collectResults(ctx)
end


---Display function for dances.
---@param dance table
---@return string
---@private
function Patch._danceDisplay(dance)
    return dance.display
end

---Map function for dances. Returns the dance name.
---@param dance patch.TAD.Dance
---@return string
---@private
function Patch._mapDanceValue(dance)
    return dance.name
end


Patch._danceStream = API.CommandStream:new {
    name = 'dance',
    helpTextID = 'help-text-dance',
    suggestSpec = { 'known-dance' },
    isEnabled = Patch.isEnabled,
    onUse = function(args)
        local player = API.player.get()
        if not player then
            return
        end

        local feedback
        local info = Patch.processDanceCommand(args.text, player)
        if info.emote then
            Patch.playEmote(info.emote, player)
        elseif info.unknownRecipe then
            feedback = getText('info-dance-unknown-recipe', { dance = info.name })
        elseif info.missingItem then
            feedback = getText('info-dance-missing-item', { dance = info.name })
        elseif info.list then
            feedback = Patch.getAvailableDanceHelpText(player)
        else
            feedback = getText('info-dance-unknown')
        end

        if feedback then
            API.chat.addInfoMessage(feedback)
        end
    end,
}

Events.OnGameStart.Add(Patch.apply)
return Patch
