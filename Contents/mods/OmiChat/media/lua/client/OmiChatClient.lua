require 'Chat/ISChat'

local utils = require 'OmiChat/util'
local OmiChatShared = require 'OmiChatShared'
local ColorModal = require 'OmiChat/ColorModal'
local IconPicker = require 'OmiChat/IconPicker'
local vanillaCommands = require 'OmiChat/VanillaCommandList'

local Option = OmiChatShared.Option
local format = string.format
local concat = table.concat
local pairs = pairs
local ipairs = ipairs
local getText = getText

---@class omichat.ISChat
local ISChat = ISChat


---Provides client API access to OmiChat.
---Includes utilities for interfacing with the chat and extending mod functionality.
---@class omichat.api.client : omichat.api.shared
---@field package commandStreams omichat.CommandStream[]
---@field package emotes table<string, string | omichat.EmoteGetter>
---@field package formatters table<string, omichat.MetaFormatter>
---@field package iconsToExclude table<string, true>
---@field package transformers omichat.MessageTransformer[]
---@field package iniVersion integer
local OmiChat = OmiChatShared:derive()
OmiChat.ColorModal = ColorModal
OmiChat.IconPicker = IconPicker

OmiChat.iniVersion = 1

---@type table<string, true>
OmiChat.iconsToExclude = {}

---@type table<string, omichat.MetaFormatter>
OmiChat.formatters = {}

