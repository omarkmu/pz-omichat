---Information about the configuration form layout.

local utils = require 'OmiChat/utils'
local Helpers = require 'OmiChat/Component/Configuration/FormHelpers'
local rules = Helpers.rules

local PAD_N = 10
local PAD_TOP = { paddingTop = PAD_N }
local PAD_BOTTOM = { paddingBottom = PAD_N }
local NO_REORDER = { noReorderButtons = true }

local TAGS = { noReorderButtons = true, onChange = Helpers.onTagChange }
local FORMAT = { init = Helpers.initFormatOption, onInfoClick = Helpers.onFormatInfoClick }

local FORMAT_PAD_TOP = utils.extendCopy(FORMAT, PAD_TOP)
local FORMAT_PAD_BOTTOM = utils.extendCopy(FORMAT, PAD_BOTTOM)


---@type omi.forms.Args.Generator.Partial
return {
    prefix = 'Sandbox_OmiChat',
    closeOnSave = false,
    rules = {
        General = rules {
            Preset = {
                paddingBottom = 16,
                actionCount = 3,
                getEnumOptions = Helpers.getPresetOptions,
                onActionClick = Helpers.onPresetAction,
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

        Callouts = rules {
            Format = FORMAT,
            SneakFormat = FORMAT,
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
                            { 'Commands', 'Card', 'Tags' },
                        },
                    },
                    Items = {
                        noReorderButtons = true,
                        prefix = 'Sandbox_OmiChat_Commands_Card_Items',
                    },
                    Format = FORMAT,
                    OverheadFormat = FORMAT,
                    Tags = TAGS,
                },
            },
            Roll = {
                childPrefix = 'Sandbox_OmiChat_Commands_Command',
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Roll', 'Format' },
                            { 'Commands', 'Roll', 'OverheadFormat' },
                            { 'Commands', 'Roll', 'Tags' },
                        },
                    },
                    Items = {
                        noReorderButtons = true,
                        prefix = 'Sandbox_OmiChat_Commands_Roll_Items',
                    },
                    Format = FORMAT,
                    OverheadFormat = FORMAT,
                    Tags = TAGS,
                },
            },
            Flip = {
                childPrefix = 'Sandbox_OmiChat_Commands_Command',
                children = {
                    Global = {
                        inverseToggleFields = {
                            { 'Commands', 'Flip', 'Format' },
                            { 'Commands', 'Flip', 'OverheadFormat' },
                            { 'Commands', 'Flip', 'Tags' },
                        },
                    },
                    Items = {
                        noReorderButtons = true,
                        prefix = 'Sandbox_OmiChat_Commands_Flip_Items',
                    },
                    Format = FORMAT,
                    OverheadFormat = FORMAT,
                    Tags = TAGS,
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
            ChatFormat = FORMAT,
            ShowColorOption = PAD_TOP,
            Tags = TAGS,
        },

        EchoMessages = rules {
            Enable = {
                toggleFields = {
                    { 'EchoMessages', 'ChatFormat' },
                    { 'EchoMessages', 'OverheadFormat' },
                    { 'EchoMessages', 'Tags' },
                },
            },
            ChatFormat = FORMAT,
            OverheadFormat = FORMAT,
            Tags = TAGS,
        },

        Format = rules {
            Chat = rules {
                Prefix = FORMAT,
                Final = FORMAT,
            },
            Overhead = rules {
                Prefix = FORMAT,
                Final = FORMAT,
            },
            PerceptionRange = rules {
                Chat = FORMAT,
                Overhead = FORMAT,
            },
            Component = rules {
                Name = FORMAT,
                Tag = FORMAT,
                Timestamp = FORMAT,
                Icon = FORMAT,
                Language = FORMAT,

                EmbeddedQuote = FORMAT_PAD_TOP,
                EmbeddedAction = FORMAT,
            },
            Filter = rules {
                ChatInput = FORMAT,
                Name = FORMAT,
                Status = FORMAT,
            },
            MenuName = rules {
                Default = FORMAT,
                Trade = FORMAT,
                Medical = FORMAT,
                SearchPlayer = FORMAT,
                Typing = FORMAT,
                MiniScoreboard = FORMAT,
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
                            local control = args.form:getFieldControl({ 'Language', 'List', 'Name' }) --[[@as omi.ui.TextEntry?]]
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

            UnknownLanguageChat = FORMAT,
            UnknownLanguageOverhead = FORMAT,
            UnknownLanguageRadio = FORMAT_PAD_BOTTOM,
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

            OverheadContentFormat = FORMAT,
            ChatContentFormat = FORMAT_PAD_BOTTOM,

            DialogueTagFormat = FORMAT,
            InputFilter = FORMAT,
        },

        Radio = rules {
            ChatFormat = FORMAT,
            Tags = TAGS,
        },

        ServerMessages = rules {
            ChatFormat = FORMAT,
            Tags = TAGS,
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
                    PerceptionRangeSigned = PAD_BOTTOM,
                    ChatFormat = FORMAT,
                    OverheadFormat = FORMAT_PAD_BOTTOM,
                    UseNarrativeStyle = PAD_BOTTOM,
                    Tags = TAGS,
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
                    local schema = args.schema --[[@as omichat.ConfigurationSchema]]
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

                    local rangeControlNames = { 'Range', 'PerceptionRange', 'PerceptionRangeSigned' }
                    for i = 1, #rangeControlNames do
                        local name = rangeControlNames[i]
                        local rangeControl = form:getFieldControl({ 'Streams', 'List', name }) --[[@as omi.ui.TextEntry?]]
                        if rangeControl then
                            rangeControl:setMaxValue(maxRange)
                        end
                    end

                    -- enable range & overhead fields only for ranged stream types
                    if not allDisabled then
                        local isRanged = chatType == 'say' or chatType == 'shout'
                        local dependentFields = {
                            { form:getFieldInfo({ 'Streams', 'List', 'Range' }) },
                            { form:getFieldInfo({ 'Streams', 'List', 'VerticalRange' }) },
                            { form:getFieldInfo({ 'Streams', 'List', 'PerceptionRange' }) },
                            { form:getFieldInfo({ 'Streams', 'List', 'PerceptionRangeSigned' }) },
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
            GlobalTags = TAGS,
        },

        TypingIndicator = rules {
            Enable = {
                toggleFields = { { 'TypingIndicator', 'Format' } },
            },

            Format = FORMAT,
        },
    },
}
