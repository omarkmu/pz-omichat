---@namespace omichat
---Helper functions for the configuration form and schema.

local utils = require 'OmiChat/Utils'

local TagList = require 'OmiChat/Definition/TagList'
local FormatData = require 'OmiChat/Definition/NamedFormatData'
local DefaultLanguages = require 'OmiChat/Definition/DefaultLanguageList'
local DefaultStreams = require 'OmiChat/Definition/DefaultStreamList'
local DefaultStreamData = require 'OmiChat/Definition/DefaultStreamData'

local sort = table.sort
local concat = table.concat
local MIDDOT = string.char(183) .. ' <SPACE> '

local API_C ---@type api.client?


local Helpers = {}


---Applies values from a preset to the form.
---@param form omi.forms.Form The current form.
---@param preset ConfigurationPreset The preset to apply.
function Helpers.applyPreset(form, preset)
    local values = form.values
    local id = preset:getID()

    -- get info text value before setting values
    local infoText = form:getValue('General.InfoText')

    -- ensure ID matches expected preset ID
    local presetValues = preset:getValues()
    presetValues.General = presetValues.General or {}
    presetValues.General.Preset = id

    form:setValues(presetValues)

    -- keep the existing info text when applying a built-in preset
    if not preset:isCustom() then
        values.General = values.General or {}
        values.General.InfoText = infoText
        form:setControlValue('General.InfoText', infoText)
    end

    form:setStatusMessage(getText('Sandbox_OmiChat_status_preset', preset:getName()))
end

---Creates a new item for the stream list.
---@return Configuration.StreamDefinition item The new item.
function Helpers.createStreamItem()
    ---@type Configuration.StreamDefinition
    local item = {
        Enable = true,
        Stream = 'custom',
        ChatType = 'say',
        Category = 'chat',
        OverheadFormat = '$Default()',
        ChatFormat = '$Default()',
        DefaultColor = { r = 255, g = 255, b = 255 },
        Range = 30,
        VerticalRange = 2,
        PerceptionRange = 0,
        PerceptionRangeSigned = 0,
    }

    return item
end

---Deletes a custom user-defined preset.
---@param form omi.forms.Form The current form.
---@param state ConfigurationFormState The current form state.
---@param value string The current preset name.
function Helpers.deletePreset(form, state, value)
    if not utils.startsWith(value, 'custom:') then
        return
    end

    API_C = API_C or utils.getAPI()
    local lib = utils.lib --[[@as omi.client]]

    if state.activePresetDialog then
        state.activePresetDialog:destroy()
    end

    local name = value:sub(8)
    local dialog = lib.ui.yesNoDialog {
        w = 400,
        h = 100,
        text = getText('UI_OmiChat_DeletePreset_Confirm', name),
        onClick = function(_, args)
            if args.internal ~= 'YES' then
                return
            end

            API_C.extension.removeCustomPreset(name, true)

            local currentValue = form:getValue('General.Preset')
            if currentValue == value then
                Helpers.refreshPresetsList(form)

                local values = form.values
                values.General.Preset = 'Default'
                form:setControlValue('General.Preset', 'Default')
            end
        end,
    }

    form:removeOnDestroy(dialog)
    state.activePresetDialog = dialog
end

---Returns a list of default language definition objects.
---@return Configuration.LanguageDefinition[]
function Helpers.getDefaultLanguages()
    return utils.copyList(DefaultLanguages)
end

---Returns a list of default stream objects.
---@return Configuration.StreamDefinition[]
function Helpers.getDefaultStreams()
    return utils.copyList(DefaultStreams)
end

---Returns a list of default stream objects, populated with required data.
---@return Configuration.StreamDefinition[]
function Helpers.getDefaultStreamsPopulated()
    return Helpers.processStreams(utils.copyList(DefaultStreams))
end

