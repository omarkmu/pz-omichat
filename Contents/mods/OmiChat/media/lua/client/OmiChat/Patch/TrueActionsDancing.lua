---Compatibility patch for True Actions Act 3 - Dancing.
---@namespace omichat
---@diagnostic disable: access-invisible

local API = require 'OmiChat/Client'
local utils = API.utils
local config = API.Configuration

local getText = getText
local pairs = pairs
local concat = table.concat
local trim = utils.trim


-- dances from TAD
local itemDanceByItemType = {}
local itemDances = {
    afoxe_samba_reggae = {
        item = 'TAD.BobTA_Afoxe_Samba_Raggae_card',
        emote = 'BobTA_Afoxe_Samba_Raggae',
        display = 'Afoxe Samba Reggae',
    },
    belly1 = {
        item = 'TAD.BobTA_Belly_Dancing_One_card',
        emote = 'BobTA_Belly_Dancing_One',
        display = 'Belly Dancing 1',
    },
    belly2 = {
        item = 'TAD.BobTA_Belly_Dancing_Two_card',
        emote = 'BobTA_Belly_Dancing_Two',
        display = 'Belly Dancing 2',
    },
    belly3 = {
        item = 'TAD.BobTA_Belly_Dancing_Three_card',
        emote = 'BobTA_Belly_Dancing_Three',
        display = 'Belly Dancing 3',
    },
    boogaloo = {
        item = 'TAD.BobTA_Boogaloo_card',
        emote = 'BobTA_Boogaloo',
    },
    breakdance1990 = {
        item = 'TAD.BobTA_Breakdance_1990_card',
        emote = 'BobTA_Breakdance_1990',
    },
    breakdance_freezes_combo = {
        item = 'TAD.BobTA_Breakdance_Freezes_Combo_card',
        emote = 'BobTA_Breakdance_Freezes_Combo',
    },
    charleston = {
        item = 'TAD.BobTA_Charleston_card',
        emote = 'BobTA_Charleston',
    },
    gandy = {
        item = 'TAD.BobTA_Gandy_card',
        emote = 'BobTA_Gandy',
    },
    house = {
        item = 'TAD.BobTA_House_Dancing_card',
        emote = 'BobTA_House_Dancing',
    },
    locking = {
        item = 'TAD.BobTA_Locking_card',
        emote = 'BobTA_Locking',
    },
    moonwalk2 = {
        item = 'TAD.BobTA_Moonwalk_Two_card',
        emote = 'BobTA_Moonwalk_Two',
        display = 'Moonwalk 2',
    },
    northern_soul_spin_and_floor_work = {
        item = 'TAD.BobTA_Northern_Soul_Spin_and_Floor_Work_card',
        emote = 'BobTA_Northern_Soul_Spin_and_Floor_Work',
    },
    northern_soul_spin_dip_and_splits = {
        item = 'TAD.BobTA_Northern_Soul_Spin_Dip_and_Splits_card',
        emote = 'BobTA_Northern_Soul_Spin_Dip_and_Splits',
    },
    rick = {
        item = 'TAD.BobTA_Rick_Dancing_card',
        emote = 'BobTA_Rick_Dancing',
    },
    robot1 = {
        item = 'TAD.BobTA_Robot_One_card',
        emote = 'BobTA_Robot_One',
        display = 'Robot 1',
    },
    robot2 = {
        item = 'TAD.BobTA_Robot_Two_card',
        emote = 'BobTA_Robot_Two',
        display = 'Robot 2',
    },
    salsa2 = {
        item = 'TAD.BobTA_Salsa_Two_card',
        emote = 'BobTA_Salsa_Two',
        display = 'Salsa 2',
    },
    samba_olodum = {
        item = 'TAD.BobTA_Samba_Olodum_card',
        emote = 'BobTA_Samba_Olodum',
    },
    samba_pagode = {
        item = 'TAD.BobTA_Samba_Pagode_card',
        emote = 'BobTA_Samba_Pagode',
    },
    slide_step = {
        item = 'TAD.BobTA_Slide_Step_card',
        emote = 'BobTA_Slide_Step',
    },
    snake = {
        item = 'TAD.BobTA_Snake_card',
        emote = 'BobTA_Snake',
    },
    thriller1 = {
        item = 'TAD.BobTA_Thriller_One_card',
        emote = 'BobTA_Thriller_One',
        display = 'Thriller 1',
    },
    thriller2 = {
        item = 'TAD.BobTA_Thriller_Two_card',
        emote = 'BobTA_Thriller_Two',
        display = 'Thriller 2',
    },
    thriller3 = {
        item = 'TAD.BobTA_Thriller_Three_card',
        emote = 'BobTA_Thriller_Three',
        display = 'Thriller 3',
    },
    thriller4 = {
        item = 'TAD.BobTA_Thriller_Four_card',
        emote = 'BobTA_Thriller_Four',
        display = 'Thriller 4',
    },
    tut1 = {
        item = 'TAD.BobTA_Tut_One_card',
        emote = 'BobTA_Tut_One',
        display = 'Tut 1',
    },
    tut2 = {
        item = 'TAD.BobTA_Tut_Two_card',
        emote = 'BobTA_Tut_Two',
        display = 'Tut 2',
    },
    wave1 = {
        item = 'TAD.BobTA_Wave_One_card',
        emote = 'BobTA_Wave_One',
        display = 'Wave 1',
    },
    wave2 = {
        item = 'TAD.BobTA_Wave_Two_card',
        emote = 'BobTA_Wave_Two',
        display = 'Wave 2',
    },
}
local recipeDances = {
    african_noodle = {
        recipe = 'BobTA African Noodle',
        emote = 'BobTA_African_Noodle',
    },
    african_rainbow = {
        recipe = 'BobTA African Rainbow',
        emote = 'BobTA_African_Rainbow',
    },
    arms_hip_hop = {
        recipe = 'BobTA Arms Hip Hop',
        emote = 'BobTA_Arms_Hip_Hop',
    },
    arm_push = {
        recipe = 'BobTA Arm Push',
        emote = 'BobTA_Arm_Push',
    },
    arm_wave1 = {
        recipe = 'BobTA Arm Wave One',
        emote = 'BobTA_Arm_Wave_One',
    },
    arm_wave2 = {
        recipe = 'BobTA Arm Wave Two',
        emote = 'BobTA_Arm_Wave_Two',
    },
    around_the_world = {
        recipe = 'BobTA Around The World',
        emote = 'BobTA_Around_The_World',
    },
    bboy_hip_hop1 = {
        recipe = 'BobTA Bboy Hip Hop One',
        emote = 'BobTA_Bboy_Hip_Hop_One',
    },
    bboy_hip_hop2 = {
        recipe = 'BobTA Bboy Hip Hop Two',
        emote = 'BobTA_Bboy_Hip_Hop_Two',
    },
    bboy_hip_hop3 = {
        recipe = 'BobTA Bboy Hip Hop Three',
        emote = 'BobTA_Bboy_Hip_Hop_Three',
    },
    body_wave = {
        recipe = 'BobTA Body Wave',
        emote = 'BobTA_Body_Wave',
    },
    booty_step = {
        recipe = 'BobTA Booty Step',
        emote = 'BobTA_Booty_Step',
    },
    breakdance_brooklyn_uprock = {
        recipe = 'BobTA Breakdance Brooklyn Uprock',
        emote = 'BobTA_Breakdance_Brooklyn_Uprock',
    },
    cabbage_patch = {
        recipe = 'BobTA Cabbage Patch',
        emote = 'BobTA_Cabbage_Patch',
    },
    can_can = {
        recipe = 'BobTA Can Can',
        emote = 'BobTA_Can_Can',
    },
    chicken = {
        recipe = 'BobTA Chicken',
        emote = 'BobTA_Chicken',
    },
    crazy_legs = {
        recipe = 'BobTA Crazy Legs',
        emote = 'BobTA_Crazy_Legs',
    },
    defile_de_samba_parade = {
        recipe = 'BobTA Defile De Samba Parade',
        emote = 'BobTA_Defile_De_Samba_Parade',
    },
    hokey_pokey = {
        recipe = 'BobTA Hokey Pokey',
        emote = 'BobTA_Hokey_Pokey',
    },
    kick_step = {
        recipe = 'BobTA Kick Step',
        emote = 'BobTA_Kick_Step',
    },
    macarena = {
        recipe = 'BobTA Macarena',
        emote = 'BobTA_Macarena',
    },
    maraschino = {
        recipe = 'BobTA Maraschino',
        emote = 'BobTA_Maraschino',
    },
    moonwalk1 = {
        recipe = 'BobTA MoonWalk One',
        emote = 'BobTA_MoonWalk_One',
    },
    northern_soul_spin = {
        recipe = 'BobTA Northern Soul Spin',
        emote = 'BobTA_Northern_Soul_Spin',
    },
    northern_soul_spin_on_floor = {
        recipe = 'BobTA Northern Soul Spin On Floor',
        emote = 'BobTA_Northern_Soul_Spin_On_Floor',
    },
    raise_the_roof = {
        recipe = 'BobTA Raise The Roof',
        emote = 'BobTA_Raise_The_Roof',
    },
    really_twirl = {
        recipe = 'BobTA Really Twirl',
        emote = 'BobTA_Really_Twirl',
    },
    rip_pops = {
        recipe = 'BobTA Rib Pops',
        emote = 'BobTA_Rib_Pops',
    },
    rockette_kick = {
        recipe = 'BobTA Rockette Kick',
        emote = 'BobTA_Rockette_Kick',
    },
    rumba = {
        recipe = 'BobTA Rumba Dancing',
        emote = 'BobTA_Rumba_Dancing',
    },
    running_man1 = {
        recipe = 'BobTA Running Man One',
        emote = 'BobTA_Running_Man_One',
    },
    running_man2 = {
        recipe = 'BobTA Running Man Two',
        emote = 'BobTA_Running_Man_Two',
    },
    running_man3 = {
        recipe = 'BobTA Running Man Three',
        emote = 'BobTA_Running_Man_Three',
    },
    salsa = {
        recipe = 'BobTA Salsa',
        emote = 'BobTA_Salsa',
    },
    salsa_double_twirl = {
        recipe = 'BobTA Salsa Double Twirl',
        emote = 'BobTA_Salsa_Double_Twirl',
    },
    salsa_double_twirl_and_clap = {
        recipe = 'BobTA Salsa Double Twirl and Clap',
        emote = 'BobTA_Salsa_Double_Twirl_and_Clap',
    },
    salsa_side_to_side = {
        recipe = 'BobTA Salsa Side to Side',
        emote = 'BobTA_Salsa_Side_to_Side',
    },
    shimmy = {
        recipe = 'BobTA Shimmy',
        emote = 'BobTA_Shimmy',
    },
    shim_sham = {
        recipe = 'BobTA Shim Sham',
        emote = 'BobTA_Shim_Sham',
    },
    shuffling = {
        recipe = 'BobTA Shuffling',
        emote = 'BobTA_Shuffling',
    },
    side_to_side = {
        recipe = 'BobTA Side to Side',
        emote = 'BobTA_Side_to_Side',
    },
    twist1 = {
        recipe = 'BobTA Twist One',
        emote = 'BobTA_Twist_One',
    },
    twist2 = {
        recipe = 'BobTA Twist Two',
        emote = 'BobTA_Twist_Two',
    },
    uprock_indian_step = {
        recipe = 'BobTA Uprock Indian Step',
        emote = 'BobTA_Uprock_Indian_Step',
    },
    ymca = {
        recipe = 'BobTA YMCA',
        emote = 'BobTA_YMCA',
    },
}

