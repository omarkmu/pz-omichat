---Handles defining topics for client and server requests.
---@namespace omichat
---@diagnostic disable: access-invisible

---@class(partial) api.shared
local API = require 'OmiChat/Module/Shared/Core'

---@class(partial) api.client
local API_C = API

---@class(partial) api.server
local API_S = API

local utils = API.utils
local config = API.Configuration

local format = string.format
local getTimestampMs = getTimestampMs
local getOnlinePlayers = getOnlinePlayers
local CharacterStat = CharacterStat

local IS_DEBUG = getDebug()


---@class(partial) api.shared.request
local Request = {}

---Contains functions for sending server and client commands.
API.request = Request

---@class api.shared.request.topic
local TOPIC = {}

---Contains topics for request exchanges between the server and client.
Request.TOPIC = TOPIC

---Dispatcher that handles routing requests.
Request.dispatch = utils.dispatch {
    module = API._key,
    logger = utils.log,
}


local dispatch = Request.dispatch

local STAT_SYNC_FLAGS = 0
do
    -- build bit flags for character stat sync
    local syncStats = {
        [CharacterStat.HUNGER] = true,
        [CharacterStat.THIRST] = true,
        [CharacterStat.FATIGUE] = true,
        [CharacterStat.BOREDOM] = true,
        [CharacterStat.UNHAPPINESS] = true,
        [CharacterStat.NICOTINE_WITHDRAWAL] = true,
    }

    ---@type ArrayList<CharacterStat>
    local arrayList = ArrayList.new(Array.new(CharacterStat.ORDERED_STATS))

    for i = 0, arrayList:size() - 1 do
        local stat = arrayList:get(i)
        if syncStats[stat] then
            STAT_SYNC_FLAGS = STAT_SYNC_FLAGS + (2 ^ i) --[[@as integer]]
        end
    end
end


---Client → server: Apply a buff.
TOPIC.APPLY_BUFF = dispatch:topic('APPLY_BUFF', {
    onServerReceive = function(req)
        local player = req:getPlayer()
        local modData = player:getModData()

        local omichatData = modData.omichat
        if type(omichatData) ~= 'table' then
            omichatData = {}
            modData.omichat = omichatData
        end

        local now = getTimestampMs()
        local buffConfig = config.Buffs
        local lastBuff = tonumber(omichatData.lastBuff)
        if lastBuff and (now - lastBuff) / 60000 < buffConfig.Cooldown then
            return
        end

        local withdrawalReduction = buffConfig.CigaretteStress * CharacterStat.NICOTINE_WITHDRAWAL:getMaximumValue()

        local stats = player:getStats()
        stats:remove(CharacterStat.HUNGER, buffConfig.Hunger)
        stats:remove(CharacterStat.THIRST, buffConfig.Thirst)
        stats:remove(CharacterStat.FATIGUE, buffConfig.Fatigue)
        stats:remove(CharacterStat.BOREDOM, buffConfig.Boredom * 100)
        stats:remove(CharacterStat.UNHAPPINESS, buffConfig.Unhappiness * 100)
        stats:remove(CharacterStat.NICOTINE_WITHDRAWAL, withdrawalReduction)
        omichatData.lastBuff = now

        syncPlayerStats(player, STAT_SYNC_FLAGS)
    end,
})

---Client → server: Apply a customization option (including character clean).
---Server → client: Indicates that customization was applied.
TOPIC.APPLY_CUSTOMIZATION = dispatch:topic('APPLY_CUSTOMIZATION', {
    ---@param req omi.ClientRequest
    ---@param args request.Args.Customization
    onServerReceive = function(req, args)
        if not config.Customization.EnableCharacterCustomization then
            return
        end

        local player = req:getPlayer()
        if args.type == 'GROW_BEARD' then
            API_S.customization.growBeard(player)
        elseif args.type == 'GROW_HAIR' then
            API_S.customization.growHair(player)
        elseif args.type == 'SET_HAIR_COLOR' then
            API_S.customization.setHairColor(player, args.hairColor)
        elseif args.type == 'CLEAN_CHARACTER' then
            API_S.customization.cleanCharacter(player)
        else
            return
        end

        req:reply(args)
    end,

    onClientReceive = function()
        local player = API_C.player.get()
        if not player then
            return
        end

        triggerEvent('OnClothingUpdated', player)
    end,
})

