---Handles overrides to show chat names within in-game menus.
---@namespace omichat
---@diagnostic disable: duplicate-set-field

local API = require 'OmiChat/Client'
local utils = API.utils
local getTextVanilla = getText
local textManager = getTextManager()


--#region Medical

local ISMedicalCheckAction_perform = ISMedicalCheckAction.perform
local ISHealthPanel_update = ISHealthPanel.update

function ISMedicalCheckAction:perform()
    ISMedicalCheckAction_perform(self)

    local healthWindow = ISMedicalCheckAction.getHealthWindowForPlayer(self.otherPlayer)
    if not healthWindow then
        return
    end

    local name = API.data.getPlayerMenuName(self.otherPlayer, 'medical')
    if not name then
        return
    end

    healthWindow:setTitle(getTextVanilla('IGUI_health_playerHealth', name))
end

function ISHealthPanel:update()
    ISHealthPanel_update(self)

    if not self.character or not self.otherPlayer or not self.blockingMessage then
        return
    end

    if not self.parent or not self.parent:getIsVisible() then
        return
    end

    local name = API.data.getPlayerMenuName(self.character, 'medical')
    if not name then
        return
    end

    self.blockingMessage = getTextVanilla('IGUI_TradingUI_TooFarAway', name)
end

--#endregion

--#region Trading

local ISTradingUI_ReceiveTradeRequest = ISTradingUI.ReceiveTradeRequest
local ISTradingUI_AcceptedTrade = ISTradingUI.AcceptedTrade
local ISTradingUI_OtherAddNewItem = ISTradingUI.OtherAddNewItem
local ISTradingUI_RemoveItem = ISTradingUI.RemoveItem
local ISTradingUI_UpdateState = ISTradingUI.UpdateState
local ISTradingUI_update = ISTradingUI.update
local ISTradingUI_prerender = ISTradingUI.prerender
local ISTradingUIHistorical_prerender = ISTradingUIHistorical.prerender
local ISWorldObjectContextMenu_onTrade = ISWorldObjectContextMenu.onTrade

