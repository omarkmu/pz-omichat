---Client API functionality related to dispatching and handling commands.

---@class omichat.api.client
local API = require 'OmiChat/API/Client/Core'

---@class omichat.api.client.commands
API.Commands = {}


local utils = API.utils
local Option = API.Option
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
function API.dispatch(command, args)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:isDead() and command ~= 'reportPlayerDeath' then
        -- prevent processing commands while dead
        return false
    end

    sendClientCommand(player, API._modDataKey, command, args or {})
    return true
end

---Reports to the server that the player died, for clearing relevant data.
---@return boolean
function API.reportPlayerDeath()
    return API.dispatch('reportPlayerDeath')
end

---Reports to the server that the player joined.
---@return boolean
function API.reportPlayerJoined()
    return API.dispatch('reportPlayerJoined')
end

---Executes the /addlanguage command.
---@param command string
---@return boolean
function API.requestAddLanguage(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return API.dispatch('requestAddLanguage', req)
end

---Executes the /clearnames command.
function API.requestClearNames()
    return API.dispatch('requestClearNames')
end

---Requests clearing mod data for a given username.
---@param username string
---@return boolean success
function API.requestClearModData(username)
    ---@type omichat.request.ClearModData
    local req = { username = username }

    return API.dispatch('requestClearModData', req)
end

---Requests an update to global mod data.
---@param updates omichat.request.ModDataUpdate
---@return boolean
function API.requestDataUpdate(updates)
    return API.dispatch('requestDataUpdate', updates)
end

---Requests drawing a card from a card deck in the player's inventory.
---@return boolean
function API.requestDrawCard()
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, Option:getCardItems()) then
        return false
    end

    return API.dispatch('requestDrawCard')
end

---Requests flipping a coin.
---@return boolean
function API.requestFlipCoin()
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if player:getAccessLevel() == 'None' and not utils.hasAnyItemType(player, Option:getCoinItems()) then
        return false
    end

    return API.dispatch('requestFlipCoin')
end

---Requests that the server updates the player cache.
---@return boolean
function API.requestPlayerCacheUpdate()
    return API.dispatch('requestPlayerCacheUpdate')
end

---Executes the /reseticon command.
---@param command string
---@return boolean
function API.requestResetIcon(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return API.dispatch('requestResetIcon', req)
end

---Executes the /resetlanguages command.
---@param command string
---@return boolean
function API.requestResetLanguages(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return API.dispatch('requestResetLanguages', req)
end

---Executes the /resetname command.
---@param command string
---@return boolean
function API.requestResetName(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return API.dispatch('requestResetName', req)
end

---Requests rolling dice.
---@param sides integer
---@return boolean
function API.requestRollDice(sides)
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

    return API.dispatch('requestRollDice', req)
end

---Executes the /seticon command.
---@param command string
---@return boolean
function API.requestSetIcon(command)
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

    return API.dispatch('requestSetIcon', req)
end

---Executes the /setlanguageslots command.
---@param command string
---@return boolean
function API.requestSetLanguageSlots(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return API.dispatch('requestSetLanguageSlots', req)
end

---Executes the /setname command.
---@param command string
---@return boolean
function API.requestSetName(command)
    ---@type omichat.request.Command
    local req = { command = command }

    return API.dispatch('requestSetName', req)
end

---Sends the current typing status to the server.
---@param range integer?
---@param chatType omichat.ChatTypeString?
---@return boolean
function API.sendTypingStatus(range, chatType)
    ---@type omichat.request.Typing
    local req = {
        range = range,
        chatType = chatType,
        typing = API.getTyping(),
    }

    return API.dispatch('requestTyping', req)
end

--#endregion

--#region handlers

---Reports the results of drawing a card.
---@param args omichat.request.ReportDrawCard
function API.Commands.reportDrawCard(args)
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
        API.addInfoMessage(getText('UI_OmiChat_Card', args.name, cardName))
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

    API.send {
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
function API.Commands.reportFlipCoin(args)
    local heads = args.heads
    local content = utils.interpolate(Option.FormatFlip, {
        heads = args.heads and '1' or nil,
    })

    API.send {
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
function API.Commands.reportRoll(args)
    local tokens = { roll = tostring(args.roll), sides = tostring(args.sides) }
    local content = utils.interpolate(Option.FormatRoll, tokens)

    API.send {
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
function API.Commands.showInfoMessage(args)
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

    API.addInfoMessage(text, args.serverAlert)
end

---Updates player cache state.
---@param info omichat.request.UpdatePlayerCache
function API.Commands.updatePlayerCache(info)
    utils.resetPlayerCache(info.items)
end

---Updates chat state.
function API.Commands.updateState()
    API.updateState(true)
end

---Updates typing state for another player.
---@param args omichat.request.UpdateTyping
function API.Commands.updateTyping(args)
    local typingInfo ---@type omichat.TypingInformation?

    local player = args.typing and utils.getPlayerInfoByUsername(args.username)
    local display = player and API.getPlayerMenuName(player, 'typing')
    if display then
        typingInfo = {
            display = display,
            lastUpdate = getTimestampMs(),
        }
    end

    API._typingInfo[args.username] = typingInfo
    API.updateTypingDisplay()
end

--#endregion


---Event handler for processing commands from the server.
---@param module string
---@param command string
---@param args table
---@protected
function API._onServerCommand(module, command, args)
    if module ~= API._modDataKey then
        return
    end

    if API.Commands[command] then
        API.Commands[command](args)
    end
end
