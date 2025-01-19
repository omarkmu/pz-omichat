---Handles IsoPlayer overrides.

local API = require 'OmiChat/API/Client/Core'
local config = API.Configuration

local min = math.min
local _IsoPlayer = __classmetatables[IsoPlayer.class].__index
local _Callout = _IsoPlayer.Callout


---Returns the default shouts to use when shouts are not customized.
---@param isSneaking boolean
---@return string[]
local function getDefaultShouts(isSneaking)
    local result = {}

    for i = 1, 3 do
        result[#result + 1] = getText('IGUI_PlayerText_Callout' .. i .. (isSneaking and 'Sneak' or 'New'))
    end

    return result
end


---Override to enable custom callouts.
---@param playEmote boolean
function _IsoPlayer:Callout(playEmote)
    if getCore():getGameMode() == 'Tutorial' then
        _Callout(self, playEmote)
        return
    end

    local isSneaking = self:isSneaking()

    local stream
    if isSneaking then
        stream = API.getFirstChatStreamWithTag('SneakCallout')
    end

    stream = stream or API.getFirstChatStreamWithTag('Callout') or API.getStreamByName('yell')
    if not stream then
        API.utils.log.once('No stream defined for callouts. Add the `Callout` tag to a stream.')
        _Callout(self, playEmote)
        return
    end

    local zombieConfig = config.ZombieAttraction
    local range = isSneaking and zombieConfig.SneakCalloutRange or zombieConfig.CalloutRange

    local shouts
    if config:isCustomShoutsEnabled() then
        shouts = API.getCustomShouts(isSneaking and 'sneakcallouts' or 'callouts')
    end

    -- this can't set .callOut, so minor boredom reduction will occur from shouting
    -- already possible to use chat for that purpose, so this isn't really problematic
    addSound(self, self:getX(), self:getY(), self:getY(), range, range)

    local shoutMax
    if not shouts or #shouts == 0 then
        shouts = getDefaultShouts(isSneaking)
        shoutMax = #shouts
    else
        shoutMax = min(#shouts, config.MAX_CUSTOM_SHOUTS)
    end

    local formatterName
    local shout = shouts[ZombRand(1, shoutMax + 1)]
    if isSneaking then
        formatterName = 'sneakCallout'
        shout = shout:lower()
    else
        formatterName = 'callout'
        shout = shout:upper()
    end

    API.send {
        stream = stream,
        text = shout,
        formatter = API.getFormatter(formatterName),
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