---Gets a final list of format data translations.
---@param list (string | FormatDataTranslation)[]?
---@param prefix string
---@return FormatDataTranslation[]
function Helpers.getFormatDataTranslations(list, prefix)
    if not list or #list == 0 then
        return {}
    end

    local index = {}
    local result = {}
    for i = 1, #list do
        local data = list[i]
        if type(data) == 'string' then
            data = {
                name = data,
                id = prefix .. data,
            }
        end

        local replaceIdx = index[data.name]
        if replaceIdx then
            -- overwrite previous instance of the token if already seen
            result[replaceIdx] = data
        else
            result[#result + 1] = data
        end

        index[data.name] = i
    end

    sort(result, function(a, b)
        return a.name:upper() < b.name:upper()
    end)

    return result
end

---Gets the display string to use for an item in the language listbox.
---@param args omi.forms.Args.Callback.Item
---@return string
function Helpers.getLanguageListDisplay(args)
    local item = args.value or {} ---@type Configuration.LanguageDefinition

    if not utils.isNilOrWhitespace(item.Name) then
        return item.Name
    end

    return getText('Sandbox_OmiChat_Language_untitled')
end

---Gets a list of options for the preset configuration value.
---@return omi.ui.Dropdown.Option[]
function Helpers.getPresetOptions()
    API_C = API_C or utils.getAPI()

    local list = {} ---@type omi.ui.Dropdown.Option[]
    local presetList = API_C.Configuration:getPresetList()
    for i = 1, #presetList do
        local preset = presetList[i]

        list[#list + 1] = {
            data = preset:getID(),
            text = preset:getName(),
            tooltip = preset:isCustom() and getText('UI_OmiChat_PresetUserDefined') or nil,
        }
    end

    return list
end

---Gets the chat type associated with a built-in stream.
---@param stream string?
---@return omi.ChatTypeString?
function Helpers.getStreamChatType(stream)
    if not stream then
        return
    end

    local data = DefaultStreamData[stream]
    return data and data.ChatType
end

---Gets the command type associated with a built-in stream.
---@param stream string?
---@return StreamCategory?
function Helpers.getStreamCategory(stream)
    if not stream then
        return
    end

    local data = DefaultStreamData[stream]
    return data and data.Category
end

---Gets a display string for an item in the stream listbox.
---@param args omi.forms.Args.Callback.Item
---@return string
function Helpers.getStreamDisplay(args)
    local item = args.value or {} ---@type Configuration.StreamDefinition
    if not item.Stream or item.Stream == 'custom' then
        return not utils.isNilOrWhitespace(item.Name) and item.Name or 'custom'
    end

    return item.Stream
end

---Gets the tooltip to use for a tag.
---@param tag string
---@return string tooltip
---@return boolean isKnownTag
function Helpers.getTagTooltip(tag)
    local desc = getTextOrNull('Sandbox_OmiChat_tag_' .. tag)
    local isKnown = desc ~= nil

    desc = desc or getText('Sandbox_OmiChat_tag_unknown')
    local color = isKnown and ' <PUSHRGB:0,0.5,1> ' or ' <PUSHRGB:0.93,0.824,0> '

    return color .. tag .. ' <POPRGB> <LINE> ' .. desc, isKnown
end

---Called to initialize format options in the configuration form.
---@param args omi.forms.Args.Callback.Item
function Helpers.initFormatOption(args)
    local info = args.info
    local button = info.infoButton
    if not button then
        return
    end

    local key = concat(info.path, '_')
    local data = FormatData[key]
    if not data then
        data = {}
        utils.log.error('Missing format data for option %s', key)
    end

    local rope = {
        getText('Sandbox_OmiChat_format_option_heading'),
    }

    local tokens = {}
    if data.tokens then
        tokens = utils.copyList(data.tokens)
    end

    if data.canSetError then
        tokens[#tokens + 1] = 'error'
        tokens[#tokens + 1] = 'errorID'
    end

    Helpers.writeFormatDataTranslations(
        getText('Sandbox_OmiChat_tokens'),
        Helpers.getFormatDataTranslations(tokens, 'Sandbox_OmiChat_token_'),
        data.tokenDescription,
        rope
    )

    Helpers.writeFormatDataTranslations(
        getText('Sandbox_OmiChat_options'),
        Helpers.getFormatDataTranslations(data.options, 'Sandbox_OmiChat_option_'),
        data.optionDescription,
        rope
    )

    if #rope > 1 then
        rope[#rope + 1] = '\n'
    end

    button.tooltip = concat(rope)
end

---Called when a language name changes in the language listbox.
---@param args omi.forms.Args.Callback.Item
function Helpers.onChangeLanguageName(args)
    local control = args.form:getFieldControl('Language.List.Name') --[[@as omi.ui.TextEntry?]]
    if not control then
        return
    end

    -- only show required input error after edit
    local oldText = control:getText()
    local currentText = control:getInternalText():trim()
    if #oldText > 0 and #currentText == 0 then
        control:setRequireValue(true)
    end
end

---Called when the preset option dropdown changes.
---@param args omi.forms.Args.Callback.Item
function Helpers.onChangePreset(args)
    local info = args.info
    local deleteBtn = info.actionButtons and info.actionButtons[3]
    if not deleteBtn then
        return
    end

    deleteBtn:setEnabled(utils.startsWith(args.value, 'custom:'))
end

---Called when a value in a stream changes.
---@param args omi.forms.Args.Callback.Item
function Helpers.onChangeStream(args)
    local form = args.form
    local item = args.parent ---@type Configuration.StreamDefinition?
    local index = args.index
    if not item or not index then
        return
    end

    -- enable/disable all fields
    local allDisabled = not (item.Enable ~= false)
    local parent = form:getFieldRecord('Streams.List')
    local childFields = parent and parent.children or {}

    for key, childRec in pairs(childFields) do
        if key ~= 'Enable' then
            form:setFieldControlEnabled(childRec.info, not allDisabled)
        end
    end

    -- disable fields incompatible with built-in streams
    if not allDisabled then
        local isCustomStream = not item.Stream or item.Stream == 'custom'
        local nameField = form:getFieldInfo('Streams.List.Name')
        local chatTypeField = form:getFieldInfo('Streams.List.ChatType')
        local commandTypeField = form:getFieldInfo('Streams.List.Category')
        form:setFieldControlEnabled(nameField, isCustomStream)
        form:setFieldControlEnabled(chatTypeField, isCustomStream)
        form:setFieldControlEnabled(commandTypeField, isCustomStream)

        if not isCustomStream then
            item.Name = nil
            item.ChatType = item.Stream and Helpers.getStreamChatType(item.Stream) or 'say'
            item.Category = item.Stream and Helpers.getStreamCategory(item.Stream) or 'chat'

            form:setFieldControlValue(nameField, '')
            form:setFieldControlValue(chatTypeField, item.ChatType)
            form:setFieldControlValue(commandTypeField, item.Category)
        end
    end

    -- update max range based on stream/chat type
    local chatType = item.ChatType or Helpers.getStreamChatType(item.Stream)
    local maxRange = 30
    if chatType == 'shout' or item.Stream == 'yell' then
        maxRange = 60
    end

    local rangeControlNames = { 'Range', 'PerceptionRange', 'PerceptionRangeSigned' }
    for i = 1, #rangeControlNames do
        local name = rangeControlNames[i]
        local rangeControl = form:getFieldControl({ path = { 'Streams', 'List', name } }) --[[@as omi.ui.TextEntry?]]
        if rangeControl then
            rangeControl:setMaxValue(maxRange)
        end
    end

    -- enable range & overhead fields only for ranged stream types
    if not allDisabled then
        local isRanged = chatType == 'say' or chatType == 'shout'
        local dependentFields = {
            { form:getFieldInfo('Streams.List.Range') },
            { form:getFieldInfo('Streams.List.VerticalRange') },
            { form:getFieldInfo('Streams.List.PerceptionRange') },
            { form:getFieldInfo('Streams.List.PerceptionRangeSigned') },
            { form:getFieldInfo('Streams.List.OverheadFormat') },
            { form:getFieldInfo('Streams.List.AttractZombies'), false },
        }

        for _, depFieldInfo in pairs(dependentFields) do
            local depField = depFieldInfo[1]
            form:setFieldControlEnabled(depField, isRanged)

            if not isRanged then
                form:setFieldControlValue(depField, depFieldInfo[2])
            end
        end
    end
end

---Called when a tag list entry changes.
---@param args omi.forms.Args.Callback.Item
function Helpers.onChangeTag(args)
    local control = args.info.control --[[@as omi.ui.ListEntry]]
    local entry = control.entry
    local listbox = control.listbox
    if not entry or not listbox then
        return
    end

    local items = listbox.items
    for i = 1, #items do
        local item = items[i]
        if not item.tooltip then
            local isKnown
            item.tooltip, isKnown = Helpers.getTagTooltip(item.text)

            if not isKnown then
                item.textColor = { r = 0.94, g = 0.824, b = 0, a = 1 }
            end
        end
    end

    if entry:getSuggestBox() then
        return
    end

    API_C = API_C or utils.getAPI()
    API_C.utils.ui.suggestBox {
        entry = entry,
        font = UIFont.Small,
        refocusOverScrollbar = true,
        target = control,
        populate = Helpers.populateTagSuggest,
    }
end

---Called when the info button on a format option is clicked.
---@param args omi.forms.Args.Callback.ButtonClick
function Helpers.onClickFormatInfo(args)
    local form = args.form
    local state = args.state --[[@as ConfigurationFormState]]

    if state.activeFormatStringDialog then
        local isVisible = state.activeFormatStringDialog:isReallyVisible()
        state.activeFormatStringDialog:destroy()
        state.activeFormatStringDialog = nil

        if isVisible then
            return
        end
    end

    local w = 600
    local x = form:getRight()
    if x + w > getPlayerScreenWidth(0) then
        x = form:getX() - w
    end

    local lib = utils.lib --[[@as omi.client]]
    local dialog = lib.ui.okDialog {
        x = x,
        y = form:getY(),
        w = 600,
        h = 200,
        richText = true,
        moveWithMouse = true,
        setHeightToContents = true,
        text = getText('Sandbox_OmiChat_format_strings'),
    }

    form:removeOnDestroy(dialog)
    state.activeFormatStringDialog = dialog
end

---Called when a preset action button is clicked.
---@param args omi.forms.Args.Callback.ButtonClick
function Helpers.onClickPresetAction(args)
    if args.buttonIndex == 1 then
        API_C = API_C or utils.getAPI()

        local config = API_C.Configuration
        local preset = config:getPreset(args.value)
        if preset then
            Helpers.applyPreset(args.form, preset)
        end
    elseif args.buttonIndex == 2 then
        Helpers.savePreset(args.form, args.state)
    else
        Helpers.deletePreset(args.form, args.state, args.value)
    end
end

---Populates a tag suggest box and list entry with tags.
---@param listEntry omi.ui.ListEntry The list entry to populate with tooltips.
---@param suggestBox omi.ui.SuggestBox The suggest box to populate with suggestions.
---@param text string The search text.
function Helpers.populateTagSuggest(listEntry, suggestBox, text)
    API_C = API_C or utils.getAPI()

    local values = utils.set.table(listEntry:getValue())
    local search = API_C.search.strings({
        search = text,
        filter = function(value) return not values[value] end,
    }, TagList)

    local list = API_C.search.toSuggestions(search, #search.results > 1)
    for i = 1, #list do
        local suggestion = list[i]
        suggestion.tooltip = Helpers.getTagTooltip(suggestion.content)
    end

    suggestBox:setSuggestions(list)
end

---Transforms configured streams to include required data and fix incompatible fields.
---@param streams Configuration.StreamDefinition[] The streams to process.
---@return Configuration.StreamDefinition[] processed The processed streams.
function Helpers.processStreams(streams)
    local seen = { [''] = true }
    local processed = {}

    for i = 1, #streams do
        local stream = streams[i]
        local streamType = utils.trim(stream.Stream or '')
        local streamName = utils.trim(stream.Name or '')
        local isCustom = streamType == '' or streamType == 'custom'

        local compareKey = isCustom and streamName or streamType
        if not seen[compareKey] then
            seen[compareKey] = true
            local data = DefaultStreamData[streamType]
            if not data then
                data = {}
                if not isCustom then
                    utils.log.error('Missing defaults for built-in stream `%s`', tostring(streamType))
                end
            end

            for k, v in pairs(data) do
                local vType = type(v)
                if not isCustom and (k == 'ChatType' or k == 'Category') then
                    -- always copy these keys for built-in streams
                    stream[k] = v
                elseif type(stream[k]) ~= vType then
                    -- use defaults for invalid values
                    stream[k] = vType == 'table' and utils.copy(v) or v
                end
            end

            if isCustom then
                stream.Stream = 'custom'
                stream.Name = streamName
                stream.ChatType = utils.isNilOrWhitespace(stream.ChatType) and 'say' or stream.ChatType
                stream.Category = utils.isNilOrWhitespace(stream.Category) and 'chat' or stream.Category
            else
                stream.Stream = streamType
                stream.Name = nil
            end

            local isValidBuiltin = stream.Stream ~= 'custom' and not utils.isNilOrWhitespace(stream.Stream)
            local isValidCustom = stream.Stream == 'custom' and not utils.isNilOrWhitespace(stream.Name)
            if isValidBuiltin or isValidCustom then
                processed[#processed + 1] = stream
            end
        end
    end

    return processed
end

---Refreshes the list of presets to match the current custom presets.
---@param form omi.forms.Form The form with the field to update.
function Helpers.refreshPresetsList(form)
    local dropdown = form:getFieldControl('General.Preset') --[[@as omi.ui.Dropdown?]]
    if not dropdown then
        return
    end

    local options = Helpers.getPresetOptions()

    dropdown:clear()
    for i = 1, #options do
        local opt = options[i]
        dropdown:addOptionWithData(opt.text, opt.data)

        local added = dropdown.options[#dropdown.options] --[[@as omi.ui.Dropdown.Option]]
        added.tooltip = opt.tooltip
    end
end

---Helper to create a rules table containing only rules for children.
---Wraps the given table in an outer table with a `children` key.
---@param childRules table<string, omi.forms.Rules> Table of child rules.
---@return omi.forms.Rules rules Table of rules with the given child rules.
function Helpers.rules(childRules)
    return { children = childRules }
end

---Saves a custom user-defined preset.
---@param form omi.forms.Form The current form.
---@param state ConfigurationFormState The current form state.
function Helpers.savePreset(form, state)
    API_C = API_C or utils.getAPI()
    local lib = utils.lib --[[@as omi.client]]
    local config = API_C.Configuration
    local values = form.values

    if state.activePresetDialog then
        state.activePresetDialog:destroy()
    end

    local warningMessage = getText('UI_OmiChat_SavePreset_Overwrite')

    local dialog ---@type omi.ui.TextDialog
    dialog = lib.ui.textDialog {
        type = 'OKCancel',
        w = 500,
        h = 200,
        okText = getText('IGUI_RadioSave'),
        text = getText('UI_OmiChat_SavePreset_Prompt'),
        minLength = 1,
        maxLength = 50,
        onClick = function(_, args)
            if args.internal ~= 'OK' then
                return
            end

            local name = utils.trim(args.text)
            if #name == 0 then
                return
            end

            local preset = API_C.extension.addCustomPreset(name, values, true)
            Helpers.refreshPresetsList(form)
            Helpers.applyPreset(form, preset)
        end,
        validate = function(_, text)
            if config:getCustomPreset(text) then
                dialog:showWarningMessage(warningMessage)
            else
                dialog:hideWarningMessage()
            end

            return true
        end,
    }

    form:removeOnDestroy(dialog)
    state.activePresetDialog = dialog
end

---Writes a list of format data elements to a string list.
---@param heading string A heading string to write at the top.
---@param list FormatDataTranslation[]? The list of format data elements.
---@param descID string? An optional string ID for description text.
---@param out string[] The string array to write to.
function Helpers.writeFormatDataTranslations(heading, list, descID, out)
    if not descID and (not list or #list == 0) then
        return
    end

    out[#out + 1] = '\n\n'
    out[#out + 1] = heading

    if descID then
        out[#out + 1] = '\n'
        out[#out + 1] = getText(descID)
    end

    if not list or #list == 0 then
        return
    end

    out[#out + 1] = ' <INDENT:18> '

    for i = 1, #list do
        local data = list[i]
        out[#out + 1] = '\n <SETX:10> '
        out[#out + 1] = MIDDOT
        out[#out + 1] = ' <PUSHRGB:0,0.5,1> '
        out[#out + 1] = data.name
        out[#out + 1] = ' <POPRGB> : '
        out[#out + 1] = getText(data.id)
    end

    out[#out + 1] = ' <INDENT:0> '
end


return Helpers
