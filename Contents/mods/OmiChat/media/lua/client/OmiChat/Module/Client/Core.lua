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
---@type table<string, string | EmoteHandler>
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

--#endregion

--#region Streams

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

---Command stream for the `/card` command.
---@private
API._cardCommand = API.CommandStream:new {
    name = 'card',
    command = '/card ',
    formatter = MetaFormatter:new(config.ID_CARD),
    helpTextID = 'UI_ServerOptionDesc_Card',
    autoTags = { 'IsCardCommand' },
    onUse = function(ctx)
        if API.hooks.has.cardCommand and API.hooks.cardCommand(ctx) then
            return
        end

        if not API.request.drawCard() then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = getSpecificPlayer(0)
        if not player then
            return false
        end

        if API.hooks.has.cardCommandEnabled then
            local result = API.hooks.cardCommandEnabled()
            if result ~= nil then
                return result
            end
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

---Command stream for the `/flip` command.
---@private
API._flipCommand = API.CommandStream:new {
    name = 'flip',
    command = '/flip ',
    formatter = MetaFormatter:new(config.ID_FLIP),
    helpTextID = 'UI_OmiChat_HelpText_Flip',
    autoTags = { 'IsFlipCommand' },
    onUse = function(ctx)
        if API.hooks.has.flipCommand and API.hooks.flipCommand(ctx) then
            return
        end

        if not API.request.flipCoin() then
            ctx.stream:showHelpText()
        end
    end,
    isEnabled = function()
        local player = getSpecificPlayer(0)
        if not player then
            return false
        end

        if API.hooks.has.flipCommandEnabled then
            local result = API.hooks.flipCommandEnabled()
            if result ~= nil then
                return result
            end
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

---Command stream for the `/roll` command.
---@private
API._rollCommand = API.CommandStream:new {
    name = 'roll',
    command = '/roll ',
    formatter = MetaFormatter:new(config.ID_ROLL),
    helpTextID = 'UI_ServerOptionDesc_Roll',
    autoTags = { 'IsRollCommand' },
    onUse = function(ctx)
        if API.hooks.has.rollCommand and API.hooks.rollCommand(ctx) then
            return
        end

        local command = utils.trim(ctx.text)
        local first = command:split(' ')[1]
        local sides = utils.tointeger(first)
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

        if API.hooks.has.rollCommandEnabled then
            local result = API.hooks.rollCommandEnabled()
            if result ~= nil then
                return result
            end
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

--#endregion


return API
