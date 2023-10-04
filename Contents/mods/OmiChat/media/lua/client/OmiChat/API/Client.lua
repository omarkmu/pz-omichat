---Base client API.

require 'Chat/ISChat'

local utils = require 'OmiChat/util'
local vanillaCommands = require 'OmiChat/VanillaCommandList'
local customStreamData = require 'OmiChat/CustomStreamData'

local concat = table.concat
local pairs = pairs
local ipairs = ipairs
local getText = getText

---@class omichat.ISChat
local ISChat = ISChat


---@class omichat.api.client : omichat.api.shared
---@field private _commandStreams omichat.CommandStream[]
---@field private _emotes table<string, string | omichat.EmoteGetter>
---@field private _formatters table<string, omichat.MetaFormatter>
---@field private _iconsToExclude table<string, true>
---@field private _transformers omichat.MessageTransformer[]
---@field private _iniVersion integer
---@field private _iniName string
---@field private _playerPrefs omichat.PlayerPreferences
local OmiChat = require 'OmiChatShared'
local Option = OmiChat.Option

OmiChat.ColorModal = require 'OmiChat/ColorModal'
OmiChat.IconPicker = require 'OmiChat/IconPicker'

OmiChat._iniVersion = 1
OmiChat._iniName = 'omichat.ini'

---@type table<string, true>
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

---@type table<string, omichat.MetaFormatter>
OmiChat._formatters = {}

