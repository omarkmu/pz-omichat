---Vanilla preset.

local utils = require 'OmiChat/utils'
local Preset = require 'OmiChat/Component/Configuration/Preset'

local set = utils.set.simple


return Preset:new {
    name = 'Vanilla',
    values = {
        General = {
            Preset = 'Vanilla',
            AlwaysShowChat = false,
            CaseInsensitiveChatStreams = false,
            ClearOnDeath = set { 'Icon', 'Languages', 'Nickname' },
            MinimumCommandAccessLevel = 16,
            AdminIcon = 'Item_Hammer',
            InfoText = '',
        },
        Buffs = {
            Enable = false,
            Cooldown = 15,
            Boredom = 0.2,
            Unhappiness = 0.2,
            Hunger = 0.1,
            Thirst = 0.1,
            Fatigue = 0.1,
            CigaretteStress = 0.2,
        },
        Callouts = {
            Format = '$DefaultOverheadFormat()',
            SneakFormat = '$DefaultOverheadFormat()',
            Range = 60,
            SneakRange = 6,
        },
        Commands = {
            SetName = 'Disable',
            Card = {
                Global = true,
                Format = '$DefaultCardFormat()',
                OverheadFormat = '$DefaultOverheadFormat()',
                ChatFormat = '$DefaultChatFormat()',
                Items = { 'CardDeck' },
                Tags = {},
            },
            Roll = {
                Global = true,
                Format = '$DefaultRollFormat()',
                OverheadFormat = '$DefaultOverheadFormat()',
                ChatFormat = '$DefaultChatFormat()',
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
                Global = true,
                Format = '$DefaultFlipFormat()',
                OverheadFormat = '$DefaultOverheadFormat()',
                ChatFormat = '$DefaultChatFormat()',
                Items = {},
                Tags = {},
            },
        },
        Compatibility = {
            BuffyCharacterBios = 'Disable',
            BuffyRPGSystem = 'Disable',
            ChatBubble = 'Disable',
            SearchPlayers = 'Disable',
            TrueActionsDancing = 'Disable',
        },
        Customization = {
            AllowCustomShouts = false,
            EnableNameColors = false,
            EnableCharacterCustomization = false,
            CleanEffects = {},
        },
        Discord = {
            ChatFormat = '$DefaultChatFormat()',
            DefaultColor = { r = 144, g = 137, b = 218 },
            ShowColorOption = 'Respect_Server_Setting',
            Tags = {
                'UseAuthorUsername',
            },
        },
        EchoMessages = {
            Enable = false,
            ChatFormat = '$DefaultChatFormat()',
            OverheadFormat = '$DefaultOverheadFormat()',
            Tags = {
                'OverRadio',
            },
        },
        Format = {
            Component = {
                Name = '$DefaultNameFormat()',
                Tag = '$DefaultTagFormat()',
                Timestamp = '$DefaultTimestampFormat()',
                Icon = '$DefaultIconFormat()',
                Language = '$DefaultLanguageFormat()',
                EmbeddedQuote = '$DefaultEmbeddedQuoteFormat()',
                EmbeddedAction = '$DefaultEmbeddedActionFormat()',
            },
            Overhead = {
                Final = '$DefaultFullOverheadFormat()',
                Prefix = '$DefaultOverheadPrefix()',
            },
            PerceptionRange = {
                Chat = '$DefaultPerceptionRangeChatFormat()',
                Overhead = '$DefaultPerceptionRangeOverheadFormat()',
            },
            Chat = {
                Final = '$DefaultFullChatFormat()',
                Prefix = '$DefaultChatPrefix()',
            },
            Filter = {
                Name = '$DefaultNameFilter()',
                ChatInput = '$DefaultChatInputFilter()',
            },
            MenuName = {
                Default = '$DefaultMenuNameFormat()',
            },
        },
        Language = {
            UseDefaultList = false,
            List = {},
            DefaultSlots = 1,
            InterpretationRolls = 2,
            InterpretationChance = 25,
            UnknownLanguage = '$DefaultUnknownLanguageFormat()',
            UnknownLanguageRadio = '$DefaultUnknownLanguageFormat()',
            SelfAddAllowlist = {},
            SelfAddBlocklist = {},
        },
        Macros = {
            AllowEmotes = false,
        },
        NarrativeStyle = {
            Enable = false,
            OverheadContentFormat = '$DefaultNarrativeOverheadFormat()',
            ChatContentFormat = '$DefaultNarrativeChatFormat()',
            DialogueTagFormat = '$DefaultNarrativeTag()',
            InputFilter = '$DefaultNarrativeInputFilter()',
        },
        Radio = {
            ChatFormat = '$DefaultChatFormat()',
            DefaultColor = { r = 178, g = 178, b = 178 },
            Tags = { 'UseAuthorUsername' },
        },
        ServerMessages = {
            ChatFormat = '$DefaultChatFormat()',
            DefaultColor = { r = 0, g = 128, b = 255 },
            Tags = { 'NoTimestamp' },
        },
        Streams = {
            UseDefaultList = false,
            GlobalTags = { 'BracketedNames', 'NoPrefixSpaceChat', 'NoIcon' },
            List = {
                {
                    Stream = 'admin',
                    Enable = true,
                },
                {
                    Stream = 'say',
                    Enable = true,
                    Tags = {
                        'EchoTarget',
                    },
                },
                {
                    Stream = 'yell',
                    Enable = true,
                    Tags = {
                        'Loud',
                        'Callout',
                        'SneakCallout',
                        'NoVolumeIndicator',
                    },
                },
                {
                    Stream = 'low',
                    Enable = false,
                },
                {
                    Stream = 'whisper',
                    Enable = false,
                },
                {
                    Stream = 'me',
                    Enable = false,
                    Tags = {
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'Action',
                        'IncludeName',
                        'ActionColorTarget',
                        'CardCommandTarget',
                        'FlipCommandTarget',
                        'RollCommandTarget',
                        'BuffyRPGTarget',
                        'UseNameColor',
                    },
                },
                {
                    Stream = 'meloud',
                    Enable = false,
                },
                {
                    Stream = 'mequiet',
                    Enable = false,
                },
                {
                    Stream = 'mewhisper',
                    Enable = false,
                },
                {
                    Stream = 'do',
                    Enable = false,
                },
                {
                    Stream = 'doloud',
                    Enable = false,
                },
                {
                    Stream = 'doquiet',
                    Enable = false,
                },
                {
                    Stream = 'dowhisper',
                    Enable = false,
                },
                {
                    Stream = 'ooc',
                    Enable = false,
                },
                {
                    Stream = 'private',
                    Command = '/whisper',
                    ShortCommand = '/w',
                    Enable = true,
                    Tags = {
                        'UseVanillaPM',
                    },
                },
                {
                    Stream = 'faction',
                    Enable = true,
                },
                {
                    Stream = 'safehouse',
                    Enable = true,
                },
                {
                    Stream = 'general',
                    Enable = true,
                },
            },
        },
        TypingIndicator = {
            Enable = false,
            Format = '$DefaultTypingFormat()',
        },
        ZombieAttraction = {
            ChatRangeMultiplier = 0,
            CalloutRange = 30,
            SneakCalloutRange = 6,
        },
    },
}
