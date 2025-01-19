local API = require 'OmiChat/API/Client/Core'
local utils = API.utils
local config = API.Configuration

local isAdmin = isAdmin
local getText = getText


local COMMAND_ARGS_START = utils.encodeInvisibleCharacter(config.ID_COMMAND_ARGS)


local rangedChatTypes = {
    say = true,
    shout = true,
}

-- accessing fields directly where possible to avoid function call overhead
---@diagnostic disable: invisible


---@type omichat.MessageTransformer[]
return {
    {
        name = 'setup-chat-info',
        priority = 100,
        transform = function(_, info)
            -- more performant than separate transformers to set up multiple types in one
            local chatType = info.chatType
            if chatType == 'radio' then
                local text = info.content or info.rawText
                local _, msgStart, freq = text:find('Radio%s*%((%d+%.%d+)[^%)]+%)%s*:')
                if msgStart then
                    info.tokens.frequency = freq
                    info.content = text:sub(msgStart + 1)

                    if not info.format then
                        info.format = config.Radio.ChatFormat
                    end
                end

                local originalStream = info.originalStream
                if originalStream then
                    info.tokens.originalStream = originalStream.name

                    local formatter = originalStream.formatter
                    if formatter then
                        info.content = formatter:read(text)
                    end
                end
            elseif chatType == 'faction' then
                if info.meta.faction then
                    info.tokens.faction = info.meta.faction
                    return
                end

                local player = getSpecificPlayer(0)
                local faction = player and Faction.getPlayerFaction(player)
                local name = faction and faction:getName() or ''
                info.tokens.faction = name
                info:setMetadataFaction(name)

                return
            elseif chatType == 'server' then
                local text = info.content or info.rawText

                -- not great, but can't access the isShowTitle chat setting to do this in a safer way
                local _, serverMsgStart = text:find('%[' .. getText('UI_chat_server_chat_title_id') .. '%]:')

                if serverMsgStart then
                    info.content = text:sub(serverMsgStart + 1)
                else
                    -- server messages can be only their text, if not set to show title
                    -- still have to extract text due to the existing rich text

                    local _, sizeEnd = text:find('<SIZE:')
                    local start = sizeEnd ~= -1 and text:find('>', sizeEnd)
                    if start then
                        info.content = text:sub(start + 1)
                    end
                end

                return
            elseif chatType == 'whisper' then
                local text = info.rawText
                local _, msgStart, other = text:find('%[to ([^%]]+)%]:')

                if not other then
                    info.tokens.incomingPM = '1'
                    info.tags.IsIncomingPM = true
                    return
                end

                info.tokens.recipient = other
                info.tokens.recipientRaw = other
                info.tokens.recipientName = utils.escapeRichText(API.getNameInChat(other, 'whisper') or other)
                info.tokens.recipientNameRaw = info.tokens.recipientName
                info.tokens.outgoingPM = '1'
                info.tags.IsOutgoingPM = true

                info.content = text:sub(msgStart + 1)

                return
            end

            local text = info.content or info.rawText
            local formatter = API._metadataFormatters.overheadFinal
            local match = formatter and formatter:read(text)
            if match then
                info.content = match
            end
        end,
    },
    {
        name = 'handle-commands',
        priority = 90,
        transform = function(_, info)
            local stream = info:getStream()
            if not stream or not stream.isCommand then
                return
            end

            local formatter = stream.formatter
            local matched = formatter and formatter:read(info.content or info.rawText)
            if not matched then
                return
            end

            local start = matched:find(COMMAND_ARGS_START)
            if not start then
                return
            end

            matched = matched:sub(start + 1)

            local targetStream
            local name = stream.name
            if name == 'card' then
                local suit = utils.decodeInvisibleCharacter(matched)
                local card = utils.decodeInvisibleCharacter(matched, 2)
                if suit < 1 or suit > 4 or card < 1 or card > 13 then
                    info:hide()
                    return
                end

                info.content = matched:sub(3)
                info.tokens.card = utils.getTranslatedCardName(card, suit)

                targetStream = API.getFirstChatStreamWithTag('CardCommandTarget')
            elseif name == 'flip' then
                local result = utils.decodeInvisibleCharacter(matched)
                if result ~= 1 and result ~= 2 then
                    info:hide()
                    return
                end

                info.content = matched:sub(2)
                info.tokens.heads = result == 1

                targetStream = API.getFirstChatStreamWithTag('FlipCommandTarget')
            elseif name == 'roll' then
                local seq = utils.decodeInvisibleIntSequence(matched, 2)
                if not seq or #seq ~= 2 then
                    info:hide()
                    return
                end

                info.content = matched:sub(3)
                info.tokens.roll = seq[1]
                info.tokens.sides = seq[2]

                targetStream = API.getFirstChatStreamWithTag('RollCommandTarget')
            else
                return
            end

            if not targetStream or info:isChatType('radio') then
                info:hide()
                return
            end

            local targetFormat = stream:getChatFormat()
            if targetFormat and targetFormat ~= '' then
                info.format = targetFormat
            end

            info:setStream(targetStream)

            if targetStream:hasTag('HideOverhead') or stream:hasTag('HideOverhead') then
                info:hideOverhead()
            end
        end,
    },
    {
        name = 'echo-chat',
        priority = 80,
        transform = function(_, info)
            local formatter = API._metadataFormatters.echo
            local matched = formatter and formatter:read(info:getRawText())
            if not matched then
                return
            end

            info.tokens.echo = '1'
            info.tags.IsEchoMessage = true
            info:addTags(config.EchoMessages.Tags)

            if not info.format then
                info.format = config.EchoMessages.ChatFormat
            end

            local targetStream = API.getFirstChatStreamWithTag('EchoTarget')
            if targetStream then
                info:setStream(targetStream)

                if targetStream:hasTag('HideOverhead') then
                    info:hideOverhead()
                end
            end

            local player = getSpecificPlayer(0)
            local username = player and player:getUsername()
            local author = info:getAuthor()
            if author == username then
                info:hide()
                return
            end

            if not author or not username then
                return
            end

            -- suppress echo messages if the player would have seen the original
            local shouldSuppress = false
            local echoType = utils.decodeInvisibleInt(utils.unwrapStringArgument(matched, config.ID_ECHO_TYPE))
            if echoType == 1 then -- faction
                local playerFaction = Faction.getPlayerFaction(username)
                shouldSuppress = playerFaction and (playerFaction:isOwner(author) or playerFaction:isMember(author))
            elseif echoType == 2 then -- safehouse
                local playerSafehouse = SafeHouse.hasSafehouse(username)
                shouldSuppress = playerSafehouse and playerSafehouse:playerAllowed(author)
            end

            if shouldSuppress then
                info:hide()
            end
        end,
    },
    {
        name = 'callouts',
        priority = 80,
        transform = function(_, info)
            local text = info.content or info.rawText
            local calloutFormatter = API._metadataFormatters.callout
            local sneakCalloutFormatter = API._metadataFormatters.sneakCallout

            local targetStream
            if calloutFormatter and calloutFormatter:isMatch(text) then
                info:setIsCallout(true)
                info.content = calloutFormatter:read(text)
                targetStream = API.getFirstChatStreamWithTag('Callout')
            elseif sneakCalloutFormatter and sneakCalloutFormatter:isMatch(text) then
                info:setIsSneakCallout(true)
                info.content = sneakCalloutFormatter:read(text)

                targetStream = API.getFirstChatStreamWithTag('SneakCallout') or API.getFirstChatStreamWithTag('Callout')
            else
                return
            end

            targetStream = targetStream or API.getStreamByName('yell')
            if targetStream then
                info:setStream(targetStream)
            end

            -- already created a sound for the callout
            info.message:setShouldAttractZombies(false)
        end,
    },
    {
        name = 'read-stream',
        priority = 70,
        transform = function(_, info)
            if info:isChatType('radio') then
                return
            end

            local stream = info:getStream()
            if not stream then
                return
            end

            local text = info.content or info.rawText
            local formatter = stream:getFormatter()
            local matched = formatter and formatter:read(text)
            if matched then
                info.content = matched
            elseif info:checkMismatch() then
                info:hide()
            end

            if not info.format then
                info.format = stream:getChatFormat()
            end

            if stream:hasTag('HideOverhead') then
                info:hideOverhead()
            end
        end,
    },
    {
        name = 'handle-language',
        priority = 60,
        transform = function(_, info)
            if info.skipLanguage then
                return
            end

            local formatter = API._metadataFormatters.language
            if not formatter then
                return
            end

            local isRadio = info.chatType == 'radio'
            local text = info.content or info.rawText

            local language = info.meta.language
            if not language and isRadio then
                -- radio messages don't have language metadata, so we need to read the language from the text
                if formatter:isMatch(text) then
                    text = formatter:read(text)
                    language = API.decodeLanguage(text)

                    if language then
                        info:setMetadataLanguage(language)
                    end
                end
            end

            if not language then
                return
            end

            -- add language information for format strings
            local isSigned = API.isRoleplayLanguageSigned(language)
            if language ~= API.getDefaultRoleplayLanguage() then
                info.tokens.language = utils.getTranslatedLanguageName(language)
                info.tokens.languageRaw = language
            end

            -- hide signed messages sent over the radio
            if isSigned and isRadio then
                info:hide()
            end

            if isAdmin() and API.getUnderstandAllLanguages() then
                return
            end

            local player = getSpecificPlayer(0)
            local username = player and player:getUsername()
            if not isRadio and username and info:getAuthor() == username then
                -- everyone understands themselves
                return
            elseif API.checkKnowsLanguage(language) then
                -- if they understand the language, we're done here
                return
            end

            -- they didn't understand it
            info:hideOverhead()
            info.tokens.unknownLanguage = language
            info.tags.IsUnknownLanguage = true

            if isRadio then
                info.format = config.Language.UnknownLanguageRadio
            else
                info.format = config.Language.UnknownLanguage

                info:syncTags()

                local targetTags
                if info.sneakCallout or info.tags.Quiet then
                    targetTags = { 'Quiet', 'Whisper' }
                elseif info.loudCallout or info.tags.Loud then
                    targetTags = { 'Loud' }
                end

                local streams = API.getChatStreamsWithTag('Action', { 'NoName' })
                local targetStream
                if targetTags then
                    for i = 1, #streams do
                        local stream = streams[i]
                        if stream:hasAnyTags(targetTags) then
                            targetStream = stream
                            break
                        end
                    end
                end

                -- if there's not a stream that matches the volume, use any action stream that displays names
                targetStream = targetStream or streams[1]
                if targetStream then
                    local stream = info.stream
                    if stream and stream.tags.Action then
                        info.tags.IsActionUnknownLanguage = true
                    end

                    info:setStream(targetStream)
                end
            end
        end,
    },
    {
        name = 'handle-narrative',
        priority = 50,
        transform = function(_, info)
            local formatter = API._metadataFormatters.narrative
            if not formatter then
                return
            end

            local text = info.content or info.rawText
            local matched = formatter:read(text)
            if not matched then
                return
            end

            local dialogueTag = utils.unwrapStringArgument(matched, config.ID_NARRATIVE_TAG)
            local unstyled = utils.unwrapStringArgument(matched, config.ID_NARRATIVE_TEXT)
            if not dialogueTag or not unstyled then
                return
            end

            info:syncTags()

            local tokens = utils.copy(info.tokens)
            tokens.input = unstyled
            tokens.dialogueTag = dialogueTag

            info.content = utils.interpolate(config.NarrativeStyle.ChatContentFormat, tokens)
            info.tokens.narrativeStyle = '1'
            info.tokens.dialogueTag = dialogueTag
            info.tokens.unstyled = unstyled
            info.tags.IsNarrativeStyle = true
        end,
    },
    {
        name = 'check-range',
        priority = 20,
        transform = function(_, info)
            local stream = info.stream
            if not stream or not stream.isChat then
                return
            end

            ---@cast stream omichat.ChatStream
            if not rangedChatTypes[stream.chatType] then
                return
            end

            local cached = info.meta.rangeResult
            if cached then
                if cached == 'out-of-range' then
                    info:hide()
                end

                return
            end

            local maxRange = info.chatType == 'shout' and 60 or 30
            local range = stream.range
            if info.loudCallout then
                range = config.Callouts.Range
            elseif info.sneakCallout then
                range = config.Callouts.SneakRange
            end

            range = range or maxRange

            if stream.attractZombies then
                info.zombieAttractRange = range * config.ZombieAttraction.ChatRangeMultiplier
            end

            if isAdmin() and API.getIgnoreMessageRange() then
                info:setMetadataRangeResult('in-range')
                return
            end

            local authorPlayer = utils.getPlayerByUsername(info.author)
            local localPlayer = getSpecificPlayer(0)
            if not authorPlayer or not localPlayer or authorPlayer == localPlayer then
                -- players can hear themselves
                return
            end

            local outOfRange = false
            local zMax = stream.verticalRange or 2
            if zMax and math.abs(authorPlayer:getZ() - localPlayer:getZ()) >= zMax then
                outOfRange = true
            elseif range ~= maxRange then
                -- calculating distance using the distance formula like ChatUtility
                -- assuming players are synced it works equivalently
                local xDiff = authorPlayer:getX() - localPlayer:getX()
                local yDiff = authorPlayer:getY() - localPlayer:getY()

                outOfRange = math.sqrt(xDiff * xDiff + yDiff * yDiff) > range
            end

            if outOfRange then
                info:setMetadataRangeResult('out-of-range')
                info:hide()
            else
                info:setMetadataRangeResult('in-range')
            end
        end,
    },
    {
        name = 'check-transmit-radio',
        priority = 5,
        transform = function(_, info)
            if info.chatType ~= 'radio' then
                return
            end

            local originalStream = info.originalStream
            local tags = originalStream and originalStream.tags
            if not tags then
                return
            end

            local canTransmit = true
            if tags.IsEchoMessage or tags.NoTransmitOverRadio then
                canTransmit = false
            else
                canTransmit = tags.TransmitOverRadio or (not tags.OOC and not tags.Action)
            end

            if not canTransmit then
                info:hide()
            end
        end,
    },
}
