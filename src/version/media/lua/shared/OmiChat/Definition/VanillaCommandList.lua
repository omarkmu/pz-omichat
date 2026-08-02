---Vanilla command list.
---Used for the rewritten `/help` command.
---This excludes disabled commands and commands without help text.
---@namespace omichat

---@type VanillaCommand[]
local VanillaCommandList = {
    {
        name = 'addalltowhitelist',
        helpText = 'UI_ServerOptionDesc_AddAllWhitelist',
        capability = Capability.ManipulateWhitelist,
    },
    {
        name = 'additem',
        helpText = 'UI_ServerOptionDesc_AddItem',
        capability = Capability.AddItem,
        suggestSpec = { 'online-username-with-self', 'item' },
    },
    {
        name = 'addkey',
        helpText = 'UI_ServerOptionDesc_AddKey',
        capability = Capability.AddItem,
    },
    {
        name = 'adduser',
        helpText = 'UI_ServerOptionDesc_AddUser',
        capability = Capability.ModifyNetworkUsers,
    },
    {
        name = 'addusertosafehouse',
        helpText = 'UI_ServerOptionDesc_AddToSafehouse',
        capability = Capability.CanSetupSafehouses,
        suggestSpec = { 'online-username' },
    },
    {
        name = 'addusertowhitelist',
        helpText = 'UI_ServerOptionDesc_AddWhitelist',
        capability = Capability.ManipulateWhitelist,
        suggestSpec = { 'online-username' },
    },
    {
        name = 'addvehicle',
        helpText = 'UI_ServerOptionDesc_AddVehicle',
        capability = Capability.ManipulateVehicle,
        suggestSpec = { 'vehicle' },
    },
    {
        name = 'addxp',
        helpText = 'UI_ServerOptionDesc_AddXp',
        capability = Capability.AddXP,
        suggestSpec = {
            'online-username-with-self',
            { type = 'perk', suffix = '=' },
        },
    },
    {
        name = 'alarm',
        helpText = 'UI_ServerOptionDesc_Alarm',
        capability = Capability.MakeEventsAlarmGunshot,
    },
    {
        name = 'banid',
        helpText = 'UI_ServerOptionDesc_BanSteamId',
        capability = Capability.BanUnbanUser,
    },
    {
        name = 'banip',
        helpText = 'UI_ServerOptionDesc_BanIp',
        capability = Capability.BanUnbanUser,
    },
    {
        name = 'banuser',
        helpText = 'UI_ServerOptionDesc_BanUser',
        capability = Capability.BanUnbanUser,
    },
    {
        name = 'changeoption',
        helpText = 'UI_ServerOptionDesc_ChangeOptions',
        capability = Capability.ChangeAndReloadServerOptions,
    },
    {
        name = 'checkModsNeedUpdate',
        helpText = 'UI_ServerOptionDesc_CheckModsNeedUpdate',
        capability = Capability.ManipulateMods,
    },
    {
        name = 'chopper',
        helpText = 'UI_ServerOptionDesc_Chopper',
        capability = Capability.MakeEventsAlarmGunshot,
    },
    {
        name = 'createhorde',
        helpText = 'UI_ServerOptionDesc_CreateHorde',
        capability = Capability.CreateHorde,
        suggestSpec = { '?', 'online-username-with-self' },
    },
    {
        name = 'createhorde2',
        -- helpText = 'UI_ServerOptionDesc_CreateHorde2', -- string doesn't exist
        capability = Capability.CreateHorde,
    },
    {
        name = 'debugplayer',
        capability = Capability.ConnectWithDebug,
        suggestSpec = { 'online-username-with-self' },
    },
    {
        name = 'godmod',
        helpText = 'UI_ServerOptionDesc_GodMod',
        capability = Capability.ToggleGodModHimself,
    },
    {
        name = 'godmodplayer',
        helpText = 'UI_ServerOptionDesc_GodModPlayer',
        capability = Capability.ToggleGodModEveryone,
        suggestSpec = { 'online-username-with-self' },
    },
    {
        name = 'grantadmin',
        capability = Capability.ChangeAccessLevel,
    },
    {
        name = 'gunshot',
        helpText = 'UI_ServerOptionDesc_Gunshot',
        capability = Capability.MakeEventsAlarmGunshot,
    },
    {
        name = 'help',
        helpText = 'UI_ServerOptionDesc_Help',
        capability = Capability.LoginOnServer,
    },
    {
        name = 'invisible',
        helpText = 'UI_ServerOptionDesc_Invisible',
        capability = Capability.ToggleInvisibleHimself,
    },
    {
        name = 'invisibleplayer',
        helpText = 'UI_ServerOptionDesc_Invisible',
        capability = Capability.ToggleInvisibleEveryone,
        suggestSpec = { 'online-username-with-self' },
    },
    {
        name = 'kick',
        helpText = 'UI_ServerOptionDesc_Kick',
        capability = Capability.KickUser,
        suggestSpec = { 'online-username' },
    },
    {
        name = 'kickfromsafehouse',
        helpText = 'UI_ServerOptionDesc_Kick',
        capability = Capability.CanSetupSafehouses,
        suggestSpec = { 'online-username' },
    },
    {
        name = 'lightning',
        helpText = 'UI_ServerOptionDesc_Lightning',
        capability = Capability.MakeEventsAlarmGunshot,
        suggestSpec = { 'online-username-with-self' },
    },
    {
        name = 'list',
        -- helpText = 'UI_ServerOptionDesc_List', -- string doesn't exist
        capability = Capability.LoginOnServer,
        suggestSpec = {
            {
                type = 'option',
                options = { 'animals' },
            },
        },
    },
    {
        name = 'log',
        helpText = 'UI_ServerOptionDesc_SetLogLevel',
        helpTextArgs = { '"type"', '"severity"' }, -- avoid showing %1 %2
        capability = Capability.DebugConsole,
        suggestSpec = {
            {
                type = 'option',
                options = (function()
                    local options = {} ---@type string[]
                    local list = DebugLog.getDebugTypes()
                    for i = 0, list:size() - 1 do
                        options[#options + 1] = list:get(i):name()
                    end

                    return options
                end)(),
            },
            {
                type = 'option',
                options = {
                    'Trace',
                    'Noise',
                    'Debug',
                    'General',
                    'Warning',
                    'Error',
                    'Off',
                },
            },
        },
    },
    {
        name = 'noclip',
        helpText = 'UI_ServerOptionDesc_NoClip',
        capability = Capability.ToggleNoclipHimself,
    },
    {
        name = 'players',
        helpText = 'UI_ServerOptionDesc_Players',
        capability = Capability.SeePlayersConnected,
    },
    {
        name = 'quit',
        helpText = 'UI_ServerOptionDesc_Quit',
        capability = Capability.QuitWorld,
    },
    {
        name = 'releasesafehouse',
        helpText = 'UI_ServerOptionDesc_SafeHouse',
        capability = Capability.CanSetupSafehouses,
    },
    {
        name = 'reloadalllua',
        helpText = 'UI_ServerOptionDesc_ReloadLua',
        capability = Capability.ReloadLuaFiles,
    },
    {
        name = 'reloadlua',
        helpText = 'UI_ServerOptionDesc_ReloadLua',
        capability = Capability.ReloadLuaFiles,
    },
    {
        name = 'reloadoptions',
        helpText = 'UI_ServerOptionDesc_ReloadOptions',
        capability = Capability.ChangeAndReloadServerOptions,
    },
    {
        name = 'removeuserfromwhitelist',
        helpText = 'UI_ServerOptionDesc_RemoveWhitelist',
        capability = Capability.ManipulateWhitelist,
    },
    {
        name = 'remove',
        helpText = 'UI_ServerOptionDesc_Remove',
        capability = Capability.AnimalCheats,
        suggestSpec = {
            {
                type = 'option',
                options = {
                    'animals',
                    'zombies',
                    'corpses',
                    'vehicles',
                },
            },
        },
    },
    {
        name = 'removeadmin',
        capability = Capability.ChangeAccessLevel,
    },
    {
        name = 'removeitem',
        helpText = 'UI_ServerOptionDesc_RemoveItem',
        capability = Capability.EditItem,
    },
    {
        name = 'removeuserfromwhitelist',
        helpText = 'UI_ServerOptionDesc_RemoveWhitelist',
        capability = Capability.ManipulateWhitelist,
    },
    {
        name = 'removezombies',
        helpText = 'UI_ServerOptionDesc_RemoveZombies',
        capability = Capability.ManipulateZombie,
    },
    {
        name = 'save',
        helpText = 'UI_ServerOptionDesc_Save',
        capability = Capability.SaveWorld,
    },
    {
        name = 'servermsg',
        helpText = 'UI_ServerOptionDesc_ServerMsg',
        capability = Capability.DisplayServerMessage,
    },
    {
        name = 'setaccesslevel',
        helpText = 'UI_ServerOptionDesc_SetAccessLevel',
        capability = Capability.ChangeAccessLevel,
        suggestSpec = { 'online-username-with-self', 'role' },
    },
    {
        name = 'setpassword',
        helpText = 'UI_ServerOptionDesc_SetPassword',
        capability = Capability.ModifyNetworkUsers,
    },
    {
        name = 'setTimeSpeed',
        helpText = 'UI_ServerOptionDesc_SetTimeSpeed',
        capability = Capability.ConnectWithDebug,
    },
    {
        name = 'showoptions',
        helpText = 'UI_ServerOptionDesc_ShowOptions',
        capability = Capability.SeePublicServerOptions,
    },
    {
        name = 'startrain',
        helpText = 'UI_ServerOptionDesc_StartRain',
        capability = Capability.StartStopRain,
    },
    {
        name = 'startstorm',
        helpText = 'UI_ServerOptionDesc_StartStorm',
        capability = Capability.StartStopRain,
    },
    {
        name = 'stats',
        helpText = 'UI_ServerOptionDesc_Statistics',
        capability = Capability.GetStatistic,
    },
    {
        name = 'stoprain',
        helpText = 'UI_ServerOptionDesc_StopRain',
        capability = Capability.StartStopRain,
    },
    {
        name = 'stopweather',
        helpText = 'UI_ServerOptionDesc_StopWeather',
        capability = Capability.StartStopRain,
    },
    {
        name = 'teleport',
        helpText = 'UI_ServerOptionDesc_TeleportTo',
        suggestSpec = { 'online-username' },
        capability = Capability.TeleportToPlayer,
    },
    {
        name = 'teleportplayer',
        helpText = 'UI_ServerOptionDesc_Teleport',
        suggestSpec = {
            'online-username-with-self',
            {
                type = 'online-username-with-self',
                filter = function(result, args)
                    return result ~= args[1]
                end,
            },
        },
        capability = Capability.TeleportPlayerToAnotherPlayer,
    },
    {
        name = 'teleportto',
        helpText = 'UI_ServerOptionDesc_TeleportTo',
        capability = Capability.TeleportToCoordinates,
    },
    {
        name = 'thunder',
        helpText = 'UI_ServerOptionDesc_Thunder',
        suggestSpec = { 'online-username-with-self' },
        capability = Capability.StartStopRain,
    },
    {
        name = 'unbanid',
        helpText = 'UI_ServerOptionDesc_UnBanSteamId',
        capability = Capability.BanUnbanUser,
    },
    {
        name = 'unbanid',
        helpText = 'UI_ServerOptionDesc_UnBanIp',
        capability = Capability.BanUnbanUser,
    },
    {
        name = 'unbanuser',
        helpText = 'UI_ServerOptionDesc_UnBanUser',
        capability = Capability.BanUnbanUser,
    },
    {
        name = 'voiceban',
        helpText = 'UI_ServerOptionDesc_VoiceBan',
        suggestSpec = { 'online-username' },
        capability = Capability.BanUnbanUser,
    },
    {
        name = 'worldgen',
        helpText = 'UI_ServerOptionDesc_Worldgen',
        capability = Capability.SaveWorld,
        suggestSpec = {
            {
                type = 'option',
                options = {
                    'start',
                    'stop',
                    'status',
                    'recheck',
                },
            },
        },
    },
}

return VanillaCommandList

--#region Type Definitions

---@class VanillaCommand
---@field name string The name of the command.
---@field helpText? string The string ID of the command's help text.
---@field capability Capability Capability required to use the command.
---@field helpTextArgs? string[] Arguments to supply to the command's help text.
---@field suggestSpec? SuggestArgSpec[] Spec for suggestions.

--#endregion
