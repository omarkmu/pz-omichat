---Handles operations on the chat UI.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Core/Client'
local StatusDisplay = require 'OmiChat/Component/UI/StatusDisplay'
local ProfileManager = require 'OmiChat/Component/UI/ProfileManager'
local PlayerDataManager = require 'OmiChat/Component/UI/PlayerDataManager'
local ConfigurationLogic = require 'OmiChat/Component/Configuration/Logic'
local callback = require 'OmiChat/Module/Client/Callbacks'
local RangeDisplay = require 'OmiChat/Component/UI/RangeDisplay'

local utils = API.utils
local UI_LIB = utils.ui
local config = API.Configuration
local MultiMap = utils.MultiMap

local max = math.max
local sort = table.sort
local concat = table.concat
local getTimestampMs = getTimestampMs
local getTextVanilla = getText
local getText = utils.getText
local getServerOptions = getServerOptions
local getTileFromMouse = UIManager.getTileFromMouse
local getSquare = getSquare
local getMouseXScaled = getMouseXScaled
local getMouseYScaled = getMouseYScaled
local textManager = getTextManager()
local ISChat = ISChat --[[@as omichat.ISChat]]


---@class api.client.ui
---@field suggestBox? omi.SuggestBox The auto-suggest box for the chat input.
---@field private _configPanel? omi.forms.Form The configuration panel.
---@field private _typingDisplay? string The current display text for the typing indicator.
---@field private _language string? The current language for the language indicator.
---@field private _rangeDisplay RangeDisplay? The range display instance.
local UI = {}

---Contains functions for controlling the chat window and related UI components.
API.ui = UI

--#region Static Fields

---The font used for the typing indicator.
UI.typingFont = UIFont.Small

---The height of the font used for the typing indicator.
UI.typingFontHgt = textManager:getFontHeight(UI.typingFont)

---Flag for whether statuses are enabled.
---@private
UI._statusEnabled = false

---Associates usernames to display UI elements.
---@type table<string, StatusDisplay>
---@private
UI._statusDisplayByUsername = {}

---List of custom buttons added to the chat window.
---@type ISButton[]
---@private
UI._customButtons = {}

---Associates chat types to title string IDs.
UI._chatTypeTitleIDs = {
    general = 'UI_chat_general_chat_title_id',
    whisper = 'UI_chat_private_chat_title_id',
    say = 'UI_chat_local_chat_title_id',
    shout = 'UI_chat_local_chat_title_id',
    faction = 'UI_chat_faction_chat_title_id',
    safehouse = 'UI_chat_safehouse_chat_title_id',
    radio = 'UI_chat_radio_chat_title_id',
    admin = 'UI_chat_admin_chat_title_id',
    server = 'UI_chat_server_chat_title_id',
}

--#endregion


---Returns the associated title ID for a chat type.
---@param chatType omi.ChatTypeString The chat type to retrieve the title for.
---@return string stringID
function UI.chatTypeToTitleID(chatType)
    return UI._chatTypeTitleIDs[chatType]
end

