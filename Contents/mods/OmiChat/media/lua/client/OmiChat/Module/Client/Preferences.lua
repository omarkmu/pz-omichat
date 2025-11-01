---Handles player preferences.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'
local schema = require 'OmiChat/Component/PreferencesSchema'

local utils = API.utils
local config = API.Configuration


---@class api.client.preferences
---@field private _prefs? PlayerPreferences The loaded player preferences.
local Preferences = {}

---Contains functions for getting and setting player preferences.
API.preferences = Preferences

---The current preferences file version.
---@private
Preferences._version = 2

---The old filename used for preferences.
---@private
Preferences._legacyFilename = 'omichat.json'

---The filename from which preferences are loaded.
---@private
Preferences._filename = 'omichat/settings.json'

---Associates admin options to setting names.
---@type table<AdminOption, string>
---@private
Preferences._adminOptionMap = {
    ShowIcon = 'adminShowIcon',
    KnowAllLanguages = 'adminKnowLanguages',
    IgnoreMessageRange = 'adminIgnoreRange',
}


---Gets or creates the player preferences table.
---@return PlayerPreferences preferences
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
        utils.log.warn.once(msg, version, Preferences._version)
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
---@param option AdminOption The option to retrieve.
---@return boolean enabled
function Preferences.getAdminOption(option)
    local prefs = Preferences.get()
    local mappedPref = Preferences._adminOptionMap[option]
    return prefs[mappedPref] or false
end

---Gets a color table matching the player's preference.
---@param name string The name of a stream.
---@return omi.ColorTable<integer>? color The player's preferred color for a stream, or `nil` if unset.
function Preferences.getColor(name)
    local profile = Preferences.getCurrentProfile()
    if not profile then
        return
    end

    return profile.colors[name]
end

---Retrieves the player's custom shouts for the current profile.
---@param shoutType CalloutCategory The type of shouts to retrieve.
---@return string[]? shouts The table of shouts. If custom shouts are disabled or no profile is set, `nil`.
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
---@return PlayerProfile? profile
function Preferences.getCurrentProfile()
    local prefs = Preferences.get()
    return prefs.profiles[prefs.profileIndex]
end

---Returns the index of the current player profile.
---@return integer? index
function Preferences.getCurrentProfileIndex()
    local prefs = Preferences.get()
    if prefs.profileIndex < 1 then
        return
    end

    return prefs.profileIndex
end

---Gets a table with the default player preferences.
---@return PlayerPreferences defaultPreferences
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
---@return boolean shouldIgnore
function Preferences.getIgnoreMessageRange()
    local prefs = Preferences.get()
    return prefs.adminIgnoreRange
end

---Retrieves a boolean for whether the current player has name colors enabled.
---@return boolean enabled
function Preferences.getNameColorsEnabled()
    local prefs = Preferences.get()
    return prefs.showNameColors
end

---Returns the configured player profiles.
---@return PlayerProfile[] profiles
function Preferences.getProfiles()
    local prefs = Preferences.get()
    return prefs.profiles
end

---Gets whether a command category is set to retain commands.
---@param category StreamCategory
---@return boolean shouldRetain
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
---@return boolean enabled
function Preferences.getSignEmotesEnabled()
    local prefs = Preferences.get()
    return prefs.useSignEmotes
end

---Retrieves whether the player has the admin option to display a chat icon enabled.
---This does not check for admin permissions.
---@return boolean shouldDisplay
function Preferences.getShowAdminIcon()
    local prefs = Preferences.get()
    return prefs.adminShowIcon
end

---Retrieves whether the player has the option to show typing indicators enabled.
---@return boolean showTyping
function Preferences.getShowTyping()
    local prefs = Preferences.get()
    return prefs.showTyping
end

---Retrieves whether suggestions should be applied on `Enter`.
---@return boolean suggestOnEnter
function Preferences.getSuggestOnEnter()
    local prefs = Preferences.get()
    return prefs.suggestOnEnter
end

---Retrieves whether suggestions should be applied on `Tab`.
---@return boolean suggestOnTab
function Preferences.getSuggestOnTab()
    local prefs = Preferences.get()
    return prefs.suggestOnTab
end

---Retrieves whether the player has the admin option to understand all roleplay languages enabled.
---This does not check for admin permissions.
---@return boolean shouldUnderstandAll
function Preferences.getUnderstandAllLanguages()
    local prefs = Preferences.get()
    return prefs.adminKnowLanguages
end

---Gets whether the current player wants to use chat suggestions.
---@return boolean useSuggester
function Preferences.getUseSuggester()
    local prefs = Preferences.get()
    return prefs.useSuggester
end

---Reloads the currently set profile.
---If no profile is set, this switches to the default profile.
function Preferences.refreshProfile()
    local prefs = Preferences.get()
    Preferences.switchProfile(prefs.profileIndex or 0)
