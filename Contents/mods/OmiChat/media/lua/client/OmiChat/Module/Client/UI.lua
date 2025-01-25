---Handles operations on the chat UI.

local API = require 'OmiChat/Module/Client/Core' ---@class omichat.api.client
local callback = require 'OmiChat/Module/Client/Callbacks'
local SuggesterBox = API.SuggesterBox

local max = math.max
local min = math.min
local sort = table.sort
local concat = table.concat
local getTexture = getTexture
local getTimestampMs = getTimestampMs
local getServerOptions = getServerOptions
local textManager = getTextManager()
local ISChat = ISChat ---@cast ISChat omichat.ISChat

local utils = API.utils
local config = API.Configuration
local IconPicker = API.IconPicker
local MultiMap = utils.MultiMap


---@class omichat.api.client.ui
local UI = {}

UI._customButtons = {}
UI._iconsToExclude = {
    -- shadowed by colors
    thistle = true,
    salmon = true,
    tomato = true,
    orange = true,

    -- doesn't work/often not included by collectAllIcons
    boilersuitblue = true,
    boilersuitred = true,
    glovesleatherbrown = true,
    jumpsuitprisonkhaki = true,
    jumpsuitprisonorange = true,
    jacketgreen = true,
    jacketlongblack = true,
    jacketlongbrown = true,
    jacketvarsity_alpha = true,
    jacketvarsity_ky = true,
    shirtdenimblue = true,
    shirtdenimlightblue = true,
    shirtdenimlightblack = true,
    shirtlumberjackblue = true,
    shirtlumberjackgreen = true,
    shirtlumberjackgrey = true,
    shirtlumberjackred = true,
    shirtlumberjackyellow = true,
    shirtscrubsblue = true,
    shirtscrubsgreen = true,
    shortsathleticblue = true,
    shortsathleticgreen = true,
    shortsathleticred = true,
    shortsathleticyellow = true,
    shortsdenimblack = true,
    shortslongathleticgreen = true,
    tshirtathleticblue = true,
    tshirtathleticred = true,
    tshirtathleticyellow = true,
    tshirtathleticgreen = true,
    trousersscrubsblue = true,
    trousersscrubsgreen = true,

    -- visually identical to other icons
    tz_mayonnaisefullrotten = true,
    tz_mayonnaisehalf = true,
    tz_mayonnaisehalfrotten = true,
    tz_remouladefullrotten = true,
    tz_remouladehalf = true,
    tz_remouladehalfrotten = true,
    glovecompartment = true,
    truckbed = true,
    fishcatfishcooked = true,
    fishcatfishoverdone = true,
    fishcrappiecooked = true,
    fishpanfishcooked = true,
    fishpanfishoverdone = true,
    fishperchcooked = true,
    fishperchoverdone = true,
    fishpikecooked = true,
    fishpikeoverdone = true,
    fishtroutcooked = true,
    fishtroutoverdone = true,
    tvdinnerburnt = true,
    tvdinnerrotten = true,

    -- shows up overhead as text
    composter = true,
    clothingdryer = true,
    clothingwasher = true,
    mailbox = true,
    mannequin = true,
    toolcabinet = true,
}
UI._settingHandlers = {
    admin = {},
    basic = {},
    customization = {},
    language = {},
    suggestions = {},
    main = {},
}


