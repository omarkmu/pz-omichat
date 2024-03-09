---Handles chat overrides and extensions.

local OmiChat = require 'OmiChat/API/Client'

-- requires buildMessageText
require 'OmiChat/API/ClientFormat'


---Extended fields for ISChat.
---@class omichat.ISChat : ISChat
---@field instance omichat.ISChat? The ISChat instance.
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
local ISChat = ISChat

local utils = OmiChat.utils
local config = OmiChat.config
local Option = OmiChat.Option
local ColorModal = OmiChat.ColorModal
local SuggesterBox = OmiChat.SuggesterBox
local getText = getText
local getTextOrNull = getTextOrNull
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
        'show_icon',
        'know_all_languages',
        'ignore_message_range',
    }

    local adminOptionName = getText('UI_OmiChat_context_admin')
    local adminOption = context:addOption(adminOptionName, ISChat.instance)

    local subMenu = context:getNew(context)
    context:addSubMenu(adminOption, subMenu)

    for i = 1, #options do
        local option = options[i]
        local name = getText('UI_OmiChat_context_admin_' .. option)
        local opt = subMenu:addOption(name, ISChat.instance, ISChat.onAdminOptionToggle, option)
        subMenu:setOptionChecked(opt, OmiChat.getAdminOption(option))
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

