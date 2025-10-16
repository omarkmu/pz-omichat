local utils = require 'OmiChat/utils'

local array = utils.schema.array
local bool = utils.schema.bool
local color = utils.schema.color
local object = utils.schema.object
local int = utils.schema.int
local str = utils.schema.string
local container = utils.schema.container

---Upgrades player preferences from V1 to V2.
---@param values table
---@return omichat.PlayerPreferences
local function transformToV2(values)
    if type(values.VERSION) ~= 'number' or values.VERSION ~= 1 then
        return values
    end

    local prefs = {
        settings = {
            showNameColors = utils.default(values.showNameColors, true),
            useSuggester = utils.default(values.useSuggester, true),
            useSignEmotes = utils.default(values.useSignEmotes, true),
            retainChatInput = utils.default(values.retainChatInput, true),
            retainRPInput = utils.default(values.retainRPInput, false),
            retainOtherInput = utils.default(values.retainOtherInput, false),
            adminShowIcon = utils.default(values.adminShowIcon, true),
            adminKnowLanguages = utils.default(values.adminKnowLanguages, true),
            adminIgnoreRange = utils.default(values.adminIgnoreRange, true),
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
                name = getText('UI_OmiChat_ProfileManager_DefaultProfileName', '1'),
                colors = colors or {},
                callouts = callouts or {},
                sneakcallouts = sneakcallouts or {},
            },
        }
    end

    return prefs
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
