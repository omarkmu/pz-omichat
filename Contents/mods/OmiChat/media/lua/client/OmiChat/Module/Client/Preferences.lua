---Handles player preferences.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client
local schema = require 'OmiChat/Component/PreferencesSchema'

local utils = API.utils
local config = API.Configuration


---@class omichat.api.client.preferences
local Preferences = {}
Preferences._filename = 'omichat.json'
Preferences._version = 2


---@type table<omichat.AdminOption, string>
local adminOptionMap = {
    ShowIcon = 'adminShowIcon',
    KnowAllLanguages = 'adminKnowLanguages',
    IgnoreMessageRange = 'adminIgnoreRange',
}


---Gets or creates the player preferences table.
---@return omichat.PlayerPreferences
function Preferences.get()
    if Preferences._prefs then
        return Preferences._prefs
    end

    local prefs = Preferences.getDefaultPlayerPreferences()
    Preferences._prefs = prefs

    local decoded = Preferences._readPrefsJson()
    if not decoded then
        return prefs
    end

    local version = decoded.VERSION
    if version > Preferences._version then
        -- use default settings & add flag to avoid overwrite
        local msg = 'Preferences file has a higher version (%d > %d). Changes to preferences will not be saved.'
        utils.log.once(msg, version, Preferences._version)
        prefs.HIGHER_VERSION = true

        return prefs
    end

    for k, v in pairs(decoded.settings) do
        prefs[k] = v
    end

    prefs.profiles = decoded.profiles
    prefs.profileIndex = decoded.profileIndex
    return prefs
end

---Gets the value of a given admin option preference.
---@param option omichat.AdminOption
---@return boolean
function Preferences.getAdminOption(option)
    local prefs = Preferences.get()
    local mappedPref = adminOptionMap[option]
    return prefs[mappedPref] or false
end

---Gets a color table for the current player's preference for a stream, or `nil` if unset.
---@param id string
---@return omi.ColorTable?
function Preferences.getColor(id)
    local profile = Preferences.getCurrentProfile()
    if not profile then
        return
    end

    return profile.colors[id]
end

---Retrieves the player's custom shouts for the current profile.
---@param shoutType omichat.CalloutCategory The type of shouts to retrieve.
---@return string[]?
function Preferences.getCustomShouts(shoutType)
    if not config:isCustomShoutsEnabled() then
        return
    end

    local profile = Preferences.getCurrentProfile()
    if not profile then
        return
    end

    return profile[shoutType]
end

---Returns the current player profile.
---@return omichat.PlayerProfile?
function Preferences.getCurrentProfile()
    local prefs = Preferences.get()
    local idx = prefs.profileIndex
    local profile = prefs.profiles[idx]
    return profile
end

---Returns the index of the current player profile.
---@return integer?
function Preferences.getCurrentProfileIndex()
    local prefs = Preferences.get()
    if prefs.profileIndex < 1 then
        return
    end

    return prefs.profileIndex
end

---Gets a table with the default player preferences.
---@return omichat.PlayerPreferences
function Preferences.getDefaultPlayerPreferences()
    return {
        HIGHER_VERSION = false,
        showNameColors = true,
        useSuggester = true,
        suggestOnEnter = true,
        suggestOnTab = true,
        useSignEmotes = true,
        retainChatInput = true,
        retainRPInput = false,
        retainOtherInput = false,
        adminShowIcon = true,
        adminKnowLanguages = true,
        adminIgnoreRange = true,
        showTyping = true,
        profileIndex = 0,
        profiles = {},
    }
end

---Retrieves whether the player has the admin option to ignore message range enabled.
---This does not check for admin permissions.
---@return boolean
function Preferences.getIgnoreMessageRange()
    local prefs = Preferences.get()
    return prefs.adminIgnoreRange
end

---Retrieves a boolean for whether the current player has name colors enabled.
---@return boolean
function Preferences.getNameColorsEnabled()
    local prefs = Preferences.get()
    return prefs.showNameColors
end

---Returns the configured player profiles.
---@return omichat.PlayerProfile[]
function Preferences.getProfiles()
    local prefs = Preferences.get()
    return prefs.profiles
end

---Gets whether a command category is set to retain commands.
---@param category omichat.ChatCommandCategory
---@return boolean
function Preferences.getRetainCommand(category)
    local prefs = Preferences.get()
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
function Preferences.getSignEmotesEnabled()
    local prefs = Preferences.get()
    return prefs.useSignEmotes
end

---Retrieves whether the player has the admin option to display a chat icon enabled.
---This does not check for admin permissions.
---@return boolean
function Preferences.getShowAdminIcon()
    local prefs = Preferences.get()
    return prefs.adminShowIcon
end

---Retrieves whether the player has the option to show typing indicators enabled.
function Preferences.getShowTyping()
    local prefs = Preferences.get()
    return prefs.showTyping
end

---Retrieves whether suggestions should be applied on Enter.
---@return boolean
function Preferences.getSuggestOnEnter()
    local prefs = Preferences.get()
    return prefs.suggestOnEnter
end

---Retrieves whether suggestions should be applied on Tab.
---@return boolean
function Preferences.getSuggestOnTab()
    local prefs = Preferences.get()
    return prefs.suggestOnTab
end

---Retrieves whether the player has the admin option to understand all roleplay languages enabled.
---This does not check for admin permissions.
---@return boolean
function Preferences.getUnderstandAllLanguages()
    local prefs = Preferences.get()
    return prefs.adminKnowLanguages
end

---Gets whether the current player wants to use chat suggestions.
---@return boolean
function Preferences.getUseSuggester()
    local prefs = Preferences.get()
    return prefs.useSuggester
end

