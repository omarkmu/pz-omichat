---Handles commands from the server.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local unpack = unpack
local getTimestampMs = getTimestampMs


---@class omichat.api.client.requestHandlers
local ClientHandler = {}


local COMMAND_ARGS_START = utils.encodeInvisibleCharacter(config.ID_COMMAND_ARGS)

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


---Reports the results of drawing a card.
---@param args omichat.request.ReportDrawCard
function ClientHandler.reportDrawCard(args)
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
        API.chat.addInfoMessage(getText('UI_OmiChat_Card', args.name, cardName))
        return
    end

    -- local message
    local commandStream = API._cardCommand
    local targetStream = API.streams.firstChatStreamWithTag('CardCommandTarget')
    if not targetStream then
        return
    end

    -- display English text overhead, encode card values for per-client translation
    local cardName = englishCards[card] .. ' of ' .. englishSuits[suit]
    local content = utils.interpolateNamed('FormatCard', config.Commands.Card.Format, {
        suit = suit,
        number = card,
        card = cardName,
    })

    local result = utils.encodeInvisibleCharacter(suit) .. utils.encodeInvisibleCharacter(card)
    local encoded = COMMAND_ARGS_START .. result

    API.chat.send {
        stream = targetStream,
        formatStream = commandStream,
        text = encoded .. content,
    }
end

---Reports the results of flipping a coin.
---@param args omichat.request.ReportFlipCoin
function ClientHandler.reportFlipCoin(args)
    local commandStream = API._flipCommand
    local targetStream = API.streams.firstChatStreamWithTag('FlipCommandTarget')
    if not targetStream then
        return
    end

    local heads = args.heads
    local content = utils.interpolateNamed('FormatFlip', config.Commands.Flip.Format, {
        heads = args.heads and '1' or nil,
    })

    local result = utils.encodeInvisibleCharacter(heads and 1 or 2)
    local encoded = COMMAND_ARGS_START .. result

    API.chat.send {
        stream = targetStream,
        formatStream = commandStream,
        text = encoded .. content,
    }
end

---Reports the results of a dice roll.
---@param args omichat.request.ReportRoll
function ClientHandler.reportRoll(args)
    local commandStream = API._rollCommand
    local targetStream = API.streams.firstChatStreamWithTag('RollCommandTarget')
    if not targetStream then
        return
    end

    local tokens = { roll = tostring(args.roll), sides = tostring(args.sides) }
    local content = utils.interpolateNamed('FormatRoll', config.Commands.Roll.Format, tokens)

    local result = utils.encodeInvisibleInt(args.roll) .. utils.encodeInvisibleInt(args.sides)
    local encoded = COMMAND_ARGS_START .. result

    API.chat.send {
        stream = targetStream,
        formatStream = commandStream,
        text = encoded .. content,
    }
end

---Adds an info message for the local player.
---@param args omichat.request.ShowMessage
function ClientHandler.showInfoMessage(args)
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

    API.chat.addInfoMessage(text, args.serverAlert)
end

---Updates the configuration with new data from the server.
---@param req omichat.request.UpdateConfiguration
function ClientHandler.updateConfiguration(req)
    config:load(req.value)
    API.chat.updateState(true)
end

---Updates player cache state.
---@param info omichat.request.UpdatePlayerCache
function ClientHandler.updatePlayerCache(info)
    API.data.resetPlayerCache(info.items)
end

---Updates chat state.
function ClientHandler.updateState()
    API.chat.updateState(true)
end

---Updates typing state for another player.
---@param args omichat.request.UpdateTyping
function ClientHandler.updateTyping(args)
    local typingInfo ---@type omichat.TypingInformation?

    local player = args.typing and API.data.getPlayerInfoByUsername(args.username)
    local display = player and API.data.getPlayerMenuName(player, 'typing')
    if display then
        typingInfo = {
            display = display,
            lastUpdate = getTimestampMs(),
        }
    end

    API._typingInfo[args.username] = typingInfo
    API.ui.updateTypingDisplay()
end


API.handlers = ClientHandler
return ClientHandler