---Determines the color options that should be enabled based on the server configuration.
---@param all boolean? If given, all possible color options will be returned instead.
---@return string[] idList List of color option names. These are stream names, or `speech` for the speech color.
function UI.getColorOptions(all)
    local colorOpts = {}

    colorOpts[#colorOpts + 1] = 'speech'
    colorOpts[#colorOpts + 1] = 'server'

    if all then
        colorOpts[#colorOpts + 1] = 'discord'
        colorOpts[#colorOpts + 1] = 'radio'
    else
        if config:canShowDiscordColorOption() then
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
    end

    for stream in API.streams.chatStreams() do
        if all or stream:checkPlayerCanCustomize() then
            colorOpts[#colorOpts + 1] = stream:getName()
        end
    end

    return colorOpts
end

---Generates the admin configuration menu, or returns an already generated menu.
---@return omi.forms.Form panel
function UI.getConfigPanel()
    if UI._configPanel then
        return UI._configPanel
    end

    local w, h = 800, 600
    local x, y = UI_LIB.getScreenCenter(w, h)
    local schema = config:getSchema()
    local panel = schema:generateForm {
        x = x,
        y = y,
        w = w,
        h = h,
        destroyOnClose = false,
        values = config:getValuesForSave(),
        onSave = API.callback.onConfigurationSave,
        onClose = API.callback.onConfigurationClose,
        onUpdate = API.callback.onConfigurationUpdate,
    }

    panel:initialise()
    panel:setVisible(false)
    UI._configPanel = panel

    return panel
end

---Gets the text that should display when clicking the info button.
---@param player IsoPlayer? The player to use to populate token values. If this is `nil`, player 1 will be used.
---@return string richText
function UI.getInfoRichText(player)
    player = player or API.player.get()
    if not player then
        return ''
    end

    local tokens = API.data.getPlayerSubstitutions(player)
    if not tokens then
        return ''
    end

    local name = API.data.getPlayerNameInChat(player, 'say')
    tokens.name = name and utils.escapeRichText(name) or ''
    return utils.trim(utils.interpolateNoEntities(config.General.InfoText, tokens, player:getUsername()))
end

---Returns the current display string for the typing indicator.
---@param maxWidth number? The maximum width of the text.
---@return string? display
function UI.getTypingDisplay(maxWidth)
    local display = UI._typingDisplay
    if display and maxWidth and textManager:MeasureStringX(UIFont.Small, display) > maxWidth then
        display = utils.interpolateNamed('TypingIndicator', config.TypingIndicator.Format, { alt = '1' })
    end

    return display
end

---Hides the auto-suggest box if it's currently visible.
function UI.hideSuggestBox()
    if UI.suggestBox then
        UI.suggestBox:setVisible(false)
    end
end

---Opens the mod configuration window.
function UI.openConfiguration()
    local instance = ISChat.instance
    if not instance then
        return
    end

    local isNew = false
    local form = instance.activeConfigurationPanel
    if not form then
        form = API.ui.getConfigPanel()
        instance.activeConfigurationPanel = form
        isNew = true
    end

    local isVisible = form:isReallyVisible()
    if isNew or not isVisible then
        local x, y = UI_LIB.getScreenCenter(800, 600)
        form:setX(x)
        form:setY(y)
    end

    if isVisible then
        ConfigurationLogic.refreshForm(form)
        form:bringToTop()
        return
    end

    ConfigurationLogic.refreshForm(form, config:getValuesForSave())
    form:setVisible(true)
    form:addToUIManager()
end

---Opens the player data manager admin utility window.
function UI.openPlayerDataManager()
    local instance = ISChat.instance
    if not instance then
        return
    end

    if instance.activePlayerDataPanel then
        instance.activePlayerDataPanel:destroy()
    end

    local x, y = UI_LIB.getScreenCenter(1200, 650)
    local panel = PlayerDataManager:new({
        x = x,
        y = y,
        w = 1200,
        h = 650,
    })

    panel:initialise()
    panel:addToUIManager()
    instance.activePlayerDataPanel = panel
end

---Opens the profile manager window.
function UI.openProfileManager()
    local instance = ISChat.instance
    if not instance then
        return
    end

    if instance.activeProfilesPanel then
        instance.activeProfilesPanel:destroy()
    end

    local x, y = UI_LIB.getScreenCenter(800, 600)
    local panel = ProfileManager:new({
        x = x,
        y = y,
        w = 800,
        h = 600,
        profiles = API.preferences.getProfiles(),
    })

    panel:initialise()
    panel:addToUIManager()
    instance.activeProfilesPanel = panel
end

---Redraws the current chat messages.
---@param doScroll boolean? Flag for whether the chat should also be scrolled to the bottom. Defaults to `true`.
function UI.redraw(doScroll)
    if not ISChat.instance then
        return
    end

    for i = 1, #ISChat.instance.tabs do
        local chatText = ISChat.instance.tabs[i]
        local messages = chatText.chatMessages
        local newText = {}
        local newLines = {}

        local start = 1 + max(0, #messages - ISChat.maxLine - 1)
        for j = start, #messages do
            local message = messages[j]
            local text = message:getTextWithPrefix()

            if message:isShowInChat() then
                newText[#newText + 1] = text
                newLines[#newLines + 1] = text .. ' <LINE> '
            end
        end

        chatText.chatTextLines = newLines
        chatText.text = concat(newText, ' <LINE> ')

        chatText:paginate()
    end

    if doScroll ~= false then
        -- fix scroll position
        UI.scrollToBottom()
    end
end

---Sets the scroll position of all chat tabs to the bottom.
function UI.scrollToBottom()
    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return
    end

    for i = 1, #tabs do
        local tab = tabs[i]
        tab:setYScroll(-tab:getScrollHeight())
    end
end

---Sets the scroll position of all chat tabs to the top.
function UI.scrollToTop()
    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return
    end

    for i = 1, #tabs do
        local tab = tabs[i]
        tab:setYScroll(0)
    end
end

---Shows the range indicator for the given range.
---@param range integer
function UI.showRangeIndicator(range)
    local player = API.player.get()
    if not player then
        return
    end

    if not UI._rangeDisplay then
        UI._rangeDisplay = RangeDisplay:new(player)
        UI._rangeDisplay:initialise()
    end

    local display = UI._rangeDisplay
    display:show(range, player)
end

---Creates and populates the context menu for chat settings.
function UI.showSettingsContextMenu()
    local x = getMouseX()
    local y = getMouseY()
    local context = ISContextMenu.get(0, x, y)

    UI._addAdminOptions(context)
    UI._addChatSettings(context)
    UI._addCustomizationSettings(context)
    UI._addProfileSwitchSubmenu(context)
    UI._addLanguageOptions(context)

    if API.hooks.has.chatSettingsMenu then
        API.hooks.chatSettingsMenu('main', context)
    end

    return context
end

---Toggles visibility of the info dialog.
---If no info text is set, or it resolves to the empty string, this hides the info dialog.
function UI.toggleInfo()
    local instance = ISChat.instance
    if not instance then
        return
    end

    local text = UI.getInfoRichText()
    instance:setInfo(text)

    local infoDialog = instance.infoRichText
    if text == '' then
        if infoDialog then
            infoDialog:removeFromUIManager()
        end

        return
    end

    if not infoDialog then
        infoDialog = UI_LIB.dialog {
            w = 600,
            h = 600,
            text = instance.infoText,
            richText = true,
            alwaysOnTop = true,
            moveWithMouse = false,
            setHeightToContents = true,
            backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        }

        ---@cast infoDialog.chatText -?
        infoDialog.chatText:setOnAction(instance, API.callback.onInfoPanelAction)
        infoDialog.chatText:setOnUpdate(instance, API.callback.onInfoPanelUpdate)

        instance.infoRichText = infoDialog
        return
    end

    if infoDialog:isReallyVisible() then
        infoDialog:removeFromUIManager()
    else
        infoDialog:setVisible(true)
        infoDialog:addToUIManager()
    end
end

---Updates the visibility and positions of custom buttons.
function UI.updateButtons()
    local instance = ISChat.instance
    if not instance or not instance.gearButton then
        return
    end

    instance.rangeButton:setVisible(config.General.IncludeRangeIndicatorButton)

    local th = instance:titleBarHeight()
    local lastBtn = instance.gearButton
    for i = 1, #UI._customButtons do
        local btn = UI._customButtons[i]
        if btn:getParent() ~= instance then
            instance:addChild(btn)
        end

        if btn:isVisible() then
            local pad = max(lastBtn:getWidth(), th)
            btn:setX(lastBtn:getX() - pad * 1.5)
            lastBtn = btn
        end
    end
end

---Updates the chat panel size based on the configured options.
function UI.updateChatPanelSize()
    local instance = ISChat.instance
    if not instance then
        return
    end

    local oldTabCnt = instance.tabCnt
    if oldTabCnt == 1 then
        -- calcTabSize assumes calling before increment
        instance.tabCnt = 0
    end

    local size = instance:calcTabSize()
    instance.tabCnt = oldTabCnt

    local height = size.height
    if config.TypingIndicator.Enable and API.preferences.getShowTyping() then
        height = height - UI.typingFontHgt - 4
    end

    for i = 1, #instance.tabs do
        local tab = instance.tabs[i]
        if tab.tabID == 0 then
            tab:setHeight(height)
        end
    end
end

---Updates the suggester box.
function UI.updateComponents()
    UI.updateSuggesterComponent()
end

---Updates the info text to the configured value.
---@param player IsoPlayer? The player to use to populate token values. If this is `nil`, player 1 will be used.
function UI.updateInfoText(player)
    local instance = ISChat.instance
    if not instance then
        return
    end

    instance:setInfo(UI.getInfoRichText(player))
end

---Updates the language indicator text.
---@param force boolean? Flag for whether the indicator should be updated even if the language hasn't changed.
function UI.updateLanguageIndicator(force)
    local instance = ISChat.instance
    local entry = instance and instance.textEntry
    if not entry then
        return
    end

    local color = utils.color.integerToDecimal(config.Language.PlaceholderColor)
    entry:setPlaceholderRGBA(color.r, color.g, color.b, 1)

    local language = API.player.getCurrentLanguage() or API.language.getDefault()
    if not force and language == UI._language then
        return
    end

    UI._language = language

    local display = ''
    if language then
        local tokens = {
            rawLanguage = language,
            language = utils.getTranslatedLanguageName(language),
        }

        display = utils.interpolateNamed(
            'LanguagePlaceholder',
            config.Language.PlaceholderFormat,
            tokens
        )

        display = display:trim()
    end

    if display == '' then
        entry:setPlaceholderText(nil)
        return
    end

    entry:setPlaceholderText(display)
end

---Updates UI elements to match configuration.
---@param redraw boolean? Flag for whether the chat messages should be redrawn.
function UI.updateState(redraw)
    if not ISChat.instance then
        return
    end

    UI._updateChatVisibility()
    UI.updateChatPanelSize()
    UI.updateInfoText()
    UI.updateButtons()
    UI.updateLanguageIndicator(true)

    if redraw then
        -- some configuration options affect how messages are drawn
        UI.redraw(false)
    end
end

---Shows or hides the suggester based on user preferences.
function UI.updateSuggesterComponent()
    local suggesterBox = UI.suggestBox
    if not suggesterBox then
        return
    end

    if not API.preferences.getUseSuggester() then
        suggesterBox:setVisible(false)
        return
    end
end

---Updates the display string for typing players based on the current typing information.
function UI.updateTypingDisplay()
    if not config.TypingIndicator.Enable or not API.preferences.getShowTyping() then
        UI._typingDisplay = nil
        return
    end

    local list = {}
    local inactive = {}

    local now = getTimestampMs()
    for username, info in pairs(API._typingInfo) do
        if now - info.lastUpdate >= 5000 then
            inactive[#inactive + 1] = username
        else
            list[#list + 1] = info.display
        end
    end

    for _, username in pairs(inactive) do
        API._typingInfo[username] = nil
    end

    if #list == 0 then
        UI._typingDisplay = nil
        return
    end

    local entries = {}
    sort(list)
    for i = 1, #list do
        entries[#entries + 1] = {
            key = i,
            value = list[i],
        }
    end

    local tokens = {
        names = MultiMap:new(entries),
    }

    local text = utils.interpolateNamed('TypingIndicator', config.TypingIndicator.Format, tokens) ---@type string?
    if text == '' then
        text = nil
    end

    UI._typingDisplay = text
end


---Adds context menu options for admin controls.
---@param context ISContextMenu
---@private
function UI._addAdminOptions(context)
    if not API.player.isChatAdmin() then
        return
    end

    local submenuName = getText('context-admin')
    local submenuOption = context:addOption(submenuName, ISChat.instance)

    local submenu = context:getNew(context)
    context:addSubMenu(submenuOption, submenu)

    local playerDataName = getText('context-admin-view-player-data')
    submenu:addOption(playerDataName, nil, UI.openPlayerDataManager)

    local settingsName = getText('context-admin-open-settings')
    submenu:addOption(settingsName, nil, UI.openConfiguration)

    local adminOptionName = getText('context-admin-show-icon')
    local opt = submenu:addOption(adminOptionName, ISChat.instance, callback.toggleAdminShowIcon)
    submenu:setOptionChecked(opt, API.preferences.getShowAdminIcon())

    adminOptionName = getText('context-admin-know-all-languages')
    opt = submenu:addOption(adminOptionName, ISChat.instance, callback.toggleAdminUnderstandLanguages)
    submenu:setOptionChecked(opt, API.preferences.getUnderstandAllLanguages())

    adminOptionName = getText('context-admin-ignore-message-range')
    opt = submenu:addOption(adminOptionName, ISChat.instance, callback.toggleAdminIgnoreRange)
    submenu:setOptionChecked(opt, API.preferences.getIgnoreMessageRange())

    if API.hooks.has.chatSettingsMenu then
        API.hooks.chatSettingsMenu('admin', submenu)
    end
end

---Adds the chat settings submenu to the context menu.
---@param context ISContextMenu
---@private
function UI._addChatSettings(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local option = context:addOption(getText('context-chat-settings'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    local timestampOptName = instance.showTimestamp
        and getTextVanilla('UI_chat_context_disable_timestamp')
        or getTextVanilla('UI_chat_context_enable_timestamp')
    local tagOptName = instance.showTitle
        and getTextVanilla('UI_chat_context_disable_tags')
        or getTextVanilla('UI_chat_context_enable_tags')

    submenu:addOption(timestampOptName, instance, ISChat.onToggleTimestampPrefix)
    submenu:addOption(tagOptName, instance, ISChat.onToggleTagPrefix)

    if config.TypingIndicator.Enable then
        local typingOptName = API.preferences.getShowTyping()
            and getText('context-disable-typing-indicator')
            or getText('context-enable-typing-indicator')
        submenu:addOption(typingOptName, instance, callback.toggleShowTyping)
    end

    UI._addSuggestionOptions(submenu)
    UI._addRetainOptions(submenu)
    UI._addVanillaSubmenuOptions(submenu)

    if API.hooks.has.chatSettingsMenu then
        API.hooks.chatSettingsMenu('basic', submenu)
    end
end

---Adds the customization submenu to the context menu.
---@param context ISContextMenu
---@private
function UI._addCustomizationSettings(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local player = API.player.get()
    if not player then
        return
    end

    local option = context:addOption(getText('context-customization'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    -- chat customization
    UI._addSignEmoteOption(submenu)

    if config.Customization.EnableNameColors then
        local nameColorOptName = API.preferences.getNameColorsEnabled()
            and getText('context-disable-name-colors')
            or getText('context-enable-name-colors')

        submenu:addOption(nameColorOptName, instance, callback.toggleShowNameColor)
    end

    local manageOptName = getText('context-manage-profiles')
    submenu:addOption(manageOptName, nil, UI.openProfileManager)

    -- character customization
    if config.Customization.EnableCharacterCustomization then
        if config:isCleanCustomizationEnabled() then
            local cleanOptName = getText('context-clean')
            submenu:addOption(cleanOptName, 'CLEAN_CHARACTER', API.request.applyCustomization)
        end

        local hairColorOptName = getText('context-hair-color')
        submenu:addOption(hairColorOptName, instance, callback.openHairColorDialog)

        local growHairOptName = getText('context-grow-hair')
        submenu:addOption(growHairOptName, 'GROW_HAIR', API.request.applyCustomization)

        if not player:isFemale() then
            local growBeardOptName = getText('context-grow-beard')
            submenu:addOption(growBeardOptName, 'GROW_BEARD', API.request.applyCustomization)
        end
    end

    if API.hooks.has.chatSettingsMenu then
        API.hooks.chatSettingsMenu('customization', submenu)
    end
end

---Adds the context menu options for roleplay languages.
---@param context ISContextMenu
---@private
function UI._addLanguageOptions(context)
    local languages = API.player.getLanguages()
    local languageSlots = math.min(API.player.getLanguageSlots(), config.MAX_LANGUAGE_SLOTS)

    local isKnown = {}
    local knownLanguages = {} ---@type string[]
    for i = 1, #languages do
        local lang = languages[i]
        if API.language.exists(lang) then
            knownLanguages[#knownLanguages + 1] = lang
            isKnown[lang] = true
        end
    end

    local addLanguages = {} ---@type any[]
    if languageSlots - #knownLanguages >= 1 then
        local allLanguages = API.language.getList()
        for i = 1, #allLanguages do
            local lang = allLanguages[i]
            if not isKnown[lang] and config:canAddLanguage(lang) then
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

    if #knownLanguages <= 1 and #addLanguages == 0 then
        return
    end

    local languageOptionName = getText('context-languages')
    local languageOption = context:addOption(languageOptionName, ISChat.instance)
    local languageSubmenu = context:getNew(context)
    context:addSubMenu(languageOption, languageSubmenu)

    local currentLang = API.player.getCurrentLanguage() or API.language.getDefault()
    for i = 1, #knownLanguages do
        local lang = knownLanguages[i]
        local name = utils.getTranslatedLanguageName(lang)
        local opt = languageSubmenu:addOption(name, ISChat.instance, callback.switchLanguage, lang)
        languageSubmenu:setOptionChecked(opt, lang == currentLang)
    end

    if #addLanguages > 0 then
        sort(addLanguages, function(a, b) return a.translated < b.translated end)

        local addLanguageSubmenu = languageSubmenu:getNew(languageSubmenu)
        local addLanguageOption = languageSubmenu:addOption(getText('context-add-language'), ISChat.instance)
        languageSubmenu:addSubMenu(addLanguageOption, addLanguageSubmenu)
        for i = 1, #addLanguages do
            local lang = addLanguages[i].language
            local name = addLanguages[i].translated
            addLanguageSubmenu:addOption(name, ISChat.instance, callback.openLanguageConfirmation, lang)
        end
    end

    if API.hooks.has.chatSettingsMenu then
        API.hooks.chatSettingsMenu('language', languageSubmenu)
    end

    if #languageSubmenu.options == 0 then
        context:removeLastOption()
    end
end

---Adds the submenu for switching between player preference profiles.
---@param context ISContextMenu
---@private
function UI._addProfileSwitchSubmenu(context)
    local instance = ISChat.instance
    local profiles = API.preferences.getProfiles()
    if #profiles == 0 then
        return
    end

    local submenuName = getText('context-profiles')
    local submenuOption = context:addOption(submenuName, instance)
    local submenu = context:getNew(context)
    context:addSubMenu(submenuOption, submenu)

    local currentIndex = API.preferences.getCurrentProfileIndex()
    local option = submenu:addOption(getText('context-profile-default'), instance, callback.switchProfile, 0)
    submenu:setOptionChecked(option, currentIndex == nil)

    for i = 1, #profiles do
        local profile = profiles[i]
        option = submenu:addOption(profile.name, instance, callback.switchProfile, i)
        submenu:setOptionChecked(option, i == currentIndex)
    end
end

---Adds the context menu options for retaining commands.
---@param context ISContextMenu
---@private
function UI._addRetainOptions(context)
    local retainOption = context:addOption(getText('context-retain-commands'), ISChat.instance)

    local retainSubmenu = context:getNew(context)
    context:addSubMenu(retainOption, retainSubmenu)

    ---@type StreamCategory[]
    local categories = {
        'chat',
        'rp',
        'other',
    }

    for i = 1, #categories do
        local cat = categories[i]
        local name = getText('context-retain-commands-' .. cat)
        local opt = retainSubmenu:addOption(name, ISChat.instance, callback.toggleRetainCommand, cat)
        retainSubmenu:setOptionChecked(opt, API.preferences.getRetainCommand(cat))
    end
end

---Adds the context menu option for enabling or disabling sign language emote animations.
---@param context ISContextMenu
---@private
function UI._addSignEmoteOption(context)
    local foundSigned = false
    local languages = API.player.getLanguages()
    for i = 1, #languages do
        if API.language.isSigned(languages[i]) then
            foundSigned = true
            break
        end
    end

    local defaultLang = not foundSigned and API.language.getDefault()
    if defaultLang then
        foundSigned = API.language.isSigned(defaultLang)
    end

    if not foundSigned then
        return
    end

    local suffix = API.preferences.getSignEmotesEnabled() and 'disable' or 'enable'
    local optName = getText('context-sign-emotes-' .. suffix)
    local option = context:addOption(optName, ISChat.instance, callback.toggleUseSignEmotes)
    option.toolTip = ISToolTip:new()
    option.toolTip.description = getText('context-sign-emotes-tooltip')
end

---Adds the context menu options for suggestions.
---@param context ISContextMenu
---@private
function UI._addSuggestionOptions(context)
    local instance = ISChat.instance
    local isUseSuggester = API.preferences.getUseSuggester()
    if not isUseSuggester then
        local optName = getText('context-suggestions-enable')
        context:addOption(optName, instance, callback.toggleUseSuggester)
        return
    end

    local suggestOption = context:addOption(getText('context-suggestions'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(suggestOption, submenu)

    local disableOptName = getText('context-suggestions-disable')
    local onEnterOptName = getText('context-suggestions-on-enter')
    local onTabOptName = getText('context-suggestions-on-tab')

    submenu:addOption(disableOptName, instance, callback.toggleUseSuggester)

    local onEnterOpt = submenu:addOption(onEnterOptName, instance, callback.toggleSuggestOnEnter)
    local onTabOpt = submenu:addOption(onTabOptName, instance, callback.toggleSuggestOnTab)
    submenu:setOptionChecked(onEnterOpt, API.preferences.getSuggestOnEnter())
    submenu:setOptionChecked(onTabOpt, API.preferences.getSuggestOnTab())

    if API.hooks.has.chatSettingsMenu then
        API.hooks.chatSettingsMenu('suggestions', submenu)
    end
end

---Adds the chat setting submenus from vanilla.
---From ISChat.
---@param context ISContextMenu
---@private
function UI._addVanillaSubmenuOptions(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local fontSizeOption = context:addOption(getTextVanilla('UI_chat_context_font_submenu_name'), instance)
    local fontSubmenu = context:getNew(context)
    context:addSubMenu(fontSizeOption, fontSubmenu)
    fontSubmenu:addOption(getTextVanilla('UI_chat_context_font_small'), instance, ISChat.onFontSizeChange, 'small')
    fontSubmenu:addOption(getTextVanilla('UI_chat_context_font_medium'), instance, ISChat.onFontSizeChange, 'medium')
    fontSubmenu:addOption(getTextVanilla('UI_chat_context_font_large'), instance, ISChat.onFontSizeChange, 'large')

    ---@cast fontSubmenu.options table<integer, any>
    if instance.chatFont == 'small' then
        fontSubmenu:setOptionChecked(fontSubmenu.options[1], true)
    elseif instance.chatFont == 'medium' then
        fontSubmenu:setOptionChecked(fontSubmenu.options[2], true)
    elseif instance.chatFont == 'large' then
        fontSubmenu:setOptionChecked(fontSubmenu.options[3], true)
    end

    local minOpaqueOption = context:addOption(getTextVanilla('UI_chat_context_opaque_min'), instance)
    local minOpaqueSubmenu = context:getNew(context)
    context:addSubMenu(minOpaqueOption, minOpaqueSubmenu)
    local opaques = { 0, 0.25, 0.5, 0.75, 1 } ---@type number[]
    for i = 1, #opaques do
        if logTo01(opaques[i]) <= instance.maxOpaque then
            local optName = (opaques[i] * 100) .. '%'
            local option = minOpaqueSubmenu:addOption(optName, instance, ISChat.onMinOpaqueChange, opaques[i])
            local current = math.floor(instance.minOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                minOpaqueSubmenu:setOptionChecked(option, true)
            end
        end
    end

    local maxOpaqueOption = context:addOption(getTextVanilla('UI_chat_context_opaque_max'), instance)
    local maxOpaqueSubmenu = context:getNew(context)
    context:addSubMenu(maxOpaqueOption, maxOpaqueSubmenu)
    for i = 1, #opaques do
        if logTo01(opaques[i]) >= instance.minOpaque then
            local optName = (opaques[i] * 100) .. '%'
            local option = maxOpaqueSubmenu:addOption(optName, instance, ISChat.onMaxOpaqueChange, opaques[i])
            local current = math.floor(instance.maxOpaque * 1000)
            local value = math.floor(logTo01(opaques[i]) * 1000)
            if current == value then
                maxOpaqueSubmenu:setOptionChecked(option, true)
            end
        end
    end

    local fadeTimeOption = context:addOption(getTextVanilla('UI_chat_context_opaque_fade_time_submenu_name'), instance)
    local fadeTimeSubmenu = context:getNew(context)
    context:addSubMenu(fadeTimeOption, fadeTimeSubmenu)
    local availFadeTime = { 0, 1, 2, 3, 5, 10 }
    local optionName = getTextVanilla('UI_chat_context_disable')
    local option = fadeTimeSubmenu:addOption(optionName, instance, ISChat.onFadeTimeChange, 0)
    if instance.fadeTime == 0 then
        fadeTimeSubmenu:setOptionChecked(option, true)
    end

    for i = 2, #availFadeTime do
        local time = availFadeTime[i]
        option = fadeTimeSubmenu:addOption(time .. ' s', instance, ISChat.onFadeTimeChange, time)
        if instance.fadeTime == time then
            fadeTimeSubmenu:setOptionChecked(option, true)
        end
    end

    local opaqueOnFocusOption = context:addOption(getTextVanilla('UI_chat_context_opaque_on_focus'), instance)
    local opaqueOnFocusSubmenu = context:getNew(context)
    context:addSubMenu(opaqueOnFocusOption, opaqueOnFocusSubmenu)
    opaqueOnFocusSubmenu:addOption(getTextVanilla('UI_chat_context_disable'), instance, ISChat.onFocusOpaqueChange, false)
    opaqueOnFocusSubmenu:addOption(getTextVanilla('UI_chat_context_enable'), instance, ISChat.onFocusOpaqueChange, true)

    local opt = opaqueOnFocusSubmenu.options[instance.opaqueOnFocus and 2 or 1] ---@cast opt -?
    opaqueOnFocusSubmenu:setOptionChecked(opt, true)
end

---Creates additional children for the chat.
---@param instance ISChat
---@private
function UI._createChildren(instance)
    local th = instance:titleBarHeight()

    instance.infoButton = UI_LIB.button {
        parent = instance,
        x = instance.gearButton:getX() - th / 2 - th,
        w = th,
        h = th,
        anchorRight = true,
        anchorLeft = false,
        borderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0 },
        backgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        backgroundColorMouseOver = { r = 0.3, g = 0.3, b = 0.3, a = 0 },
        image = instance.infoBtn,
        uiName = 'chat info button',
        visible = false,
        target = instance,
        onClick = instance.onInfo,
    }

    instance.rangeButton = UI_LIB.button {
        parent = instance,
        x = instance.infoButton:getX() - th / 2 - th,
        w = th,
        h = th,
        anchorRight = true,
        anchorLeft = false,
        borderColor = { r = 0.7, g = 0.7, b = 0.7, a = 0 },
        backgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        backgroundColorMouseOver = { r = 0.3, g = 0.3, b = 0.3, a = 0 },
        image = getTexture('media/ui/OmiChat/range.png'),
        uiName = 'chat range button',
        visible = false,
        target = instance,
        onClick = API.callback.onRangeClick,
    }

    API.extension.addCustomButton(instance.rangeButton)
    API.extension.addCustomButton(instance.infoButton)

    -- replace the text entry so we can add the suggest box
    instance:removeChild(instance.textEntry)

    local inset, EdgeSize, fontHgt = instance.inset, 5, instance.fontHgt
    local height = EdgeSize * 2 + fontHgt
    instance.textEntry = UI_LIB.textEntry {
        parent = instance,
        uiName = ISChat.textEntryName,
        x = inset,
        y = instance:getHeight() - 8 - inset - height,
        w = instance:getWidth() - inset * inset,
        h = height,
        font = UIFont.Medium,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        borderColor = { r = 1, g = 1, b = 1, a = 0.0 },
        hasFrame = true,
        anchorTop = false,
        anchorBottom = true,
        anchorRight = true,
        target = instance,
        onCommand = ISChat.onCommandEntered,
        onChange = ISChat.onTextChange,
        onPressDown = ISChat.onPressDown,
        onPressUp = ISChat.onPressUp,
        onOtherKey = ISChat.onOtherKey,
        onClick = ISChat.onMouseDown,
        editable = false,
    }

    UI.suggestBox = UI_LIB.suggestBox {
        entry = instance.textEntry,
        openUpwards = true,
        populateAfterInsert = true,
        suggestOnTab = false, -- handled in `onSwitchStream`
        suggestOnEnter = API.preferences.getSuggestOnEnter(),
        target = instance,
        populate = API.callback.populateChatSuggestBox,
    }
end

---Gets a set of objects the mouse is hovering over.
---This does not use the same logic as the name hovering functionality, since that requires Reflection.
---@return omi.SetTable<IsoMovingObject>
---@private
function UI._getHoveringObjects()
    local player = getSpecificPlayer(0)
    if not player then
        return {}
    end

    local z = player:getZ()
    local tile = getTileFromMouse(getMouseXScaled(), getMouseYScaled(), z)
    local square = getSquare(tile:getX(), tile:getY(), z)
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

---Updates the visibility of the chat and close button based on the `Always Show Chat` option.
---@private
function UI._updateChatVisibility()
    local instance = ISChat.instance
    if not instance or not instance.closeButton then
        return
    end

    local closeBtn = instance.closeButton
    local alwaysShowChat = config.General.AlwaysShowChat
    if closeBtn and closeBtn:isVisible() == alwaysShowChat then
        closeBtn:setVisible(not alwaysShowChat)
    end

    if alwaysShowChat then
        instance:setVisible(true)
    end
end

---Updates status display elements based on mouse hover.
---Called on every UI update.
---@private
function UI._updateStatusDisplays()
    local statusEnabled = config.Commands.Status.Enable
    if not statusEnabled and not UI._statusEnabled then
        return
    end

    UI._statusEnabled = statusEnabled

    local players = getOnlinePlayers()
    local selfPlayer = API.player.get()
    if not players or not selfPlayer then
        return
    end

    -- update display cache
    local onlineSet = {}
    local displayCache = UI._statusDisplayByUsername
    local range = config.Commands.Status.Range
    local hoverSet = UI._getHoveringObjects()
    for i = 0, players:size() - 1 do
        local onlinePlayer = players:get(i) ---@type IsoPlayer
        local username = onlinePlayer:getUsername()

        onlineSet[onlinePlayer] = true
        local display = displayCache[username]
        if not display then
            display = StatusDisplay:new(onlinePlayer)
            display:initialise()
            display:addToUIManager()

            displayCache[username] = display
        end

        local show = hoverSet[onlinePlayer] and display:shouldShow(onlinePlayer, range) or false
        display:setVisible(show)
    end

    for username, display in pairs(displayCache) do
        local onlinePlayer = display.target
        if not statusEnabled or not onlineSet[onlinePlayer] then
            -- player is unavailable or feature is disabled; remove the display
            display:destroy()
            displayCache[username] = nil
        end
    end
end


utils.setIntervalUI(UI._updateStatusDisplays)
return UI

--#region Type Definitions

---@alias SettingCategory
---| 'basic'
---| 'customization'
---| 'language'
---| 'admin'
---| 'suggestions'
---| 'main'

--#endregion
