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
local StreamInfo = require 'OmiChat/Component/StreamInfo'

OmiChat.ColorModal = require 'OmiChat/Component/ColorModal'
OmiChat.IconPicker = require 'OmiChat/Component/IconPicker'
OmiChat.SuggesterBox = require 'OmiChat/Component/SuggesterBox'
OmiChat.StreamInfo = StreamInfo

OmiChat._prefsVersion = 1
OmiChat._prefsFileName = 'omichat.json'


---Checks whether the current player can use custom admin commands.
---@return boolean
local function canUseAdminCommands()
    local player = getSpecificPlayer(0)
    local access = player and player:getAccessLevel()
    return utils.getNumericAccessLevel(access) >= Option.MinimumCommandAccessLevel
end

---Appends members of `t1` to `t2`.
---@param t1 string[]
---@param t2 string[]
---@return string[]
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

---Encodes additional information in a message tag.
---@param message omichat.Message
---@param key string
---@param value unknown
local function addMessageTagValue(message, key, value)
    local tag = message:getCustomTag()
    local success, newTag, encodedTag
    success, newTag = utils.json.tryDecode(tag)
    if not success or type(newTag) ~= 'table' then
        newTag = {}
    end

    newTag[key] = value
    success, encodedTag = utils.json.tryEncode(newTag)
    if not success then
        -- other data is bad, so just throw it out
        if type(value) == 'string' then
            value = string.format('%q', value)
        end

        encodedTag = string.format('{"%s":%s}', key, tostring(value))
    end

    message:setCustomTag(encodedTag)
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
            helpText = 'UI_OmiChat_helptext_name',
            isEnabled = function() return Option:isNameCommandEnabled() end,
            onUse = function(ctx)
                if Option:isNameCommandSetNickname() then
                    local _, feedback = OmiChat.setNickname(ctx.command)
                    if feedback then
                        OmiChat.showInfoMessage(feedback)
                    end

                    return
                end

                local input = utils.trim(ctx.command or '')
                if #input == 0 then
                    OmiChat.showInfoMessage(getText('UI_OmiChat_set_name_empty'))
                    return
                end

                local _, feedback = OmiChat.updateCharacterName(input, Option:isNameCommandSetFullName())
                if feedback then
                    OmiChat.showInfoMessage(feedback)
                end
            end,
            onHelp = function()
                local msg = 'UI_OmiChat_helptext_name'
                if Option:isNameCommandSetFullName() then
                    msg = 'UI_OmiChat_helptext_name_full'
                end

                OmiChat.showInfoMessage(getText(msg))
            end,
        },
    },
    {
        name = 'nickname',
        command = '/nickname ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_nickname',
            isEnabled = function() return Option:isNicknameCommandEnabled() end,
            onUse = function(ctx)
                local _, feedback = OmiChat.setNickname(ctx.command)
                if feedback then
                    OmiChat.showInfoMessage(feedback)
                end
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
            onUse = function(ctx)
                OmiChat.requestSetName(ctx.command)
            end,
        },
    },
    {
        name = 'iconinfo',
        command = '/iconinfo ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_iconinfo',
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                local command = utils.trim(ctx.command)
                if getTexture(command) then
                    local image = table.concat { ' <SPACE> <IMAGE:', command, ',15,14> ' }
                    OmiChat.showInfoMessage(getText('UI_OmiChat_icon_info', command, image))
                    return
                end

                local textureName = utils.getTextureNameFromIcon(command)
                if not textureName or not getTexture(textureName) then
                    OmiChat.showInfoMessage(getText('UI_OmiChat_icon_info_unknown', command))
                    return
                end

                local image = table.concat { ' <SPACE> <IMAGE:', textureName, ',15,14> ' }
                OmiChat.showInfoMessage(getText('UI_OmiChat_icon_info_alias', textureName, image, command))
            end,
        },
    },
    {
        name = 'seticon',
        command = '/seticon ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_seticon',
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                if not OmiChat.requestSetIcon(ctx.command) then
                    local args = utils.parseCommandArgs(ctx.command)
                    local icon = args[2]
                    if not args[1] or not icon then
                        OmiChat.showInfoMessage(ctx.stream:getHelpText())
                    else
                        OmiChat.showInfoMessage(getText('UI_OmiChat_icon_info_unknown', icon))
                    end
                end
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
            onUse = function(ctx)
                OmiChat.requestResetName(ctx.command)
            end,
        },
    },
    {
        name = 'reseticon',
        command = '/reseticon ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_reseticon',
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestResetIcon(ctx.command)
            end,
        },
    },
    {
        name = 'addlanguage',
        command = '/addlanguage ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_addlanguage',
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestAddLanguage(ctx.command)
            end,
        },
    },
    {
        name = 'resetlanguages',
        command = '/resetlanguages ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_resetlanguages',
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestResetLanguages(ctx.command)
            end,
        },
    },
    {
        name = 'setlanguageslots',
        command = '/setlanguageslots ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_setlanguageslots',
            isEnabled = canUseAdminCommands,
            onUse = function(ctx)
                OmiChat.requestSetLanguageSlots(ctx.command)
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
            onUse = function(ctx)
                if not OmiChat.requestDrawCard() then
                    OmiChat.showInfoMessage(ctx.stream:getHelpText())
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
            onUse = function(ctx)
                local command = utils.trim(ctx.command)
                local first = command:split(' ')[1]
                local sides = first and tonumber(first)
                if not sides and #command == 0 then
                    sides = 6
                elseif not sides then
                    OmiChat.showInfoMessage(ctx.stream:getHelpText())
                    return
                end

                if not OmiChat.requestRollDice(sides) then
                    OmiChat.showInfoMessage(ctx.stream:getHelpText())
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
            onUse = function(ctx) ctx.stream:onHelp() end,
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
            onUse = function(ctx)
                local accessLevel
                if isCoopHost() then
                    accessLevel = 'admin'
                else
                    local player = getSpecificPlayer(0)
                    accessLevel = player and player:getAccessLevel()
                end

                local command = ctx.command
                if not accessLevel then
                    -- something went wrong, defer to default help command
                    SendCommandToServer('/help ' .. command)
                    return
                end

                command = utils.trim(command)

                -- specific command help
                if #command > 0 then
                    ---@type omichat.StreamInfo?, function?, string?
                    local helpStream, helpCallback, helpText

                    for stream in OmiChat.iterCommandStreams() do
                        if stream:getName() == command and stream:isEnabled() then
                            helpCallback = stream:getHelpCallback()
                            helpText = stream:getHelpTextStringID() and stream:getHelpText()
                            if helpCallback or helpText then
                                helpStream = stream
                                break
                            end
                        end
                    end

                    if helpCallback then
                        helpCallback(helpStream)
                    elseif helpText then
                        OmiChat.showInfoMessage(helpText)
                    else
                        -- defer to default help command
                        SendCommandToServer('/help ' .. command)
                    end

                    return
                end

                -- overall help
                local seen = {}
                local commands = {} ---@type omichat.VanillaCommand[]

                for stream in OmiChat.iterCommandStreams() do
                    if stream:config() then
                        local name = stream:getName()
                        local helpText = stream:getHelpTextStringID()
                        if not seen[name] and helpText and stream:isEnabled() then
                            seen[name] = true
                            commands[#commands + 1] = { name = name, helpText = helpText, access = 0 }
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
        collectStreamResults = function(tab, command, fullCommand, currentTabID, startsWith, contains)
            for i = 1, #tab do
                local stream = StreamInfo:new(tab[i])
                if stream:isTabID(currentTabID) and stream:isEnabled() then
                    local streamCommand = stream:getCommand()
                    local shortCommand = stream:getShortCommand()
                    if utils.startsWith(streamCommand, fullCommand) then
                        startsWith[#startsWith + 1] = streamCommand
                    elseif shortCommand and utils.startsWith(shortCommand, fullCommand) then
                        startsWith[#startsWith + 1] = shortCommand
                    elseif utils.contains(streamCommand, command) then
                        contains[#contains + 1] = streamCommand
                    elseif shortCommand and utils.contains(shortCommand, command) then
                        contains[#contains + 1] = shortCommand
                    end

                    for alias in stream:aliases() do
                        if utils.startsWith(alias, fullCommand) then
                            startsWith[#startsWith + 1] = alias
                        elseif utils.contains(alias, command) then
                            contains[#contains + 1] = alias
                        end
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

            local command = info.input:match('^/(%S+)$')
            if not command then
                return
            end

            command = command:lower()
            local fullCommand = '/' .. command

            local startsWith = {}
            local contains = {}

            -- chat & command streams
            self.collectStreamResults(ISChat.allChatStreams, command, fullCommand, currentTabID, startsWith, contains)
            self.collectStreamResults(OmiChat._commandStreams, command, fullCommand, currentTabID, startsWith, contains)

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
            local context = stream and stream:getContext()
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
            if not stream then
                if utils.startsWith(info.input, '/') then
                    -- disallow for unknown commands
                    return
                end

                local default = OmiChat.getDefaultTabStream(currentTabID)
                if not default then
                    return
                end

                stream = default
            end

            if not stream:isTabID(currentTabID) then
                return
            end

            if not stream:isEnabled() or not stream:isAllowEmotes() then
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
        priority = 55,
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
        name = 'cleanup-author-metadata',
        priority = 50,
        transform = function(_, info)
            local text = info.content or info.rawText
            local formatter = OmiChat.getFormatter('onlineID')
            local id = formatter:read(text)

            -- cleanup
            if id then
                local start, finish = text:find(formatter:getPattern())
                if start then
                    info.content = concat { text:sub(1, start - 1), text:sub(start, finish), text:sub(finish + 1) }
                end
            end
        end,
    },
    {
        name = 'decode-full-overhead',
        priority = 45,
        transform = function(_, info)
            local formatter = OmiChat.getFormatter('overheadFull')
            local text = info.content or info.rawText
            local match = formatter:read(text)
            if match then
                info.content = match
            end
        end,
    },
    {
        name = 'handle-echo',
        priority = 40,
        transform = function(_, info)
            local text = info.content or info.rawText
            local formatter = OmiChat.getFormatter('echo')

            local matched = formatter:read(text)
            if not matched then
                return
            end

            if Option.ChatFormatEcho ~= '' then
                info.format = Option.ChatFormatEcho
            end

            local player = getSpecificPlayer(0)
            local username = player and player:getUsername()
            if info.message:getAuthor() == username then
                info.message:setShowInChat(false)
                info.message:setOverHeadSpeech(false)
            end
        end,
    },
    {
        name = 'decode-card',
        priority = 35,
        transform = function(_, info)
            if info.chatType ~= 'say' or not OmiChat.isCustomStreamEnabled('card') then
                return
            end

            local text = info.content or info.rawText
            local formatter = OmiChat.getFormatter('card')
            local matched = formatter:read(text)
            if not matched then
                return
            end

            if info.context.ocIsRadio then
                info.message:setShowInChat(false)
                info.message:setOverHeadSpeech(false)
                return
            end

            if Option.OverheadFormatCard == '' then
                info.message:setOverHeadSpeech(false)
            end

            local suit = utils.decodeInvisibleCharacter(matched)
            local card = utils.decodeInvisibleCharacter(matched:sub(2, 2))

            if suit < 1 or suit > 4 or card < 1 or card > 13 then
                info.message:setShowInChat(false)
                return
            end

            info.content = matched:sub(3)
            info.substitutions.card = utils.getTranslatedCardName(card, suit)

            info.format = Option.ChatFormatCard
            info.formatOptions.color = OmiChat.getColorOrDefault('me')
            info.formatOptions.useDefaultChatColor = false

            info.context.ocCustomStream = 'me'
            info.substitutions.stream = 'card'
        end,
    },
    {
        name = 'decode-roll',
        priority = 35,
        transform = function(_, info)
            if info.chatType ~= 'say' or not OmiChat.isCustomStreamEnabled('roll') then
                return
            end

            local text = info.content or info.rawText
            local formatter = OmiChat.getFormatter('roll')
            local matched = formatter:read(text)
            if not matched then
                return
            end

            if info.context.ocIsRadio then
                info.message:setShowInChat(false)
                info.message:setOverHeadSpeech(false)
                return
            end

            if Option.OverheadFormatRoll == '' then
                info.message:setOverHeadSpeech(false)
            end

            local roll = tonumber(utils.unwrapStringArgument(matched, 1, '(%d+)'))
            local sides = tonumber(utils.unwrapStringArgument(matched, 2, '(%d+)'))

            if not roll or not sides then
                info.message:setShowInChat(false)
                return
            end

            info.content = matched
            info.substitutions.roll = roll
            info.substitutions.sides = sides

            info.format = Option.ChatFormatRoll
            info.formatOptions.color = OmiChat.getColorOrDefault('me')
            info.formatOptions.useDefaultChatColor = false

            info.context.ocCustomStream = 'me'
            info.substitutions.stream = 'roll'
        end,
    },
    {
        name = 'decode-callout',
        priority = 30,
        transform = function(_, info)
            if info.chatType ~= 'shout' then
                return
            end

            local text = info.content or info.rawText
            local calloutFormatter = OmiChat.getFormatter('callout')
            local sneakCalloutFormatter = OmiChat.getFormatter('sneakCallout')

            if calloutFormatter:isMatch(text) then
                info.content = calloutFormatter:read(text)
                info.context.ocIsCallout = true
            elseif sneakCalloutFormatter:isMatch(text) then
                info.content = sneakCalloutFormatter:read(text)
                info.context.ocIsSneakCallout = true

                if OmiChat.isCustomStreamEnabled('whisper') then
                    -- format sneak callouts like whispers, if enabled
                    info.format = info.format or Option.ChatFormatWhisper
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
        priority = 30,
        transform = function(_, info)
            local isRadio = info.context.ocIsRadio
            local text = info.content or info.rawText
            for data in config:chatStreams() do
                local name = data.name

                local formatter = OmiChat.getFormatter(name)
                local isValidStream = data.chatTypes[info.chatType] and OmiChat.isCustomStreamEnabled(name)

                local isMatch = formatter:isMatch(text)
                if isMatch and isRadio then
                    if data.convertToRadio then
                        info.content = formatter:read(text)
                    else
                        info.message:setShowInChat(false)
                        info.message:setOverHeadSpeech(false)
                    end

                    break
                elseif isValidStream and isMatch then
                    info.content = formatter:read(text)
                    info.format = info.format or Option[data.chatFormatOpt]
                    info.context.ocCustomStream = data.streamAlias or name
                    info.substitutions.stream = name

                    info.formatOptions.color = OmiChat.getColorOrDefault(info.context.ocCustomStream)
                    info.formatOptions.useDefaultChatColor = false

                    if data.titleID then
                        info.titleID = data.titleID
                    end

                    if Option[data.overheadFormatOpt] == '' then
                        info.message:setOverHeadSpeech(false)
                    end

                    break
                end
            end
        end,
    },
    {
        name = 'decode-other',
        priority = 30,
        transform = function(_, info)
            local text = info.content or info.rawText
            local formatter = OmiChat.getFormatter('overheadOther')

            local matched = formatter:read(text)
            if matched then
                info.content = matched
            end
        end,
    },
    {
        name = 'handle-language',
        priority = 25,
        allowedChatTypes = {
            say = true,
            shout = true,
            radio = true,
        },
        transform = function(self, info)
            local isRadio = info.context.ocIsRadio
            local formatter = OmiChat.getFormatter('language')
            local text = info.content or info.rawText

            -- radio messages don't have language metadata, so we need to grab the id
            local encodedId
            if formatter:isMatch(text) then
                text = formatter:read(text)
                encodedId = utils.decodeInvisibleCharacter(text)
                if encodedId >= 1 and encodedId <= 32 then
                    info.content = text:sub(2)
                else
                    encodedId = nil
                end
            end

            if not self.allowedChatTypes[info.chatType] then
                return
            end

            local streamData = config:getCustomStreamInfo(info.context.ocCustomStream)
            if streamData and streamData.ignoreLanguage then
                return
            end

            local defaultLanguage = OmiChat.getDefaultRoleplayLanguage()
            local language = info.meta.language or defaultLanguage

            if not language and isRadio and encodedId then
                language = OmiChat.getRoleplayLanguageFromID(encodedId)
                if language then
                    addMessageTagValue(info.message, 'ocLanguage', language)
                end
            end

            if not language then
                return
            end

            -- add language information for format strings
            local isSigned = OmiChat.isRoleplayLanguageSigned(language)
            if language ~= defaultLanguage then
                info.substitutions.language = utils.getTranslatedLanguageName(language)
                info.substitutions.languageRaw = language
            end

            if isSigned and isRadio then
                -- hide signed messages sent over the radio
                info.message:setShowInChat(false)
                info.message:setOverHeadSpeech(false)
            end

            if isAdmin() and OmiChat.getAdminOption('know_all_languages') then
                return
            end

            local player = getSpecificPlayer(0)
            local username = player and player:getUsername()
            if not isRadio and username and info.author == username then
                -- everyone understands themselves
                return
            elseif OmiChat.checkKnowsLanguage(language) then
                -- if they understand the language, we're done here
                return
            end

            -- they didn't understand it
            local isWhisper = info.context.ocIsSneakCallout or info.context.ocCustomStream == 'whisper'
            local signedSuffix = isSigned and '_signed' or ''
            info.message:setOverHeadSpeech(false)
            info.format = Option.ChatFormatUnknownLanguage
            info.formatOptions.useDefaultChatColor = false
            info.substitutions.unknownLanguage = language

            if isRadio then
                info.substitutions.unknownLanguageString = 'UI_OmiChat_unknown_language_radio'
                info.format = Option.ChatFormatUnknownLanguageRadio
            elseif isWhisper then
                info.titleID = 'UI_OmiChat_whisper_chat_title_id'
                info.substitutions.unknownLanguageString = 'UI_OmiChat_unknown_language_whisper' .. signedSuffix
                info.formatOptions.color = OmiChat.getColorOrDefault('mequiet')
                info.context.ocCustomStream = 'mequiet'
                info.substitutions.stream = 'mequiet'
            elseif info.chatType == 'shout' then
                info.substitutions.unknownLanguageString = 'UI_OmiChat_unknown_language_shout' .. signedSuffix
                info.formatOptions.color = OmiChat.getColorOrDefault('meloud')
                info.context.ocCustomStream = 'meloud'
                info.substitutions.stream = 'meloud'
            else
                info.substitutions.unknownLanguageString = 'UI_OmiChat_unknown_language_say' .. signedSuffix
                info.formatOptions.color = OmiChat.getColorOrDefault('me')
                info.context.ocCustomStream = 'me'
                info.substitutions.stream = 'me'
            end
        end,
    },
    {
        name = 'decode-narrative',
        priority = 20,
        transform = function(_, info)
            local text = info.content or info.rawText
            local formatter = OmiChat.getFormatter('narrative')

            local matched = formatter:read(text)
            if not matched then
                return
            end

            local dialogueTag = utils.unwrapStringArgument(matched, 21)
            local content = utils.unwrapStringArgument(matched, 22)

            if not dialogueTag or not content then
                return
            end

            content = string.format('"%s"', content)

            local dialogueTagIdent = dialogueTag:gsub('%s', '_')

            local translated = getTextOrNull('UI_OmiChat_NarrativeTag_' .. dialogueTagIdent, content)
            if not translated then
                translated = getText('UI_OmiChat_NarrativeTag', dialogueTag, content)
            end

            info.content = translated
        end,
    },
    {
        name = 'check-range',
        priority = 15,
        transform = function(_, info)
            local range
            local defaultRange
            local streamData = config:getCustomStreamInfo(info.context.ocCustomStream)
            if streamData then
                range = Option[streamData.rangeOpt]
                defaultRange = Option:getDefault(streamData.defaultRangeOpt or 'RangeSay')
            elseif info.context.ocIsCallout then
                range = Option.RangeCallout
                defaultRange = Option:getDefault('RangeYell')
            elseif info.context.ocIsSneakCallout then
                range = Option.RangeSneakCallout
                defaultRange = Option:getDefault('RangeYell')
            elseif info.chatType == 'say' then
                range = Option.RangeSay
                defaultRange = Option:getDefault('RangeSay')
            elseif info.chatType == 'shout' then
                range = Option.RangeYell
                defaultRange = Option:getDefault('RangeYell')
            end

            if range then
                info.attractRange = range * Option.RangeMultiplierZombies
                if not info.context.ocIsCallout and not info.context.ocIsSneakCallout then
                    local tokens = { stream = info.substitutions.stream }
                    info.message:setShouldAttractZombies(utils.testPredicate(Option.PredicateCanZombiesHear, tokens))
                end
            end

            if isAdmin() and OmiChat.getAdminOption('ignore_message_range') then
                return
            end

            local authorPlayer = getPlayerFromUsername(info.author)
            local localPlayer = getSpecificPlayer(0)
            if not authorPlayer or not localPlayer or authorPlayer == localPlayer then
                -- players can hear themselves
                return
            end

            local outOfRange = false

            local tokens = { stream = info.substitutions.stream }
            local zMax = tonumber(utils.interpolate(Option.RangeVertical, tokens))
            if zMax and math.abs(authorPlayer:getZ() - localPlayer:getZ()) >= zMax then
                outOfRange = true
            elseif range and range ~= defaultRange then
                -- calculating distance using the distance formula like ChatUtility
                -- assuming players are synced it works equivalently
                local xDiff = authorPlayer:getX() - localPlayer:getX()
                local yDiff = authorPlayer:getY() - localPlayer:getY()

                outOfRange = math.sqrt(xDiff * xDiff + yDiff * yDiff) > range
            end

            if outOfRange then
                -- it's okay that this runs on refresh, because the
                -- show in chat value is only used on the initial message add
                info.message:setOverHeadSpeech(false)
                info.message:setShowInChat(false)
            end
        end,
    },
    {
        name = 'private-chat',
        priority = 10,
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
                info.substitutions.recipientName = utils.escapeRichText(OmiChat.getNameInChat(other, 'whisper') or other)
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
        priority = 5,
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
        priority = 5,
        basicChatFormats = {
            say = 'ChatFormatSay',
            shout = 'ChatFormatYell',
            general = 'ChatFormatGeneral',
            admin = 'ChatFormatAdmin',
            faction = 'ChatFormatFaction',
            safehouse = 'ChatFormatSafehouse',
        },
        transform = function(self, info)
            local chatFormat = self.basicChatFormats[info.chatType]
            if not chatFormat and not info.context.ocIsIncomingPM then
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

            if info.chatType == 'faction' then
                local faction = Faction.getPlayerFaction(getPlayer())
                info.substitutions.faction = faction and faction:getName() or nil
            end

            if info.format then
                return
            end

            if info.message:isFromDiscord() then
                info.format = Option.ChatFormatDiscord
            elseif info.context.ocIsIncomingPM then
                info.format = Option.ChatFormatIncomingPrivate
            else
                info.format = Option[chatFormat]
            end
        end,
    },
    {
        name = 'avoid-empty-chats',
        priority = 0,
        transform = function(_, info)
            local text = info.content or info.rawText
            local chars = {}
            for i = 1, #text do
                local c = text:sub(i, i)
                local byte = c:byte()

                -- throw away invisible characters
                if byte < 128 or byte > 159 then
                    chars[#chars + 1] = byte
                end
            end

            text = utils.trim(concat(chars))
            if #text == 0 then
                info.message:setShowInChat(false)
            end
        end,
    },
    {
        name = 'suppress-radio-overhead',
        priority = 0,
        transform = function(_, info)
            -- the message showing overhead is hardcoded for radio messages,
            -- so we have to suppress it by overwriting it with empty messages
            if not info.context.ocIsRadio or info.message:isOverHeadSpeech() then
                return
            end

            -- make sure we haven't done this already
            local tag = info.message:getCustomTag()
            local decoded = OmiChat.decodeMessageTag(tag)
            if decoded.suppressed then
                return
            end

            -- push the message up with blank text
            local author = info.message:getAuthor()
            local speaker = author and utils.getPlayerByUsername(author)
            if speaker then
                for _ = 1, 5 do
                    speaker:Say(' ')
                end
            end

            -- avoid doing this again
            addMessageTagValue(info.message, 'ocSupressed', true)
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


---Event handler that runs when a player is created.
---@param playerNum integer
---@param player IsoPlayer
---@protected
function OmiChat._onCreatePlayer(playerNum, player)
    if ISChat.instance and playerNum == 0 then
        ISChat.instance:setInfo(OmiChat.getInfoRichText(player))
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

    -- reset languages
    OmiChat.requestDataUpdate({
        field = 'languages',
        target = player:getUsername(),
    })
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