---@type omichat.CommandStream[]
OmiChat._commandStreams = {
    {
        name = 'name',
        command = '/name ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_name_no_reset',
            isEnabled = function() return Option.EnableSetName end,
            onUse = function(self, command)
                local _, feedback = OmiChat.setNickname(command)
                if feedback then
                    OmiChat.showInfoMessage(feedback)
                end
            end,
            onHelp = function()
                local msg = 'UI_OmiChat_helptext_name'
                if Option.EnableChatNameAsCharacterName then
                    msg = 'UI_OmiChat_helptext_name_no_reset'
                end

                OmiChat.showInfoMessage(getText(msg))
            end,
        },
    },
    {
        name = 'emotes',
        command = '/emotes ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_emotes',
            isEnabled = function() return Option.EnableEmotes end,
            onUse = function(self) self.omichat.onHelp() end,
            onHelp = function()
                -- collect currently available emotes
                local emotes = {}
                for k, v in pairs(OmiChat._emotes) do
                    if type(v) ~= 'function' or v(k) then
                        emotes[#emotes+1] = k
                    end
                end

                if #emotes == 0 then
                    -- no emotes; ignore
                    return
                end

                table.sort(emotes)

                local parts = {
                    getText('UI_OmiChat_available_emotes'),
                }

                for _, emote in ipairs(emotes) do
                    parts[#parts+1] = ' <LINE> * .'
                    parts[#parts+1] = emote
                end

                OmiChat.showInfoMessage(concat(parts))
            end,
        },
    },
    {
        -- reimplementing this because the vanilla clear doesn't actually clear the chatbox
        name = 'clear',
        command = '/clear ',
        omichat = {
            isCommand = true,
            isEnabled = function() return isAdmin() or isCoopHost() end,
            onUse = function()
                OmiChat.clearMessages()
                OmiChat.showInfoMessage(getText('UI_OmiChat_clear_message'))
            end,
        }
    },
    {
        name = 'help',
        command = '/help ',
        omichat = {
            isCommand = true,
            checkHasAccess = function(access, accessLevel)
                if access >= 32 then
                    if accessLevel == 'admin' then
                        return true
                    end

                    access = access - 32
                end

                if access >= 16 then
                    if accessLevel == 'moderator' then
                        return true
                    end

                    access = access - 16
                end

                if access >= 8 then
                    if accessLevel == 'overseer' then
                        return true
                    end

                    access = access - 8
                end

                if access >= 4 then
                    if accessLevel == 'gm' then
                        return true
                    end

                    access = access - 4
                end

                if access >= 2 then
                    if accessLevel == 'observer' then
                        return true
                    end

                    access = access - 2
                end

                return access == 1
            end,
            onUse = function(self, command)
                local accessLevel
                if isCoopHost() then
                    accessLevel = 'admin'
                else
                    local player = getSpecificPlayer(0)
                    accessLevel = player and player:getAccessLevel()
                end

                if not accessLevel then
                    -- something went wrong, defer to default help command
                    SendCommandToServer('/help ' .. command)
                    return
                end

                accessLevel = accessLevel:lower()
                command = utils.trim(command)

                -- specific command help
                if #command > 0 then
                    ---@type omichat.CommandStream?
                    local helpStream

                    for _, stream in pairs(OmiChat._commandStreams) do
                        if stream.name == command then
                            local isEnabled = stream.omichat and stream.omichat.isEnabled
                            if stream.omichat and (not isEnabled or isEnabled(stream)) then
                                if stream.omichat.onHelp or stream.omichat.helpText then
                                    helpStream = stream
                                end
                            end

                            break
                        end
                    end

                    if helpStream and helpStream.omichat.onHelp then
                        helpStream.omichat.onHelp(helpStream)
                    elseif helpStream and helpStream.omichat.helpText then
                        OmiChat.showInfoMessage(getText(helpStream.omichat.helpText))
                    else
                        -- defer to default help command
                        SendCommandToServer('/help ' .. command)
                    end

                    return
                end

                local seen = {}
                local commands = {} ---@type omichat.VanillaCommandEntry[]

                for _, stream in pairs(OmiChat._commandStreams) do
                    if stream.omichat then
                        local isEnabled = stream.omichat.isEnabled
                        local helpText = stream.omichat.helpText
                        if not seen[stream.name] and helpText and (not isEnabled or isEnabled(stream)) then
                            seen[stream.name] = true
                            commands[#commands+1] = { name = stream.name, helpText = helpText, access = 0 }
                        end
                    end
                end

                for _, info in ipairs(vanillaCommands) do
                    if info.name and info.helpText and not seen[info.name] then
                        if not info.access or self.omichat.checkHasAccess(info.access, accessLevel) then
                            commands[#commands+1] = info
                        end
                    end
                end

                table.sort(commands, function(a, b) return a.name < b.name end)

                local result = { getText('UI_OmiChat_list_of_commands') }
                for _, cmd in ipairs(commands) do
                    result[#result+1] = ' <LINE> * '
                    result[#result+1] = cmd.name
                    result[#result+1] = ' : '

                    if cmd.helpTextArgs then
                        result[#result+1] = getText(cmd.helpText, unpack(cmd.helpTextArgs))
                    else
                        result[#result+1] = getText(cmd.helpText)
                    end
                end

                OmiChat.showInfoMessage(concat(result))
            end,
        },
    },
}

---@type omichat.MessageTransformer[]
OmiChat._transformers = {
    {
        name = 'radio-chat',
        priority = 10,
        transform = function(self, info)
            if info.chatType ~= 'radio' then
                return
            end

            local _, msgStart, freq = info.rawText:find('Radio%s*%((%d+%.%d+)[^%)]+%)%s*:')
            if not msgStart then
                return
            end

            info.context.ocIsRadio = true
            info.content = info.rawText:sub(msgStart + 1)
            info.format = Option.ChatFormatRadio
            info.substitutions.frequency = freq
        end
    },
    {
        name = 'decode-stream',
        priority = 8,
        transform = function(self, info)
            local isRadio = info.context.ocIsRadio
            for name, streamData in pairs(customStreamData.table) do
                local formatter = OmiChat.getFormatter(name)
                local isValidStream = OmiChat.isCustomStreamEnabled(name) and streamData.chatTypes[info.chatType]
                local isMatch = formatter:isMatch(info.content or info.rawText)

                if isMatch and isRadio then
                    if streamData.showOnRadio then
                        info.content = formatter:read(info.content)
                    else
                        info.formatOptions.showInChat = false
                    end
                elseif isValidStream and isMatch then
                    info.content = formatter:read(info.rawText)
                    info.format = Option[streamData.chatFormatOpt]
                    info.context.ocCustomStream = name
                    info.substitutions.stream = name

                    info.formatOptions.color = OmiChat.getColorTable(name)
                    info.formatOptions.useChatColor = false

                    if streamData.stripColors then
                        info.formatOptions.stripColors = true
                    end

                    if streamData.titleID then
                        info.titleID = streamData.titleID
                    end

                    info.message:setShouldAttractZombies(streamData.attractZombies)

                    if Option[streamData.overheadFormatOpt] == '' then
                        info.message:setOverHeadSpeech(false)
                    end

                    break
                end
            end
        end,
    },
    {
        name = 'set-range',
        priority = 6,
        transform = function(self, info)
            local range
            local chatRange
            local streamData = info.context.ocCustomStream and customStreamData.table[info.context.ocCustomStream]
            if streamData then
                range = Option[streamData.rangeOpt]
                chatRange = Option:getDefault(streamData.defaultRangeOpt or 'RangeSay')
            elseif info.chatType == 'say' then
                range = Option.RangeSay
                chatRange = Option:getDefault('RangeSay')
            elseif info.chatType == 'shout' then
                range = Option.RangeYell
                chatRange = Option:getDefault('RangeYell')
            else
                return
            end

            -- default ranges are existing chat ranges, so this avoids unnecessary work
            if range == chatRange then
                return
            end

            local authorPlayer = getPlayerFromUsername(info.author)
            local localPlayer = getSpecificPlayer(0)
            if not authorPlayer or not localPlayer or authorPlayer == localPlayer then
                return
            end

            -- calculating distance using the distance formula like ChatUtility
            -- assuming players are synced it works equivalently
            local xDiff = authorPlayer:getX() - localPlayer:getX()
            local yDiff = authorPlayer:getY() - localPlayer:getY()

            if math.sqrt(xDiff*xDiff + yDiff*yDiff) > range then
                info.message:setOverHeadSpeech(false)
                info.formatOptions.showInChat = false
                info.context.ocOutOfRange = true
                return true
            end
        end,
    },
    {
        name = 'private-chat',
        priority = 4,
        transform = function(self, info)
            if info.chatType ~= 'whisper' then
                return
            end

            local bracketStart, msgStart, other = info.rawText:find('%[to ([^%]]+)%]:')
            if other and bracketStart == info.rawText:find('%[') then
                info.content = info.rawText:sub(msgStart + 1)
                info.format = Option.ChatFormatOutgoingPrivate
                info.substitutions.recipient = other
                info.substitutions.recipientName = OmiChat.getNameInChat(other, 'whisper') or other
            else
                -- defer to basic chat format handler
                info.context.ocIsIncomingPM = true
            end

            info.formatOptions.color = OmiChat.getColorTable('private')
            info.formatOptions.useChatColor = false
        end,
    },
    {
        name = 'server-chat',
        priority = 2,
        transform = function(self, info)
            if info.chatType ~= 'server' then
                return
            end

            if ISChat.instance.showTitle then
                -- not great, but can't access the real isShowTitle chat setting to do this in a safer way
                local patt = concat { '%[', getText('UI_chat_server_chat_title_id'), '%]:' }
                local _, serverMsgStart = info.rawText:find(patt)
                if serverMsgStart then
                    info.content = info.rawText:sub(serverMsgStart + 1)
                end
            else
                -- server messages can be only their text, if not set to show title
                -- still have to extract text due to the existing rich text

                local _, sizeEnd = info.rawText:find('<SIZE:')
                local start = sizeEnd ~= -1 and info.rawText:find('>', sizeEnd)
                if start then
                    info.content = info.rawText:sub(start + 1)
                end
            end

            -- mirroring ServerChat settings
            info.formatOptions.showTimestamp = false
            info.format = Option.ChatFormatServer
        end,
    },
    {
        name = 'basic-chats',
        priority = 2,
        basicChatFormats = {
            say = 'ChatFormatSay',
            shout = 'ChatFormatYell',
            general = 'ChatFormatGeneral',
            admin = 'ChatFormatAdmin',
            faction = 'ChatFormatFaction',
            safehouse = 'ChatFormatSafehouse',
        },
        transform = function(self, info)
            if not self.basicChatFormats[info.chatType] and not info.context.ocIsIncomingPM then
                return
            end

            if not info.content then
                -- grab text after the author
                local authorPattern = concat { '%[', utils.escape(info.author), '%]:' }
                local _, authorEnd = info.rawText:find(authorPattern)

                if authorEnd then
                    info.content = info.rawText:sub(authorEnd + 1)
                end
            end

            if info.message:isFromDiscord() then
                info.format = Option.ChatFormatDiscord
            end

            if not info.format then
                if info.context.ocIsIncomingPM then
                    info.format = Option.ChatFormatIncomingPrivate
                else
                    info.format = Option[self.basicChatFormats[info.chatType]]
                end
            end
        end,
    },
}

---@type table<string, string | omichat.EmoteGetter>
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


---@protected
---@param idx integer
---@param player IsoPlayer
function OmiChat._onCreatePlayer(idx, player)
    if idx ~= 0 then
        return
    end

    if Option.EnableChatNameAsCharacterName then
        local name = OmiChat.getNickname()
        if not name then
            return
        end

        -- set existing nickname to character name
        -- server will handle clearing nickname
        if name then
            OmiChat.updateCharacterName(name)
        end
    end

    OmiChat.informPlayerCreated(player)
end

---Event handler that runs on game start.
---@protected
function OmiChat._onGameStart()
    OmiChat.updateState(true)
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
    modData.nicknames = newData.nicknames
    modData.nameColors = newData.nameColors
end


return OmiChat
