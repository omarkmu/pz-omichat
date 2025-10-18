---@namespace omichat
---Handles getting and setting data about the local player.

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration
local concat = table.concat
local sqrt = math.sqrt
local getText = getText
local ISChat = ISChat ---@type ISChat


---Contains functions for getting and setting data related to the local player.
---@class api.client.player
local Player = {}


---Adds a roleplay language to the local player's list.
---@param language string The language to add.
---@return boolean success
---@return string? error
function Player.addLanguage(language)
    local username = Player.getUsername()
    if not username then
        return false, 'Unable to retrieve local player'
    end

    return API.request.updateData({
        target = username,
        field = 'languages',
        value = language,
    })
end

---Applies a buff to the player if the cooldown period has expired.
---@param ignoreCooldown boolean? Flag for whether the buff should be applied even if the cooldown has not expired.
function Player.applyBuff(ignoreCooldown)
    local player = getSpecificPlayer(0)
    local modData = player and player:getModData()
    if not modData then
        return
    end

    local now = getTimestampMs()
    local buffConfig = config.Buffs
    if not ignoreCooldown then
        local lastBuff = modData and tonumber(modData.ocLastBuff)
        if lastBuff and (now - lastBuff) / 60000 < buffConfig.Cooldown then
            return
        end
    end

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    local cigaretteStressReduction = buffConfig.CigaretteStress * stats:getMaxStressFromCigarettes()

    stats:setHunger(stats:getHunger() - buffConfig.Hunger)
    stats:setThirst(stats:getThirst() - buffConfig.Thirst)
    stats:setFatigue(stats:getFatigue() - buffConfig.Fatigue)
    stats:setStressFromCigarettes(stats:getStressFromCigarettes() - cigaretteStressReduction)
    bodyDamage:setBoredomLevel(bodyDamage:getBoredomLevel() - buffConfig.Boredom * 100)
    bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - buffConfig.Unhappiness * 100)
    modData.ocLastBuff = now
end

---Checks whether the current player can use admin commands added by the mod.
---@return boolean isAllowed
function Player.canUseAdminCommands()
    local player = getSpecificPlayer(0)
    local access = player and player:getAccessLevel()
    return utils.getNumericAccessLevel(access) >= config.General.MinimumCommandAccessLevel
end

---Returns a color table preferred by the local player.
---@param id string The color identifier. This is the name of a stream, or `speech` for the speech color.
---@return omi.ColorTable<integer>? color The color table, or `nil` if the color is unset.
function Player.getColor(id)
    if id == 'speech' then
        return Player.getSpeechColor()
    end

    return API.preferences.getColor(id)
end

---Returns a color table preferred by the local player, or the default color table if there isn't one.
---@param id string The color identifier. This is the name of a stream, or `speech` for the speech color.
---@return omi.ColorTable<integer> color The color table to use.
function Player.getColorOrDefault(id)
    return Player.getColor(id) or Player.getDefaultColor(id)
end

---Gets the player's currently active roleplay language.
---@return string? currentLanguage
function Player.getCurrentLanguage()
    local username = Player.getUsername()
    if not username then
        return
    end

    return API.data.getCurrentLanguage(username)
end

---Gets the default color associated with a stream or speech color.
---@param id string The color identifier. This is the name of a stream, or `speech` for the speech color.
---@return omi.ColorTable<integer> color The default color table. If the default could not be retrieved or there is no default, this returns white.
function Player.getDefaultColor(id)
    if id == 'speech' then
        local speechColor = Player.getSpeechColor()
        if not speechColor then
            return { r = 255, g = 255, b = 255 }
        end

        return speechColor
    end

    local stream = API.streams.getChatStream(id)

    local defaultColor = stream and stream:getDefaultColor()
    if not defaultColor then
        return { r = 255, g = 255, b = 255 }
    end

    return defaultColor
end

