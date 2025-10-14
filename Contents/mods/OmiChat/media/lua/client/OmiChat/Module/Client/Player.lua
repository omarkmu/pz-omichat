---Handles getting and setting data about the local player.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local concat = table.concat
local sqrt = math.sqrt
local getText = getText


---@class omichat.api.client.player
local Player = {}


---Adds a roleplay language to the local player's list.
---@param language string
---@return boolean
function Player.addLanguage(language)
    local username = Player.getUsername()
    if not username then
        return false
    end

    API.request.updateData({
        target = username,
        field = 'languages',
        value = language,
    })

    return true
end

---Applies a buff to the player, if the cooldown period has expired.
---@param ignoreCooldown boolean? If `true`, the buff will be applied even if the cooldown has not expired.
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

---Checks whether the current player can use custom admin commands.
---@return boolean
function Player.canUseAdminCommands()
    local player = getSpecificPlayer(0)
    local access = player and player:getAccessLevel()
    return utils.getNumericAccessLevel(access) >= config.General.MinimumCommandAccessLevel
end

---Gets a color table for the local player, or `nil` if unset.
---@param id string
---@return omi.ColorTable?
function Player.getColor(id)
    if id == 'speech' then
        return Player.getSpeechColor()
    end

    return API.preferences.getColor(id)
end

---Returns a color table preferred by the local player, or the default color table if there isn't one.
---@param id string
---@return omi.ColorTable
function Player.getColorOrDefault(id)
    return Player.getColor(id) or Player.getDefaultColor(id)
end

---Gets the player's currently active roleplay language.
---@return string?
function Player.getCurrentLanguage()
    local username = Player.getUsername()
    if not username then
        return
    end

    return API.data.getCurrentLanguage(username)
end

---Gets the default color associated with a stream or speech color.
---If the default could not be retrieved or there is no default, this returns white.
---@param category string
---@return omi.ColorTable
function Player.getDefaultColor(category)
    if category == 'speech' then
        return Player.getSpeechColor() or { r = 255, g = 255, b = 255 }
    end

    local stream = API.streams.getChatStream(category)
    return stream and stream:getDefaultColor() or { r = 255, g = 255, b = 255 }
end

---Gets the default shouts to use when custom shouts aren't set.
---@param isSneaking boolean
---@return string[]
function Player.getDefaultShouts(isSneaking)
    local result = {}
    for i = 1, 3 do
        result[#result + 1] = getText('IGUI_PlayerText_Callout' .. i .. (isSneaking and 'Sneak' or 'New'))
    end

    return result
end

---Gets the local player's distance from another player.
---Returns `nil` if either player is not available.
---@param otherPlayer IsoPlayer?
---@return number?
function Player.getDistanceFrom(otherPlayer)
    if not otherPlayer then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local xDiff = otherPlayer:getX() - player:getX()
    local yDiff = otherPlayer:getY() - player:getY()

    return sqrt(xDiff * xDiff + yDiff * yDiff)
end

---Gets a list of the local player's known roleplay languages.
---@return string[]
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
---@return integer
function Player.getLanguageSlots()
    local default = config.Language.DefaultSlots
    local username = Player.getUsername()
    if not username then
        return default
    end

    local playerData = API.data.getPlayerInfoByUsername(username)
    return playerData and playerData.languageSlots or default
end

---Gets the nickname for the local player, or `nil` if unset.
---@return string?
function Player.getNickname()
    local username = Player.getUsername()
    if not username then
        return
    end

    return API.data.getNickname(username)
end

---Returns a color table for the local player's speech color.
---@return omi.ColorTable?
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
---@return string?
function Player.getUsername()
    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if username then
        return username
    end
end

---Checks whether the player is dead or unable to be retrieved.
---@return boolean
function Player.isDeadOrUnavailable()
    local player = getSpecificPlayer(0)
    return not player or player:isDead()
end

---Checks whether the local player knows a given roleplay language.
---@param language string
---@return boolean
function Player.knowsLanguage(language)
    local username = Player.getUsername()
    if not username then
        return false
    end

    return API.language.doesPlayerKnow(username, language)
end

---Sets the color associated with a given stream or identifier for the local player.
---@param category string
---@param color omi.ColorTable?
function Player.setColor(category, color)
    if category == 'speech' then
        Player.setSpeechColor(color)
        return
    end

    API.preferences.setColor(category, color)
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
---@return boolean success
---@return string? status
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
---@param color omi.ColorTable? The new speech color.
---@param requestCacheUpdate boolean? Whether a request to update the cache should be made. Defaults to `true`.
---@return boolean success
function Player.setSpeechColor(color, requestCacheUpdate)
    local player = getSpecificPlayer(0)
    if not player then
        return false
    end

    if not utils.color.isValid(color) then
        return false
    end

    ---@cast color omi.ColorTable
    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255

    local core = getCore()
    core:setMpTextColor(ColorInfo.new(r, g, b, 1))
    core:saveOptions()
    player:setSpeakColourInfo(core:getMpTextColor())
    sendPersonalColor(player)

    if requestCacheUpdate ~= false then
        API.request.updatePlayerCache()
    end

    return true
end

---Sets the status of the current player.
---@param status string? The status to set. A `nil` or empty value will unset the status.
---@return boolean success
---@return string? message
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
---@param updateSurname boolean? Whether the name should be split into forename and surname. Defaults to `false`.
---@return boolean success
---@return string? message
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
            surname = utils.trim(parts[#parts])
        end
    end

    desc:setForename(forename)
    if ISChat.instance and config:compatBuffyCharacterBiosEnabled() then
        -- fix incompatibility with buffy's character bios
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
