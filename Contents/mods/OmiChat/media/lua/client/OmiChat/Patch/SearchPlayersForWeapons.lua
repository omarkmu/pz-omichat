---@diagnostic disable: undefined-global
---Compatibility patch for Search Players For Weapons.

local API = require 'OmiChat/Client'
local config = API.Configuration

local _getContextOptionText
local _reportBeingSearched

---Gets the text to display in the search player context menu option.
---@param otherPlayer IsoPlayer
---@return string
local function getContextOptionText(otherPlayer)
    if config:compatSearchPlayersEnabled() then
        local name = API.getPlayerMenuName(otherPlayer, 'search_player')
        if name then
            return getText('UI_SearchStub', name)
        end
    end

    if _getContextOptionText then
        return _getContextOptionText(otherPlayer)
    end

    return getText('UI_SearchStub', otherPlayer:getDisplayName())
end

---Reports being searched by another player.
---@param player IsoPlayer
---@param otherPlayer IsoPlayer
local function reportBeingSearched(player, otherPlayer)
    if config:compatSearchPlayersEnabled() then
        local name = API.getNameInChat(otherPlayer:getUsername(), 'say')
        if name then
            player:Say(getText('UI_SearchedBy', name))
            return
        end
    end

    if _reportBeingSearched then
        _reportBeingSearched(player, otherPlayer)
        return
    end

    player:Say(getText('UI_SearchedBy', otherPlayer:getDisplayName()))
end

---Applies the SPFW patch.
local function applyPatch()
    if not SearchPlayer then
        return
    end

    _getContextOptionText = SearchPlayer.getContextOptionText
    SearchPlayer.getContextOptionText = getContextOptionText

    _reportBeingSearched = SearchPlayer.reportBeingSearched
    SearchPlayer.reportBeingSearched = reportBeingSearched
end

Events.OnGameStart.Add(applyPatch)
