---API functionality exclusive to the client.
---@namespace omichat

---@class(partial) api.client : api.shared
---@field utils utils.client Contains various utility functions.
local API = require 'OmiChat/Shared'
local lib = require 'OmiLibrary/Client'
local ChatEmote = require 'OmiChat/Component/ChatEmote'
local config = API.Configuration

require 'Chat/ISChat'


---Dummy chat message object.
API.MimicMessage = lib.chat.MimicMessage

---Base stream type.
API.Stream = require 'OmiChat/Component/Stream'

---Stream for sending chat messages.
API.ChatStream = require 'OmiChat/Component/ChatStream'

---Stream for sending commands in chat.
API.CommandStream = require 'OmiChat/Component/CommandStream'

---Handler for emote macros.
API.ChatEmote = ChatEmote

--#region Static Fields

---@class utils.client : utils
local utils = API.utils

---Reference to the library module.
utils.lib = lib

---Contains UI utilities.
utils.ui = lib.ui

---Associates usernames to information about typing status.
---@type table<string, TypingInformation>
---@private
API._typingInfo = {}

---Associates emote names to emote handlers.
---@type table<string, ChatEmote>
---@private
API._emotes = {
    yes = ChatEmote:new { emote = 'yes' },
    no = ChatEmote:new { emote = 'no' },
    ok = ChatEmote:new { emote = 'signalok' },
    hi = ChatEmote:new { emote = 'wavehi' },
    hi2 = ChatEmote:new { emote = 'wavehi02' },
    bye = ChatEmote:new { emote = 'wavebye' },
    salute = ChatEmote:new { emote = 'saluteformal' },
    salute2 = ChatEmote:new { emote = 'salutecasual' },
    ceasefire = ChatEmote:new { emote = 'ceasefire' },
    clap = ChatEmote:new { emote = 'clap02' }, -- 'clap' emote only works while sneaking; Bob_EmoteClap is missing
    comehere = ChatEmote:new { emote = 'comehere' },
    comehere2 = ChatEmote:new { emote = 'comehere02' },
    follow = ChatEmote:new { emote = 'followme' },
    followbehind = ChatEmote:new { emote = 'followbehind' },
    followme = ChatEmote:new { emote = 'followme' },
    thumbsup = ChatEmote:new { emote = 'thumbsup' },
    thumbsdown = ChatEmote:new { emote = 'thumbsdown' },
    thanks = ChatEmote:new { emote = 'thankyou' },
    insult = ChatEmote:new { emote = 'insult' },
    stop = ChatEmote:new { emote = 'stop' },
    stop2 = ChatEmote:new { emote = 'stop02' },
    surrender = ChatEmote:new { emote = 'surrender' },
    shrug = ChatEmote:new { emote = 'shrug' },
    shout = ChatEmote:new { emote = 'shout' },
    undecided = ChatEmote:new { emote = 'undecided' },
    moveout = ChatEmote:new { emote = 'moveout' },
    freeze = ChatEmote:new { emote = 'freeze' },
    comefront = ChatEmote:new { emote = 'comefront' },
    fire = ChatEmote:new { emote = 'signalfire' },
}

---List of emote names.
---@type string[]
---@private
API._emoteList = utils.keys(API._emotes)
table.sort(API._emoteList)

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
    overheadFormat = config.Radio.OverheadFormat,
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
