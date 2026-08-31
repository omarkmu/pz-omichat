---Handles defining channels for client and server requests.
---@namespace omichat
---@diagnostic disable: access-invisible

---@class(partial) api.shared
local API = require 'OmiChat/Module/Core/Shared'

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

---Creates a new dice stringifier with the given settings.
---@param includeTotal boolean? Whether to include the roll's total in the stringified result.
---@param includeValues boolean? Whether to include individual dice values in the stringified result.
local function getDiceStringifier(includeTotal, includeValues)
    return utils.dice.SimpleStringifier:new({
        includeTotal = includeTotal or false,
        includeValues = includeValues or false,
        doStrikethrough = false,
    })
end

---@class(partial) api.shared.request
local Request = {}

---Contains functions for sending server and client commands.
API.request = Request

---@class api.shared.request.channel
local CHANNEL = {}

---Contains channels for request exchanges between the server and client.
Request.CHANNEL = CHANNEL

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
CHANNEL.APPLY_BUFF = dispatch:channel('APPLY_BUFF', {
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
CHANNEL.APPLY_CUSTOMIZATION = dispatch:channel('APPLY_CUSTOMIZATION', {
    ---@param req omi.ClientRequest
    ---@param args Args.Request.Customization
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
CHANNEL.COMMAND = dispatch:channel('COMMAND', {
    ---@param args Args.Request.Command
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
    ---@param args Args.Request.Command
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
CHANNEL.CONFIGURATION = dispatch:channel('CONFIGURATION', {
    canLogArgs = false,
    requireAdmin = true,

    onSend = function(req)
        local args = { values = config:getValues() } ---@type Args.Request.UpdateConfiguration
        req:send(args)
    end,

    ---@param req omi.Request
    ---@param args Args.Request.UpdateConfiguration
    onReceive = function(req, args)
        config:load(args.values)

        if req:isFromServer() then
            API_C.chat.updateState(true)
        else
            config:saveFile()
            req:broadcast()
        end
    end,
})

---Client → server: add/remove a preset (admin only).
---Server → client: update configuration presets.
CHANNEL.CONFIGURATION_PRESETS = dispatch:channel('CONFIGURATION_PRESETS', {
    requireAdmin = true,

    ---@param args Args.Request.AddOrRemovePreset
    ---@return string?
    onStringifyClientArgs = function(args)
        return format('{"type": %q, "name": %q, "values": {...}}', args.type, args.name)
    end,

    ---@param args Args.Request.UpdatePresets
    ---@return string?
    onStringifyServerArgs = function(args)
        if #args.list > 0 then
            return '{"list": ' .. Request._encodeListDisplay(args.list) .. '}'
        end
    end,

    onServerSend = function(req)
        local args = { list = config:getCustomPresetsForSave() } ---@type Args.Request.UpdatePresets
        req:send(args)
    end,

    ---@param args Args.Request.UpdatePresets
    onClientReceive = function(_, args)
        config:_setCustomPresets(args.list) ---@diagnostic disable-line: access-invisible
    end,

    ---@param req omi.ClientRequest
    ---@param args Args.Request.AddOrRemovePreset
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
CHANNEL.DATA_CLEAR = dispatch:channel('DATA_CLEAR', {
    requireAdmin = true,

    ---@param args Args.Request.ClearPlayerData
    onServerReceive = function(_, args)
        API_S.data.clear(args.username)
        API_S.request.updatePlayerCache()
    end,
})

---Client → server: request a list of all data for all players (admin only).
---Server → client: return a list of player data.
CHANNEL.DATA_LIST = dispatch:channel('DATA_LIST', {
    requireAdmin = true,

    ---@param args Args.Request.PlayerDataListResponse
    ---@return string?
    onStringifyServerArgs = function(args)
        if #args.list > 0 then
            return '{"list": ' .. Request._encodeListDisplay(args.list) .. '}'
        end
    end,

    ---@param args Args.Request.PlayerDataListResponse
    onClientReceive = function(_, args)
        local instance = ISChat.instance --[[@as omichat.ISChat]]
        local panel = instance and instance.activePlayerDataPanel
        if not panel then
            return
        end

        panel:onUpdateList(args.list)
    end,

    onServerReceive = function(req)
        ---@type Args.Request.PlayerDataListResponse
        local resp = { list = API_S.data.getPlayerDataList() }

        req:reply(resp)
    end,
})

---Client → server: request updating data for a username.
CHANNEL.DATA_UPDATE = dispatch:channel('DATA_UPDATE', {
    ---@param req omi.ClientRequest
    ---@param args Args.Request.PlayerDataUpdate
    onServerReceive = function(req, args)
        args.fromCommand = false
        API_S.data.tryUpdate(req:getPlayer(), args)
    end,
})

---Client → server: request that a card is drawn.
---Server → client: display the result of drawing a card.
CHANNEL.DRAW_CARD = dispatch:channel('DRAW_CARD', {
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
            local args = { card = card, suit = suit } ---@type Args.Request.ReportDrawCard
            req:reply(args)
            return
        end

        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

        ---@type Args.Request.ShowMessage
        local args = {
            id = 'command-card-global',
            args = {
                name = name,
                card = {
                    id = 'card-name',
                    args = {
                        card = { id = 'card-' .. utils._cards[card] },
                        suit = { id = 'card-suit-' .. utils._suits[suit] },
                    },
                },
            },
        }

        req:broadcastOn(CHANNEL.SHOW_MESSAGE, args)
    end,

    ---@param args Args.Request.ReportDrawCard
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
CHANNEL.FLIP_COIN = dispatch:channel('FLIP_COIN', {
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
            local args = { heads = heads } ---@type Args.Request.ReportFlipCoin
            req:reply(args)
            return
        end

        local player = req:getPlayer()
        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

        ---@type Args.Request.ShowMessage
        local args = {
            id = heads and 'command-flip-heads-global' or 'command-flip-tails-global',
            args = { name = name },
        }

        req:broadcastOn(CHANNEL.SHOW_MESSAGE, args)
    end,

    ---@param args Args.Request.ReportFlipCoin
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
CHANNEL.PLAYER_CACHE = dispatch:channel('PLAYER_CACHE', {
    serverTriggers = {
        dispatch.trigger.onInterval(60000),
    },

    ---@param args Args.Request.UpdatePlayerCache
    ---@return string?
    onStringifyServerArgs = function(args)
        return '{"items": ' .. Request._encodeListDisplay(args.items) .. '}'
    end,

    onServerSend = function(req)
        local items = API_S.data.refreshPlayerCache()
        local args = { items = items } ---@type Args.Request.UpdatePlayerCache

        req:send(args)
    end,

    ---@param args Args.Request.UpdatePlayerCache
    onClientReceive = function(_, args)
        API.data.setPlayerCache(args.items)
        API_C.ui.updateLanguageIndicator()
    end,

    onServerReceive = function(req) req:broadcast() end,
})

---Client → server: report that the player died.
CHANNEL.PLAYER_DEATH = dispatch:channel('PLAYER_DEATH', {
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
CHANNEL.PLAYER_JOINED = dispatch:channel('PLAYER_JOINED', {
    clientTriggers = {
        dispatch.trigger.onPlayerJoined(),
    },

    -- TODO(vanilla bug): remove when https://theindiestone.com/forums/index.php?/channel/90037-42131 is fixed
    onClientSend = function()
        local player = API_C.player.get()
        if not player then
            return
        end

        -- due to the bug, this returns a random color
        -- this initial call is to ensure the backing field is set
        local color = getCore():getMpTextColor()

        local prefs = API_C.preferences.get()
        local profile = prefs.profiles[prefs.profileIndex]
        local speechColor = profile and profile.colors.speech

        -- since ArrayConfigOption isn't exposed, this is the best workaround as far as I can tell
        if speechColor then
            -- if a color is set on the selected profile, use it
            API_C.player.setSpeechColor(speechColor)
        else
            -- otherwise, we'll have to use the random one (which will at least be synced)
            player:setSpeakColourInfo(color)
            sendPersonalColor(player)
        end
    end,

    onServerReceive = function(req)
        req:broadcastOn(CHANNEL.PLAYER_CACHE)
        req:replyWith(CHANNEL.CONFIGURATION)
        req:replyWith(CHANNEL.CONFIGURATION_PRESETS)
    end,
})

---Client → server: request that dice is rolled.
---Server → client: display the result of rolling dice.
CHANNEL.ROLL_DICE = dispatch:channel('ROLL_DICE', {
    ---@param req omi.ClientRequest
    ---@param args Args.Request.RollDice
    ---@return boolean
    ---@return string?
    onClientValidate = function(req, args)
        local player = req:getPlayer()
        if not utils.hasIgnoreItemReqPower(player) and not utils.hasAnyItemType(player, config.Commands.Roll.Items) then
            return false, 'Missing required item'
        end

        local expr, err = utils.roller:tryParse(args.command:lower())
        if not expr then
            return false, err and err.message or nil
        end

        return true
    end,

    ---@param req omi.ClientRequest
    ---@param args Args.Request.RollDice
    onServerReceive = function(req, args)
        local command = args.command:lower()
        local expr = utils.roller:tryParse(command)
        local result = expr and utils.roller:tryRoll(expr, {
            stringifier = getDiceStringifier(
                config.Commands.Roll.IncludeSumOfRolls,
                config.Commands.Roll.IncludeIndividualRolls
            ),
        })

        local roll = result and result:tryGetTotal()
        if not roll then
            local replyArgs = { id = 'help-text-roll' } ---@type Args.Request.ShowMessage
            req:replyWith(CHANNEL.SHOW_MESSAGE, replyArgs)
            return
        end

        ---@cast result -?
        local player = req:getPlayer()
        local sides = utils.tointeger(command:match('^d(%d+)$'))
        if config.Commands.Roll.Global then
            local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()

            ---@type Args.Request.ShowMessage
            local replyArgs
            if sides then
                replyArgs = {
                    id = 'command-roll-global',
                    args = { name = name, roll = roll, sides = sides },
                }
            elseif command == 'd%' then
                replyArgs = {
                    id = 'command-roll-global-percentile',
                    args = { name = name, roll = roll },
                }
            elseif config.Commands.Roll.IncludeSumOfRolls then
                replyArgs = {
                    id = 'command-roll-global-expression',
                    args = { name = name, expression = result:getString() },
                }
            else
                replyArgs = {
                    id = 'command-roll-global-with-expression',
                    args = { name = name, roll = roll, expression = result:getString() },
                }
            end

            req:broadcastOn(CHANNEL.SHOW_MESSAGE, replyArgs)
        else
            ---@type Args.Request.ReportRoll
            local replyArgs = {
                roll = roll,
                sides = sides,
                expression = not sides and result:getString() or nil,
                isPercentile = command == 'd%',
            }

            req:reply(replyArgs)
        end
    end,

    ---@param args Args.Request.ReportRoll
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
                diceExpression = args.expression,
                percentileDice = args.isPercentile,
            },
        }
    end,
})

---Server → client: display an info message in chat.
CHANNEL.SHOW_MESSAGE = dispatch:channel('SHOW_MESSAGE', {
    ---@param args Args.Request.ShowMessage
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
CHANNEL.TYPING = dispatch:channel('TYPING', {
    ---@param args Args.Request.UpdateTyping
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
    ---@param args Args.Request.Typing
    onServerReceive = function(req, args)
        local sender = req:getPlayer()
        local senderUsername = sender:getUsername()
        local onlinePlayers = getOnlinePlayers()
        for i = 0, onlinePlayers:size() - 1 do
            local receiver = onlinePlayers:get(i)

            if sender ~= receiver or IS_DEBUG then
                ---@type Args.Request.UpdateTyping
                local replyArgs = {
                    username = senderUsername,
                    typing = args.typing and Request._shouldSendTyping(sender, receiver, args.range, args.chatType),
                }

                CHANNEL.TYPING:toPlayer(receiver, replyArgs, req)
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
---@class Args.Request.AddOrRemovePreset
---@field type 'ADD' | 'DELETE' The operation to complete.
---@field name string The name of the preset.
---@field values table? The configuration values.

---Client to server request to clear player data for a username.
---@class Args.Request.ClearPlayerData
---@field username string The username of the player whose data should be cleared.

---Client to server request to execute a command.
---@class Args.Request.Command
---@field name request.ChatCommandName The name of the command.
---@field text string The command text, excluding the command itself.

---Client to server request to perform a customization option.
---@class Args.Request.Customization
---@field type request.CustomizationType The customization type to apply.
---@field hairColor? omi.ColorTable<integer> The hair color to set. Defaults to the natural hair color.

---Client to server request to update player data.
---@class Args.Request.PlayerDataUpdate
---@field target string The target username.
---@field field PlayerDataField The field to update.
---@field fromCommand boolean? Flag for whether the request was created from a command.
---@field value? any The value to set on the field.

---Server to client response to a request for player data.
---@class Args.Request.PlayerDataListResponse
---@field list PlayerData[] The request list of player data.

---Server to client request to report the result of drawing a card.
---@class Args.Request.ReportDrawCard
---@field name string? The name of the player who drew the card, if called for a global message.
---@field card integer The card number, in [1, 13].
---@field suit integer The suit number, in [1, 4].

---Server to client request to report the result of flipping a coin.
---@class Args.Request.ReportFlipCoin
---@field heads boolean Flag for whether the result of the flip was heads.

---Server to client request to report the result of rolling dice.
---@class Args.Request.ReportRoll
---@field roll integer The value of the dice roll.
---@field expression string? The expression for a dice roll. Only included for complex rolls.
---@field isPercentile boolean? Flag for whether a single percentile dice was rolled.
---@field sides integer? The number of sides on the dice that was rolled. Only included for simple rolls.

---Server to client request to display a message.
---@class Args.Request.ShowMessage : omi.PartialTranslateTable<number | string>
---@field text string? The message text.
---@field serverAlert boolean? Flag for whether this should be treated as a server alert.

---Client to server request to roll dice.
---@class Args.Request.RollDice
---@field command string A dice expression for the roll (e.g., d6, 2d20, 5d10kh1+3).

---Client to server request to notify other players about typing status.
---@class Args.Request.Typing
---@field typing boolean Flag for whether the source player is typing.
---@field range integer? Optional range to limit notifications to.
---@field chatType omi.ChatTypeString? The chat type of the stream on which the player is typing.

---Client to server request to update the configuration.
---@class Args.Request.UpdateConfiguration
---@field values Configuration The new configuration values.

---Server to client request to update typing information.
---@class Args.Request.UpdateTyping
---@field username string Flag for whether the target player is typing.
---@field typing boolean Flag for whether the target player is typing.

---Client to server request to update the player cache.
---@class Args.Request.UpdatePlayerCache
---@field items PlayerCacheData[] The new cache items.

---Client to server request to update the user-defined configuration presets.
---@class Args.Request.UpdatePresets
---@field list Configuration.PresetTable[] The new values.

--#endregion
