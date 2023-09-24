local lib = require 'OmiChat/lib'

---Helper for retrieving sandbox variables and their defaults.
---@class omichat.Options : omi.Sandbox
---@field AllowCustomShouts boolean
---@field AllowCustomSneakShouts boolean
---@field AllowEmotes boolean
---@field AllowMe boolean
---@field AllowSetName boolean
---@field AllowSetNameColor boolean
---@field UseNameColorInAllChats boolean
---@field UseSpeechColorAsDefaultNameColor boolean
---@field AllowSetChatColors boolean
---@field AllowSetSpeechColor boolean
---@field EnableEmojiPicker boolean
---@field IncludeMiscellaneousEmoji boolean
---@field EnableTADCompat boolean
---@field UppercaseCustomShouts boolean
---@field LowercaseCustomSneakShouts boolean
---@field UseLocalWhisper boolean
---@field UseChatNameAsCharacterName boolean
---@field CustomShoutMaxLength integer
---@field MaximumCustomShouts integer
---@field MinimumColorValue integer
---@field MaximumColorValue integer
---@field NameMaxLength integer
---@field MeRange integer
---@field SayRange integer
---@field WhisperRange integer
---@field ShoutRange integer
---@field MeColor string
---@field WhisperColor string
---@field NameFormat string
---@field TagFormat string
---@field TimestampFormat string
---@field MeOverheadFormat string
---@field WhisperOverheadFormat string
---@field MeChatFormat string
---@field SayChatFormat string
---@field WhisperChatFormat string
---@field ShoutChatFormat string
---@field AdminChatFormat string
---@field GeneralChatFormat string
---@field DiscordChatFormat string
---@field RadioChatFormat string
---@field FactionChatFormat string
---@field SafehouseChatFormat string
---@field IncomingPrivateChatFormat string
---@field OutgoingPrivateChatFormat string
---@field ServerChatFormat string
---@field MenuNameFormat string
local Option = lib.sandbox('OmiChat')

local floor = math.floor
local utils = require 'OmiChat/util'

---@type table<omichat.ColorCategory, omichat.ColorTable>
local colorDefaults = {
    name = {r=255,g=255,b=255},
    admin = {r=255,g=255,b=255},
    me = {r=130,g=130,b=130},
    say = {r=255,g=255,b=255},
    shout = {r=255,g=51,b=51},
    -- pm whisper
    private = {r=85,g=26,b=139},
    -- local whisper
    whisper = {r=85,g=48,b=139},
    general = {r=255,g=165,b=0},
    discord = {r=114,g=137,b=218},
    radio = {r=178,g=178,b=178},
    faction = {r=22,g=113,b=20},
    safehouse = {r=55,g=148,b=53},
    server = {r=0,g=128,b=255},
}

---Returns the default color associated with a category.
---@param category omichat.ColorCategory
---@param username string? The username of the user to use for getting defaults, if applicable.
---@return omichat.ColorTable
function Option:getDefaultColor(category, username)
    if category == 'speech' or (category == 'name' and self.UseSpeechColorAsDefaultNameColor) then
        local speechColor
        if username then
            local player = getPlayerFromUsername(username)
            if player then
                speechColor = player:getSpeakColour()
            end
        else
            speechColor = getCore():getMpTextColor()
        end

        if category == 'speech' and not speechColor then
            speechColor = getCore():getMpTextColor()
        end

        if speechColor then
            return {
                r = floor(speechColor:getR() * 255),
                g = floor(speechColor:getG() * 255),
                b = floor(speechColor:getB() * 255),
            }
        end
    end

    if category == 'me' then
        local settingDefault = utils.stringToColor(self.MeColor)
        if settingDefault then
            return settingDefault
        end
    end

    if category == 'whisper' then
        local settingDefault = utils.stringToColor(self.WhisperColor)
        if settingDefault then
            return settingDefault
        end
    end

    if category == 'faction' then
        local player
        if username then
            player = getPlayerFromUsername(username)
        else
            player = getSpecificPlayer(0)
        end

        local playerFaction = player and Faction.getPlayerFaction(player)
        if playerFaction then
            local color = playerFaction:getTagColor():toColor()

            return {
                r = color:getRed(),
                g = color:getGreen(),
                b = color:getBlue(),
            }
        end
    end

    if colorDefaults[category] then
        return colorDefaults[category]
    end

    error(string.format('invalid color category: %s', category))
end


return Option
