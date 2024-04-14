---Client API functionality related to handling player preferences.

---@class omichat.api.client
local OmiChat = require 'OmiChat/API/Client'

local utils = OmiChat.utils
local Option = OmiChat.Option
local concat = table.concat


---@type table<omichat.AdminOption, string>
local adminOptionMap = {
    ShowIcon = 'adminShowIcon',
    KnowAllLanguages = 'adminKnowLanguages',
    IgnoreMessageRange = 'adminIgnoreRange',

    -- deprecated
    show_icon = 'adminShowIcon',
    know_all_languages = 'adminKnowLanguages',
    ignore_message_range = 'adminIgnoreRange',
}

---Converts all elements of a list to strings.
---@param tab table
---@return string[]
local function readStringList(tab)
    return utils.pack(utils.mapList(tostring, tab))
end

---Reads the JSON preferences file and converts it to an equivalent Lua table.
---@return table?
local function readPrefsJson()
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

    local encoded = utils.trim(concat(content))
    if #encoded == 0 then
        return
    end

    local success, decoded = utils.json.tryDecode(encoded)
    if type(decoded) ~= 'table' then
        if success then
            decoded = 'invalid file content'
        end

        utils.logError('failed to read preferences (%s)', decoded)

        -- reset to default on failed read
        return
    end

    if type(decoded.VERSION) ~= 'number' then
        return
    end

    return decoded
end

---Converts the input to a boolean.
---If the input is `nil`, `default` is returned.
---@param value unknown
---@param default boolean
---@return boolean
local function readBool(value, default)
    return not not utils.default(value, default)
end

---Reads player preferences file with format version 1.
---@param decoded table
---@param prefs omichat.PlayerPreferences
local function readPrefsV1(decoded, prefs)
    prefs.showNameColors = readBool(decoded.showNameColors, prefs.showNameColors)
    prefs.useSuggester = readBool(decoded.useSuggester, prefs.useSuggester)
    prefs.useSignEmotes = readBool(decoded.useSignEmotes, prefs.useSignEmotes)
    prefs.retainChatInput = readBool(decoded.retainChatInput, prefs.retainChatInput)
    prefs.retainRPInput = readBool(decoded.retainRPInput, prefs.retainRPInput)
    prefs.retainOtherInput = readBool(decoded.retainOtherInput, prefs.retainOtherInput)
    prefs.adminShowIcon = readBool(decoded.adminShowIcon, prefs.adminShowIcon)
    prefs.adminKnowLanguages = readBool(decoded.adminKnowLanguages, prefs.adminShowIcon)
    prefs.adminIgnoreRange = readBool(decoded.adminIgnoreRange, prefs.adminShowIcon)

    if type(decoded.callouts) == 'table' then
        prefs.callouts = readStringList(decoded.callouts)
    end

    if type(decoded.sneakcallouts) == 'table' then
        prefs.sneakcallouts = readStringList(decoded.sneakcallouts)
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
end

---Reads player preferences file with format version 2.
---@param decoded table
---@param prefs omichat.PlayerPreferences
local function readPrefsV2(decoded, prefs)
    local settings = decoded.settings
    if type(settings) == 'table' then
        readPrefsV1(settings, prefs)

        prefs.showTyping = readBool(decoded.showTyping, prefs.showTyping)
    end
end


---Gets the value of a given admin option preference.
---@param option omichat.AdminOption
---@return boolean
function OmiChat.getAdminOption(option)
    local prefs = OmiChat.getPlayerPreferences()
    local mappedPref = adminOptionMap[option]
    return prefs[mappedPref] or false
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

---Gets a table with the default player preferences.
---@return omichat.PlayerPreferences
function OmiChat.getDefaultPlayerPreferences()
    return {
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
        showTyping = true,
        colors = {},
        callouts = {},
        sneakcallouts = {},
    }
end

---Retrieves whether the player has the admin option to ignore message range enabled.
---This does not check for admin permissions.
---@return boolean
function OmiChat.getIgnoreMessageRange()
    return OmiChat.getAdminOption('IgnoreMessageRange')
end

---Retrieves a boolean for whether the current player has name colors enabled.
---@return boolean
function OmiChat.getNameColorsEnabled()
    local prefs = OmiChat.getPlayerPreferences()
    return prefs.showNameColors
