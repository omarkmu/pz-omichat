---Handles overriding player names shown within in-game menus.
---@diagnostic disable: duplicate-set-field

local OmiChat = require 'OmiChatClient'


---@param player IsoPlayer
---@param menuType 'trade' | 'medical' | 'mini_scoreboard'
---@return string?
local function getMenuName(player, menuType)
    local nameFormat = OmiChat.Option.FormatMenuName
    if not nameFormat or nameFormat == '' then
        return
    end

    local chatName = OmiChat.getNameInChat(player:getUsername(), 'say')
    local tokens = chatName and OmiChat.getPlayerSubstitutions(player)
    if not chatName or not tokens then
        return
    end

    tokens.name = OmiChat.utils.replaceEntities(chatName)
    tokens.menuType = menuType
    local result = OmiChat.utils.interpolate(nameFormat, tokens)

    if result == '' then
        return
    end

    return result
end


--#region Medical

local ISMedicalCheckAction_perform = ISMedicalCheckAction.perform
local ISHealthPanel_update = ISHealthPanel.update

function ISMedicalCheckAction:perform()
    ISMedicalCheckAction_perform(self)

    ---@type ISCollapsableWindow
    local healthWindow = ISMedicalCheckAction.getHealthWindowForPlayer(self.otherPlayer)
    if not healthWindow then
        return
    end

    local name = getMenuName(self.otherPlayer, 'medical')
    if not name then
        return
    end

    healthWindow:setTitle(getText('IGUI_health_playerHealth', name))
end

function ISHealthPanel:update()
    ISHealthPanel_update(self)

    if not self.character or not self.otherPlayer or not self.blockingMessage or not self.parent:getIsVisible() then
        return
    end

    local name = getMenuName(self.character, 'medical')
    if not name then
        return
    end

    self.blockingMessage = getText('IGUI_TradingUI_TooFarAway', name)
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

    local name = getMenuName(requester, 'trade')
    if not name then
        return
    end

    modal.text = getText('IGUI_TradingUI_RequestTrade', name):gsub('\\n', '\n')

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

    local name = getMenuName(instance.otherPlayer, 'trade')
    if not name then
        return
    end

    instance.blockingMessage = getText('IGUI_TradingUI_RefusedTrade', name)
end

---@param player IsoPlayer
---@param item InventoryItem
function ISTradingUI.OtherAddNewItem(player, item)
    ISTradingUI_OtherAddNewItem(player, item)

    local instance = ISTradingUI.instance
    if not instance or not instance:isVisible() or not instance.historyMessage then
        return
    end

    local name = getMenuName(player, 'trade')
    if not name then
        return
    end

    local message = getText('IGUI_TradingUI_AddedItem', name, item:getName())
    updateHistoryMessage(message, {
        message = message,
        add = true,
        remove = false,
    })
end

---@param player IsoPlayer
---@param index integer
function ISTradingUI.RemoveItem(player, index)
    local removed = ISTradingUI.instance.hisOfferDatas.items[index]
    ISTradingUI_RemoveItem(player, index)

    local instance = ISTradingUI.instance
    if not removed or not removed.item or not instance or not instance:isVisible() or not instance.historyMessage then
        return
    end

    local name = getMenuName(player, 'trade')
    if not name then
        return
    end

    local message = getText('IGUI_TradingUI_RemovedItem', name, removed.item:getName())
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

    local name = getMenuName(instance.otherPlayer, 'trade')
    if not name then
        return
    end

    local historyMessage
    if state == ISTradingUI.States.PlayerClosedWindow then
        if wasModalVisible then
            return
        end

        if instance.otherPlayer == player and instance.blockingMessage then
            instance.blockingMessage = getText('IGUI_TradingUI_ClosedTrade', name)
        end
    elseif state == ISTradingUI.States.SealOffer then
        historyMessage = getText('IGUI_TradingUI_OtherPlayerSealedOffer', name)
    elseif state == ISTradingUI.States.UnSealOffer then
        historyMessage = getText('IGUI_TradingUI_OtherPlayerUnSealedOffer', name)
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

    local name = getMenuName(self.otherPlayer, 'trade')
    if not name then
        return
    end

    local player = getPlayerByOnlineID(self.otherPlayer:getOnlineID())
    if not player then
        self.blockingMessage = getText('IGUI_TradingUI_ClosedTrade', name)
    end

    if not self.blockingMessage and (math.abs(player:getX() - self.player:getX()) > 2 or
            math.abs(player:getY() - self.player:getY()) > 2) then
        self.blockingMessage2 = getText('IGUI_TradingUI_TooFarAway', name)
        return
    else
        self.blockingMessage2 = nil
    end