---Client → server: Execute a chat command.
TOPIC.COMMAND = dispatch:topic('COMMAND', {
    ---@param args request.Args.Command
    ---@return boolean
    ---@return string?
    onClientValidate = function(_, args)
        if args.name ~= 'setIcon' then
            return true
        end

        -- need to validate texture client-side
        local cmdArgs = utils.parseCommandArgs(args.text)
        local username = cmdArgs[1]
        local icon = cmdArgs[2]

        if not username or not icon then
            return false
        end

        if not getTexture(icon) then
            local textureName = utils.getTextureNameFromIcon(icon)
            if textureName and getTexture(textureName) then
                args.text = format('%q', username) .. ' ' .. textureName
            else
                return false, 'Unknown icon'
            end
        end

        return true
    end,

    ---@param req omi.ClientRequest
    ---@param args request.Args.Command
    onServerReceive = function(req, args)
        local handler = API_S.commands[args.name]
        if type(handler) ~= 'function' then
            return
        end

        handler(req:getPlayer(), args)
    end,
})

---Client → server: update configuration on server (admin only).
---Server → client: update configuration.
TOPIC.CONFIGURATION = dispatch:topic('CONFIGURATION', {
    canLogArgs = false,
    requireAdmin = true,

    onSend = function(req)
        local args = { values = config:getValues() } ---@type request.Args.UpdateConfiguration
        req:send(args)
    end,

    ---@param req omi.Request
    ---@param args request.Args.UpdateConfiguration
    onReceive = function(req, args)
        config:load(args.values)

        if req:isFromServer() then
            API_C.chat.updateState(true)
        else
            config:saveModData()
            req:broadcast()
        end
    end,
})

---Client → server: add/remove a preset (admin only).
---Server → client: update configuration presets.
TOPIC.CONFIGURATION_PRESETS = dispatch:topic('CONFIGURATION_PRESETS', {
    requireAdmin = true,

    ---@param args request.Args.AddOrRemovePreset
    ---@return string?
    onStringifyClientArgs = function(args)
        return format('{"type": %q, "name": %q, "values": {...}}', args.type, args.name)
    end,

    ---@param args request.Args.UpdatePresets
    ---@return string?
    onStringifyServerArgs = function(args)
        if #args.list > 0 then
            return '{"list": ' .. Request._encodeListDisplay(args.list) .. '}'
        end
    end,

    onServerSend = function(req)
        local args = { list = config:getCustomPresetsForSave() } ---@type request.Args.UpdatePresets
        req:send(args)
    end,

    ---@param args request.Args.UpdatePresets
    onClientReceive = function(_, args)
        config:_setCustomPresets(args.list) ---@diagnostic disable-line: access-invisible
    end,

    ---@param req omi.ClientRequest
    ---@param args request.Args.AddOrRemovePreset
    onServerReceive = function(req, args)
        if args.type == 'DELETE' then
            API_S.extension.removeCustomPreset(args.name)
        elseif args.values then
            API_S.extension.addCustomPreset(args.name, args.values)
        end

        req:broadcast()
    end,
})

---Client → server: request clearing player data for a username (admin only).
TOPIC.DATA_CLEAR = dispatch:topic('DATA_CLEAR', {
    requireAdmin = true,

    ---@param args request.Args.ClearPlayerData
    onServerReceive = function(_, args)
        API_S.data.clear(args.username)
        API_S.request.updatePlayerCache()
    end,
})

---Client → server: request a list of all data for all players (admin only).
---Server → client: return a list of player data.
TOPIC.DATA_LIST = dispatch:topic('DATA_LIST', {
    requireAdmin = true,

    ---@param args request.Args.PlayerDataListResponse
    ---@return string?
    onStringifyServerArgs = function(args)
        if #args.list > 0 then
            return '{"list": ' .. Request._encodeListDisplay(args.list) .. '}'
        end
    end,

    ---@param args request.Args.PlayerDataListResponse
    onClientReceive = function(_, args)
        local instance = ISChat.instance --[[@as omichat.ISChat]]
        local panel = instance and instance.activePlayerDataPanel
        if not panel then
            return
        end

        panel:onUpdateList(args.list)
    end,

    onServerReceive = function(req)
        ---@type request.Args.PlayerDataListResponse
        local resp = { list = API_S.data.getPlayerDataList() }

        req:reply(resp)
    end,
})

---Client → server: request updating data for a username.
TOPIC.DATA_UPDATE = dispatch:topic('DATA_UPDATE', {
    ---@param req omi.ClientRequest
    ---@param args request.Args.PlayerDataUpdate
    onServerReceive = function(req, args)
        args.fromCommand = false
        API_S.data.tryUpdate(req:getPlayer(), args)
    end,
})

