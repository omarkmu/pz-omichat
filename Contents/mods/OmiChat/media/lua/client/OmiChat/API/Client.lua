---Base client API.

require 'Chat/ISChat'

local vanillaCommands = require 'OmiChat/Data/VanillaCommandList'

local concat = table.concat
local pairs = pairs
local getText = getText
local ISChat = ISChat ---@cast ISChat omichat.ISChat


---@class omichat.api.client : omichat.api.shared
---@field private _commandStreams omichat.CommandStream[]
---@field private _emotes table<string, string | omichat.EmoteGetter>
---@field private _formatters table<string, omichat.MetaFormatter>
---@field private _iconsToExclude table<string, true>
---@field private _transformers omichat.MessageTransformer[]
---@field private _prefsVersion integer
---@field private _prefsFileName string
---@field private _playerPrefs omichat.PlayerPreferences
---@field private _customChatStreams table<string, omichat.ChatStream>
---@field private _vanillaStreamConfigs table<string, omichat.ChatStreamConfig>
local OmiChat = require 'OmiChatShared'
local Option = OmiChat.Option
local utils = OmiChat.utils
local config = OmiChat.config

OmiChat.ColorModal = require 'OmiChat/Component/ColorModal'
OmiChat.IconPicker = require 'OmiChat/Component/IconPicker'
OmiChat.SuggesterBox = require 'OmiChat/Component/SuggesterBox'

OmiChat._prefsVersion = 1
OmiChat._prefsFileName = 'omichat.json'


---Checks whether the current player can use custom admin commands.
---@return boolean
local function canUseAdminCommands()
    local player = getSpecificPlayer(0)
    local access = player and player:getAccessLevel() or 0
    return utils.getNumericAccessLevel(access) >= Option.MinimumCommandAccessLevel
end

