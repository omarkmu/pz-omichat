---Handles IsoPlayer overrides.

local OmiChat = require 'OmiChat/API/Client'

local Option = OmiChat.Option
local min = math.min
local _IsoPlayer = __classmetatables[IsoPlayer.class].__index
local _Callout = _IsoPlayer.Callout


---Override to enable custom callouts.
---@param playEmote boolean
function _IsoPlayer:Callout(playEmote)
    if getCore():getGameMode() == 'Tutorial' then
        return _Callout(self, playEmote)
    end

    local isSneaking = self:isSneaking()
    local range = isSneaking and 6 or 30

    local shouts
    if isSneaking and Option.EnableCustomSneakShouts then
        shouts = OmiChat.getCustomShouts('sneakcallouts')
    elseif not isSneaking and Option.EnableCustomShouts then
        shouts = OmiChat.getCustomShouts('callouts')
    end

    if not shouts or #shouts == 0 then
        return _Callout(self, playEmote)
    end

    -- this can't set .callOut, so minor boredom reduction will occur from shouting
    -- already possible to use chat for that purpose, so this isn't really problematic
    addSound(self, self:getX(), self:getY(), self:getY(), range, range)

    local shoutMax = Option.MaximumCustomShouts > 0 and min(#shouts, Option.MaximumCustomShouts) or #shouts

    local shout = shouts[ZombRand(1, shoutMax + 1)]
    if isSneaking then
        shout = shout:lower()
    else
        shout = shout:upper()
    end

    processShoutMessage(shout)

    if playEmote then
        self:playEmote('shout')
    end
end
