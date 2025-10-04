---Contains callbacks for chat UI controls.
---@diagnostic disable: unused-local

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client

local utils = API.utils
local config = API.Configuration
local UI = API.utils.ui
local getText = getText
local max = math.max
local BloodBodyPartType = BloodBodyPartType
local getCoveredParts = BloodClothingType.getCoveredParts
local ISChat = ISChat ---@cast ISChat omichat.ISChat
local textManager = getTextManager()


---@class omichat.api.client.callbacks
local Callback = {}


---Callback for the clean character customization option.
---@param target omichat.ISChat
function Callback.cleanCharacter(target)
    local player = getSpecificPlayer(0)
    local visual = player and player:getHumanVisual()
    if not visual then
        return
    end

    if config:isCleanBodyEnabled() then
        for i = 0, BloodBodyPartType.MAX:index() - 1 do
            local bodyPart = BloodBodyPartType.FromIndex(i)
            visual:setDirt(bodyPart, 0)
            visual:setBlood(bodyPart, 0)
        end
    end

    local shouldUpdateClothing = config:isCleanClothingEnabled()
    if shouldUpdateClothing then
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

                item:setDirtyness(0)
                item:setBloodLevel(0)
            end
        end
    end

    player:resetModel()
    sendVisual(player)

    if shouldUpdateClothing then
        sendClothing(player)
        triggerEvent('OnClothingUpdated', player)
    end
end

---Callback for the grow beard customization option.
---@param target omichat.ISChat
function Callback.growBeard(target)
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    ISTimedActionQueue.add(ISTrimBeard:new(player, 'Long', nil, 1))
end

---Callback for the grow hair customization option.
---@param target omichat.ISChat
function Callback.growHair(target)
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local hairStyle = player:isFemale() and 'Long2' or 'Fabian'
    ISTimedActionQueue.add(ISCutHair:new(player, hairStyle, nil, 1))
end

---Callback for confirming adding a roleplay language.
---@param target omichat.ISChat
---@param button ISButton
---@param language string
function Callback.onConfirmAddLanguage(target, button, language)
    if button.internal ~= 'YES' then
        return
    end

    API.player.addLanguage(language)
end

---Callback for hair color menu selection.
---@param target omichat.ISChat
---@param args omi.ui.Args.ColorDialog.Click
function Callback.onHairColorMenuClick(target, args)
    if args.internal ~= 'OK' then
        return
    end

    local player = getSpecificPlayer(0)
    local visual = player and player:getHumanVisual()
    if not visual then
        return
    end

    local hairColor
    local color = args.button.parent:getColor()
    if color then
        hairColor = ImmutableColor.new(color.r / 255, color.g / 255, color.b / 255, 1)
    else
        hairColor = visual:getNaturalHairColor()
    end

    visual:setHairColor(hairColor)
    visual:setBeardColor(hairColor)

    player:resetModel()
    sendVisual(player)
end

---Callback for clicking the update configuration admin context option.
---@param target omichat.ISChat
function Callback.openConfiguration(target)
    if target.activeConfigurationPanel then
        target.activeConfigurationPanel:destroy()
    end

    local x, y = UI.getScreenCenter(800, 600)
    local generator = config:getSchema():getFormGenerator()
    local panel = generator:generate {
        x = x,
        y = y,
        w = 800,
        h = 600,
        values = config:getValuesForSave(),
        onSave = Callback.onConfigurationSave,
    }

    panel:initialise()
    panel:addToUIManager()
    target.activeConfigurationPanel = panel
end

---Callback for hair color customization menu initialization.
---@param target omichat.ISChat
function Callback.openHairColorDialog(target)
    local player = getSpecificPlayer(0)
    local visual = player and player:getHumanVisual()
    if not visual then
        return
    end

    if target.activeColorModal then
        target.activeColorModal:destroy()
    end

    local currentHairColor = visual:getHairColor()
    local naturalHairColor = visual:getNaturalHairColor()
    local color = {
        r = currentHairColor:getRedInt(),
        g = currentHairColor:getGreenInt(),
        b = currentHairColor:getBlueInt(),
    }
    local emptyColor = {
        r = naturalHairColor:getRedInt(),
        g = naturalHairColor:getGreenInt(),
        b = naturalHairColor:getBlueInt(),
    }

    local text = getText('UI_OmiChat_ContextHairColorDesc')
    target.activeColorModal = UI.colorDialog {
        w = max(450, textManager:MeasureStringX(UIFont.Small, text) + 60),
        h = 250,
        text = text,
        defaultColor = color,
        emptyColor = emptyColor,
        target = target,
        onClick = Callback.onHairColorMenuClick,
    }
end

