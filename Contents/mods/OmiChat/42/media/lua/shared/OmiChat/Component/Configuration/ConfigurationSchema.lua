---Schema for the mod's configuration options.
---@namespace omichat
---@diagnostic disable: access-invisible

local utils = require 'OmiChat/Utils'
local Helpers = require 'OmiChat/Component/Configuration/ConfigurationHelpers'

local array = utils.schema.array
local bool = utils.schema.bool
local color = utils.schema.color
local compat = utils.schema.compatibility
local container = utils.schema.container
local double = utils.schema.double
local enum = utils.schema.stringEnum
local int = utils.schema.int
local object = utils.schema.object
local set = utils.schema.set
local str = utils.schema.string
local DEFAULT = '$Default()'

local CLEAR_ON_DEATH = {
    'Icon',
    'Languages',
    'Nickname',
    'Status',
}

local BUILTIN_MACROS = {
    'Emote',
}


return utils.schema {
    form = require 'OmiChat/Component/Configuration/ConfigurationForm',

    properties = {
        VERSION = int(1),

        General = container {
            Preset = str('Buffy'),

            AlwaysShowChat = bool(false),
            CaseInsensitiveChatStreams = bool(true),

            ClearOnDeath = set {
                default = utils.set.table(CLEAR_ON_DEATH),
                items = enum { values = CLEAR_ON_DEATH },
            },

            AdminIcon = str('Item_Hammer'),

            InfoText = str(),

            Variables = array {
                items = str(),
                default = {
                    'DefaultNameMode:name',
                    'DefaultNameMode_admin:username',
                    'DefaultNameMode_whisper:both',
                    'PMParenthesisCount:2',
                    'VolumeIndicatorLoud:Long',
                },
            },
        },

        Buffs = container {
            Enable = bool(true),
            Cooldown = int(15, 0, 1440),

            Boredom = double(0.2, 0, 1),
            Unhappiness = double(0.2, 0, 1),
            Hunger = double(0.1, 0, 1),
            Thirst = double(0.1, 0, 1),
            Fatigue = double(0.1, 0, 1),
            CigaretteStress = double(0.2, 0, 1),
        },

        Callouts = container {
            Format = str(DEFAULT),
            SneakFormat = str(DEFAULT),
            Range = int(48, 1, 60),
            SneakRange = int(6, 1, 60),
        },

        Commands = container {
            Name = container {
                Mode = enum {
                    default = 'Nickname',
                    values = {
                        'Disable',
                        'Nickname',
                        'Forename',
                        'Fullname',
                        'Forename-Plus-Nickname',
                        'Fullname-Plus-Nickname',
                    },
                },
            },

            Status = container {
                Enable = bool(true),
                Range = int(20, 1, 100),
            },

            Card = container {
                Global = bool(false),
                OverheadFormat = str(DEFAULT),
                Items = array {
                    items = str(),
                    default = { 'CardDeck' },
                },
                Tags = array { items = str() },
            },
            Roll = container {
                Global = bool(false),
                OverheadFormat = str(DEFAULT),
                Items = array {
                    items = str(),
                    default = {
                        'Dice',
                        'Dice_00',
                        'Dice_4',
                        'Dice_6',
                        'Dice_8',
                        'Dice_10',
                        'Dice_12',
                        'Dice_20',
                    },
                },
                Tags = array { items = str() },
            },
            Flip = container {
                Global = bool(false),
                OverheadFormat = str(DEFAULT),
                Items = array { items = str() },
                Tags = array { items = str() },
            },
        },

        Compatibility = container {
            ApplyOverrides = bool(true),
            ChatBubble = compat(),
            SearchPlayers = compat(),
            TrueActionsDancing = compat(),
        },

        Customization = container {
            AllowCustomShouts = bool(true),
            EnableNameColors = bool(true), -- based on speech colors
            EnableCharacterCustomization = bool(true),

            CleanEffects = set {
                default = utils.set.table { 'Body', 'Clothing' },
                items = enum {
                    values = {
                        'Body',
                        'Clothing',
                    },
                },
            },
        },

        Discord = container {
            ChatFormat = str(DEFAULT),
            DefaultColor = color {
                default = { r = 144, g = 137, b = 218 },
            },
            ShowColorOption = enum {
                default = 'Respect-Server-Setting',
                values = {
                    'Yes',
                    'No',
                    'Respect-Server-Setting',
                },
            },
            Tags = array {
                items = str(),
                default = { 'OOC', 'UseAuthorUsername' },
            },
        },

        EchoMessages = container {
            Enable = bool(true),
            ChatFormat = str(DEFAULT),
            OverheadFormat = str(DEFAULT),
            Tags = array {
                items = str(),
                default = { 'OverRadio' },
            },
        },

        Format = container {
            Chat = container {
                Prefix = str(DEFAULT),
                Final = str(DEFAULT),
            },

            Overhead = container {
                Prefix = str(DEFAULT),
                Final = str(DEFAULT),
            },

            PerceptionRange = container {
                Chat = str(DEFAULT),
                Overhead = str(DEFAULT),
            },

            Component = container {
                Name = str(DEFAULT),
                Tag = str(DEFAULT),
                Timestamp = str(DEFAULT),
                Icon = str(DEFAULT),
                Language = str(DEFAULT),
                EmbeddedQuote = str(DEFAULT),
                EmbeddedAction = str(DEFAULT),
            },

            Filter = container {
                ChatInput = str(DEFAULT),
                Name = str(DEFAULT),
                Status = str(DEFAULT),
            },

            MenuName = container {
                Trade = str(DEFAULT),
                Medical = str(DEFAULT),
                SearchPlayer = str(DEFAULT),
                MiniScoreboard = str(DEFAULT),
            },
        },

        Language = container {
            UseDefaultList = bool(true),
            List = array {
                maxItems = 1000, -- Configuration.MAX_LANGUAGES

                getDefault = Helpers.getDefaultLanguages,

                items = object {
                    skipMissing = true,
                    properties = {
                        Name = str(),
                        Signed = bool(false),
                    },
                },
            },

            DefaultSlots = int(1, 0, 50),
            InterpretationRolls = int(2, 0, 10),
            InterpretationChance = int(25, 0, 100),

            UnknownLanguageOverhead = str(DEFAULT),
            UnknownLanguageChat = str(DEFAULT),
            UnknownLanguageRadio = str(DEFAULT),

            SelfAddAllowlist = array { items = str() },
            SelfAddBlocklist = array { items = str() },
        },

        Macros = container {
            Enable = bool(true),
            BuiltIn = set {
                default = utils.set.table(BUILTIN_MACROS),
                items = enum { values = BUILTIN_MACROS },
            },
        },

        Mentions = container {
            Enable = bool(true),
            AlwaysUseNameColors = bool(true),
            Range = int(20, 0, 60),
            ChatFormat = str(DEFAULT),
            OverheadFormat = str(DEFAULT),
        },

        NarrativeStyle = container {
            Enable = bool(true),
            OverheadContentFormat = str(DEFAULT),
            ChatContentFormat = str(DEFAULT),
            DialogueTagFormat = str(DEFAULT),
            InputFilter = str(DEFAULT),
        },

        Radio = container {
            ChatFormat = str(DEFAULT),
            OverheadFormat = str(DEFAULT),
            DefaultColor = color {
                default = { r = 178, g = 178, b = 178 },
            },
            Tags = array {
                items = str(),
                default = { 'NoVolumeIndicator' },
            },
        },

        ServerMessages = container {
            ChatFormat = str(DEFAULT),
            DefaultColor = color {
                default = { r = 0, g = 128, b = 255 },
            },
            Tags = array {
                items = str(),
                default = { 'NoTimestamp' },
            },
        },

        Streams = container {
            UseDefaultList = bool(true),
            List = array {
                maxItems = 50, -- Configuration.MAX_CHAT_STREAMS

                getDefault = Helpers.getDefaultStreamsPopulated,

                items = object {
                    skipMissing = true,
                    properties = {
                        Enable = bool(true),

                        Stream = enum {
                            default = 'custom',
                            values = {
                                'custom',
                                'say',
                                'yell',
                                'private',
                                'faction',
                                'safehouse',
                                'general',
                                'admin',
                                'whisper',
                                'low',
                                'me',
                                'meloud',
                                'mequiet',
                                'mewhisper',
                                'do',
                                'doloud',
                                'doquiet',
                                'dowhisper',
                                'ooc',
                            },
                        },

                        Name = str(), -- ignored for non-custom streams
                        Command = str(),
                        ShortCommand = str(),

                        ChatType = enum {
                            default = 'say',
                            values = {
                                'say',
                                'shout',
                                'faction',
                                'safehouse',
                                'whisper',
                                'general',
                                'admin',
                            },
                        },

                        Category = enum {
                            default = 'chat',
                            values = {
                                'chat',
                                'rp',
                                'other',
                            },
                        },

                        DefaultColor = color(),
                        Range = int(30, 1, 60), -- maximum is dependent on chat type
                        VerticalRange = int(2, 1, 32),
                        PerceptionRange = int(0, 0, 60),
                        PerceptionRangeSigned = int(0, 0, 60),

                        ChatFormat = str(DEFAULT),
                        OverheadFormat = str(DEFAULT),

                        AllowBuffs = bool(false),
                        AllowMentions = bool(true),
                        AllowLanguages = bool(false),
                        AllowTypingIndicator = bool(false),
                        AttractZombies = bool(false),
                        UseNarrativeStyle = bool(false),

                        Tags = array { items = str() },
                        Aliases = array { items = str() },

                    },
                },
            },

            GlobalTags = array {
                items = str(),
                default = {
                    'ActionAsterisks',
                    'IncludeAdminIndicator',
                },
            },
        },

        TypingIndicator = container {
            Enable = bool(true),
            Format = str(DEFAULT),
            NameFormat = str(DEFAULT),
        },

        ZombieAttraction = container {
            ChatRangeMultiplier = double(0, 0, 10),
            CalloutRange = int(30, 1, 60),
            SneakCalloutRange = int(6, 1, 60),
        },
    },

    ---@param values Configuration
    onRead = function(values)
        -- read default languages
        local languages = values.Language.List
        values._Languages = languages

        if type(languages) ~= 'table' or values.Language.UseDefaultList then
            languages = Helpers.getDefaultLanguages()
        end

        -- read default stream data
        local streams = values.Streams.List

        values._Streams = streams

        if type(streams) ~= 'table' or #streams == 0 or values.Streams.UseDefaultList then
            streams = Helpers.getDefaultStreams()
        else
            streams = utils.deepcopy(streams)
        end

        values.Language.List = languages
        values.Streams.List = Helpers.processStreams(streams)
    end,

    ---@param values Configuration
    sanitize = function(values)
        -- doesn't do anything, so don't save it to avoid confusion
        values.General.Preset = nil

        if values._Streams then
            values.Streams = values.Streams or {}
            values.Streams.List = values._Streams
            values._Streams = nil
        end

        if values._Languages then
            values.Language = values.Language or {}
            values.Language.List = values._Languages
            values._Languages = nil
        end
    end,
}

