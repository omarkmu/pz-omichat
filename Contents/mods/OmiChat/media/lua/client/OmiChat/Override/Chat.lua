---Handles chat overrides and extensions.

local OmiChat = require 'OmiChatClient'


---Extended fields for ISChat.
---@class omichat.ISChat : ISChat
---@field instance omichat.ISChat? The ISChat instance.
---@field infoButton ISButton
---@field focused boolean Whether the chat is currently focused.
---@field showTitle boolean Whether chat type titles should display.
---@field showTimestamp boolean Whether timestamps should display.
---@field chatFont omichat.ChatFont The current font of the chat.
---@field chatText omichat.ChatTab The current chat tabs.
---@field tabs omichat.ChatTab[] List of available chat tabs.
---@field allChatStreams omichat.ChatStream[] List of all available chat streams.
---@field defaultTabStream table<integer, omichat.ChatStream?> An association of 1-indexed tab IDs to default streams.
---@field gearButton ISButton The settings button.
---@field textEntry ISTextEntryBox The text entry UI element.
---@field currentTabID integer The 1-indexed tab ID of the current tab.
---@field tabCnt integer The number of available tabs.
---@field iconButton ISButton? The icon button UI element.
---@field iconPicker omichat.IconPicker? The icon picker UI element.
---@field suggesterBox omichat.SuggesterBox? The suggester box UI element.
---@field typingFont UIFont The font used for the typing indicator.
---@field typingFontHgt integer The height of the font used for the typing indicator.
local ISChat = ISChat

local utils = OmiChat.utils
local config = OmiChat.config
local Option = OmiChat.Option
local ColorModal = OmiChat.ColorModal
local SuggesterBox = OmiChat.SuggesterBox
local getText = getText
local max = math.max
local concat = table.concat

local BloodBodyPartType = BloodBodyPartType
local getCoveredParts = BloodClothingType.getCoveredParts


--#region helpers

---Adds context menu options for admin controls.
---@param context ISContextMenu
local function addAdminOptions(context)
    if not isAdmin() then
        return
    end

    ---@type omichat.AdminOption[]
    local options = {
        'ShowIcon',
        'KnowAllLanguages',
        'IgnoreMessageRange',
    }

    local adminOptionName = getText('UI_OmiChat_ContextAdmin')
    local adminOption = context:addOption(adminOptionName, ISChat.instance)

    local subMenu = context:getNew(context)
    context:addSubMenu(adminOption, subMenu)

    local manageName = getText('UI_OmiChat_ContextAdminManageModData')
    subMenu:addOption(manageName, ISChat.instance, ISChat.onManageModData)

    for i = 1, #options do
        local option = options[i]
        local name = getText('UI_OmiChat_ContextAdmin_' .. option)
        local opt = subMenu:addOption(name, ISChat.instance, ISChat.onAdminOptionToggle, option)
        subMenu:setOptionChecked(opt, OmiChat.getAdminOption(option))
    end

    local handlers = OmiChat.getSettingHandlers('admin')
    for i = 1, #handlers do
        handlers[i](subMenu)
    end
end

