---Information about dances added by `True Actions Act 3 - Dancing`.
---@namespace omichat

local Data = {}

---Associates dance name to dance information, for dances which require an item.
---@type table<string, patch.TAD.ItemDance>
Data.itemDances = {}

---Associates dance name to dance information, for learnable dances.
---@type table<string, patch.TAD.RecipeDance>
Data.recipeDances = {}

---Associates item types to dances for those items.
---@type table<string, patch.TAD.ItemDance>
Data.itemDanceByItemType = {}

do
    --#region Definitions
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
    --#endregion

    --#region Processing

    for k, v in pairs(itemDances) do
        ---@cast v patch.TAD.ItemDance
        v.name = k
        v.display = v.display or v.emote:gsub('^BobTA_', ''):gsub('_', ' ')
        Data.itemDances[k] = v
        Data.itemDanceByItemType[v.item] = v
    end

    for k, v in pairs(recipeDances) do
        ---@cast v patch.TAD.RecipeDance
        v.name = k
        v.display = v.display or v.recipe:gsub('^BobTA%s*', '')
        Data.recipeDances[k] = v
    end

    --#endregion
end

return Data

--#region Type Definitions

---@class patch.TAD.BaseDance
---@field name string The identifier for the dance.
---@field emote string The emote to play for the dance.
---@field display string A display string to use for the dance.

---@class patch.TAD.ItemDance : patch.TAD.BaseDance
---@field item string The item type of the item required for the dance.

---@class patch.TAD.RecipeDance : patch.TAD.BaseDance
---@field recipe string The name of the recipe required for the dance.


---@alias patch.TAD.Dance
---| patch.TAD.ItemDance
---| patch.TAD.RecipeDance

--#endregion
