---Vanilla preset.

local Preset = require 'OmiChat/Component/Configuration/Preset'


return Preset:new {
    name = 'Vanilla',
    values = {
        General = Preset.general {
            Name = 'Vanilla',
            CaseInsensitiveChatStreams = false,
        },
        Buffs = Preset.buffs(),
        Callouts = Preset.callouts(),
        Commands = Preset.commands {
            NameMode = 'Disable',
            EnableStatus = false,
            GlobalCommands = true,
        },
        Compatibility = Preset.compatibility(false),
        Customization = Preset.customization {
            Enable = false,
        },
        Discord = Preset.discord(),
        EchoMessages = Preset.echo(),
        Format = Preset.format(),
        Language = Preset.languages {
            UseDefaultList = false,
        },
        Macros = Preset.macros {
            AllowEmotes = false,
        },
        NarrativeStyle = Preset.narrative {
            Enable = false,
        },
        Radio = Preset.radio {
            Tags = {
                'UseAuthorUsername',
            },
        },
        ServerMessages = Preset.server {
            Tags = {
                'NoTimestamp',
            },
        },
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
            },
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
    },
}