---@param message string
---@param messageRecord table?
local function updateHistoryMessage(message, messageRecord)
    local instance = ISTradingUI.instance
    if not instance then
        return
    end

    instance.historyMessage = message

    if not messageRecord then
        return
    end

    instance.historical[#instance.historical] = messageRecord
    if instance.historicalUI and instance.historicalUI:isVisible() then
        instance.historicalUI:populateList(instance.historical)
    end
end


---@param requester IsoPlayer
function ISTradingUI.ReceiveTradeRequest(requester)
    ISTradingUI_ReceiveTradeRequest(requester)

    local modal = ISTradingUI.tradeQuestionUI
    if not modal then
        return
    end

    local name = API.data.getPlayerMenuName(requester, 'trade')
    if not name then
        return
    end

    modal.text = getTextVanilla('IGUI_TradingUI_RequestTrade', name):gsub('\\n', '\n')

    local w, h = ISModalDialog.CalcSize(modal.width, modal.height, modal.text)
    modal.width = w
    modal.height = h
end

---@param accepted boolean
function ISTradingUI.AcceptedTrade(accepted)
    ISTradingUI_AcceptedTrade(accepted)

    local instance = ISTradingUI.instance
    if accepted or not instance or not instance.blockingMessage then
        return
    end

    local name = API.data.getPlayerMenuName(instance.otherPlayer, 'trade')
    if not name then
        return
    end

    instance.blockingMessage = getTextVanilla('IGUI_TradingUI_RefusedTrade', name)
end

---@param player IsoPlayer
---@param item InventoryItem
function ISTradingUI.OtherAddNewItem(player, item)
    ISTradingUI_OtherAddNewItem(player, item)

    local instance = ISTradingUI.instance
    if not instance or not instance:isVisible() or not instance.historyMessage then
        return
    end

    local name = API.data.getPlayerMenuName(player, 'trade')
    if not name then
        return
    end

    local message = getTextVanilla('IGUI_TradingUI_AddedItem', name, item:getName())
    updateHistoryMessage(message, {
        message = message,
        add = true,
        remove = false,
    })
end

---@param player IsoPlayer
---@param index integer
function ISTradingUI.RemoveItem(player, index)
    if not ISTradingUI.instance then
        return
    end

    local removed = ISTradingUI.instance.hisOfferDatas.items[index]
    ISTradingUI_RemoveItem(player, index)

    local instance = ISTradingUI.instance
    if not removed or not removed.item or not instance or not instance:isVisible() or not instance.historyMessage then
        return
    end

    local name = API.data.getPlayerMenuName(player, 'trade')
    if not name then
        return
    end

    local message = getTextVanilla('IGUI_TradingUI_RemovedItem', name, removed.item:getName())
    updateHistoryMessage(message, {
        message = message,
        add = false,
        remove = true,
    })
end

---@param player IsoPlayer
---@param state integer
function ISTradingUI.UpdateState(player, state)
    local wasModalVisible = ISTradingUI.tradeQuestionUI and ISTradingUI.tradeQuestionUI:isVisible()
    ISTradingUI_UpdateState(player, state)

    local instance = ISTradingUI.instance
    if not instance or not instance:isVisible() then
        return
    end

    local name = API.data.getPlayerMenuName(instance.otherPlayer, 'trade')
    if not name then
        return
    end

    local historyMessage
    if state == ISTradingUI.States.PlayerClosedWindow then
        if wasModalVisible then
            return
        end

        if instance.otherPlayer == player and instance.blockingMessage then
            instance.blockingMessage = getTextVanilla('IGUI_TradingUI_ClosedTrade', name)
        end
    elseif state == ISTradingUI.States.SealOffer then
        historyMessage = getTextVanilla('IGUI_TradingUI_OtherPlayerSealedOffer', name)
    elseif state == ISTradingUI.States.UnSealOffer then
        historyMessage = getTextVanilla('IGUI_TradingUI_OtherPlayerUnSealedOffer', name)
    end

    if historyMessage then
        updateHistoryMessage(historyMessage, {
            message = historyMessage,
            add = false,
            remove = false,
        })
    end
end

function ISTradingUI:update()
    ISTradingUI_update(self)

    local name = API.data.getPlayerMenuName(self.otherPlayer, 'trade')
    if not name then
        return
    end

    local player = getPlayerByOnlineID(self.otherPlayer:getOnlineID())
    if not player then
        self.blockingMessage = getTextVanilla('IGUI_TradingUI_ClosedTrade', name)
    end

    if not self.blockingMessage and (math.abs(player:getX() - self.player:getX()) > 2 or
            math.abs(player:getY() - self.player:getY()) > 2) then
        self.blockingMessage2 = getTextVanilla('IGUI_TradingUI_TooFarAway', name)
        return
    else
        self.blockingMessage2 = nil
    end
end

function ISTradingUI:prerender()
    local name = API.data.getPlayerMenuName(self.otherPlayer, 'trade')
    if not name then
        return ISTradingUI_prerender(self)
    end

    local bgColor = self.backgroundColor
    local offer = self.yourOfferDatas
    local hisOffer = self.hisOfferDatas
    local title = getTextVanilla('IGUI_TradingUI_Title')
    local titleX = self.width / 2 - (textManager:MeasureStringX(UIFont.Medium, title) / 2)

    self:drawRect(0, 0, self.width, self.height, bgColor.a, bgColor.r, bgColor.g, bgColor.b)
    self:drawText(title, titleX, 15, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(getTextVanilla('IGUI_TradingUI_YourOffer'), offer.x, offer.y - 32, 1, 1, 1, 1, UIFont.Small)
    self:drawText(getTextVanilla('IGUI_TradingUI_HisOffer', name), hisOffer.x, hisOffer.y - 32, 1, 1, 1, 1, UIFont.Small)

    local yourItems = getTextVanilla('IGUI_TradingUI_Items', #offer.items, ISTradingUI.MaxItems)
    local hisItems = getTextVanilla('IGUI_TradingUI_Items', #hisOffer.items, ISTradingUI.MaxItems)
    self:drawText(yourItems, offer.x, offer.y - 20, 1, 1, 1, 1, UIFont.Small)
    self:drawText(hisItems, hisOffer.x, hisOffer.y - 20, 1, 1, 1, 1, UIFont.Small)

    if self.otherSealedOffer then
        local text = getTextVanilla('IGUI_TradingUI_OtherPlayerSealedOffer', name)
        self:drawText(text, self.sealOffer.x, self.sealOffer.y + self.sealOffer.height + 5, 0.2, 1, 0.2, 1, UIFont.Small)
    end
end

function ISTradingUIHistorical:prerender()
    local name = API.data.getPlayerMenuName(self.otherPlayer, 'trade')
    if not name then
        return ISTradingUIHistorical_prerender(self)
    end

    local bgColor = self.backgroundColor
    local borderColor = self.borderColor
    local title = getTextVanilla('IGUI_ISTradingUIHistorical_Title', name)
    local titleX = self.width / 2 - (textManager:MeasureStringX(UIFont.Medium, title) / 2)

    self:drawRect(0, 0, self.width, self.height, bgColor.a, bgColor.r, bgColor.g, bgColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, borderColor.a, borderColor.r, borderColor.g, borderColor.b)
    self:drawText(title, titleX, 10, 1, 1, 1, 1, UIFont.Medium)
end

---@param worldobjects table
---@param player IsoPlayer
---@param otherPlayer IsoPlayer
function ISWorldObjectContextMenu.onTrade(worldobjects, player, otherPlayer)
    ISWorldObjectContextMenu_onTrade(worldobjects, player, otherPlayer)

    local instance = ISTradingUI.instance
    if not instance or not instance.blockingMessage then
        return
    end

    local name = API.data.getPlayerMenuName(otherPlayer, 'trade')
    if not name then
        return
    end

    instance.blockingMessage = getTextVanilla('IGUI_TradingUI_WaitingAnswer', name)
end


Events.RequestTrade.Remove(ISTradingUI_ReceiveTradeRequest)
Events.AcceptedTrade.Remove(ISTradingUI_AcceptedTrade)
Events.TradingUIAddItem.Remove(ISTradingUI_OtherAddNewItem)
Events.TradingUIRemoveItem.Remove(ISTradingUI_RemoveItem)
Events.TradingUIUpdateState.Remove(ISTradingUI_UpdateState)

Events.RequestTrade.Add(ISTradingUI.ReceiveTradeRequest)
Events.AcceptedTrade.Add(ISTradingUI.AcceptedTrade)
Events.TradingUIAddItem.Add(ISTradingUI.OtherAddNewItem)
Events.TradingUIRemoveItem.Add(ISTradingUI.RemoveItem)
Events.TradingUIUpdateState.Add(ISTradingUI.UpdateState)

--#endregion

--#region Mini Scoreboard

local ISMiniScoreboardUI_populateList = ISMiniScoreboardUI.populateList

function ISMiniScoreboardUI:populateList()
    ISMiniScoreboardUI_populateList(self)

    if not self.playerList then
        return
    end

    for i = 1, #self.playerList.items do
        local item = self.playerList.items[i]
        local username = item.item and item.item.username ---@type string?

        local player = username and API.data.getPlayerInfoByUsername(username)
        local name = player and API.data.getPlayerMenuName(player, 'mini_scoreboard')
        if player and name then
            item.text = name
            local forename = utils.trim(player.forename or '')
            local surname = utils.trim(player.surname or '')
            local chatName = API.data.getPlayerNameInChat(player, 'say') or ''

            local details = {
                'Username: ',
                username,
            }

            if chatName ~= '' then
                details[#details + 1] = '\nChat Name: '
                details[#details + 1] = chatName
            end

            if forename ~= '' then
                details[#details + 1] = '\nForename: '
                details[#details + 1] = forename
            end

            if surname ~= '' then
                details[#details + 1] = '\nSurname: '
                details[#details + 1] = surname
            end

            item.tooltip = table.concat(details)
        end
    end
end

--#endregion

--#region Context Menu

local ISWorldObjectContextMenu_createMenu = ISWorldObjectContextMenu.createMenu

---Modifies a context menu option if it matches one of the known options that uses the player name.
---@param opt table
local function handleContextMenuOption(opt)
    local otherPlayer = opt.param2
    if not otherPlayer or not instanceof(otherPlayer, 'IsoPlayer') then
        return
    end

    local onSelect = opt.onSelect
    if onSelect == ISWorldObjectContextMenu.onTrade then
        local name = API.data.getPlayerMenuName(otherPlayer, 'trade')
        if not name then
            return
        end

        opt.name = getTextVanilla('ContextMenu_Trade', name)
        if opt.toolTip and opt.notAvailable then
            opt.toolTip.description = getTextVanilla('ContextMenu_GetCloserToTrade', name)
        end
    elseif onSelect == ISWorldObjectContextMenu.onMedicalCheck then
        local name = opt.toolTip and opt.notAvailable and API.data.getPlayerMenuName(otherPlayer, 'medical')
        if name then
            opt.toolTip.description = getTextVanilla('ContextMenu_GetCloser', name)
        end
    end
end

---Override to createMenu to ensure our handling occurs after all event handlers have run.
---@param ...any
---@return any
function ISWorldObjectContextMenu.createMenu(...)
    local context = ISWorldObjectContextMenu_createMenu(...) --[[@as ISContextMenu]]
    if type(context) ~= 'table' or not context.options then
        return context
    end

    for i = 1, #context.options do
        handleContextMenuOption(context.options[i])
    end

    return context
end

--#endregion
