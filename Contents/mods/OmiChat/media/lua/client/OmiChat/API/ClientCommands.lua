---Client API functionality related to dispatching and handling commands.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

---@class omichat.api.client.commands
OmiChat.Commands = {}


local utils = OmiChat.utils
local Option = OmiChat.Option
local unpack = unpack
local concat = table.concat
local getTimestampMs = getTimestampMs

local englishSuits = {
    'Clubs',
    'Diamonds',
    'Hearts',
    'Spades',
}
local englishCards = {
    'the Ace',
    'a Two',
    'a Three',
    'a Four',
    'a Five',
    'a Six',
    'a Seven',
    'an Eight',
    'a Nine',
    'a Ten',
    'the Jack',
    'the Queen',
    'the King',
}


--#region dispatch

---Dispatches a client command.
---@param command string
---@param args table?
---@return boolean success Whether the command was successfully sent.
function OmiChat.dispatch(command, args)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:isDead() and command ~= 'reportPlayerDeath' then
        -- prevent processing commands while dead
        return false
    end

    sendClientCommand(player, OmiChat._modDataKey, command, args or {})
    return true
end

---Reports to the server that the player died, for clearing relevant data.
---@return boolean
function OmiChat.reportPlayerDeath()
    return OmiChat.dispatch('reportPlayerDeath')
end

---Reports to the server that the player joined.
---@return boolean
function OmiChat.reportPlayerJoined()
    return OmiChat.dispatch('reportPlayerJoined')
end

---Executes the /addlanguage command.
---@param command string
---@return boolean
function OmiChat.requestAddLanguage(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return OmiChat.dispatch('requestAddLanguage', req)
end

---Executes the /clearnames command.
function OmiChat.requestClearNames()
    return OmiChat.dispatch('requestClearNames')
end

---Requests clearing mod data for a given username.
---@param username string
---@return boolean success
function OmiChat.requestClearModData(username)
    ---@type omichat.request.ClearModData
    local req = { username = username }

    return OmiChat.dispatch('requestClearModData', req)
end

---Requests an update to global mod data.
---@param updates omichat.request.ModDataUpdate
---@return boolean
function OmiChat.requestDataUpdate(updates)
    return OmiChat.dispatch('requestDataUpdate', updates)
end

---Requests drawing a card from a card deck in the player's inventory.
---@return boolean
function OmiChat.requestDrawCard()
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, Option:getCardItems()) then
        return false
    end

    return OmiChat.dispatch('requestDrawCard')
end

---Requests flipping a coin.
---@return boolean
function OmiChat.requestFlipCoin()
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, Option:getCoinItems()) then
        return false
    end

    return OmiChat.dispatch('requestFlipCoin')
end

---Requests that the server updates the player cache.
---@return boolean
function OmiChat.requestPlayerCacheUpdate()
    return OmiChat.dispatch('requestPlayerCacheUpdate')
end

