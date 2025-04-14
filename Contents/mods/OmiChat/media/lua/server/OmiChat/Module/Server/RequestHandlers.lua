---Handles client requests.

if isClient() then return end

local API = require 'OmiChat/Module/Server/Core' ---@class omichat.api.server
local config = API.Configuration
local utils = API.utils


---@class omichat.api.server.requestHandlers
local ServerHandler = {}


---Handlers for commands.
---@type table<omichat.request.CommandName, function>
ServerHandler.Command = {}

---Handlers for mod data update requests.
---@type table<omichat.ModDataField, function>
ServerHandler.ModData = {}



---Handles the /addlanguage command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.Command.addLanguage(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local language = args[2]

    local err
    local success = false
    if username and language then
        success, err = ServerHandler.requestDataUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
            value = language,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'FULL' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageFull', { username })
        elseif err == 'ALREADY_KNOW' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageKnown', { username, language })
        elseif err == 'UNKNOWN' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_AddLanguageNotConfigured', { language })
        elseif err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_AddLanguage')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_AddLanguageOther', { username, language })
end

---Handles the /clearnames command.
---@param player IsoPlayer
function ServerHandler.Command.clearNames(player)
    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if access < config.General.MinimumCommandAccessLevel then
        return
    end

    API.data.clearNicknames()
    API.data.transmit()
    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ClearNames')
end

---Handles the /reseticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.Command.resetIcon(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = ServerHandler.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetIcon')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetIconOther', { username })
end

