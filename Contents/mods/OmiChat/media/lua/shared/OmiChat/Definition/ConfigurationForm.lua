---Information about the configuration form layout.

local utils = require 'OmiChat/utils'


local PAD_N = 10
local PAD_TOP = { paddingTop = PAD_N }
local PAD_BOTTOM = { paddingBottom = PAD_N }
local NO_REORDER = { noReorderButtons = true }
local PATH_PRESET = { 'General', 'Preset' }
local PATH_INFO = { 'General', 'InfoText' }

---Helper to create a rules table containing only rules for children.
---Wraps the given table in an outer table with a `children` key.
---@param ruleTable table<string, omi.forms.Rules>
---@return omi.forms.Rules
local function rules(ruleTable)
    return { children = ruleTable }
end

---Applies values from a preset to the form.
---@param form omi.forms.Form
---@param preset omichat.ConfigurationPreset
local function applyPreset(form, preset)
    local values = form.values
    local schema = form:getSchema() ---@cast schema omichat.ConfigurationSchema
    local id = preset:getID()

    -- get info text value before setting values
    local infoText = form:getValue(PATH_INFO)

    -- ensure ID matches expected preset ID
    local presetValues = preset:getValues(schema)
    presetValues.General = presetValues.General or {}
    presetValues.General.Preset = id

    form:setValues(presetValues)

    -- keep the existing info text when applying a built-in preset
    if not preset:isCustom() then
        values.General = values.General or {}
        values.General.InfoText = infoText
        form:setControlValue(PATH_INFO, infoText)
    end

    form:setStatusMessage(getText('Sandbox_OmiChat_status_preset', preset:getName()))
end

---Gets a list of options for the preset configuration value.
---@return omi.ui.Dropdown.OptionOrString[]
local function getPresetOptions()
    local list = {} ---@type omi.ui.Dropdown.OptionOrString[]
    local presetList = utils.getAPI().Configuration:getPresetList()
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

