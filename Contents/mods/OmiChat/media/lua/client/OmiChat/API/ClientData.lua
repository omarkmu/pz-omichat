---Client API functionality related to handling player data.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local utils = OmiChat.utils
local Option = OmiChat.Option
local concat = table.concat
local getText = getText


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

---Returns a color table associated with the current player,
---or the default color table if there isn't one.
---@param category omichat.ColorCategory
---@return omichat.ColorTable
function OmiChat.getColorOrDefault(category)
    return OmiChat.getColor(category) or Option:getDefaultColor(category)
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

    OmiChat._playerPrefs = {
        showNameColors = true,
        useSuggester = true,
        retainChatInput = true,
        retainRPInput = true,
        retainOtherInput = false,
        colors = {},
        callouts = {},
        sneakcallouts = {},
    }

    local line
    local content = {}
    local prefsFile = getFileReader(OmiChat._prefsFileName, true)
    while true do
        line = prefsFile:readLine()
        if line == nil then
            prefsFile:close()
            break
        end

        content[#content + 1] = line
    end

    local prefs = OmiChat._playerPrefs
    local encoded = utils.trim(concat(content))
    if #encoded == 0 then
        return prefs
    end

    local success, decoded = utils.json.tryDecode(encoded)
    if type(decoded) ~= 'table' then
        if success then
            decoded = 'invalid file content'
        end

        utils.logError('failed to read preferences (%s)', decoded)

        -- reset to default on failed read
        return prefs
    end

    prefs.showNameColors = not not decoded.showNameColors
    prefs.useSuggester = not not decoded.useSuggester
    prefs.retainChatInput = not not decoded.retainChatInput
    prefs.retainRPInput = not not decoded.retainRPInput
    prefs.retainOtherInput = not not decoded.retainOtherInput

    if type(decoded.callouts) == 'table' then
        prefs.callouts = utils.pack(utils.mapList(tostring, decoded.callouts))
    end

    if type(decoded.sneakcallouts) == 'table' then
        prefs.sneakcallouts = utils.pack(utils.mapList(tostring, decoded.sneakcallouts))
    end

    if type(decoded.colors) == 'table' then
        prefs.colors = utils.pack(utils.mapList(utils.stringToColor, decoded.colors))
    end

    return prefs
end

---Gets whether a retain command category is set to retain commands.
---@param category omichat.ChatCommandType
---@return boolean
function OmiChat.getRetainCommand(category)
    local prefs = OmiChat.getPlayerPreferences()
    if category == 'chat' then
        return prefs.retainChatInput
    elseif category == 'rp' then
        return prefs.retainRPInput
    elseif category == 'other' then
        return prefs.retainOtherInput
    end

    return false
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

---Sets whether the current player wants to use chat suggestions.
---@return boolean
function OmiChat.getUseSuggester()
    return OmiChat.getPlayerPreferences().useSuggester
end

---Saves the current player preferences to a file.
function OmiChat.savePlayerPreferences()
    if not OmiChat._playerPrefs then
        return
    end

    local prefs = OmiChat._playerPrefs
    local success, encoded = utils.json.tryEncode {
        VERSION = OmiChat._prefsVersion,
        useSuggester = prefs.useSuggester,
        showNameColors = prefs.showNameColors,
        retainChatInput = prefs.retainChatInput,
        retainRPInput = prefs.retainRPInput,
        retainOtherInput = prefs.retainOtherInput,
        colors = utils.pack(utils.map(utils.colorToHexString, prefs.colors)),
        callouts = prefs.callouts,
        sneakcallouts = prefs.sneakcallouts,
    }

    if not success or type(encoded) ~= 'string' then
        utils.logError('failed to write preferences (%s)', encoded)
        return
    end

    local outFile = getFileWriter(OmiChat._prefsFileName, true, false)
    outFile:write(encoded)
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

    local modData = OmiChat.getModData()
    if #nickname == 0 then
        modData.nicknames[username] = nil
        OmiChat.requestDataUpdate({
            target = username,
            field = 'nicknames',
        })

        if Option.EnableChatNameAsCharacterName then
            return false, getText('UI_OmiChat_set_name_empty')
        end

        return true, getText('UI_OmiChat_reset_name_success')
    end

    nickname = utils.interpolate(Option.FilterNickname, { name = nickname })
    if nickname == '' then
        return false, getText('UI_OmiChat_set_name_failure', utils.escapeRichText(nickname))
    end

    if Option.EnableChatNameAsCharacterName then
        OmiChat.updateCharacterName(nickname)
        return true, getText('UI_OmiChat_set_name_success', utils.escapeRichText(nickname))
    end

    modData.nicknames[username] = nickname
    OmiChat.requestDataUpdate({
        value = nickname,
        target = username,
        field = 'nicknames',
    })

    return true, getText('UI_OmiChat_set_name_success', utils.escapeRichText(nickname))
end

---Sets whether a retain command category will retain commands.
---@param category omichat.ChatCommandType
---@param value boolean
function OmiChat.setRetainCommand(category, value)
    local prefs = OmiChat.getPlayerPreferences()
    if category == 'chat' then
        prefs.retainChatInput = value
    elseif category == 'rp' then
        prefs.retainRPInput = value
    elseif category == 'other' then
        prefs.retainOtherInput = value
    end

    OmiChat.savePlayerPreferences()
end

---Sets whether the current player wants to use chat suggestions.
---@param useSuggester boolean
function OmiChat.setUseSuggester(useSuggester)
    OmiChat.getPlayerPreferences().useSuggester = not not useSuggester
    OmiChat.savePlayerPreferences()
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
