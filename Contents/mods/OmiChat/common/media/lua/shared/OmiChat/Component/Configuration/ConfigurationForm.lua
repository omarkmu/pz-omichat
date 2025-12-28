---Configuration form layout.
---@namespace omichat

local utils = require 'OmiChat/Utils'
local Helpers = require 'OmiChat/Component/Configuration/ConfigurationHelpers'
local rules = Helpers.rules

local PAD_N = 10
local PAD_TOP = { paddingTop = PAD_N }
local PAD_BOTTOM = { paddingBottom = PAD_N }
local NO_REORDER = { noReorderButtons = true }
local ENABLE = { togglePageFields = true }

local TAGS = { noReorderButtons = true, onChange = Helpers.onChangeTag }
local FORMAT = { init = Helpers.initFormatOption, onInfoClick = Helpers.onClickFormatInfo }

local FORMAT_PAD_TOP = utils.extendCopy(FORMAT, PAD_TOP)
local FORMAT_PAD_BOTTOM = utils.extendCopy(FORMAT, PAD_BOTTOM)


---@type omi.forms.Args.Generator.Partial
return {
    prefix = 'OmiChat.config',
    closeOnSave = false,
    rules = {
        General = rules {
            Preset = {
                actionCount = 3,
                paddingBottom = 16,
                getEnumOptions = Helpers.getPresetOptions,
                onActionClick = Helpers.onClickPresetAction,
                onChange = Helpers.onChangePreset,
            },

            CaseInsensitiveChatStreams = PAD_BOTTOM,
            AdminIcon = {
                noFullWidth = true,
                paddingBottom = PAD_N,
            },

            InfoText = {
                displayLines = 10,
                maxLines = 50,
            },

            Variables = NO_REORDER,
        },

        Buffs = rules {
            Enable = ENABLE,
            Cooldown = PAD_BOTTOM,
        },

        Callouts = rules {
            Format = FORMAT,
            SneakFormat = FORMAT,
        },

        Commands = rules {
            Name = rules {
                Mode = { noLabel = true },
            },
            Status = rules {
                Enable = {
                    toggleFields = {
                        { 'Commands', 'Status', 'Range' },
                    },
                },
            },
            Card = {
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Card', 'Format' },
                            { 'Commands', 'Card', 'OverheadFormat' },
                            { 'Commands', 'Card', 'Tags' },
                        },
                    },
                    Items = NO_REORDER,
                    Format = FORMAT,
                    OverheadFormat = FORMAT,
                    Tags = TAGS,
                },
            },
            Roll = {
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Roll', 'Format' },
                            { 'Commands', 'Roll', 'OverheadFormat' },
                            { 'Commands', 'Roll', 'Tags' },
                        },
                    },
                    Items = NO_REORDER,
                    Format = FORMAT,
                    OverheadFormat = FORMAT,
                    Tags = TAGS,
                },
            },
            Flip = {
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Flip', 'Format' },
                            { 'Commands', 'Flip', 'OverheadFormat' },
                            { 'Commands', 'Flip', 'Tags' },
                        },
                    },
                    Items = NO_REORDER,
                    Format = FORMAT,
                    OverheadFormat = FORMAT,
                    Tags = TAGS,
                },
            },
        },

        -- hide compatibility options until relevant mods are updated
        Compatibility = rules {
            ChatBubble = { skip = true },
            SearchPlayers = { skip = true },
            TrueActionsDancing = { skip = true },
        },

        Customization = rules {
            EnableCharacterCustomization = {
                paddingTop = PAD_N,
                toggleFields = { { 'Customization', 'CleanEffects' } },
            },
        },

        Discord = rules {
            ChatFormat = FORMAT,
            ShowColorOption = PAD_TOP,
            Tags = TAGS,
        },

        EchoMessages = rules {
            Enable = ENABLE,
            ChatFormat = FORMAT,
            OverheadFormat = FORMAT,
            Tags = TAGS,
        },

        Format = rules {
            Chat = rules {
                Prefix = FORMAT,
                Final = FORMAT,
            },
            Overhead = rules {
                Prefix = FORMAT,
                Final = FORMAT,
            },
            PerceptionRange = rules {
                Chat = FORMAT,
                Overhead = FORMAT,
            },
            Component = rules {
                Name = FORMAT,
                Tag = FORMAT,
                Timestamp = FORMAT,
                Icon = FORMAT,
                Language = FORMAT,

                EmbeddedQuote = FORMAT_PAD_TOP,
                EmbeddedAction = FORMAT,
            },
            Filter = rules {
                ChatInput = FORMAT,
                Name = FORMAT,
                Status = FORMAT,
            },
            MenuName = rules {
                Default = FORMAT,
                Trade = FORMAT,
                Medical = FORMAT,
                SearchPlayer = FORMAT,
                MiniScoreboard = FORMAT,
            },
        },

        Language = rules {
            UseDefaultList = {
                inverseToggleFields = {
                    { 'Language', 'List' },
                },
            },
            List = {
                noLabel = true,
                useFullPage = true,
                paddingBottom = 16,
                arrayDisplayField = 'Name',
                getItemDisplay = Helpers.getLanguageListDisplay,

                children = {
                    Name = {
                        onChange = Helpers.onChangeLanguageName,
                    },
                },
            },

            SelfAddAllowlist = NO_REORDER,
            SelfAddBlocklist = NO_REORDER,

            InterpretationChance = PAD_BOTTOM,

            UnknownLanguageChat = FORMAT,
            UnknownLanguageOverhead = FORMAT,
            UnknownLanguageRadio = FORMAT_PAD_BOTTOM,
        },

        Macros = rules {
            Enable = ENABLE,
        },

        Mentions = rules {
            Enable = ENABLE,

            Range = PAD_TOP,
            ChatFormat = FORMAT,
            OverheadFormat = FORMAT,
        },

        NarrativeStyle = rules {
            Enable = ENABLE,

            OverheadContentFormat = FORMAT,
            ChatContentFormat = FORMAT_PAD_BOTTOM,

            DialogueTagFormat = FORMAT,
            InputFilter = FORMAT,
        },

        Radio = rules {
            ChatFormat = FORMAT,
            OverheadFormat = FORMAT,
            Tags = TAGS,
        },

        ServerMessages = rules {
            ChatFormat = FORMAT,
            Tags = TAGS,
        },

        Streams = rules {
            UseDefaultList = {
                inverseToggleFields = {
                    { 'Streams', 'List' },
                },
            },
            List = {
                noLabel = true,
                useFullPage = true,
                paddingBottom = 16,

                children = {
                    Enable = PAD_BOTTOM,
                    ShortCommand = PAD_BOTTOM,
                    Aliases = PAD_BOTTOM,
                    PerceptionRangeSigned = PAD_BOTTOM,
                    ChatFormat = FORMAT,
                    OverheadFormat = FORMAT_PAD_BOTTOM,
                    UseNarrativeStyle = PAD_BOTTOM,
                    Tags = TAGS,
                },

                createItem = Helpers.createStreamItem,
                getItemDisplay = Helpers.getStreamDisplay,
                onChange = Helpers.onChangeStream,
            },
            GlobalTags = TAGS,
        },

        TypingIndicator = rules {
            Enable = ENABLE,
            Format = FORMAT,
            NameFormat = FORMAT,
        },
    },
}
