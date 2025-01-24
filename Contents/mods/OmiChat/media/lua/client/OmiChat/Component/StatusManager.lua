local API = require 'OmiChat/API/Client/Core'
local StatusDisplay = require 'OmiChat/Component/StatusDisplay'

local config = API.Configuration
local getPicked = UIManager.getPicked
local getClassFieldVal = getClassFieldVal


---@class omichat.StatusManager : ISUIElement
---@field instance omichat.StatusManager
---@field private _enabled boolean
---@field private _displayByUsername table<string, omichat.StatusDisplay>
local StatusManager = ISUIElement:derive('StatusManager')

StatusManager._enabled = false
StatusManager._displayByUsername = {}


local TILE_FIELD ---@type Field?
local TILE_FIELD_INDEX = 2


---Gets a set of objects the mouse is hovering over.
---This uses the same logic as the name hovering functionality.
---@static
---@return table<IsoMovingObject, boolean>
function StatusManager.getHoveringObjects()
    local square = StatusManager.getPickedSquare()
    if not square then
        return {}
    end

    local hoverSet = {}

    local squareX = square:getX()
    local squareY = square:getY()
    local squareZ = square:getZ()

    local cell = getCell()
    for x = squareX - 1, squareX + 1 do
        for y = squareY - 1, squareY + 1 do
            local checkSquare = cell:getGridSquare(x, y, squareZ)
            local movingObjects = checkSquare and checkSquare:getMovingObjects()

            if movingObjects then
                for i = 0, movingObjects:size() - 1 do
                    local obj = movingObjects:get(i) ---@type IsoMovingObject
                    hoverSet[obj] = true
                end
            end
        end
    end

    return hoverSet
end

---Gets the square of the currently hovered object.
---@static
---@return IsoGridSquare?
function StatusManager.getPickedSquare()
    local picked = getPicked()
    if not picked then
        return
    end

    if not TILE_FIELD then
        TILE_FIELD = getClassField(picked, TILE_FIELD_INDEX)
    end

    local value = getClassFieldVal(picked, TILE_FIELD)
    if not value or type(value) == 'string' then
        return
    end

    ---@cast value IsoObject
    return value:getSquare()
end

---Sets up the status manager instance.
---@static
function StatusManager.init()
    if StatusManager.instance then
        return
    end

    local instance = StatusManager:new()
    instance:initialise()
    instance:addToUIManager()

    StatusManager.instance = instance
end


---Updates status display elements based on mouse hover.
---Called every 100ms.
function StatusManager:update()
    local statusEnabled = config.Commands.Status.Enable
    if not statusEnabled and not self._enabled then
        return
    end

    self._enabled = statusEnabled

    local players = getOnlinePlayers()
    local selfPlayer = getSpecificPlayer(0)
    if not players or not selfPlayer then
        -- for singleplayer debugging
        return
    end

    -- update display cache
    local onlineSet = {}
    local displayCache = StatusManager._displayByUsername
    for i = 0, players:size() - 1 do
        local onlinePlayer = players:get(i) ---@type IsoPlayer
        local username = onlinePlayer:getUsername()

        onlineSet[onlinePlayer] = true
        if not displayCache[username] then
            local display = StatusDisplay:new(onlinePlayer)
            display:initialise()
            display:addToUIManager()

            displayCache[username] = display
        end
    end

    local toRemove = {}
    local hoverSet = self.getHoveringObjects()
    for username, display in pairs(displayCache) do
        local onlinePlayer = display.target
        display.mouseOver = hoverSet[onlinePlayer] == true

        if not statusEnabled or not onlineSet[onlinePlayer] then
            -- player is unavailable or feature is disabled; remove the display
            toRemove[#toRemove + 1] = username
        end
    end

    for i = 1, #toRemove do
        local username = toRemove[i]
        displayCache[username]:destroy()
        displayCache[username] = nil
    end
end


---Creates a new status manager.
---@return omichat.StatusManager
function StatusManager:new()
    local this = ISUIElement.new(self, 0, 0, 0, 0) ---@cast this omichat.StatusManager
    return this
end


return StatusManager