local chatTypeTitleIDs = {
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


---Returns the associated title ID for a chat type.
---@param chatType omichat.ChatTypeString
---@return string
function UI.chatTypeToTitleID(chatType)
    return chatTypeTitleIDs[chatType]
end

---Clears the current chat messages.
---@param tabID integer? The 0-indexed ID of the tab to clear. If `nil`, all tabs are cleared.
function UI.clear(tabID)
    local tabs = ISChat.instance and ISChat.instance.tabs
    if not tabs then
        return
    end

    for i = 1, #tabs do
        local chatText = tabs[i]

        if not tabID or chatText.tabID == tabID then
            chatText.chatMessages = {}
            chatText.chatTextLines = {}
            chatText.text = ''
            chatText:paginate()
        end
    end
end

---Creates additional children for the chat.
---@param instance omichat.ISChat
function UI.createChildren(instance)
    UI.typingFont = UIFont.Small
    UI.typingFontHgt = getTextManager():getFontHeight(UI.typingFont)

    local th = instance:titleBarHeight()
    local infoButton = ISButton:new(instance.gearButton:getX() - th / 2 - th, 0, th, th, '', instance, instance.onInfo)
    infoButton.anchorRight = true
    infoButton.anchorLeft = false
    infoButton:initialise()
    infoButton.borderColor.a = 0.0
    infoButton.backgroundColor.a = 0.0
    infoButton.backgroundColorMouseOver.a = 0
    infoButton:setImage(instance.infoBtn)
    infoButton:setUIName('chat info button')
    infoButton:setVisible(false)

    local suggesterBox = SuggesterBox:new(0, 0, 0, 0)
    suggesterBox:setOnMouseDownFunction(instance, API.callback.onSuggesterSelect)
    suggesterBox:setAlwaysOnTop(true)
    suggesterBox:setUIName('chat suggester box')
    suggesterBox:addToUIManager()
    suggesterBox:setVisible(false)

    instance.infoButton = infoButton
    UI.suggesterBox = suggesterBox

    API.extension.addCustomButton(infoButton)
end

---Hides the suggester box if it's currently visible.
function UI.hideSuggesterBox()
    local suggesterBox = UI.suggesterBox
    if suggesterBox then
        suggesterBox:setVisible(false)
    end
end

---Determines the color options that should be enabled based on the server configuration.
---@param all boolean? If given, all possible color options will be returned instead.
---@return string[]
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
        if all or stream:checkPlayerCanUse() then
            colorOpts[#colorOpts + 1] = stream:getName()
        end
    end

    return colorOpts
end

---Gets the text that should display when clicking the info button.
---@param player IsoPlayer? The player to use to populate token values. If `nil`, this will be player 1.
---@return string
function UI.getInfoRichText(player)
    player = player or getSpecificPlayer(0)
    if not player then
        return ''
    end

    local tokens = API.data.getPlayerSubstitutions(player)
    if not tokens then
        return ''
    end

    local name = API.data.getPlayerNameInChat(player, 'say')
    tokens.name = name and utils.escapeRichText(name) or ''
    return utils.interpolate(config.General.InfoText, tokens, player:getUsername())
end

---Returns the current leftmost chat button.
---@return ISButton?
function UI.getLeftmostButton()
    if UI._leftmostBtn then
        return UI._leftmostBtn
    end

    local instance = ISChat.instance
    if instance then
        return instance.gearButton
    end
end

---Returns the current display string for the typing indicator.
---@param maxWidth integer?
---@return string?
function UI.getTypingDisplay(maxWidth)
    local display = UI._typingDisplay
    if display and maxWidth and textManager:MeasureStringX(UIFont.Small, display) > maxWidth then
        display = utils.interpolate(config.TypingIndicator.Format, { alt = true })
    end

    return display
end

---Redraws the current chat messages.
---@param doScroll boolean? Whether the chat should also be scrolled to the bottom. Defaults to `true`.
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

---Sets whether the icon picker button is enabled.
---If the button is disabled, the icon picker component will also be hidden.
---@param enable boolean?
function UI.setIconButtonEnabled(enable)
    local iconButton = UI.iconButton
    if not iconButton then
        return
    end

    local value = enable and 0.8 or 0.3
    iconButton:setTextureRGBA(value, value, value, 1)
    iconButton.enable = enable

    local iconPicker = UI.iconPicker
    if not enable and iconPicker then
        iconPicker:setVisible(false)
    end
end

---Sets the icons that should be excluded by the icon picker.
---This does not update the icon picker icons.
---@see omichat.IconPicker.updateIcons
---@param icons table<string, true>?
function UI.setIconsToExclude(icons)
    UI._iconsToExclude = icons or {}
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
    UI._runSettingsHandlers(context, 'main')

    return context
end

---Updates the positions of custom buttons.
function UI.updateButtons()
    local instance = ISChat.instance
    if not instance or not instance.gearButton then
        return
    end

    local th = instance:titleBarHeight()
    local lastBtn = instance.gearButton
    for i = 1, #UI._customButtons do
        local btn = UI._customButtons[i]
        if btn:getParent() ~= instance then
            instance:addChild(btn)
        end

        if btn:isVisible() then
            local pad = max(lastBtn:getWidth(), th)
            btn:setX(lastBtn:getX() - pad - pad / 2)
            lastBtn = btn
        end
    end

    UI._leftmostBtn = lastBtn
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

---Updates the icon picker and suggester box based on the current input text.
---@param text string? The current text entry text. If omitted, the current text will be retrieved.
function UI.updateCustomComponents(text)
    local instance = ISChat.instance
    if not instance then
        return
    end

    text = text or instance.textEntry:getInternalText()

    UI.updateIconComponents(text)
    UI.updateSuggesterComponent(text)
end

---Enables or disables the icon picker based on the current input.
---@param text string? The current text entry text.
function UI.updateIconComponents(text)
    local instance = ISChat.instance
    if not instance or not UI.iconButton then
        return
    end

    text = text or instance.textEntry:getInternalText()
    local stream = API.streams.chatCommandToStream(text)

    if not stream then
        stream = API.streams.getDefaultTabStream(instance.currentTabID)
    end

    UI.setIconButtonEnabled(false)
end

---Updates the info text to the configured value.
---@param player IsoPlayer?
function UI.updateInfoText(player)
    local instance = ISChat.instance
    if not instance then
        return
    end

    instance:setInfo(UI.getInfoRichText(player))
end

---Updates UI elements to match configuration.
---@param redraw boolean? If true, chat messages will be redrawn.
function UI.updateState(redraw)
    if not ISChat.instance then
        return
    end

    UI._addOrRemoveIconComponents()
    UI._updateChatVisibility()
    UI.updateChatPanelSize()
    UI.updateInfoText()
    UI.updateButtons()

    if redraw then
        -- some configuration options affect how messages are drawn
        UI.redraw(false)
    end
end

---Shows or hides the suggester based on the current input.
---@param text string? The current text entry text. If omitted, the current text will be retrieved.
function UI.updateSuggesterComponent(text)
    local instance = ISChat.instance
    local suggesterBox = UI.suggesterBox
    if not instance or not suggesterBox then
        return
    end

    if not API.preferences.getUseSuggester() then
        suggesterBox:setVisible(false)
        return
    end

    text = text or instance.textEntry:getInternalText()
    local suggestions = API.chat.getSuggestions(text)
    if #suggestions == 0 then
        suggesterBox:setVisible(false)
        return
    end

    suggesterBox:setSuggestions(suggestions)
    suggesterBox:setWidth(instance:getWidth())
    suggesterBox:setHeight(suggesterBox.itemheight * min(#suggestions, 5))
    suggesterBox:setX(instance:getX())
    suggesterBox:setY(instance:getY() + instance.textEntry:getY() - suggesterBox.height)
    suggesterBox:setVisible(true)
    suggesterBox:bringToTop()

    if suggesterBox.vscroll then
        suggesterBox.vscroll:setHeight(suggesterBox.height)
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

    local text = utils.interpolate(config.TypingIndicator.Format, tokens) ---@type string?
    if text == '' then
        text = nil
    end

    UI._typingDisplay = text
end


---Creates or removes the icon button and picker from the chat box based on sandbox options.
---@private
function UI._addOrRemoveIconComponents()
    local instance = ISChat.instance
    if not instance then
        return
    end

    local add = false
    local iconPicker = UI.iconPicker
    local iconButton = UI.iconButton
    local epIncludeMisc = iconPicker and iconPicker.includeUnknownAsMiscellaneous
    local includeMisc = false
    if iconPicker and epIncludeMisc ~= includeMisc then
        iconPicker.includeUnknownAsMiscellaneous = includeMisc
        iconPicker:updateIcons()
    end

    if add and iconButton then
        return
    end

    if not add and not iconButton then
        return
    end

    if add then
        local size = math.floor(instance.textEntry.height * 0.75)
        iconButton = ISButton:new(
            instance.width - size * 1.25 - 2.5,
            instance.textEntry.y + instance.textEntry.height * 0.5 - size * 0.5 + 1,
            size,
            size,
            '',
            instance,
            callback.openIconPicker
        )

        instance.textEntry.width = instance.textEntry.width - size * 1.5
        instance.textEntry.javaObject:setWidth(instance.textEntry.width)

        iconButton.anchorRight = true
        iconButton.anchorBottom = true
        iconButton.anchorLeft = false
        iconButton.anchorTop = false

        iconButton:initialise()
        iconButton.borderColor.a = 0
        iconButton.backgroundColor.a = 0
        iconButton.backgroundColorMouseOver.a = 0
        iconButton:setImage(getTexture('Item_PlushSpiffo'))
        iconButton:setTextureRGBA(0.3, 0.3, 0.3, 1)
        iconButton:setUIName('chat icon button')
        instance:addChild(iconButton)

        iconButton:bringToTop()

        iconPicker = IconPicker:new(0, 0, instance, callback.onIconClick)
        iconPicker.exclude = UI._iconsToExclude
        iconPicker.includeUnknownAsMiscellaneous = false

        iconPicker:initialise()
        iconPicker:addToUIManager()
        iconPicker:setVisible(false)

        UI.iconButton = iconButton
        UI.iconPicker = iconPicker

        return
    end

    instance.textEntry.width = instance:getWidth() - instance.inset * 2
    instance.textEntry.javaObject:setWidth(instance.textEntry.width)

    if iconButton then
        instance:removeChild(iconButton)
        iconButton:setVisible(false)
        iconButton:removeFromUIManager()
        iconButton = nil
    end

    if iconPicker then
        iconPicker:setVisible(false)
        iconPicker:removeFromUIManager()
        iconPicker = nil
    end
end

---Adds context menu options for admin controls.
---@param context ISContextMenu
---@private
function UI._addAdminOptions(context)
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

    local submenu = context:getNew(context)
    context:addSubMenu(adminOption, submenu)

    local manageName = getText('UI_OmiChat_ContextAdminManageModData')
    submenu:addOption(manageName, ISChat.instance, callback.openModDataManager)

    local optionsName = getText('UI_OmiChat_ContextAdminUpdateConfiguration')
    submenu:addOption(optionsName, ISChat.instance, callback.openConfiguration)

    for i = 1, #options do
        local option = options[i]
        local name = getText('UI_OmiChat_ContextAdmin_' .. option)
        local opt = submenu:addOption(name, ISChat.instance, callback.toggleAdminOption, option)
        submenu:setOptionChecked(opt, API.preferences.getAdminOption(option))
    end

    UI._runSettingsHandlers(submenu, 'admin')
end

---Adds the chat settings submenu to the context menu.
---@param context ISContextMenu
---@private
function UI._addChatSettings(context)
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

    if config.TypingIndicator.Enable then
        local typingOptName = API.preferences.getShowTyping()
            and getText('UI_OmiChat_ContextDisableTypingIndicator')
            or getText('UI_OmiChat_ContextEnableTypingIndicator')
        submenu:addOption(typingOptName, instance, callback.toggleShowTyping)
    end

    UI._addSuggestionOptions(submenu)
    UI._addRetainOptions(submenu)
    UI._addVanillaSubmenuOptions(submenu)
    UI._runSettingsHandlers(submenu, 'basic')
end

---Adds the customization submenu to the context menu.
---@param context ISContextMenu
---@private
function UI._addCustomizationSettings(context)
    local instance = ISChat.instance
    if not instance then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local option = context:addOption(getText('UI_OmiChat_ContextCustomization'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    -- chat customization
    UI._addSignEmoteOption(submenu)

    if config.Customization.EnableNameColors then
        local nameColorOptName = API.preferences.getNameColorsEnabled()
            and getText('UI_OmiChat_ContextDisableNameColors')
            or getText('UI_OmiChat_ContextEnableNameColors')

        submenu:addOption(nameColorOptName, instance, callback.toggleShowNameColor)
    end

    local manageOptName = getText('UI_OmiChat_ContextManageProfiles')
    submenu:addOption(manageOptName, instance, callback.openProfileManager)

    -- character customization
    if config.Customization.EnableCharacterCustomization then
        if config:isCleanCustomizationEnabled() then
            local cleanOptName = getText('UI_OmiChat_ContextClean')
            submenu:addOption(cleanOptName, instance, callback.cleanCharacter)
        end

        local hairColorOptName = getText('UI_OmiChat_ContextHairColor')
        submenu:addOption(hairColorOptName, instance, callback.openHairColorDialog)

        local growHairOptName = getText('UI_OmiChat_ContextGrowHair')
        submenu:addOption(growHairOptName, instance, callback.growHair)

        if not player:isFemale() then
            local growBeardOptName = getText('UI_OmiChat_ContextGrowBeard')
            submenu:addOption(growBeardOptName, instance, callback.growBeard)
        end
    end

    UI._runSettingsHandlers(submenu, 'customization')
end

---Runs settings handlers on a context menu or submenu.
---@param context ISContextMenu
---@param category omichat.SettingCategory
function UI._runSettingsHandlers(context, category)
    local handlers = UI._settingHandlers[category]
    if not handlers then
        return
    end

    for i = 1, #handlers do
        handlers[i](context)
    end
end

---Adds the context menu options for roleplay languages.
---@param context ISContextMenu
---@private
function UI._addLanguageOptions(context)
    local languages = API.player.getLanguages()
    local languageSlots = math.min(API.player.getLanguageSlots(), config.MAX_LANGUAGE_SLOTS)

    local isKnown = {}
    local knownLanguages = {}
    for i = 1, #languages do
        local lang = languages[i]
        if API.language.exists(lang) then
            knownLanguages[#knownLanguages + 1] = lang
            isKnown[lang] = true
        end
    end

    local addLanguages = {}
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

    if #knownLanguages == 0 and #addLanguages == 0 then
        return
    end

    local languageOptionName = getText('UI_OmiChat_ContextLanguages')
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
        table.sort(addLanguages, function(a, b) return a.translated < b.translated end)

        local addLanguageSubmenu = languageSubmenu:getNew(languageSubmenu)
        local addLanguageOption = languageSubmenu:addOption(getText('UI_OmiChat_ContextAddLanguage'), ISChat.instance)
        languageSubmenu:addSubMenu(addLanguageOption, addLanguageSubmenu)
        for i = 1, #addLanguages do
            local lang = addLanguages[i].language
            local name = addLanguages[i].translated
            addLanguageSubmenu:addOption(name, ISChat.instance, callback.openLanguageConfirmation, lang)
        end
    end

    UI._runSettingsHandlers(languageSubmenu, 'language')

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

    local submenuName = getText('UI_OmiChat_ContextProfiles')
    local submenuOption = context:addOption(submenuName, instance)
    local submenu = context:getNew(context)
    context:addSubMenu(submenuOption, submenu)

    local currentIndex = API.preferences.getCurrentProfileIndex()
    local option = submenu:addOption(getText('UI_OmiChat_ContextProfileDefault'), instance, callback.switchProfile, 0)
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
    local retainOption = context:addOption(getText('UI_OmiChat_ContextRetainCommands'), ISChat.instance)

    local retainSubmenu = context:getNew(context)
    context:addSubMenu(retainOption, retainSubmenu)

    local categories = {
        'chat',
        'rp',
        'other',
    }

    for i = 1, #categories do
        local cat = categories[i]
        local name = getText('UI_OmiChat_ContextRetainCommands_' .. cat)
        local opt = retainSubmenu:addOption(name, ISChat.instance, callback.toggleRetainCommand, cat)
        retainSubmenu:setOptionChecked(opt, API.preferences.getRetainCommand(cat))
    end
end

---Adds the context menu option for enabling/disabling sign language emote animations.
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

    local suffix = API.preferences.getSignEmotesEnabled() and 'Disable' or 'Enable'
    local optName = getText('UI_OmiChat_ContextSignEmotes' .. suffix)
    local option = context:addOption(optName, ISChat.instance, callback.toggleUseSignEmotes)
    option.toolTip = ISToolTip:new()
    option.toolTip.description = getText('UI_OmiChat_ContextSignEmotesTooltip')
end

---Adds the context menu options for suggestions.
---@param context ISContextMenu
---@private
function UI._addSuggestionOptions(context)
    local instance = ISChat.instance
    local isUseSuggester = API.preferences.getUseSuggester()
    if not isUseSuggester then
        local optName = getText('UI_OmiChat_ContextSuggestions_Enable')
        context:addOption(optName, instance, callback.toggleUseSuggester)
        return
    end

    local suggestOption = context:addOption(getText('UI_OmiChat_ContextSuggestions'), instance)
    local submenu = context:getNew(context)
    context:addSubMenu(suggestOption, submenu)

    local disableOptName = getText('UI_OmiChat_ContextSuggestions_Disable')
    local onEnterOptName = getText('UI_OmiChat_ContextSuggestions_OnEnter')
    local onTabOptName = getText('UI_OmiChat_ContextSuggestions_OnTab')

    submenu:addOption(disableOptName, instance, callback.toggleUseSuggester)

    local onEnterOpt = submenu:addOption(onEnterOptName, instance, callback.toggleSuggestOnEnter)
    local onTabOpt = submenu:addOption(onTabOptName, instance, callback.toggleSuggestOnTab)
    submenu:setOptionChecked(onEnterOpt, API.preferences.getSuggestOnEnter())
    submenu:setOptionChecked(onTabOpt, API.preferences.getSuggestOnTab())

    UI._runSettingsHandlers(submenu, 'suggestions')
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

    local fontSizeOption = context:addOption(getText('UI_chat_context_font_submenu_name'), instance)
    local fontSubmenu = context:getNew(context)
    context:addSubMenu(fontSizeOption, fontSubmenu)
    fontSubmenu:addOption(getText('UI_chat_context_font_small'), instance, ISChat.onFontSizeChange, 'small')
    fontSubmenu:addOption(getText('UI_chat_context_font_medium'), instance, ISChat.onFontSizeChange, 'medium')
    fontSubmenu:addOption(getText('UI_chat_context_font_large'), instance, ISChat.onFontSizeChange, 'large')
    if instance.chatFont == 'small' then
        fontSubmenu:setOptionChecked(fontSubmenu.options[1], true)
    elseif instance.chatFont == 'medium' then
        fontSubmenu:setOptionChecked(fontSubmenu.options[2], true)
    elseif instance.chatFont == 'large' then
        fontSubmenu:setOptionChecked(fontSubmenu.options[3], true)
    end

    local minOpaqueOption = context:addOption(getText('UI_chat_context_opaque_min'), instance)
    local minOpaqueSubmenu = context:getNew(context)
    context:addSubMenu(minOpaqueOption, minOpaqueSubmenu)
    local opaques = { 0, 0.25, 0.5, 0.75, 1 }
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

    local maxOpaqueOption = context:addOption(getText('UI_chat_context_opaque_max'), instance)
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

    local fadeTimeOption = context:addOption(getText('UI_chat_context_opaque_fade_time_submenu_name'), instance)
    local fadeTimeSubmenu = context:getNew(context)
    context:addSubMenu(fadeTimeOption, fadeTimeSubmenu)
    local availFadeTime = { 0, 1, 2, 3, 5, 10 }
    local optionName = getText('UI_chat_context_disable')
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

    local opaqueOnFocusOption = context:addOption(getText('UI_chat_context_opaque_on_focus'), instance)
    local opaqueOnFocusSubmenu = context:getNew(context)
    context:addSubMenu(opaqueOnFocusOption, opaqueOnFocusSubmenu)
    opaqueOnFocusSubmenu:addOption(getText('UI_chat_context_disable'), instance, ISChat.onFocusOpaqueChange, false)
    opaqueOnFocusSubmenu:addOption(getText('UI_chat_context_enable'), instance, ISChat.onFocusOpaqueChange, true)
    opaqueOnFocusSubmenu:setOptionChecked(opaqueOnFocusSubmenu.options[instance.opaqueOnFocus and 2 or 1], true)
end

---Updates the visibility of the chat and close button based on the `Always Show Chat` option.
---@private
function UI._updateChatVisibility()
    local instance = ISChat.instance
    if not instance or not instance.closeButton then
        return
    end

    local closeBtn = ISChat.instance.closeButton
    local alwaysShowChat = config.General.AlwaysShowChat
    if closeBtn and closeBtn:isVisible() == alwaysShowChat then
        closeBtn:setVisible(not alwaysShowChat)
    end

    if alwaysShowChat then
        ISChat.instance:setVisible(true)
    end
end


API.ui = UI
return UI
