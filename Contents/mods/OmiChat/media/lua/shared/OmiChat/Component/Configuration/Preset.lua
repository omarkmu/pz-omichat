---Class for configuration presets.

local utils = require 'OmiChat/utils'
local set = utils.set.simple
local DEFAULT = '$Default()'


---@class omichat.ConfigurationPreset : omi.Class
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
---@param options omichat.Args.ConfigurationPreset.Callouts?
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
---@param options omichat.Args.ConfigurationPreset.Commands?
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
            Enable = utils.default(options.EnableStatus, true),
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
---@param enable boolean?
---@return omichat.Configuration.Compatibility
function Preset.compatibility(enable)
    local value = utils.default(enable, true) and 'Auto' or 'Disable'

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
---@param options omichat.Args.ConfigurationPreset.Customization?
---@return omichat.Configuration.Customization
function Preset.customization(options)
    options = options or {}

    local value = utils.default(options.Enable, true)

    ---@type omichat.Configuration.Customization
    return {
        AllowCustomShouts = value,
        EnableNameColors = value,
        EnableCharacterCustomization = value,
        CleanEffects = set(options.CleanEffects or { 'Body', 'Clothing' }),
    }
end

---Creates a table for Discord configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.Discord?
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
---@param options omichat.Args.ConfigurationPreset.Echo?
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
            Default = DEFAULT,
        },
    }
end

---Creates a table for general configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.General
---@return omichat.Configuration.General
function Preset.general(options)
    ---@type omichat.Configuration.General
    return {
        Preset = options.Name,
        AlwaysShowChat = false,
        CaseInsensitiveChatStreams = utils.default(options.CaseInsensitiveChatStreams, true),
        MinimumCommandAccessLevel = 16,
        InfoText = '',
        AdminIcon = options.AdminIcon or 'Item_Sledgehamer',
        ClearOnDeath = options.ClearOnDeath or Preset.clearOnDeath(),
        Variables = options.Variables or {},
    }
end

---Returns the default language configuration.
---@param options omichat.Args.ConfigurationPreset.Language?
---@return omichat.Configuration.Language
function Preset.languages(options)
    options = options or {}

    ---@type omichat.Configuration.Language
    return {
        UseDefaultList = utils.default(options.UseDefaultList, true),
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

---Returns the default macro configuration.
---@param options omichat.Args.ConfigurationPreset.Macros?
---@return omichat.Configuration.Macros
function Preset.macros(options)
    options = options or {}

    ---@type omichat.Configuration.Macros
    return {
        AllowEmotes = utils.default(options.AllowEmotes, true),
    }
end

---Returns the default narrative style configuration.
---@param options omichat.Args.ConfigurationPreset.NarrativeStyle?
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
---@param options omichat.Args.ConfigurationPreset.Radio?
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
---@param options omichat.Args.ConfigurationPreset.ServerMessages?
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
---@param options omichat.Args.ConfigurationPreset.TypingIndicator?
---@return omichat.Configuration.TypingIndicator
function Preset.typing(options)
    options = options or {}

    ---@type omichat.Configuration.TypingIndicator
    return {
        Enable = utils.default(options.Enable, true),
        Format = DEFAULT,
    }
end

---Creates a table for zombie attraction configuration based on the defaults.
---@param options omichat.Args.ConfigurationPreset.ZombieAttraction?
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
---@return boolean
function Preset:isCustom()
    return self._isCustom
end

---Returns the ID of the preset.
---For built-in presets, this is the preset name. Custom user-defined presets are prefixed with `custom:`.
---@return string
function Preset:getID()
    if not self._isCustom then
        return self._name
    end

    return 'custom:' .. self._name
end

---Returns the name of the preset.
---@return string
function Preset:getName()
    return self._name
end

---Gets the values associated with the preset.
---@param schema omichat.ConfigurationSchema
---@return omichat.Configuration
function Preset:getValues(schema)
    local values
    if self._getValues then
        values = self:_getValues(schema) or {}
    else
        values = utils.deepcopy(self._values)
    end

    if self._getLanguages then
        values.Language.List = self:_getLanguages(schema)
    end

    if self._getStreams then
        values.Streams.List = self:_getStreams(schema)
    end

    return values
end


---Creates a new configuration preset.
---@param args omichat.Args.ConfigurationPreset?
---@return omichat.ConfigurationPreset
function Preset:new(args)
    local this = setmetatable({}, self) ---@cast this omichat.ConfigurationPreset

    args = args or {}
    this._name = args.name
    this._isCustom = utils.default(args.isCustom, false)
    this._values = args.values or {}
    this._getValues = args.getValues
    this._getLanguages = args.getLanguages
    this._getStreams = args.getStreams

    return this
end


return Preset