---Callback for adding a roleplay language.
---@param target omichat.ISChat
---@param language string
function Callback.openLanguageConfirmation(target, language)
    if target.activeLanguageModal then
        target.activeLanguageModal:destroy()
    end

    target.activeLanguageModal = UI.yesNoDialog {
        text = getText('UI_OmiChat_ContextConfirmAddLanguage', utils.getTranslatedLanguageName(language)),
        target = target,
        onClick = Callback.onConfirmAddLanguage,
        onClickArgs = { language },
    }
end

---Callback for clicking the manage mod data admin context option.
---@param target omichat.ISChat
function Callback.openModDataManager(target)
    if target.activeModDataPanel then
        target.activeModDataPanel:destroy()
    end

    local x, y = UI.getScreenCenter(1200, 650)
    local panel = API.ModDataManager:new(x, y, 1200, 650)
    panel:initialise()
    panel:addToUIManager()

    target.activeModDataPanel = panel
end

---Callback for clicking the manage profiles context option.
---@param target omichat.ISChat
function Callback.openProfileManager(target)
    if target.activeProfilesPanel then
        target.activeProfilesPanel:destroy()
    end

    local x, y = UI.getScreenCenter(800, 600)
    local panel = API.ProfileManager:new(x, y, 800, 600, API.preferences.getProfiles())
    panel:initialise()
    panel:addToUIManager()
    target.activeProfilesPanel = panel
end

---Called when configuration is saved from the editor form.
---@param args omi.forms.Args.Callback.Save
function Callback.onConfigurationSave(args)
    config:load(args.values)
    API.request.updateConfiguration()
end

---Populates the auto-suggest box with relevant suggestions.
---@param target ISChat?
---@param suggestBox omi.ui.SuggestBox
---@param text string?
function Callback.populateSuggestBox(target, suggestBox, text)
    target = target or ISChat.instance
    if not target then
        return
    end

    if not API.preferences.getUseSuggester() then
        suggestBox:setVisible(false)
        return
    end

    text = text or target.textEntry:getInternalText()
    suggestBox:setSuggestions(API.chat.getSuggestions(text))
end

---Callback for selecting the current roleplay language.
---@param target omichat.ISChat
---@param language string
function Callback.switchLanguage(target, language)
    API.player.setCurrentLanguage(language)
end

---Callback for switching a chat profile.
---@param target omichat.ISChat
---@param idx integer
function Callback.switchProfile(target, idx)
    API.preferences.switchProfile(idx)
    API.ui.redraw()
end

---Callback for toggling admin options.
---@param target omichat.ISChat
---@param option omichat.AdminOption
function Callback.toggleAdminOption(target, option)
    local value = API.preferences.getAdminOption(option)
    API.preferences.setAdminOption(option, not value)
end

---Callback for toggling command retaining.
---@param target omichat.ISChat
---@param type omichat.ChatCommandCategory
function Callback.toggleRetainCommand(target, type)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local value = not API.preferences.getRetainCommand(type)
    API.preferences.setRetainCommand(type, value)

    if value then
        -- don't need to clear the last command for enable
        return
    end

    for i = 1, #instance.tabs do
        ---@diagnostic disable-next-line: invisible
        API.chat._checkLastCommand(instance.tabs[i])
    end
end

---Callback for toggling showing name colors.
---@param target omichat.ISChat
function Callback.toggleShowNameColor(target)
    API.preferences.setNameColorsEnabled(not API.preferences.getNameColorsEnabled())
    API.ui.redraw()
end

---Callback for toggling showing typing indicators.
---@param target omichat.ISChat
function Callback.toggleShowTyping(target)
    API.preferences.setShowTyping(not API.preferences.getShowTyping())
    API.ui.updateTypingDisplay()
    API.ui.updateChatPanelSize()
end

---Callback for toggling applying suggestions on Enter.
---@param target omichat.ISChat
function Callback.toggleSuggestOnEnter(target)
    local value = not API.preferences.getSuggestOnEnter()
    API.preferences.setSuggestOnEnter(value)

    if API.ui.suggestBox then
        API.ui.suggestBox.suggestOnEnter = value
    end
end

---Callback for toggling applying suggestions on Tab.
---@param target omichat.ISChat
function Callback.toggleSuggestOnTab(target)
    API.preferences.setSuggestOnTab(not API.preferences.getSuggestOnTab())
end

---Callback for toggling sign language emotes.
---@param target omichat.ISChat
function Callback.toggleUseSignEmotes(target)
    API.preferences.setSignEmotesEnabled(not API.preferences.getSignEmotesEnabled())
end

---Callback for toggling using the auto-suggest box.
---@param target omichat.ISChat
function Callback.toggleUseSuggester(target)
    API.preferences.setUseSuggester(not API.preferences.getUseSuggester())
    API.ui.updateSuggesterComponent()
end


API.callback = Callback
return Callback
