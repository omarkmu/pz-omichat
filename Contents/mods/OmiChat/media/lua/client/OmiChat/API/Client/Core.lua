---Base client API.

require 'Chat/ISChat'
local lib = require 'OmiLibrary/Client'


---@class omichat.api.client : omichat.api.shared
---@field utils omichat.utils.client
---@field private _commandStreams omichat.CommandStream[]
---@field private _emotes table<string, string | omichat.EmoteHandler>
---@field private _chatFormatters table<integer, omichat.MetaFormatter>
---@field private _metadataFormatters table<omichat.FormatterName, omichat.MetaFormatter>
---@field private _iconsToExclude table<string, true>
---@field private _transformers omichat.MessageTransformer[]
---@field private _suggesters omichat.Suggester[]
---@field private _prefsVersion integer
---@field private _prefsFileName string
---@field private _playerPrefs omichat.PlayerPreferences
---@field private _customButtons ISButton[]
---@field private _customSuggesterArgTypes table<string, omichat.SuggestSearchCallback>
---@field private _settingHandlers table<omichat.SettingCategory, omichat.SettingHandlerCallback[]>
---@field private _isTyping boolean
---@field private _typingDisplay string?
---@field private _typingInfo table<string, omichat.TypingInformation>
---@field private _leftmostBtn ISButton?
---@field private _mock omi.chat.Mock?
---@field private _serverStream omichat.ChatStream
---@field private _radioStream omichat.ChatStream
---@field private _discordStream omichat.ChatStream
---@field private _cardCommand omichat.CommandStream
---@field private _flipCommand omichat.CommandStream
---@field private _rollCommand omichat.CommandStream
local API = require 'OmiChat/Shared'

local utils = API.utils
local config = API.Configuration


---@class omichat.utils.client : omichat.utils
---@field ui omi.ui
---@field lib omi.client

API.utils.ui = lib.ui
API.utils.lib = lib

API.IconPicker = require 'OmiChat/Component/IconPicker'
API.SuggesterBox = require 'OmiChat/Component/SuggesterBox'
API.Stream = require 'OmiChat/Component/Stream'
API.Stream.__api = API ---@diagnostic disable-line: invisible
API.ChatStream = require 'OmiChat/Component/ChatStream'
API.CommandStream = require 'OmiChat/Component/CommandStream'
API.MimicMessage = lib.chat.MimicMessage

API._prefsVersion = 2
API._prefsFileName = 'omichat.json'

API._chatFormatters = {}
API._metadataFormatters = {}
API._customButtons = {}
API._customSuggesterArgTypes = {}
API._typingDisplay = nil
API._typingInfo = {}
API._isTyping = false

API._settingHandlers = {
    admin = {},
    basic = {},
    customization = {},
    language = {},
    suggestions = {},
    main = {},
}
API._iconsToExclude = {
    -- shadowed by colors
    thistle = true,
    salmon = true,
    tomato = true,
    orange = true,

    -- doesn't work/often not included by collectAllIcons
    boilersuitblue = true,
    boilersuitred = true,
    glovesleatherbrown = true,
    jumpsuitprisonkhaki = true,
    jumpsuitprisonorange = true,
    jacketgreen = true,
    jacketlongblack = true,
    jacketlongbrown = true,
    jacketvarsity_alpha = true,
    jacketvarsity_ky = true,
    shirtdenimblue = true,
    shirtdenimlightblue = true,
    shirtdenimlightblack = true,
    shirtlumberjackblue = true,
    shirtlumberjackgreen = true,
    shirtlumberjackgrey = true,
    shirtlumberjackred = true,
    shirtlumberjackyellow = true,
    shirtscrubsblue = true,
    shirtscrubsgreen = true,
    shortsathleticblue = true,
    shortsathleticgreen = true,
    shortsathleticred = true,
    shortsathleticyellow = true,
    shortsdenimblack = true,
    shortslongathleticgreen = true,
    tshirtathleticblue = true,
    tshirtathleticred = true,
    tshirtathleticyellow = true,
    tshirtathleticgreen = true,
    trousersscrubsblue = true,
    trousersscrubsgreen = true,

    -- visually identical to other icons
    tz_mayonnaisefullrotten = true,
    tz_mayonnaisehalf = true,
    tz_mayonnaisehalfrotten = true,
    tz_remouladefullrotten = true,
    tz_remouladehalf = true,
    tz_remouladehalfrotten = true,
    glovecompartment = true,
    truckbed = true,
    fishcatfishcooked = true,
    fishcatfishoverdone = true,
    fishcrappiecooked = true,
    fishpanfishcooked = true,
    fishpanfishoverdone = true,
    fishperchcooked = true,
    fishperchoverdone = true,
    fishpikecooked = true,
    fishpikeoverdone = true,
    fishtroutcooked = true,
    fishtroutoverdone = true,
    tvdinnerburnt = true,
    tvdinnerrotten = true,

    -- shows up overhead as text
    composter = true,
    clothingdryer = true,
    clothingwasher = true,
    mailbox = true,
    mannequin = true,
    toolcabinet = true,
}
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
}