end

---Saves the current player preferences to a file.
---@return boolean success
function Preferences.save()
    local prefs = Preferences._prefs
    if not prefs or prefs.HIGHER_VERSION then
        return false
    end

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
---@param option AdminOption The option to update.
---@param value boolean The new value.
function Preferences.setAdminOption(option, value)
    local prefs = Preferences.get()
    local mappedPref = Preferences._adminOptionMap[option]
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
---@param name string The name of the stream to set a color for.
---@param color omi.ColorTable<integer>? The color table to set, or `nil` to unset the value.
function Preferences.setColor(name, color)
    local profile = Preferences.getCurrentProfile()
    if not profile then
        return
    end

    profile.colors[name] = color
end

---Sets the player's custom shouts.
---@param shoutType CalloutCategory The type of shouts to set.
---@param shouts string[]? The list of shouts to set.
---@return boolean success
function Preferences.setCustomShouts(shoutType, shouts)
    local profile = Preferences.getCurrentProfile()
    if not profile then
        return false
    end

    profile[shoutType] = shouts and shouts or {}
    Preferences.save()
    return true
end

---Sets whether the current player has name colors enabled.
---@param enabled boolean Flag for whether name colors should be shown.
function Preferences.setNameColorsEnabled(enabled)
    local prefs = Preferences.get()
    prefs.showNameColors = not not enabled
    Preferences.save()
end

---Sets the list of player profiles.
---@param profiles PlayerProfile[] A list of profiles. This is assumed to be valid.
function Preferences.setProfiles(profiles)
    local prefs = Preferences.get()
    prefs.profiles = profiles
    prefs.profileIndex = utils.clamp(prefs.profileIndex, 0, #profiles)
    Preferences.save()
end

---Sets whether a retain command category will retain commands.
---@param category StreamCategory The command category to update.
---@param value boolean Flag for whether commands should be retained.
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
---@param showTyping boolean Flag for whether typing indicators should be shown.
function Preferences.setShowTyping(showTyping)
    local prefs = Preferences.get()
    prefs.showTyping = not not showTyping
    Preferences.save()
end

---Sets whether sign language emotes are enabled for the current player.
---@param enable boolean Flag for whether sign language emotes should play when using a signed language.
function Preferences.setSignEmotesEnabled(enable)
    local prefs = Preferences.get()
    prefs.useSignEmotes = not not enable
    Preferences.save()
end

---Sets whether suggestions should be applied on `Enter`.
---@param enable boolean Flag for whether suggestions should be entered when pressing `Enter`.
function Preferences.setSuggestOnEnter(enable)
    local prefs = Preferences.get()
    prefs.suggestOnEnter = enable
    Preferences.save()
end

---Sets whether suggestions should be applied on `Tab`.
---@param enable boolean Flag for whether suggestions should be entered when pressing `Tab`.
function Preferences.setSuggestOnTab(enable)
    local prefs = Preferences.get()
    prefs.suggestOnTab = enable
    Preferences.save()
end

---Sets whether the current player wants to use chat suggestions.
---@param useSuggester boolean Flag for whether suggestions should be shown.
function Preferences.setUseSuggester(useSuggester)
    local prefs = Preferences.get()
    prefs.useSuggester = not not useSuggester
    Preferences.save()
end

---Switches to a player preference profile.
---@param idx integer The profile index, or `0` for the default profile.
---@return boolean success
function Preferences.switchProfile(idx)
    local prefs = Preferences.get()
    local profile = prefs.profiles[idx] ---@type PlayerProfile?
    if not profile and idx >= 1 then
        return false
    end

    prefs.profileIndex = math.max(0, math.min(idx, #prefs.profiles))

    local doNickname = profile and profile.chatNickname and config:isNicknameEnabled()

    local colors = profile and profile.colors or {}
    API.player.setSpeechColor(colors.speech, not doNickname)

    if profile and doNickname then
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
    local decoded, err = schema:readFile({
        filename = Preferences._filename,
        create = false,
    })

    if err then
        -- read from legacy file when file is not found
        if utils.startsWith(err, 'could not open file') then
            decoded, err = schema:readFile({
                filename = Preferences._legacyFilename,
                create = false,
            })
        end

        if err then
            utils.log.error('Failed to read preferences: %s', err)
        end
    end

    if not decoded then
        return
    end

    if type(decoded.VERSION) ~= 'number' then
        return
    end

    return decoded
end


return Preferences

--#region Type Definitions

---@alias AdminOption
---| 'ShowIcon'
---| 'KnowAllLanguages'
---| 'IgnoreMessageRange'

---@alias CalloutCategory
---| 'callouts'
---| 'sneakcallouts'

--#endregion
