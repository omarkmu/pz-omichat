---Schema for player preferences.
---@namespace omichat

local utils = require 'OmiChat/Utils'

local array = utils.schema.array
local bool = utils.schema.bool
local color = utils.schema.color
local object = utils.schema.object
local int = utils.schema.int
local str = utils.schema.string
local container = utils.schema.container
local getAttr = utils.getAttr

---Upgrades player preferences from V1 to V2.
---@param values table
---@return PlayerPreferences
local function transformToV2(values)
    if type(values.VERSION) ~= 'number' or values.VERSION ~= 1 then
        return values
    end

    local prefs = {
        settings = {
            showNameColors = values.showNameColors ~= false,
            useSuggester = values.useSuggester ~= false,
            useSignEmotes = values.useSignEmotes ~= false,
            retainChatInput = values.retainChatInput ~= false,
            retainRPInput = values.retainRPInput or false,
            retainOtherInput = values.retainOtherInput or false,
            adminShowIcon = values.adminShowIcon ~= false,
            adminKnowLanguages = values.adminKnowLanguages ~= false,
            adminIgnoreRange = values.adminIgnoreRange ~= false,
        },
    }

    local callouts
    if type(values.callouts) == 'table' then
        callouts = utils.mapList(tostring, values.callouts)
        if #callouts == 0 then
            callouts = nil
        end
    end

    local sneakcallouts
    if type(values.sneakcallouts) == 'table' then
        sneakcallouts = utils.mapList(tostring, values.sneakcallouts)
        if #sneakcallouts == 0 then
            sneakcallouts = nil
        end
    end

    local colors
    if type(values.colors) == 'table' then
        colors = {}

        local hasColor
        for k, v in pairs(values.colors) do
            local colorTable = utils.color.fromString(v)
            if colorTable then
                hasColor = true
                colors[k] = colorTable
            end
        end

        if not hasColor then
            colors = nil
        end
    end

    if callouts or sneakcallouts or colors then
        prefs.profileIndex = 1
        prefs.profiles = {
            {
                name = getAttr('profile-manager', 'default-profile-name', { index = 1 }),
                colors = colors or {},
                callouts = callouts or {},
                sneakcallouts = sneakcallouts or {},
            },
        }
    end

    return prefs --[[@as PlayerPreferences]]
end

return utils.schema {
    properties = {
        VERSION = int(2),

        settings = container {
            adminShowIcon = bool(true),
            adminKnowLanguages = bool(true),
            adminIgnoreRange = bool(true),

            useSuggester = bool(true),
            suggestOnEnter = bool(true),
            suggestOnTab = bool(true),

            retainChatInput = bool(true),
            retainRPInput = bool(false),
            retainOtherInput = bool(false),

            showNameColors = bool(true),
            useSignEmotes = bool(true),
            showTyping = bool(true),
        },

        profileIndex = int(0),
        profiles = array {
            items = object {
                properties = {
                    name = str(),
                    chatNickname = str(),
                    callouts = array { items = str() },
                    sneakcallouts = array { items = str() },
                    colors = object { additionalProperties = color() },
                },
            },
        },
    },

    transforms = {
        transformToV2,
    },
}

--#region Type Definitions

---@class PlayerPreferences
---@field HIGHER_VERSION? boolean Flag which is set when the preferences file had a higher verson than the current version, to avoid bad overwrites.
---@field showNameColors boolean Flag for whether name colors are enabled.
---@field useSuggester boolean Flag for whether suggestions are enabled.
---@field useSignEmotes boolean Flag for whether signed roleplay languages should play a random emote.
---@field showTyping boolean Flag for whether typing indicators should be shown and sent.
---@field suggestOnEnter boolean Flag for whether suggestions should be entered when pressing `Enter`.
---@field suggestOnTab boolean Flag for whether suggestions should be entered when pressing `Tab`.
---@field retainChatInput boolean Flag for whether to retain chat input for chat streams.
---@field retainRPInput boolean Flag for whether to retain chat input for roleplay streams (e.g., `/me`).
---@field retainOtherInput boolean Flag for whether to retain other chat input.
---@field adminShowIcon boolean Flag for whether the admin icon should display in chat.
---@field adminKnowLanguages boolean Flag for whether all languages should be treated as known.
---@field adminIgnoreRange boolean Flag for whether message range should be ignored.
---@field profileIndex integer The index of the current profile.
---@field profiles PlayerProfile[] List of chat profiles.

---@class PlayerProfile
---@field name string The name of the profile.
---@field chatNickname? string Nickname to use in chat when switching to a profile.
---@field callouts string[] Custom callouts.
---@field sneakcallouts string[] Custom sneak callouts.
---@field colors table<string, omi.ColorTable<integer>> Associates stream names to custom colors.

--#endregion
