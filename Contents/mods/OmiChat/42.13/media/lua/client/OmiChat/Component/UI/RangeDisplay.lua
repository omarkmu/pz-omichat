---UI element for displaying a range.
---@namespace omichat

local API = require 'OmiChat/Module/Client/Core'

local floor = math.floor

local utils = API.utils
local UI = utils.ui

---The number of ticks to display for.
local DISPLAY_TICKS = 70

---@class RangeDisplay : omi.BaseUI
---@field player IsoPlayer The local player.
---@field range integer The range to display.
---@field toCleanup omi.SetTable<IsoObject> Objects to reset the highlight for.
---@field lastPos? [integer, integer, integer] The last player position.
---@field protected tickCount integer The count of render ticks for which the display has been showing.
local RangeDisplay = UI.class('RangeDisplay')

---Hides the display
function RangeDisplay:hide()
    self.tickCount = 0
    self:removeFromUIManager()
    self:_cleanup()
end

---Increases the render tick counter to hide the range display.
function RangeDisplay:render()
    self.tickCount = self.tickCount + 1

    if self.tickCount >= DISPLAY_TICKS then
        self:hide()
        return
    end
end

---Shows the range display with the given range.
---@param range integer
---@param player IsoPlayer?
function RangeDisplay:show(range, player)
    self.range = range
    self.player = player or self.player
    self.lastPos = nil
    self.tickCount = 0
    self:update()
    self:addToUIManager()
end

---Updates the floor objects to highlight based on the player's location.
function RangeDisplay:update()
    local player = self.player
    local range = self.range

    local pX = floor(player:getX())
    local pY = floor(player:getY())
    local pZ = floor(player:getZ())

    if self.lastPos then
        local oldX = self.lastPos[1]
        local oldY = self.lastPos[2]
        local oldZ = self.lastPos[3]

        if oldX == pX and oldY == pY and oldZ == pZ then
            return
        end
    end

    self:_cleanup()
    self.lastPos = { pX, pY, pZ }

    if range == 0 then
        return
    end

    local cell = getCell()
    local rangeSq = range * range
    for x = pX - range, pX + range do
        for y = pY - range, pY + range do
            local dx = x - pX
            local dy = y - pY
            if dx * dx + dy * dy <= rangeSq then
                local sq = cell:getOrCreateGridSquare(x, y, pZ)
                local obj = sq and sq:getFloor()
                if obj then
                    obj:setHighlighted(0, true, false)
                    obj:setHighlightColor(0, 0.2, 0.2, 0.6, 0.5)
                    self.toCleanup[obj] = true
                end
            end
        end
    end
end


---Resets highlight state for highlighted objects.
---@protected
function RangeDisplay:_cleanup()
    for obj in pairs(self.toCleanup) do
        obj:setHighlighted(0, false, false)
    end

    self.toCleanup = {}
end


---Creates a new range display element.
---@param player IsoPlayer The local player.
---@return RangeDisplay element
function RangeDisplay:new(player)
    local this = UI.new(self, RangeDisplay.__base.new, 0, 0, 0, 0)

    this.range = 0
    this.tickCount = 0
    this.toCleanup = {}
    this.player = player

    return this
end


return RangeDisplay
