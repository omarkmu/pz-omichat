---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local concat = table.concat
local char = string.char
local getText = getText
local instanceof = instanceof

local utils = OmiChat.utils
local Option = OmiChat.Option
local config = OmiChat.config


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

---@type omichat.MessageTransformer[]
return {
    {
        name = 'radio-chat',
        priority = 75,
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
            info.tokens.frequency = freq
        end,
    },
    {
        name = 'cleanup-author-metadata',
        priority = 70,
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
        priority = 65,
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
        priority = 60,
        transform = function(_, info)
            local text = info.content or info.rawText
            local formatter = OmiChat.getFormatter('echo')

            local matched = formatter:read(text)
            if not matched then
                return
            end

            if Option.ChatFormatEcho ~= '' then
                info.tokens.echo = '1'
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
        priority = 55,
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
            info.tokens.card = utils.getTranslatedCardName(card, suit)

            info.format = Option.ChatFormatCard
            info.formatOptions.color = OmiChat.getColorOrDefault('me')
            info.formatOptions.useDefaultChatColor = false

            info.context.ocCustomStream = 'me'
            info.tokens.stream = 'card'
        end,
    },
    {
        name = 'decode-roll',
        priority = 50,
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
            info.tokens.roll = roll
            info.tokens.sides = sides

            info.format = Option.ChatFormatRoll
            info.formatOptions.color = OmiChat.getColorOrDefault('me')
            info.formatOptions.useDefaultChatColor = false

            info.context.ocCustomStream = 'me'
            info.tokens.stream = 'roll'
        end,
    },
    {
        name = 'decode-callout',
        priority = 45,
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
                end
            else
                return
            end

            info.tokens.callout = '1'
            info.tokens.sneakCallout = info.context.ocIsSneakCallout and '1' or nil

            -- already created a sound for the callout
            info.message:setShouldAttractZombies(false)
        end,
    },
    {
        name = 'decode-stream',
        priority = 40,
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
                    info.tokens.stream = name

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
        priority = 35,
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
        priority = 30,
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
                info.tokens.language = utils.getTranslatedLanguageName(language)
                info.tokens.languageRaw = language
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
            info.tokens.unknownLanguage = language

            if isRadio then
                info.tokens.unknownLanguageString = 'UI_OmiChat_unknown_language_radio'
                info.format = Option.ChatFormatUnknownLanguageRadio
            elseif isWhisper then
                info.tokens.unknownLanguageString = 'UI_OmiChat_unknown_language_whisper' .. signedSuffix
                info.formatOptions.color = OmiChat.getColorOrDefault('mequiet')
                info.context.ocCustomStream = 'mequiet'
                info.tokens.stream = 'mequiet'
            elseif info.chatType == 'shout' then
                info.tokens.unknownLanguageString = 'UI_OmiChat_unknown_language_shout' .. signedSuffix
                info.formatOptions.color = OmiChat.getColorOrDefault('meloud')
                info.context.ocCustomStream = 'meloud'
                info.tokens.stream = 'meloud'
            else
                info.tokens.unknownLanguageString = 'UI_OmiChat_unknown_language_say' .. signedSuffix
                info.formatOptions.color = OmiChat.getColorOrDefault('me')
                info.context.ocCustomStream = 'me'
                info.tokens.stream = 'me'
            end
        end,
    },
    {
        name = 'decode-narrative',
        priority = 25,
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

            info.context.ocNarrativeTag = dialogueTag
            info.context.ocNarrativeContent = content
        end,
    },
    {
        name = 'apply-narrative',
        priority = 20,
        transform = function(_, info)
            local dialogueTag = info.context.ocNarrativeTag
            local content = info.context.ocNarrativeContent
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

            local tokens = { stream = info.tokens.stream }
            if range then
                info.attractRange = range * Option.RangeMultiplierZombies
                if not info.context.ocIsCallout and not info.context.ocIsSneakCallout then
                    info.message:setShouldAttractZombies(utils.testPredicate(Option.PredicateAttractZombies, tokens))
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
            tokens.callout = (info.context.ocIsCallout or info.context.ocIsSneakCallout) and '1' or nil
            tokens.sneakCallout = info.context.ocIsSneakCallout and '1' or nil

            local zMax = tonumber(utils.interpolate(Option.RangeVertical, tokens))
            if range and zMax and math.abs(authorPlayer:getZ() - localPlayer:getZ()) >= zMax then
                outOfRange = true
            elseif range and range ~= defaultRange then
                -- calculating distance using the distance formula like ChatUtility
                -- assuming players are synced it works equivalently
                local xDiff = authorPlayer:getX() - localPlayer:getX()
                local yDiff = authorPlayer:getY() - localPlayer:getY()

                outOfRange = math.sqrt(xDiff * xDiff + yDiff * yDiff) > range
            end

            if outOfRange then
                -- show in chat value is only used on the initial message add,
                -- so it's okay that this runs on refresh
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

            local text = info.rawText
            local _, msgStart, other = text:find('%[to ([^%]]+)%]:')
            if other then
                if not info.content then
                    info.content = text:sub(msgStart + 1)
                end

                info.format = Option.ChatFormatOutgoingPrivate
                info.tokens.recipient = other
                info.tokens.recipientName = utils.escapeRichText(OmiChat.getNameInChat(other, 'whisper') or other)
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
                info.tokens.faction = faction and faction:getName() or nil
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
                -- throw away invisible characters
                local c = text:sub(i, i)
                if not utils.isInvisibleByte(c:byte()) then
                    chars[#chars + 1] = c
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

            -- avoid doing this again
            addMessageTagValue(info.message, 'ocSupressed', true)

            -- push the message up with blank text
            local player = getSpecificPlayer(0)
            if player then
                for _ = 1, 5 do
                    player:Say(' ')
                end
            end

            local zomboidRadio = getZomboidRadio()
            if not zomboidRadio then
                return
            end

            -- do the same thing for radios
            local devices = zomboidRadio:getDevices()
            for i = 0, devices:size() - 1 do
                local device = devices:get(i) ---@cast device IsoWaveSignal
                local deviceData = device and device:getDeviceData()
                if deviceData and instanceof(device, 'IsoRadio') then
                    local canTransmit = not deviceData:isPlayingMedia() and not deviceData:isNoTransmit()
                    local hasSayLine = canTransmit and device.getSayLine and device:getSayLine()
                    if hasSayLine and deviceData:getChannel() == info.message:getRadioChannel() then
                        for _ = 1, 5 do
                            device:Say(' ')
                        end
                    end
                end
            end
        end,
    },
}
