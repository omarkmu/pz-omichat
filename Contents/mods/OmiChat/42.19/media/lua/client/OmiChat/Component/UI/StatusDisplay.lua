---UI element for displaying text set with `/status`.
---@namespace omichat

local API = require 'OmiChat/Module/Core/Client'

local utils = API.utils
local UI = utils.ui
local isoToScreenX = isoToScreenX
local isoToScreenY = isoToScreenY
local core = getCore()
local tileScale = Core.getTileScale()


---@class StatusDisplay : omi.BaseUI
---@field target IsoPlayer The player to display the status over.
---@field mouseOver boolean Flag for whether the mouse is over the player.
---@field protected text? string The text of the display.
---@field protected font UIFont The font to use for the display.
---@field protected targetUsername string The username of the target player.
---@field protected drawObject TextDrawObject The draw object used to render the text.
local StatusDisplay = UI.class('StatusDisplay')


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
    if not text then
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

---Determines whether the display should be visible.
---@param player IsoPlayer The local player.
---@param range number The display range.
---@return boolean shouldShow
function StatusDisplay:shouldShow(player, range)
    if not self.text then
        return false
    end

    local target = self.target
    if not target then
        return false
    end

    if target == player or player:canSeeAll() then
        return true
    end

    if target:isInvisible() and not player:isInvisible() then
        return false
    end

    if not API.player.isWithinRange(range, target, player) then
        return false
    end

    local square = target:getCurrentSquare()
    if not square or not square:getCanSee(0) then
        return false
    end

    return true
end

---Updates the status text with the latest status.
function StatusDisplay:update()
    local oldText = self.text
    self.text = API.data.getStatus(self.targetUsername)

    local text = self.text or ''
    if self.text ~= oldText then
        self.drawObject:ReadString(text)
    end
end


---Creates a new status display element.
---@param target IsoPlayer The player to display the status over.
---@return StatusDisplay element
function StatusDisplay:new(target)
    local this = UI.new(self, StatusDisplay.__base.new, 0, 0, 0, 0)

    this.font = UIFont.Small
    this.target = target
    this.targetUsername = target:getUsername()
    this.text = API.data.getStatus(this.targetUsername)

    return this
end


return StatusDisplay
