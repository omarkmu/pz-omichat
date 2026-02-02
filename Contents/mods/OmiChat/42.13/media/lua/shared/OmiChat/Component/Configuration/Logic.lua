---Logic for the configuration form and schema.
---@namespace omichat
---@diagnostic disable: access-invisible

local utils = require 'OmiChat/Utils'
local utils_c = utils --[[@as omichat.utils.client]]

local log = utils.log
local schema = utils.schema

local DefaultLanguages = require 'OmiChat/Definition/DefaultLanguageList'
local DefaultStreams = require 'OmiChat/Definition/DefaultStreamList'
local DefaultStreamData = require 'OmiChat/Definition/DefaultStreamData'

local sort = table.sort
local concat = table.concat
local isempty = table.isempty
local getText = utils.getText
local getTextOrNull = utils.getTextOrNull
local getAttr = utils.getAttr
local MIDDOT = string.char(183) .. ' <SPACE> '

local API_C ---@type api.client?

---@class ConfigurationLogic
---@field private _schema? omi.Schema Generated schema.
---@field private _tagList string[] List of available tags.
local Logic = {}

Logic._tagList = {}

---Gets the configuration schema.
---If it hasn't already been generated, this will generate it.
---@return omi.Schema
function Logic.getSchema()
    if not Logic._schema then
        Logic.load()
    end

    assert(Logic._schema)
    return Logic._schema
end

---Reads the data file to generate the schema, form, and metadata.
---Throws an error for invalid data.
function Logic.load()
    local data = Logic._readDefinitions()
    Logic._loadSchema(data.fields, data._VARS, data._VERSION)
    Logic._loadTags()
end

---Refreshes information in the form from external sources.
---@param form omi.forms.Form The form with the fields to update.
---@param values Configuration? New form values.
function Logic.refreshForm(form, values)
    Logic._refreshPresetsList(form)

    if values then
        form.values = values
        form:clearState()
        form:refresh()
    end
end


---Applies values from a preset to the form.
---@param form omi.forms.Form The current form.
---@param preset ConfigurationPreset The preset to apply.
---@private
function Logic._applyPreset(form, preset)
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

    form:setStatusMessage(getText('status-preset', { name = preset:getName() }))
end

