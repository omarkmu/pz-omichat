---Compatibility patch for Search Players For Weapons.
---@namespace omichat
---@diagnostic disable: undefined-global

local API = require 'OmiChat/Client'
local config = API.Configuration

local getText = getText


---@class patch.SPFW
---@field private _getContextOptionText function? The original `getContextOptionText` function.
---@field private _reportBeingSearched function? The original `reportBeingSearched` function.
local Patch = {}

---Applies the Search Players for Weapons patch.
function Patch.apply()
    if not SearchPlayer then
        return
    end

    Patch._getContextOptionText = SearchPlayer.getContextOptionText
    SearchPlayer.getContextOptionText = Patch.getContextOptionText

    Patch._reportBeingSearched = SearchPlayer.reportBeingSearched
    SearchPlayer.reportBeingSearched = Patch.reportBeingSearched
end

---Gets the text to display in the search player context menu option.
---@param otherPlayer IsoPlayer
---@return string
function Patch.getContextOptionText(otherPlayer)
    if config:compatSearchPlayersEnabled() then
        local name = API.data.getPlayerMenuName(otherPlayer, 'search_player')
        if name then
            return getText('UI_SearchStub', name)
        end
    end

    if Patch._getContextOptionText then
        return Patch._getContextOptionText(otherPlayer)
    end

    return getText('UI_SearchStub', otherPlayer:getDisplayName())
end

---Reports being searched by another player.
---@param player IsoPlayer
---@param otherPlayer IsoPlayer
function Patch.reportBeingSearched(player, otherPlayer)
    if config:compatSearchPlayersEnabled() then
        local name = API.data.getNameInChat(otherPlayer:getUsername(), 'say')
        if name then
            player:Say(getText('UI_SearchedBy', name))
            return
        end
    end

    if Patch._reportBeingSearched then
        Patch._reportBeingSearched(player, otherPlayer)
        return
    end

    player:Say(getText('UI_SearchedBy', otherPlayer:getDisplayName()))
end

Events.OnGameStart.Add(Patch.apply)
return Patch
