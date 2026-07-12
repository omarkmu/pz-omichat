---Handles IsoPlayer overrides.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local config = API.Configuration
local core = getCore()
local getTextVanilla = getText

local min = math.min
local _IsoPlayer = __classmetatables[IsoPlayer.class].__index ---@type any
local _Callout = _IsoPlayer.Callout

local SHOUTS = {}
local SNEAK_SHOUTS = {}
for i = 1, 3 do
    local shoutId = 'IGUI_PlayerText_Callout' .. i .. 'New'
    local sneakShoutId = 'IGUI_PlayerText_Callout' .. i .. 'Sneak'
    SHOUTS[shoutId] = getTextVanilla(shoutId)
    SNEAK_SHOUTS[sneakShoutId] = getTextVanilla(sneakShoutId)
end

---Gets the chat stream to use for a callout.
---@param player IsoPlayer
---@param isSneaking boolean
---@param playEmote boolean?
---@return ChatStream?
local function getCalloutStream(player, isSneaking, playEmote)
    local stream
    if isSneaking then
        stream = API.streams.firstChatStreamWithTag('SneakCallout')
    end

    stream = stream
        or API.streams.firstChatStreamWithTag('Callout')
        or API.streams.getChatStream('yell', { enabledOnly = true })

    if not stream then
        utils.log.warn.once('No stream defined for callouts; add the `Callout` tag to a stream')
        _Callout(player, playEmote)
        return
    end

    return stream
end

---Gets the text to use for a callout.
---@param isSneaking boolean
---@return string
local function getCalloutText(isSneaking)
    local shouts = API.preferences.getCustomShouts(isSneaking and 'sneakcallouts' or 'callouts')
    if #shouts == 0 then
        shouts = nil
    end

    local shoutMax
    if not shouts then
        shouts = API.player.getDefaultShouts(isSneaking)
        shoutMax = #shouts
    else
        shoutMax = min(#shouts, config.MAX_CUSTOM_SHOUTS)
    end

    local shout = shouts[utils.randInt(1, shoutMax)] --[[@as string]]
    return isSneaking and shout:lower() or shout:upper()
end

---Override to enable custom callouts.
---@param self IsoPlayer
---@param playEmote boolean?
function _IsoPlayer.Callout(self, playEmote)
    if core:getGameMode() == 'Tutorial' then
        _Callout(self, playEmote)
        return
    end

    local isSneaking = self:isSneaking()
    local stream = getCalloutStream(self, isSneaking, playEmote)
    if not stream then
        return
    end

    -- as of b42, the `callOut` field is no longer just for boredom;
    -- it also determines whether animals are attracted to voices, which is pretty essential
    -- so, we have to disable conversation and call the regular logic

    if self:isAllowConversation() then
        self:setAllowConversation(false)
        _Callout(self, playEmote)
        self:setAllowConversation(true)
    else
        _Callout(self, playEmote)
    end

    API.chat.send {
        stream = stream,
        text = getCalloutText(isSneaking),
        playSignedEmote = not playEmote,
        context = {
            type = 'omichat.callout',
            sneak = isSneaking,
        },
    }
end
