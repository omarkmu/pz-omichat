---Information about the mod's configuration options.

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


return utils.schema {
    form = require 'OmiChat/Component/Configuration/ConfigurationForm',

    properties = {
        VERSION = int(1),

        General = container {
            Preset = str('Default'),

            AlwaysShowChat = bool(false),
            CaseInsensitiveChatStreams = bool(true),

            ClearOnDeath = set {
                default = utils.set.simple { 'Icon', 'Languages', 'Nickname', 'Status' },
                items = enum {
                    values = {
                        'Icon',
                        'Languages',
                        'Nickname',
                        'Status',
                    },
                },
            },

            MinimumCommandAccessLevel = int(16, 1, 32),

            AdminIcon = str('Item_Sledgehamer'),

            InfoText = str(),

            Variables = array { items = str() },
        },

        Buffs = container {
            Enable = bool(false),
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
            Range = int(60, 1, 60),
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
                        'Forename_Plus_Nickname',
                        'Fullname_Plus_Nickname',
                    },
                },
            },

            Status = container {
                Enable = bool(true),
                Range = int(20, 1, 100),
            },

            Card = container {
                Global = bool(false),
                Format = str(DEFAULT),
                OverheadFormat = str(DEFAULT),
                Items = array {
                    items = str(),
                    default = { 'CardDeck' },
                },
                Tags = array { items = str() },
            },
            Roll = container {
                Global = bool(false),
                Format = str(DEFAULT),
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
                Format = str(DEFAULT),
                OverheadFormat = str(DEFAULT),
                Items = array { items = str() },
                Tags = array { items = str() },
            },
        },

        Compatibility = container {
            ApplyOverrides = bool(true),
            BuffyCharacterBios = compat(),
            BuffyRPGSystem = compat(),
            ChatBubble = compat(),
            SearchPlayers = compat(),
            TrueActionsDancing = compat(),
        },

        Customization = container {
            AllowCustomShouts = bool(true),
            EnableNameColors = bool(true), -- based on speech colors
            EnableCharacterCustomization = bool(false),

            CleanEffects = set {
                default = utils.set.simple { 'Body', 'Clothing' },
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
                default = 'Respect_Server_Setting',
                values = {
                    'Yes',
                    'No',
                    'Respect_Server_Setting',
                },
            },
            Tags = array {
                items = str(),
                default = { 'UseAuthorUsername' },
            },
        },

        EchoMessages = container {
            Enable = bool(false),
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
            AllowEmotes = bool(true),
        },

        Mentions = container {
            Enable = bool(true),
            AlwaysUseNameColors = bool(true),
            Range = int(20, 0, 60),
            Format = str(DEFAULT),
            ChatFormat = str(DEFAULT),
        },

        NarrativeStyle = container {
            Enable = bool(false),
            OverheadContentFormat = str(DEFAULT),
            ChatContentFormat = str(DEFAULT),
            DialogueTagFormat = str(DEFAULT),
            InputFilter = str(DEFAULT),
        },

        Radio = container {
            ChatFormat = str(DEFAULT),
            DefaultColor = color {
                default = { r = 178, g = 178, b = 178 },
            },
            Tags = array {
                items = str(),
                default = { 'IncludeColon' },
            },
        },

        ServerMessages = container {
            ChatFormat = str(DEFAULT),
            DefaultColor = color {
                default = { r = 0, g = 128, b = 255 },
            },
            Tags = array {
                items = str(),
                default = { 'NoTimestamp', 'NoTagColon' },
            },
        },

        Streams = container {
            UseDefaultList = bool(true),
            List = array {
                maxItems = 32, -- Configuration.MAX_CHAT_STREAMS

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
                        AllowEmotes = bool(false),
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

            GlobalTags = array { items = str() },
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

    ---@diagnostic disable: inject-field
    ---@param values omichat.Configuration
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

    ---@param values omichat.Configuration
    sanitize = function(values)
        values.Streams = values.Streams or {}
        values.Language = values.Language or {}

        values.Streams.List = values._Streams
        values.Language.List = values._Languages
        values._Streams = nil
        values._Languages = nil
    end,
    ---@diagnostic enable: inject-field
}


--#region Type Definitions

---@class omichat.Configuration
---@field General omichat.Configuration.General
---@field Buffs omichat.Configuration.Buffs
---@field Callouts omichat.Configuration.Callouts
---@field Commands omichat.Configuration.Commands
---@field Compatibility omichat.Configuration.Compatibility
---@field Customization omichat.Configuration.Customization
---@field Discord omichat.Configuration.Discord
---@field Format omichat.Configuration.Format
---@field EchoMessages omichat.Configuration.EchoMessages
---@field Language omichat.Configuration.Language
---@field Macros omichat.Configuration.Macros
---@field Mentions omichat.Configuration.Mentions
---@field NarrativeStyle omichat.Configuration.NarrativeStyle
---@field Radio omichat.Configuration.Radio
---@field ServerMessages omichat.Configuration.ServerMessages
---@field Streams omichat.Configuration.Streams
---@field TypingIndicator omichat.Configuration.TypingIndicator
---@field ZombieAttraction omichat.Configuration.ZombieAttraction

---@class omichat.Configuration.General
---@field Preset string
---@field AlwaysShowChat boolean
---@field CaseInsensitiveChatStreams boolean
---@field MinimumCommandAccessLevel integer
---@field AdminIcon string
---@field ClearOnDeath omichat.Configuration.General.ClearOnDeath
---@field InfoText string
---@field Variables string[]

---@class omichat.Configuration.General.ClearOnDeath
---@field Icon boolean?
---@field Languages boolean?
---@field Nickname boolean?
---@field Status boolean?

---@class omichat.Configuration.Buffs
---@field Enable boolean
---@field Cooldown integer
---@field Boredom number
---@field Unhappiness number
---@field Hunger number
---@field Thirst number
---@field Fatigue number
---@field CigaretteStress number

---@class omichat.Configuration.Callouts
---@field Range integer
---@field SneakRange integer
---@field Format string
---@field SneakFormat string

---@class omichat.Configuration.Commands
---@field Name omichat.Configuration.Commands.Name
---@field Status omichat.Configuration.Commands.Status
---@field Card omichat.Configuration.Commands.ItemCommand
---@field Roll omichat.Configuration.Commands.ItemCommand
---@field Flip omichat.Configuration.Commands.ItemCommand

---@class omichat.Configuration.Commands.Name
---@field Mode omichat.Configuration.Commands.Name.Mode

---@class omichat.Configuration.Commands.Status
---@field Enable boolean
---@field Range number

---@class omichat.Configuration.Commands.ItemCommand
---@field Global boolean
---@field Format string
---@field OverheadFormat string
---@field Items string[]
---@field Tags string[]

---@class omichat.Configuration.Compatibility
---@field ApplyOverrides boolean
---@field BuffyCharacterBios omi.schema.CompatibilityValue
---@field BuffyRPGSystem omi.schema.CompatibilityValue
---@field ChatBubble omi.schema.CompatibilityValue
---@field SearchPlayers omi.schema.CompatibilityValue
---@field TrueActionsDancing omi.schema.CompatibilityValue

---@class omichat.Configuration.Customization
---@field AllowCustomShouts boolean
---@field EnableNameColors boolean
---@field EnableCharacterCustomization boolean
---@field CleanEffects omi.SimpleSet

---@class omichat.Configuration.Discord
---@field ShowColorOption 'Yes' | 'No' | 'Respect_Server_Setting'
---@field ChatFormat string
---@field DefaultColor omi.ColorTable
---@field Tags string[]

---@class omichat.Configuration.EchoMessages
---@field Enable boolean
---@field ChatFormat string
---@field OverheadFormat string
---@field Tags string[]

---@class omichat.Configuration.Format
---@field Chat omichat.Configuration.Format.Chat
---@field Component omichat.Configuration.Format.Component
---@field Filter omichat.Configuration.Format.Filter
---@field MenuName omichat.Configuration.Format.MenuName
---@field PerceptionRange omichat.Configuration.Format.PerceptionRange
---@field Overhead omichat.Configuration.Format.Overhead

---@class omichat.Configuration.Format.Chat
---@field Final string
---@field Prefix string

---@class omichat.Configuration.Format.Component
---@field Name string
---@field Tag string
---@field Timestamp string
---@field Icon string
---@field Language string
---@field EmbeddedAction string
---@field EmbeddedQuote string

---@class omichat.Configuration.Format.Filter
---@field Name string
---@field Status string
---@field ChatInput string

---@class omichat.Configuration.Format.MenuName
---@field Trade string
---@field Medical string
---@field SearchPlayer string
---@field MiniScoreboard string

---@class omichat.Configuration.Format.PerceptionRange
---@field Chat string
---@field Overhead string

---@class omichat.Configuration.Format.Overhead
---@field Final string
---@field Prefix string

---@class omichat.Configuration.Language
---@field DefaultSlots integer
---@field InterpretationRolls integer
---@field InterpretationChance integer
---@field SelfAddAllowlist string[]
---@field SelfAddBlocklist string[]
---@field UnknownLanguageChat string
---@field UnknownLanguageRadio string
---@field UnknownLanguageOverhead string
---@field UseDefaultList boolean
---@field List omichat.Configuration.LanguageDefinition[]

---@class omichat.Configuration.Macros
---@field AllowEmotes boolean

---@class omichat.Configuration.Mentions
---@field Enable boolean
---@field AlwaysUseNameColors boolean
---@field Range integer
---@field Format string
---@field ChatFormat string

---@class omichat.Configuration.NarrativeStyle
---@field Enable boolean
---@field OverheadContentFormat string
---@field ChatContentFormat string
---@field DialogueTagFormat string
---@field InputFilter string

---@class omichat.Configuration.Radio
---@field ChatFormat string
---@field DefaultColor omi.ColorTable
---@field Tags string[]

---@class omichat.Configuration.ServerMessages
---@field ChatFormat string
---@field DefaultColor omi.ColorTable
---@field Tags string[]

---@class omichat.Configuration.Streams
---@field UseDefaultList boolean
---@field GlobalTags string[]
---@field List omichat.Configuration.StreamDefinition[]

---@class omichat.Configuration.TypingIndicator
---@field Enable boolean
---@field NameFormat string
---@field Format string

---@class omichat.Configuration.ZombieAttraction
---@field ChatRangeMultiplier number
---@field CalloutRange integer
---@field SneakCalloutRange integer


---@class omichat.Configuration.LanguageDefinition
---@field Name string The name of the language.
---@field Signed boolean? Flag for whether the language should be treated as signed.

---@class omichat.Configuration.StreamDefinition
---@field Enable boolean?
---@field Stream string?
---@field ChatType string?
---@field Category string?
---@field Name string?
---@field Command string?
---@field ShortCommand string?
---@field DefaultColor omi.ColorTable?
---@field Aliases string[]?
---@field Tags string[]?
---@field OverheadFormat string?
---@field ChatFormat string?
---@field Range integer?
---@field VerticalRange integer?
---@field PerceptionRange integer?
---@field PerceptionRangeSigned integer?
---@field AllowBuffs boolean?
---@field AllowEmotes boolean?
---@field AllowMentions boolean?
---@field AllowLanguages boolean?
---@field AllowTypingIndicator boolean?
---@field AttractZombies boolean?
---@field UseNarrativeStyle boolean?

--#endregion
