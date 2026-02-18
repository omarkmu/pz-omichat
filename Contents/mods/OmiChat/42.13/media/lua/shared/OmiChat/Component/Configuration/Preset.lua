---Class for configuration presets.
---@namespace omichat

local utils = require 'OmiChat/Utils'
local set = utils.set.table
local DEFAULT = '$Default()'


---@class ConfigurationPreset : omi.Class
---@field protected _name string The name of the preset.
---@field protected _tooltip string? The tooltip to use for the preset.
---@field protected _isCustom boolean Flag for whether the preset is a custom, user-defined preset.
---@field protected _values Configuration The preset's configuration values.
local Preset = utils.class('Preset')


---Creates a table for configuration of buffs based on the defaults.
---@param options Args.ConfigurationPreset.Buffs? Options for creation of the table.
---@return Configuration.Buffs
function Preset.buffs(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Buffs]]

    ---@type Configuration.Buffs
    return {
        Enable = options.Enable ~= false,
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
---@param options Args.ConfigurationPreset.Callouts? Options for creation of the table.
---@return Configuration.Callouts
function Preset.callouts(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Callouts]]

    ---@type Configuration.Callouts
    return {
        Format = DEFAULT,
        SneakFormat = DEFAULT,
        Range = options.Range or 48,
        SneakRange = options.SneakRange or 6,
    }
end

---Returns the default set for information to clear on player character death.
---@return Configuration.General.ClearOnDeath
function Preset.clearOnDeath()
    return {
        Icon = true,
        Languages = true,
        Nickname = true,
        Status = true,
    }
end

---Creates a table for command configuration based on the defaults.
---@param options Args.ConfigurationPreset.Commands? Options for creation of the table.
---@return Configuration.Commands
function Preset.commands(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Commands]]

    local globalCommands = options.GlobalCommands or false

    ---@type Configuration.Commands
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
---@return Configuration.Compatibility
function Preset.compatibility(enable)
    local value = enable ~= false and 'Auto' or 'Disable'

    ---@type Configuration.Compatibility
    return {
        ApplyOverrides = true,
        ChatBubble = value,
        SearchPlayers = value,
        TrueActionsDancing = value,
    }
end

---Creates a table for customization configuration based on the defaults.
---@param options Args.ConfigurationPreset.Customization? Options for creation of the table.
---@return Configuration.Customization
function Preset.customization(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Customization]]

    local value = options.Enable ~= false

    ---@type Configuration.Customization
    return {
        AllowCustomShouts = value,
        EnableNameColors = value,
        EnableCharacterCustomization = value,
        CleanEffects = set(options.CleanEffects or { 'Body', 'Clothing' }),
    }
end

---Creates a table for Discord configuration based on the defaults.
---@param options Args.ConfigurationPreset.Discord? Options for creation of the table.
---@return Configuration.Discord
function Preset.discord(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Discord]]

    ---@type Configuration.Discord
    return {
        ChatFormat = DEFAULT,
        DefaultColor = { r = 144, g = 137, b = 218 },
        ShowColorOption = 'Respect-Server-Setting',
        Tags = options.Tags or { 'UseAuthorUsername' },
    }
end

---Creates a table for echo message configuration based on the defaults.
---@param options Args.ConfigurationPreset.Echo? Options for creation of the table.
---@return Configuration.EchoMessages
function Preset.echo(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Echo]]

    ---@type Configuration.EchoMessages
    return {
        Enable = options.Enable ~= false,
        ChatFormat = DEFAULT,
        OverheadFormat = DEFAULT,
        Tags = options.Tags or { 'OverRadio' },
    }
end

---Returns the default format configuration.
---@param options Args.ConfigurationPreset.Format? Options for creation of the table.
---@return Configuration.Format
function Preset.format(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Format]]

    ---@type Configuration.Format
    return {
        Other = {
            PMParentheses = options.PMParentheses or 2,
            DefaultNameMode = options.DefaultNameMode or 'name',
            DefaultNameModeForChatType = options.DefaultNameModeForChatType or {},
            VolumeIndicators = options.VolumeIndicators or {},
        },
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
---@param options Args.ConfigurationPreset.General Options for creation of the table.
---@return Configuration.General
function Preset.general(options)
    ---@type Configuration.General
    return {
        Preset = options.Name,
        AlwaysShowChat = false,
        CaseInsensitiveChatStreams = options.CaseInsensitiveChatStreams ~= false,
        IncludeRangeIndicatorButton = options.IncludeRangeIndicatorButton or false,
        InfoText = '',
        AdminIcon = options.AdminIcon or 'Item_Hammer',
        ClearOnDeath = options.ClearOnDeath or Preset.clearOnDeath(),
        Variables = options.Variables or {},
    }
end

---Creates a table for language configuration based on the defaults.
---@param options Args.ConfigurationPreset.Language? Options for creation of the table.
---@return Configuration.Language
function Preset.languages(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Language]]

    ---@type Configuration.Language
    return {
        UseDefaultList = options.UseDefaultList ~= false,
        List = options.List or {},
        DefaultSlots = options.DefaultSlots or 1,
        InterpretationRolls = 2,
        InterpretationChance = 25,
        UnknownLanguageChat = DEFAULT,
        UnknownLanguageRadio = DEFAULT,
        UnknownLanguageOverhead = DEFAULT,
        PlaceholderFormat = DEFAULT,
        PlaceholderColor = { r = 127, g = 127, b = 127 },
        SelfAddAllowlist = {},
        SelfAddBlocklist = {},
    }
