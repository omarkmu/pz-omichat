---@namespace omichat
---Message transformer definitions.
---@diagnostic disable: access-invisible


local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local config = API.Configuration

local isAdmin = isAdmin
local getText = getText
local format = string.format

local COMMAND_ARGS_START = utils.encodeInvisibleCharacter(config.ID_COMMAND_ARGS)


---@class MessageTransformer
---@field name? string The name of the transformer.
---@field transform fun(self: table, info: MessageInfo): true? Performs message transformation.
---@field priority? integer The priority of the transformer. Higher numbers will run first.


---@type MessageTransformer[]
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

                if not msgStart or not other then
                    info.tokens.incomingPM = '1'
                    info.tags.IsIncomingPM = true
                    return
                end

                info.tokens.recipient = other
                info.tokens.recipientRaw = other
                info.tokens.recipientName = utils.escapeRichText(API.data.getNameInChat(other, 'whisper') or other)
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
        name = 'decode-mentions',
        priority = 95,
        transform = function(_, info)
            local text = info.content or info.rawText
            local formatter = API._metadataFormatters.mention
            local pattern = formatter:getPattern(false, true)

            info.content = text:gsub(pattern, function(match)
                local onlineID, name = utils.decodeInvisibleInt(match)
                if not onlineID or not name then
                    return match
                end

                return format('<@%03d:%s>', onlineID, name)
            end)
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

                targetStream = API.streams.firstChatStreamWithTag('CardCommandTarget')
            elseif name == 'flip' then
                local result = utils.decodeInvisibleCharacter(matched)
                if result ~= 1 and result ~= 2 then
                    info:hide()
                    return
                end

                info.content = matched:sub(2)
                info.tokens.heads = result == 1

                targetStream = API.streams.firstChatStreamWithTag('FlipCommandTarget')
            elseif name == 'roll' then
                local seq = utils.decodeInvisibleIntSequence(matched, 2)
                if not seq or #seq ~= 2 then
                    info:hide()
                    return
                end

                info.content = matched:sub(3)
                info.tokens.roll = seq[1]
                info.tokens.sides = seq[2]

                targetStream = API.streams.firstChatStreamWithTag('RollCommandTarget')
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

            local targetStream = API.streams.firstChatStreamWithTag('EchoTarget')
            if targetStream then
                info:setStream(targetStream)
            end

            local player = getSpecificPlayer(0)
            local username = player and player:getUsername()
            local author = info:getAuthor()
            if author == username then
                info:hideInChat()
                return
            end

            if not author or not username then
                return
            end

            -- hide echo messages in chat if the player would have seen the original
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
                info:hideInChat()
            end
        end,
    },
    {
        name = 'callouts',
        priority = 70,
        transform = function(_, info)
            local text = info.content or info.rawText
            local calloutFormatter = API._metadataFormatters.callout
            local sneakCalloutFormatter = API._metadataFormatters.sneakCallout

            local targetStream
            if calloutFormatter and calloutFormatter:isMatch(text) then
                info:setIsCallout(true)
                info.content = calloutFormatter:read(text)
                targetStream = API.streams.firstChatStreamWithTag('Callout')
            elseif sneakCalloutFormatter and sneakCalloutFormatter:isMatch(text) then
                info:setIsSneakCallout(true)
                info.content = sneakCalloutFormatter:read(text)

                targetStream = API.streams.firstChatStreamWithTag('SneakCallout') or
                    API.streams.firstChatStreamWithTag('Callout')
            else
                return
            end

            targetStream = targetStream or API.streams.get('yell')
            if targetStream then
                info:setStream(targetStream)
            end

            -- already created a sound for the callout
            info.message:setShouldAttractZombies(false)
        end,
    },
    {
        name = 'read-stream',
        priority = 60,
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
        end,
    },
    {
        name = 'handle-language',
        priority = 50,
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
                local matchText = formatter:read(text)
                if matchText then
                    text = matchText
                    language = API.format.decodeLanguage(text)

                    if language then
                        info:setMetadataLanguage(language)
                    end
                end
            end

            if not language then
                return
            end

            -- add language information for format strings
            local isSigned = API.language.isSigned(language)
            if language ~= API.language.getDefault() then
                info.tokens.language = utils.getTranslatedLanguageName(language)
                info.tokens.languageRaw = language
            end

            -- hide signed messages sent over the radio
            if isSigned and isRadio then
                info:hide()
            end

            if isAdmin() and API.preferences.getUnderstandAllLanguages() then
                return
            end

            local cached = info.meta.languageResult
            if cached == 'unknown-language' then
                info.tokens.unknownLanguage = language
                info.tags.IsUnknownLanguage = true
                info:setUseUnknownLanguageText(true)
                return
            elseif cached then
                return
            end

            local player = getSpecificPlayer(0)
            local username = player and player:getUsername()
            if not isRadio and username and info:getAuthor() == username then
                -- everyone understands themselves
                info:setMetadataLanguageResult('known-language')
                return
            elseif language and API.player.knowsLanguage(language) then
                -- if they understand the language, we're done here
                info:setMetadataLanguageResult('known-language')
                return
            end

            -- they didn't understand it
            info:setUseUnknownLanguageText(true)
            info:setMetadataLanguageResult('unknown-language')
            info.tokens.unknownLanguage = language
            info.tags.IsUnknownLanguage = true
        end,
    },
    {
        name = 'handle-narrative',
        priority = 40,
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

            info:syncTags() -- sync tags for the narrative content format

            local tokens = utils.copy(info.tokens)
            tokens.input = unstyled
            tokens.dialogueTag = dialogueTag

            info.content = utils.interpolateNamed('NarrativeChatContent', config.NarrativeStyle.ChatContentFormat, tokens)
            info.tokens.narrativeStyle = '1'
            info.tokens.dialogueTag = dialogueTag
            info.tokens.unstyled = unstyled
            info.tags.IsNarrativeStyle = true
        end,
    },
    {
        name = 'handle-mentions',
        priority = 30,
        transform = function(_, info)
            if not config.Mentions.Enable then
                return
            end

            local text = info.content or info.rawText
            local cached = info.meta.mentions
            local useColors = info:shouldUseMentionColors()

            local i = 1
            local mentions = {} ---@type MessageInfo.Metadata.Mention[]

            info.content = text:gsub('%s*<@%d+:.->%s*', function(match)
                local leading, onlineID, name, trailing = match:match('(%s*)<@(%d+):(.-)>(%s*)')
                onlineID = utils.tointeger(onlineID)

                if not onlineID or not name then
                    return match
                end

                local color = { r = 255, g = 255, b = 255 } ---@type omi.ColorTable<integer>
                local hoverName
                if cached then
                    local item = cached[i] or {}
                    hoverName = item.name
                    if item and item.color then
                        color = utils.color.fromString(item.color) or color
                    end

                    i = i + 1
                else
                    local playerData = onlineID and API.data.getPlayerInfoByOnlineID(onlineID)
                    color = playerData and playerData.speechColor or color
                    hoverName = playerData and API.data.getPlayerNameInChat(playerData, info.chatType)
                end

                local tokens = utils.copy(info.tokens)
                tokens.input = name
                tokens.onlineID = tostring(onlineID)

                local result = utils.interpolateNamed('MentionChat', config.Mentions.ChatFormat, tokens)

                if useColors then
                    result = utils.color.toRichText(color, true) .. result .. ' <POPRGB> '
                end

                -- avoid breaking segment detection
                hoverName = hoverName and hoverName:gsub('"', "''")

                if hoverName and name ~= hoverName then
                    result = ' <HOVER:' .. utils.escapeRichText(hoverName) .. '> ' .. result .. ' </HOVER> '
                end

                if #leading > 0 then
                    result = ' <SPACE> ' .. result
                end

                if #trailing > 0 then
                    result = result .. ' <SPACE> '
                end

                if not cached then
                    mentions[#mentions + 1] = {
                        name = hoverName,
                        color = utils.color.toHexString(color),
                    }
                end

                return result
            end)

            if not cached then
                info:setMetadataMentions(mentions)
            end
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

            ---@cast stream ChatStream
            if stream.chatType ~= 'say' and stream.chatType ~= 'shout' then
                return
            end

            local cached = info.meta.rangeResult
            if cached == 'out-of-range' then
                info:hide()
                return
            elseif cached == 'in-perception-range' then
                info:setUsePerceivedText(true)
                return
            elseif cached then
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

            if isAdmin() and API.preferences.getIgnoreMessageRange() then
                info:setMetadataRangeResult('in-range')
                return
            end

            local author = utils.getPlayerByUsername(info.author)
            local player = getSpecificPlayer(0)
            if not author or not player or author == player then
                -- players can hear themselves
                return
            end

            local outOfRange = false
            local zMax = stream.verticalRange or 2

            local dist
            if zMax > 0 and math.abs(author:getZ() - player:getZ()) >= zMax then
                outOfRange = true
            elseif range ~= maxRange then
                dist = API.player.getDistanceFrom(author, player)
                outOfRange = dist > range
            end

            if not outOfRange then
                info:setMetadataRangeResult('in-range')
                return
            end

            local language = info.tokens.languageRaw
            local isSigned = language and API.language.isSigned(language)

            if dist and not info.tags.Action then
                range = isSigned and stream.perceptionRangeSigned or stream.perceptionRange
                if API.hooks.has.perceptionRange then
                    range = API.hooks.perceptionRange({
                        range = range,
                        distance = dist,
                        player = player,
                        author = author,
                        isSigned = isSigned or false,
                    })
                end

                if dist <= range then
                    info:setUsePerceivedText(true)
                    info:setMetadataRangeResult('in-perception-range')
                    return
                end
            end

            info:hide()
            info:setMetadataRangeResult('out-of-range')
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