---Adds context menu options for chat colors.
---@param context ISContextMenu
local function addColorOptions(context)
    local colorOpts = {}
    local canUsePM = checkPlayerCanUseChat('/w')
    local useLocalWhisper = OmiChat.isCustomStreamEnabled('whisper')

    if Option.EnableSetNameColor then
        colorOpts[#colorOpts + 1] = 'name'
    end

    if Option.EnableSetSpeechColor then
        colorOpts[#colorOpts + 1] = 'speech'
    end

    colorOpts[#colorOpts + 1] = 'server'

    if Option:showDiscordColorOption() then
        colorOpts[#colorOpts + 1] = 'discord'
    end

    -- need to check the option because checkPlayerCanUseChat checks for a radio item
    local allowedStreams = getServerOptions():getOption('ChatStreams'):split(',')
    for i = 1, #allowedStreams do
        if allowedStreams[i] == 'r' then
            colorOpts[#colorOpts + 1] = 'radio'
            break
        end
    end

    if checkPlayerCanUseChat('/a') then
        colorOpts[#colorOpts + 1] = 'admin'
    end

    if checkPlayerCanUseChat('/all') then
        colorOpts[#colorOpts + 1] = 'general'
    end

    if checkPlayerCanUseChat('/f') then
        colorOpts[#colorOpts + 1] = 'faction'
    end

    if checkPlayerCanUseChat('/sh') then
        colorOpts[#colorOpts + 1] = 'safehouse'
    end

    if useLocalWhisper and canUsePM then
        colorOpts[#colorOpts + 1] = 'private' -- /pm
    end

    if checkPlayerCanUseChat('/s') then
        colorOpts[#colorOpts + 1] = 'say'
    end

    if checkPlayerCanUseChat('/y') then
        colorOpts[#colorOpts + 1] = 'shout'
    end

    if not useLocalWhisper and canUsePM then
        colorOpts[#colorOpts + 1] = 'private' -- /whisper
    end

    for info in config:chatStreams() do
        local name = info.name
        if info.autoColorOption ~= false and OmiChat.isCustomStreamEnabled(name) then
            colorOpts[#colorOpts + 1] = name
        end
    end

    if #colorOpts > 0 then
        local colorOptionName = getText('UI_OmiChat_context_colors_submenu_name')
        local colorOption = context:addOption(colorOptionName, ISChat.instance)

        local colorSubMenu = context:getNew(context)
        context:addSubMenu(colorOption, colorSubMenu)

        for i = 1, #colorOpts do
            local category = colorOpts[i]
            local name = getTextOrNull('UI_OmiChat_context_submenu_color_' .. category)
            if not name then
                name = getText('UI_OmiChat_context_submenu_color', OmiChat.getColorCategoryCommand(category))
            end

            colorSubMenu:addOption(name, ISChat.instance, ISChat.onCustomColorMenu, category)
        end
    end
end

---Adds the context menu options for custom callouts.
---@param context ISContextMenu
local function addCustomCalloutOptions(context)
    local shoutOpts = { 'callouts', 'sneakcallouts' }
    for i = 1, #shoutOpts do
        local shoutType = shoutOpts[i]
        local shoutOptionName = getText('UI_OmiChat_context_set_custom_' .. shoutType)
        context:addOption(shoutOptionName, ISChat.instance, ISChat.onCustomCalloutMenu, shoutType)
    end
end

---Adds the context menu options for roleplay languages.
---@param context ISContextMenu
local function addLanguageOptions(context)
    local languages = OmiChat.getRoleplayLanguages()
    local languageSlots = OmiChat.getRoleplayLanguageSlots()
    if languageSlots == 0 and #languages <= 1 then
        -- nothing to configure → don't show the menu
        return
    end

    local isKnown = {}
    local knownLanguages = {}
    local allLanguages = OmiChat.getConfiguredRoleplayLanguages()
    local currentLang = OmiChat.getCurrentRoleplayLanguage() or OmiChat.getDefaultRoleplayLanguage()
    for i = 1, #languages do
        local lang = languages[i]
        if allLanguages[lang] then
            knownLanguages[#knownLanguages + 1] = lang
            isKnown[lang] = true
        end
    end

    local addLanguages = {}
    if languageSlots - #languages >= 1 and #languages < 32 then
        for i = 1, #allLanguages do
            local lang = allLanguages[i]
            if not isKnown[lang] then
                addLanguages[#addLanguages + 1] = {
                    language = lang,
                    translated = getTextOrNull('UI_OmiChat_Language_' .. lang) or lang,
                }
            end
        end
    end

    local languageSubMenu
    if #knownLanguages > 0 or #addLanguages > 0 then
        local languageOptionName = getText('UI_OmiChat_context_languages')
        local languageOption = context:addOption(languageOptionName, ISChat.instance)

        languageSubMenu = context:getNew(context)
        context:addSubMenu(languageOption, languageSubMenu)
    end

    for i = 1, #knownLanguages do
        local lang = knownLanguages[i]
        local name = getTextOrNull('UI_OmiChat_Language_' .. lang) or lang
        local opt = languageSubMenu:addOption(name, ISChat.instance, ISChat.onLanguageSelect, lang)
        languageSubMenu:setOptionChecked(opt, lang == currentLang)
    end

    if #addLanguages == 0 then
        return
    end

    table.sort(addLanguages, function(a, b) return a.translated < b.translated end)

    local addLanguageSubMenu = languageSubMenu:getNew(languageSubMenu)
    local addLanguageOption = languageSubMenu:addOption(getText('UI_OmiChat_context_add_language'), ISChat.instance)
    languageSubMenu:addSubMenu(addLanguageOption, addLanguageSubMenu)
    for i = 1, #addLanguages do
        local lang = addLanguages[i].language
        local name = addLanguages[i].translated
        addLanguageSubMenu:addOption(name, ISChat.instance, ISChat.onAddLanguage, lang)
    end
end

---Adds the context menu options for retaining commands.
---@param context ISContextMenu
local function addRetainOptions(context)
    local retainOption = context:addOption(getText('UI_OmiChat_context_retain_commands'), ISChat.instance)

    local retainSubMenu = context:getNew(context)
    context:addSubMenu(retainOption, retainSubMenu)

    local categories = {
        'chat',
        'rp',
        'other',
    }

    for i = 1, #categories do
        local cat = categories[i]
        local name = getText('UI_OmiChat_context_retain_commands_' .. cat)
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

    local suffix = OmiChat.getSignEmotesEnabled() and 'disable' or 'enable'
    local optName = getText('UI_OmiChat_context_sign_emotes_' .. suffix)
    local option = context:addOption(optName, ISChat.instance, ISChat.onToggleUseSignEmotes)
    option.toolTip = ISToolTip:new()
    option.toolTip.description = getText('UI_OmiChat_context_sign_emotes_tooltip')
end

---Adds the chat settings submenu to the context menu.
---@param context ISContextMenu
local function addChatSettings(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local option = context:addOption(getText('UI_OmiChat_context_chat_settings'), instance)
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

    local suggesterOptName = OmiChat.getUseSuggester()
        and getText('UI_OmiChat_context_disable_suggestions')
        or getText('UI_OmiChat_context_enable_suggestions')
    submenu:addOption(suggesterOptName, instance, ISChat.onToggleUseSuggester)

    addRetainOptions(submenu)
    addVanillaSubmenuOptions(submenu)
end

---Adds the chat customization submenu to the context menu.
---@param context ISContextMenu
local function addChatCustomizationSettings(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local option = context:addOption(getText('UI_OmiChat_context_chat_customization'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    if Option.EnableCustomShouts then
        addCustomCalloutOptions(submenu)
    end

    if Option.EnableSetNameColor or Option.EnableSpeechColorAsDefaultNameColor then
        local nameColorOptName = OmiChat.getNameColorsEnabled()
            and getText('UI_OmiChat_context_disable_name_colors')
            or getText('UI_OmiChat_context_enable_name_colors')

        submenu:addOption(nameColorOptName, instance, ISChat.onToggleShowNameColor)
    end

    if not Option.EnableCharacterCustomization then
        addSignEmoteOption(submenu)
    end

    if #submenu.options == 0 then
        -- no submenu options → just add the color option to the top-level menu
        context:removeLastOption()
        submenu = context
    end

    addColorOptions(submenu)
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

    local option = context:addOption(getText('UI_OmiChat_context_character_customization'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    addSignEmoteOption(submenu)

    local cleanOptName = getText('UI_OmiChat_context_clean')
    submenu:addOption(cleanOptName, instance, ISChat.onCleanCharacter)

    local hairColorOptName = getText('UI_OmiChat_context_hair_color')
    submenu:addOption(hairColorOptName, instance, ISChat.onHairColorMenu)

    local growHairOptName = getText('UI_OmiChat_context_grow_hair')
    submenu:addOption(growHairOptName, instance, ISChat.onGrowHair)

    if not player:isFemale() then
        local growBeardOptName = getText('UI_OmiChat_context_grow_beard')
        submenu:addOption(growBeardOptName, instance, ISChat.onGrowBeard)
    end
end

---Returns the non-empty lines of a string.
---If there are no non-empty lines, returns `nil`.
---@param text string
---@param maxLen integer?
---@return string[]?
local function getLines(text, maxLen)
    if not text then
        return
    end

    local lines = {}
    for line in text:gmatch('[^\n]+\n?') do
        line = utils.trim(line)
        if maxLen and #line > maxLen then
            lines[#lines + 1] = line:sub(1, maxLen)
        elseif #line > 0 then
            lines[#lines + 1] = line
        end
    end

    if #lines == 0 then
        return
    end

    return lines
end

---Checks whether the player is dead or unavailable.
---@return boolean
local function isPlayerDead()
    local player = getSpecificPlayer(0)
    return not player or player:isDead()
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

    -- update clothing
    local items = player:getWornItems()
    for i = 0, items:size() - 1 do
        local item = items:getItemByIndex(i)
        local itemVisual = item and instanceof(item, 'Clothing') and item:getVisual()
        if itemVisual then
            local parts = getCoveredParts(item:getBloodClothingType())

            for j = 0, parts:size() - 1 do
                local part = parts:get(j)
                itemVisual:setDirt(part, 0)
                itemVisual:setBlood(part, 0)
            end
        end
    end

    player:resetModel()
    sendVisual(player)
    sendClothing(player)
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

    local text = getText('UI_OmiChat_context_hair_color_desc')
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

---Event handler for color menu initialization.
---@param target omichat.ISChat
---@param category omichat.ColorCategory The target color category.
function ISChat.onCustomColorMenu(target, category)
    if target.activeColorModal then
        target.activeColorModal:destroy()
    end

    local color = OmiChat.getColorOrDefault(category)
    local text = getTextOrNull('UI_OmiChat_context_color_desc_' .. category)
    if not text then
        local catName = getTextOrNull('UI_OmiChat_context_message_type_' .. category) or
            OmiChat.getColorCategoryCommand(category)
        text = getText('UI_OmiChat_context_color_desc', catName)
    end

    local width = max(450, getTextManager():MeasureStringX(UIFont.Small, text) + 60)
    local modal = ColorModal:new(0, 0, width, 250, text, color, target, ISChat.onCustomColorMenuClick, 0, category)

    modal:setMinValue(category == 'speech' and 48 or 0)
    modal:setEmptyColor(Option:getDefaultColor(category))
    modal:initialise()
    modal:addToUIManager()

    target.activeColorModal = modal
end

---Event handler for color picker selection.
---@param target omichat.ISChat
---@param button table
---@param category omichat.ColorCategory The color category that has been changed.
---@diagnostic disable-next-line: unused-local
function ISChat.onCustomColorMenuClick(target, button, category)
    if button.internal == 'OK' then
        OmiChat.changeColor(category, button.parent:getColorTable())

        if category ~= 'name' and category ~= 'speech' then
            OmiChat.redrawMessages()
        end
    end
end

---Event handler for accepting the custom callout dialog.
---@param target omichat.ISChat
---@param button table
---@param category omichat.CalloutCategory
---@diagnostic disable-next-line: unused-local
function ISChat.onCustomCalloutClick(target, button, category)
    if button.internal ~= 'OK' then
        return
    end

    local maxLen = Option.CustomShoutMaxLength > 0 and Option.CustomShoutMaxLength or nil
    local lines = getLines(button.parent.entry:getText(), maxLen)
    if not lines then
        lines = nil
    end

    if lines and category == 'sneakcallouts' then
        for i = 1, #lines do
            lines[i] = lines[i]:lower()
        end
    end

    OmiChat.setCustomShouts(lines, category)
end

---Event handler for custom callout menu initialization.
---@param target omichat.ISChat
---@param category omichat.CalloutCategory
function ISChat.onCustomCalloutMenu(target, category)
    if target.activeCalloutModal then
        target.activeCalloutModal:destroy()
    end

    local shouts = OmiChat.getCustomShouts(category)
    local defaultText = shouts and concat(shouts, '\n') or ''

    local numLines = Option.MaximumCustomShouts
    if numLines <= 0 then
        numLines = Option:getDefault('MaximumCustomShouts') or 1
    elseif numLines > 20 then
        numLines = 20
    end

    local textManager = getTextManager()
    local boxHeight = 4 + textManager:getFontHeight(UIFont.Medium) * numLines

    local desc = getText('UI_OmiChat_context_set_custom_callouts_desc')

    local width = 500
    local height = boxHeight + 100
    local x = getPlayerScreenLeft(0) + (getPlayerScreenWidth(0) - width) / 2
    local y = getPlayerScreenTop(0) + (getPlayerScreenHeight(0) - height) / 2
    local modal = ISTextBox:new(x, y, width, height, desc, defaultText, target, ISChat.onCustomCalloutClick, 0, category)

    modal:setValidateFunction(modal, ISChat.validateCustomCalloutText)
    modal:setMultipleLine(numLines > 1)
    modal:setNumberOfLines(numLines)
    modal:initialise()

    modal.entry:setMaxLines(numLines)
    if category == 'callouts' then
        modal.entry:setForceUpperCase(true)
    end

    modal:addToUIManager()
    target.activeCalloutModal = modal
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

    -- check to see whether the last command should be cleared based on this change
    for i = 1, #instance.tabs do
        local chatText = instance.tabs[i]
        local lastChatCommand = chatText.lastChatCommand

        if lastChatCommand then
            local stream = OmiChat.chatCommandToStream(lastChatCommand, true)
            local commandType = stream and stream:getCommandType()
            if commandType == type then
                chatText.lastChatCommand = ''
            end
        end
    end
end

---Event handler for toggling showing name colors.
---@param target omichat.ISChat
---@diagnostic disable-next-line: unused-local
function ISChat.onToggleShowNameColor(target)
    OmiChat.setNameColorEnabled(not OmiChat.getNameColorsEnabled())
    OmiChat.redrawMessages()
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

    local languages = OmiChat.getRoleplayLanguages()
    local languageTranslated = utils.getTranslatedLanguageName(language)
    local text = getText('UI_OmiChat_context_confirm_add_language', languageTranslated, #languages + 1)
    local width, height = ISModalDialog.CalcSize(0, 0, text)
    local x = getPlayerScreenLeft(0) + (getPlayerScreenWidth(0) - width) / 2
    local y = getPlayerScreenTop(0) + (getPlayerScreenHeight(0) - height) / 2

    local modal = ISModalDialog:new(x, y, width, height, text, true, target, ISChat.onConfirmAddLanguage, 0, language)

    modal:initialise()
    modal:addToUIManager()
    target.activeLanguageModal = modal
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

---Validation function for custom callout menu.
---@param target ISTextBox
---@param text string
---@return boolean
function ISChat.validateCustomCalloutText(target, text)
    local lines = getLines(text)
    if not lines then
        return true
    end

    if #lines > Option.MaximumCustomShouts then
        target:setValidateTooltipText(getText('UI_OmiChat_error_too_many_shouts', tostring(Option.MaximumCustomShouts)))
        return false
    end

    for i = 1, #lines do
        if #lines[i] > Option.CustomShoutMaxLength then
            local maxLen = tostring(Option.CustomShoutMaxLength)
            target:setValidateTooltipText(getText('UI_OmiChat_error_shout_too_long', maxLen))
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

        if Option:compatChatBubbleEnabled() and message:getText():match('^%[img=media/textures/bubble%d%.png%]$') then
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
    end
end

---Override to add custom components.
function ISChat:createChildren()
    _createChildren(self)

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
    self:addChild(self.infoButton)
    self.infoButton:setVisible(false)

    self.suggesterBox = SuggesterBox:new(0, 0, 0, 0)
    self.suggesterBox:setOnMouseDownFunction(self, self.onSuggesterSelect)
    self.suggesterBox:setAlwaysOnTop(true)
    self.suggesterBox:setUIName('chat suggester box')
    self.suggesterBox:addToUIManager()
    self.suggesterBox:setVisible(false)

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

    if tryInputSuggestedItem() then
        OmiChat.updateCustomComponents()
        return
    end

    local instance = ISChat.instance ---@cast instance omichat.ISChat
    local input = instance.textEntry:getText()
    local stream, command, chatCommand, hasDisabled = OmiChat.chatCommandToStream(input, true, true)

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
        local emoteToPlay, start, finish = OmiChat.getEmoteFromCommand(command)
        if emoteToPlay then
            -- remove the emote text
            shouldHandle = true
            command = utils.trim(command:sub(1, start - 1) .. command:sub(finish + 1))

            local player = getSpecificPlayer(0)
            if player then
                player:playEmote(emoteToPlay)
                playedEmote = true
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

    if hasDisabled then
        OmiChat.addInfoMessage('Unknown command ' .. command:sub(2))
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
            stream = callbackStream,
            command = command,
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
    addLanguageOptions(context)
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
    if not tryInputSuggestedItem() then
        text = OmiChat.cycleStream()
        local entry = ISChat.instance.textEntry
        entry:setText(text)
    end

    OmiChat.updateCustomComponents(text)
end

---Override to update custom components and include aliases.
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

---Override to hide icon picker and disable button on unfocus.
function ISChat:unfocus()
    _unfocus(self)
    OmiChat.hideSuggesterBox()
    OmiChat.setIconButtonEnabled(false)
end

---Override to improve performance of text refresh.
function ISChat:updateChatPrefixSettings()
    updateChatSettings(self.chatFont, self.showTimestamp, self.showTitle)
    OmiChat.redrawMessages()
end

--#endregion