---Creates the tooltip to use for a format string option.
---@param def ConfigurationFieldDef
---@param vars table<string, any>
---@return string
---@private
function Logic._buildFormatTooltip(def, vars)
    local rope = {
        getText('heading-format-string'),
    }

    local tokens = Logic._resolveTableVars(def._tokens, vars)
    local args = Logic._resolveTableVars(def._args, vars)

    if def._errorTokens then
        tokens = tokens or {}
        tokens[#tokens + 1] = 'error'
        tokens[#tokens + 1] = 'errorID'
    end

    Logic._writeFormatDataTranslations(
        getText('heading-tokens'),
        Logic._getFormatDataTranslations(tokens, 'token'),
        def._descriptionTokens,
        rope
    )

    Logic._writeFormatDataTranslations(
        getText('heading-args'),
        Logic._getFormatDataTranslations(args, 'arg'),
        def._descriptionArgs,
        rope
    )

    if #rope > 1 then
        rope[#rope + 1] = '\n'
    end

    return concat(rope)
end

---Creates a new item for the stream list.
---@return Configuration.StreamDefinition item The new item.
---@private
function Logic._createStreamItem()
    ---@type Configuration.StreamDefinition
    local item = {
        Enable = true,
        Stream = 'custom',
        ChatType = 'say',
        Category = 'chat',
        OverheadFormat = '$Default()',
        ChatFormat = '$Default()',
        DefaultColor = { r = 255, g = 255, b = 255 },
        Range = 16,
        VerticalRange = 2,
        PerceptionRange = 0,
        PerceptionRangeSigned = 0,
        AllowMentions = true,
    }

    return item
end

---Deletes a custom user-defined preset.
---@param form omi.forms.Form The current form.
---@param state ConfigurationFormState The current form state.
---@param value string The current preset name.
---@private
function Logic._deletePreset(form, state, value)
    if not utils.startsWith(value, 'custom:') then
        return
    end

    API_C = API_C or utils.getAPI()

    if state.activePresetDialog then
        state.activePresetDialog:destroy()
    end

    local name = value:sub(8)
    local dialog = utils_c.ui.yesNoDialog {
        w = 400,
        h = 100,
        text = getText('dialog-confirm-delete-preset', { name = name }),
        onClick = function(_, args)
            if args.internal ~= 'YES' then
                return
            end

            API_C.extension.removeCustomPreset(name, true)

            local currentValue = form:getValue('General.Preset')
            if currentValue == value then
                Logic._refreshPresetsList(form)

                local values = form.values
                values.General.Preset = 'Buffy'
                form:setControlValue('General.Preset', 'Buffy')
            end
        end,
    }

    form:removeOnDestroy(dialog)
    state.activePresetDialog = dialog
end

---Generates a single schema field and its corresponding form rules.
---@return omi.schema.Field, omi.forms.Rules?
---@param vars table<string, any>
---@param def ConfigurationFieldDef
---@private
function Logic._generateField(def, vars, parentKey)
    local properties = {} ---@type table<string, omi.schema.Field>
    local childRules = {} ---@type table<string, omi.forms.Rules>

    local key = (parentKey and (parentKey .. '.') or '') .. def.name

    local fields = def.fields or {} --[[@as ConfigurationFieldDef[] ]]
    for i = 1, #fields do
        local child = fields[i]
        properties[child.name], childRules[child.name] = Logic._generateField(child, vars, key)
    end

    local rules = {} ---@type omi.forms.Rules
    if not isempty(childRules) then
        rules.children = childRules
    end

    local field ---@type omi.schema.Field
    local _type = def.type
    if _type == 'object' then
        field = schema.container(properties)
    elseif _type == 'string' or _type == 'textbox' then
        field = schema.string(def.default)

        if _type == 'textbox' then
            rules.displayLines = 10
        end
    elseif _type == 'format-string' then
        field = schema.string(def.default or '$Default()')
        rules.onInfoClick = Logic._onClickFormatInfo
        rules.infoTooltip = Logic._buildFormatTooltip(def, vars)
    elseif _type == 'compatibility' then
        field = schema.compatibility(def.default)
    elseif _type == 'checkbox' then
        field = schema.bool(def.default)
    elseif _type == 'page-checkbox' then
        field = schema.bool(def.default)
        rules.togglePageFields = true
    elseif _type == 'object-list' then
        field = schema.array({
            maxItems = def.maxItems,
            items = schema.object({
                skipMissing = true,
                properties = properties,
            }),
        })
    elseif _type == 'dropdown' then
        field = schema.stringEnum({
            default = def.default,
            values = def.options,
        })
    elseif _type == 'checkbox-group' then
        local options = def.options

        local default
        if def.default then
            default = def.default
        elseif def.defaultAll then
            default = options
        end

        field = schema.set({
            default = utils.set.table(default),
            items = schema.stringEnum({ values = options }),
        })
    elseif _type == 'string-map' then
        field = schema.object({
            skipMissing = true,
            default = def.default,
            additionalProperties = schema.string(),
        })
    elseif _type == 'string-list' or _type == 'tags' then
        field = schema.array({
            items = schema.string(),
            default = def.default,
            maxItems = def.maxItems,
        })

        if _type == 'tags' then
            rules.onChange = Logic._onChangeTag
        end
    elseif _type == 'color' then
        local default
        local raw = def.default
        if raw then
            default = { r = raw[1], g = raw[2], b = raw[3] }
        end

        field = schema.color({ default = default })
    elseif _type == 'integer' or _type == 'number' then
        local cons = _type == 'integer' and schema.int or schema.double

        local max = def.max
        local min = def.min
        local default = def.default

        if not max then
            max = 0
            log.error('Missing max value for field %s', key)
        end

        if not min then
            min = 0
            log.error('Missing min value for field %s', key)
        end

        if not default then
            default = 0
            log.error('Missing default value for field %s', key)
        end

        field = cons(default, min, max)
    else
        log.error('Invalid field type %s for field %s', _type, key)
    end

    rules.paddingTop = def.padTop
    rules.paddingBottom = def.padBottom
    rules.maxLines = def.maxLines
    rules.displayLines = def.displayLines or rules.displayLines
    rules.noReorderButtons = utils.default(def.noReorderButtons, true)

    if def.toggle then
        rules.toggleFields = utils.mapList(utils.split, def.toggle, '.')
    end

    if def.toggleInverse then
        rules.inverseToggleFields = utils.mapList(utils.split, def.toggleInverse, '.')
    end

    local flags = {
        'noLabel',
        'useFullPage',
        'noFullWidth',
        'hidden',
    }

    for i = 1, #flags do
        local flag = flags[i]
        if def[flag] then
            rules[flag] = true
        end
    end

    if Logic._formRules[key] then
        utils.extend(rules, Logic._formRules[key])
    end

    if isempty(rules) then
        return field
    end

    return field, rules
end

---Returns a list of default language definition objects.
---@return Configuration.LanguageDefinition[]
---@private
function Logic._getDefaultLanguages()
    return utils.deepcopy(DefaultLanguages)
end

---Returns a list of default stream objects.
---@return Configuration.StreamDefinition[]
---@private
function Logic._getDefaultStreams()
    return utils.deepcopy(DefaultStreams)
end

---Gets a final list of format data translations.
---@param list (string | FormatDataTranslation)[]?
---@param _type 'token' | 'arg'
---@return FormatDataTranslation[]
---@private
function Logic._getFormatDataTranslations(list, _type)
    if not list or #list == 0 then
        return {}
    end

    local prefix = _type .. '-'

    local index = {}
    local result = {}
    for i = 1, #list do
        local dataOrName = list[i]
        ---@type FormatDataTranslation
        local data

        if type(dataOrName) == 'string' then
            data = {
                id = prefix .. dataOrName,
                name = dataOrName,
            }
        else
            data = dataOrName
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
---@param args omi.Args.FormCallback.Item
---@return string
---@private
function Logic._getLanguageListDisplay(args)
    local item = args.value or {} ---@type Configuration.LanguageDefinition

    if not utils.isNilOrWhitespace(item.Name) then
        return item.Name
    end

    return getAttr('config-Language', 'untitled')
end

---Gets a list of options for the preset configuration value.
---@return omi.Dropdown.Option[]
---@private
function Logic._getPresetOptions()
    API_C = API_C or utils.getAPI()

    local list = {} ---@type omi.Dropdown.Option[]
    local presetList = API_C.Configuration:getPresetList()
    for i = 1, #presetList do
        local preset = presetList[i]

        list[#list + 1] = {
            data = preset:getID(),
            text = preset:getName(),
            tooltip = preset:getTooltip(),
        }
    end

    return list
end

---Gets the chat type associated with a built-in stream.
---@param stream string?
---@return omi.ChatTypeString?
---@private
function Logic._getStreamChatType(stream)
    if not stream then
        return
    end

    local data = DefaultStreamData[stream]
    return data and data.ChatType
end

---Gets the command type associated with a built-in stream.
---@param stream string?
---@return StreamCategory?
---@private
function Logic._getStreamCategory(stream)
    if not stream then
        return
    end

    local data = DefaultStreamData[stream]
    return data and data.Category
end

---Gets a display string for an item in the stream listbox.
---@param args omi.Args.FormCallback.Item
---@private
---@return string
function Logic._getStreamDisplay(args)
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
---@private
function Logic._getTagTooltip(tag)
    local desc = getTextOrNull('tag-' .. tag)
    local isKnown = desc ~= nil

    desc = desc or getText('unrecognized-tag')
    local color = isKnown and ' <PUSHRGB:0,0.5,1> ' or ' <PUSHRGB:0.93,0.824,0> '

    return color .. tag .. ' <POPRGB> <LINE> ' .. desc, isKnown
end

---Handles changes to the stream list or related fields in the form.
---@param form omi.forms.Form
---@param item Configuration.StreamDefinition
---@private
function Logic._handleStreamChange(form, item)
    -- enable/disable all fields
    local useDefaults = form:getValue('Streams.UseDefaultList')
    local allDisabled = not (item.Enable ~= false and not useDefaults)
    local parent = form:getFieldRecord('Streams.List')
    local childFields = parent and parent.children or {}

    form:setControlEnabled('Streams.List.Enable', not useDefaults)
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
            item.ChatType = item.Stream and Logic._getStreamChatType(item.Stream) or 'say'
            item.Category = item.Stream and Logic._getStreamCategory(item.Stream) or 'chat'

            form:setFieldControlValue(nameField, '')
            form:setFieldControlValue(chatTypeField, item.ChatType)
            form:setFieldControlValue(commandTypeField, item.Category)
        end
    end

    -- update max range based on stream/chat type
    local chatType = item.ChatType or Logic._getStreamChatType(item.Stream)
    local maxRange = (chatType == 'shout' or item.Stream == 'yell') and 60 or 30
    local rangeControlNames = {
        'Range',
        'RangeSigned',
        'PerceptionRange',
        'PerceptionRangeSigned',
    }

    for i = 1, #rangeControlNames do
        local name = rangeControlNames[i]
        local rangeControl = form:getFieldControl({ path = { 'Streams', 'List', name } }) --[[@as omi.TextEntry?]]
        if rangeControl then
            rangeControl:setMaxValue(maxRange)
        end
    end

    -- enable range & overhead fields only for ranged stream types
    if not allDisabled then
        local isRanged = chatType == 'say' or chatType == 'shout'
        local dependentFields = {
            { form:getFieldInfo('Streams.List.Range') },
            { form:getFieldInfo('Streams.List.RangeSigned') },
            { form:getFieldInfo('Streams.List.VerticalRange') },
            { form:getFieldInfo('Streams.List.VerticalRangeSigned') },
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

---Reads the data file to generate the schema and form.
---Throws an error for invalid data.
---@param definitions ConfigurationFieldDef[]
---@param vars table<string, any>
---@param version integer
---@private
function Logic._loadSchema(definitions, vars, version)
    ---@type table<string, omi.schema.Field>
    local properties = {
        VERSION = schema.int(version),
    }

    local rules = {} ---@type table<string, omi.forms.Rules>
    for i = 1, #definitions do
        local def = definitions[i]
        if def.type ~= 'object' then
            log.error('Invalid top-level field type for %s (%s)', def.name, def.type)
        else
            properties[def.name], rules[def.name] = Logic._generateField(def, vars)
        end
    end

    Logic._schema = schema({
        properties = properties,
        form = {
            prefix = 'OmiChat.config',
            closeOnSave = false,
            rules = rules,
        },

        onRead = Logic._onRead,
        sanitize = Logic._onSanitize,
    })
end

---Reads translations to load available tags.
---@private
function Logic._loadTags()
    local bundle = utils.l10n.getBundle('OmiChat')
    if not bundle then
        log.error('Translations are not loaded')
        return
    end

    local tagList = {}
    for name in bundle:messages() do
        local tag = name:match('^tag%-([A-Z][A-Za-z]+)$')
        if tag then
            tagList[#tagList + 1] = tag
        end
    end

    Logic._tagList = tagList
end

---Called when a language name changes in the language list.
---@param args omi.Args.FormCallback.Item
---@private
function Logic._onChangeLanguageName(args)
    local control = args.form:getFieldControl('Language.List.Name') --[[@as omi.TextEntry?]]
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

---Called when the value of `Use Defaults` changes for the language list.
---@param args omi.Args.FormCallback.Item
---@private
function Logic._onChangeLanguageUseDefault(args)
    local form = args.form

    local useDefault = form:getValue('Language.UseDefaultList')
    local parent = form:getFieldRecord('Language.List')
    local childFields = parent and parent.children or {}

    for _, childRec in pairs(childFields) do
        form:setFieldControlEnabled(childRec.info, not useDefault)
    end
end

---Called when the preset option dropdown changes.
---@param args omi.Args.FormCallback.Item
---@private
function Logic._onChangePreset(args)
    local info = args.info
    local deleteBtn = info.actionButtons and info.actionButtons[3]
    if not deleteBtn then
        return
    end

    deleteBtn:setEnabled(utils.startsWith(args.value, 'custom:'))
end

---Called when a value in a stream list item changes.
---@param args omi.Args.FormCallback.Item
---@private
function Logic._onChangeStream(args)
    local form = args.form
    local item = args.parent
    if not item then
        return
    end

    Logic._handleStreamChange(form, item)
end

---Called when the value of `Use Defaults` changes for the stream list.
---@param args omi.Args.FormCallback.Item
---@private
function Logic._onChangeStreamUseDefault(args)
    local form = args.form

    local list = form:getValue('Streams.List')
    local index = form:getFieldSelectedIndex('Streams.List')
    local item = list and index and list[index]
    if not item then
        return
    end

    Logic._handleStreamChange(form, item)
end

---Called when a tag list entry changes.
---@param args omi.Args.FormCallback.Item
---@private
function Logic._onChangeTag(args)
    local control = args.info.control --[[@as omi.ListEntry]]
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
            item.tooltip, isKnown = Logic._getTagTooltip(item.text)

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
        populate = Logic._populateTagSuggest,
    }
end

---Called when the info button on a format option is clicked.
---@param args omi.Args.FormCallback.ButtonClick
---@private
function Logic._onClickFormatInfo(args)
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

    local dialog = utils_c.ui.okDialog {
        x = x,
        y = form:getY(),
        w = 600,
        h = 200,
        richText = true,
        moveWithMouse = true,
        setHeightToContents = true,
        text = getText('config-format-strings'),
    }

    form:removeOnDestroy(dialog)
    state.activeFormatStringDialog = dialog
end

---Called when a preset action button is clicked.
---@param args omi.Args.FormCallback.ButtonClick
---@private
function Logic._onClickPresetAction(args)
    if args.buttonIndex == 1 then
        API_C = API_C or utils.getAPI()

        local config = API_C.Configuration
        local preset = config:getPreset(args.value)
        if preset then
            Logic._applyPreset(args.form, preset)
        end
    elseif args.buttonIndex == 2 then
        Logic._savePreset(args.form, args.state)
    else
        Logic._deletePreset(args.form, args.state, args.value)
    end
end

---Called when configuration values are read by the schema.
---@param values Configuration
---@private
function Logic._onRead(values)
    -- read default languages
    local languages = values.Language.List
    values._Languages = languages

    if type(languages) ~= 'table' or values.Language.UseDefaultList then
        languages = Logic._getDefaultLanguages()
    end

    -- read default stream data
    local streams = values.Streams.List
    values._Streams = streams

    if type(streams) ~= 'table' or #streams == 0 or values.Streams.UseDefaultList then
        streams = Logic._getDefaultStreams()
    else
        streams = utils.deepcopy(streams)
    end

    values.Language.List = languages
    values.Streams.List = Logic._processStreams(streams)
end

---Called to sanitize values before saving.
---@param values Configuration
---@private
function Logic._onSanitize(values)
    -- doesn't do anything, so don't save it to avoid confusion
    values.General.Preset = nil

    if values._Streams then
        values.Streams = values.Streams or {}
        values.Streams.List = values._Streams
        values._Streams = nil
    end

    if values._Languages then
        values.Language = values.Language or {}
        values.Language.List = values._Languages
        values._Languages = nil
    end
end

---Populates a tag suggest box and list entry with tags.
---@param listEntry omi.ListEntry The list entry to populate with tooltips.
---@param suggestBox omi.SuggestBox The suggest box to populate with suggestions.
---@param text string The search text.
---@private
function Logic._populateTagSuggest(listEntry, suggestBox, text)
    API_C = API_C or utils.getAPI()

    local values = utils.set.table(listEntry:getValue())
    local search = API_C.search.strings({
        search = text,
        filter = function(value) return not values[value] end,
    }, Logic._tagList)

    local list = API_C.search.toSuggestions(search, #search.results > 1)
    for i = 1, #list do
        local suggestion = list[i]
        suggestion.tooltip = Logic._getTagTooltip(suggestion.content)
    end

    suggestBox:setSuggestions(list)
end

---Transforms configured streams to include required data and fix incompatible fields.
---@param streams Configuration.StreamDefinition[] The streams to process.
---@return Configuration.StreamDefinition[] processed The processed streams.
---@private
function Logic._processStreams(streams)
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
                    log.error('Missing defaults for built-in stream `%s`', tostring(streamType))
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

---Reads the configuration definition file.
---@return table data
---@private
function Logic._readDefinitions()
    local reader = getModFileReader('\\OmiChat', 'configuration.json', false)
    if not reader then
        log.fatal('Failed to open configuration file') ---@cast reader -?
    end

    local data, err = utils.json.tryReadObject({ reader = reader })
    if not data then
        log.fatal(err or 'Failed to read configuration file') ---@cast data -?
    end

    if type(data._VERSION) ~= 'number' then
        log.fatal('Invalid value for _VERSION in configuration file')
    end

    return data
end

---Refreshes the list of presets to match the current custom presets.
---@param form omi.forms.Form The form with the field to update.
---@private
function Logic._refreshPresetsList(form)
    local dropdown = form:getFieldControl('General.Preset') --[[@as omi.Dropdown?]]
    if not dropdown then
        return
    end

    local options = Logic._getPresetOptions()

    dropdown:clear()
    for i = 1, #options do
        local opt = options[i]
        dropdown:addOptionWithData(opt.text, opt.data)

        local added = dropdown.options[#dropdown.options] --[[@as omi.Dropdown.Option]]
        added.tooltip = opt.tooltip
    end
end

---Resolves variable references in a table.
---@param t any[]?
---@param vars table<string, any>
---@return table?
---@private
function Logic._resolveTableVars(t, vars)
    if not t then
        return
    end

    local result = {}
    for i = 1, #t do
        local el = t[i]
        if type(el) == 'string' then
            local var = el:match('^%$([%u_]+)$')
            local replacement = var and vars[var]

            -- this is only used for tokens and args currently, so only tables
            if replacement and type(replacement) == 'table' then
                utils.append(result, replacement)
            else
                result[#result + 1] = el
            end
        else
            result[#result + 1] = el
        end
    end

    return result
end

---Saves a custom user-defined preset.
---@param form omi.forms.Form The current form.
---@param state ConfigurationFormState The current form state.
---@private
function Logic._savePreset(form, state)
    API_C = API_C or utils.getAPI()
    local config = API_C.Configuration
    local values = form.values

    if state.activePresetDialog then
        state.activePresetDialog:destroy()
    end

    local warningMessage = getText('save-preset-overwrite')

    local dialog ---@type omi.TextDialog
    dialog = utils_c.ui.textDialog {
        type = 'OKCancel',
        w = 500,
        h = 200,
        okText = getText('@ui.btn-save'),
        text = getText('dialog-save-preset'),
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
            Logic._refreshPresetsList(form)
            Logic._applyPreset(form, preset)
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
---@private
function Logic._writeFormatDataTranslations(heading, list, descID, out)
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


---Associates field keys to additional form rules to include.
---@type table<string, omi.forms.Rules>
Logic._formRules = {
    ['General.Preset'] = {
        actionCount = 3,
        getEnumOptions = Logic._getPresetOptions,
        onActionClick = Logic._onClickPresetAction,
        onChange = Logic._onChangePreset,
    },
    ['Language.List'] = {
        getItemDisplay = Logic._getLanguageListDisplay,
    },
    ['Language.List.Name'] = {
        onChange = Logic._onChangeLanguageName,
    },
    ['Language.UseDefaultList'] = {
        onChange = Logic._onChangeLanguageUseDefault,
    },
    ['Streams.List'] = {
        createItem = Logic._createStreamItem,
        getItemDisplay = Logic._getStreamDisplay,
        onChange = Logic._onChangeStream,
    },
    ['Streams.UseDefaultList'] = {
        onChange = Logic._onChangeStreamUseDefault,
    },
}

return Logic

--#region Type Definitions

---@class ConfigurationFieldDef
---@field name string The name of the field.
---@field type string The type of the field.
---@field fields? ConfigurationFieldDef[] Child fields.
---@field default? any The default value of the field.
---@field max? any The maximum value of the field.
---@field min? any The minimum value of the field.
---@field defaultAll? boolean Whether to use all options as the default value.
---@field options? any Options for a field.
---@field padTop? number Padding to add to the top of the field in the form.
---@field padBottom? number Padding to add to the bottom of the field in the form.
---@field maxItems? integer The maximum number of items for a field.
---@field maxLines? integer The maximum number of lines for a field input.
---@field displayLines? integer The maximum number of lines to display for a field input.
---@field noReorderButtons? boolean Whether to exclude reorder buttons for a list control.
---@field toggle? string[] Fields to toggle when a checkbox is checked.
---@field toggleInverse? string[] Fields to toggle when a checkbox is unchecked.
---@field _tokens? (string | FormatDataTranslation)[] Tokens available for a format string.
---@field _args? (string | FormatDataTranslation)[] Arguments available for a format string.
---@field _errorTokens? boolean Whether to include error tokens in the tokens.
---@field _descriptionTokens? string A description to include alongside tokens.
---@field _descriptionArgs? string A description to include alongside arguments.

--#endregion
