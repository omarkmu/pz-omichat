---Class for configuration presets.

local utils = require 'OmiChat/Utils'
local set = utils.set.simple
local DEFAULT = '$Default()'


---@class omichat.ConfigurationPreset : omi.Class
---@field protected _name string The name of the preset.
---@field protected _isCustom boolean Flag for whether the preset is a custom, user-defined preset.
---@field protected _values omichat.Configuration The preset's configuration values.
local Preset = utils.lib.class()


---Creates a table for configuration of buffs based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Buffs? Options for creation of the table.
---@return omichat.Configuration.Buffs
function Preset.buffs(options)
    options = options or {}

    ---@type omichat.Configuration.Buffs
    return {
        Enable = options.Enable or false,
        Cooldown = 15,
        Boredom = 0.2,
        Unhappiness = 0.2,
        Hunger = 0.1,
        Thirst = 0.1,
        Fatigue = 0.1,
        CigaretteStress = 0.2,
    }
end

---Creates a table for callout configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Callouts? Options for creation of the table.
---@return omichat.Configuration.Callouts
function Preset.callouts(options)
    options = options or {}

    ---@type omichat.Configuration.Callouts
    return {
        Format = DEFAULT,
        SneakFormat = DEFAULT,
        Range = options.Range or 60,
        SneakRange = options.SneakRange or 6,
    }
end

---Returns the default set for information to clear on player character death.
---@return omichat.Configuration.General.ClearOnDeath
function Preset.clearOnDeath()
    return set {
        'Icon',
        'Languages',
        'Nickname',
        'Status',
    }
end

---Creates a table for command configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Commands? Options for creation of the table.
---@return omichat.Configuration.Commands
function Preset.commands(options)
    options = options or {}

    local globalCommands = options.GlobalCommands or false

    ---@type omichat.Configuration.Commands
    return {
        Name = {
            Mode = options.NameMode or 'Nickname',
        },
        Status = {
            Enable = options.EnableStatus ~= false,
            Range = 20,
        },
        Card = {
            Global = globalCommands,
            Format = DEFAULT,
            OverheadFormat = DEFAULT,
            ChatFormat = DEFAULT,
            Items = { 'CardDeck' },
            Tags = {},
        },
        Roll = {
            Global = globalCommands,
            Format = DEFAULT,
            OverheadFormat = DEFAULT,
            ChatFormat = DEFAULT,
            Items = {
                'Dice',
                'Dice_00',
                'Dice_4',
                'Dice_6',
                'Dice_8',
                'Dice_10',
                'Dice_12',
                'Dice_20',
            },
            Tags = {},
        },
        Flip = {
            Global = globalCommands,
            Format = DEFAULT,
            OverheadFormat = DEFAULT,
            ChatFormat = DEFAULT,
            Items = {},
            Tags = {},
        },
    }
end

---Returns the default values for compatibility options.
---@param enable boolean? Flag for whether compatibility options should be set to `'Auto'`. Defaults to `true`.
---@return omichat.Configuration.Compatibility
function Preset.compatibility(enable)
    local value = enable ~= false and 'Auto' or 'Disable'

    ---@type omichat.Configuration.Compatibility
    return {
        ApplyOverrides = true,
        BuffyCharacterBios = value,
        BuffyRPGSystem = value,
        ChatBubble = value,
        SearchPlayers = value,
        TrueActionsDancing = value,
    }
end

---Creates a table for customization configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Customization? Options for creation of the table.
---@return omichat.Configuration.Customization
function Preset.customization(options)
    options = options or {}

    local value = options.Enable ~= false

    ---@type omichat.Configuration.Customization
    return {
        AllowCustomShouts = value,
        EnableNameColors = value,
        EnableCharacterCustomization = value,
        CleanEffects = set(options.CleanEffects or { 'Body', 'Clothing' }),
    }
end

---Creates a table for Discord configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Discord? Options for creation of the table.
---@return omichat.Configuration.Discord
function Preset.discord(options)
    options = options or {}

    ---@type omichat.Configuration.Discord
    return {
        ChatFormat = DEFAULT,
        DefaultColor = { r = 144, g = 137, b = 218 },
        ShowColorOption = 'Respect_Server_Setting',
        Tags = options.Tags or { 'UseAuthorUsername' },
    }
end

---Creates a table for echo message configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Echo? Options for creation of the table.
---@return omichat.Configuration.EchoMessages
function Preset.echo(options)
    options = options or {}

    ---@type omichat.Configuration.EchoMessages
    return {
        Enable = options.Enable or false,
        ChatFormat = DEFAULT,
        OverheadFormat = DEFAULT,
        Tags = options.Tags or { 'OverRadio' },
    }
end

