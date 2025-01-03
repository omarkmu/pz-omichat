---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local concat = table.concat
local getText = getText
local instanceof = instanceof

local utils = OmiChat.utils
local Option = OmiChat.Option
local config = OmiChat.config

---Checks whether input matches a command stream.
---@param name omichat.CustomStreamName
---@param info omichat.MessageInfo
---@return string?
local function matchCommand(name, info)
    if not OmiChat.isCustomStreamEnabled(name) then
        return
    end

    local streamConfig = config:getCustomStreamInfo(name)
    if not streamConfig then
        return
    end

    local text = info.content or info.rawText
    local formatter = OmiChat.getFormatter(name)
    local matched = formatter:read(text)
    if not matched then
        return
    end

    if info.context.ocIsRadio then
        info.message:setShowInChat(false)
        info.message:setOverHeadSpeech(false)
        return
    end

    if streamConfig.overheadFormatOpt and Option[streamConfig.overheadFormatOpt] == '' then
        info.message:setOverHeadSpeech(false)
    end

    return matched
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
            info.format = info.format or Option.ChatFormatRadio
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
            local text = info.rawText
            local formatter = OmiChat.getFormatter('echo')

            local matched = formatter:read(text)
            if not matched then
                return
            end

            if Option.ChatFormatEcho ~= '' then
                info.tokens.echo = '1'
                info.format = info.format or Option.ChatFormatEcho
            end

            local player = getSpecificPlayer(0)
            local username = player and player:getUsername()
            local author = info.message:getAuthor()
            if author == username then
                info.message:setShowInChat(false)
                info.message:setOverHeadSpeech(false)
                return
            end

            if not author or not username then
                return
            end

            local shouldSuppress = false
            local echoType = utils.decodeInvisibleCharacter(matched)
            if echoType == 1 then -- faction
                local playerFaction = Faction.getPlayerFaction(username)
                shouldSuppress = playerFaction and (playerFaction:isOwner(author) or playerFaction:isMember(author))
            elseif echoType == 2 then -- safehouse
                local playerSafehouse = SafeHouse.hasSafehouse(username)
                shouldSuppress = playerSafehouse and playerSafehouse:playerAllowed(author)
            end

            if shouldSuppress then
                info.message:setShowInChat(false)
                info.message:setOverHeadSpeech(false)
            end
        end,
    },
    {
        name = 'decode-card',
        priority = 55,
        transform = function(_, info)
            local matched = matchCommand('card', info)
            if not matched then
                return
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
        name = 'decode-flip',
        priority = 54,
        transform = function(_, info)
            local matched = matchCommand('flip', info)
            if not matched then
                return
            end

            local result = utils.decodeInvisibleCharacter(matched)

            if result ~= 1 and result ~= 2 then
                info.message:setShowInChat(false)
                return
            end

            info.content = matched:sub(3)
            info.tokens.heads = result == 1

            info.format = Option.ChatFormatFlip
            info.formatOptions.color = OmiChat.getColorOrDefault('me')
            info.formatOptions.useDefaultChatColor = false

            info.context.ocCustomStream = 'me'
            info.tokens.stream = 'flip'
        end,
    },
    {
        name = 'decode-roll',
        priority = 50,
        transform = function(_, info)
            local matched = matchCommand('roll', info)
            if not matched then
                return
            end

            local seq
            seq, matched = utils.decodeInvisibleIntSequence(matched, 2)
            if not matched or not seq then
                info.message:setShowInChat(false)
                return
            end

            info.content = matched
            info.tokens.roll = seq[1]
            info.tokens.sides = seq[2]

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
                    info.tokens.customStream = data.streamAlias or name
                    info.content = formatter:read(text)
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
                info.context.ocIsOtherOverhead = true
                info.content = matched
            end
        end,
    },
    {
        name = 'handle-language',
        priority = 30,
        transform = function(_, info)
            if info.context.ocSkipLanguage then
                return
            end

            local isRadio = info.context.ocIsRadio
            local formatter = OmiChat.getFormatter('language')
            local text = info.content or info.rawText

            -- radio messages don't have language metadata, so we need to read the language from the text
            local encodedLanguage
            if formatter:isMatch(text) then
                text = formatter:read(text)
                encodedLanguage = OmiChat.decodeLanguage(text)
            end

            local language = info.meta.language
            if not language and isRadio and encodedLanguage then
                language = encodedLanguage
                info.meta.language = language
                utils.addMessageTagValue(info.message, 'ocLanguage', language)
            end

            if not language then
                return
            end

            -- add language information for format strings
            local isSigned = OmiChat.isRoleplayLanguageSigned(language)
            if language ~= OmiChat.getDefaultRoleplayLanguage() then
                info.tokens.language = utils.getTranslatedLanguageName(language)
                info.tokens.languageRaw = language
            end

            -- hide signed messages sent over the radio
            if isSigned and isRadio then
                info.message:setShowInChat(false)
                info.message:setOverHeadSpeech(false)
            end

            if isAdmin() and OmiChat.getUnderstandAllLanguages() then
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
            info.message:setOverHeadSpeech(false)
            info.formatOptions.useDefaultChatColor = false
            info.tokens.unknownLanguage = language

            if isRadio then
                info.format = Option.ChatFormatUnknownLanguageRadio
            else
                info.format = Option.ChatFormatUnknownLanguage
                local isQuietStream = info.context.ocIsSneakCallout
                    or info.context.ocCustomStream == 'whisper'
                    or info.context.ocCustomStream == 'low'
                if isQuietStream and OmiChat.isCustomStreamEnabled('mequiet') then
                    info.context.ocStreamForRange = 'whisper'
                    info.formatOptions.color = OmiChat.getColorOrDefault('mequiet')
                    info.tokens.stream = 'mequiet'
                elseif info.chatType == 'shout' and OmiChat.isCustomStreamEnabled('meloud') then
                    info.context.ocStreamForRange = 'shout'
                    info.formatOptions.color = OmiChat.getColorOrDefault('meloud')
                    info.tokens.stream = 'meloud'
                elseif OmiChat.isCustomStreamEnabled('me') then
                    info.formatOptions.color = OmiChat.getColorOrDefault('me')
                    info.tokens.stream = 'me'
                end
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

            local dialogueTag = utils.unwrapStringArgument(matched, config.NARRATIVE_TAG)
            local content = utils.unwrapStringArgument(matched, config.NARRATIVE_TEXT)
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

            info.tokens.dialogueTag = dialogueTag
            info.tokens.unstyled = info.context.ocNarrativeContent
            info.content = translated
        end,
    },
    {
        name = 'check-range',
        priority = 15,
        transform = function(_, info)
            if info.chatType ~= 'say' and info.chatType ~= 'shout' then
                return
            end

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

            local tokens = { stream = info.context.ocStreamForRange or info.tokens.stream }
            if range then
                info.attractRange = range * Option.RangeMultiplierZombies
                if not info.context.ocIsCallout and not info.context.ocIsSneakCallout then
                    info.message:setShouldAttractZombies(utils.testPredicate(Option.PredicateAttractZombies, tokens))
                end
            end

            if isAdmin() and OmiChat.getIgnoreMessageRange() then
                return
            end

            local authorPlayer = utils.getPlayerByUsername(info.author)
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
                info.tokens.recipientRaw = other
                info.tokens.recipientName = utils.escapeRichText(OmiChat.getNameInChat(other, 'whisper') or other)
                info.tokens.recipientNameRaw = info.tokens.recipientName

                if not info.meta.recipientNameColor then
                    info.meta.recipientNameColor = OmiChat.getNameColorInChat(other)
                end
            else
                -- defer to basic chat format handler
                info.context.ocIsIncomingPM = true
            end

            info.formatOptions.color = OmiChat.getColorOrDefault('private')
            info.formatOptions.useDefaultChatColor = false
        end,
    },
    {
        name = 'check-hide-radio',
        priority = 5,
        transform = function(_, info)
            if info.chatType ~= 'radio' or utils.testPredicate(Option.PredicateTransmitOverRadio, info.tokens) then
                return
            end

            info.message:setShowInChat(false)
            info.message:setOverHeadSpeech(false)
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
                local authorEnd = utils.getAuthorEndPos(info.rawText, info.author)
                if authorEnd then
                    info.content = info.rawText:sub(authorEnd + 1)
                end
            end

            if info.chatType == 'faction' then
                local player = getSpecificPlayer(0)
                local faction = player and Faction.getPlayerFaction(player)
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
        name = 'radio-storm-fix',
        priority = 0,
        transform = function(_, info)
            if info.chatType ~= 'radio' or Option.PredicateUseNarrativeStyle == '' then
                return
            end

            local text = info.content
            -- avoid duplicate name when radios scramble narrative style messages
            if not text or not text:match('&lt;[bfws]zzt&gt;') then
                return
            end

            -- this is not ideal, but for now it will have to do
            local author = info.message:getAuthor()
            if author and author ~= '' then
                text = text:gsub(utils.escape(author), '')
            end

            if info.tokens.nameRaw then
                text = text:gsub(utils.escape(info.tokens.nameRaw), '')
            end

            info.content = text
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
            utils.addMessageTagValue(info.message, 'ocSuppressed', true)

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