---Appends members of `t1` to `t2`.
---@param t1 unknown[]
---@param t2 unknown[]
---@return unknown[]
local function extend(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end

    return t1
end

---Checks whether a given access level should have access based on provided flags.
---@param flags integer?
---@param accessLevel string
---@return boolean
local function hasAccess(flags, accessLevel)
    if not flags then
        return true
    end

    accessLevel = accessLevel:lower()

    if flags >= 32 then
        if accessLevel == 'admin' then
            return true
        end

        flags = flags - 32
    end

    if flags >= 16 then
        if accessLevel == 'moderator' then
            return true
        end

        flags = flags - 16
    end

    if flags >= 8 then
        if accessLevel == 'overseer' then
            return true
        end

        flags = flags - 8
    end

    if flags >= 4 then
        if accessLevel == 'gm' then
            return true
        end

        flags = flags - 4
    end

    if flags >= 2 then
        if accessLevel == 'observer' then
            return true
        end

        flags = flags - 2
    end

    return flags == 1
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
            onUse = function(_, command)
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
            onUse = function()
                OmiChat.requestClearNames()
            end,
        },
    },
    {
        name = 'setname',
        command = '/setname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_setname',
            isEnabled = canUseAdminCommands,
            onUse = function(_, command)
                OmiChat.requestSetName(command)
            end,
        },
    },
    {
        name = 'resetname',
        command = '/resetname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_resetname',
            isEnabled = canUseAdminCommands,
            onUse = function(_, command)
                OmiChat.requestResetName(command)
            end,
        },
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
                return inv:contains('CardDeck') or player:getAccessLevel() ~= 'None'
            end,
            onUse = function(self)
                if not OmiChat.requestDrawCard() then
                    OmiChat.showInfoMessage(getText(self.omichat.helpText))
                end
            end,
        },
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
                return inv:contains('Dice') or player:getAccessLevel() ~= 'None'
            end,
            onUse = function(self, command)
                command = utils.trim(command)
                local first = command:split(' ')[1]
                local sides = first and tonumber(first)
                if not sides and #command == 0 then
                    sides = 6
                elseif not sides then
                    OmiChat.showInfoMessage(getText(self.omichat.helpText))
                    return
                end

                if not OmiChat.requestRollDice(sides) then
                    OmiChat.showInfoMessage(getText(self.omichat.helpText))
                end
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
                        emotes[#emotes + 1] = k
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

                for i = 1, #emotes do
                    parts[#parts + 1] = ' <LINE> * .'
                    parts[#parts + 1] = emotes[i]
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
        },
    },
    {
        name = 'help',
        command = '/help ',
        omichat = {
            isCommand = true,
            onUse = function(_, command)
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

                command = utils.trim(command)

                -- specific command help
                if #command > 0 then
                    ---@type omichat.CommandStream?
                    local helpStream

                    for i = 1, #OmiChat._commandStreams do
                        local stream = OmiChat._commandStreams[i]
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
                local commands = {} ---@type omichat.VanillaCommand[]

                for i = 1, #OmiChat._commandStreams do
                    local stream = OmiChat._commandStreams[i]
                    if stream.omichat then
                        local isEnabled = stream.omichat.isEnabled
                        local helpText = stream.omichat.helpText
                        if not seen[stream.name] and helpText and (not isEnabled or isEnabled(stream)) then
                            seen[stream.name] = true
                            commands[#commands + 1] = { name = stream.name, helpText = helpText, access = 0 }
                        end
                    end
                end

                for i = 1, #vanillaCommands do
                    local info = vanillaCommands[i]
                    if info.name and info.helpText and not seen[info.name] then
                        if hasAccess(info.access, accessLevel) then
                            commands[#commands + 1] = info
                        end
                    end
                end

                table.sort(commands, function(a, b) return a.name < b.name end)

                local result = { getText('UI_OmiChat_list_of_commands') }
                for i = 1, #commands do
                    local cmd = commands[i]
                    result[#result + 1] = ' <LINE> * '
                    result[#result + 1] = cmd.name
                    result[#result + 1] = ' : '

                    if cmd.helpTextArgs then
                        result[#result + 1] = getText(cmd.helpText, unpack(cmd.helpTextArgs))
                    else
                        result[#result + 1] = getText(cmd.helpText)
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
        ---@param tab (omichat.ChatStream | omichat.CommandStream)[]
        ---@param command string
        ---@param fullCommand string
        ---@param currentTabID integer
        ---@param startsWith string[]
        ---@param contains string[]
        collectStreamResults = function(_, tab, command, fullCommand, currentTabID, startsWith, contains)
            for i = 1, #tab do
                local stream = tab[i]
                local isEnabled = stream.omichat and stream.omichat.isEnabled
                local matchingTab = currentTabID == stream.tabID
                if matchingTab and (not isEnabled or isEnabled(stream)) then
                    if utils.startsWith(stream.command, fullCommand) then
                        startsWith[#startsWith + 1] = stream.command
                    elseif stream.shortCommand and utils.startsWith(stream.shortCommand, fullCommand) then
                        startsWith[#startsWith + 1] = stream.shortCommand
                    elseif utils.contains(stream.command, command) then
                        contains[#contains + 1] = stream.command
                    elseif stream.shortCommand and utils.contains(stream.shortCommand, command) then
                        contains[#contains + 1] = stream.shortCommand
                    end
                end
            end
        end,
        suggest = function(self, info)
            local instance = ISChat.instance
            if not instance then
                return
            end

            local currentTabID = instance.currentTabID
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

            -- chat & command streams
            self:collectStreamResults(ISChat.allChatStreams, command, fullCommand, currentTabID, startsWith, contains)
            self:collectStreamResults(OmiChat._commandStreams, command, fullCommand, currentTabID, startsWith, contains)

            -- vanilla command streams
            for i = 1, #vanillaCommands do
                local commandInfo = vanillaCommands[i]
                if hasAccess(commandInfo.access, accessLevel) then
                    local vanillaCommand = concat { '/', commandInfo.name, ' ' }
                    if utils.startsWith(vanillaCommand, fullCommand) then
                        startsWith[#startsWith + 1] = vanillaCommand
                    elseif utils.contains(vanillaCommand, command) then
                        contains[#contains + 1] = vanillaCommand
                    end
                end
            end

            local seen = {}
            local results = extend(startsWith, contains)
            for i = 1, #results do
                local cmd = results[i]
                if not seen[cmd] then
                    info.suggestions[#info.suggestions + 1] = {
                        type = 'command',
                        display = cmd,
                        suggestion = cmd,
                    }

                    seen[cmd] = true
                end
            end
        end,
    },
    {
        name = 'online-usernames',
        priority = 8,
        suggest = function(_, info)
            if #info.input < 2 then
                return
            end

            local stream = OmiChat.chatCommandToStream(info.input)
            local context = stream and stream.omichat and stream.omichat.context
            local wantsSuggestions = context and context.ocSuggestUsernames

            local player = getSpecificPlayer(0)
            local isCommand = not stream and info.input:sub(1, 1) == '/' and player and player:getAccessLevel() ~= 'None'

            if not wantsSuggestions and not isCommand then
                return
            end

            local onlinePlayers = getOnlinePlayers()
            local parts = luautils.split(info.input, ' ')
            if #parts == 0 or (isCommand and #parts == 1) then
                return
            end

            local startsWith = {}
            local contains = {}

            local ownUsername = player and player:getUsername()
            local includeSelf = utils.default(context and context.ocSuggestOwnUsername, true)
            local last = parts[#parts]:lower()
            for i = 0, onlinePlayers:size() - 1 do
                local onlinePlayer = onlinePlayers:get(i)
                local username = onlinePlayer and onlinePlayer:getUsername()

                if includeSelf or username ~= ownUsername then
                    local usernameLower = username and username:lower()
                    if #parts == 1 then
                        -- only command specified; include all options
                        contains[#contains + 1] = username
                    elseif usernameLower == last then
                        -- exact match
                        return
                    elseif usernameLower and utils.startsWith(usernameLower, last) then
                        startsWith[#startsWith + 1] = username
                    elseif usernameLower and utils.contains(usernameLower, last) then
                        contains[#contains + 1] = username
                    end
                end
            end

            local prefix = concat(parts, ' ', 1, #parts == 1 and 1 or #parts - 1)
            local results = extend(startsWith, contains)
            for i = 1, #results do
                local username = results[i]
                if utils.contains(username, ' ') then
                    username = concat({ '"', username:gsub('"', '\\"'), '"' })
                end

                info.suggestions[#info.suggestions + 1] = {
                    type = 'user',
                    display = username,
                    suggestion = concat({ prefix, username }, ' ') .. ' ',
                }
            end
        end,
    },
    {
        name = 'emotes',
        priority = 6,
        suggest = function(_, info)
            local instance = ISChat.instance
            if not instance then
                return
            end

            local currentTabID = instance.currentTabID
            local stream = OmiChat.chatCommandToStream(info.input)
            local allowEmotes = false
            if not stream then
                local isCommand = utils.startsWith(info.input, '/')
                local default = ISChat.defaultTabStream[currentTabID]
                allowEmotes = not isCommand

                if not isCommand and default then
                    stream = default
                else
                    return
                end
            end

            if stream.tabID and currentTabID ~= stream.tabID then
                return
            end

            local def = stream.omichat
            if def then
                if def.isEnabled and not def.isEnabled(stream) then
                    return
                end

                allowEmotes = true
                if def.allowEmotes ~= nil then
                    allowEmotes = def.allowEmotes
                elseif def.isCommand then
                    allowEmotes = false
                end
            end

            if not allowEmotes then
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
                    -- exact match
                    return
                elseif utils.startsWith(k, text) then
                    startsWith[#startsWith + 1] = k
                elseif utils.contains(k, text) then
                    contains[#contains + 1] = k
                end
            end

            local prefix = info.input:sub(1, period)
            local results = extend(startsWith, contains)
            for i = 1, #results do
                local emote = results[i]
                info.suggestions[#info.suggestions + 1] = {
                    type = 'emote',
                    display = '.' .. emote,
                    suggestion = concat({ prefix, emote }),
                }
            end
        end,
    },
}

---@type omichat.MessageTransformer[]
OmiChat._transformers = {
    {
        name = 'radio-chat',
        priority = 10,
        transform = function(_, info)
            local text = info.content or info.rawText
            if info.chatType ~= 'radio' then
                return
            end

            local _, msgStart, freq = text:find('Radio%s*%((%d+%.%d+)[^%)]+%)%s*:')
            if not msgStart then
                return
            end

            info.context.ocIsRadio = true
            info.content = text:sub(msgStart + 1)
            info.format = Option.ChatFormatRadio
            info.substitutions.frequency = freq
        end,
    },
    {
        name = 'decode-callout',
        priority = 8,
        transform = function(_, info)
            if info.chatType ~= 'shout' then
                return
            end

            local text = info.content or info.rawText
            local calloutFormatter = OmiChat.getFormatter('callout')
            local sneakCalloutFormatter = OmiChat.getFormatter('sneakcallout')

            if calloutFormatter:isMatch(text) then
                info.content = calloutFormatter:read(text)
                info.context.ocIsCallout = true
            elseif sneakCalloutFormatter:isMatch(text) then
                info.content = sneakCalloutFormatter:read(text)
                info.context.ocIsSneakCallout = true

                if OmiChat.isCustomStreamEnabled('whisper') then
                    info.format = Option.ChatFormatWhisper
                    info.formatOptions.color = OmiChat.getColorOrDefault('whisper')
                    info.titleID = 'UI_OmiChat_whisper_chat_title_id'
                end
            else
                return
            end

            -- already created a sound for the callout
            info.message:setShouldAttractZombies(false)
        end,
    },
    {
        name = 'decode-stream',
        priority = 8,
        transform = function(_, info)
            local isRadio = info.context.ocIsRadio
            for data in config:streams() do
                local name = data.name

                local formatter = OmiChat.getFormatter(name)
                local isValidStream = data.chatTypes[info.chatType] and OmiChat.isCustomStreamEnabled(name)

                local text = info.content or info.rawText
                local isMatch = formatter:isMatch(text)

                if isMatch and isRadio then
                    if data.convertToRadio then
                        info.content = formatter:read(text)
                    else
                        info.message:setShowInChat(false)

                        -- the message showing overhead is hardcoded for radio messages,
                        -- so this can't actually be prevented
                        info.message:setOverHeadSpeech(false)
                    end

                    break
                elseif isValidStream and isMatch then
                    info.content = formatter:read(text)
                    info.format = Option[data.chatFormatOpt]
                    info.context.ocCustomStream = data.streamAlias or name
                    info.substitutions.stream = name

                    info.formatOptions.color = OmiChat.getColorOrDefault(info.context.ocCustomStream)
                    info.formatOptions.useDefaultChatColor = false

                    if data.stripColors then
                        info.formatOptions.stripColors = true
                    end

                    if data.titleID then
                        info.titleID = data.titleID
                    end

                    info.message:setShouldAttractZombies(not not data.attractZombies)

                    if Option[data.overheadFormatOpt] == '' then
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
        transform = function(_, info)
            local range
            local chatRange
            local streamData = config:getCustomStreamInfo(info.context.ocCustomStream)
            if streamData then
                range = Option[streamData.rangeOpt]
                chatRange = Option:getDefault(streamData.defaultRangeOpt or 'RangeSay')
            elseif info.context.ocIsCallout then
                range = Option.RangeCallout
                chatRange = Option:getDefault('RangeYell')
            elseif info.context.ocIsSneakCallout then
                range = Option.RangeSneakCallout
                chatRange = Option:getDefault('RangeYell')
            elseif info.chatType == 'say' then
                range = Option.RangeSay
                chatRange = Option:getDefault('RangeSay')
            elseif info.chatType == 'shout' then
                range = Option.RangeYell
                chatRange = Option:getDefault('RangeYell')
            else
                return
            end

            info.attractRange = range * Option.RangeMultiplierZombies

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

            if math.sqrt(xDiff * xDiff + yDiff * yDiff) > range then
                info.message:setOverHeadSpeech(false)
                info.message:setShowInChat(false)
                info.context.ocOutOfRange = true
                return true
            end
        end,
    },
    {
        name = 'private-chat',
        priority = 4,
        transform = function(_, info)
            if info.chatType ~= 'whisper' then
                return
            end

            local text = info.content or info.rawText
            local _, msgStart, other = text:find('%[to ([^%]]+)%]:')
            if other then
                info.content = text:sub(msgStart + 1)
                info.format = Option.ChatFormatOutgoingPrivate
                info.substitutions.recipient = other
                info.substitutions.recipientName = OmiChat.getNameInChat(other, 'whisper') or other
            else
                -- defer to basic chat format handler
                info.context.ocIsIncomingPM = true
            end

            info.formatOptions.color = OmiChat.getColorOrDefault('private')
            info.formatOptions.useDefaultChatColor = false
        end,
    },
    {
        name = 'server-chat',
        priority = 2,
        transform = function(_, info)
            if info.chatType ~= 'server' then
                return
            end

            local text = info.content or info.rawText
            -- not great, but can't access the isShowTitle chat setting to do this in a safer way
            local patt = concat { '%[', getText('UI_chat_server_chat_title_id'), '%]:' }
            local _, serverMsgStart = text:find(patt)

            if serverMsgStart then
                info.content = text:sub(serverMsgStart + 1)
            else
                -- server messages can be only their text, if not set to show title
                -- still have to extract text due to the existing rich text

                local _, sizeEnd = text:find('<SIZE:')
                local start = sizeEnd ~= -1 and text:find('>', sizeEnd)
                if start then
                    info.content = info.rawText:sub(start + 1)
                end
            end

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