---Returns the default format configuration.
---@return omichat.Configuration.Format
function Preset.format()
    ---@type omichat.Configuration.Format
    return {
        Component = {
            Name = DEFAULT,
            Tag = DEFAULT,
            Timestamp = DEFAULT,
            Icon = DEFAULT,
            Language = DEFAULT,
            EmbeddedQuote = DEFAULT,
            EmbeddedAction = DEFAULT,
        },
        Overhead = {
            Prefix = DEFAULT,
            Final = DEFAULT,
        },
        PerceptionRange = {
            Chat = DEFAULT,
            Overhead = DEFAULT,
        },
        Chat = {
            Prefix = DEFAULT,
            Final = DEFAULT,
        },
        Filter = {
            Name = DEFAULT,
            Status = DEFAULT,
            ChatInput = DEFAULT,
        },
        MenuName = {
            Trade = DEFAULT,
            Medical = DEFAULT,
            MiniScoreboard = DEFAULT,
            SearchPlayer = DEFAULT,
        },
    }
end

---Creates a table for general configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.General Options for creation of the table.
---@return omichat.Configuration.General
function Preset.general(options)
    ---@type omichat.Configuration.General
    return {
        Preset = options.Name,
        AlwaysShowChat = false,
        CaseInsensitiveChatStreams = options.CaseInsensitiveChatStreams ~= false,
        MinimumCommandAccessLevel = 16,
        InfoText = '',
        AdminIcon = options.AdminIcon or 'Item_Sledgehamer',
        ClearOnDeath = options.ClearOnDeath or Preset.clearOnDeath(),
        Variables = options.Variables or {},
    }
end

---Creates a table for language configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Language? Options for creation of the table.
---@return omichat.Configuration.Language
function Preset.languages(options)
    options = options or {}

    ---@type omichat.Configuration.Language
    return {
        UseDefaultList = options.UseDefaultList ~= false,
        List = options.List or {},
        DefaultSlots = 1,
        InterpretationRolls = 2,
        InterpretationChance = 25,
        UnknownLanguageChat = DEFAULT,
        UnknownLanguageRadio = DEFAULT,
        UnknownLanguageOverhead = DEFAULT,
        SelfAddAllowlist = {},
        SelfAddBlocklist = {},
    }
end

---Creates a table for macro configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Macros? Options for creation of the table.
---@return omichat.Configuration.Macros
function Preset.macros(options)
    options = options or {}

    ---@type omichat.Configuration.Macros
    return {
        AllowEmotes = options.AllowEmotes ~= false,
    }
end

---Creates a table for mention configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Mentions? Options for creation of the table.
---@return omichat.Configuration.Mentions
function Preset.mentions(options)
    options = options or {}

    ---@type omichat.Configuration.Mentions
    return {
        Enable = options.Enable ~= false,
        AlwaysUseNameColors = true,
        Range = options.Range or 10,
        Format = DEFAULT,
        ChatFormat = DEFAULT,
    }
end

---Creates a table for narrative style configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.NarrativeStyle? Options for creation of the table.
---@return omichat.Configuration.NarrativeStyle
function Preset.narrative(options)
    options = options or {}

    ---@type omichat.Configuration.NarrativeStyle
    return {
        Enable = options.Enable or false,
        OverheadContentFormat = DEFAULT,
        ChatContentFormat = DEFAULT,
        DialogueTagFormat = DEFAULT,
        InputFilter = DEFAULT,
    }
end

---Creates a table for radio configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Radio? Options for creation of the table.
---@return omichat.Configuration.Radio
function Preset.radio(options)
    options = options or {}

    ---@type omichat.Configuration.Radio
    return {
        ChatFormat = DEFAULT,
        DefaultColor = { r = 178, g = 178, b = 178 },
        Tags = options.Tags or {},
    }
end

---Creates a table for server message configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.ServerMessages? Options for creation of the table.
---@return omichat.Configuration.ServerMessages
function Preset.server(options)
    options = options or {}

    ---@type omichat.Configuration.ServerMessages
    return {
        ChatFormat = DEFAULT,
        DefaultColor = { r = 0, g = 128, b = 255 },
        Tags = options.Tags or { 'NoTimestamp', 'NoTagColon' },
    }
end

---Creates a table for typing indicator configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.TypingIndicator? Options for creation of the table.
---@return omichat.Configuration.TypingIndicator
function Preset.typing(options)
    options = options or {}

    ---@type omichat.Configuration.TypingIndicator
    return {
        Enable = options.Enable ~= false,
        Format = DEFAULT,
        NameFormat = DEFAULT,
    }
end

---Creates a table for zombie attraction configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.ZombieAttraction? Options for creation of the table.
---@return omichat.Configuration.ZombieAttraction
function Preset.zombies(options)
    options = options or {}

    ---@type omichat.Configuration.ZombieAttraction
    return {
        ChatRangeMultiplier = options.ChatRangeMultiplier or 0,
        CalloutRange = options.CalloutRange or 30,
        SneakCalloutRange = options.SneakCalloutRange or 6,
    }
end


---Returns whether the preset is a user-defined custom preset.
---@return boolean isCustom
function Preset:isCustom()
    return self._isCustom
