---Handles IsoPlayer overrides.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'
local utils = API.utils
local config = API.Configuration
local core = getCore()

local min = math.min
local addSound = addSound
local _IsoPlayer = __classmetatables[IsoPlayer.class].__index
local _Callout = _IsoPlayer.Callout


---Override to enable custom callouts.
---@param playEmote boolean
function _IsoPlayer:Callout(playEmote)
    if core:getGameMode() == 'Tutorial' then
        _Callout(self, playEmote)
        return
    end

    local isSneaking = self:isSneaking()

    local stream
    if isSneaking then
        stream = API.streams.firstChatStreamWithTag('SneakCallout')
    end

    stream = stream
        or API.streams.firstChatStreamWithTag('Callout')
        or API.streams.getChatStream('yell', { enabledOnly = true })

    if not stream then
        utils.log.warn.once('No stream defined for callouts. Add the `Callout` tag to a stream.')
        _Callout(self, playEmote)
        return
    end

    local zombieConfig = config.ZombieAttraction
    local range = isSneaking and zombieConfig.SneakCalloutRange or zombieConfig.CalloutRange

    local shouts = API.preferences.getCustomShouts(isSneaking and 'sneakcallouts' or 'callouts')

    -- this can't set .callOut, so minor boredom reduction will occur from shouting
    -- already possible to use chat for that purpose, so this isn't really problematic
    addSound(self, self:getX(), self:getY(), self:getY(), range, range)

    local shoutMax
    if not shouts or #shouts == 0 then
        shouts = API.player.getDefaultShouts(isSneaking)
        shoutMax = #shouts
    else
        shoutMax = min(#shouts, config.MAX_CUSTOM_SHOUTS)
    end

    local formatterName
    local shout = shouts[utils.randInt(1, shoutMax)] --[[@as string]]
    if isSneaking then
        formatterName = 'sneakCallout'
        shout = shout:lower()
    else
        formatterName = 'callout'
        shout = shout:upper()
    end

    API.chat.send {
        stream = stream,
        text = shout,
        formatter = API.format.get(formatterName),
        playSignedEmote = not playEmote,
        tokens = {
            callout = '1',
            sneakCallout = isSneaking and '1' or nil,
        },
        extraTags = {
            'IsCallout',
            isSneaking and 'IsSneakCallout' or nil,
        },
    }

    if playEmote then
        self:playEmote('shout')
    end
end