---Gets a list of default shouts to use when custom shouts aren't set.
---@param isSneaking boolean Flag for whether strings for sneak shouts should be retrieved.
---@return string[] shouts A list of translated shout strings.
function Player.getDefaultShouts(isSneaking)
    local result = {}
    for i = 1, 3 do
        result[#result + 1] = getText('IGUI_PlayerText_Callout' .. i .. (isSneaking and 'Sneak' or 'New'))
    end

    return result
end

---Gets the local player's distance from another player.
---Returns `nil` if either player is not available.
---@param otherPlayer IsoPlayer? The player to compare with. If this is `nil`, the return value will be `nil`.
---@param player IsoPlayer? The local player. Will be retrieved if not given.
---@return number? distance The distance between the players. If either player is unavailable, `nil`.
function Player.getDistanceFrom(otherPlayer, player)
    if not otherPlayer then
        return
    end

    player = player or getSpecificPlayer(0)
    if not player then
        return
    end

    local xDiff = otherPlayer:getX() - player:getX()
    local yDiff = otherPlayer:getY() - player:getY()

    return sqrt(xDiff * xDiff + yDiff * yDiff)
end

---Gets a list of the local player's known roleplay languages.
---@return string[] languages
function Player.getLanguages()
    local username = Player.getUsername()
    if not username then
        return {}
    end

    local playerData = API.data.getPlayerInfoByUsername(username)
    if not playerData or not playerData.languages then
        return { API.language.getDefault() }
    end

    return playerData.languages
end

---Gets the number of available roleplay language slots for the local player.
---@return integer slots
function Player.getLanguageSlots()
    local default = config.Language.DefaultSlots
    local username = Player.getUsername()
    if not username then
        return default
    end

    local playerData = API.data.getPlayerInfoByUsername(username)
    return playerData and playerData.languageSlots or default
end

---Gets the nickname for the local player.
---@return string? nickname The player's chosen nickname, or `nil` if unset.
function Player.getNickname()
    local username = Player.getUsername()
    if not username then
        return
    end

    return API.data.getNickname(username)
end

---Returns a color table for the local player's speech color.
---@return omi.ColorTable<integer>? color
function Player.getSpeechColor()
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local speechColor = player:getSpeakColour()
    if not speechColor then
        return
    end

    return {
        r = speechColor:getRed(),
        g = speechColor:getGreen(),
        b = speechColor:getBlue(),
    }
end

---Gets the username of the local player.
---@return string? username The player's username, or `nil` if the player is unavailable.
function Player.getUsername()
    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if username then
        return username
    end
end

---Checks whether the player is dead or unable to be retrieved.
---@return boolean isDeadOrUnavailable
function Player.isDeadOrUnavailable()
    local player = getSpecificPlayer(0)
    return not player or player:isDead()
end

---Checks whether the local player knows a given roleplay language.
---@param language string The untranslated name of the language to check.
---@return boolean isKnown
function Player.knowsLanguage(language)
    local username = Player.getUsername()
    if not username then
        return false
    end

    return API.language.doesPlayerKnow(username, language)
end

---Sets the color associated with a given stream or identifier for the local player.
---@param id string The color identifier. This is the name of a stream, or `speech` for the speech color.
---@param color omi.ColorTable<integer>? The color to set, or `nil` to unset it.
function Player.setColor(id, color)
    if id == 'speech' then
        Player.setSpeechColor(color)
        return
    end

    API.preferences.setColor(id, color)
end

---Sets the player's current roleplay language.
---@param language string
---@return boolean
function Player.setCurrentLanguage(language)
    local username = Player.getUsername()
    if not username then
        return false
    end

    API.request.updateData({
        field = 'currentLanguage',
        target = username,
        value = language,
    })

    return true
end

---Sets the number of available roleplay language slots for the current player.
---@param slots integer
---@return boolean success
function Player.setLanguageSlots(slots)
    local username = Player.getUsername()
    if not username then
        return false
    end

    if slots < 1 or slots > config.MAX_LANGUAGE_SLOTS then
        return false
    end

    API.request.updateData({
        field = 'languageSlots',
        target = username,
        value = slots,
    })

    return true
end

---Sets the nickname of the current player.
---@param nickname string? The nickname to set. A `nil` or empty value will unset the nickname.
---@return boolean success Flag for whether the nickname was successfully updated.
---@return string? feedback A status message to report to the player.
function Player.setNickname(nickname)
    nickname = utils.trim(nickname or '')

    local username = Player.getUsername()
    if not username then
        return false
    end

    if #nickname == 0 then
        API.request.updateData({
            target = username,
            field = 'nickname',
        })

        return true, getText('UI_OmiChat_Success_ResetName')
    end

    local original = nickname
    local tokens = {
        target = 'nickname',
        input = nickname,
        error = '',
        errorID = '',
    }

    nickname = utils.interpolateNamed('FilterName', config.Format.Filter.Name, tokens)
    local err = utils.extractError(tokens)
    if nickname == '' or err then
        return false, err or getText('UI_OmiChat_Error_InvalidName', utils.escapeRichText(original))
    end

    API.request.updateData({
        value = nickname,
        target = username,
        field = 'nickname',
    })

    return true, getText('UI_OmiChat_Success_SetNameSelf', utils.escapeRichText(nickname))
end

---Sets the color used for overhead chat bubbles.
---This will set the speech color in-game option.
---@param color omi.ColorTable<integer>? The new speech color.
---@param doRequest boolean? Flag for whether a request to update the cache should be made. Defaults to `true`.
---@return boolean success
function Player.setSpeechColor(color, doRequest)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if not utils.color.isValid(color) then
        return false
    end

    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255

    local core = getCore()
    core:setMpTextColor(ColorInfo.new(r, g, b, 1))
    core:saveOptions()
    player:setSpeakColourInfo(core:getMpTextColor())
    sendPersonalColor(player)

    if doRequest ~= false then
        API.request.updatePlayerCache()
    end

    return true
end

---Sets the status of the current player.
---@param status string? The status to set. A `nil` or empty value will unset the status.
---@return boolean success Flag for whether the status was successfully set.
---@return string? message A status message to report to the player.
function Player.setStatus(status)
    status = utils.trim(status or ''):gsub('[\r\n]', '')

    local username = Player.getUsername()
    if not username then
        return false
    end

    if #status == 0 then
        API.request.updateData({
            target = username,
            field = 'status',
        })

        return true, getText('UI_OmiChat_Success_ResetStatus')
    end

    local original = status
    local tokens = {
        input = status,
        error = '',
        errorID = '',
    }

    status = utils.interpolateNamed('FilterStatus', config.Format.Filter.Status, tokens)
    local err = utils.extractError(tokens)
    if status == '' or err then
        return false, err or getText('UI_OmiChat_Error_InvalidStatus', utils.escapeRichText(original))
    end

    API.request.updateData({
        value = status,
        target = username,
        field = 'status',
    })

    return true, getText('UI_OmiChat_Success_SetStatusSelf', utils.escapeRichText(status))
end

---Updates the current player's character name.
---@param name string The new name of the character.
---@param updateSurname boolean? Flag for whether the name should be split into forename and surname.
---@return boolean success Flag for whether the name was successfully updated.
---@return string? message A status message to report to the player.
function Player.updateCharacterName(name, updateSurname)
    name = utils.trim(name)
    if #name == 0 then
        return false
    end

    local player = getSpecificPlayer(0)
    local desc = player and player:getDescriptor()
    if not desc then
        return false
    end

    local tokens = {
        target = 'name',
        input = name,
        error = '',
        errorID = '',
    }

    name = utils.trim(utils.interpolateNamed('FilterName', config.Format.Filter.Name, tokens))

    local err = utils.extractError(tokens)
    if name == '' or err then
        return false, err or getText('UI_OmiChat_Error_InvalidName', utils.escapeRichText(name))
    end

    local surname
    local forename = name
    if updateSurname then
        surname = ''

        local parts = name:split(' ')
        if #parts > 1 then
            forename = utils.trim(concat(parts, ' ', 1, #parts - 1))
            surname = utils.trim(parts[#parts] --[[@as string]])
        end
    end

    desc:setForename(forename)

    -- fix incompatibility with buffy's character bios
    if ISChat.instance and config:compatBuffyCharacterBiosEnabled() then
        ---@diagnostic disable-next-line: inject-field
        ISChat.instance.rpName = forename
    end

    if surname then
        desc:setSurname(surname)
    end

    sendPlayerStatsChange(player)
    API.request.updatePlayerCache()

    -- update name in inventory
    local data = getPlayerData(player:getPlayerNum())
    if data and data.playerInventory then
        player:getInventory():setDrawDirty(true)
        data.playerInventory:refreshBackpacks()
    end

    return true, getText('UI_OmiChat_Success_SetNameSelf', utils.escapeRichText(name))
end


API.player = Player
return Player