end

---Creates a table for macro configuration based on the defaults.
---@param options Args.ConfigurationPreset.Macros? Options for creation of the table.
---@return Configuration.Macros
function Preset.macros(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Macros]]

    ---@type Configuration.Macros
    return {
        Enable = options.Enable ~= false,
        BuiltIn = {
            Emote = true,
        },
    }
end

---Creates a table for mention configuration based on the defaults.
---@param options Args.ConfigurationPreset.Mentions? Options for creation of the table.
---@return Configuration.Mentions
function Preset.mentions(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Mentions]]

    ---@type Configuration.Mentions
    return {
        Enable = options.Enable ~= false,
        AlwaysUseNameColors = true,
        Range = options.Range or 10,
        ChatFormat = DEFAULT,
        OverheadFormat = DEFAULT,
    }
end

---Creates a table for narrative style configuration based on the defaults.
---@param options Args.ConfigurationPreset.NarrativeStyle? Options for creation of the table.
---@return Configuration.NarrativeStyle
function Preset.narrative(options)
    options = options or {} --[[@as Args.ConfigurationPreset.NarrativeStyle]]

    ---@type Configuration.NarrativeStyle
    return {
        Enable = options.Enable ~= false,
        OverheadContentFormat = DEFAULT,
        ChatContentFormat = DEFAULT,
        DialogueTagFormat = DEFAULT,
        InputFilter = DEFAULT,
    }
end

---Creates a table for radio configuration based on the defaults.
---@param options Args.ConfigurationPreset.Radio? Options for creation of the table.
---@return Configuration.Radio
function Preset.radio(options)
    options = options or {} --[[@as Args.ConfigurationPreset.Radio]]

    ---@type Configuration.Radio
    return {
        ChatFormat = DEFAULT,
        OverheadFormat = DEFAULT,
        DefaultColor = { r = 178, g = 178, b = 178 },
        Tags = options.Tags or { 'NoVolumeIndicator' },
    }
end

---Creates a table for server message configuration based on the defaults.
---@param options Args.ConfigurationPreset.ServerMessages? Options for creation of the table.
---@return Configuration.ServerMessages
function Preset.server(options)
    options = options or {} --[[@as Args.ConfigurationPreset.ServerMessages]]

    ---@type Configuration.ServerMessages
    return {
        ChatFormat = DEFAULT,
        DefaultColor = { r = 0, g = 128, b = 255 },
        Tags = options.Tags or { 'NoTimestamp' },
    }
end

---Creates a table for typing indicator configuration based on the defaults.
---@param options Args.ConfigurationPreset.TypingIndicator? Options for creation of the table.
---@return Configuration.TypingIndicator
function Preset.typing(options)
    options = options or {} --[[@as Args.ConfigurationPreset.TypingIndicator]]

    ---@type Configuration.TypingIndicator
    return {
        Enable = options.Enable ~= false,
        Format = DEFAULT,
        NameFormat = DEFAULT,
    }
end

