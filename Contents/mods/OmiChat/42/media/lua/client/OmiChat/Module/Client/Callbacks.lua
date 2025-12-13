---Contains callbacks for UI controls.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration
local UI = utils.ui
local ISChat = ISChat --[[@as omichat.ISChat]]

local max = math.max
local getAttr = utils.getAttr
local textManager = getTextManager()


---@class api.client.callbacks
local Callback = {}

---Contains callbacks for UI controls.
API.callback = Callback

---Counter for skipping info panel updates.
---@private
Callback._infoUpdateCounter = 0


---Callback for adding a roleplay language.
---@param _ ISChat Unused.
---@param args omi.Args.Dialog.Click Click arguments.
---@param language string The language to add.
function Callback.onConfirmAddLanguage(_, args, language)
    if args.internal == 'YES' then
        API.player.addLanguage(language)
    end
end

---Callback for hair color menu selection.
---@param _ ISChat Unused.
---@param args omi.Args.ColorDialog.Click Click arguments.
function Callback.onHairColorMenuClick(_, args)
    if args.internal == 'OK' then
        API.request.applyCustomization('SET_HAIR_COLOR', { hairColor = args.dialog:getColor() })
    end
end

---Callback for hair color customization menu initialization.
---@param target ISChat The chat instance.
function Callback.openHairColorDialog(target)
    local player = API.player.get()
    local visual = player and player:getHumanVisual()
    if not visual then
        return
    end

    if target.activeColorDialog then
        target.activeColorDialog:destroy()
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

    local text = getAttr('context-hair-color', 'dialog')
    target.activeColorDialog = UI.colorDialog {
        w = max(450, textManager:MeasureStringX(UIFont.Small, text) + 60),
        h = 250,
        text = text,
        defaultColor = color,
        emptyColor = emptyColor,
        target = target,
        onClick = Callback.onHairColorMenuClick,
    }
end

---Called when an action is clicked in the info panel.
---@param _ ISChat Unused.
---@param name string The name of the action.
---@param action omi.RichTextActionType The type of the action.
---@param ...string Additional arguments to pass to the handler.
function Callback.onInfoPanelAction(_, name, action, ...)
    if API.hooks.has.richTextAction then
        API.hooks.richTextAction(name, action, ...)
    end
end

---Called every 100ms while the info text panel is visible.
---Updates info text with the latest token values approximately every second.
---@param target ISChat The chat instance.
function Callback.onInfoPanelUpdate(target)
    local counter = Callback._infoUpdateCounter
    if counter < 9 then
        Callback._infoUpdateCounter = counter + 1
        return
    end

    Callback._infoUpdateCounter = 0
    local text = API.ui.getInfoRichText()
    if text ~= target.infoText then
        target:setInfo(text)
    end
end

---Callback for attempting to add a roleplay language.
---@param target ISChat The chat instance.
---@param language string The language to add.
function Callback.openLanguageConfirmation(target, language)
    if target.activeLanguageDialog then
        target.activeLanguageDialog:destroy()
    end

    target.activeLanguageDialog = UI.yesNoDialog {
        text = getAttr('context-add-language', 'dialog', { language = utils.getTranslatedLanguageName(language) }),
        target = target,
        onClick = Callback.onConfirmAddLanguage,
        onClickArgs = { language },
    }
end

---Called when the configuration menu is closed.
---@param args omi.forms.Args.Callback.Close Callback arguments.
function Callback.onConfigurationClose(args)
    local form = args.form
    for el in pairs(form:getRemoveOnDestroy()) do
        el:removeFromUIManager()
    end

    form:clearRemoveOnDestroy()
end

---Called when configuration is saved from the editor form.
---@param args omi.forms.Args.Callback.Save Callback arguments.
function Callback.onConfigurationSave(args)
    config:load(args.values)
    API.request.updateConfiguration()
end

---Populates the auto-suggest box with relevant suggestions.
---@param target ISChat The chat instance.
---@param suggestBox omi.SuggestBox The suggest box to populate.
---@param text string The search text. Defaults to the chat entry's text.
function Callback.populateChatSuggestBox(target, suggestBox, text)
    if not API.preferences.getUseSuggester() then
        suggestBox:setVisible(false)
        return
    end

    text = text or target.textEntry:getInternalText()
    suggestBox:setSuggestions(API.suggestion.getChatSuggestions(text))
end

---Callback for selecting the current roleplay language.
---@param _ ISChat Unused.
---@param language string The language to switch to.
function Callback.switchLanguage(_, language)
    API.player.setCurrentLanguage(language)
end

---Callback for switching a chat profile.
---@param _ ISChat Unused.
---@param idx integer
function Callback.switchProfile(_, idx)
    API.preferences.switchProfile(idx)
    API.ui.redraw()
end

---Callback for toggling the admin option for ignoring message range.
function Callback.toggleAdminIgnoreRange()
    local value = API.preferences.getIgnoreMessageRange()
    API.preferences.setIgnoreMessageRange(not value)
end

---Callback for toggling the admin option for showing a chat icon.
function Callback.toggleAdminShowIcon()
    local value = API.preferences.getShowAdminIcon()
    API.preferences.setShowAdminIcon(not value)
end

---Callback for toggling the admin option for understanding all languags.
function Callback.toggleAdminUnderstandLanguages()
    local value = API.preferences.getUnderstandAllLanguages()
    API.preferences.setUnderstandAllLanguages(not value)
end

---Callback for toggling command retaining.
---@param _ ISChat Unused.
---@param type StreamCategory The category to toggle.
function Callback.toggleRetainCommand(_, type)
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
        API.chat._checkLastCommand(instance.tabs[i]) ---@diagnostic disable-line: invisible
    end
end

---Callback for toggling showing name colors.
---@param _ ISChat Unused.
function Callback.toggleShowNameColor(_)
    API.preferences.setNameColorsEnabled(not API.preferences.getNameColorsEnabled())
    API.ui.redraw()
end

---Callback for toggling showing typing indicators.
---@param _ ISChat Unused.
function Callback.toggleShowTyping(_)
    API.preferences.setShowTyping(not API.preferences.getShowTyping())
    API.ui.updateTypingDisplay()
    API.ui.updateChatPanelSize()
end

---Callback for toggling applying suggestions on `Enter`.
---@param _ ISChat Unused.
function Callback.toggleSuggestOnEnter(_)
    local value = not API.preferences.getSuggestOnEnter()
    API.preferences.setSuggestOnEnter(value)

    if API.ui.suggestBox then
        API.ui.suggestBox.suggestOnEnter = value
    end
end

---Callback for toggling applying suggestions on `Tab`.
---@param _ ISChat Unused.
function Callback.toggleSuggestOnTab(_)
    API.preferences.setSuggestOnTab(not API.preferences.getSuggestOnTab())
end

---Callback for toggling sign language emotes.
---@param _ ISChat Unused.
function Callback.toggleUseSignEmotes(_)
    API.preferences.setSignEmotesEnabled(not API.preferences.getSignEmotesEnabled())
end

---Callback for toggling using the auto-suggest box.
---@param _ ISChat Unused.
function Callback.toggleUseSuggester(_)
    API.preferences.setUseSuggester(not API.preferences.getUseSuggester())
    API.ui.updateSuggesterComponent()
end


return Callback
