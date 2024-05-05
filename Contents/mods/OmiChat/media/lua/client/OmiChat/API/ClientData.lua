---Client API functionality related to handling player data.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local utils = OmiChat.utils
local Option = OmiChat.Option
local concat = table.concat
local getText = getText


---Adds a roleplay language to the current player's list.
---@param language string
---@return boolean
function OmiChat.addRoleplayLanguage(language)
    local username = utils.getPlayerUsername()
    if not username then
        return false
    end

    OmiChat.requestDataUpdate({
        target = username,
        field = 'languages',
        value = language,
    })

    return true
end

---Sets the color associated with a given color category for the current player,
---if the related option is enabled.
---@param category omichat.ColorCategory
---@param color omichat.ColorTable?
function OmiChat.changeColor(category, color)
    if category == 'speech' then
        OmiChat.changeSpeechColor(color)
        return
    end

    if category ~= 'name' then
        -- no syncing necessary for chat colors; just set in player preferences
        OmiChat.setPreferredColor(category, color)
        return
    end

    local username = utils.getPlayerUsername()
    if not username then
        return
    end

    local modData = OmiChat.getModData()
    local value = color and utils.colorToHexString(color) or nil

    modData.nameColors[username] = value
    OmiChat.requestDataUpdate({
        target = username,
        field = 'nameColors',
        value = value,
    })
end

---Sets the color used for overhead chat bubbles.
---This will set the speech color in-game option.
---@param color omichat.ColorTable?
function OmiChat.changeSpeechColor(color)
    if not utils.isValidColor(color) then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    ---@cast color omichat.ColorTable
    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255

    local core = getCore()
    core:setMpTextColor(ColorInfo.new(r, g, b, 1))
    core:saveOptions()
    player:setSpeakColourInfo(core:getMpTextColor())
    sendPersonalColor(player)
end

---Checks whether the current player knows a given roleplay language.
---@param language string
---@return boolean
function OmiChat.checkKnowsLanguage(language)
    local username = utils.getPlayerUsername()
    if not username then
        return false
    end

    return OmiChat.checkPlayerKnowsLanguage(username, language)
end

---Removes the mod data associated with a username.
---@param username string
function OmiChat.clearModData(username)
    OmiChat._clearModData(username)
    OmiChat.requestClearModData(username)
end

---Gets a color table for the current player, or `nil` if unset.
---@param category omichat.ColorCategory
---@return omichat.ColorTable?
function OmiChat.getColor(category)
    if category == 'name' then
        local player = getSpecificPlayer(0)
        return OmiChat.getNameColor(player and player:getUsername())
    end

    if category == 'speech' then
        return OmiChat.getSpeechColor()
    end

    return OmiChat.getPreferredColor(category)
end

---Returns a color table associated with the current player,
---or the default color table if there isn't one.
---@param category omichat.ColorCategory
---@return omichat.ColorTable
function OmiChat.getColorOrDefault(category)
    return OmiChat.getColor(category) or Option:getDefaultColor(category)
end

---Gets the player's current roleplay language.
---@return string?
function OmiChat.getCurrentRoleplayLanguage()
    local username = utils.getPlayerUsername()
    if not username then
        return
    end

    local modData = OmiChat.getModData()
    local language = modData.currentLanguage[username]
    if not OmiChat.isConfiguredRoleplayLanguage(language) then
        return
    end

    return language
end

---Gets the nickname for the current player, if one is set.
---@return string?
function OmiChat.getNickname()
    local username = utils.getPlayerUsername()
    if not username then
        return
    end

    local modData = OmiChat.getModData()
    return modData.nicknames[username]
end

---Gets a list of the current player's known roleplay languages.
---@return string[]
function OmiChat.getRoleplayLanguages()
    local username = utils.getPlayerUsername()
    if not username then
        return {}
    end

    local modData = OmiChat.getModData()
    if not modData.languages[username] then
        modData.languages[username] = { OmiChat.getDefaultRoleplayLanguage() }
    end

    return modData.languages[username]
end