---Handles the /resetlanguages command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.Command.resetLanguages(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = ServerHandler.requestDataUpdate(player, {
            target = username,
            field = 'languages',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetLanguages')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetLanguagesOther', { username })
end

---Handles the /resetname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.Command.resetName(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]

    local err
    local success = false
    if username then
        success, err = ServerHandler.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_ResetName')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_ResetNameOther', { username })
end

---Handles the /seticon command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.Command.setIcon(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local icon = args[2]

    local err
    local success = false
    if username and icon then
        success, err = ServerHandler.requestDataUpdate(player, {
            target = username,
            field = 'icons',
            value = icon,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetIcon')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetIconOther', { username })
end

---Handles the /setlanguageslots command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.Command.setLanguageSlots(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local slots = args[2]

    local err
    local success = false
    if username and slots then
        success, err = ServerHandler.requestDataUpdate(player, {
            target = username,
            field = 'languageSlots',
            fromCommand = true,
            value = slots,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetLanguageSlots')
        end

        return
    end

    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetLanguageSlotsOther', { username, slots })
end

---Handles the /setname command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.Command.setName(player, args)
    args = utils.parseCommandArgs(args.text)
    local username = args[1]
    local name = args[2]

    local err
    local success = false
    if username and name then
        success, err = ServerHandler.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
            value = name,
            fromCommand = true,
        })
    end

    username = utils.escapeRichText(username)
    if not success then
        if err == 'UNKNOWN_PLAYER' then
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Error_UnknownPlayer', { username })
        else
            API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_HelpText_SetName')
        end

        return
    end

    name = utils.escapeRichText(name)
    API.request.sendTranslatedInfoMessage(player, 'UI_OmiChat_Success_SetNameOther', { username, name })
end


---Updates all mod data for a player.
---@param args omichat.request.ModDataUpdate
---@return boolean
function ServerHandler.ModData.all(args)
    if not args.value then
        return false
    end

    API.data.setPlayerData(args.target, args.value)
    return true
end

---Updates a player's currently active roleplay language.
---@param args omichat.request.ModDataUpdate
---@return boolean
function ServerHandler.ModData.currentLanguage(args)
    if not args.value then
        return false
    end

    return API.data.setCurrentLanguage(args.target, args.value)
end

---Updates a player's chat icon.
---@param args omichat.request.ModDataUpdate
---@return boolean
function ServerHandler.ModData.icons(args)
    API.data.setChatIcon(args.target, args.value and tostring(args.value) or nil)
    return true
end

---Updates a player's known roleplay languages.
---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
function ServerHandler.ModData.languages(args)
    if not args.value then
        API.data.resetLanguages(args.target)
        return true
    end

    return API.data.addLanguage(args.target, args.value)
end

---Updates a player's roleplay language slots.
---@param args omichat.request.ModDataUpdate
---@return boolean
function ServerHandler.ModData.languageSlots(args)
    local slots = tonumber(args.value)
    if not slots then
        return false
    end

    return API.data.setLanguageSlots(args.target, slots)
end

---Updates a player's chat nickname.
---@param args omichat.request.ModDataUpdate
---@return boolean
function ServerHandler.ModData.nicknames(args)
    if not config:isNicknameEnabled() and not args.fromCommand then
        return false
    end

    API.data.setNickname(args.target, args.value and tostring(args.value) or nil)
    return true
end

---Updates a player's status text.
---@param args omichat.request.ModDataUpdate
---@return boolean
function ServerHandler.ModData.statuses(args)
    if not config.Commands.Status.Enable and not args.fromCommand then
        return false
    end

    API.data.setStatus(args.target, args.value and tostring(args.value) or nil)
    return true
end


---Executes a chat command.
---@param player IsoPlayer
---@param args omichat.request.Command
function ServerHandler.executeCommand(player, args)
    local handler = ServerHandler.Command[args.name]
    if not handler then
        return
    end

    handler(player, args)
end

---Handles player death.
---@param player IsoPlayer
function ServerHandler.playerDied(player)
    local username = player:getUsername()
    if not ServerHandler._canAccessTarget(player, username) then
        return
    end

    local doTransmit = false
    local clearConfig = config.General.ClearOnDeath
    if clearConfig.Nickname then
        ServerHandler.ModData.nicknames({ target = username })
        doTransmit = true
    end

    if clearConfig.Icon then
        ServerHandler.ModData.icons({ target = username })
        doTransmit = true
    end

    if clearConfig.Languages then
        ServerHandler.ModData.languages({ target = username })
        doTransmit = true
    end

    if clearConfig.Status then
        ServerHandler.ModData.statuses({ target = username })
        doTransmit = true
    end

    if doTransmit then
        API.data.transmit()
    end
end

---Handles player join.
---@param player IsoPlayer
function ServerHandler.playerJoined(player)
    ServerHandler.requestPlayerCacheUpdate()
    API.request.sendConfiguration(player)
end

---Handles a request to clear mod data for a given username.
---@param player IsoPlayer
---@param req omichat.request.ClearModData
function ServerHandler.requestClearModData(player, req)
    if player:getAccessLevel() ~= 'Admin' then
        return
    end

    API.data.clearModData(req.username)
    API.data.transmit()
end

---Updates global mod data.
---@param player IsoPlayer
---@param args omichat.request.ModDataUpdate
---@return boolean
---@return string?
function ServerHandler.requestDataUpdate(player, args)
    local err
    local success = false
    if args.field ~= 'all' and not ServerHandler._isOnlinePlayer(args.target) then
        return false, 'UNKNOWN_PLAYER'
    end

    if ServerHandler._canAccessTarget(player, args.target, args.fromCommand) then
        local handler = ServerHandler.ModData[args.field]
        if handler then
            success, err = handler(args)
        end
    end

    API.data.transmit()
    return success, err
end

---Handles the /card command.
---@param player IsoPlayer
function ServerHandler.requestDrawCard(player)
    local suit = 1 + ZombRand(4)
    local card = 1 + ZombRand(13)

    if config.Commands.Card.Global then
        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        API.request.reportDrawCardGlobal(name, card, suit)
    else
        API.request.reportDrawCard(player, card, suit)
    end
end

---Handles the /flip command.
---@param player IsoPlayer
function ServerHandler.requestFlipCoin(player)
    local heads = ZombRand(2) == 0
    if config.Commands.Flip.Global then
        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        API.request.sendTranslatedServerMessage('UI_OmiChat_Flip' .. (heads and 'Heads' or 'Tails'), { name })
    else
        API.request.reportFlipCoin(player, heads)
    end
end

---Updates player cache information.
function ServerHandler.requestPlayerCacheUpdate()
    API._refreshCache()
end

---Handles the /roll command.
---@param player IsoPlayer
---@param args omichat.request.RollDice
function ServerHandler.requestRollDice(player, args)
    local sides = tonumber(args.sides)
    if type(sides) ~= 'number' or sides < 1 or sides > 100 then
        API.request.sendTranslatedInfoMessage(player, 'UI_ServerOptionDesc_Roll')
        return
    end

    local roll = 1 + ZombRand(sides)
    if config.Commands.Roll.Global then
        local name = API.data.getNameInChatRichText(player:getUsername(), 'general') or player:getUsername()
        API.request.sendTranslatedServerMessage('UI_OmiChat_Roll', { name, tostring(roll), tostring(sides) })
    else
        API.request.reportRoll(player, roll, sides)
    end
end

---Handles a request to notify other players of typing status.
---@param player IsoPlayer
---@param args omichat.request.Typing
function ServerHandler.requestTyping(player, args)
    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local otherPlayer = onlinePlayers:get(i)

        if player ~= otherPlayer or getDebug() then
            local typing = args.typing
                and ServerHandler._shouldSendTyping(player, otherPlayer, args.range, args.chatType)
            API.request.sendTyping(otherPlayer, player, typing)
        end
    end
end

---Updates the configuration with data from the client.
---@param player IsoPlayer
---@param args omichat.request.UpdateConfiguration
function ServerHandler.updateConfiguration(player, args)
    if not player:isAccessLevel('Admin') then
        return
    end

    config:load(args.value)
    config:saveModData()
    API.request.sendConfiguration()
end


---Checks whether a player has permission to execute a command for the given target.
---@param player IsoPlayer
---@param target string
---@param fromCommand boolean?
---@return boolean
---@private
function ServerHandler._canAccessTarget(player, target, fromCommand)
    if not target then
        return false
    end

    local access = utils.getNumericAccessLevel(player:getAccessLevel())
    if fromCommand and access < config.General.MinimumCommandAccessLevel then
        return false
    end

    if access == 1 and target ~= player:getUsername() then
        return false
    end

    return true
end

---Checks whether the given username belongs to a currently online player.
---@param username string
---@return boolean
---@private
function ServerHandler._isOnlinePlayer(username)
    if not username then
        return false
    end

    local player = utils.getPlayerByUsername(username)
    return player ~= nil
end

---Checks whether the typing indicator should be sent for a pair of players.
---@param player IsoPlayer
---@param otherPlayer IsoPlayer
---@param range integer?
---@param chatType omichat.ChatTypeString?
---@return boolean
---@private
function ServerHandler._shouldSendTyping(player, otherPlayer, range, chatType)
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


API.handlers = ServerHandler
return ServerHandler
