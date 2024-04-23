---Base client API.

require 'Chat/ISChat'


---@class omichat.api.client : omichat.api.shared
---@field private _commandStreams omichat.CommandStream[]
---@field private _emotes table<string, string | omichat.EmoteHandler>
---@field private _formatters table<string, omichat.MetaFormatter>
---@field private _iconsToExclude table<string, true>
---@field private _transformers omichat.MessageTransformer[]
---@field private _suggesters omichat.Suggester[]
---@field private _prefsVersion integer
---@field private _prefsFileName string
---@field private _playerPrefs omichat.PlayerPreferences
---@field private _customChatStreams table<string, omichat.ChatStream>
---@field private _customButtons ISButton[]
---@field private _customSuggesterArgTypes table<string, omichat.SuggestSearchCallback>
---@field private _settingHandlers table<omichat.SettingCategory, omichat.SettingHandlerCallback[]>
---@field private _isTyping boolean
---@field private _typingDisplay string?
---@field private _typingInfo table<string, omichat.TypingInformation>
---@field private _leftmostBtn ISButton?
local OmiChat = require 'OmiChatShared'

OmiChat.ColorModal = require 'OmiChat/Component/ColorModal'
OmiChat.ValidatedColorEntry = require 'OmiChat/Component/ValidatedColorEntry'
OmiChat.ValidatedTextEntry = require 'OmiChat/Component/ValidatedTextEntry'
OmiChat.IconPicker = require 'OmiChat/Component/IconPicker'
OmiChat.SuggesterBox = require 'OmiChat/Component/SuggesterBox'
OmiChat.StreamInfo = require 'OmiChat/Component/StreamInfo'
OmiChat.TextPanel = require 'OmiChat/Component/TextPanel'

OmiChat._prefsVersion = 2
OmiChat._prefsFileName = 'omichat.json'

OmiChat._formatters = {}
OmiChat._customButtons = {}
OmiChat._customSuggesterArgTypes = {}
OmiChat._typingDisplay = nil
OmiChat._typingInfo = {}
OmiChat._isTyping = false

OmiChat._settingHandlers = {
    admin = {},
    basic = {},
    chat_customization = {},
    character_customization = {},
    language = {},
    suggestions = {},
    main = {},
}
OmiChat._iconsToExclude = {
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
OmiChat._emotes = {
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


---Event handler that runs when a player is created.
---@param playerNum integer
---@param player IsoPlayer
---@protected
function OmiChat._onCreatePlayer(playerNum, player)
    if playerNum == 0 then
        OmiChat.updateInfoText(player)
        OmiChat.refreshLanguageInfo(player:getUsername())
    end
end

---Event handler that runs on game start.
---@protected
function OmiChat._onGameStart()
    OmiChat.updateState(true)
end

---Event handler that runs on player death.
---@param player IsoPlayer
---@protected
function OmiChat._onPlayerDeath(player)
    if player ~= getSpecificPlayer(0) then
        return
    end

    -- reset nickname, icon, and languages
    OmiChat.reportPlayerDeath()

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
function OmiChat._onReceiveGlobalModData(key, newData)
    if key ~= OmiChat._modDataKey or type(newData) ~= 'table' then
        return
    end

    local modData = OmiChat.getModData()
    for k in pairs(newData) do
        modData[k] = newData[k]
    end
end


return OmiChat