end

function ISTradingUI:prerender()
    local name = getMenuName(self.otherPlayer, 'trade')
    if not name then
        return ISTradingUI_prerender(self)
    end

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawText(getText('IGUI_TradingUI_Title'), self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, getText('IGUI_TradingUI_Title')) / 2), 15, 1, 1, 1, 1, UIFont.Medium)
    self:drawText(getText('IGUI_TradingUI_YourOffer'), self.yourOfferDatas.x, self.yourOfferDatas.y - 32, 1, 1, 1, 1, UIFont.Small)
    self:drawText(getText('IGUI_TradingUI_HisOffer', name), self.hisOfferDatas.x, self.hisOfferDatas.y - 32, 1, 1, 1, 1, UIFont.Small)

    local yourItems = getText('IGUI_TradingUI_Items', #self.yourOfferDatas.items, ISTradingUI.MaxItems)
    local hisItems = getText('IGUI_TradingUI_Items', #self.hisOfferDatas.items, ISTradingUI.MaxItems)
    self:drawText(yourItems, self.yourOfferDatas.x, self.yourOfferDatas.y - 20, 1, 1, 1, 1, UIFont.Small)
    self:drawText(hisItems, self.hisOfferDatas.x, self.hisOfferDatas.y - 20, 1, 1, 1, 1, UIFont.Small)

    if self.otherSealedOffer then
        self:drawText(getText('IGUI_TradingUI_OtherPlayerSealedOffer', name), self.sealOffer.x, self.sealOffer.y + self.sealOffer.height + 5, 0.2, 1, 0.2, 1, UIFont.Small)
    end
end

function ISTradingUIHistorical:prerender()
    local name = getMenuName(self.otherPlayer, 'trade')
    if not name then
        return ISTradingUIHistorical_prerender(self)
    end

    local title = getText('IGUI_ISTradingUIHistorical_Title', name)
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawText(title, self.width/2 - (getTextManager():MeasureStringX(UIFont.Medium, title) / 2), 10, 1, 1, 1, 1, UIFont.Medium)
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

    local name = getMenuName(otherPlayer, 'trade')
    if not name then
        return
    end

    instance.blockingMessage = getText('IGUI_TradingUI_WaitingAnswer', name)
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
        local username = item.text
        if item.tooltip then
            username = item.tooltip
        end

        local player = getPlayerFromUsername(username)
        local name = player and getMenuName(player, 'mini_scoreboard')
        if name then
            item.text = name
            if name ~= username then
                item.tooltip = username
            end
        end
    end
end

--#endregion

--#region Context Menu

---@param context ISContextMenu
local function onContextMenu(_, context)
    for i = 1, #context.options do
        local opt = context.options[i]

        local player = opt.param2
        local isParamPlayer = instanceof(player, 'IsoPlayer')
        if isParamPlayer and opt.onSelect == ISWorldObjectContextMenu.onTrade then
            local name = getMenuName(player, 'trade')
            if name then
                opt.name = getText('ContextMenu_Trade', name)

                if opt.toolTip and opt.notAvailable then
                    opt.toolTip.description = getText('ContextMenu_GetCloserToTrade', name)
                end
            end
        elseif isParamPlayer and opt.onSelect == ISWorldObjectContextMenu.onMedicalCheck then
            local name = opt.toolTip and opt.notAvailable and getMenuName(player, 'medical')
            if name then
                opt.toolTip.description = getText('ContextMenu_GetCloser', name)
            end
        end
    end
end


Events.OnFillWorldObjectContextMenu.Add(onContextMenu)

--#endregion