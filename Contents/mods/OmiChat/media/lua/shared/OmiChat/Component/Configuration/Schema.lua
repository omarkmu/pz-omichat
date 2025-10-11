---Information about the mod's configuration options.

local utils = require 'OmiChat/utils'
local Schema = require 'OmiChat/Component/Configuration/SchemaClass'
local FormDefinition = require 'OmiChat/Definition/ConfigurationForm'

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


return Schema:new {
    form = FormDefinition,

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
                ChatFormat = str(DEFAULT),
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
                ChatFormat = str(DEFAULT),
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
                ChatFormat = str(DEFAULT),
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
                Default = str(DEFAULT),
                Trade = str(),
                Medical = str(),
                SearchPlayer = str(),
                Typing = str(),
                MiniScoreboard = str(),
            },
        },

        Language = container {
            UseDefaultList = bool(true),
            List = array {
                maxItems = 1000, -- Configuration.MAX_LANGUAGES

                ---@param schema omichat.ConfigurationSchema
                ---@return table
                getDefault = function(_, schema)
                    return schema:getDefaultLanguages()
                end,

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

                ---@param schema omichat.ConfigurationSchema
                ---@return table
                getDefault = function(_, schema)
                    return schema:processStreams(schema:getDefaultStreams())
                end,

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

                        CommandType = enum {
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
        },

        ZombieAttraction = container {
            ChatRangeMultiplier = double(0, 0, 10),
            CalloutRange = int(30, 1, 60),
            SneakCalloutRange = int(6, 1, 60),
        },
    },

    ---@param self omichat.ConfigurationSchema
    ---@param values omichat.Configuration
    onRead = function(self, values)
        -- read default languages
        local languages = values.Language.List
        values._Languages = languages ---@diagnostic disable-line: inject-field

        if type(languages) ~= 'table' or values.Language.UseDefaultList then
            languages = self:getDefaultLanguages()
        end

        -- read default stream data
        local streams = values.Streams.List
        values._Streams = streams ---@diagnostic disable-line: inject-field

        if type(streams) ~= 'table' or #streams == 0 or values.Streams.UseDefaultList then
            streams = self:getDefaultStreams()
        else
            streams = utils.deepcopy(streams)
        end

        values.Language.List = languages
        values.Streams.List = self:processStreams(streams)
    end,

    ---@param values omichat.Configuration
    sanitize = function(_, values)
        values.Streams = values.Streams or {}
        values.Language = values.Language or {}

        values.Streams.List = values._Streams
        values.Language.List = values._Languages
        values._Streams = nil ---@diagnostic disable-line: inject-field
        values._Languages = nil ---@diagnostic disable-line: inject-field
    end,
}
