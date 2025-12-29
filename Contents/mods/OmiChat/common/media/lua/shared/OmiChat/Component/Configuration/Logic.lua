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

local DATA_PATH = 'media/ftl/data/configuration-data.ftl'

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


---Converts a string value to a boolean.
---@param value string?
---@return boolean
---@private
local function bool(value)
    if not value then
        return false
    end

    return value:lower() ~= 'false'
end

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
    local defs, version = Logic._readDefinitions()
    Logic._loadSchema(defs, version)
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
---@param def any
---@private
function Logic._generateField(def)
    local properties = {} ---@type table<string, omi.schema.Field>
    local childRules = {} ---@type table<string, omi.forms.Rules>

    for i = 1, #def do
        local child = def[i]
        properties[child._key], childRules[child._key] = Logic._generateField(child)
    end

    local rules = {} ---@type omi.forms.Rules
    if not isempty(childRules) then
        rules.children = childRules
    end

    local field ---@type omi.schema.Field
    local _type = def.type
    if _type == 'container' then
        field = schema.container(properties)
    elseif _type == 'string' or _type == 'textbox' then
        field = schema.string(def.default)

        if _type == 'textbox' then
            rules.displayLines = 10
        end
    elseif _type == 'format-string' then
        field = schema.string(def.default or '$Default()')
        rules.onInfoClick = Logic._onClickFormatInfo
        rules.infoTooltip = Logic._buildFormatTooltip(def)
    elseif _type == 'compatibility' then
        field = schema.compatibility(def.default)
    elseif _type == 'checkbox' then
        field = schema.bool(bool(def.default))
    elseif _type == 'page-checkbox' then
        field = schema.bool(bool(def.default))
        rules.togglePageFields = true
    elseif _type == 'object-list' then
        field = schema.array({
            maxItems = utils.tointeger(def.max_items),
            items = schema.object {
                skipMissing = true,
                properties = properties,
            },
        })
    elseif _type == 'dropdown' then
        field = schema.stringEnum({
            default = def.default,
            values = utils.split(def.options or '', ';'),
        })
    elseif _type == 'checkbox-group' then
        local options = utils.split(def.options or '', ';')

        local default
        if def.default then
            default = utils.split(def.default, ';')
        elseif def.default_all then
            default = options
        end

        field = schema.set({
            default = utils.set.table(default),
            items = schema.stringEnum({ values = options }),
        })
    elseif _type == 'string-list' or _type == 'tags' then
        field = schema.array({
            items = schema.string(),
            default = utils.split(def.default or '', ';'),
            maxItems = utils.tointeger(def.max_items),
        })

        if _type == 'tags' then
            rules.onChange = Logic._onChangeTag
        end
    elseif _type == 'color' then
        local default
        if def.default then
            default = utils.color.fromString(def.default)
            if not default then
                log.error('Invalid default value for key %s', def._key)
            end
        end

        field = schema.color({ default = default })
    elseif _type == 'integer' or _type == 'number' then
        local cons = _type == 'integer' and schema.int or schema.double

        local max = tonumber(def.max) --[[@as integer]]
        local min = tonumber(def.min) --[[@as integer]]
        local default = tonumber(def.default) --[[@as integer]]

        if not max then
            max = 0
            log.error('Missing max value for key %s', def._key)
        end

        if not min then
            min = 0
            log.error('Missing min value for key %s', def._key)
        end

        if not default then
            default = 0
            log.error('Missing default value for key %s', def._key)
        end

        field = cons(default, min, max)
    else
        log.error('Invalid field type %s for key %s', _type, def._key)
    end

    rules.paddingTop = tonumber(def.pad_top)
    rules.paddingBottom = tonumber(def.pad_bottom)
    rules.maxLines = tonumber(def.max_lines)
    rules.displayLines = tonumber(def.display_lines) or rules.displayLines
    rules.noReorderButtons = not bool(def.can_reorder) or nil

    if def.toggle then
        rules.toggleFields = utils.mapList(utils.split, utils.split(def.toggle, ';'), '.')
    end

    if def.toggle_inverse then
        rules.inverseToggleFields = utils.mapList(utils.split, utils.split(def.toggle_inverse, ';'), '.')
    end

    local flags = {
        no_label = 'noLabel',
        full_page = 'useFullPage',
        no_full_width = 'noFullWidth',
        hidden = 'hidden',
    }

    for k, v in pairs(flags) do
        if bool(def[k]) then
            rules[v] = true
        end
    end

    if Logic._formRules[def._id] then
        utils.extend(rules, Logic._formRules[def._id])
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
---@param def table
---@param list string[]?
---@param _type 'token' | 'arg'
---@return FormatDataTranslation[]
---@private
function Logic._getFormatDataTranslations(def, list, _type)
    if not list or #list == 0 then
        return {}
    end

    local prefix = _type .. '-'
    local overridePrefix = _type .. '_'

    local index = {}
    local result = {}
    for i = 1, #list do
        local name = list[i]

        ---@type FormatDataTranslation
        local data = {
            id = def[overridePrefix .. name] or (prefix .. name),
            name = name,
        }

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
            tooltip = preset:isCustom() and getText('preset-user-defined') or nil,
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
---@param args omi.forms.Args.Callback.Item
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

