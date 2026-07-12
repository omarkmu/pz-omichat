---Handles player customization options.
---@namespace omichat

if isClient() then return end

---@class(partial) api.server
local API = require 'OmiChat/Module/Core/Server'
local config = API.Configuration

local BloodBodyPartType = BloodBodyPartType
local getCoveredParts = BloodClothingType.getCoveredParts

---@class api.server.customization
local Customization = {}

---Contains functions for applying player customization.
API.customization = Customization


---Cleans a character.
---This cleans the body and/or clothing depending on configuration.
---@param player IsoPlayer
function Customization.cleanCharacter(player)
    local cleanBody = config:isCleanBodyEnabled()
    local cleanClothing = config:isCleanClothingEnabled()
    if not cleanBody and not cleanClothing then
        return
    end

    local visual = player:getHumanVisual()
    if cleanBody then
        for i = 0, BloodBodyPartType.MAX:index() - 1 do
            local bodyPart = BloodBodyPartType.FromIndex(i)
            visual:setDirt(bodyPart, 0)
            visual:setBlood(bodyPart, 0)
        end
    end

    if cleanClothing then
        local items = player:getWornItems()
        for i = 0, items:size() - 1 do
            local item = items:getItemByIndex(i)
            local itemVisual = item and instanceof(item, 'Clothing') and item:getVisual()
            if itemVisual then
                ---@cast item Clothing
                local parts = getCoveredParts(item:getBloodClothingType())

                for j = 0, parts:size() - 1 do
                    local part = parts:get(j)
                    itemVisual:setDirt(part, 0)
                    itemVisual:setBlood(part, 0)
                end

                item:setDirtiness(0)
                item:setBloodLevel(0)
                syncItemFields(player, item)
            end
        end
    end

    player:resetModel()

    if cleanBody then
        sendHumanVisual(player)
    end

    if cleanClothing then
        syncVisuals(player)
    end
end

---Grows a player's beard.
---@param player IsoPlayer
function Customization.growBeard(player)
    if player:isFemale() then
        return
    end

    player:getHumanVisual():setBeardModel('Long')
    sendHumanVisual(player)
end

---Grows a player's hair.
---@param player IsoPlayer
function Customization.growHair(player)
    local visual = player:getHumanVisual()
    local style = player:isFemale() and 'Long2' or 'Fabian'

    visual:setNonAttachedHair(nil --[[@as any]])
    visual:setHairModel(style)

    player:resetModel()
    player:resetHairGrowingTime()

    sendHumanVisual(player)
end

---Sets a player's hair color.
---@param player IsoPlayer
---@param color omi.ColorTable<integer>? The hair color to set. Defaults to the player's natural hair color.
function Customization.setHairColor(player, color)
    local visual = player:getHumanVisual()

    local hairColor
    if color then
        hairColor = ImmutableColor.new(color.r / 255, color.g / 255, color.b / 255, 1)
    else
        hairColor = visual:getNaturalHairColor()
    end

    visual:setHairColor(hairColor)
    visual:setBeardColor(hairColor)

    player:resetModel()
    sendHumanVisual(player)
end


return Customization