--#region Type Definitions

---@class Configuration
---@field General Configuration.General
---@field Buffs Configuration.Buffs
---@field Callouts Configuration.Callouts
---@field Commands Configuration.Commands
---@field Compatibility Configuration.Compatibility
---@field Customization Configuration.Customization
---@field Discord Configuration.Discord
---@field Format Configuration.Format
---@field EchoMessages Configuration.EchoMessages
---@field Language Configuration.Language
---@field Macros Configuration.Macros
---@field Mentions Configuration.Mentions
---@field NarrativeStyle Configuration.NarrativeStyle
---@field Radio Configuration.Radio
---@field ServerMessages Configuration.ServerMessages
---@field Streams Configuration.Streams
---@field TypingIndicator Configuration.TypingIndicator
---@field ZombieAttraction Configuration.ZombieAttraction
---@field private _Languages? any
---@field private _Streams? any

---@class Configuration.General
---@field Preset string
---@field AlwaysShowChat boolean
---@field CaseInsensitiveChatStreams boolean
---@field AdminIcon string
---@field ClearOnDeath Configuration.General.ClearOnDeath
---@field InfoText string
---@field Variables string[]

---@class Configuration.General.ClearOnDeath
---@field Icon boolean?
---@field Languages boolean?
---@field Nickname boolean?
---@field Status boolean?