---Client → server: request that a card is drawn.
---Server → client: display the result of drawing a card.
TOPIC.DRAW_CARD = dispatch:topic('DRAW_CARD', {
    onClientValidate = function(req)
        local player = req:getPlayer()
        if not utils.hasIgnoreItemReqPower(player) and not utils.hasAnyItemType(player, config.Commands.Card.Items) then
            return false, 'Missing required item'
        end

        return true
    end,

    onServerReceive = function(req)
        local player = req:getPlayer()
        local suit = utils.randInt(1, 4)
        local card = utils.randInt(1, 13)

        if not config.Commands.Card.Global then
            local args = { card = card, suit = suit } ---@type request.Args.ReportDrawCard
            req:reply(args)
            return
        end

        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

        ---@type request.Args.ShowMessage
        local args = {
            id = 'command-card-global',
            args = {
                name = name,
                card = {
                    id = 'card-name',
                    args = {
                        card = { id = 'card-' .. card },
                        suit = { id = 'card-suit-' .. utils._suits[suit] },
                    },
                },
            },
        }

        req:broadcastOn(TOPIC.SHOW_MESSAGE, args)
    end,

    ---@param args request.Args.ReportDrawCard
    onClientReceive = function(_, args)
        local card = utils.tointeger(args.card)
        if not card or card < 1 or card > 13 then
            return
        end

        local suit = utils.tointeger(args.suit)
        if not suit or suit < 1 or suit > 4 then
            return
        end

        local targetStream = API_C.streams.firstChatStreamWithTag('CardCommandTarget')
        if not targetStream then
            return
        end

        API_C.chat.send {
            allowEmpty = true,
            stream = targetStream,
            text = '',
            context = {
                type = 'omichat.card',
                suit = suit,
                card = card,
            },
        }
    end,
})

---Client → server: request that a coin is flipped.
---Server → client: display the result of flipping a coin.
TOPIC.FLIP_COIN = dispatch:topic('FLIP_COIN', {
    onClientValidate = function(req)
        local player = req:getPlayer()
        if not utils.hasIgnoreItemReqPower(player) and not utils.hasAnyItemType(player, config.Commands.Flip.Items) then
            return false, 'Missing required item'
        end

        return true
    end,

    onServerReceive = function(req)
        local heads = utils.randInt(2) == 1
        if not config.Commands.Flip.Global then
            local args = { heads = heads } ---@type request.Args.ReportFlipCoin
            req:reply(args)
            return
        end

        local player = req:getPlayer()
        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

        ---@type request.Args.ShowMessage
        local args = {
            id = heads and 'command-flip-heads-global' or 'command-flip-tails-global',
            args = { name = name },
        }

        req:broadcastOn(TOPIC.SHOW_MESSAGE, args)
    end,

    ---@param args request.Args.ReportFlipCoin
    onClientReceive = function(_, args)
        local targetStream = API_C.streams.firstChatStreamWithTag('FlipCommandTarget')
        if not targetStream then
            return
        end

        API_C.chat.send {
            allowEmpty = true,
            stream = targetStream,
            text = '',
            context = {
                type = 'omichat.flip',
                heads = args.heads,
            },
        }
    end,
})

---Client → server: requests that the server refreshes the player cache for all players.
---Server → client: updates the player cache.
TOPIC.PLAYER_CACHE = dispatch:topic('PLAYER_CACHE', {
    serverTriggers = {
        dispatch.trigger.onInterval(60000),
    },

    ---@param args request.Args.UpdatePlayerCache
    ---@return string?
    onStringifyServerArgs = function(args)
        return '{"items": ' .. Request._encodeListDisplay(args.items) .. '}'
    end,

    onServerSend = function(req)
        local items = API_S.data.refreshPlayerCache()
        local args = { items = items } ---@type request.Args.UpdatePlayerCache

        req:send(args)
    end,

    ---@param args request.Args.UpdatePlayerCache
    onClientReceive = function(_, args)
        API.data.setPlayerCache(args.items)
    end,

    onServerReceive = function(req) req:broadcast() end,
})

---Client → server: report that the player died.
TOPIC.PLAYER_DEATH = dispatch:topic('PLAYER_DEATH', {
    allowDead = true,

    clientTriggers = {
        dispatch.trigger.onPlayerDeath({ onlyPlayer1 = true }),
    },

    onClientSend = function()
        local instance = ISChat.instance
        if instance then
            instance:unfocus()
            instance:close()
        end
    end,

    onServerReceive = function(req)
        local player = req:getPlayer()
        local username = player:getUsername()

        local doBroadcast = false
        local clearConfig = config.General.ClearOnDeath
        if clearConfig.Nickname then
            API_S.data.tryUpdate(player, { field = 'nickname', target = username }, false)
            doBroadcast = true
        end

        if clearConfig.Icon then
            API_S.data.tryUpdate(player, { field = 'icon', target = username }, false)
            doBroadcast = true
        end

        if clearConfig.Languages then
            API_S.data.tryUpdate(player, { field = 'languages', target = username }, false)
            doBroadcast = true
        end

        if clearConfig.Status then
            API_S.data.tryUpdate(player, { field = 'status', target = username }, false)
            doBroadcast = true
        end

        if doBroadcast then
            API_S.request.updatePlayerCache()
        end
    end,
})