---Creates the tooltip to use for a format string option.
---@param def any
---@return string
---@private
function Logic._buildFormatTooltip(def)
    local rope = {
        getText('heading-format-string'),
    }

    local tokens = def.tokens and utils.split(def.tokens, ';')
    local args = def.args and utils.split(def.args, ';')

    if def.error_tokens then
        tokens[#tokens + 1] = 'error'
        tokens[#tokens + 1] = 'errorID'
    end

    Logic._writeFormatDataTranslations(
        getText('heading-tokens'),
        Logic._getFormatDataTranslations(def, tokens, 'token'),
        def.description_tokens,
        rope
    )

    Logic._writeFormatDataTranslations(
        getText('heading-args'),
        Logic._getFormatDataTranslations(def, args, 'arg'),
        def.description_args,
        rope
    )

    if #rope > 1 then
        rope[#rope + 1] = '\n'
    end

    return concat(rope)
end

---Reads the data file to generate the schema and form.
---Throws an error for invalid data.
---@param definitions table
---@param version integer
---@private
function Logic._loadSchema(definitions, version)
    ---@type table<string, omi.schema.Field>
    local properties = {
        VERSION = schema.int(version),
    }

    local rules = {} ---@type table<string, omi.forms.Rules>
    for i = 1, #definitions do
        local def = definitions[i]
        if def.type ~= 'container' then
            log.error('Invalid top-level field type for %s (%s)', def._id, def.type)
        else
            properties[def._key], rules[def._key] = Logic._generateField(def)
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

---Called when a language name changes in the language listbox.
---@param args omi.forms.Args.Callback.Item
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

---Called when the preset option dropdown changes.
---@param args omi.forms.Args.Callback.Item
---@private
function Logic._onChangePreset(args)
    local info = args.info
    local deleteBtn = info.actionButtons and info.actionButtons[3]
    if not deleteBtn then
        return
    end

    deleteBtn:setEnabled(utils.startsWith(args.value, 'custom:'))
end

---Called when a value in a stream changes.
---@param args omi.forms.Args.Callback.Item
---@private
function Logic._onChangeStream(args)
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
            item.ChatType = item.Stream and Logic._getStreamChatType(item.Stream) or 'say'
            item.Category = item.Stream and Logic._getStreamCategory(item.Stream) or 'chat'

            form:setFieldControlValue(nameField, '')
            form:setFieldControlValue(chatTypeField, item.ChatType)
            form:setFieldControlValue(commandTypeField, item.Category)
        end
    end

    -- update max range based on stream/chat type
    local chatType = item.ChatType or Logic._getStreamChatType(item.Stream)
    local maxRange = 30
    if chatType == 'shout' or item.Stream == 'yell' then
        maxRange = 60
    end

    local rangeControlNames = { 'Range', 'PerceptionRange', 'PerceptionRangeSigned' }
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
---@param args omi.forms.Args.Callback.ButtonClick
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
---@param args omi.forms.Args.Callback.ButtonClick
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
---@return table definitions
---@return integer version
---@private
function Logic._readDefinitions()
    local resource = utils.l10n.loadModResource('\\OmiChat', DATA_PATH)
    if not resource then
        log.fatal('Failed to load configuration schema') ---@cast resource -?
    end

    local bundle = utils.l10n.FluentBundle:new()
    bundle:addResource(resource)

    local versionMsg = bundle:getMessage('VERSION')
    local versionVal = versionMsg and versionMsg.value
    if not versionVal then
        log.fatal('Missing VERSION in configuration schema') ---@cast versionVal -?
    end

    local version = tonumber((bundle:formatPattern(versionVal))) --[[@as integer]]
    if not version then
        log.fatal('Invalid value for VERSION in configuration schema')
    end

    ---@type any
    local definitions = { _map = {} }
    for i = 1, #resource.body do
        local entry = resource.body[i]
        local id = entry.id
        local isTerm = id:sub(1, 1) == '-'

        if isTerm or id == 'VERSION' then
            -- skip
        elseif id:sub(1, 7) ~= 'config-' then
            log.error('Unknown message in configuration schema: %s', id)
        else
            id = id:sub(8)

            local parts = utils.split(id, '-')
            local item = definitions --[[@as any]]
            for j = 1, #parts do
                local key = parts[j] --[[@as string]]
                if not item._map[key] then
                    local def = {
                        type = 'container',
                        _id = id,
                        _key = key,
                        _map = {},
                    }

                    item._map[key] = def
                    item[#item + 1] = def
                end

                item = item._map[key]
            end

            if #parts == 0 then
                log.error('Invalid configuration key config-%s', id)
                item = {}
            end

            for k, v in pairs(entry.attributes) do
                k = k:gsub('%-', '_')

                local value = bundle:formatPattern(v) ---@type any
                item[k] = value
            end
        end
    end

    return definitions, version
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
    ['General-Preset'] = {
        actionCount = 3,
        getEnumOptions = Logic._getPresetOptions,
        onActionClick = Logic._onClickPresetAction,
        onChange = Logic._onChangePreset,
    },
    ['Language-List'] = {
        getItemDisplay = Logic._getLanguageListDisplay,
    },
    ['Language-List-Name'] = {
        onChange = Logic._onChangeLanguageName,
    },
    ['Streams-List'] = {
        createItem = Logic._createStreamItem,
        getItemDisplay = Logic._getStreamDisplay,
        onChange = Logic._onChangeStream,
    },
}

return Logic