---@class Configuration.Buffs
---@field Enable boolean
---@field Cooldown integer
---@field Boredom number
---@field Unhappiness number
---@field Hunger number
---@field Thirst number
---@field Fatigue number
---@field CigaretteStress number

---@class Configuration.Callouts
---@field Range integer
---@field SneakRange integer
---@field Format string
---@field SneakFormat string

---@class Configuration.Commands
---@field Name Configuration.Commands.Name
---@field Status Configuration.Commands.Status
---@field Card Configuration.Commands.ItemCommand
---@field Roll Configuration.Commands.ItemCommand
---@field Flip Configuration.Commands.ItemCommand

---@class Configuration.Commands.Name
---@field Mode Configuration.Commands.Name.Mode

---@class Configuration.Commands.Status
---@field Enable boolean
---@field Range number

---@class Configuration.Commands.ItemCommand
---@field Global boolean
---@field OverheadFormat string
---@field Items string[]
---@field Tags string[]

---@class Configuration.Compatibility
---@field ApplyOverrides boolean
---@field ChatBubble omi.schema.CompatibilityValue
---@field SearchPlayers omi.schema.CompatibilityValue
---@field TrueActionsDancing omi.schema.CompatibilityValue

---@class Configuration.Customization
---@field AllowCustomShouts boolean
---@field EnableNameColors boolean
---@field EnableCharacterCustomization boolean
---@field CleanEffects omi.SetTable<string>

