---Client API functionality related to handling player data.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local utils = OmiChat.utils
local Option = OmiChat.Option
local concat = table.concat
local getText = getText

---@type table<omichat.AdminOption, string>
local adminOptionMap = {
    show_icon = 'adminShowIcon',
    know_all_languages = 'adminKnowLanguages',
    ignore_message_range = 'adminIgnoreRange',
}


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
        local prefs = OmiChat.getPlayerPreferences()
        prefs.colors[category] = color
        OmiChat.savePlayerPreferences()

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

---Gets the value of a given admin option preference.
---@param option omichat.AdminOption
---@return boolean
function OmiChat.getAdminOption(option)
    local prefs = OmiChat.getPlayerPreferences()
    local mappedPref = adminOptionMap[option]
    return prefs[mappedPref] or false
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

---Retrieves the player's custom shouts.
---@param shoutType omichat.CalloutCategory The type of shouts to retrieve.
---@return string[]?
function OmiChat.getCustomShouts(shoutType)
    if not Option.EnableCustomShouts then
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
    local username = utils.getPlayerUsername()
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
        HIGHER_VERSION = false,
        showNameColors = true,
        useSuggester = true,
        useSignEmotes = true,
        retainChatInput = true,
        retainRPInput = true,
        retainOtherInput = false,
        adminShowIcon = true,
        adminKnowLanguages = true,
        adminIgnoreRange = true,
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

    local version = decoded.VERSION
    if type(version) == 'number' and version > OmiChat._prefsVersion then
        utils.logError('preferences file has a higher version (%d > %d)', version, OmiChat._prefsVersion)

        -- use default settings & add flag to avoid overwrite
        prefs.HIGHER_VERSION = true
        return prefs
    end

    prefs.showNameColors = not not utils.default(decoded.showNameColors, prefs.showNameColors)
    prefs.useSuggester = not not utils.default(decoded.useSuggester, prefs.useSuggester)
    prefs.useSignEmotes = not not utils.default(decoded.useSignEmotes, prefs.useSignEmotes)
    prefs.retainChatInput = not not utils.default(decoded.retainChatInput, prefs.retainChatInput)
    prefs.retainRPInput = not not utils.default(decoded.retainRPInput, prefs.retainRPInput)
    prefs.retainOtherInput = not not utils.default(decoded.retainOtherInput, prefs.retainOtherInput)
    prefs.adminShowIcon = not not utils.default(decoded.adminShowIcon, prefs.adminShowIcon)
    prefs.adminKnowLanguages = not not utils.default(decoded.adminKnowLanguages, prefs.adminShowIcon)
    prefs.adminIgnoreRange = not not utils.default(decoded.adminIgnoreRange, prefs.adminShowIcon)

    if type(decoded.callouts) == 'table' then
        prefs.callouts = utils.pack(utils.mapList(tostring, decoded.callouts))
    end

    if type(decoded.sneakcallouts) == 'table' then
        prefs.sneakcallouts = utils.pack(utils.mapList(tostring, decoded.sneakcallouts))
    end

    if type(decoded.colors) == 'table' then
        prefs.colors = {}
        for k, v in pairs(decoded.colors) do
            local color = utils.stringToColor(v)
            if color then
                prefs.colors[k] = color
            end
        end
    end

    return prefs
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

---Retrieves a boolean for whether the current player has sign language emotes enabled.
---@return boolean
function OmiChat.getSignEmotesEnabled()
    return OmiChat.getPlayerPreferences().useSignEmotes
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
---@return boolean success
function OmiChat.savePlayerPreferences()
    if not OmiChat._playerPrefs or OmiChat._playerPrefs.HIGHER_VERSION then
        return false
    end

    local prefs = OmiChat._playerPrefs
    local success, encoded = utils.json.tryEncode {
        VERSION = OmiChat._prefsVersion,
        useSuggester = prefs.useSuggester,
        useSignEmotes = prefs.useSignEmotes,
        showNameColors = prefs.showNameColors,
        retainChatInput = prefs.retainChatInput,
        retainRPInput = prefs.retainRPInput,
        retainOtherInput = prefs.retainOtherInput,
        adminShowIcon = prefs.adminShowIcon,
        adminKnowLanguages = prefs.adminKnowLanguages,
        adminIgnoreRange = prefs.adminIgnoreRange,
        colors = utils.pack(utils.map(utils.colorToHexString, prefs.colors)),
        callouts = prefs.callouts,
        sneakcallouts = prefs.sneakcallouts,
    }

    if not success or type(encoded) ~= 'string' then
        utils.logError('failed to write preferences (%s)', tostring(encoded))
        return false
    end

    local outFile = getFileWriter(OmiChat._prefsFileName, true, false)
    outFile:write(encoded)
    outFile:close()

    return true
end

---Sets the value of a given admin option preference.
---@param option omichat.AdminOption
---@param value boolean
function OmiChat.setAdminOption(option, value)
    local prefs = OmiChat.getPlayerPreferences()
    local mappedPref = adminOptionMap[option]
    if prefs[mappedPref] == nil then
        return
    end

    prefs[mappedPref] = not not value
    OmiChat.savePlayerPreferences()

    if option == 'know_all_languages' then
        OmiChat.redrawMessages()
    end
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

---Sets the player's custom shouts.
---@param shouts string[]?
---@param shoutType omichat.CalloutCategory The type of shouts to set.
function OmiChat.setCustomShouts(shouts, shoutType)
    if not Option.EnableCustomShouts then
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

        return true, getText('UI_OmiChat_reset_name_success')
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
        return false, err or getText('UI_OmiChat_set_name_failure', utils.escapeRichText(original))
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

---Sets the number of available roleplay language slots for the current player.
---@param slots integer
---@return boolean success
function OmiChat.setRoleplayLanguageSlots(slots)
    local username = utils.getPlayerUsername()
    if not username then
        return false
    end

    if slots < 0 or slots > 32 then
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

---Sets whether sign language emotes are enabled for the current player.
---@param enable boolean
function OmiChat.setSignEmotesEnabled(enable)
    OmiChat.getPlayerPreferences().useSignEmotes = not not enable
    OmiChat.savePlayerPreferences()
end

---Sets whether the current player wants to use chat suggestions.
---@param useSuggester boolean
function OmiChat.setUseSuggester(useSuggester)
    OmiChat.getPlayerPreferences().useSuggester = not not useSuggester
    OmiChat.savePlayerPreferences()
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
        return false, err or getText('UI_OmiChat_set_name_failure', utils.escapeRichText(name))
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

    return true, getText('UI_OmiChat_set_name_success', utils.escapeRichText(name))
end