---Gets the number of available roleplay language slots for the current player.
---@return integer
function OmiChat.getRoleplayLanguageSlots()
    local username = utils.getPlayerUsername()
    return username and OmiChat.getModData().languageSlots[username] or Option.LanguageSlots
end

---Returns a color table for the current player's speech color.
---@return omichat.ColorTable?
function OmiChat.getSpeechColor()
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

---Sets the player's current roleplay language.
---@param language string
---@return boolean
function OmiChat.setCurrentRoleplayLanguage(language)
    local username = utils.getPlayerUsername()
    if not username then
        return false
    end

    local modData = OmiChat.getModData()
    if OmiChat.isConfiguredRoleplayLanguage(language) then
        modData.currentLanguage[username] = language
    end

    OmiChat.requestDataUpdate({
        field = 'currentLanguage',
        target = username,
        value = language,
    })

    return true
end

---Sets the mod data for the given username.
---@param username string
---@param data omichat.UserModData?
function OmiChat.setModData(username, data)
    local modData = OmiChat.getModData()

    data = data or {}
    modData.nicknames[username] = data.nickname
    modData.icons[username] = data.icon
    modData.nameColors[username] = data.nameColor
    modData.languageSlots[username] = data.languageSlots
    modData.languages[username] = data.languages
    modData.currentLanguage[username] = data.currentLanguage

    OmiChat.requestDataUpdate({
        target = username,
        field = 'all',
        value = data,
    })
end

---Sets the nickname of the current player.
---@param nickname string? The nickname to set. A `nil` or empty value will unset the nickname.
---@return boolean success
---@return string? status
function OmiChat.setNickname(nickname)
    nickname = utils.trim(nickname or '')

    local username = utils.getPlayerUsername()
    if not username then
        return false
    end

    local modData = OmiChat.getModData()
    if #nickname == 0 then
        modData.nicknames[username] = nil
        OmiChat.requestDataUpdate({
            target = username,
            field = 'nicknames',
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

    nickname = utils.interpolate(Option.FilterNickname, tokens)
    local err = utils.extractError(tokens)
    if nickname == '' or err then
        return false, err or getText('UI_OmiChat_Error_InvalidName', utils.escapeRichText(original))
    end

    modData.nicknames[username] = nickname
    OmiChat.requestDataUpdate({
        value = nickname,
        target = username,
        field = 'nicknames',
    })

    return true, getText('UI_OmiChat_Success_SetNameSelf', utils.escapeRichText(nickname))
end

---Sets the number of available roleplay language slots for the current player.
---@param slots integer
---@return boolean success
function OmiChat.setRoleplayLanguageSlots(slots)
    local username = utils.getPlayerUsername()
    if not username then
        return false
    end

    if slots < 1 or slots > OmiChat.config:maxLanguageSlots() then
        return false
    end

    local modData = OmiChat.getModData()
    modData.languageSlots[username] = slots
    OmiChat.requestDataUpdate({
        field = 'languageSlots',
        target = username,
        value = slots,
    })

    return true
end

---Updates the current player's character name.
---@param name string The new name of the character.
---@param updateSurname boolean? Whether the name should be split into forename and surname. Defaults to false.
---@return boolean success
---@return string? status
function OmiChat.updateCharacterName(name, updateSurname)
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

    name = utils.interpolate(Option.FilterNickname, tokens)

    local err = utils.extractError(tokens)
    if name == '' then
        return false, err or getText('UI_OmiChat_Error_InvalidName', utils.escapeRichText(name))
    end

    local surname
    local forename = name
    if updateSurname then
        surname = ''

        local parts = name:split(' ')
        if #parts > 1 then
            forename = concat(parts, ' ', 1, #parts - 1)
            surname = parts[#parts]
        end
    end

    desc:setForename(forename)
    if surname then
        desc:setSurname(surname)
    end

    sendPlayerStatsChange(player)

    -- update name in inventory
    local data = getPlayerData(player:getPlayerNum())
    if data and data.playerInventory then
        player:getInventory():setDrawDirty(true)
        data.playerInventory:refreshBackpacks()
    end

    return true, getText('UI_OmiChat_Success_SetNameSelf', utils.escapeRichText(name))
end