---Client → server: report that a player joined.
TOPIC.PLAYER_JOINED = dispatch:topic('PLAYER_JOINED', {
    clientTriggers = {
        dispatch.trigger.onPlayerJoined(),
    },

    onServerReceive = function(req)
        req:broadcastOn(TOPIC.PLAYER_CACHE)
        req:replyWith(TOPIC.CONFIGURATION)
        req:replyWith(TOPIC.CONFIGURATION_PRESETS)
    end,
})

---Client → server: request that dice is rolled.
---Server → client: display the result of rolling dice.
TOPIC.ROLL_DICE = dispatch:topic('ROLL_DICE', {
    ---@param req omi.ClientRequest
    ---@param args request.Args.RollDice
    ---@return boolean
    ---@return string?
    onClientValidate = function(req, args)
        local player = req:getPlayer()
        if not utils.hasIgnoreItemReqPower(player) and not utils.hasAnyItemType(player, config.Commands.Roll.Items) then
            return false, 'Missing required item'
        end

        if args.sides < 1 or args.sides > 100 then
            return false, 'Invalid value for sides'
        end

        return true
    end,

    ---@param req omi.ClientRequest
    ---@param args request.Args.RollDice
    onServerReceive = function(req, args)
        local sides = args.sides
        if sides < 1 or sides > 100 then
            local replyArgs = { id = 'help-text-roll' } ---@type request.Args.ShowMessage
            req:replyWith(TOPIC.SHOW_MESSAGE, replyArgs)
            return
        end

        local player = req:getPlayer()
        local roll = utils.randInt(1, sides)
        if config.Commands.Roll.Global then
            local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

            ---@type request.Args.ShowMessage
            local replyArgs = {
                id = 'command-roll-global',
                args = {
                    name = name,
                    roll = roll,
                    sides = sides,
                },
            }

            req:broadcastOn(TOPIC.SHOW_MESSAGE, replyArgs)
        else
            local replyArgs = { roll = roll, sides = sides } ---@type request.Args.ReportRoll
            req:reply(replyArgs)
        end
    end,

    ---@param args request.Args.ReportRoll
    onClientReceive = function(_, args)
        local targetStream = API_C.streams.firstChatStreamWithTag('RollCommandTarget')
        if not targetStream then
            return
        end

        API_C.chat.send {
            allowEmpty = true,
            stream = targetStream,
            text = '',
            context = {
                type = 'omichat.roll',
                roll = args.roll,
                sides = args.sides,
            },
        }
    end,
})

---Server → client: display an info message in chat.
TOPIC.SHOW_MESSAGE = dispatch:topic('SHOW_MESSAGE', {
    ---@param args request.Args.ShowMessage
    onClientReceive = function(_, args)
        local text
        if args.text then
            text = args.text
        elseif args.id then
            text = utils.resolveTranslateTable(args)
        end

        if not text then
            return
        end

        API_C.chat.addInfoMessage(text, args.serverAlert)
    end,
})

---Server → client: notify that another player is a typing.
---Client → server: send typing information to other players.
TOPIC.TYPING = dispatch:topic('TYPING', {
    ---@param args request.Args.UpdateTyping
    onClientReceive = function(_, args)
        local typingInfo ---@type TypingInformation?

        local player = args.typing and API.data.getPlayerInfoByUsername(args.username)
        local display = player and API.data.getPlayerTypingName(player)
        if display then
            typingInfo = {
                display = display,
                lastUpdate = getTimestampMs(),
            }
        end

        API_C._typingInfo[args.username] = typingInfo
        API_C.ui.updateTypingDisplay()
    end,

    ---@param req omi.ClientRequest
    ---@param args request.Args.Typing
    onServerReceive = function(req, args)
        local sender = req:getPlayer()
        local senderUsername = sender:getUsername()
        local onlinePlayers = getOnlinePlayers()
        for i = 0, onlinePlayers:size() - 1 do
            local receiver = onlinePlayers:get(i)

            if sender ~= receiver or IS_DEBUG then
                ---@type request.Args.UpdateTyping
                local replyArgs = {
                    username = senderUsername,
                    typing = args.typing and Request._shouldSendTyping(sender, receiver, args.range, args.chatType),
                }

                TOPIC.TYPING:toPlayer(receiver, replyArgs, req)
            end
        end
    end,
})