---@class Configuration.Discord
---@field ShowColorOption 'Yes' | 'No' | 'Respect-Server-Setting'
---@field ChatFormat string
---@field DefaultColor omi.ColorTable<integer>
---@field Tags string[]

---@class Configuration.EchoMessages
---@field Enable boolean
---@field ChatFormat string
---@field OverheadFormat string
---@field Tags string[]

---@class Configuration.Format
---@field Chat Configuration.Format.Chat
---@field Component Configuration.Format.Component
---@field Filter Configuration.Format.Filter
---@field MenuName Configuration.Format.MenuName
---@field PerceptionRange Configuration.Format.PerceptionRange
---@field Overhead Configuration.Format.Overhead

---@class Configuration.Format.Chat
---@field Final string
---@field Prefix string

---@class Configuration.Format.Component
---@field Name string
---@field Tag string
---@field Timestamp string
---@field Icon string
---@field Language string
---@field EmbeddedAction string
---@field EmbeddedQuote string

---@class Configuration.Format.Filter
---@field Name string
---@field Status string
---@field ChatInput string

---@class Configuration.Format.MenuName
---@field Trade string
---@field Medical string
---@field SearchPlayer string
---@field MiniScoreboard string

---@class Configuration.Format.PerceptionRange
---@field Chat string
---@field Overhead string

---@class Configuration.Format.Overhead
---@field Final string
---@field Prefix string

---@class Configuration.Language
---@field DefaultSlots integer
---@field InterpretationRolls integer
---@field InterpretationChance integer
---@field SelfAddAllowlist string[]
---@field SelfAddBlocklist string[]
---@field UnknownLanguageChat string
---@field UnknownLanguageRadio string
---@field UnknownLanguageOverhead string
---@field UseDefaultList boolean
---@field List Configuration.LanguageDefinition[]

---@class Configuration.Macros
---@field Enable boolean
---@field BuiltIn Configuration.Macros.BuiltIn

---@class Configuration.Macros.BuiltIn
---@field Emote boolean?

---@class Configuration.Mentions
---@field Enable boolean
---@field AlwaysUseNameColors boolean
---@field Range integer
---@field ChatFormat string
---@field OverheadFormat string

---@class Configuration.NarrativeStyle
---@field Enable boolean
---@field OverheadContentFormat string
---@field ChatContentFormat string
---@field DialogueTagFormat string
---@field InputFilter string

---@class Configuration.Radio
---@field ChatFormat string
---@field OverheadFormat string
---@field DefaultColor omi.ColorTable<integer>
---@field Tags string[]

---@class Configuration.ServerMessages
---@field ChatFormat string
---@field DefaultColor omi.ColorTable<integer>
---@field Tags string[]

---@class Configuration.Streams
---@field UseDefaultList boolean
---@field GlobalTags string[]
---@field List Configuration.StreamDefinition[]

---@class Configuration.TypingIndicator
---@field Enable boolean
---@field NameFormat string
---@field Format string

---@class Configuration.ZombieAttraction
---@field ChatRangeMultiplier number
---@field CalloutRange integer
---@field SneakCalloutRange integer


---@class Configuration.LanguageDefinition
---@field Name string The name of the language.
---@field Signed boolean? Flag for whether the language should be treated as signed.

---@class Configuration.StreamDefinition
---@field Enable boolean?
---@field Stream string?
---@field ChatType omi.ChatTypeString?
---@field Category StreamCategory?
---@field Name string?
---@field Command string?
---@field ShortCommand string?
---@field DefaultColor omi.ColorTable<integer>?
---@field Aliases string[]?
---@field Tags string[]?
---@field OverheadFormat string?
---@field ChatFormat string?
---@field Range integer?
---@field VerticalRange integer?
---@field PerceptionRange integer?
---@field PerceptionRangeSigned integer?
---@field AllowBuffs boolean?
---@field AllowMentions boolean?
---@field AllowLanguages boolean?
---@field AllowTypingIndicator boolean?
---@field AttractZombies boolean?
---@field UseNarrativeStyle boolean?


---@alias Configuration.Commands.Name.Mode
---| 'Disable'
---| 'Nickname'
---| 'Forename'
---| 'Fullname'
---| 'Forename-Plus-Nickname'
---| 'Fullname-Plus-Nickname'

--#endregion
