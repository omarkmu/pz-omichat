---Light RP preset.
---@namespace omichat

local Preset = require 'OmiChat/Component/Configuration/Preset'

return Preset:new {
    name = 'LightRP',
    values = {
        General = Preset.general {
            Name = 'LightRP',
            PMParentheses = 1,
            DefaultNameModeForChatType = { admin = 'username' },
            VolumeIndicators = {},
        },
        Buffs = Preset.buffs {
            Enable = false,
        },
        Callouts = Preset.callouts {
            Range = 60,
        },
        Commands = Preset.commands(),
        Compatibility = Preset.compatibility(),
        Customization = {
            AllowCustomShouts = true,
            EnableNameColors = true,
            EnableCharacterCustomization = false,
            CleanEffects = { Body = true, Clothing = true },
        },
        Discord = Preset.discord {
            Tags = {
                'UseAuthorUsername',
            },
        },
        EchoMessages = Preset.echo {
            Enable = false,
        },
        Format = Preset.format(),
        Language = Preset.languages(),
        Macros = Preset.macros(),
        Mentions = Preset.mentions(),
        NarrativeStyle = Preset.narrative {
            Enable = false,
        },
        Radio = Preset.radio(),
        ServerMessages = Preset.server {
            Tags = {
                'NoTimestamp',
                'NoTagColon',
            },
        },
        TypingIndicator = Preset.typing(),
        ZombieAttraction = Preset.zombies(),

        Streams = {
            UseDefaultList = false,
            GlobalTags = {},
            List = {
                {
                    Stream = 'admin',
                    Enable = true,
                },
                {
                    Stream = 'say',
                    Enable = true,
                    Range = 30,
                    DefaultColor = { r = 210, g = 210, b = 210 },
                },
                {
                    Stream = 'yell',
                    Enable = true,
                    Range = 60,
                },
                {
                    Stream = 'low',
                    Enable = true,
                    Range = 5,
                    PerceptionRange = 10,
                    PerceptionRangeSigned = 12,
                    DefaultColor = { r = 85, g = 48, b = 139 },
                },
                {
                    Stream = 'whisper',
                    Enable = true,
                    Range = 2,
                    PerceptionRange = 8,
                    PerceptionRangeSigned = 10,
                    DefaultColor = { r = 85, g = 48, b = 139 },
                },
                {
                    Stream = 'me',
                    Enable = true,
                    Range = 30,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'AutoPunctuateEmbeddedQuotes',
                        'AutoCapitalizeEmbeddedQuotes',
                        'AutoCapitalizeNonInitialSegments',
                        'Action',
                        'ActionColorTarget',
                        'CardCommandTarget',
                        'FlipCommandTarget',
                        'RollCommandTarget',
                        'UseNameColor',
                    },
                },
                {
                    Stream = 'meloud',
                    Enable = true,
                    Range = 60,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'AutoPunctuateEmbeddedQuotes',
                        'AutoCapitalizeEmbeddedQuotes',
                        'AutoCapitalizeNonInitialSegments',
                        'Action',
                        'Loud',
                        'UseNameColor',
                    },
                },
                {
                    Stream = 'mequiet',
                    Enable = true,
                    Range = 5,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'AutoPunctuateEmbeddedQuotes',
                        'AutoCapitalizeEmbeddedQuotes',
                        'AutoCapitalizeNonInitialSegments',
                        'Action',
                        'Quiet',
                        'UseNameColor',
                    },
                },
                {
                    Stream = 'mewhisper',
                    Enable = true,
                    Range = 2,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'AutoPunctuateEmbeddedQuotes',
                        'AutoCapitalizeEmbeddedQuotes',
                        'AutoCapitalizeNonInitialSegments',
                        'Action',
                        'Whisper',
                        'UseNameColor',
                    },
                },
                {
                    Stream = 'do',
                    Enable = true,
                    Range = 30,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoCapitalizeNarrative',
                        'AutoCapitalizeChat',
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'NoName',
                        'Action',
                    },
                },
                {
                    Stream = 'doloud',
                    Enable = true,
                    Range = 60,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoCapitalizeNarrative',
                        'AutoCapitalizeChat',
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'NoName',
                        'Action',
                        'Loud',
                    },
                },
                {
                    Stream = 'doquiet',
                    Enable = true,
                    Range = 5,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoCapitalizeNarrative',
                        'AutoCapitalizeChat',
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'NoName',
                        'Action',
                        'Quiet',
                    },
                },
                {
                    Stream = 'dowhisper',
                    Enable = true,
                    Range = 2,
                    DefaultColor = { r = 130, g = 130, b = 130 },
                    Tags = {
                        'AutoCapitalizeNarrative',
                        'AutoCapitalizeChat',
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'NoName',
                        'Action',
                        'Whisper',
                    },
                },
                {
                    Stream = 'ooc',
                    Enable = true,
                    Range = 30,
                    Tags = {
                        'OOC',
                        'NoNameOverhead',
                    },
                },
                {
                    Stream = 'private',
                    Enable = true,
                    Tags = {
                        'UseNameColor',
                    },
                },
                {
                    Stream = 'faction',
                    Enable = true,
                    Tags = {
                        'AutoCapitalizeNarrative',
                        'AutoPunctuateNarrative',
                    },
                },
                {
                    Stream = 'safehouse',
                    Enable = true,
                    Tags = {
                        'AutoCapitalizeNarrative',
                        'AutoPunctuateNarrative',
                    },
                },
                {
                    Stream = 'general',
                    Enable = true,
                    Tags = {
                        'IncludeMentionAtSignChat',
                    },
                },
            },
        },
    },
}
