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
OmiChat.SuggesterBox = require 'OmiChat/SuggesterBox'

OmiChat._iniVersion = 1
OmiChat._iniName = 'omichat.ini'


local function canUseAdminCommands()
    local player = getSpecificPlayer(0)
    local access = player and player:getAccessLevel() or 0
    return utils.getNumericAccessLevel(access) >= Option.MinimumCommandAccessLevel
end

local function hasAccess(access, accessLevel)
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
end


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
        name = 'clearnames',
        command = '/clearnames ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_clearnames',
            isEnabled = canUseAdminCommands,
            onUse = function(self, command)
                OmiChat.sendClearNames(getSpecificPlayer(0))
            end,
        }
    },
    {
        name = 'setname',
        command = '/setname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_setname',
            isEnabled = canUseAdminCommands,
            onUse = function(self, command)
                local player = getSpecificPlayer(0)
                OmiChat.sendSetName(player, command)
            end,
        }
    },
    {
        name = 'resetname',
        command = '/resetname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_resetname',
            isEnabled = canUseAdminCommands,
            onUse = function(self, command)
                local player = getSpecificPlayer(0)
                OmiChat.sendResetName(player, command)
            end,
        }
    },
    {
        name = 'card',
        command = '/card ',
        omichat = {
            isCommand = true,
            helpText = 'UI_ServerOptionDesc_Card',
            isEnabled = function()
                local player = getSpecificPlayer(0)
                local inv = player:getInventory()
                if not inv:contains('CardDeck') and player:getAccessLevel() == 'None' then
                    return false
                end

                return true
            end,
            onUse = function(self)
                local player = getSpecificPlayer(0)
                local inv = player:getInventory()
                if not inv:contains('CardDeck') and player:getAccessLevel() == 'None' then
                    OmiChat.showInfoMessage(getText(self.omichat.helpText))
                    return
                end

                OmiChat.requestDrawCard(player)
            end,
        }
    },
    {
        name = 'roll',
        command = '/roll ',
        omichat = {
            isCommand = true,
            helpText = 'UI_ServerOptionDesc_Roll',
            isEnabled = function()
                local player = getSpecificPlayer(0)
                local inv = player:getInventory()
                if not inv:contains('Dice') and player:getAccessLevel() == 'None' then
                    return false
                end

                return true
            end,
            onUse = function(self, command)
                local player = getSpecificPlayer(0)
                local inv = player:getInventory()
                if not inv:contains('Dice') and player:getAccessLevel() == 'None' then
                    OmiChat.showInfoMessage(getText(self.omichat.helpText))
                    return
                end

                command = utils.trim(command)
                local first = command:split(' ')[1]
                local sides = first and tonumber(first)
                if not sides and #command == 0 then
                    sides = 6
                elseif not sides or sides < 1 or sides > 100 then
                    OmiChat.showInfoMessage(getText(self.omichat.helpText))
                    return
                end

                OmiChat.requestRollDice(player, sides)
            end,
        }
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
                        if not info.access or hasAccess(info.access, accessLevel) then
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

---@type omichat.Suggester[]
OmiChat._suggesters = {
    {
        name = 'commands',
        priority = 10,
        suggest = function(self, info)
            if OmiChat.chatCommandToStream(info.input) then
                return
            end

            local player = getSpecificPlayer(0)
            local accessLevel = player and player:getAccessLevel()
            if isCoopHost() then
                accessLevel = 'admin'
            end
            if not accessLevel then
                return
            end

            local command = info.input:match('^/(%S*)$')
            if not command then
                return
            end

            command = command:lower()
            local fullCommand = '/' .. command

            local startsWith = {}
            local contains = {}

            -- chat streams
            for _, stream in ipairs(ISChat.allChatStreams) do
                local isEnabled = stream.omichat and stream.omichat.isEnabled
                if not isEnabled or isEnabled(stream) then
                    if utils.startsWith(stream.command, fullCommand) then
                        startsWith[#startsWith+1] = stream.command
                    elseif stream.shortCommand and utils.startsWith(stream.shortCommand, fullCommand) then
                        startsWith[#startsWith+1] = stream.shortCommand
                    elseif utils.contains(stream.command, command) then
                        contains[#contains+1] = stream.command
                    elseif stream.shortCommand and utils.contains(stream.shortCommand, command) then
                        contains[#contains+1] = stream.shortCommand
                    end
                end
            end

            -- command streams
            for _, stream in ipairs(OmiChat._commandStreams) do
                local isEnabled = stream.omichat and stream.omichat.isEnabled
                if not isEnabled or isEnabled(stream) then
                    if utils.startsWith(stream.command, fullCommand) then
                        startsWith[#startsWith+1] = stream.command
                    elseif stream.shortCommand and utils.startsWith(stream.shortCommand, fullCommand) then
                        startsWith[#startsWith+1] = stream.shortCommand
                    elseif utils.contains(stream.command, command) then
                        contains[#contains+1] = stream.command
                    elseif stream.shortCommand and utils.contains(stream.shortCommand, command) then
                        contains[#contains+1] = stream.shortCommand
                    end
                end
            end

            -- vanilla command streams
            for _, commandInfo in ipairs(vanillaCommands) do
                if not commandInfo.access or hasAccess(commandInfo.access, accessLevel) then
                    local vanillaCommand = concat { '/', commandInfo.name, ' ' }
                    if utils.startsWith(vanillaCommand, fullCommand) then
                        startsWith[#startsWith+1] = vanillaCommand
                    elseif utils.contains(vanillaCommand, command) then
                        contains[#contains+1] = vanillaCommand
                    end
                end
            end

            local i = 1
            local seen = {}
            while i <= #startsWith + #contains do
                local cmd
                if i <= #startsWith then
                    cmd = startsWith[i]
                else
                    cmd = contains[i - #startsWith]
                end

                if not cmd then
                    break
                end

                if not seen[cmd] then
                    info.suggestions[#info.suggestions+1] = {
                        type = 'command',
                        display = cmd,
                        suggestion = cmd,
                    }
                end

                i = i + 1
                seen[cmd] = true
            end
        end,
    },
    {
        name = 'online-usernames',
        priority = 8,
        suggest = function(self, info)
            if #info.input < 2 then
                return
            end

            local stream = OmiChat.chatCommandToStream(info.input)
            local context = stream and stream.omichat and stream.omichat.context
            local wantsSuggestions = context and context.ocSuggestUsernames
            local unknownCommand = not stream and info.input:sub(1, 1) == '/'

            if not wantsSuggestions and not unknownCommand then
                return
            end

            local onlinePlayers = getOnlinePlayers()
            local parts = luautils.split(info.input, ' ')
            if #parts == 0 or (unknownCommand and #parts == 1) then
                return
            end

            local startsWith = {}
            local contains = {}

            local last = parts[#parts]:lower()
            for i = 0, onlinePlayers:size() - 1 do
                local player = onlinePlayers:get(i)
                local username = player and player:getUsername()
                local usernameLower = username and username:lower()

                if #parts == 1 then
                    contains[#contains+1] = username
                elseif usernameLower == last then
                    -- exact match
                    return
                elseif usernameLower and utils.startsWith(usernameLower, last) then
                    startsWith[#startsWith+1] = username
                elseif usernameLower and utils.contains(usernameLower, last) then
                    contains[#contains+1] = username
                end
            end

            local i = 1
            local prefix = concat(parts, ' ', 1, #parts == 1 and 1 or #parts - 1)
            while i <= #startsWith + #contains do
                local username
                if i <= #startsWith then
                    username = startsWith[i]
                else
                    username = contains[i - #startsWith]
                end

                if not username then
                    break
                end

                if utils.contains(username, ' ') then
                    username = concat({ '"', username:gsub('"', '\\"'), '"' })
                end

                info.suggestions[#info.suggestions+1] = {
                    type = 'user',
                    display = username,
                    suggestion = concat({ prefix, username }, ' ') .. ' '
                }

                i = i + 1
            end
        end
    },
    {
        name = 'emotes',
        priority = 6,
        suggest = function(self, info)
            local stream = OmiChat.chatCommandToStream(info.input)
            if stream and not stream.omichat then
                return
            end

            local def = stream and stream.omichat
            if def and (def.isCommand or def.allowEmotes == false) then
                return
            end

            if not stream and utils.startsWith(info.input, '/') then
                return
            end

            local existingEmote = OmiChat.getEmoteFromCommand(info.input)
            if existingEmote then
                return
            end

            local start, _, whitespace, period, text = info.input:find('(%s*)()%.([%w_]*)$')

            -- require whitespace unless the emote is at the start
            if not start or (start ~= 1 and #whitespace == 0) then
                return
            end

            text = text:lower()
            local startsWith = {}
            local contains = {}

            for k in pairs(OmiChat._emotes) do
                if k:lower() == text then
                    -- exact message
                    return
                elseif utils.startsWith(k, text) then
                    startsWith[#startsWith+1] = k
                elseif utils.contains(k, text) then
                    contains[#contains+1] = k
                end
            end

            local i = 1
            local prefix = info.input:sub(1, period)
            while i <= #startsWith + #contains do
                local emote
                if i <= #startsWith then
                    emote = startsWith[i]
                else
                    emote = contains[i - #startsWith]
                end

                if not emote then
                    break
                end

                info.suggestions[#info.suggestions+1] = {
                    type = 'emote',
                    display = '.' .. emote,
                    suggestion = concat({ prefix, emote })
                }

                i = i + 1
            end
        end,
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
                    info.context.ocCustomStream = streamData.streamAlias or name
                    info.substitutions.stream = name

                    info.formatOptions.color = OmiChat.getColorTable(info.context.ocCustomStream)
                    info.formatOptions.useDefaultChatColor = false

                    if streamData.stripColors then
                        info.formatOptions.stripColors = true
                    end

                    if streamData.titleID then
                        info.titleID = streamData.titleID
                    end

                    info.message:setShouldAttractZombies(not not streamData.attractZombies)

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
            info.formatOptions.useDefaultChatColor = false
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