end

---Gets or creates the player preferences table.
---@return omichat.PlayerPreferences
function OmiChat.getPlayerPreferences()
    if OmiChat._playerPrefs then
        return OmiChat._playerPrefs
    end

    local prefs = OmiChat.getDefaultPlayerPreferences()
    OmiChat._playerPrefs = prefs

    local decoded = readPrefsJson()
    if not decoded then
        return prefs
    end

    local version = decoded.VERSION
    if version > OmiChat._prefsVersion then
        utils.logError('preferences file has a higher version (%d > %d)', version, OmiChat._prefsVersion)

        -- use default settings & add flag to avoid overwrite
        prefs.HIGHER_VERSION = true
        return prefs
    elseif version == 1 then
        readPrefsV1(decoded, prefs)
    elseif version == 2 then
        readPrefsV2(decoded, prefs)
    end

    return prefs
end

---Gets a color table for the current player's preference for a category, or `nil` if unset.
---@param category omichat.ColorCategory
---@return omichat.ColorTable?
function OmiChat.getPreferredColor(category)
    local prefs = OmiChat.getPlayerPreferences()
    return prefs.colors[category]
end

---Gets whether a command category is set to retain commands.
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

---Retrieves whether the player has the admin option to display a chat icon enabled.
---This does not check for admin permissions.
---@return boolean
function OmiChat.getShowAdminIcon()
    return OmiChat.getAdminOption('ShowIcon')
end

---Retrieves whether the player has the option to show typing indicators enabled.
function OmiChat.getShowTyping()
    local prefs = OmiChat.getPlayerPreferences()
    return prefs.showTyping
end

---Retrieves whether the player has the admin option to understand all roleplay languages enabled.
---This does not check for admin permissions.
---@return boolean
function OmiChat.getUnderstandAllLanguages()
    return OmiChat.getAdminOption('KnowAllLanguages')
end

---Gets whether the current player wants to use chat suggestions.
---@return boolean
function OmiChat.getUseSuggester()
    local prefs = OmiChat.getPlayerPreferences()
    return prefs.useSuggester
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
        settings = {
            useSuggester = prefs.useSuggester,
            useSignEmotes = prefs.useSignEmotes,
            showNameColors = prefs.showNameColors,
            retainChatInput = prefs.retainChatInput,
            retainRPInput = prefs.retainRPInput,
            retainOtherInput = prefs.retainOtherInput,
            adminShowIcon = prefs.adminShowIcon,
            adminKnowLanguages = prefs.adminKnowLanguages,
            adminIgnoreRange = prefs.adminIgnoreRange,
            showTyping = prefs.showTyping,
            colors = utils.pack(utils.map(utils.colorToHexString, prefs.colors)),
            callouts = prefs.callouts,
            sneakcallouts = prefs.sneakcallouts,
        },
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

    if mappedPref == 'adminKnowLanguages' then
        OmiChat.redrawMessages()
    end
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
    local prefs = OmiChat.getPlayerPreferences()
    prefs.showNameColors = not not enabled
    OmiChat.savePlayerPreferences()
end

---Sets a color table for the current player's preference for a category.
---@param category omichat.ColorCategory
---@param color omichat.ColorTable?
function OmiChat.setPreferredColor(category, color)
    local prefs = OmiChat.getPlayerPreferences()
    prefs.colors[category] = color
    OmiChat.savePlayerPreferences()
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

---Sets whether typing indicators should be shown for the current player.
---@param enable boolean
function OmiChat.setShowTyping(enable)
    local prefs = OmiChat.getPlayerPreferences()
    prefs.showTyping = not not enable
    OmiChat.savePlayerPreferences()
end

---Sets whether sign language emotes are enabled for the current player.
---@param enable boolean
function OmiChat.setSignEmotesEnabled(enable)
    local prefs = OmiChat.getPlayerPreferences()
    prefs.useSignEmotes = not not enable
    OmiChat.savePlayerPreferences()
end

---Sets whether the current player wants to use chat suggestions.
---@param useSuggester boolean
function OmiChat.setUseSuggester(useSuggester)
    local prefs = OmiChat.getPlayerPreferences()
    prefs.useSuggester = not not useSuggester
    OmiChat.savePlayerPreferences()
end
