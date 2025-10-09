---UI element for displaying `/status` text.

local API = require 'OmiChat/Module/Client/Core'

local config = API.Configuration
local utils = API.utils
local UI = utils.ui
local isoToScreenX = isoToScreenX
local isoToScreenY = isoToScreenY
local core = getCore()
local tileScale = Core.getTileScale()


---@class omichat.StatusDisplay : omi.ui.Base
local StatusDisplay = UI.class('OmiStatusDisplay')

---Initializes the display element.
function StatusDisplay:initialise()
    StatusDisplay.__base.initialise(self)
    self:setFollowGameWorld(true)

    local drawObject = TextDrawObject.new()
    drawObject:setDefaultFont(self.font)
    drawObject:setAllowLineBreaks(false)
    drawObject:setSettings(false, false, false, false, false, false)

    drawObject:ReadString(self.text or '')
    self.drawObject = drawObject
end

---Renders the status of the character.
function StatusDisplay:render()
    local text = self.text
    if self.shouldHide or not text then
        return
    end

    -- necessary to check position every render for smooth display
    local target = self.target
    local targetX = target:getX()
    local targetY = target:getY()
    local targetZ = target:getZ()
    local zoom = core:getZoom(0)

    local x = isoToScreenX(0, targetX, targetY, targetZ)
    local y = isoToScreenY(0, targetX, targetY, targetZ)

    y = y - (64 * tileScale) / zoom -- 128 / (2 / tileScale) → 64 * tileScale

    self.drawObject:Draw(x, y, true)
end

---Updates the status text with the latest status.
function StatusDisplay:update()
    self.text = API.data.getStatus(self.targetUsername)

    local text = self.text or ''
    if text ~= self.drawObject:getOriginal() then
        self.drawObject:ReadString(text)
    end

    self.shouldHide = self:_getShouldHide()
end

---Determines whether the display should be hidden.
---@protected
function StatusDisplay:_getShouldHide()
    if not self.mouseOver then
        return true
    end

    local target = self.target
    local player = getSpecificPlayer(0)

    if not target or not player then
        return true
    end

    if target == player or player:isCanSeeAll() then
        return false
    end

    local range = config.Commands.Status.Range
    if player:getDistanceSq(target) > range * range then
        return true
    end

    if target:isInvisible() and not player:isInvisible() then
        return true
    end

    local square = target:getCurrentSquare()
    return not square or not square:getCanSee(0)
end


---Creates a new status display element.
---@param target IsoPlayer
---@return omichat.StatusDisplay
function StatusDisplay:new(target)
    local this = StatusDisplay.__base.new(self, 0, 0, 0, 0) --[[@as omichat.StatusDisplay]]

    this.font = UIFont.Small
    this.target = target
    this.targetUsername = target:getUsername()
    this.text = API.data.getStatus(this.targetUsername)
    this.mouseOver = false
    this.shouldHide = true

    return this
end


return StatusDisplay
