---Core client API definition.

require 'Chat/ISChat'
local lib = require 'OmiLibrary/Client'


---@class omichat.api.client : omichat.api.shared
local API = require 'OmiChat/Shared'

local config = API.Configuration
local MetaFormatter = API.MetaFormatter

local utils = API.utils
utils.lib = lib
utils.ui = lib.ui

API.MimicMessage = lib.chat.MimicMessage
API.IconPicker = require 'OmiChat/Component/UI/IconPicker'
API.SuggesterBox = require 'OmiChat/Component/UI/SuggesterBox'
API.Stream = require 'OmiChat/Component/Stream'
API.ChatStream = require 'OmiChat/Component/ChatStream'
API.CommandStream = require 'OmiChat/Component/CommandStream'

API._chatFormatters = {}
API._metadataFormatters = {}
API._typingInfo = {}

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

API._discordStream = API.ChatStream:new {
    name = 'discord',
    chatType = 'general',
    chatFormat = API.Configuration.Discord.ChatFormat,
    defaultColor = API.Configuration.Discord.DefaultColor,
    tags = API.Configuration.Discord.Tags,
    autoTags = { 'IsDiscordStream' },
}

API._radioStream = API.ChatStream:new {
    name = 'radio',
    chatType = 'radio',
    chatFormat = API.Configuration.Radio.ChatFormat,
    defaultColor = API.Configuration.Radio.DefaultColor,
    tags = API.Configuration.Radio.Tags,
    autoTags = { 'IsRadioStream' },
}

API._serverStream = API.ChatStream:new {
    name = 'server',
    chatType = 'server',
    chatFormat = API.Configuration.ServerMessages.ChatFormat,
    defaultColor = API.Configuration.ServerMessages.DefaultColor,
    tags = API.Configuration.ServerMessages.Tags,
    autoTags = { 'IsServerStream' },
}

API._cardCommand = API.CommandStream:new {
    name = 'card',
    command = '/card ',
    formatter = MetaFormatter:new(config.ID_CARD),
    helpTextID = 'UI_ServerOptionDesc_Card',
    autoTags = { 'IsCardCommand' },
    onUse = function(ctx)
        if not API.request.drawCard() then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = getSpecificPlayer(0)
        if not player then
            return false
        end

        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config:getCardItems()) then
            return false
        end

        if not config.Commands.Card.Global and not API.streams.firstChatStreamWithTag('CardCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.streams.firstChatStreamWithTag('CardCommandTarget') then
            utils.log.once('No target stream defined for /card')
            API.chat.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

API._flipCommand = API.CommandStream:new {
    name = 'flip',
    command = '/flip ',
    formatter = MetaFormatter:new(config.ID_FLIP),
    helpTextID = 'UI_OmiChat_HelpText_Flip',
    autoTags = { 'IsFlipCommand' },
    onUse = function(ctx)
        if not API.request.flipCoin() then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = getSpecificPlayer(0)
        if not player then
            return false
        end

        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config:getCoinItems()) then
            return false
        end

        if not config.Commands.Flip.Global and not API.streams.firstChatStreamWithTag('FlipCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.streams.firstChatStreamWithTag('FlipCommandTarget') then
            utils.log.once('No target stream defined for /flip')
            API.chat.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

API._rollCommand = API.CommandStream:new {
    name = 'roll',
    command = '/roll ',
    formatter = MetaFormatter:new(config.ID_ROLL),
    helpTextID = 'UI_ServerOptionDesc_Roll',
    autoTags = { 'IsRollCommand' },
    onUse = function(ctx)
        local command = utils.trim(ctx.text)
        local first = command:split(' ')[1]
        local sides = first and tonumber(first)
        if not sides and #command == 0 then
            sides = 6
        elseif not sides then
            ctx.stream:showHelpText()
            return
        end

        if not API.request.rollDice(sides) then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = getSpecificPlayer(0)
        if not player then
            return false
        end

        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config:getDiceItems()) then
            return false
        end

        if not config.Commands.Roll.Global and not API.streams.firstChatStreamWithTag('RollCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.streams.firstChatStreamWithTag('RollCommandTarget') then
            utils.log.once('No target stream defined for /roll')
            API.chat.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}


return API
