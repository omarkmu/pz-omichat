---@namespace omichat
---API functionality exclusive to the client.
---@class(partial) api.client : api.shared
---@field utils utils.client
local API = require 'OmiChat/Shared'

require 'Chat/ISChat'
local lib = require 'OmiLibrary/Client'


local config = API.Configuration
local MetaFormatter = API.MetaFormatter


API.MimicMessage = lib.chat.MimicMessage
API.Stream = require 'OmiChat/Component/Stream'
API.ChatStream = require 'OmiChat/Component/ChatStream'
API.CommandStream = require 'OmiChat/Component/CommandStream'

--#region Static Fields

---Contains various utility functions.
---@class utils.client : utils
local utils = API.utils

---Reference to the library module.
utils.lib = lib

---Contains UI utilities.
utils.ui = lib.ui

---Associates formatter IDs to MetaFormatters for chat streams.
---@type table<integer, MetaFormatter>
---@private
API._chatFormatters = {}

---Associates formatter names to formatters for metadata.
---@type table<FormatterName, MetaFormatter>
---@private
API._metadataFormatters = {}

---Associates usernames to information about typing status.
---@type table<string, TypingInformation>
---@private
API._typingInfo = {}

---Associates emote names to emotes or handler functions.
---@type table<string, string | fun(player: IsoPlayer, emote: string)>
---@private
API._emotes = {
    yes = 'yes',
    no = 'no',
    ok = 'signalok',
    hi = 'wavehi',
    hi2 = 'wavehi02',
    bye = 'wavebye',
    salute = 'saluteformal',
    salute2 = 'salutecasual',
    ceasefire = 'ceasefire',
    -- 'clap' emote only works while sneaking; Bob_EmoteClap is missing
    clap = 'clap02',
    comehere = 'comehere',
    comehere2 = 'comehere02',
    follow = 'followme',
    followbehind = 'followbehind',
    followme = 'followme',
    thumbsup = 'thumbsup',
    thumbsdown = 'thumbsdown',
    thanks = 'thankyou',
    insult = 'insult',
    stop = 'stop',
    stop2 = 'stop02',
    surrender = 'surrender',
    shrug = 'shrug',
    shout = 'shout',
    undecided = 'undecided',
    moveout = 'moveout',
    freeze = 'freeze',
    comefront = 'comefront',
    fire = 'signalfire',
}

---Chat stream used for messages from Discord.
---@private
API._discordStream = API.ChatStream:new {
    name = 'discord',
    chatType = 'general',
    chatFormat = config.Discord.ChatFormat,
    defaultColor = config.Discord.DefaultColor,
    tags = config.Discord.Tags,
    autoTags = { 'IsDiscordStream' },
}

---Chat stream used for radio messages.
---@private
API._radioStream = API.ChatStream:new {
    name = 'radio',
    chatType = 'radio',
    chatFormat = config.Radio.ChatFormat,
    defaultColor = config.Radio.DefaultColor,
    tags = config.Radio.Tags,
    autoTags = { 'IsRadioStream' },
}

---Chat stream used for server messages.
---@private
API._serverStream = API.ChatStream:new {
    name = 'server',
    chatType = 'server',
    chatFormat = config.ServerMessages.ChatFormat,
    defaultColor = config.ServerMessages.DefaultColor,
    tags = config.ServerMessages.Tags,
    autoTags = { 'IsServerStream' },
}

--#endregion


return API
