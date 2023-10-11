---Handles IsoPlayer overrides.

local OmiChat = require 'OmiChat/API/Client'

local min = math.min
local Option = OmiChat.Option
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
    local range = isSneaking and Option.RangeSneakCalloutZombies or Option.RangeCalloutZombies

    local shouts
    if isSneaking and Option.EnableCustomSneakShouts then
        shouts = OmiChat.getCustomShouts('sneakcallouts')
    elseif not isSneaking and Option.EnableCustomShouts then
        shouts = OmiChat.getCustomShouts('callouts')
    end

    -- this can't set .callOut, so minor boredom reduction will occur from shouting
    -- already possible to use chat for that purpose, so this isn't really problematic
    addSound(self, self:getX(), self:getY(), self:getY(), range, range)

    local shoutMax
    if not shouts or #shouts == 0 then
        shouts = getDefaultShouts(isSneaking)
        shoutMax = #shouts
    else
        shoutMax = Option.MaximumCustomShouts > 0 and min(#shouts, Option.MaximumCustomShouts) or #shouts
    end

    local formatter
    local shout = shouts[ZombRand(1, shoutMax + 1)]
    if isSneaking then
        formatter = OmiChat.getFormatter('sneakcallout')
        shout = shout:lower()
    else
        formatter = OmiChat.getFormatter('callout')
        shout = shout:upper()
    end

    processShoutMessage(formatter:format(shout))

    if playEmote then
        self:playEmote('shout')
    end
end
