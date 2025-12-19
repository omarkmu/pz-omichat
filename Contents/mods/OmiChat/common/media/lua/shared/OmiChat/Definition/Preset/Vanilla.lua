---Vanilla preset.
---@namespace omichat

local Preset = require 'OmiChat/Component/Configuration/Preset'

return Preset:new {
    name = 'Vanilla',
    values = {
        General = Preset.general {
            Name = 'Vanilla',
            CaseInsensitiveChatStreams = false,
            Variables = {
                'DefaultNameMode:username',
            },
        },
        Buffs = Preset.buffs {
            Enable = false,
        },
        Callouts = Preset.callouts {
            Range = 60,
        },
        Commands = Preset.commands {
            NameMode = 'Disable',
            EnableStatus = false,
            GlobalCommands = true,
        },
        Compatibility = Preset.compatibility(false),
        Customization = Preset.customization {
            Enable = false,
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
        Language = Preset.languages {
            UseDefaultList = false,
        },
        Macros = Preset.macros {
            Enable = false,
        },
        Mentions = Preset.mentions {
            Enable = false,
        },
        NarrativeStyle = Preset.narrative {
            Enable = false,
        },
        Radio = Preset.radio {
            Tags = {
                'UseAuthorUsername',
            },
        },
        ServerMessages = Preset.server(),
        TypingIndicator = Preset.typing {
            Enable = false,
        },
        ZombieAttraction = Preset.zombies(),

        Streams = {
            UseDefaultList = false,
            GlobalTags = {
                'BracketedNames',
                'NoPrefixSpaceChat',
                'NoIcon',
                'IncludeMentionAtSign',
            },
            List = {
                {
                    Stream = 'admin',
                    Enable = true,
                    DefaultColor = { r = 255, g = 255, b = 255 },
                },
                {
                    Stream = 'say',
                    Enable = true,
                    DefaultColor = { r = 255, g = 255, b = 255 },
                    Range = 30,
                    Tags = {
                        'EchoTarget',
                    },
                },
                {
                    Stream = 'yell',
                    Enable = true,
                    Range = 60,
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
                    Range = 5,
                },
                {
                    Stream = 'whisper',
                    Enable = false,
                    Range = 2,
                },
                {
                    Stream = 'me',
                    Enable = false,
                    Range = 30,
                    Tags = {
                        'AutoPunctuateChat',
                        'AutoColorQuotes',
                        'Action',
                        'IncludeName',
                        'ActionColorTarget',
                        'CardCommandTarget',
                        'FlipCommandTarget',
                        'RollCommandTarget',
                    },
                },
                {
                    Stream = 'meloud',
                    Enable = false,
                    Range = 60,
                },
                {
                    Stream = 'mequiet',
                    Enable = false,
                    Range = 5,
                },
                {
                    Stream = 'mewhisper',
                    Enable = false,
                    Range = 2,
                },
                {
                    Stream = 'do',
                    Enable = false,
                    Range = 30,
                },
                {
                    Stream = 'doloud',
                    Enable = false,
                    Range = 60,
                },
                {
                    Stream = 'doquiet',
                    Enable = false,
                    Range = 5,
                },
                {
                    Stream = 'dowhisper',
                    Enable = false,
                    Range = 2,
                },
                {
                    Stream = 'ooc',
                    Enable = false,
                    Range = 30,
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
