---Client API functionality related to handling player data.

local utils = require 'OmiChat/util'

local concat = table.concat
local pairs = pairs
local getText = getText

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'
local Option = OmiChat.Option


---Sets the color associated with a given color category for the current player,
---if the related option is enabled.
---@param category omichat.ColorCategory
---@param color omichat.ColorTable?
function OmiChat.changeColor(category, color)
    if category == 'speech' then
        return OmiChat.changeSpeechColor(color)
    end

    if category ~= 'name' then
        -- no syncing necessary for chat colors; just set in player preferences
        local prefs = OmiChat.getPlayerPreferences()
        prefs.colors[category] = color
        OmiChat.savePlayerPreferences()

        return
    end

    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if not username then
        return
    end

    local modData = OmiChat.getModData()
    local value = color and utils.colorToHexString(color) or nil

    modData.nameColors[username] = value
    OmiChat.requestDataUpdate(player, {
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

---Gets a color table for the current player, or nil if unset.
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

    local prefs = OmiChat.getPlayerPreferences()
    return prefs.colors[category]
end

---Retrieves the player's custom shouts.
---@param shoutType omichat.CalloutCategory The type of shouts to retrieve.
---@return string[]?
function OmiChat.getCustomShouts(shoutType)
    if not Option:isCustomCalloutTypeEnabled(shoutType) then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local prefs = OmiChat.getPlayerPreferences()
    return prefs[shoutType]
end

---Retrieves a boolean for whether the current player has name colors enabled.
---@return boolean
function OmiChat.getNameColorsEnabled()
    return OmiChat.getPlayerPreferences().showNameColors
end

---Gets the nickname for the current player, if one is set.
---@return string?
function OmiChat.getNickname()
    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if not username then
        return
    end

    local modData = OmiChat.getModData()
    return modData.nicknames[username]
end

---Gets or creates the player preferences table.
---@return omichat.PlayerPreferences
function OmiChat.getPlayerPreferences()
    if OmiChat._playerPrefs then
        return OmiChat._playerPrefs
    end

    ---@type omichat.PlayerPreferences
    local prefs = {
        showNameColors = true,
        colors = {},
        callouts = {},
        sneakcallouts = {},
    }

    local line, dest
    local inFile = getFileReader(OmiChat._iniName, true)
    while true do
        line = inFile:readLine()
        if line == nil then
            inFile:close()
            break
        end

        if line:sub(1, 1) == '[' then
            local endBracket = line:find(']')
            local target = endBracket and line:sub(2, endBracket - 1)
            if target and prefs[target] then
                dest = prefs[target]
            end
        else
            local eq = line:find('=')
            local key = line:sub(1, eq - 1)
            local value = line:sub(eq + 1)

            if not dest and key == 'showNameColors'then
                prefs.showNameColors = value == 'true'
            elseif dest == prefs.colors then
                dest[key] = utils.stringToColor(value)
            elseif dest and tonumber(key) then
                dest[tonumber(key)] = value
            elseif dest then
                ---@cast dest table
                dest[key] = value
            end
        end
    end

    OmiChat._playerPrefs = prefs
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

---Saves the current player preferences to a file.
function OmiChat.savePlayerPreferences()
    if not OmiChat._playerPrefs then
        return
    end

    local outFile = getFileWriter(OmiChat._iniName, true, false)
    outFile:write(concat { 'VERSION=', tostring(OmiChat._iniVersion), '\n' })

    outFile:write(concat { 'showNameColors=', tostring(OmiChat._playerPrefs.showNameColors), '\n' })

    outFile:write(concat {'[colors]\n'})
    for cat, color in pairs(OmiChat._playerPrefs.colors) do
        outFile:write(concat { cat, '=', utils.colorToHexString(color), '\n' })
    end

    for _, name in pairs({ 'callouts', 'sneakcallouts' }) do
        if OmiChat._playerPrefs[name] then
            outFile:write(concat {'[', name, ']\n'})

            for k, v in pairs(OmiChat._playerPrefs[name]) do
                outFile:write(concat { tostring(k), '=', tostring(v), '\n' })
            end
        end
    end

    outFile:close()
end

---Sets the player's custom shouts.
---@param shouts string[]?
---@param shoutType omichat.CalloutCategory The type of shouts to set.
function OmiChat.setCustomShouts(shouts, shoutType)
    if not Option:isCustomCalloutTypeEnabled(shoutType) then
        return
    end

    local prefs = OmiChat.getPlayerPreferences()

    if not shouts then
        prefs[shoutType] = {}
    else
        prefs[shoutType] = shouts
    end

    OmiChat.savePlayerPreferences()
end

---Sets whether the current player has name colors enabled.
---@param enabled boolean True to enable, false to disable.
function OmiChat.setNameColorEnabled(enabled)
    OmiChat.getPlayerPreferences().showNameColors = not not enabled
    OmiChat.savePlayerPreferences()
end

---Sets the nickname of the current player.
---@param nickname string? The nickname to set. A nil or empty value will unset the nickname.
---@return boolean success
---@return string? status
function OmiChat.setNickname(nickname)
    nickname = utils.trim(nickname or '')

    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()
    if not username then
        return false
    end

    local maxLength = Option.NameMaxLength
    if maxLength > 0 and #nickname > maxLength then
        nickname = nickname:sub(1, maxLength)
    end

    local modData = OmiChat.getModData()

    if #nickname == 0 then
        modData.nicknames[username] = nil
        OmiChat.requestDataUpdate(player, {
            target = username,
            field = 'nicknames',
        })

        if Option.EnableChatNameAsCharacterName then
            return false, getText('UI_OmiChat_set_name_empty')
        end

        return true, getText('UI_OmiChat_reset_name_success')
    end

    if Option.EnableChatNameAsCharacterName then
        OmiChat.updateCharacterName(nickname)
        return true, getText('UI_OmiChat_set_name_success', utils.escapeRichText(nickname))
    end

    modData.nicknames[username] = nickname
    OmiChat.requestDataUpdate(player, {
        value = nickname,
        target = username,
        field = 'nicknames',
    })

    return true, getText('UI_OmiChat_set_name_success', utils.escapeRichText(nickname))
end

---Updates the current player's character name.
---@param name string The new full name of the character. This will be split into forename and surname.
---@param surname string? The character surname. If provided, `name` will be interpreted as the forename.
---@return boolean success
function OmiChat.updateCharacterName(name, surname)
    if #name == 0 then
        return false
    end

    local player = getSpecificPlayer(0)
    local desc = player and player:getDescriptor()
    if not desc then
        return false
    end

    local forename = name
    if not surname then
        surname = ''

        local parts = name:split(' ')
        if #parts > 1 then
            forename = concat(parts, ' ', 1, #parts - 1)
            surname = parts[#parts]
        end
    end

    desc:setForename(forename)
    desc:setSurname(surname)

    -- update name in inventory
    player:getInventory():setDrawDirty(true)
    getPlayerData(player:getPlayerNum()).playerInventory:refreshBackpacks()

    sendPlayerStatsChange(player)

    return true
end
