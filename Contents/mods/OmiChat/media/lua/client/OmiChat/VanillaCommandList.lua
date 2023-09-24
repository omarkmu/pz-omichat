---@class omichat.VanillaCommandEntry
---@field name string
---@field helpText string
---@field access integer
---@field helpTextArgs string[]?

---List of vanilla commands used for extending the /help command.
---Excludes disabled commands and commands without help text.
---@type omichat.VanillaCommandEntry[]
return {
    {
        name = 'additem',
        helpText = 'UI_ServerOptionDesc_AddItem',
        access = 60,
    },
    {
        name = 'adduser',
        helpText = 'UI_ServerOptionDesc_AddUser',
        access = 48,
    },
    {
        name = 'addvehicle',
        helpText = 'UI_ServerOptionDesc_AddVehicle',
        access = 60,
    },
    {
        name = 'addxp',
        helpText = 'UI_ServerOptionDesc_AddXp',
        access = 60,
    },
    {
        name = 'alarm',
        helpText = 'UI_ServerOptionDesc_Alarm',
        access = 60,
    },
    {
        name = 'banid',
        helpText = 'UI_ServerOptionDesc_BanSteamId',
        access = 48,
    },
    {
        name = 'banuser',
        helpText = 'UI_ServerOptionDesc_BanUser',
        access = 48,
    },
    {
        name = 'changeoption',
        helpText = 'UI_ServerOptionDesc_ChangeOptions',
        access = 32,
    },
    {
        name = 'checkModsNeedUpdate',
        helpText = 'UI_ServerOptionDesc_CheckModsNeedUpdate',
        access = 62,
    },
    {
        name = 'chopper',
        helpText = 'UI_ServerOptionDesc_Chopper',
        access = 60,
    },
    {
        name = 'createhorde',
        helpText = 'UI_ServerOptionDesc_CreateHorde',
        access = 56,
    },
    {
        name = 'createhorde2',
        helpText = 'UI_ServerOptionDesc_CreateHorde2',
        access = 56,
    },
    {
        name = 'godmod',
        helpText = 'UI_ServerOptionDesc_GodMod',
        access = 62,
    },
    {
        name = 'gunshot',
        helpText = 'UI_ServerOptionDesc_Gunshot',
        access = 60,
    },
    {
        name = 'help',
        helpText = 'UI_ServerOptionDesc_Help',
        access = 32,
    },
    {
        name = 'invisible',
        helpText = 'UI_ServerOptionDesc_Invisible',
        access = 62,
    },
    {
        name = 'kick',
        helpText = 'UI_ServerOptionDesc_Kick',
        access = 56,
    },
    {
        name = 'lightning',
        helpText = 'UI_ServerOptionDesc_Lightning',
        access = 60,
    },
    {
        name = 'log',
        helpText = 'UI_ServerOptionDesc_SetLogLevel',
        -- avoid showing %1 %2
        helpTextArgs = { '"type"', '"severity"' },
        access = 32,
    },
    {
        name = 'noclip',
        helpText = 'UI_ServerOptionDesc_NoClip',
        access = 62,
    },
    {
        name = 'players',
        helpText = 'UI_ServerOptionDesc_Players',
        access = 62,
    },
    {
        name = 'quit',
        helpText = 'UI_ServerOptionDesc_Quit',
        access = 32,
    },
    {
        name = 'releasesafehouse',
        helpText = 'UI_ServerOptionDesc_SafeHouse',
        access = 63,
    },
    {
        name = 'reloadlua',
        helpText = 'UI_ServerOptionDesc_ReloadLua',
        access = 32,
    },
    {
        name = 'reloadoptions',
        helpText = 'UI_ServerOptionDesc_ReloadLua',
        access = 32,
    },
    {
        name = 'removeuserfromwhitelist',
        helpText = 'UI_ServerOptionDesc_RemoveWhitelist',
        access = 48,
    },
    {
        name = 'removezombies',
        helpText = 'UI_ServerOptionDesc_RemoveZombies',
        access = 56,
    },
    {
        name = 'replay',
        helpText = 'UI_ServerOptionDesc_Replay',
        access = 32,
    },
    {
        name = 'save',
        helpText = 'UI_ServerOptionDesc_Save',
        access = 32,
    },
    {
        name = 'servermsg',
        helpText = 'UI_ServerOptionDesc_ServerMsg',
        access = 56,
    },
    {
        name = 'setaccesslevel',
        helpText = 'UI_ServerOptionDesc_SetAccessLevel',
        access = 48,
    },
    {
        name = 'showoptions',
        helpText = 'UI_ServerOptionDesc_ShowOptions',
        access = 63,
    },
    {
        name = 'startrain',
        helpText = 'UI_ServerOptionDesc_StartRain',
        access = 60,
    },
    {
        name = 'startstorm',
        helpText = 'UI_ServerOptionDesc_StartStorm',
        access = 60,
    },
    {
        name = 'stats',
        helpText = 'UI_ServerOptionDesc_SetStatisticsPeriod',
        access = 32,
    },
    {
        name = 'stoprain',
        helpText = 'UI_ServerOptionDesc_StopRain',
        access = 60,
    },
    {
        name = 'stopweather',
        helpText = 'UI_ServerOptionDesc_StopWeather',
        access = 60,
    },
    {
        name = 'teleport',
        helpText = 'UI_ServerOptionDesc_Teleport',
        access = 62,
    },
    {
        name = 'teleportto',
        helpText = 'UI_ServerOptionDesc_TeleportTo',
        access = 62,
    },
    {
        name = 'thunder',
        helpText = 'UI_ServerOptionDesc_Thunder',
        access = 60,
    },
    {
        name = 'unbanid',
        helpText = 'UI_ServerOptionDesc_UnBanSteamId',
        access = 48,
    },
    {
        name = 'unbanuser',
        helpText = 'UI_ServerOptionDesc_UnBanUser',
        access = 48,
    },
    {
        name = 'voiceban',
        helpText = 'UI_ServerOptionDesc_VoiceBan',
        access = 48,
    },
}