---Checks whether the compatibility patch is enabled.
---@return boolean
local function isPatchEnabled()
    return config:compatTADEnabled()
end

---Display function for dances.
---@param dance table
---@return string
local function danceDisplay(dance)
    return dance.display
end

---Returns a list of available dances that are provided by inventory items.
---@param player IsoPlayer The player to check.
---@param search string? If provided, the index of the dance with this emote in the result will be returned.
---@return table[] #List of dances.
---@return table<string, true> #Set of dances.
---@return integer? #Index of `search` in the list, if `search` was provided and found.
local function getAvailableItemDances(player, search)
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

---Returns a list of available dances.
---@param player IsoPlayer The player to check.
---@param search string? If provided, the index of the dance with this emote in the result will be returned.
---@return table[] #List of dances.
---@return integer? #Index of `search` in the list, if `search` was provided and found.
local function getAvailableDances(player, search)
    local danceList, _, searchIdx = getAvailableItemDances(player, search)

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
---@return string
local function getAvailableDanceHelpText(player)
    local dances = getAvailableDances(player)
    local parts = {}

    table.sort(dances, function(a, b)
        return a.name < b.name
    end)

    if #dances > 0 then
        parts[#parts + 1] = getText('UI_OmiChat_Info_AvailableDances')
    end

    for i = 1, #dances do
        parts[#parts + 1] = ' <LINE> * '
        parts[#parts + 1] = dances[i].name:gsub('_', ' ')
    end

    return concat(parts)
end

---Map function for dances. Returns the dance name.
---@param dance table
---@return string
local function mapDanceValue(dance)
    return dance.name
end

---Gets a random dance the player knows, or `nil` if the player doesn't know any.
---@return table?
local function getRandomKnownDance(player)
    local dances, currentDanceIdx = getAvailableDances(player, player:getVariableString('emote'))

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

---Returns a dance emote given command input, or information
---used to display an error message.
---@param name string
---@param player IsoPlayer
---@return table
local function processDanceCommand(name, player)
    name = trim(name or '')

    if name == 'list' then
        return { list = true }
    end

    -- get a random known dance
    if #name == 0 then
        local dance = getRandomKnownDance(player)
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
            name = getText('IGUI_Emote_' .. dance.emote):gsub('\n', ' '),
        }
    end

    -- check special card dances
    dance = itemDances[name]
    if dance then
        local _, dances = getAvailableItemDances(player)
        if dances[dance.name] then
            return { emote = dance.emote }
        end

        return {
            missingItem = true,
            name = getText('IGUI_Emote_' .. dance.emote):gsub('\n', ' '),
        }
    end

    return { unknown = true }
end

---Searches known dances for the input.
---@param ctxOrSearch SearchContext | string
---@return SearchResults?
local function searchKnownDances(ctxOrSearch)
    if not config:compatTADEnabled() then
        return
    end

    local player = API.player.get()
    if not player then
        return
    end


    local ctx = API.search._buildContext(ctxOrSearch)
    ctx.display = ctx.display or danceDisplay
    ctx.mapValue = mapDanceValue

    local dances = getAvailableDances(player)
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

---Plays a dance emote.
---@param emote string The dance emote to play.
---@param player IsoPlayer The player to play the emote on.
local function playDanceEmote(emote, player)
    player:setPrimaryHandItem(nil)
    player:setSecondaryHandItem(nil)
    player:playEmote(emote)
end

local danceStream = API.CommandStream:new {
    name = 'dance',
    helpTextID = 'UI_OmiChat_HelpText_Dance',
    suggestSpec = { 'known-dance' },
    isEnabled = isPatchEnabled,
    onUse = function(args)
        local player = API.player.get()
        if not player then
            return
        end

        local feedback
        local info = processDanceCommand(args.text, player)
        if info.emote then
            playDanceEmote(info.emote, player)
        elseif info.unknownRecipe then
            feedback = getText('UI_OmiChat_Info_DanceUnknownRecipe', info.name)
        elseif info.missingItem then
            feedback = getText('UI_OmiChat_Info_DanceMissingItem', info.name)
        elseif info.list then
            feedback = getAvailableDanceHelpText(player)
        else
            feedback = getText('UI_OmiChat_Info_DanceUnknown')
        end

        if feedback then
            API.chat.addInfoMessage(feedback)
        end
    end,
}

---Applies the TAD patch.
local function applyPatch()
    local emotes = {}
    for k, v in pairs(itemDances) do
        v.name = k
        v.display = v.display or v.emote:gsub('^BobTA_', ''):gsub('_', ' ')
        itemDanceByItemType[v.item] = v

        emotes['dance_' .. k] = API.ChatEmote:new {
            emote = v.emote,
            isEnabled = function()
                if not isPatchEnabled() then
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
        v.name = k
        v.display = v.display or v.recipe:gsub('^BobTA%s*', '')

        emotes['dance_' .. k] = API.ChatEmote:new {
            emote = v.emote,
            isEnabled = function()
                if not isPatchEnabled() then
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
        isEnabled = isPatchEnabled,
        onPlay = function(player)
            local dance = getRandomKnownDance(player)
            if dance then
                playDanceEmote(dance.emote, player)
            end
        end,
    }

    API.extension.addEmotes(emotes)
    API.extension.addCommand(danceStream)
    API.extension.addSuggesterType('known-dance', searchKnownDances)
end

Events.OnGameStart.Add(applyPatch)
