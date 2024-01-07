---Client command handling.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
OmiChat.Commands = {}


local utils = OmiChat.utils
local Option = OmiChat.Option
local unpack = unpack
local concat = table.concat

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
        OmiChat.showInfoMessage(getText('UI_OmiChat_card', args.name, cardName))
        return
    end

    -- local message
    -- display english overhead & encode card values for future translation
    local language
    local cardName = concat { englishCards[card], ' of ', englishSuits[suit] }
    local content = utils.interpolate(Option.FormatCard, { card = cardName })
    if OmiChat.canUseRoleplayLanguage('card', content) then
        content, language = OmiChat.getLanguageEncodedText(content, false)
    end

    local formatter = OmiChat.getFormatter('card')
    content = formatter:format(concat {
        utils.encodeInvisibleCharacter(suit),
        utils.encodeInvisibleCharacter(card),
        content,
    })

    processSayMessage(OmiChat.formatOverheadText(content, 'card', language))
end

---Reports the results of a dice roll.
---@param args omichat.request.ReportRoll
function OmiChat.Commands.reportRoll(args)
    local rollChar = utils.encodeInvisibleCharacter(1)
    local sidesChar = utils.encodeInvisibleCharacter(2)

    local roll = concat { rollChar, tostring(args.roll), rollChar }
    local sides = concat { sidesChar, tostring(args.sides), sidesChar }
    local content = utils.interpolate(Option.FormatRoll, { roll = roll, sides = sides })

    local language
    if OmiChat.canUseRoleplayLanguage('roll', content) then
        content, language = OmiChat.getLanguageEncodedText(content, false)
    end

    local formatted = OmiChat.getFormatter('roll'):format(content)
    processSayMessage(OmiChat.formatOverheadText(formatted, 'roll', language))
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

    OmiChat.showInfoMessage(text, args.serverAlert)
end


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