---Adds the chat setting submenus from vanilla.
---From ISChat.
---@param context ISContextMenu
local function addVanillaSubmenuOptions(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local fontSizeOption = context:addOption(getText('UI_chat_context_font_submenu_name'), instance)
    local fontSubMenu = context:getNew(context)
    context:addSubMenu(fontSizeOption, fontSubMenu)
    fontSubMenu:addOption(getText('UI_chat_context_font_small'), instance, ISChat.onFontSizeChange, 'small')
    fontSubMenu:addOption(getText('UI_chat_context_font_medium'), instance, ISChat.onFontSizeChange, 'medium')
    fontSubMenu:addOption(getText('UI_chat_context_font_large'), instance, ISChat.onFontSizeChange, 'large')
    if instance.chatFont == 'small' then
        fontSubMenu:setOptionChecked(fontSubMenu.options[1], true)
    elseif instance.chatFont == 'medium' then
        fontSubMenu:setOptionChecked(fontSubMenu.options[2], true)
    elseif instance.chatFont == 'large' then
        fontSubMenu:setOptionChecked(fontSubMenu.options[3], true)
    end

    local minOpaqueOption = context:addOption(getText('UI_chat_context_opaque_min'), instance)
    local minOpaqueSubMenu = context:getNew(context)
    context:addSubMenu(minOpaqueOption, minOpaqueSubMenu)
    local opaques = { 0, 0.25, 0.5, 0.75, 1 }
    for i = 1, #opaques do
        if logTo01(opaques[i]) <= instance.maxOpaque then
            local optName = (opaques[i] * 100) .. '%'
            local option = minOpaqueSubMenu:addOption(optName, instance, ISChat.onMinOpaqueChange, opaques[i])
            local current = math.floor(instance.minOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                minOpaqueSubMenu:setOptionChecked(option, true)
            end
        end
    end

    local maxOpaqueOption = context:addOption(getText('UI_chat_context_opaque_max'), instance)
    local maxOpaqueSubMenu = context:getNew(context)
    context:addSubMenu(maxOpaqueOption, maxOpaqueSubMenu)
    for i = 1, #opaques do
        if logTo01(opaques[i]) >= instance.minOpaque then
            local optName = (opaques[i] * 100) .. '%'
            local option = maxOpaqueSubMenu:addOption(optName, instance, ISChat.onMaxOpaqueChange, opaques[i])
            local current = math.floor(instance.maxOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                maxOpaqueSubMenu:setOptionChecked(option, true)
            end
        end
    end

    local fadeTimeOption = context:addOption(getText('UI_chat_context_opaque_fade_time_submenu_name'), instance)
    local fadeTimeSubMenu = context:getNew(context)
    context:addSubMenu(fadeTimeOption, fadeTimeSubMenu)
    local availFadeTime = { 0, 1, 2, 3, 5, 10 }
    local optionName = getText('UI_chat_context_disable')
    local option = fadeTimeSubMenu:addOption(optionName, instance, ISChat.onFadeTimeChange, 0)
    if instance.fadeTime == 0 then
        fadeTimeSubMenu:setOptionChecked(option, true)
    end

    for i = 2, #availFadeTime do
        local time = availFadeTime[i]
        option = fadeTimeSubMenu:addOption(time .. ' s', instance, ISChat.onFadeTimeChange, time)
        if instance.fadeTime == time then
            fadeTimeSubMenu:setOptionChecked(option, true)
        end
    end

    local opaqueOnFocusOption = context:addOption(getText('UI_chat_context_opaque_on_focus'), instance)
    local opaqueOnFocusSubMenu = context:getNew(context)
    context:addSubMenu(opaqueOnFocusOption, opaqueOnFocusSubMenu)
    opaqueOnFocusSubMenu:addOption(getText('UI_chat_context_disable'), instance, ISChat.onFocusOpaqueChange, false)
    opaqueOnFocusSubMenu:addOption(getText('UI_chat_context_enable'), instance, ISChat.onFocusOpaqueChange, true)
    opaqueOnFocusSubMenu:setOptionChecked(opaqueOnFocusSubMenu.options[instance.opaqueOnFocus and 2 or 1], true)
end

---Adds the submenu for switching between player preference profiles.
---@param context ISContextMenu
local function addProfileSwitchSubmenu(context)
    local instance = ISChat.instance
    local profiles = OmiChat.getProfiles()
    if #profiles == 0 then
        return
    end

    local submenuName = getText('UI_OmiChat_ContextProfiles')
    local submenuOption = context:addOption(submenuName, instance)
    local submenu = context:getNew(context)
    context:addSubMenu(submenuOption, submenu)

    local currentIndex = OmiChat.getCurrentProfileIndex()
    local option = submenu:addOption(getText('UI_OmiChat_ContextProfileDefault'), instance, ISChat.onSwitchProfile, 0)
    submenu:setOptionChecked(option, currentIndex == nil)

    for i = 1, #profiles do
        local profile = profiles[i]
        option = submenu:addOption(profile.name, instance, ISChat.onSwitchProfile, i)
        submenu:setOptionChecked(option, i == currentIndex)
    end
end

---Adds the context menu options for roleplay languages.
---@param context ISContextMenu
local function addLanguageOptions(context)
    local languages = OmiChat.getRoleplayLanguages()
    local languageSlots = math.min(OmiChat.getRoleplayLanguageSlots(), config:maxLanguageSlots())

    local isKnown = {}
    local knownLanguages = {}
    for i = 1, #languages do
        local lang = languages[i]
        if OmiChat.isConfiguredRoleplayLanguage(lang) then
            knownLanguages[#knownLanguages + 1] = lang
            isKnown[lang] = true
        end
    end

    local addLanguages = {}
    if languageSlots - #knownLanguages >= 1 then
        local allLanguages = OmiChat.getConfiguredRoleplayLanguages()
        for i = 1, #allLanguages do
            local lang = allLanguages[i]
            if not isKnown[lang] and Option:canAddLanguage(lang) then
                addLanguages[#addLanguages + 1] = {
                    language = lang,
                    translated = utils.getTranslatedLanguageName(lang),
                }

                -- hard limit add menu to 50 to avoid freezing
                if #addLanguages == 50 then
                    break
                end
            end
        end
    end

    local languageOptionName = getText('UI_OmiChat_ContextLanguages')
    local languageOption = context:addOption(languageOptionName, ISChat.instance)
    local languageSubMenu = context:getNew(context)
    context:addSubMenu(languageOption, languageSubMenu)

    local currentLang = OmiChat.getCurrentRoleplayLanguage() or OmiChat.getDefaultRoleplayLanguage()
    for i = 1, #knownLanguages do
        local lang = knownLanguages[i]
        local name = utils.getTranslatedLanguageName(lang)
        local opt = languageSubMenu:addOption(name, ISChat.instance, ISChat.onLanguageSelect, lang)
        languageSubMenu:setOptionChecked(opt, lang == currentLang)
    end

    if #addLanguages > 0 then
        table.sort(addLanguages, function(a, b) return a.translated < b.translated end)

        local addLanguageSubMenu = languageSubMenu:getNew(languageSubMenu)
        local addLanguageOption = languageSubMenu:addOption(getText('UI_OmiChat_ContextAddLanguage'), ISChat.instance)
        languageSubMenu:addSubMenu(addLanguageOption, addLanguageSubMenu)
        for i = 1, #addLanguages do
            local lang = addLanguages[i].language
            local name = addLanguages[i].translated
            addLanguageSubMenu:addOption(name, ISChat.instance, ISChat.onAddLanguage, lang)
        end
    end

    local handlers = OmiChat.getSettingHandlers('language')
    for i = 1, #handlers do
        handlers[i](languageSubMenu)
    end

    if #languageSubMenu.options == 0 then
        context:removeLastOption()
    end
end

---Adds the context menu options for retaining commands.
---@param context ISContextMenu
local function addRetainOptions(context)
    local retainOption = context:addOption(getText('UI_OmiChat_ContextRetainCommands'), ISChat.instance)

    local retainSubMenu = context:getNew(context)
    context:addSubMenu(retainOption, retainSubMenu)

    local categories = {
        'chat',
        'rp',
        'other',
    }

    for i = 1, #categories do
        local cat = categories[i]
        local name = getText('UI_OmiChat_ContextRetainCommands_' .. cat)
        local opt = retainSubMenu:addOption(name, ISChat.instance, ISChat.onToggleRetainCommand, cat)
        retainSubMenu:setOptionChecked(opt, OmiChat.getRetainCommand(cat))
    end
end

---Adds the context menu option for enabling/disabling sign language emote animations.
---@param context ISContextMenu
local function addSignEmoteOption(context)
    local foundSigned = false
    local languages = OmiChat.getRoleplayLanguages()
    for i = 1, #languages do
        if OmiChat.isRoleplayLanguageSigned(languages[i]) then
            foundSigned = true
            break
        end
    end

    local defaultLang = not foundSigned and OmiChat.getDefaultRoleplayLanguage()
    if defaultLang then
        foundSigned = OmiChat.isRoleplayLanguageSigned(defaultLang)
    end

    if not foundSigned then
        return
    end

    local infix = OmiChat.getSignEmotesEnabled() and 'Disable' or 'Enable'
    local optName = getText('UI_OmiChat_Context' .. infix .. 'SignEmotes')
    local option = context:addOption(optName, ISChat.instance, ISChat.onToggleUseSignEmotes)
    option.toolTip = ISToolTip:new()
    option.toolTip.description = getText('UI_OmiChat_ContextSignEmotesTooltip')
end

---Adds the context menu options for suggestions.
---@param context ISContextMenu
local function addSuggestionOptions(context)
    local instance = ISChat.instance
    local isUseSuggester = OmiChat.getUseSuggester()
    if not isUseSuggester then
        local optName = getText('UI_OmiChat_ContextSuggestions_Enable')
        context:addOption(optName, instance, ISChat.onToggleUseSuggester)
        return
    end

    local suggestOption = context:addOption(getText('UI_OmiChat_ContextSuggestions'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(suggestOption, submenu)

    local disableOptName = getText('UI_OmiChat_ContextSuggestions_Disable')
    local onEnterOptName = getText('UI_OmiChat_ContextSuggestions_OnEnter')
    local onTabOptName = getText('UI_OmiChat_ContextSuggestions_OnTab')

    submenu:addOption(disableOptName, instance, ISChat.onToggleUseSuggester)

    local onEnterOpt = submenu:addOption(onEnterOptName, instance, ISChat.onToggleSuggestOnEnter)
    local onTabOpt = submenu:addOption(onTabOptName, instance, ISChat.onToggleSuggestOnTab)
    submenu:setOptionChecked(onEnterOpt, OmiChat.getSuggestOnEnter())
    submenu:setOptionChecked(onTabOpt, OmiChat.getSuggestOnTab())

    local handlers = OmiChat.getSettingHandlers('suggestions')
    for i = 1, #handlers do
        handlers[i](submenu)
    end
end

---Adds the chat settings submenu to the context menu.
---@param context ISContextMenu
local function addChatSettings(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local option = context:addOption(getText('UI_OmiChat_ContextChatSettings'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    local timestampOptName = instance.showTimestamp
        and getText('UI_chat_context_disable_timestamp')
        or getText('UI_chat_context_enable_timestamp')
    local tagOptName = instance.showTitle
        and getText('UI_chat_context_disable_tags')
        or getText('UI_chat_context_enable_tags')

    submenu:addOption(timestampOptName, instance, ISChat.onToggleTimestampPrefix)
    submenu:addOption(tagOptName, instance, ISChat.onToggleTagPrefix)

    if Option.PredicateShowTypingIndicator ~= '' then
        local typingOptName = OmiChat.getShowTyping()
            and getText('UI_OmiChat_ContextDisableTypingIndicator')
            or getText('UI_OmiChat_ContextEnableTypingIndicator')
        submenu:addOption(typingOptName, instance, ISChat.onToggleShowTyping)
    end

    addSuggestionOptions(submenu)
    addRetainOptions(submenu)
    addVanillaSubmenuOptions(submenu)

    local handlers = OmiChat.getSettingHandlers('basic')
    for i = 1, #handlers do
        handlers[i](submenu)
    end
end

---Adds the chat customization submenu to the context menu.
---@param context ISContextMenu
local function addChatCustomizationSettings(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local option = context:addOption(getText('UI_OmiChat_ContextChatCustomization'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    if Option.EnableSetNameColor or Option.EnableSpeechColorAsDefaultNameColor then
        local nameColorOptName = OmiChat.getNameColorsEnabled()
            and getText('UI_OmiChat_ContextDisableNameColors')
            or getText('UI_OmiChat_ContextEnableNameColors')

        submenu:addOption(nameColorOptName, instance, ISChat.onToggleShowNameColor)
    end

    if not Option.EnableCharacterCustomization then
        addSignEmoteOption(submenu)
    end

    local manageOptName = getText('UI_OmiChat_ContextManageProfiles')
    submenu:addOption(manageOptName, instance, ISChat.onManageProfiles)

    local handlers = OmiChat.getSettingHandlers('chat_customization')
    for i = 1, #handlers do
        handlers[i](submenu)
    end
end

---Adds the character customization submenu to the context menu.
---@param context ISContextMenu
local function addCharacterCustomizationSettings(context)
    local instance = ISChat.instance
    if not instance or not Option.EnableCharacterCustomization then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local option = context:addOption(getText('UI_OmiChat_ContextCharacterCustomization'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    addSignEmoteOption(submenu)

    if Option:isCleanCustomizationEnabled() then
        local cleanOptName = getText('UI_OmiChat_ContextClean')
        submenu:addOption(cleanOptName, instance, ISChat.onCleanCharacter)
    end

    local hairColorOptName = getText('UI_OmiChat_ContextHairColor')
    submenu:addOption(hairColorOptName, instance, ISChat.onHairColorMenu)

    local growHairOptName = getText('UI_OmiChat_ContextGrowHair')
    submenu:addOption(growHairOptName, instance, ISChat.onGrowHair)

    if not player:isFemale() then
        local growBeardOptName = getText('UI_OmiChat_ContextGrowBeard')
        submenu:addOption(growBeardOptName, instance, ISChat.onGrowBeard)
    end

    local handlers = OmiChat.getSettingHandlers('character_customization')
    for i = 1, #handlers do
        handlers[i](submenu)
    end
end

---Checks whether the player is dead or unavailable.
---@return boolean
local function isPlayerDead()
    local player = getSpecificPlayer(0)
    return not player or player:isDead()
end

---Clears the last chat command for a tab based on retain options.
---@param tab omichat.ChatTab
local function refreshLastCommand(tab)
    local lastChatCommand = tab.lastChatCommand
    if not lastChatCommand or lastChatCommand == '' then
        return
    end

    local stream = OmiChat.chatCommandToStream(lastChatCommand, true)
    local commandType = stream and stream:getCommandType() or 'other'
    if not OmiChat.getRetainCommand(commandType) then
        tab.lastChatCommand = ''
    end
end

---Checks whether the chat input should be reset to a slash based on the current input.
---@param prefix string?
---@param text string
---@param internalText string
---@return string?
local function shouldResetText(prefix, text, internalText)
    if not prefix or not utils.startsWith(internalText, prefix) then
        return
    end

    if #text:sub(#prefix + 1, #text) <= 5 and utils.endsWith(internalText, '/') then
        return prefix
    end
end

---Attempts to set the current text with the currently selected suggester box item.
---@return boolean didSet
local function tryInputSuggestedItem()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    local visible = suggesterBox and suggesterBox:isVisible()
    if not instance or not suggesterBox or not visible then
        return false
    end

    local item = suggesterBox:getSelectedItem()
    if item then
        instance:onSuggesterSelect(item)
        return true
    end

    return false
end

--#endregion

--#region callbacks

---Event handler for toggling admin options.
---@param target omichat.ISChat
---@param option omichat.AdminOption
---@diagnostic disable-next-line: unused-local
function ISChat.onAdminOptionToggle(target, option)
    local value = OmiChat.getAdminOption(option)
    OmiChat.setAdminOption(option, not value)
end

---Event handler for the clean character customization option.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onCleanCharacter(target)
    local player = getSpecificPlayer(0)
    local visual = player and player:getHumanVisual()
    if not visual then
        return
    end

    -- update body
    for i = 0, BloodBodyPartType.MAX:index() - 1 do
        local bodyPart = BloodBodyPartType.FromIndex(i)
        visual:setDirt(bodyPart, 0)
        visual:setBlood(bodyPart, 0)
    end

    local shouldUpdateClothing = Option:isCleanClothingEnabled()
    if shouldUpdateClothing then
        -- update clothing
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

---Event handler for the grow hair customization option.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onGrowHair(target)
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local hairStyle = player:isFemale() and 'Long2' or 'Fabian'
    ISTimedActionQueue.add(ISCutHair:new(player, hairStyle, nil, 1))
end

---Event handler for the grow beard customization option.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onGrowBeard(target)
    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    ISTimedActionQueue.add(ISTrimBeard:new(player, 'Long', nil, 1))
end

---Event handler for the hair color customization menu initialization.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onHairColorMenu(target)
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
    local width = max(450, getTextManager():MeasureStringX(UIFont.Small, text) + 60)
    local modal = ColorModal:new(0, 0, width, 250, text, color, target, ISChat.onCustomHairColorMenuClick, 0)

    modal:setEmptyColor(emptyColor)
    modal:initialise()
    modal:addToUIManager()

    target.activeColorModal = modal
end

---Event handler for hair color picker selection.
---@param target omichat.ISChat
---@param button table
---@diagnostic disable-next-line: unused-local
function ISChat.onCustomHairColorMenuClick(target, button)
    if button.internal ~= 'OK' then
        return
    end

    local player = getSpecificPlayer(0)
    local visual = player and player:getHumanVisual()
    if not visual then
        return
    end

    local hairColor
    local color = button.parent:getColorTable()
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

---Event handler for toggling command retaining.
---@param target omichat.ISChat
---@param type omichat.ChatCommandType
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleRetainCommand(target, type)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local value = not OmiChat.getRetainCommand(type)
    OmiChat.setRetainCommand(type, value)

    if value then
        -- don't need to clear the last command for enable
        return
    end

    for i = 1, #instance.tabs do
        refreshLastCommand(instance.tabs[i])
    end
end

---Event handler for toggling showing name colors.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleShowNameColor(target)
    OmiChat.setNameColorEnabled(not OmiChat.getNameColorsEnabled())
    OmiChat.redrawMessages()
end

---Event handler for toggling using the suggester.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleShowTyping(target)
    OmiChat.setShowTyping(not OmiChat.getShowTyping())
    OmiChat.updateTypingDisplay()
    OmiChat.updateChatPanelSize()
end

---Event handler for toggling applying suggestions on Enter.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleSuggestOnEnter(target)
    OmiChat.setSuggestOnEnter(not OmiChat.getSuggestOnEnter())
end

---Event handler for toggling applying suggestions on Tab.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleSuggestOnTab(target)
    OmiChat.setSuggestOnTab(not OmiChat.getSuggestOnTab())
end

---Event handler for toggling sign language emotes.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleUseSignEmotes(target)
    OmiChat.setSignEmotesEnabled(not OmiChat.getSignEmotesEnabled())
end

---Event handler for toggling using the suggester.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleUseSuggester(target)
    OmiChat.setUseSuggester(not OmiChat.getUseSuggester())
    OmiChat.updateSuggesterComponent()
end

---Event handler for icon button click.
---@param target omichat.ISChat
---@return boolean
function ISChat.onIconButtonClick(target)
    if isPlayerDead() then
        return false
    end

    local iconPicker = target.iconPicker
    if not ISChat.focused or not iconPicker then
        return false
    end

    local targetHeight = target:getHeight()
    local x = target:getX() + target:getWidth()
    local y = target:getY() + max(0, targetHeight - iconPicker:getHeight())

    -- avoid covering the button
    if x + iconPicker:getWidth() >= getPlayerScreenWidth(0) then
        y = y - target.textEntry:getHeight() - target.inset * 2 - 5

        if y <= 0 then
            y = targetHeight
        end
    end

    iconPicker:setX(x)
    iconPicker:setY(y)
    iconPicker:bringToTop()
    iconPicker:setVisible(not iconPicker:isVisible())
    OmiChat.hideSuggesterBox()

    return true
end

---Event handler for icon picker selection.
---@param target omichat.ISChat
---@param icon string The icon that was selected.
function ISChat.onIconClick(target, icon)
    if isPlayerDead() then
        return
    end

    if not ISChat.focused then
        target:focus()
    elseif not ISChat.instance.textEntry:isFocused() then
        ISChat.instance.textEntry:focus()
    end

    local text = target.textEntry:getInternalText()

    local addSpace = #text > 0 and text:sub(-1) ~= ' '
    target.textEntry:setText(concat { text, addSpace and ' *' or '*', icon, '*' })
    OmiChat.updateSuggesterComponent()
end

---Event handler for selecting a suggestion.
---@param target omichat.ISChat
---@param suggestion omichat.Suggestion
---@diagnostic disable-next-line: unused-local
function ISChat.onSuggesterSelect(target, suggestion)
    local entry = ISChat.instance.textEntry

    OmiChat.hideSuggesterBox()
    entry:setText(suggestion.suggestion)
    OmiChat.updateSuggesterComponent()
end

---Event handler for adding a roleplay language.
---@param target omichat.ISChat
---@param language string
---@diagnostic disable-next-line: unused-local
function ISChat.onAddLanguage(target, language)
    if target.activeLanguageModal then
        target.activeLanguageModal:destroy()
    end

    local text = getText('UI_OmiChat_ContextConfirmAddLanguage', utils.getTranslatedLanguageName(language))
    target.activeLanguageModal = utils.createModal(text, target, ISChat.onConfirmAddLanguage, language)
end

---Event handler for confirming adding a roleplay language.
---@param target omichat.ISChat
---@param button ISButton
---@param language string
---@diagnostic disable-next-line: unused-local
function ISChat.onConfirmAddLanguage(target, button, language)
    if button.internal ~= 'YES' then
        return
    end

    OmiChat.addRoleplayLanguage(language)
end

---Event handler for selecting the current roleplay language.
---@param target omichat.ISChat
---@param language string
---@diagnostic disable-next-line: unused-local
function ISChat.onLanguageSelect(target, language)
    OmiChat.setCurrentRoleplayLanguage(language)
end

---Event handler for clicking the manage profiles context option.
---@param target omichat.ISChat
function ISChat.onManageProfiles(target)
    if target.activeProfilesPanel then
        target.activeProfilesPanel:destroy()
    end

    local x, y = utils.getScreenCenter(800, 600)
    local panel = OmiChat.ProfileManager:new(x, y, 800, 600, OmiChat.getProfiles())
    panel:initialise()
    panel:addToUIManager()
    target.activeProfilesPanel = panel
end

---Event handler for clicking the manage mod data admin context option.
---@param target omichat.ISChat
function ISChat.onManageModData(target)
    if target.activeModDataPanel then
        target.activeModDataPanel:destroy()
    end

    local x, y = utils.getScreenCenter(1200, 650)
    local panel = OmiChat.ModDataManager:new(x, y, 1200, 650)
    panel:initialise()
    panel:addToUIManager()

    target.activeModDataPanel = panel
end

---Event handler for switching a chat profile.
---@param target omichat.ISChat
---@param idx integer
---@diagnostic disable-next-line: unused-local
function ISChat.onSwitchProfile(target, idx)
    OmiChat.switchProfile(idx)
    OmiChat.redrawMessages()
end

---Validation function for custom callout menu.
---@param target ISTextBox | omichat.ValidatedTextEntry
---@param text string
---@return boolean
function ISChat.validateCustomCalloutText(target, text)
    local lines = utils.getLines(text)
    if not lines then
        return true
    end

    if #lines > Option.MaximumCustomShouts then
        target:setValidateTooltipText(getText('UI_OmiChat_Error_TooManyShouts', tostring(Option.MaximumCustomShouts)))
        return false
    end

    for i = 1, #lines do
        if #lines[i] > Option.CustomShoutMaxLength then
            local maxLen = tostring(Option.CustomShoutMaxLength)
            target:setValidateTooltipText(getText('UI_OmiChat_Error_TooLongShout', maxLen))
            return false
        end
    end

    return true
end

--#endregion

--#region overrides

local _addLineInChat = ISChat.addLineInChat
local _onCommandEntered = ISChat.onCommandEntered
local _logChatCommand = ISChat.logChatCommand
local _createChildren = ISChat.createChildren
local _createTab = ISChat.createTab
local _focus = ISChat.focus
local _unfocus = ISChat.unfocus
local _close = ISChat.close
local _onMouseDown = ISChat.onMouseDown
local _onPressDown = ISChat.onPressDown
local _onPressUp = ISChat.onPressUp
local _onOtherKey = ISChat.onOtherKey
local _onInfo = ISChat.onInfo
local _onTabAdded = ISChat.onTabAdded
local _onTabRemoved = ISChat.onTabRemoved
local _update = ISChat.update
local _render = ISChat.render

local _ChatMessage = __classmetatables[ChatMessage.class].__index
local _ServerChatMessage = __classmetatables[ServerChatMessage.class].__index

---Override to enable custom formatting.
_ChatMessage.getTextWithPrefix = OmiChat.buildMessageText
_ServerChatMessage.getTextWithPrefix = OmiChat.buildMessageText


---Override to add information to chat messages and remove blank lines.
---@param message omichat.Message The new chat message.
---@param tabID integer 0-indexed tab ID.
function ISChat.addLineInChat(message, tabID)
    if not message then
        return
    end

    local soundRange
    local player = getSpecificPlayer(0)
    local username = player and player:getUsername()

    local mtIndex = (getmetatable(message) or {}).__index
    if mtIndex == _ChatMessage or mtIndex == _ServerChatMessage or utils.isinstance(message, OmiChat.MimicMessage) then
        local chatType = OmiChat.getMessageChatType(message)
        if chatType == 'radio' then
            local formatter = OmiChat.getFormatter('onlineID')
            local value = formatter:read(message:getText())
            local onlineID = value and utils.decodeInvisibleInt(value)
            local authorPlayer = onlineID and getPlayerByOnlineID(onlineID)

            if authorPlayer then
                message:setAuthor(authorPlayer:getUsername())
            elseif username and message:getAuthor() == username then
                -- if we can't find the author, clear instead of attributing to this player
                message:setAuthor('')
            end
        end

        if Option:compatChatBubbleEnabled() and message:getText():match('%[img=media/textures/bubble%d%.png%]') then
            return
        end

        message:setCustomTag(OmiChat.encodeMessageTag(message))

        -- necessary to process transforms so we know whether this message should be added to chat
        local info = OmiChat.buildMessageInfo(message, true)
        if info then
            if not message:isShowInChat() then
                return
            end

            if message:isShouldAttractZombies() and username == message:getAuthor() then
                soundRange = info.attractRange
            end
        end
    end

    local s, e = pcall(_addLineInChat, message, tabID)
    if not s then
        utils.logError('error while adding message %s: %s', tostring(message), e)
        return
    end

    if player and soundRange and soundRange > 0 then
        addSound(player, player:getX(), player:getY(), player:getZ(), soundRange, soundRange)
    end
end

---Override to unfocus on close.
function ISChat:close()
    _close(self)

    if not self.locked then
        self:unfocus()
        OmiChat.updateTypingStatus(true)
    end
end

---Override to add custom components.
function ISChat:createChildren()
    _createChildren(self)

    self.typingFont = UIFont.Small
    self.typingFontHgt = getTextManager():getFontFromEnum(self.typingFont):getLineHeight()

    local th = self:titleBarHeight()
    self.infoButton = ISButton:new(self.gearButton:getX() - th / 2 - th, 0, th, th, '', self, self.onInfo)
    self.infoButton.anchorRight = true
    self.infoButton.anchorLeft = false
    self.infoButton:initialise()
    self.infoButton.borderColor.a = 0.0
    self.infoButton.backgroundColor.a = 0.0
    self.infoButton.backgroundColorMouseOver.a = 0
    self.infoButton:setImage(self.infoBtn)
    self.infoButton:setUIName('chat info button')
    self.infoButton:setVisible(false)

    self.suggesterBox = SuggesterBox:new(0, 0, 0, 0)
    self.suggesterBox:setOnMouseDownFunction(self, self.onSuggesterSelect)
    self.suggesterBox:setAlwaysOnTop(true)
    self.suggesterBox:setUIName('chat suggester box')
    self.suggesterBox:addToUIManager()
    self.suggesterBox:setVisible(false)

    OmiChat.addCustomButton(self.infoButton)
    OmiChat.updateState()
end

---Override to mark chat tabs for rich text processing changes.
---@return omichat.ChatTab
function ISChat:createTab()
    local tab = _createTab(self)
    tab.ocIsChatTab = true
    return tab
end

---Override to correct the chat stream and enable the icon button on focus.
function ISChat:focus()
    if isPlayerDead() then
        return
    end

    _focus(self)

    local text = ISChat.instance.textEntry:getInternalText()
    OmiChat.updateCustomComponents(text)

    -- correct the stream ID to the current stream
    local currentStreamName = OmiChat.chatCommandToStreamName(text)
    if currentStreamName then
        OmiChat.cycleStream(currentStreamName)
    end
end

---Override to avoid adding sequential duplicates to the history log.
---@param command string
function ISChat:logChatCommand(command)
    if self.chatText.log[1] == command then
        self.chatText.logIndex = 0
        return
    end

    _logChatCommand(self, command)
end

---Override to support custom commands and emote shortcuts.
function ISChat:onCommandEntered()
    if isPlayerDead() then
        return
    end

    if OmiChat.getSuggestOnEnter() and tryInputSuggestedItem() then
        OmiChat.updateCustomComponents()
        return
    end

    local instance = ISChat.instance ---@cast instance omichat.ISChat
    local input = instance.textEntry:getText()
    local stream, command, chatCommand, disabledStream = OmiChat.chatCommandToStream(input, true, true)

    local useCallback
    local callbackStream

    local commandType = 'other'
    local shouldHandle = false
    local allowEmotes = false
    local isDefault = false

    if not stream then
        -- process emotes for streamless messages unless there's a leading slash
        local isCommand = utils.startsWith(input, '/')
        allowEmotes = not isCommand
        command = input

        local default = OmiChat.getDefaultTabStream(instance.currentTabID)
        if not isCommand and default then
            stream = default
            allowEmotes = not isCommand and default:isAllowEmotes()
            isDefault = true
        end
    end

    if stream then
        if not stream:isTabID(instance.currentTabID) then
            -- wrong chat tab
            showWrongChatTabMessage(instance.currentTabID - 1, stream:getTabID() - 1, chatCommand or '')
            stream = nil
            allowEmotes = false
            shouldHandle = true
        else
            shouldHandle = true
            callbackStream = stream
            allowEmotes = not isDefault and stream:isAllowEmotes() or allowEmotes
            useCallback = stream:getUseCallback() or OmiChat.send
            commandType = stream:getCommandType()
        end

        if isDefault then
            stream = nil
        end
    end

    -- handle emotes specified with .emote
    local playedEmote
    if allowEmotes and Option.EnableEmotes then
        local emoteToPlay, start, finish, emote = OmiChat.getEmoteFromCommand(command)
        if emoteToPlay then
            -- remove the emote text
            shouldHandle = true
            playedEmote = true
            command = utils.trim(command:sub(1, start - 1) .. command:sub(finish + 1))

            local player = getSpecificPlayer(0)
            if player then
                if type(emoteToPlay) == 'string' then
                    player:playEmote(emoteToPlay)
                else
                    ---@cast emote string
                    emoteToPlay(player, emote)
                end
            end
        end
    end

    local shouldRetain = OmiChat.getRetainCommand(commandType)
    if shouldRetain and stream then
        -- fix the switching functionality by updating to the used stream
        OmiChat.cycleStream(stream:getName())
    end

    if callbackStream and not callbackStream:validate(command) then
        shouldHandle = true
        callbackStream = nil
    end

    if disabledStream then
        local onUseDisabled = disabledStream:getUseDisabledCallback()
        if onUseDisabled then
            onUseDisabled(disabledStream)
        elseif disabledStream:getCommandType() ~= 'chat' then
            OmiChat.addInfoMessage('Unknown command ' .. command:sub(2))
        else
            local msg = { getText('UI_chat_chat_disabled_msg', utils.trim(disabledStream:getCommand())) }
            for i = 1, #ISChat.allChatStreams do
                local info = OmiChat.StreamInfo:new(ISChat.allChatStreams[i])
                if info:isEnabled() then
                    msg[#msg + 1] = '* '
                    msg[#msg + 1] = utils.trim(info:getCommand())
                    msg[#msg + 1] = ' <LINE> '
                end
            end

            if #msg > 1 then
                msg[#msg] = nil
                OmiChat.addInfoMessage(concat(msg))
            end
        end
    elseif not shouldHandle then
        -- no special handling, pass to original function
        _onCommandEntered(self)

        if shouldRetain then
            instance.chatText.lastChatCommand = command:sub(1, command:find(' ') or #command)
        end

        return
    end

    instance:unfocus()
    instance:logChatCommand(input)
    OmiChat.scrollToBottom()

    if shouldRetain and stream then
        instance.chatText.lastChatCommand = chatCommand
    elseif stream then
        -- if the used stream shouldn't be set as the last, cycle to the previous command
        local lastChatStream = OmiChat.chatCommandToStreamName(instance.chatText.lastChatCommand)
        if lastChatStream then
            OmiChat.cycleStream(lastChatStream)
        end
    end

    if callbackStream and useCallback then
        useCallback {
            text = command,
            stream = callbackStream,
            playSignedEmote = not playedEmote,
        }
    end

    doKeyPress(false)
    instance.timerTextEntry = 20
end

---Override to add additional settings and reorganize existing ones.
function ISChat:onGearButtonClick()
    if isPlayerDead() then
        -- avoid errors from clicking the button after dying
        return
    end

    OmiChat.hideSuggesterBox()

    local x = getMouseX()
    local y = getMouseY()
    local context = ISContextMenu.get(0, x, y)

    addAdminOptions(context)
    addChatSettings(context)
    addChatCustomizationSettings(context)
    addCharacterCustomizationSettings(context)
    addProfileSwitchSubmenu(context)
    addLanguageOptions(context)

    local handlers = OmiChat.getSettingHandlers('main')
    for i = 1, #handlers do
        handlers[i](context)
    end
end

---Override to handle custom info text.
function ISChat:onInfo()
    OmiChat.hideSuggesterBox()

    local text = OmiChat.getInfoRichText()
    self:setInfo(text)

    if text == '' and self.infoRichText then
        self.infoRichText:removeFromUIManager()
        return
    end

    _onInfo(self)
end

---Override to hide components on text panel or entry click.
---@param target ISUIElement
---@param x number
---@param y number
---@return boolean
function ISChat.onMouseDown(target, x, y)
    local handled = _onMouseDown(target, x, y)
    local instance = ISChat.instance
    if not instance then
        return handled
    end

    local iconPicker = instance.iconPicker
    OmiChat.hideSuggesterBox()

    if not handled or not iconPicker or not iconPicker:isVisible() then
        return handled
    end

    local name = target:getUIName()
    if name == ISChat.textPanelName or name == ISChat.textEntryName then
        iconPicker:setVisible(false)
    end

    return handled
end

---Override to update custom components.
function ISChat:onOtherKey(key)
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox and suggesterBox:isVisible() and key == Keyboard.KEY_ESCAPE then
        OmiChat.hideSuggesterBox()
    else
        _onOtherKey(self, key)
    end
end

---Override to update custom components.
function ISChat.onPressDown()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox and suggesterBox:isVisible() then
        suggesterBox:selectNext()
        return
    end

    _onPressDown()
    OmiChat.updateCustomComponents()
end

---Override to update custom components.
function ISChat.onPressUp()
    local instance = ISChat.instance
    local suggesterBox = instance and instance.suggesterBox
    if suggesterBox and suggesterBox:isVisible() then
        suggesterBox:selectPrevious()
        return
    end

    _onPressUp()
    OmiChat.updateCustomComponents()
end

---Override to control custom components and allow switching to custom streams.
function ISChat.onSwitchStream()
    if not ISChat.focused or not ISChat.instance then
        return
    end

    local text
    if not (OmiChat.getSuggestOnTab() and tryInputSuggestedItem()) then
        text = OmiChat.cycleStream()
        local entry = ISChat.instance.textEntry
        entry:setText(text)
    end

    OmiChat.updateCustomComponents(text)
end

---Override to respect retain options when creating chat tabs.
---@param tabTitle string
---@param tabID integer
function ISChat.onTabAdded(tabTitle, tabID)
    _onTabAdded(tabTitle, tabID)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local target
    for i = 1, #instance.tabs do
        if instance.tabs[i].tabID == tabID then
            target = instance.tabs[i]
            break
        end
    end

    if target then
        refreshLastCommand(target)
    end

    OmiChat.updateChatPanelSize()
end

---Override to correct the chat panel sizes after removing a tab.
---@param tabTitle string
---@param tabID integer
function ISChat.onTabRemoved(tabTitle, tabID)
    _onTabRemoved(tabTitle, tabID)
    OmiChat.updateChatPanelSize()
end

---Override to update custom components and include aliases in determination for resetting input.
function ISChat.onTextChange()
    local instance = ISChat.instance
    local chatText = instance and instance.chatText
    if not instance or not chatText or not chatText.lastChatCommand then
        OmiChat.updateCustomComponents()
        return
    end

    local entry = ISChat.instance.textEntry
    local internalText = entry:getInternalText()
    if not utils.endsWith(internalText, '/') then
        OmiChat.updateCustomComponents()
        return
    end

    local text = entry:getText()
    if #text <= 6 then
        entry:setText('/')
        OmiChat.updateCustomComponents()
        return
    end

    for i = 1, #chatText.chatStreams do
        local prefix
        local stream = chatText.chatStreams[i]

        if stream.command then
            prefix = shouldResetText(stream.command, text, internalText)
        end

        if not prefix and stream.shortCommand then
            prefix = shouldResetText(stream.shortCommand, text, internalText)
        end

        if not prefix and stream.omichat and stream.omichat.aliases then
            for j = 1, #stream.omichat.aliases do
                prefix = shouldResetText(stream.omichat.aliases[j], text, internalText)
                if prefix then
                    break
                end
            end
        end

        if prefix and #text:sub(#prefix + 1, #text) <= 5 then
            entry:setText('/')
            OmiChat.updateCustomComponents()
            return
        end
    end

    OmiChat.updateCustomComponents()
end

---Override to render the typing indicator.
function ISChat:render()
    _render(self)

    if self.currentTabID ~= 1 then
        return
    end

    local w = self:getWidth()
    local text = OmiChat.getTypingDisplay(w)
    if not text then
        return
    end

    local x = 4
    local y = self.textEntry:getY() - self.typingFontHgt - 3
    self:setStencilRect(0, 0, w, self:getHeight())
    self:drawText(text, x, y, 1, 1, 1, 1, self.typingFont)
    self:clearStencilRect()
end

---Override to hide icon picker and disable button on unfocus.
function ISChat:unfocus()
    _unfocus(self)
    OmiChat.hideSuggesterBox()
    OmiChat.setIconButtonEnabled(false)
end

---Override to process typing indicators.
function ISChat:update()
    _update(self)
    OmiChat.updateTypingDisplay()
    OmiChat.updateTypingStatus()
end

---Override to improve performance of text refresh.
function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    OmiChat.redrawMessages()
end

--#endregion