---Creates a table for zombie attraction configuration based on the defaults.
---@param options Args.ConfigurationPreset.ZombieAttraction? Options for creation of the table.
---@return Configuration.ZombieAttraction
function Preset.zombies(options)
    options = options or {} --[[@as Args.ConfigurationPreset.ZombieAttraction]]

    ---@type Configuration.ZombieAttraction
    return {
        ChatRangeMultiplier = options.ChatRangeMultiplier or 0,
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

---Gets the tooltip to display for the preset.
---@return string?
function Preset:getTooltip()
    return self._tooltip
end

---Gets the values associated with the preset.
---@return Configuration values
function Preset:getValues()
    return utils.deepcopy(self._values)
end


---Creates a new configuration preset.
---@param args Args.ConfigurationPreset? Arguments for preset creation.
---@return ConfigurationPreset preset
function Preset:new(args)
    local this = utils.new(self)

    args = args or {} --[[@as Args.ConfigurationPreset]]
    this._name = args.name
    this._isCustom = args.isCustom or false
    this._values = args.values or {} --[[@as any]]

    if this._isCustom then
        this._tooltip = utils.getText('preset-custom')
    else
        this._tooltip = utils.getTextOrNull('preset-' .. this._name:lower())
    end

    return this
end


return Preset

--#region Type Definitions

---@class Args.ConfigurationPreset
---@field name string The name of the preset.
---@field isCustom? boolean Flag for whether the preset is custom (user-defined).
---@field values? Configuration The preset's configuration values.

---@class Args.ConfigurationPreset.Buffs
---@field Enable boolean? Flag for whether buffs should be enabled. Defaults to `true`.

---@class Args.ConfigurationPreset.Callouts
---@field Range integer? The callout range to use. Defaults to `48`.
---@field SneakRange integer? The sneak callout range to use. Defaults to `6`.

---@class Args.ConfigurationPreset.Commands
---@field NameMode Configuration.Commands.Name.Mode? The mode to use for name commands. Defaults to `Nickname`.
---@field EnableStatus boolean? Flag for whether the `/status` command is enabled. Defaults to `true`.
---@field GlobalCommands boolean? Flag for whether the `/card`, `/flip`, and `/roll` commands should be global. Defaults to `false`.

---@class Args.ConfigurationPreset.Customization
---@field Enable boolean? Flag for whether customization features should be enabled. Defaults to `true`.
---@field CleanEffects string[]? The clean effects to enable. Defaults to `['Body', 'Clothing']`.

---@class Args.ConfigurationPreset.Discord
---@field Tags string[]? Tags to include on the Discord stream. Defaults to `['OOC', 'UseAuthorUsername']`.

---@class Args.ConfigurationPreset.Echo
---@field Enable boolean? Flag for whether echo messages are enabled. Defaults to `true`.
---@field Tags string[]? Tags to include on echo messages. Defaults to `['OverRadio']`.

---@class Args.ConfigurationPreset.Format
---@field PMParentheses integer? The amount of parentheses to include for names in PMs. Defaults to `2`.
---@field DefaultNameMode ('name' | 'username' | 'both')? The default name mode.
---@field DefaultNameModeForChatType table<omi.ChatTypeString, 'name' | 'username' | 'both'>? The default name mode per chat type.
---@field VolumeIndicators table<string, string>? Volume indicator strings.

---@class Args.ConfigurationPreset.General
---@field Name string The name of the preset.
---@field AdminIcon string? The texture name to use as the admin icon. Defaults to `Item_Hammer`.
---@field CaseInsensitiveChatStreams boolean? Flag for whether chat streams are case-insensitive. Defaults to `true`.
---@field IncludeRangeIndicatorButton boolean? Flag for including the range indicator button. Defaults to `false`.
---@field ClearOnDeath Configuration.General.ClearOnDeath? Information that should be cleared death.
---@field Variables table<string, string>? Arbitrary key-value pairs for variables.

---@class Args.ConfigurationPreset.Language
---@field UseDefaultList boolean? Flag for whether the default language list should be used. Defaults to `true`.
---@field List Configuration.LanguageDefinition[]? A list of languages to use.
---@field DefaultSlots integer? The default number of language slots users should have. Defaults to `1`.

---@class Args.ConfigurationPreset.Macros
---@field Enable boolean? Flag for whether macros should be enabled. Defaults to `true`.

---@class Args.ConfigurationPreset.Mentions
---@field Enable boolean? Flag for whether mentions should be enabled. Defaults to `true`.
---@field Range integer? Range for mentions on ranged streams. Defaults to `10`.

---@class Args.ConfigurationPreset.NarrativeStyle
---@field Enable boolean? Flag for whether narrative style should be enabled. Defaults to `true`.

---@class Args.ConfigurationPreset.Radio
---@field Tags string[]? Tags to include on the radio stream. Defaults to no tags.

---@class Args.ConfigurationPreset.ServerMessages
---@field Tags string[]? Tags to include on the server message stream. Defaults to `['NoTimestamp']`.

---@class Args.ConfigurationPreset.TypingIndicator
---@field Enable boolean? Flag for whether the typing indicator should be enabled.

---@class Args.ConfigurationPreset.ZombieAttraction
---@field ChatRangeMultiplier number? The multiplier to use with the chat range to determine the zombie attraction range. Defaults to `0`.


---@class Configuration.PresetTable
---@field name string The name of the preset.
---@field values table The configuration values.

--#endregion