---Gets a display string for a list in request arguments.
---Displays only the number of items.
---@param list any[]
---@return string
---@private
function Request._encodeListDisplay(list)
    local count = list and #list
    if not count or count == 0 then
        return '[]'
    elseif count == 1 then
        return '[...(1 item)]'
    end

    return '[...(' .. count .. ' items)]'
end

---Checks whether the typing indicator should be sent for a pair of players.
---@param sender IsoPlayer
---@param receiver IsoPlayer
---@param range integer?
---@param chatType omi.ChatTypeString?
---@return boolean
---@private
function Request._shouldSendTyping(sender, receiver, range, chatType)
    if sender:isInvisible() and not receiver:isInvisible() then
        return false
    end

    if range and receiver:getDistanceSq(sender) > range * range then
        return false
    end

    if chatType == 'faction' then
        local faction = Faction.getPlayerFaction(sender:getUsername())
        local other = receiver:getUsername()

        return faction and (faction:isOwner(other) or faction:isMember(other))
    elseif chatType == 'safehouse' then
        local safehouse = SafeHouse.hasSafehouse(sender:getUsername())
        return safehouse and safehouse:playerAllowed(receiver:getUsername())
    end

    return true
end


return Request

--#region Type Definitions

---@alias request.CustomizationType
---| 'GROW_BEARD'
---| 'GROW_HAIR'
---| 'CLEAN_CHARACTER'
---| 'SET_HAIR_COLOR'

---Client to server request to add or remove a user-defined configuration preset.
---@class request.Args.AddOrRemovePreset
---@field type 'ADD' | 'DELETE' The operation to complete.
---@field name string The name of the preset.
---@field values table? The configuration values.

---Client to server request to clear player data for a username.
---@class request.Args.ClearPlayerData
---@field username string The username of the player whose data should be cleared.

---Client to server request to execute a command.
---@class request.Args.Command
---@field name request.ChatCommandName The name of the command.
---@field text string The command text, excluding the command itself.

---Client to server request to perform a customization option.
---@class request.Args.Customization
---@field type request.CustomizationType The customization type to apply.
---@field hairColor? omi.ColorTable<integer> The hair color to set. Defaults to the natural hair color.

---Client to server request to update player data.
---@class request.Args.PlayerDataUpdate
---@field target string The target username.
---@field field PlayerDataField The field to update.
---@field fromCommand boolean? Flag for whether the request was created from a command.
---@field value? any The value to set on the field.

---Server to client response to a request for player data.
---@class request.Args.PlayerDataListResponse
---@field list PlayerData[] The request list of player data.

---Server to client request to report the result of drawing a card.
---@class request.Args.ReportDrawCard
---@field name string? The name of the player who drew the card, if called for a global message.
---@field card integer The card number, in [1, 13].
---@field suit integer The suit number, in [1, 4].

---Server to client request to report the result of flipping a coin.
---@class request.Args.ReportFlipCoin
---@field heads boolean Flag for whether the result of the flip was heads.

---Server to client request to report the result of rolling dice.
---@class request.Args.ReportRoll
---@field roll integer The value of the dice roll.
---@field sides integer The number of sides on the dice that was rolled.

---Server to client request to display a message.
---@class request.Args.ShowMessage : omi.PartialTranslateTable<number | string>
---@field text string? The message text.
---@field serverAlert boolean? Flag for whether this should be treated as a server alert.

---Client to server request to roll dice.
---@class request.Args.RollDice
---@field sides integer The number of sides on the dice to roll.

---Client to server request to notify other players about typing status.
---@class request.Args.Typing
---@field typing boolean Flag for whether the source player is typing.
---@field range integer? Optional range to limit notifications to.
---@field chatType omi.ChatTypeString? The chat type of the stream on which the player is typing.

---Client to server request to update the configuration.
---@class request.Args.UpdateConfiguration
---@field values Configuration The new configuration values.

---Server to client request to update typing information.
---@class request.Args.UpdateTyping
---@field username string Flag for whether the target player is typing.
---@field typing boolean Flag for whether the target player is typing.

---Client to server request to update the player cache.
---@class request.Args.UpdatePlayerCache
---@field items PlayerCacheData[] The new cache items.

---Client to server request to update the user-defined configuration presets.
---@class request.Args.UpdatePresets
---@field list Configuration.PresetTable[] The new values.

--#endregion