---Saves the current player preferences to a file.
---@return boolean success
function Preferences.save()
    if not Preferences._prefs or Preferences._prefs.HIGHER_VERSION then
        return false
    end

    local prefs = Preferences._prefs
    local encoded, err = utils.json.tryEncode {
        VERSION = Preferences._version,
        profileIndex = prefs.profileIndex,
        profiles = prefs.profiles,
        settings = {
            useSuggester = prefs.useSuggester,
            suggestOnEnter = prefs.suggestOnEnter,
            suggestOnTab = prefs.suggestOnTab,
            useSignEmotes = prefs.useSignEmotes,
            showNameColors = prefs.showNameColors,
            retainChatInput = prefs.retainChatInput,
            retainRPInput = prefs.retainRPInput,
            retainOtherInput = prefs.retainOtherInput,
            adminShowIcon = prefs.adminShowIcon,
            adminKnowLanguages = prefs.adminKnowLanguages,
            adminIgnoreRange = prefs.adminIgnoreRange,
            showTyping = prefs.showTyping,
        },
    }

    if not encoded then
        utils.log.error('Failed to write preferences: %s', err)
        return false
    end

    pcall(function()
        local outFile = getFileWriter(Preferences._filename, true, false)
        outFile:write(encoded)
        outFile:close()
    end)

    return true
end

---Sets the value of a given admin option preference.
---@param option omichat.AdminOption
---@param value boolean
function Preferences.setAdminOption(option, value)
    local prefs = Preferences.get()
    local mappedPref = adminOptionMap[option]
    if prefs[mappedPref] == nil then
        return
    end

    prefs[mappedPref] = not not value
    Preferences.save()

    if mappedPref == 'adminKnowLanguages' or mappedPref == 'adminIgnoreRange' then
        API.ui.redraw()
    end
end

---Sets a color table for the current player's preference for a stream.
---This sets the value in the current profile.
---@param category string
---@param color omi.ColorTable?
function Preferences.setColor(category, color)
    local profile = Preferences.getCurrentProfile()
    if not profile then
        return
    end

    profile.colors[category] = color
end

---Sets the player's custom shouts.
---@param shouts string[]?
---@param shoutType omichat.CalloutCategory The type of shouts to set.
---@return boolean success
function Preferences.setCustomShouts(shouts, shoutType)
    local profile = Preferences.getCurrentProfile()
    if not profile then
        return false
    end

    profile[shoutType] = shouts and shouts or {}
    Preferences.save()
    return true
end

---Sets whether the current player has name colors enabled.
---@param enabled boolean True to enable, false to disable.
function Preferences.setNameColorsEnabled(enabled)
    local prefs = Preferences.get()
    prefs.showNameColors = not not enabled
    Preferences.save()
end

---Sets the list of player profiles.
---This assumes the input is a valid list of `PlayerProfile` tables.
---@param profiles omichat.PlayerProfile[]
function Preferences.setProfiles(profiles)
    local prefs = Preferences.get()
    prefs.profiles = profiles
    prefs.profileIndex = utils.clamp(prefs.profileIndex, 0, #profiles)
    Preferences.save()
end

---Sets whether a retain command category will retain commands.
---@param category omichat.ChatCommandCategory
---@param value boolean
function Preferences.setRetainCommand(category, value)
    local prefs = Preferences.get()
    if category == 'chat' then
        prefs.retainChatInput = value
    elseif category == 'rp' then
        prefs.retainRPInput = value
    elseif category == 'other' then
        prefs.retainOtherInput = value
    end

    Preferences.save()
end

---Sets whether typing indicators should be shown for the current player.
---@param enable boolean
function Preferences.setShowTyping(enable)
    local prefs = Preferences.get()
    prefs.showTyping = not not enable
    Preferences.save()
end

---Sets whether sign language emotes are enabled for the current player.
---@param enable boolean
function Preferences.setSignEmotesEnabled(enable)
    local prefs = Preferences.get()
    prefs.useSignEmotes = not not enable
    Preferences.save()
end

---Sets whether suggestions should be applied on Enter.
---@param enable boolean
function Preferences.setSuggestOnEnter(enable)
    local prefs = Preferences.get()
    prefs.suggestOnEnter = enable
    Preferences.save()
end

---Sets whether suggestions should be applied on Tab.
---@param enable boolean
function Preferences.setSuggestOnTab(enable)
    local prefs = Preferences.get()
    prefs.suggestOnTab = enable
    Preferences.save()
end

---Sets whether the current player wants to use chat suggestions.
---@param useSuggester boolean
function Preferences.setUseSuggester(useSuggester)
    local prefs = Preferences.get()
    prefs.useSuggester = not not useSuggester
    Preferences.save()
end

---Switches to a player preference profile.
---@param idx integer
---@return boolean success
function Preferences.switchProfile(idx)
    local prefs = Preferences.get()
    local profile = prefs.profiles[idx] ---@type omichat.PlayerProfile?
    if not profile and idx >= 1 then
        return false
    end

    prefs.profileIndex = math.max(0, math.min(idx, #prefs.profiles))

    local colors = profile and profile.colors or {}
    API.player.setSpeechColor(colors.speech)

    if profile and profile.chatNickname and config:isNicknameEnabled() then
        API.player.setNickname(profile.chatNickname)
    end

    Preferences.save()
    return true
end

---Switches to the default player preference profile.
function Preferences.switchToDefaultProfile()
    Preferences.switchProfile(0)
end


---Reads the JSON preferences file and converts it to an equivalent Lua table.
---@return table?
---@private
function Preferences._readPrefsJson()
    local decoded, err = schema:readFile(Preferences._filename)
    if err then
        utils.log.error('Failed to read preferences: %s', err)
    end

    if not decoded then
        return
    end

    if type(decoded.VERSION) ~= 'number' then
        return
    end

    return decoded
end


API.preferences = Preferences
return Preferences
