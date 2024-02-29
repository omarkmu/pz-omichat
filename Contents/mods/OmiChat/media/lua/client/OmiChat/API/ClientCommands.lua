---Client API functionality related to dispatching and handling commands.

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

    sendClientCommand(player, OmiChat._modDataKey, command, args or {})
    return true
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

    local inv = player:getInventory()
    if not inv:contains('CardDeck') and player:getAccessLevel() == 'None' then
        return false
    end

    return OmiChat.dispatch('requestDrawCard')
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

    local inv = player:getInventory()
    if not inv:contains('Dice') and player:getAccessLevel() == 'None' then
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
        OmiChat.addInfoMessage(getText('UI_OmiChat_card', args.name, cardName))
        return
    end

    -- local message
    -- display english overhead & encode card values for future translation
    local cardName = concat { englishCards[card], ' of ', englishSuits[suit] }
    local content = utils.interpolate(Option.FormatCard, { card = cardName })

    content = concat {
        utils.encodeInvisibleCharacter(suit),
        utils.encodeInvisibleCharacter(card),
        content,
    }

    processSayMessage(OmiChat.formatForChat {
        text = content,
        formatterName = 'card',
        chatType = 'say',
        playSignedEmote = false,
    })
end

---Reports the results of a dice roll.
---@param args omichat.request.ReportRoll
function OmiChat.Commands.reportRoll(args)
    local roll = utils.wrapStringArgument(tostring(args.roll), 1)
    local sides = utils.wrapStringArgument(tostring(args.sides), 2)
    local content = utils.interpolate(Option.FormatRoll, { roll = roll, sides = sides })

    processSayMessage(OmiChat.formatForChat {
        text = content,
        formatterName = 'roll',
        chatType = 'say',
    })
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