API._radioStream = API.ChatStream:new {
    name = 'radio',
    chatType = 'radio',
    chatFormat = API.Configuration.Radio.ChatFormat,
    defaultColor = API.Configuration.Radio.DefaultColor,
    tags = API.Configuration.Radio.Tags,
}

API._serverStream = API.ChatStream:new {
    name = 'server',
    chatType = 'server',
    chatFormat = API.Configuration.ServerMessages.ChatFormat,
    defaultColor = API.Configuration.ServerMessages.DefaultColor,
    tags = API.Configuration.ServerMessages.Tags,
}

API._cardCommand = API.CommandStream:new {
    name = 'card',
    command = '/card ',
    formatter = API.MetaFormatter:new(config.ID_CARD),
    helpTextID = 'UI_ServerOptionDesc_Card',
    autoTags = { 'IsCardCommand' },
    onUse = function(ctx)
        if not API.requestDrawCard() then
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

        if not config.Commands.Card.Global and not API.getFirstChatStreamWithTag('CardCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.getFirstChatStreamWithTag('CardCommandTarget') then
            utils.log.once('No target stream defined for /card')
            API.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

API._flipCommand = API.CommandStream:new {
    name = 'flip',
    command = '/flip ',
    formatter = API.MetaFormatter:new(config.ID_FLIP),
    helpTextID = 'UI_OmiChat_HelpText_Flip',
    autoTags = { 'IsFlipCommand' },
    onUse = function(ctx)
        if not API.requestFlipCoin() then
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

        if not config.Commands.Flip.Global and not API.getFirstChatStreamWithTag('FlipCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.getFirstChatStreamWithTag('FlipCommandTarget') then
            utils.log.once('No target stream defined for /flip')
            API.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}

API._rollCommand = API.CommandStream:new {
    name = 'roll',
    command = '/roll ',
    formatter = API.MetaFormatter:new(config.ID_ROLL),
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

        if not API.requestRollDice(sides) then
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

        if not config.Commands.Roll.Global and not API.getFirstChatStreamWithTag('RollCommandTarget') then
            return false
        end

        return true
    end,
    onUseDisabled = function(stream)
        if not API.getFirstChatStreamWithTag('RollCommandTarget') then
            utils.log.once('No target stream defined for /roll')
            API.addInfoMessage('Unknown command ' .. stream:getCommand():sub(2))
        else
            stream:showHelpText()
        end
    end,
}


---Called when configuration is saved to a file.
---@protected
function API._onConfigurationSave()
    if API.updateState then
        API.updateState(true)
    end
end

---Event handler that runs when a player is created.
---@param playerNum integer
---@param player IsoPlayer
---@protected
function API._onCreatePlayer(playerNum, player)
    if playerNum == 0 then
        API.updateInfoText(player)
        API.refreshLanguageInfo(player:getUsername())
    end
end

---Event handler that runs on game start.
---@protected
function API._onGameStart()
    if getDebug() and not isClient() then
        -- if we're running in singleplayer & debug, mock the chat
        local mock = lib.chat.Mock:new()
        mock:start()

        API._mock = mock

        API.raw = {
            say = processSayMessage,
            shout = processShoutMessage,
            whisper = proceedPM,
            general = processGeneralMessage,
            safehouse = processSafehouseMessage,
            faction = proceedFactionMessage,
            admin = processAdminChatMessage,
        }
    end

    API.updateState(true)
end

---Event handler that runs on player death.
---@param player IsoPlayer
---@protected
function API._onPlayerDeath(player)
    if player ~= getSpecificPlayer(0) then
        return
    end

    -- reset nickname, icon, and languages
    API.reportPlayerDeath()

    local instance = ISChat.instance
    if instance then
        instance:unfocus()
        instance:close()
    end
end

---Event handler for retrieving global mod data.
---@param key string
---@param newData omichat.ModData
---@protected
function API._onReceiveGlobalModData(key, newData)
    if key ~= API._modDataKey or type(newData) ~= 'table' then
        return
    end

    local modData = API.getModData()
    for k in pairs(newData) do
        modData[k] = newData[k]
    end
end

---Called when configuration is saved from the editor form.
---@param args omi.forms.Args.Callback.Save
---@protected
function API._onSaveConfiguration(args)
    API.Configuration:load(args.values)
    API.updateConfiguration()

    -- save to file if testing in singleplayer
    if getDebug() and not isClient() then
        API.Configuration:saveFile()
    end
end

---Event handler that runs on tick until the player has loaded.
---@protected
function API._onTickTemporary()
    if not getSpecificPlayer(0) then
        return
    end

    Events.OnTick.Remove(API._onTickTemporary)
    API.reportPlayerJoined()
end


return API