---Executes the /reseticon command.
---@param command string
---@return boolean
function OmiChat.requestResetIcon(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return OmiChat.dispatch('requestResetIcon', req)
end

---Executes the /resetlanguages command.
---@param command string
---@return boolean
function OmiChat.requestResetLanguages(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return OmiChat.dispatch('requestResetLanguages', req)
end

---Executes the /resetname command.
---@param command string
---@return boolean
function OmiChat.requestResetName(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return OmiChat.dispatch('requestResetName', req)
end

---Requests rolling dice.
---@param sides integer
---@return boolean
function OmiChat.requestRollDice(sides)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, Option:getDiceItems()) then
        return false
    end

    if not sides or sides < 1 or sides > 100 then
        return false
    end

    ---@type omichat.request.RollDice
    local req = { sides = sides }

    return OmiChat.dispatch('requestRollDice', req)
end

---Executes the /seticon command.
---@param command string
---@return boolean
function OmiChat.requestSetIcon(command)
    -- need to process client-side for texture information
    local args = utils.parseCommandArgs(command)
    local username = args[1]
    local icon = args[2]

    if not username or not icon then
        return false
    end

    if not getTexture(icon) then
        local textureName = utils.getTextureNameFromIcon(icon)
        if textureName and getTexture(textureName) then
            command = table.concat { string.format('%q', username), textureName }
        else
            return false
        end
    end

    ---@type omichat.request.Command
    local req = { command = command }

    return OmiChat.dispatch('requestSetIcon', req)
end

---Executes the /setlanguageslots command.
---@param command string
---@return boolean
function OmiChat.requestSetLanguageSlots(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return OmiChat.dispatch('requestSetLanguageSlots', req)
end

---Executes the /setname command.
---@param command string
---@return boolean
function OmiChat.requestSetName(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return OmiChat.dispatch('requestSetName', req)
end

---Sends the current typing status to the server.
---@param range integer?
---@param chatType omichat.ChatTypeString?
---@return boolean
function OmiChat.sendTypingStatus(range, chatType)
    ---@type omichat.request.Typing
    local req = {
        range = range,
        chatType = chatType,
        typing = OmiChat.getTyping(),
    }

    return OmiChat.dispatch('requestTyping', req)
end

--#endregion

--#region handlers

---Reports the results of drawing a card.
---@param args omichat.request.ReportDrawCard
function OmiChat.Commands.reportDrawCard(args)
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
        local cardName = utils.getTranslatedCardName(card, suit)
        OmiChat.addInfoMessage(getText('UI_OmiChat_Card', args.name, cardName))
        return
    end

    -- local message
    -- display english overhead & encode card values for future translation
    local cardName = concat { englishCards[card], ' of ', englishSuits[suit] }
    local content = utils.interpolate(Option.FormatCard, {
        suit = suit,
        number = card,
        card = cardName,
    })

    OmiChat.send {
        streamName = 'card',
        formatterName = 'card',
        text = concat {
            utils.encodeInvisibleCharacter(suit),
            utils.encodeInvisibleCharacter(card),
            content,
        },
    }
end

---Reports the results of flipping a coin.
---@param args omichat.request.ReportFlipCoin
function OmiChat.Commands.reportFlipCoin(args)
    local heads = args.heads
    local content = utils.interpolate(Option.FormatFlip, {
        heads = args.heads and '1' or nil,
    })

    OmiChat.send {
        streamName = 'flip',
        formatterName = 'flip',
        text = concat {
            utils.encodeInvisibleCharacter(heads and 1 or 2),
            content,
        },
    }
end

---Reports the results of a dice roll.
---@param args omichat.request.ReportRoll
function OmiChat.Commands.reportRoll(args)
    local tokens = { roll = tostring(args.roll), sides = tostring(args.sides) }
    local content = utils.interpolate(Option.FormatRoll, tokens)

    OmiChat.send {
        streamName = 'roll',
        formatterName = 'roll',
        text = concat {
            utils.encodeInvisibleInt(args.roll),
            utils.encodeInvisibleInt(args.sides),
            content,
        },
    }
end

---Adds an info message for the local player.
---@param args omichat.request.ShowMessage
function OmiChat.Commands.showInfoMessage(args)
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

    OmiChat.addInfoMessage(text, args.serverAlert)
end

---Updates player cache state.
---@param info omichat.request.UpdatePlayerCache
function OmiChat.Commands.updatePlayerCache(info)
    utils.resetPlayerCache(info.items)
end

---Updates chat state.
function OmiChat.Commands.updateState()
    OmiChat.updateState(true)
end

---Updates typing state for another player.
---@param args omichat.request.UpdateTyping
function OmiChat.Commands.updateTyping(args)
    local typingInfo ---@type omichat.TypingInformation?

    local player = args.typing and utils.getPlayerInfoByUsername(args.username)
    local display = player and OmiChat.getPlayerMenuName(player, 'typing')
    if display then
        typingInfo = {
            display = display,
            lastUpdate = getTimestampMs(),
        }
    end

    OmiChat._typingInfo[args.username] = typingInfo
    OmiChat.updateTypingDisplay()
end

--#endregion


---Event handler for processing commands from the server.
---@param module string
---@param command string
---@param args table
---@protected
function OmiChat._onServerCommand(module, command, args)
    if module ~= OmiChat._modDataKey then
        return
    end

    if OmiChat.Commands[command] then
        OmiChat.Commands[command](args)
    end
end
