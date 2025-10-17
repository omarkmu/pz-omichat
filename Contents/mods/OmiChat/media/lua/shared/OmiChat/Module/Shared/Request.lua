---Handles defining topics for client and server requests.

local API = require 'OmiChat/Module/Shared/Core' ---@class omichat.api.shared
local API_C = API ---@class omichat.api.client
local API_S = API ---@class omichat.api.server

local utils = API.utils
local config = API.Configuration

local unpack = unpack
local format = string.format
local getTimestampMs = getTimestampMs
local getOnlinePlayers = getOnlinePlayers

local IS_DEBUG = getDebug()
local COMMAND_ARGS_START = utils.encodeInvisibleCharacter(config.ID_COMMAND_ARGS)

local dispatch = utils.dispatch {
    module = API._key,
    logger = utils.log,
    enableLogs = IS_DEBUG,
}


---@class omichat.api.shared.request
local Request = {}
Request.TOPIC = {} ---@class omichat.api.shared.request.topics
Request.dispatch = dispatch

local Topic = Request.TOPIC


---Client → server: Execute a chat command.
Request.TOPIC.COMMAND = dispatch:topic('COMMAND', {
    ---@param args omichat.request.Command
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
                args.text = string.format('%q', username) .. ' ' .. textureName
            else
                return false, 'Unknown icon'
            end
        end

        return true
    end,

    ---@param req omi.ClientRequest
    ---@param args omichat.request.Command
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
Request.TOPIC.CONFIGURATION = dispatch:topic('CONFIGURATION', {
    canLogArgs = false,
    requireAdmin = true,

    onSend = function(req)
        local args = { values = config:getValues() } ---@type omichat.request.UpdateConfiguration
        req:send(args)
    end,

    ---@param req omi.Request
    ---@param args omichat.request.UpdateConfiguration
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
Request.TOPIC.CONFIGURATION_PRESETS = dispatch:topic('CONFIGURATION_PRESETS', {
    requireAdmin = true,

    ---@param args omichat.request.AddOrRemovePreset
    ---@return string?
    onStringifyClientArgs = function(args)
        return format('{"type": %q, "name": %q, "values": {...}}', args.type, args.name)
    end,

    ---@param args omichat.request.UpdatePresets
    ---@return string?
    onStringifyServerArgs = function(args)
        if #args.list > 0 then
            return '{"list": ' .. Request._encodeListDisplay(args.list) .. '}'
        end
    end,

    onServerSend = function(req)
        local args = { list = config:getCustomPresetsSimple() } ---@type omichat.request.UpdatePresets
        req:send(args)
    end,

    ---@param args omichat.request.UpdatePresets
    onClientReceive = function(_, args)
        config:_setCustomPresets(args.list) ---@diagnostic disable-line: invisible
    end,

    ---@param req omi.ClientRequest
    ---@param args omichat.request.AddOrRemovePreset
    onServerReceive = function(req, args)
        if args.type == 'DELETE' then
            API_S.extension.removeCustomPreset(args.name)
        elseif args.values then
            API_S.extension.addCustomPreset(args.name, args.values)
        end

        req:broadcast()
    end,
})

---Client → server: request clearing data for a username (admin only).
Request.TOPIC.DATA_CLEAR = dispatch:topic('DATA_CLEAR', {
    requireAdmin = true,

    ---@param args omichat.request.ClearModData
    onServerReceive = function(_, args)
        API_S.data.clear(args.username)
        API_S.request.updatePlayerCache()
    end,
})

---Client → server: request a list of all data for all players (admin only).
---Server → client: return a list of player data.
Request.TOPIC.DATA_LIST = dispatch:topic('DATA_LIST', {
    requireAdmin = true,

    ---@param args omichat.request.ModDataListResponse
    ---@return string?
    onStringifyServerArgs = function(args)
        if #args.list > 0 then
            return '{"list": ' .. Request._encodeListDisplay(args.list) .. '}'
        end
    end,

    ---@param args omichat.request.ModDataListResponse
    onClientReceive = function(_, args)
        local instance = ISChat.instance --[[@as omichat.ISChat]]
        local panel = instance and instance.activePlayerDataPanel
        if not panel then
            return
        end

        panel:onUpdateList(args.list)
    end,

    onServerReceive = function(req)
        ---@type omichat.request.ModDataListResponse
        local resp = { list = API_S.data.getPlayerDataList() }

        req:reply(resp)
    end,
})

---Client → server: request updating data for a username.
Request.TOPIC.DATA_UPDATE = dispatch:topic('DATA_UPDATE', {
    ---@param req omi.ClientRequest
    ---@param args omichat.request.ModDataUpdate
    onServerReceive = function(req, args)
        args.fromCommand = false
        API_S.data.tryUpdate(req:getPlayer(), args)
    end,
})

---Client → server: request that a card is drawn.
---Server → client: display the result of drawing a card.
Request.TOPIC.DRAW_CARD = dispatch:topic('DRAW_CARD', {
    onClientValidate = function(req)
        local player = req:getPlayer()
        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config.Commands.Card.Items) then
            return false, 'Missing required item'
        end

        return true
    end,

    onServerReceive = function(req)
        local player = req:getPlayer()
        local suit = 1 + ZombRand(4)
        local card = 1 + ZombRand(13)

        if config.Commands.Card.Global then
            local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
            local args = { name = name, card = card, suit = suit } ---@type omichat.request.ReportDrawCard

            req:broadcast(args)
        else
            local args = { card = card, suit = suit } ---@type omichat.request.ReportDrawCard
            req:reply(args)
        end
    end,

    ---@param args omichat.request.ReportDrawCard
    onClientReceive = function(_, args)
        local card = tonumber(args.card)
        if not card or card < 1 or card > 13 then
            return
        end

        local suit = tonumber(args.suit)
        if not suit or suit < 1 or suit > 4 then
            return
        end

        -- global message
        if args.name then
            -- "global" on the client because the card name needs to be translated locally
            local cardName = utils.getTranslatedCardName(card, suit)
            API_C.chat.addInfoMessage(getText('UI_OmiChat_Card', args.name, cardName))
            return
        end

        -- local message
        local commandStream = API_C._cardCommand
        local targetStream = API_C.streams.firstChatStreamWithTag('CardCommandTarget')
        if not targetStream then
            return
        end

        -- display English text overhead, encode card values for per-client translation
        local cardName = utils.getCardName(card, suit)
        local content = utils.interpolateNamed('FormatCard', config.Commands.Card.Format, {
            suit = suit,
            number = card,
            card = cardName,
        })

        local result = utils.encodeInvisibleCharacter(suit) .. utils.encodeInvisibleCharacter(card)
        local encoded = COMMAND_ARGS_START .. result

        API_C.chat.send {
            allowInvisible = true,
            stream = targetStream,
            formatStream = commandStream,
            text = encoded .. content,
        }
    end,
})

---Client → server: request that a coin is flipped.
---Server → client: display the result of flipping a coin.
Request.TOPIC.FLIP_COIN = dispatch:topic('FLIP_COIN', {
    onClientValidate = function(req)
        local player = req:getPlayer()
        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config.Commands.Flip.Items) then
            return false, 'Missing required item'
        end

        return true
    end,

    onServerReceive = function(req)
        local heads = ZombRand(2) == 0
        if not config.Commands.Flip.Global then
            local args = { heads = heads } ---@type omichat.request.ReportFlipCoin
            req:reply(args)
            return
        end

        local player = req:getPlayer()
        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

        ---@type omichat.request.ShowMessage
        local args = {
            stringID = 'UI_OmiChat_Flip' .. (heads and 'Heads' or 'Tails'),
            args = { name },
        }

        req:broadcastOn(Topic.SHOW_MESSAGE, args)
    end,

    ---@param args omichat.request.ReportFlipCoin
    onClientReceive = function(_, args)
        local commandStream = API_C._flipCommand
        local targetStream = API_C.streams.firstChatStreamWithTag('FlipCommandTarget')
        if not targetStream then
            return
        end

        local heads = args.heads
        local content = utils.interpolateNamed('FormatFlip', config.Commands.Flip.Format, {
            heads = args.heads and '1' or nil,
        })

        local result = utils.encodeInvisibleCharacter(heads and 1 or 2)
        local encoded = COMMAND_ARGS_START .. result

        API_C.chat.send {
            allowInvisible = true,
            stream = targetStream,
            formatStream = commandStream,
            text = encoded .. content,
        }
    end,
})

---Client → server: requests that the server refreshes the player cache for all players.
---Server → client: updates the player cache.
Request.TOPIC.PLAYER_CACHE = dispatch:topic('PLAYER_CACHE', {
    serverTriggers = {
        dispatch.trigger.onInterval(60000),
    },

    ---@param args omichat.request.UpdatePlayerCache
    ---@return string?
    onStringifyServerArgs = function(args)
        return '{"items": ' .. Request._encodeListDisplay(args.items) .. '}'
    end,

    onServerSend = function(req)
        local items = API_S.data.refreshPlayerCache()
        local args = { items = items } ---@type omichat.request.UpdatePlayerCache

        req:send(args)
    end,

    ---@param args omichat.request.UpdatePlayerCache
    onClientReceive = function(_, args)
        API.data.setPlayerCache(args.items)
    end,

    onServerReceive = function(req) req:broadcast() end,
})

---Client → server: report that the player died.
Request.TOPIC.PLAYER_DEATH = dispatch:topic('PLAYER_DEATH', {
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
Request.TOPIC.PLAYER_JOINED = dispatch:topic('PLAYER_JOINED', {
    clientTriggers = {
        dispatch.trigger.onPlayerJoined(),
    },

    onServerReceive = function(req)
        req:broadcastOn(Topic.PLAYER_CACHE)
        req:replyWith(Topic.CONFIGURATION)
        req:replyWith(Topic.CONFIGURATION_PRESETS)
    end,
})

---Client → server: request that dice is rolled.
---Server → client: display the result of rolling dice.
Request.TOPIC.ROLL_DICE = dispatch:topic('ROLL_DICE', {
    ---@param req omi.ClientRequest
    ---@param args omichat.request.RollDice
    ---@return boolean
    ---@return string?
    onClientValidate = function(req, args)
        local player = req:getPlayer()
        if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, config.Commands.Roll.Items) then
            return false, 'Missing required item'
        end

        if args.sides < 1 or args.sides > 100 then
            return false, 'Invalid value for sides'
        end

        return true
    end,

    ---@param req omi.ClientRequest
    ---@param args omichat.request.RollDice
    onServerReceive = function(req, args)
        local sides = args.sides
        if sides < 1 or sides > 100 then
            local replyArgs = { stringID = 'UI_ServerOptionDesc_Roll' } ---@type omichat.request.ShowMessage
            req:replyWith(Topic.SHOW_MESSAGE, replyArgs)
            return
        end

        local player = req:getPlayer()
        local roll = 1 + ZombRand(sides)
        if config.Commands.Roll.Global then
            local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

            ---@type omichat.request.ShowMessage
            local replyArgs = {
                stringID = 'UI_OmiChat_Roll',
                args = { name, tostring(roll), tostring(sides) },
            }

            req:broadcastOn(Topic.SHOW_MESSAGE, replyArgs)
        else
            local replyArgs = { roll = roll, sides = sides } ---@type omichat.request.ReportRoll
            req:reply(replyArgs)
        end
    end,

    ---@param args omichat.request.ReportRoll
    onClientReceive = function(_, args)
        local commandStream = API_C._rollCommand
        local targetStream = API_C.streams.firstChatStreamWithTag('RollCommandTarget')
        if not targetStream then
            return
        end

        local tokens = { roll = tostring(args.roll), sides = tostring(args.sides) }
        local content = utils.interpolateNamed('FormatRoll', config.Commands.Roll.Format, tokens)

        local result = utils.encodeInvisibleInt(args.roll) .. utils.encodeInvisibleInt(args.sides)
        local encoded = COMMAND_ARGS_START .. result

        API_C.chat.send {
            allowInvisible = true,
            stream = targetStream,
            formatStream = commandStream,
            text = encoded .. content,
        }
    end,
})

---Server → client: display an info message in chat.
Request.TOPIC.SHOW_MESSAGE = dispatch:topic('SHOW_MESSAGE', {
    ---@param args omichat.request.ShowMessage
    onClientReceive = function(_, args)
        local text
        if args.text then
            text = args.text
        elseif args.stringID then
            local substitutions = args.args or {}
            text = getText(args.stringID, unpack(substitutions))
        end

        if not text then
            return
        end

        API_C.chat.addInfoMessage(text, args.serverAlert)
    end,
})

---Server → client: notify that another player is a typing.
---Client → server: send typing information to other players.
Request.TOPIC.TYPING = dispatch:topic('TYPING', {
    ---@param args omichat.request.UpdateTyping
    onClientReceive = function(_, args)
        local typingInfo ---@type omichat.TypingInformation?

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
    ---@param args omichat.request.Typing
    onServerReceive = function(req, args)
        local sender = req:getPlayer()
        local senderUsername = sender:getUsername()
        local onlinePlayers = getOnlinePlayers()
        for i = 0, onlinePlayers:size() - 1 do
            local receiver = onlinePlayers:get(i)

            if sender ~= receiver or IS_DEBUG then
                ---@type omichat.request.Args.UpdateTyping
                local replyArgs = {
                    username = senderUsername,
                    typing = args.typing and Request._shouldSendTyping(sender, receiver, args.range, args.chatType),
                }

                Topic.TYPING:toPlayer(receiver, replyArgs, req)
            end
        end
    end,
})


---Checks whether a player has permission to execute a command for the given target username.
---@param player IsoPlayer
---@param target string
---@param fromCommand boolean?
---@return boolean
---@private
function Request._canAccessTarget(player, target, fromCommand)
    return utils.canAccessTarget(player, target, config.General.MinimumCommandAccessLevel, fromCommand)
end

---Gets a display string for a list in request arguments.
---Displays only the number of items.
---@param list unknown[]
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
---@param player IsoPlayer
---@param otherPlayer IsoPlayer
---@param range integer?
---@param chatType omichat.ChatTypeString?
---@return boolean
---@private
function Request._shouldSendTyping(player, otherPlayer, range, chatType)
    if player:isInvisible() and not otherPlayer:isInvisible() then
        return false
    end

    if range then
        local xDiff = otherPlayer:getX() - player:getX()
        local yDiff = otherPlayer:getY() - player:getY()
        if math.sqrt(xDiff * xDiff + yDiff * yDiff) > range then
            return false
        end
    end

    if chatType == 'faction' then
        local faction = Faction.getPlayerFaction(player:getUsername())
        local other = otherPlayer:getUsername()

        return faction and (faction:isOwner(other) or faction:isMember(other))
    elseif chatType == 'safehouse' then
        local safehouse = SafeHouse.hasSafehouse(player:getUsername())
        return safehouse and safehouse:playerAllowed(otherPlayer:getUsername())
    end

    return true
end


API.request = Request
return Request