---@type omichat.CommandStream[]
OmiChat.commandStreams = {
    {
        name = 'name',
        command = '/name ',
        omichat = {
            isCommand = true,
            helpText = 'UI_OmiChat_helptext_name_no_reset',
            isEnabled = function() return Option.AllowSetName end,
            onUse = function(self, command)
                local op, name = OmiChat.setNickname(command)

                local feedback
                if op then
                    feedback = concat { 'UI_OmiChat_', op, '_name_success' }
                else
                    feedback = 'UI_OmiChat_set_name_failure'
                end

                OmiChat.showInfoMessage(getText(feedback, name))
            end,
            onHelp = function()
                local msg = 'UI_OmiChat_helptext_name'
                if Option.UseChatNameAsCharacterName then
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
            isEnabled = function() return Option.AllowEmotes end,
            onUse = function(self) self.omichat.onHelp() end,
            onHelp = function()
                -- collect currently available emotes
                local emotes = {}
                for k, v in pairs(OmiChat.emotes) do
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

                    for _, stream in pairs(OmiChat.commandStreams) do
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

                for _, stream in pairs(OmiChat.commandStreams) do
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
OmiChat.transformers = {
    {
        name = 'decode-me',
        priority = 8,
        transform = function(self, info)
            if info.chatType ~= 'say' or not Option.AllowMe then
                return
            end

            local meFormatter = OmiChat.getFormatter('me')
            if not meFormatter:isMatch(info.rawText) then
                return
            end

            -- it's a /me, mario
            info.rawText = meFormatter:read(info.rawText)
            info.format = Option.MeChatFormat
            info.context.isMeMessage = true
            info.formatOptions.color = OmiChat.getColor('me') or Option:getDefaultColor('me')
            info.formatOptions.useChatColor = false
            info.formatOptions.useNameColor = info.formatOptions.useNameColor and Option.UseNameColorInAllChats
            info.formatOptions.stripColors = true

            -- some actions could feasibly be heard, but generally descriptions of actions should not be
            info.message:setShouldAttractZombies(false)

            if Option.MeOverheadFormat == '' then
                info.message:setOverHeadSpeech(false)
            end
        end,
    },
    {
        name = 'decode-whisper',
        priority = 8,
        transform = function(self, info)
            if info.chatType ~= 'say' or not Option.UseLocalWhisper then
                return
            end

            local whisperFormatter = OmiChat.getFormatter('whisper')
            if not whisperFormatter:isMatch(info.rawText) then
                return
            end

            info.rawText = whisperFormatter:read(info.rawText)
            info.format = Option.WhisperChatFormat
            info.titleID = 'UI_OmiChat_whisper_chat_title_id'
            info.context.isWhisperMessage = true
            info.formatOptions.color = OmiChat.getColor('whisper') or Option:getDefaultColor('whisper')
            info.formatOptions.useChatColor = false
            info.formatOptions.useNameColor = info.formatOptions.useNameColor and Option.UseNameColorInAllChats

            -- whispering should not attract zombies
            info.message:setShouldAttractZombies(false)

            if Option.WhisperOverheadFormat == '' then
                info.message:setOverHeadSpeech(false)
            end
        end,
    },
    {
        name = 'set-range',
        priority = 6,
        transform = function(self, info)
            local range
            local defaultRange
            if info.context.isMeMessage then
                range = Option.MeRange
                defaultRange = Option:getDefault('SayRange')
            elseif info.context.isWhisperMessage then
                range = Option.WhisperRange
                defaultRange = Option:getDefault('SayRange')
            elseif info.chatType == 'say' then
                range = Option.SayRange
                defaultRange = Option:getDefault('SayRange')
            elseif info.chatType == 'shout' then
                range = Option.ShoutRange
                defaultRange = Option:getDefault('ShoutRange')
            else
                return
            end

            -- default ranges are existing chat ranges, so this avoids unnecessary work
            if range == defaultRange then
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
            end
        end,
    },
    {
        name = 'private-chat',
        priority = 6,
        transform = function(self, info)
            if info.chatType ~= 'whisper' then
                return
            end

            local bracketStart, msgStart, other = info.rawText:find('%[to ([^%]]+)%]:')
            if other and bracketStart == info.rawText:find('%[') then
                info.content = info.rawText:sub(msgStart + 1)
                info.format = Option.OutgoingPrivateChatFormat
                info.substitutions.recipient = other
                info.substitutions.recipientName = OmiChat.getNameInChat(other, 'whisper') or other
            else
                -- defer to basic chat format handler
                info.context.isIncomingPrivateMessage = true
            end

            local color = OmiChat.getColor('private')
            if color then
                info.formatOptions.color = color
                info.formatOptions.useChatColor = false
            end
        end,
    },
    {
        name = 'basic-chats',
        priority = 2,
        basicChatFormats = {
            say = 'SayChatFormat',
            shout = 'ShoutChatFormat',
            general = 'GeneralChatFormat',
            admin = 'AdminChatFormat',
            faction = 'FactionChatFormat',
            safehouse = 'SafehouseChatFormat',
        },
        transform = function(self, info)
            if not self.basicChatFormats[info.chatType] and not info.context.isIncomingPrivateMessage then
                return
            end

            -- grab text after the author
            local authorPattern = concat { '%[', utils.escape(info.author), '%]:' }
            local _, authorEnd = info.rawText:find(authorPattern)

            if authorEnd then
                info.content = info.rawText:sub(authorEnd + 1)
            end

            if info.message:isFromDiscord() then
                info.format = Option.DiscordChatFormat

                -- avoid applying name colors to discord usernames that match player usernames
                info.formatOptions.useNameColor = false
            end

            if not info.format then
                if info.context.isIncomingPrivateMessage then
                    info.format = Option.IncomingPrivateChatFormat
                else
                    info.format = Option[self.basicChatFormats[info.chatType]]
                end
            end
        end,
    },
    {
        name = 'radio-chat',
        priority = 2,
        transform = function(self, info)
            if info.chatType ~= 'radio' then
                return
            end

            local _, msgStart, freq = info.rawText:find('Radio%s*%((%d+%.%d+)[^%)]+%)%s*:')
            if msgStart then
                info.content = info.rawText:sub(msgStart + 1)
                info.format = Option.RadioChatFormat
                info.substitutions.frequency = freq

                -- /whisper messages should display normally
                local whisperFormatter = OmiChat.getFormatter('whisper')
                if whisperFormatter:isMatch(info.content) then
                    info.content = whisperFormatter:read(info.content)
                end
            end

            -- /me messages on radio shouldn't show up in chat
            if OmiChat.getFormatter('me'):isMatch(info.rawText) then
                info.formatOptions.showInChat = false
            end
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
            info.format = Option.ServerChatFormat
        end,
    },
}

---@type table<string, string | omichat.EmoteGetter>
OmiChat.emotes = {
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


--#region definitions

---@type table<string, omichat.ChatStreamConfig>
local streamOverrides

---@type table<string, omichat.ChatStream>
local customStreams

---@type omichat.PlayerPreferences
local playerPrefs

local iniName = 'omichat.ini'

do
    ---Helper for checking if a basic chat stream is enabled.
    ---@param self omichat.BaseStream
    ---@return boolean
    local function chatIsEnabled(self)
        return checkPlayerCanUseChat(self.command)
    end

    ---Helper for handling basic chat stream use.
    ---@param self omichat.ChatStream
    ---@param command string
    local function chatOnUse(self, command)
        command = utils.trim(command)
        if #command == 0 then
            return
        end

        local ctx = self.omichat.context
        if ctx and ctx.process then
            ctx.process(command)
        else
            processSayMessage(command)
        end
    end

    ---Helper for handling formatted chat stream use.
    ---@param self omichat.ChatStream
    ---@param command string
    local function formattedChatOnUse(self, command)
        command = utils.trim(command)
        if #command == 0 then
            return
        end

        local ctx = self.omichat.context
        local name = ctx and ctx.formatterName or self.name

        chatOnUse(self, OmiChat.getFormatter(name):format(command))
    end

    streamOverrides = {
        say = {
            context = { process = processSayMessage },
            allowEmojiPicker = true,
            isEnabled = chatIsEnabled,
            onUse = chatOnUse,
        },
        yell = {
            context = { process = processShoutMessage },
            isEnabled = chatIsEnabled,
            onUse = chatOnUse,
        },
        private = {
            allowEmotes = false,
            isEnabled = function() return checkPlayerCanUseChat('/w') end,
            onUse = function(self, command)
                local username = proceedPM(command)
                local chatText = ISChat.instance.chatText
                chatText.lastChatCommand = concat { chatText.lastChatCommand, username, ' ' }
            end,
        },
        faction = {
            allowEmotes = false,
            context = { process = proceedFactionMessage },
            isEnabled = chatIsEnabled,
            onUse = chatOnUse,
        },
        safehouse = {
            allowEmotes = false,
            context = { process = processSafehouseMessage },
            isEnabled = chatIsEnabled,
            onUse = chatOnUse,
        },
        general = {
            allowEmotes = false,
            context = { process = processGeneralMessage },
            isEnabled = chatIsEnabled,
            onUse = chatOnUse,
        },
        admin = {
            allowEmotes = false,
            context = { process = processAdminChatMessage },
            isEnabled = chatIsEnabled,
            onUse = chatOnUse,
        }
    }

    customStreams = {
        me = {
            name = 'me',
            command = '/me ',
            shortCommand = '/m ',
            tabID = 1,
            omichat = {
                allowEmotes = true,
                allowEmojiPicker = true,
                isEnabled = function() return Option.AllowMe end,
                onUse = formattedChatOnUse,
            },
        },
        whisper = {
            name = 'whisper',
            command = '/whisper ',
            shortCommand = '/w ',
            tabID = 1,
            omichat = {
                allowEmotes = true,
                allowEmojiPicker = true,
                context = { isLocalWhisper = true },
                isEnabled = function() return Option.UseLocalWhisper end,
                onUse = formattedChatOnUse,
            }
        }
    }
end

---Fake server message.
local InfoMessage = {
    isServerAlert = function() return false end,
    getText = function(self) return self.text end,
    getTextWithPrefix = function(self)
        local instance = ISChat.instance

        local tag
        if instance.showTitle then
            tag = utils.interpolate(Option.TagFormat, {
                chatType = 'server',
                tag = getText('UI_chat_server_chat_title_id'),
            })
        end

        return concat {
            utils.toChatColor(OmiChat.getColorTable('server')),
            '<SIZE:', instance.chatFont or 'medium', '> ',
            tag or '',
            utils.interpolate(Option.ServerChatFormat, { message = self.text })
        }
    end,
    new = function(self, text, isServerAlert)
        return setmetatable({
            text = tostring(text),
            isServerAlert = isServerAlert
        }, self)
    end,
}
InfoMessage.__index = InfoMessage


---Inserts a chat stream relative to another.
---If the other chat stream isn't found, inserts at the end.
---@param stream omichat.ChatStream
---@param other omichat.ChatStream?
---@param value integer The relative index.
---@return omichat.ChatStream
local function insertStreamRelative(stream, other, value)
    if not other then
        return OmiChat.addStream(stream)
    end

    local pos = #ISChat.allChatStreams + 1
    for i, chatStream in ipairs(ISChat.allChatStreams) do
        if chatStream == other then
            pos = i + value
            break
        end
    end

    table.insert(ISChat.allChatStreams, pos, stream)

    local tabs = ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for _, tab in ipairs(tabs) do
        if stream.tabID == tab.tabID + 1 then
            pos = #tab.chatStreams + 1
            for i, chatStream in ipairs(tab.chatStreams) do
                if chatStream == other then
                    pos = i + value
                    break
                end
            end

            table.insert(tab.chatStreams, pos, stream)
        end
    end

    return stream
end

---Creates a built-in formatter and assigns a constant ID.
---@param fmt string
---@param id integer
local function createFormatter(fmt, id)
    -- not using `new` directly to avoid ID assignment
    ---@type omichat.MetaFormatter
    local formatter = setmetatable({}, OmiChat.MetaFormatter)

    formatter:init(fmt)
    formatter:setID(id)

    return formatter
end

---Creates or updates built-in formatters.
local function updateFormatters()
    local formatterDefs = {
        { name = 'me', opt = 'MeOverheadFormat' },
        { name = 'whisper', opt = 'WhisperOverheadFormat' },
    }

    for idx, info in ipairs(formatterDefs) do
        local fmtName = info.name
        local opt = Option[info.opt]
        if OmiChat.formatters[fmtName] then
            OmiChat.formatters[fmtName]:setFormatString(opt)
        else
            OmiChat.formatters[fmtName] = createFormatter(opt, idx)
        end
    end
end

---Updates streams based on sandbox options.
local function updateStreams()
    -- grab references to insert new streams before default /whisper
    local me, private, whisper
    for _, stream in ipairs(ISChat.allChatStreams) do
        if stream.omichat then
            if stream.name == 'me' then
                me = stream
            elseif stream.name == 'private' then
                private = stream
            elseif stream.name == 'whisper' then
                if stream.omichat.context and stream.omichat.context.isLocalWhisper then
                    whisper = stream
                else
                    private = stream
                end
            end
        elseif stream.name == 'whisper' then
            private = stream
            private.omichat = streamOverrides.private
        elseif streamOverrides[stream.name] then
            stream.omichat = streamOverrides[stream.name]
        end
    end

    if not me then
        me = OmiChat.addStreamBefore(customStreams.me, private)
    end

    if Option.UseLocalWhisper and not whisper then
        if private then
            -- modify /whisper to be /private
            private.name = 'private'
            private.command = '/private '
            private.shortCommand = '/pm '
        end

        -- add custom /whisper
        OmiChat.addStreamBefore(customStreams.whisper, me or private)
    elseif not Option.UseLocalWhisper and whisper then
        if private then
            -- revert /private to /whisper
            private.name = 'whisper'
            private.command = '/whisper '
            private.shortCommand = '/w '
        end

        -- remove custom /whisper
        OmiChat.removeStream(whisper)
    end
end

---Creates or removes the emoji button and picker from the chat box based on sandbox options.
local function updateEmojiComponents()
    local add = Option.EnableEmojiPicker
    local instance = ISChat.instance

    local epIncludeMisc = instance.emojiPicker and instance.emojiPicker.includeUnknownAsMiscellaneous
    local includeMisc = Option.IncludeMiscellaneousEmoji
    if instance.emojiPicker and epIncludeMisc ~= includeMisc then
        instance.emojiPicker.includeUnknownAsMiscellaneous = includeMisc
        instance.emojiPicker:updateIcons()
    end

    if add and instance.emojiButton then
        return
    end

    if not add and not instance.emojiButton then
        return
    end

    if add then
        local size = math.floor(instance.textEntry.height * 0.75)
        instance.emojiButton = ISButton:new(
            instance.width - size * 1.25 - 2.5,
            instance.textEntry.y + instance.textEntry.height * 0.5 - size * 0.5 + 1,
            size,
            size,
            '',
            instance,
            ISChat.onEmojiButtonClick
        )

        instance.textEntry.width = instance.textEntry.width - size * 1.5
        instance.textEntry.javaObject:setWidth(instance.textEntry.width)

        instance.emojiButton.anchorRight = true
        instance.emojiButton.anchorBottom = true
        instance.emojiButton.anchorLeft = false
        instance.emojiButton.anchorTop = false

        instance.emojiButton:initialise()
        instance.emojiButton.borderColor.a = 0
        instance.emojiButton.backgroundColor.a = 0
        instance.emojiButton.backgroundColorMouseOver.a = 0
        instance.emojiButton:setImage(getTexture('Item_PlushSpiffo'))
        instance.emojiButton:setTextureRGBA(0.3, 0.3, 0.3, 1)
        instance.emojiButton:setUIName('chat emoji button')
        instance:addChild(instance.emojiButton)

        instance.emojiButton:bringToTop()

        instance.emojiPicker = IconPicker:new(0, 0, instance, ISChat.onEmojiClick)
        instance.emojiPicker.exclude = OmiChat.iconsToExclude
        instance.emojiPicker.includeUnknownAsMiscellaneous = OmiChat.Option.IncludeMiscellaneousEmoji

        instance.emojiPicker:initialise()
        instance.emojiPicker:addToUIManager()
        instance.emojiPicker:setVisible(false)

        return
    end

    instance.textEntry.width = instance:getWidth() - instance.inset * 2
    instance.textEntry.javaObject:setWidth(instance.textEntry.width)

    instance:removeChild(instance.emojiButton)
    instance.emojiButton:setVisible(false)
    instance.emojiButton:removeFromUIManager()
    instance.emojiButton = nil

    if instance.emojiPicker then
        instance.emojiPicker:setVisible(false)
        instance.emojiPicker:removeFromUIManager()
        instance.emojiPicker = nil
    end
end

---Removes an element from a table, shifting subsequent elements.
---@param tab table
---@param target unknown
---@return boolean
local function remove(tab, target)
    if target == nil then
        return false
    end

    local i = 1
    local found = false
    while i <= #tab and not found do
        found = tab[i] == target
        i = i + 1
    end

    if found then
        while i <= #tab do
            tab[i - 1] = tab[i]
            i = i + 1
        end

        tab[#tab] = nil
    end

    return found
end

--#endregion

--#region Data API

---@type table<omichat.CalloutCategory, string>
local shoutOpts = {
    callouts = 'AllowCustomShouts',
    sneakcallouts = 'AllowCustomSneakShouts',
}

---Gets or creates the player preferences table.
---@return omichat.PlayerPreferences
function OmiChat.getPlayerPreferences()
    if playerPrefs then
        return playerPrefs
    end

    ---@type omichat.PlayerPreferences
    local prefs = {
        showNameColors = true,
        colors = {},
        callouts = {},
        sneakcallouts = {},
    }

    local line, dest
    local inFile = getFileReader(iniName, true)
    while true do
        line = inFile:readLine()
        if line == nil then
            inFile:close()
            break
        end

        if line:sub(1, 1) == '[' then
            local target = line:sub(2, line:find(']') - 1)
            if prefs[target] then
                dest = prefs[target]
            end
        else
            local eq = string.find(line, '=')
            local key = line:sub(1, eq - 1)
            local value = line:sub(eq + 1)

            if not dest and key == 'showNameColors'then
                prefs.showNameColors = value == 'true'
            elseif dest == prefs.colors then
                dest[key] = utils.stringToColor(value)
            elseif tonumber(key) then
                dest[tonumber(key)] = value
            elseif dest then
                ---@cast dest table
                dest[key] = value
            end
        end
    end

    playerPrefs = prefs
end

---Saves current player preferences to a file.
function OmiChat.savePlayerPreferences()
    local outFile = getFileWriter(iniName, true, false)
    outFile:write(concat { 'VERSION=', tostring(OmiChat.iniVersion), '\n' })

    outFile:write(concat { 'showNameColors=', tostring(playerPrefs.showNameColors), '\n' })

    outFile:write(concat {'[colors]\n'})
    for cat, color in pairs(playerPrefs.colors) do
        outFile:write(concat { cat, '=', utils.colorToHexString(color), '\n' })
    end

    for _, name in pairs({ 'callouts', 'sneakcallouts' }) do
        outFile:write(concat {'[', name, ']\n'})

        for k, v in pairs(playerPrefs[name]) do
            outFile:write(concat { tostring(k), '=', tostring(v), '\n' })
        end
    end

    outFile:close()
end

---Updates the current player's character name.
---@param name string The new full name of the character. This will be split into forename and surname.
---@param surname string? The character surname. If provided, `name` will be interpreted as the forename.
function OmiChat.updateCharacterName(name, surname)
    if #name == 0 then
        return
    end

    local player = getSpecificPlayer(0)
    local desc = player and player:getDescriptor()
    if not desc then
        return
    end

    local forename = name
    if not surname then
        surname = ''

        local parts = name:split(' ')
        if #parts > 1 then
            forename = concat(parts, ' ', 1, #parts - 1)
            surname = parts[#parts]
        end
    end

    desc:setForename(forename)
    desc:setSurname(surname)

    -- update name in inventory
    player:getInventory():setDrawDirty(true)
    getPlayerData(player:getPlayerNum()).playerInventory:refreshBackpacks()

    sendPlayerStatsChange(player)
end

---Gets the nickname for the current player, if one is set.
---@return string?
function OmiChat.getNickname()
    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if not username then
        return
    end

    local modData = OmiChat.getModData()
    return modData.nicknames[username]
end

---Sets the nickname of the current player.
---@param nickname string? The nickname to set. A nil or empty value will unset the nickname.
---@return 'reset' | 'set' | nil #The operation that was completed.
---@return string? #The nickname that was set.
function OmiChat.setNickname(nickname)
    nickname = utils.trim(nickname or '')

    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if not username then
        return
    end

    local maxLength = Option.NameMaxLength
    if maxLength > 0 and #nickname > maxLength then
        nickname = nickname:sub(1, maxLength)
    end

    local modData = OmiChat.getModData()

    if #nickname == 0 then
        modData.nicknames[username] = nil
        modData._updates = { nicknameToClear = username }
        ModData.transmit(OmiChat.modDataKey)
    end

    if Option.UseChatNameAsCharacterName then
        if #nickname == 0 then
            return
        end

        OmiChat.updateCharacterName(nickname)
        return 'set', nickname
    end

    -- reset nickname
    if #nickname == 0 then
        return 'reset'
    end

    modData.nicknames[username] = nickname
    modData._updates = { nicknameToUpdate = username }
    ModData.transmit(OmiChat.modDataKey)
    return 'set', nickname
end

---Sets the color used for overhead chat bubbles.
---This will set the speech color in-game option.
---@param color omichat.ColorTable?
function OmiChat.changeSpeechColor(color)
    if not color or not Option.AllowSetSpeechColor then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255

    local core = getCore()
    core:setMpTextColor(ColorInfo.new(r, g, b, 1))
    core:saveOptions()
    player:setSpeakColourInfo(core:getMpTextColor())
    sendPersonalColor(player)
end

---Sets the color associated with a given color category for the current player,
---if the related option is enabled.
---Client only.
---@param category omichat.ColorCategory
---@param color omichat.ColorTable?
function OmiChat.changeColor(category, color)
    if category == 'speech' then
        return OmiChat.changeSpeechColor(color)
    end

    if category ~= 'name' then
        -- no syncing necessary for chat colors; just set in player preferences
        local prefs = OmiChat.getPlayerPreferences()
        prefs.colors[category] = color
        OmiChat.savePlayerPreferences()

        return
    end

    if not Option.AllowSetNameColor then
        return
    end

    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if not username then
        return
    end

    local modData = OmiChat.getModData()

    modData.nameColors[username] = color and utils.colorToHexString(color) or nil
    modData._updates = { nameColorToUpdate = username }

    ModData.transmit(OmiChat.modDataKey)
end

---Gets a color table for the current player, or nil if unset.
---@param category omichat.ColorCategory
---@return omichat.ColorTable?
function OmiChat.getColor(category)
    if category == 'name' then
        local player = getSpecificPlayer(0)
        return OmiChat.getNameColor(player and player:getUsername())
    end

    if category == 'speech' then
        return OmiChat.getSpeechColor()
    end

    if not Option.AllowSetChatColors then
        return
    end

    local prefs = OmiChat.getPlayerPreferences()
    return prefs.colors[category]
end

---Retrieves the player's custom shouts.
---@param shoutType omichat.CalloutCategory The type of shouts to retrieve.
---@return string[]?
function OmiChat.getCustomShouts(shoutType)
    if not Option[shoutOpts[shoutType]] then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local prefs = OmiChat.getPlayerPreferences()
    return prefs[shoutType]
end

---Retrieves a boolean for whether the current player has name colors enabled.
---@return boolean
function OmiChat.getNameColorsEnabled()
    return OmiChat.getPlayerPreferences().showNameColors
end

---Returns a color table for the current player's speech color.
---@return omichat.ColorTable?
function OmiChat.getSpeechColor()
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local speechColor = player:getSpeakColour()
    if not speechColor then
        return
    end

    return {
        r = speechColor:getRed(),
        g = speechColor:getGreen(),
        b = speechColor:getBlue(),
    }
end

---Sets the player's custom shouts.
---@param shouts string[]?
---@param shoutType omichat.CalloutCategory The type of shouts to set.
function OmiChat.setCustomShouts(shouts, shoutType)
    if not Option[shoutOpts[shoutType]] then
        return
    end

    local prefs = OmiChat.getPlayerPreferences()

    if not shouts then
        prefs[shoutType] = nil
    else
        prefs[shoutType] = shouts
    end

    OmiChat.savePlayerPreferences()
end

---Sets whether the current player has name colors enabled.
---@param enabled boolean True to enable, false to disable.
function OmiChat.setNameColorEnabled(enabled)
    OmiChat.getPlayerPreferences().showNameColors = not not enabled
    OmiChat.savePlayerPreferences()
end

--#endregion

--#region Chat API

---Adds information about a command that can be triggered from chat.
---@param stream omichat.CommandStream
function OmiChat.addCommand(stream)
    if not stream.omichat then
        stream.omichat = {}
    end

    stream.omichat.isCommand = true
    OmiChat.commandStreams[#OmiChat.commandStreams+1] = stream
end

---Removes a stream from the list of available chat commands.
---@param stream omichat.CommandStream
function OmiChat.removeCommand(stream)
    if not stream then
        return
    end

    remove(OmiChat.commandStreams, stream)
end

---Adds a chat stream.
---@param stream omichat.ChatStream
---@return omichat.ChatStream
function OmiChat.addStream(stream)
    ISChat.allChatStreams[#ISChat.allChatStreams+1] = stream

    local tabs = ISChat.instance.tabs
    if not tabs then
        return stream
    end

    for _, tab in ipairs(tabs) do
        if stream.tabID == tab.tabID + 1 then
            tab.chatStreams[#tab.chatStreams+1] = stream
        end
    end

    return stream
end

---Adds a chat stream after an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
function OmiChat.addStreamAfter(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 1)
end

---Adds a chat stream before an existing stream.
---If no stream is provided or it isn't found, the stream is added at the end.
---@param stream omichat.ChatStream The stream to add.
---@param otherStream omichat.ChatStream?
function OmiChat.addStreamBefore(stream, otherStream)
    return insertStreamRelative(stream, otherStream, 0)
end

---Removes a stream from the list of available chat streams.
---@param stream omichat.ChatStream
function OmiChat.removeStream(stream)
    if not stream then
        return
    end

    -- remove from all streams table
    remove(ISChat.allChatStreams, stream)

    -- remove from tab streams
    local tabs = ISChat.instance.tabs
    if tabs then
        remove(tabs, stream)
    end
end

---Adds an emote that is playable from chat with the .emote syntax.
---@param name string The name of the emote, as it can be used from chat.
---@param emoteOrGetter string | omichat.EmoteGetter The string to associate with the emote, or a function which retrieves one.
function OmiChat.addEmote(name, emoteOrGetter)
    if type(emoteOrGetter) == 'function' then
        OmiChat.emotes[name] = emoteOrGetter
    elseif emoteOrGetter then
        OmiChat.emotes[name] = tostring(emoteOrGetter)
    end
end

---Removes an emote from the registry.
---@param name string
function OmiChat.removeEmote(name)
    OmiChat.emotes[name] = nil
end

---Adds a message transformer which can act on message information
---to modify display or behavior.
---@param transformer omichat.MessageTransformer
function OmiChat.addMessageTransform(transformer)
    OmiChat.transformers[#OmiChat.transformers+1] = transformer

    -- not stable sorting
    table.sort(OmiChat.transformers, function(a, b)
        local aPri = a.priority or 1
        local bPri = b.priority or 1

        return aPri > bPri
    end)
end

---Removes a message transformer.
---@param transformer omichat.MessageTransformer
function OmiChat.removeMessageTransform(transformer)
    remove(OmiChat.transformers, transformer)
end

---Removes the first message transformer with the provided name.
---@param name string
function OmiChat.removeMessageTransformByName(name)
    local target
    for _, v in ipairs(OmiChat.transformers) do
        if v.name and v.name == name then
            target = v
            break
        end
    end

    if target then
        remove(OmiChat.transformers, target)
    end
end

---Applies format options from a message information table.
---This mutates `info`.
---@param info omichat.MessageInfo
---@return boolean #If false, the information table is invalid.
function OmiChat.applyFormatOptions(info)
    local meta = info.meta
    local options = info.formatOptions
    local message = info.message

    local msg = info.content
    if not msg or not info.format then
        return false
    end

    if options.showTimestamp then
        local hour, minute = tostring(message:getDatetime()):match('[^T]*T(%d%d):(%d%d)')

        hour = tonumber(hour)
        minute = tonumber(minute)

        if hour and minute then
            local hour12 = hour % 12
            if hour12 == 0 then
                hour12 = 12
            end

            local ampm = hour < 12 and 'am' or 'pm'
            info.timestamp = utils.interpolate(Option.TimestampFormat, {
                chatType = info.chatType,
                H = format('%d', hour),
                HH = format('%02d', hour),
                h = format('%d', hour12),
                hh = format('%02d', hour12),
                m = format('%d', minute),
                mm = format('%02d', minute),
                ampm = ampm,
                AMPM = ampm:upper(),
                hourFormatPref = getCore():getOptionClock24Hour() and 24 or 12,
            })
        end
    end

    if options.showTitle then
        info.tag = utils.interpolate(Option.TagFormat, {
            chatType = info.chatType,
            tag = getText(info.titleID),
        })
    end

    if options.stripColors then
        msg = msg:gsub('<RGB:%d%.%d+,%d%.%d+,%d%.%d+>', '')
    end

    local shouldUseNameColor = info.chatType == 'say' or Option.UseNameColorInAllChats
    if shouldUseNameColor and options.useNameColor and OmiChat.getNameColorsEnabled() then
        local selectedColor = Option.AllowSetNameColor and meta.nameColor
        local colorToUse = selectedColor or Option:getDefaultColor('name', message:getAuthor())
        local nameColor = utils.toChatColor(colorToUse, true)

        info.substitutions.name = concat {
            nameColor,
            info.substitutions.name,
            ' <POPRGB> '
        }
        info.substitutions.author = concat {
            nameColor,
            info.substitutions.author,
            ' <POPRGB> '
        }
    end

    msg = utils.trim(msg)
    if not options.color then
        local color
        if options.useChatColor then
            if message:isFromDiscord() then
                color = OmiChat.getColor('discord')
            else
                color = OmiChat.getColor(info.chatType)
            end
        end

        options.color = color or {
            r = info.textColor:getRed(),
            g = info.textColor:getGreen(),
            b = info.textColor:getBlue(),
        }
    end

    info.substitutions.message = msg
    return true
end

---Applies message transforms.
---@param info omichat.MessageInfo
function OmiChat.applyTransforms(info)
    for _, transformer in ipairs(OmiChat.transformers) do
        if transformer.transform and transformer:transform(info) == true then
            break
        end
    end
end

---Determines stream information given a chat command.
---@param command string The input text.
---@param includeCommands boolean? If true, commands should be included. Defaults to true.
---@return (omichat.ChatStream | omichat.CommandStream)? #The stream.
---@return string #The text following the command in the input.
---@return string? #The command or short command that was used.
function OmiChat.chatCommandToStream(command, includeCommands)
    if not command or command == '' then
        return nil, ''
    end

    if includeCommands == nil then
        includeCommands = true
    end

    local chatStream
    local chatCommand

    local i = 1
    local numStreams = #ISChat.allChatStreams
    local numCommands = #OmiChat.commandStreams
    while i <= numStreams + numCommands do
        local stream
        if i <= numStreams then
            stream = ISChat.allChatStreams[i]
        else
            if not includeCommands then
                break
            end

            stream = OmiChat.commandStreams[i - numStreams]
        end

        chatCommand = nil
        if utils.startsWith(command, stream.command) then
            chatCommand = stream.command
            command = command:sub(#chatCommand)
        elseif utils.startsWith(command, stream.shortCommand) then
            chatCommand = stream.shortCommand
            command = command:sub(#chatCommand)
        elseif stream.omichat and stream.omichat.isCommand and command == utils.trim(stream.command) then
            chatCommand = command
            command = ' '
        end

        if chatCommand then
            chatStream = stream
            break
        end

        i = i + 1
    end

    return chatStream, command, chatCommand
end

---Retrieves a stream name given a chat command.
---@param command string A chat stream's command, with the leading slash.
---@param includeCommands boolean? If true, commands should be included.
---@return string? #The name of the chat stream, or nil if not found.
function OmiChat.chatCommandToStreamName(command, includeCommands)
    local stream = OmiChat.chatCommandToStream(command, includeCommands)
    if stream then
        return stream.name
    end
end

---Clears all of the current chat messages.
function OmiChat.clearMessages()
    for _, chatText in ipairs(ISChat.instance.tabs) do
        chatText.chatMessages = {}
        chatText.chatTextLines = {}
        chatText.text = ''
        chatText:paginate()
    end
end

---Cycles to the next chat stream.
---This is used with onSwitchStream.
---@param target string? The name of a target stream to switch to instead of the next stream.
---@return string #The command of the new current stream.
function OmiChat.cycleStream(target)
    local curChatText = ISChat.instance.chatText
    local chatStreams = curChatText.chatStreams

    local targetID
    local streamID = curChatText.streamID

    for _ = 0, #chatStreams do
        streamID = streamID % #chatStreams + 1
        local stream = chatStreams[streamID]

        if not target or stream.name == target then
            if stream.omichat then
                local isEnabled = stream.omichat.isEnabled
                if not isEnabled or isEnabled(stream) then
                    targetID = streamID
                    break
                end
            elseif checkPlayerCanUseChat(stream.command) then
                targetID = streamID
                break
            end
        end
    end

    if targetID then
        curChatText.streamID = targetID
    end

    return curChatText.chatStreams[curChatText.streamID].command
end

---Returns a color table associated with the current player,
---or the default color table if there isn't one.
---@param category omichat.ColorCategory
---@return omichat.ColorTable
function OmiChat.getColorTable(category)
    return OmiChat.getColor(category) or Option:getDefaultColor(category)
end

---Returns a playable emote given an emote name.
---Returns nil if there is not an emote associated with the emote name.
---@param emote string
---@return string?
function OmiChat.getEmote(emote)
    local value = OmiChat.emotes[emote]
    if type(value) == 'function' then
        return value(emote)
    end

    return value
end

---Gets a named formatter.
---@param name omichat.FormatterName
---@return omichat.MetaFormatter
function OmiChat.getFormatter(name)
    return OmiChat.formatters[name]
end

---Redraws the current chat messages.
---@param doScroll boolean? Whether the chat should also be scrolled to the bottom. Defaults to true.
function OmiChat.redrawMessages(doScroll)
    for _, chatText in ipairs(ISChat.instance.tabs) do
        local newText = {}
        local newLines = {}

        for i, msg in ipairs(chatText.chatMessages) do
            local text = msg:getTextWithPrefix()

            newText[#newText+1] = text
            newLines[#newLines+1] = text .. ' <LINE> '

            if i ~= #chatText.chatMessages then
                newText[#newText+1] = ' <LINE> '
            end
        end

        chatText.chatTextLines = newLines
        chatText.text = concat(newText)

        chatText:paginate()
    end

    if doScroll ~= false then
        -- fix scroll position
        OmiChat.scrollToBottom()
    end
end

---Sets the scroll position of all chat tabs to the bottom.
function OmiChat.scrollToBottom()
    if not ISChat.instance.tabs then
        return
    end

    for _, tab in ipairs(ISChat.instance.tabs) do
        tab:setYScroll(-tab:getScrollHeight())
    end
end

---Sets the scroll position of all chat tabs to the top.
function OmiChat.scrollToTop()
    if not ISChat.instance.tabs then
        return
    end

    for _, tab in ipairs(ISChat.instance.tabs) do
        tab:setYScroll(0)
    end
end

---Sets the icons that should be excluded by the icon picker.
---This does not update the icon picker icons. 
---@see omichat.IconPicker.updateIcons
---@param icons table<string, true>?
function OmiChat.setIconsToExclude(icons)
    OmiChat.iconsToExclude = icons or {}
end

---Adds an info message to chat.
---This displays only for the local user.
---@param text string
function OmiChat.showInfoMessage(text)
    ISChat.addLineInChat(InfoMessage:new(text), ISChat.instance.currentTabID - 1)
end

---Updates state to match sandbox variables.
---@param redraw boolean? If true, chat messages will be redrawn.
function OmiChat.updateState(redraw)
    if not ISChat.instance then
        return
    end

    OmiChat.getPlayerPreferences()
    updateStreams()
    updateFormatters()
    updateEmojiComponents()

    if redraw then
        -- some sandbox vars affect how messages are drawn
        OmiChat.redrawMessages(false)
    end
end

--#endregion

--#region Types

---Function to retrieve a playable emote string given an emote name.
---@alias omichat.EmoteGetter fun(emoteName: string): string?

---The names of built-in formatters.
---@see omichat.api.getFormatter
---@alias omichat.FormatterName
---| 'me'
---| 'whisper'

---Categories for custom callouts.
---@alias omichat.CalloutCategory 'callouts' | 'sneakcallouts'

---Categories for colors that can be customized by players.
---@alias omichat.ColorCategory
---| 'general'
---| 'whisper'
---| 'say'
---| 'shout'
---| 'faction'
---| 'safehouse'
---| 'radio'
---| 'admin'
---| 'server'
---| 'me'
---| 'private'
---| 'discord'
---| 'name'
---| 'speech'

---Valid values for the chat's font.
---@alias omichat.ChatFont 'small' | 'medium' | 'large'


---Metadata that can be attached to a message.
---@class omichat.MessageMetadata
---@field name string?
---@field nameColor omichat.ColorTable?

---Options for how to format a message in chat.
---@class omichat.MessageFormatOptions
---@field showInChat boolean
---@field showTitle boolean
---@field showTimestamp boolean
---@field useChatColor boolean
---@field useNameColor boolean
---@field stripColors boolean
---@field font omichat.ChatFont
---@field color omichat.ColorTable?

---Information used during message transformation and formatting.
---@class omichat.MessageInfo
---@field message ChatMessage
---@field content string? The message content to display in chat. Set by transformers.
---@field format string? The string format to use for the message. Set by transformers.
---@field tag string?
---@field timestamp string?
---@field textColor Color The message's default text color.
---@field meta omichat.MessageMetadata
---@field rawText string The raw text of the message.
---@field author string The username of the message author.
---@field titleID string The string ID of the chat type's tag.
---@field chatType omichat.ChatTypeString The chat type of the message's chat.
---@field context table Table for arbitrary context data.
---@field substitutions table<string, any> Message substitution values.
---@field formatOptions omichat.MessageFormatOptions

---Transforms messages based on context and format strings.
---@class omichat.MessageTransformer
---@field name string?
---@field transform fun(self: table, info: omichat.MessageInfo): true?
---@field priority integer?

---Description of the `omichat` field on stream tables.
---@class omichat.BaseStreamConfig
---@field context table?
---@field isCommand boolean? Field added to signify that a stream is a command.
---@field isEnabled (fun(self: table): boolean)? Returns a boolean representing whether the stream is enabled.
---@field onUse fun(self: table, command: string)? Callback triggered when the stream is used.
---@field allowEmotes boolean? Whether to allow emotes on this stream. Defaults to true for non-commands and false for commands.
---@field allowEmojiPicker boolean? Whether to enable the emoji button for this stream. Defaults to false.
---@field allowRetain boolean? Whether to allow retaining this stream's command for subsequent inputs. Defaults to true for non-commands and false for commands.

---Description of the `omichat` field on chat stream tables.
---@class omichat.ChatStreamConfig : omichat.BaseStreamConfig

---Description of the `omichat` field on command stream tables.
---@class omichat.CommandStreamConfig : omichat.BaseStreamConfig
---@field helpText string? Summary of the command's purpose. Displays when the /help command is used.
---@field onHelp fun(self: table)? Callback triggered when /help is used with this command.

---Base stream object for chat and command streams.
---@class omichat.BaseStream
---@field name string
---@field command string
---@field shortCommand string?
---@field omichat omichat.ChatStreamConfig?

---A stream used for communicating in chat.
---@class omichat.ChatStream : omichat.BaseStream
---@field tabID integer

---A stream used to invoke a command in chat.
---@class omichat.CommandStream : omichat.BaseStream
---@field omichat omichat.CommandStreamConfig

---Player preferences.
---@class omichat.PlayerPreferences
---@field showNameColors boolean
---@field callouts string[]
---@field sneakcallouts string[]
---@field colors table<omichat.ColorCategory, omichat.ColorTable>

--#endregion


---@protected
function OmiChat._onGameStart()
    OmiChat.updateState()

    local name = Option.UseChatNameAsCharacterName and OmiChat.getNickname()
    if name then
        -- set existing nickname to character name and clear it
        OmiChat.setNickname()
        OmiChat.updateCharacterName(name)
    end
end

Events.OnGameStart.Add(OmiChat._onGameStart)
return OmiChat
