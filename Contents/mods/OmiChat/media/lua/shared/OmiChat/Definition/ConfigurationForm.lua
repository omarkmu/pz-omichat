---Information about the configuration form layout.

local utils = require 'OmiChat/utils'


local PAD_N = 10
local PAD_TOP = { paddingTop = PAD_N }
local PAD_BOTTOM = { paddingBottom = PAD_N }

---Helper to create a rules table containing only rules for children.
---Wraps the given table in an outer table with a `children` key.
---@param ruleTable table<string, omi.forms.Rules>
---@return omi.forms.Rules
local function rules(ruleTable)
    return { children = ruleTable }
end


---@type omi.forms.Args.Generator.Partial
return {
    prefix = 'Sandbox_OmiChat',
    closeOnSave = false,
    rules = {
        General = rules {
            Preset = {
                paddingBottom = 16,
                onActionClick = function(args)
                    local schema = args.schema ---@cast schema omichat.ConfigurationSchema
                    local preset = schema.getPreset(args.value)
                    local values = args.values
                    if not preset then
                        return
                    end

                    local path = { 'General', 'InfoText' }
                    local infoText = args.form:getValue(path)

                    args.form:setValues(preset:getValues(schema))

                    -- keep the existing info text when applying a preset
                    values.General = values.General or {}
                    values.General.InfoText = infoText
                    args.form:setControlValue(path, infoText)

                    args.form:setStatusMessage(getText('Sandbox_OmiChat_status_preset', preset:getName()))
                end,
            },

            CaseInsensitiveChatStreams = PAD_BOTTOM,
            ClearOnDeath = PAD_BOTTOM,
            AdminIcon = {
                noFullWidth = true,
                paddingBottom = PAD_N,
            },

            InfoText = {
                displayLines = 10,
                maxLines = 50,
            },
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
                    Items = { prefix = 'Sandbox_OmiChat_Commands_Card_Items' },
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Card', 'Format' },
                            { 'Commands', 'Card', 'OverheadFormat' },
                            { 'Commands', 'Card', 'ChatFormat' },
                            { 'Commands', 'Card', 'Tags' },
                        },
                    },
                },
            },
            Roll = {
                childPrefix = 'Sandbox_OmiChat_Commands_Command',
                children = {
                    Items = { prefix = 'Sandbox_OmiChat_Commands_Roll_Items' },
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Roll', 'Format' },
                            { 'Commands', 'Roll', 'OverheadFormat' },
                            { 'Commands', 'Roll', 'ChatFormat' },
                            { 'Commands', 'Roll', 'Tags' },
                        },
                    },
                },
            },
            Flip = {
                childPrefix = 'Sandbox_OmiChat_Commands_Command',
                children = {
                    Items = { prefix = 'Sandbox_OmiChat_Commands_Flip_Items' },
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Flip', 'Format' },
                            { 'Commands', 'Flip', 'OverheadFormat' },
                            { 'Commands', 'Flip', 'ChatFormat' },
                            { 'Commands', 'Flip', 'Tags' },
                        },
                    },
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
        },

        EchoMessages = rules {
            Enable = {
                toggleFields = {
                    { 'EchoMessages', 'ChatFormat' },
                    { 'EchoMessages', 'OverheadFormat' },
                    { 'EchoMessages', 'Tags' },
                },
            },
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

        TypingIndicator = rules {
            Enable = {
                toggleFields = { { 'TypingIndicator', 'Format' } },
            },
        },

        Streams = rules {
            UseDefaultList = {
                inverseToggleFields = { { 'Streams', 'List' } },
            },
            List = {
                noLabel = true,
                useFullPage = true,

                children = {
                    Enable = PAD_BOTTOM,
                    ShortCommand = PAD_BOTTOM,
                    Aliases = PAD_BOTTOM,
                    PerceptionRange = PAD_BOTTOM,
                },

                createItem = function()
                    ---@type omichat.Configuration.StreamDefinition
                    local item = {
                        Enable = true,
                        Stream = 'custom',
                        ChatType = 'say',
                        CommandType = 'chat',
                        OverheadFormat = '$DefaultOverheadFormat()',
                        ChatFormat = '$DefaultChatFormat()',
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
        },
    },
}