end

---Returns the ID of the preset.
---For built-in presets, this is the preset name. Custom user-defined presets are prefixed with `custom:`.
---@return string id
function Preset:getID()
    if not self._isCustom then
        return self._name
    end

    return 'custom:' .. self._name
end

---Returns the name of the preset.
---@return string name
function Preset:getName()
    return self._name
end

---Gets the values associated with the preset.
---@return omichat.Configuration values
function Preset:getValues()
    return utils.deepcopy(self._values)
end


---Creates a new configuration preset.
---@param args omichat.Args.ConfigurationPreset? Arguments for preset creation.
---@return omichat.ConfigurationPreset preset
function Preset:new(args)
    local this = setmetatable({}, self) --[[@as omichat.ConfigurationPreset]]

    args = args or {}
    this._name = args.name
    this._isCustom = args.isCustom or false
    this._values = args.values or {}

    return this
end


return Preset


--#region Type Definitions

---@class omichat.Configuration.PresetTable
---@field name string The name of the preset.
---@field values table The configuration values.

---@class omichat.Args.ConfigurationPreset
---@field name string The name of the preset.
---@field isCustom boolean? Flag for whether the preset is custom (user-defined).
---@field values omichat.Configuration? The preset's configuration values.

---@class omichat.Args.ConfigurationPreset.Buffs
---@field Enable boolean? Flag for whether buffs should be enabled. Defaults to `false`.

---@class omichat.Args.ConfigurationPreset.Callouts
---@field Range integer? The callout range to use. Defaults to `60`.
---@field SneakRange integer? The sneak callout range to use. Defaults to `6`.

---@class omichat.Args.ConfigurationPreset.Commands
---@field NameMode omichat.Configuration.Commands.Name.Mode? The mode to use for name commands. Defaults to `Nickname`.
---@field EnableStatus boolean? Flag for whether the `/status` command is enabled. Defaults to `true`.
---@field GlobalCommands boolean? Flag for whether the `/card`, `/flip`, and `/roll` commands should be global. Defaults to `false`.

---@class omichat.Args.ConfigurationPreset.Customization
---@field Enable boolean? Flag for whether customization features should be enabled. Defaults to `true`.
---@field CleanEffects string[]? The clean effects to enable. Defaults to `['Body', 'Clothing']`.

---@class omichat.Args.ConfigurationPreset.Discord
---@field Tags string[]? Tags to include on the Discord stream. Defaults to `['UseAuthorUsername']`.

---@class omichat.Args.ConfigurationPreset.Echo
---@field Enable boolean? Flag for whether echo messages are enabled. Defaults to `false`.
---@field Tags string[]? Tags to include on echo messages. Defaults to `['OverRadio']`.

---@class omichat.Args.ConfigurationPreset.General
---@field Name string The name of the preset.
---@field AdminIcon string? The texture name to use as the admin icon. Defaults to `Item_Sledgehamer` [sic].
---@field CaseInsensitiveChatStreams boolean? Flag for whether chat streams are case-insensitive. Defaults to `true`.
---@field ClearOnDeath omichat.Configuration.General.ClearOnDeath? Information taht should be cleared death.
---@field Variables string[]? Arbitrary key-value pairs for variables.

---@class omichat.Args.ConfigurationPreset.Language
---@field UseDefaultList boolean? Flag for whether the default language list should be used. Defaults to `true`.
---@field List omichat.Configuration.LanguageDefinition[]? A list of languages to use.

---@class omichat.Args.ConfigurationPreset.Macros
---@field AllowEmotes boolean? Flag for whether emotes should be enabled. Defaults to `true`.

---@class omichat.Args.ConfigurationPreset.Mentions
---@field Enable boolean? Flag for whether mentions should be enabled. Defaults to `true`.
---@field Range integer? Range for mentions on ranged streams. Defaults to `10`.

---@class omichat.Args.ConfigurationPreset.NarrativeStyle
---@field Enable boolean? Flag for whether narrative style should be enabled.

---@class omichat.Args.ConfigurationPreset.Radio
---@field Tags string[]? Tags to include on the radio stream. Defaults to no tags.

---@class omichat.Args.ConfigurationPreset.ServerMessages
---@field Tags string[]? Tags to include on the server message stream. Defaults to `['NoTimestamp', 'NoTagColon']`.

---@class omichat.Args.ConfigurationPreset.TypingIndicator
---@field Enable boolean? Flag for whether the typing indicator should be enabled.

---@class omichat.Args.ConfigurationPreset.ZombieAttraction
---@field ChatRangeMultiplier number? The multiplier to use with the chat range to determine the zombie attraction range. Defaults to `0`.
---@field CalloutRange integer? The default zombie attraction range for callouts. Defaults to `30`.
---@field SneakCalloutRange integer? The default zombie attraction range for sneak callouts. Defaults to `6`.


--#endregion