---Refreshes the list of presets to match the current custom presets.
---@param form omi.forms.Form
local function refreshPresetsList(form)
    local dropdown = form:getFieldControl(PATH_PRESET) ---@cast dropdown omi.ui.Dropdown?
    if not dropdown then
        return
    end

    local options = getPresetOptions()

    dropdown:clear()
    for i = 1, #options do
        local opt = options[i]
        dropdown:addOptionWithData(opt.text, opt.data)

        local added = dropdown.options[#dropdown.options]
        added.tooltip = opt.tooltip
    end
end

---Called when a preset action button is clicked.
---@param args omi.forms.Args.Callback.ButtonClick
local function onPresetAction(args)
    local API = utils.getAPI()
    local config = API.Configuration
    local lib = utils.lib --[[@as omi.client]]
    local state = args.state
    local form = args.form
    local value = args.value ---@type string

    if args.buttonIndex == 1 then
        -- apply preset
        local preset = config:getPreset(value)
        if preset then
            applyPreset(form, preset)
        end
    elseif args.buttonIndex == 2 then
        -- save preset
        if state.activePresetDialog then
            state.activePresetDialog:destroy()
        end

        local values = args.values
        local dialog ---@type omi.ui.TextDialog
        local warningMessage = getText('UI_OmiChat_SavePreset_Overwrite')

        dialog = lib.ui.textDialog {
            type = 'OKCancel',
            w = 500,
            h = 200,
            okText = getText('IGUI_RadioSave'),
            text = getText('UI_OmiChat_SavePreset_Prompt'),
            minLength = 1,
            maxLength = 50,
            onClick = function(_, _args)
                if _args.internal == 'CANCEL' then
                    return
                end

                local name = utils.trim(_args.text)
                if #name == 0 then
                    return
                end

                local preset = API.extension.addCustomPreset(name, values, true)
                refreshPresetsList(form)
                applyPreset(form, preset)
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

        state.activePresetDialog = dialog
    else
        if not utils.startsWith(value, 'custom:') then
            return
        end

        -- delete preset
        if state.activePresetDialog then
            state.activePresetDialog:destroy()
        end

        local name = value:sub(8)
        state.activePresetDialog = lib.ui.yesNoDialog {
            w = 400,
            h = 100,
            text = getText('UI_OmiChat_DeletePreset_Confirm', name),
            onClick = function(_, _args)
                if _args.internal == 'NO' then
                    return
                end

                API.extension.removeCustomPreset(name, true)

                local currentValue = form:getValue(PATH_PRESET)
                if currentValue == value then
                    refreshPresetsList(form)

                    local values = form.values
                    values.General.Preset = 'Default'
                    form:setControlValue(PATH_PRESET, 'Default')
                end
            end,
        }
    end
end


---@type omi.forms.Args.Generator.Partial
return {
    prefix = 'Sandbox_OmiChat',
    closeOnSave = false,
    rules = {
        General = rules {
            Preset = {
                paddingBottom = 16,
                actionCount = 3,
                getEnumOptions = getPresetOptions,
                onActionClick = onPresetAction,
                onChange = function(args)
                    local deleteBtn = args.info.actionButtons[3]
                    deleteBtn:setEnabled(utils.startsWith(args.value, 'custom:'))
                end,
            },

            CaseInsensitiveChatStreams = PAD_BOTTOM,
            AdminIcon = {
                noFullWidth = true,
                paddingBottom = PAD_N,
            },

            InfoText = {
                displayLines = 10,
                maxLines = 50,
            },

            Variables = NO_REORDER,
        },

        Buffs = rules {
            Enable = {
                toggleFields = {
                    { 'Buffs', 'Cooldown' },
                    { 'Buffs', 'Boredom' },
                    { 'Buffs', 'Unhappiness' },
                    { 'Buffs', 'Hunger' },
                    { 'Buffs', 'Thirst' },
                    { 'Buffs', 'Fatigue' },
                    { 'Buffs', 'CigaretteStress' },
                },
            },
            Cooldown = PAD_BOTTOM,
        },

        Commands = rules {
            Name = rules {
                Mode = { noLabel = true },
            },
            Status = rules {
                Enable = {
                    toggleFields = {
                        { 'Commands', 'Status', 'Range' },
                    },
                },
            },
            Card = {
                childPrefix = 'Sandbox_OmiChat_Commands_Command',
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Card', 'Format' },
                            { 'Commands', 'Card', 'OverheadFormat' },
                            { 'Commands', 'Card', 'ChatFormat' },
                            { 'Commands', 'Card', 'Tags' },
                        },
                    },
                    Items = {
                        noReorderButtons = true,
                        prefix = 'Sandbox_OmiChat_Commands_Card_Items',
                    },
                    Tags = NO_REORDER,
                },
            },
            Roll = {
                childPrefix = 'Sandbox_OmiChat_Commands_Command',
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Roll', 'Format' },
                            { 'Commands', 'Roll', 'OverheadFormat' },
                            { 'Commands', 'Roll', 'ChatFormat' },
                            { 'Commands', 'Roll', 'Tags' },
                        },
                    },
                    Items = {
                        noReorderButtons = true,
                        prefix = 'Sandbox_OmiChat_Commands_Roll_Items',
                    },
                    Tags = NO_REORDER,
                },
            },
            Flip = {
                childPrefix = 'Sandbox_OmiChat_Commands_Command',
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Flip', 'Format' },
                            { 'Commands', 'Flip', 'OverheadFormat' },
                            { 'Commands', 'Flip', 'ChatFormat' },
                            { 'Commands', 'Flip', 'Tags' },
                        },
                    },
                    Items = {
                        noReorderButtons = true,
                        prefix = 'Sandbox_OmiChat_Commands_Flip_Items',
                    },
                    Tags = NO_REORDER,
                },
            },
        },

        Customization = rules {
            EnableCharacterCustomization = {
                paddingTop = PAD_N,
                toggleFields = { { 'Customization', 'CleanEffects' } },
            },
        },

        Discord = rules {
            ShowColorOption = PAD_TOP,
            Tags = NO_REORDER,
        },

        EchoMessages = rules {
            Enable = {
                toggleFields = {
                    { 'EchoMessages', 'ChatFormat' },
                    { 'EchoMessages', 'OverheadFormat' },
                    { 'EchoMessages', 'Tags' },
                },
            },
            Tags = NO_REORDER,
        },

        Format = rules {
            Component = rules {
                EmbeddedQuote = PAD_TOP,
            },
        },

        Language = rules {
            UseDefaultList = {
                inverseToggleFields = { { 'Language', 'List' } },
            },
            List = {
                noLabel = true,
                useFullPage = true,
                paddingBottom = 16,
                arrayDisplayField = 'Name',
                getItemDisplay = function(args)
                    local item = args.value or {} ---@type omichat.Configuration.LanguageDefinition

                    if not utils.isNilOrWhitespace(item.Name) then
                        return item.Name
                    end

                    return getText('Sandbox_OmiChat_Language_untitled')
                end,

                children = {
                    Name = {
                        onChange = function(args)
                            local control = args.form:getFieldControl({ 'Language', 'List', 'Name' }) ---@cast control omi.ui.TextEntry?
                            if not control then
                                return
                            end

                            -- only show required input error after edit
                            local oldText = control:getText()
                            local currentText = control:getInternalText():trim()
                            if #oldText > 0 and #currentText == 0 then
                                control:setRequireValue(true)
                            end
                        end,
                    },
                },
            },

            SelfAddAllowlist = NO_REORDER,
            SelfAddBlocklist = NO_REORDER,

            InterpretationChance = PAD_BOTTOM,
            UnknownLanguageRadio = PAD_BOTTOM,
        },

        NarrativeStyle = rules {
            Enable = {
                toggleFields = {
                    { 'NarrativeStyle', 'OverheadContentFormat' },
                    { 'NarrativeStyle', 'ChatContentFormat' },
                    { 'NarrativeStyle', 'DialogueTagFormat' },
                    { 'NarrativeStyle', 'InputFilter' },
                },
            },

            ChatContentFormat = PAD_BOTTOM,
        },

        Radio = rules {
            Tags = NO_REORDER,
        },

        ServerMessages = rules {
            Tags = NO_REORDER,
        },

        Streams = rules {
            UseDefaultList = {
                inverseToggleFields = { { 'Streams', 'List' } },
            },
            List = {
                noLabel = true,
                useFullPage = true,
                paddingBottom = 16,

                children = {
                    Enable = PAD_BOTTOM,
                    ShortCommand = PAD_BOTTOM,
                    Aliases = PAD_BOTTOM,
                    PerceptionRange = PAD_BOTTOM,
                    OverheadFormat = PAD_BOTTOM,
                    UseNarrativeStyle = PAD_BOTTOM,
                    Tags = NO_REORDER,
                },

                createItem = function()
                    ---@type omichat.Configuration.StreamDefinition
                    local item = {
                        Enable = true,
                        Stream = 'custom',
                        ChatType = 'say',
                        CommandType = 'chat',
                        OverheadFormat = '$Default()',
                        ChatFormat = '$Default()',
                        Range = 30,
                        VerticalRange = 2,
                    }

                    return item
                end,
                getItemDisplay = function(args)
                    local item = args.value or {} ---@type omichat.Configuration.StreamDefinition
                    if not item.Stream or item.Stream == 'custom' then
                        return not utils.isNilOrWhitespace(item.Name) and item.Name or 'custom'
                    end

                    return item.Stream
                end,
                onChange = function(args)
                    local form = args.form
                    local schema = args.schema ---@cast schema omichat.ConfigurationSchema
                    local item = args.parent ---@type omichat.Configuration.StreamDefinition?
                    local index = args.index
                    if not item or not index then
                        return
                    end

                    -- enable/disable all fields
                    local allDisabled = not utils.default(item.Enable, true)
                    local parent = form:getFieldRecord({ 'Streams', 'List' })
                    local childFields = parent and parent.children or {}

                    for key, childRec in pairs(childFields) do
                        if key ~= 'Enable' then
                            form:setFieldControlEnabled(childRec.info, not allDisabled)
                        end
                    end

                    -- disable fields incompatible with built-in streams
                    if not allDisabled then
                        local isCustomStream = not item.Stream or item.Stream == 'custom'
                        local nameField = form:getFieldInfo({ 'Streams', 'List', 'Name' })
                        local chatTypeField = form:getFieldInfo({ 'Streams', 'List', 'ChatType' })
                        local commandTypeField = form:getFieldInfo({ 'Streams', 'List', 'CommandType' })
                        form:setFieldControlEnabled(nameField, isCustomStream)
                        form:setFieldControlEnabled(chatTypeField, isCustomStream)
                        form:setFieldControlEnabled(commandTypeField, isCustomStream)

                        if not isCustomStream then
                            item.Name = nil
                            item.ChatType = schema:getStreamChatType(item.Stream) or 'say'
                            item.CommandType = schema:getStreamCommandType(item.Stream) or 'chat'

                            form:setFieldControlValue(nameField, '')
                            form:setFieldControlValue(chatTypeField, item.ChatType)
                            form:setFieldControlValue(commandTypeField, item.CommandType)
                        end
                    end

                    -- update max range based on stream/chat type
                    local chatType = item.ChatType or schema:getStreamChatType(item.Stream)
                    local maxRange = 30
                    if chatType == 'shout' or item.Stream == 'yell' then
                        maxRange = 60
                    end

                    local rangeControl = form:getFieldControl({ 'Streams', 'List', 'Range' }) ---@cast rangeControl omi.ui.TextEntry?
                    if rangeControl then
                        rangeControl:setMaxValue(maxRange)
                    end

                    local perceiveRangeControl = form:getFieldControl({ 'Streams', 'List', 'PerceptionRange' }) ---@cast perceiveRangeControl omi.ui.TextEntry?
                    if perceiveRangeControl then
                        perceiveRangeControl:setMaxValue(maxRange)
                    end

                    -- enable range & overhead fields only for ranged stream types
                    if not allDisabled then
                        local isRanged = chatType == 'say' or chatType == 'shout'
                        local dependentFields = {
                            { form:getFieldInfo({ 'Streams', 'List', 'Range' }) },
                            { form:getFieldInfo({ 'Streams', 'List', 'VerticalRange' }) },
                            { form:getFieldInfo({ 'Streams', 'List', 'PerceptionRange' }) },
                            { form:getFieldInfo({ 'Streams', 'List', 'OverheadFormat' }) },
                            { form:getFieldInfo({ 'Streams', 'List', 'AttractZombies' }), false },
                        }

                        for _, depFieldInfo in pairs(dependentFields) do
                            local depField = depFieldInfo[1]
                            form:setFieldControlEnabled(depField, isRanged)

                            if not isRanged then
                                form:setFieldControlValue(depField, depFieldInfo[2])
                            end
                        end
                    end
                end,
            },
            GlobalTags = NO_REORDER,
        },

        TypingIndicator = rules {
            Enable = {
                toggleFields = { { 'TypingIndicator', 'Format' } },
            },
        },
    },
}
