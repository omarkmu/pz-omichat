---Information about the mod's configuration options.

local utils = require 'OmiChat/utils'
local Schema = require 'OmiChat/Component/Configuration/SchemaClass'


local PAD_N = 10
local PAD_TOP = { paddingTop = PAD_N }
local PAD_BOTTOM = { paddingBottom = PAD_N }

local field = utils.schema
local array, bool, color, compat, container, double, enum, int, object, set, str =
    field.array, field.bool, field.color, field.compatibility, field.container,
    field.double, field.stringEnum, field.int, field.object, field.set, field.string


---Helper to create a rules table containing only rules for children.
---Wraps the given table in an outer table with a `children` key.
---@param ruleTable table<string, omi.forms.Rules>
---@return omi.forms.Rules
local function rules(ruleTable)
    return { children = ruleTable }
end


return Schema:new {
    properties = {
        VERSION = int(1),

        General = container {
            Preset = enum {
                default = 'Default',
                values = {
                    'Default',
                    'Buffy',
                    'Vanilla',
                },
            },

            AlwaysShowChat = bool(false),
            CaseInsensitiveChatStreams = bool(true),

            ClearOnDeath = set {
                default = utils.set.simple { 'Icon', 'Languages', 'Nickname' },
                items = enum {
                    values = {
                        'Icon',
                        'Languages',
                        'Nickname',
                    },
                },
            },

            MinimumCommandAccessLevel = int(16, 1, 32),

            AdminIcon = str('Item_Sledgehamer'),

            InfoText = str(),
        },

        Buffs = container {
            Enable = bool(false),
            Cooldown = int(15, 0, 1440),

            Boredom = double(0.2, 0, 1),
            Unhappiness = double(0.2, 0, 1),
            Hunger = double(0.1, 0, 1),
            Thirst = double(0.1, 0, 1),
            Fatigue = double(0.1, 0, 1),
            CigaretteStress = double(0.2, 0, 1),
        },

        Callouts = container {
            Format = str('$DefaultOverheadFormat()'),
            SneakFormat = str('$DefaultOverheadFormat()'),
            Range = int(60, 1, 60),
            SneakRange = int(6, 1, 60),
        },

        Commands = container {
            SetName = enum {
                default = 'Nickname',
                values = {
                    'Disable',
                    'Nickname',
                    'Forename',
                    'Fullname',
                    'Forename_Plus_Nickname',
                    'Fullname_Plus_Nickname',
                },
            },

            Card = container {
                Global = bool(false),
                Items = array {
                    items = str(),
                    default = { 'CardDeck' },
                },
                Format = str('$DefaultCardFormat()'),
                OverheadFormat = str('$DefaultOverheadFormat()'),
                ChatFormat = str('$DefaultChatFormat()'),
                Tags = array { items = str() },
            },
            Roll = container {
                Global = bool(false),
                Items = array {
                    items = str(),
                    default = {
                        'Dice',
                        'Dice_00',
                        'Dice_4',
                        'Dice_6',
                        'Dice_8',
                        'Dice_10',
                        'Dice_12',
                        'Dice_20',
                    },
                },
                Format = str('$DefaultRollFormat()'),
                OverheadFormat = str('$DefaultOverheadFormat()'),
                ChatFormat = str('$DefaultChatFormat()'),
                Tags = array { items = str() },
            },
            Flip = container {
                Global = bool(false),
                Items = array { items = str() },
                Format = str('$DefaultFlipFormat()'),
                OverheadFormat = str('$DefaultOverheadFormat()'),
                ChatFormat = str('$DefaultChatFormat()'),
                Tags = array { items = str() },
            },
        },

        Compatibility = container {
            BuffyCharacterBios = compat(),
            BuffyRPGSystem = compat(),
            ChatBubble = compat(),
            SearchPlayers = compat(),
            TrueActionsDancing = compat(),
        },

        Customization = container {
            AllowCustomShouts = bool(true),
            EnableNameColors = bool(true), -- based on speech colors
            EnableCharacterCustomization = bool(false),

            CleanEffects = set {
                default = utils.set.simple { 'Body', 'Clothing' },
                items = enum {
                    values = {
                        'Body',
                        'Clothing',
                    },
                },
            },
        },

        Discord = container {
            ChatFormat = str('$DefaultChatFormat()'),
            Tags = array {
                items = str(),
                default = { 'UseAuthorUsername' },
            },
            DefaultColor = color {
                default = { r = 144, g = 137, b = 218 },
            },
            ShowColorOption = enum {
                default = 'Respect_Server_Setting',
                values = {
                    'Yes',
                    'No',
                    'Respect_Server_Setting',
                },
            },
        },

        EchoMessages = container {
            Enable = bool(false),
            ChatFormat = str('$DefaultChatFormat()'),
            OverheadFormat = str('$DefaultOverheadFormat()'),
            Tags = array {
                items = str(),
                default = { 'OverRadio' },
            },
        },

        Format = container {
            Chat = container {
                Prefix = str('$DefaultChatPrefix()'),
                Final = str('$DefaultFullChatFormat()'),
            },

            Overhead = container {
                Prefix = str('$DefaultOverheadPrefix()'),
                Final = str('$DefaultFullOverheadFormat()'),
            },

            PerceptionRange = container {
                Chat = str('$DefaultPerceptionRangeChatFormat()'),
                Overhead = str('$DefaultPerceptionRangeOverheadFormat()'),
            },

            Component = container {
                Name = str('$DefaultNameFormat()'),
                Tag = str('$DefaultTagFormat()'),
                Timestamp = str('$DefaultTimestampFormat()'),
                Icon = str('$DefaultIconFormat()'),
                Language = str('$DefaultLanguageFormat()'),
                EmbeddedQuote = str('$DefaultEmbeddedQuoteFormat()'),
                EmbeddedAction = str('$DefaultEmbeddedActionFormat()'),
            },

            Filter = container {
                ChatInput = str('$DefaultChatInputFilter()'),
                Name = str('$DefaultNameFilter()'),
            },

            MenuName = container {
                Default = str('$DefaultMenuNameFormat()'),
                Trade = str(),
                Medical = str(),
                SearchPlayer = str(),
                Typing = str(),
                MiniScoreboard = str(),
            },
        },

        Language = container {
            UseDefaultList = bool(true),
            List = array {
                ---@param schema omichat.ConfigurationSchema
                ---@return table
                getDefault = function(_, schema)
                    return schema:getDefaultLanguages()
                end,
                items = object {
                    skipMissing = true,
                    properties = {
                        Name = str(),
                        Signed = bool(false),
                    },
                },
            },

            DefaultSlots = int(1, 0, 50),
            InterpretationRolls = int(2, 0, 10),
            InterpretationChance = int(25, 0, 100),

            UnknownLanguageOverhead = str('$DefaultUnknownLanguageOverheadFormat()'),
            UnknownLanguageChat = str('$DefaultUnknownLanguageFormat()'),
            UnknownLanguageRadio = str('$DefaultUnknownLanguageFormat()'),

            SelfAddAllowlist = array { items = str() },
            SelfAddBlocklist = array { items = str() },
        },

        Macros = container {
            AllowEmotes = bool(true),
        },

        NarrativeStyle = container {
            Enable = bool(false),
            OverheadContentFormat = str('$DefaultNarrativeOverheadFormat()'),
            ChatContentFormat = str('$DefaultNarrativeChatFormat()'),
            DialogueTagFormat = str('$DefaultNarrativeTag()'),
            InputFilter = str('$DefaultNarrativeInputFilter()'),
        },

        Radio = container {
            ChatFormat = str('$DefaultChatFormat()'),
            Tags = array { items = str() },
            DefaultColor = color {
                default = { r = 178, g = 178, b = 178 },
            },
        },

        ServerMessages = container {
            ChatFormat = str('$DefaultChatFormat()'),
            Tags = array {
                items = str(),
                default = { 'NoTimestamp', 'NoTagColon' },
            },
            DefaultColor = color {
                default = { r = 0, g = 128, b = 255 },
            },
        },

        Streams = container {
            GlobalTags = array { items = str() },
            UseDefaultList = bool(true),
            List = array {
                ---@param schema omichat.ConfigurationSchema
                ---@return table
                getDefault = function(_, schema)
                    return schema:processStreams(schema:getDefaultStreams())
                end,
                items = object {
                    skipMissing = true,
                    properties = {
                        Enable = bool(true),

                        Stream = enum {
                            default = 'custom',
                            values = {
                                'custom',
                                'say',
                                'yell',
                                'private',
                                'faction',
                                'safehouse',
                                'general',
                                'admin',
                                'whisper',
                                'low',
                                'me',
                                'meloud',
                                'mequiet',
                                'mewhisper',
                                'do',
                                'doloud',
                                'doquiet',
                                'dowhisper',
                                'ooc',
                            },
                        },

                        Name = str(), -- ignored for non-custom streams
                        Command = str(),
                        ShortCommand = str(),

                        ChatType = enum {
                            default = 'say',
                            values = {
                                'say',
                                'shout',
                                'faction',
                                'safehouse',
                                'whisper',
                                'general',
                                'admin',
                            },
                        },

                        CommandType = enum {
                            default = 'chat',
                            values = {
                                'chat',
                                'rp',
                                'other',
                            },
                        },

                        Tags = array { items = str() },

                        ChatFormat = str('$DefaultChatFormat()'),
                        OverheadFormat = str('$DefaultOverheadFormat()'),
                        Aliases = array { items = str() },

                        DefaultColor = color(),
                        Range = int(30, 1, 60), -- maximum is dependent on chat type
                        VerticalRange = int(2, 1, 32),
                        PerceptionRange = int(0, 0, 60),

                        AllowBuffs = bool(false),
                        AllowEmotes = bool(false),
                        AllowLanguages = bool(false),
                        AllowTypingIndicator = bool(false),
                        AttractZombies = bool(false),

                        UseNarrativeStyle = bool(false),
                    },
                },
            },
        },

        TypingIndicator = container {
            Enable = bool(true),
            Format = str('$DefaultTypingFormat()'),
        },

        ZombieAttraction = container {
            ChatRangeMultiplier = double(0, 0, 10),
            CalloutRange = int(30, 1, 60),
            SneakCalloutRange = int(6, 1, 60),
        },
    },

    form = {
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
                    onChange = function(args)
                        if args.key ~= 'Name' then
                            return
                        end

                        local control = args.form:getFieldControl({ 'Language', 'List', 'Name' }) ---@cast control omi.ui.TextEntry?
                        if control then
                            -- only show required input error after edit
                            local oldText = control:getText()
                            local currentText = control:getInternalText():trim()
                            if #oldText > 0 and #currentText == 0 then
                                control:setRequireValue(true)
                            end
                        end
                    end,
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
    },

    ---@param self omichat.ConfigurationSchema
    ---@param values omichat.Configuration
    onRead = function(self, values)
        -- read default languages
        local languages = values.Language.List
        values._Languages = languages ---@diagnostic disable-line: inject-field

        if type(languages) ~= 'table' or values.Language.UseDefaultList then
            languages = self:getDefaultLanguages()
        end

        -- read default stream data
        local streams = values.Streams.List
        values._Streams = streams ---@diagnostic disable-line: inject-field

        if type(streams) ~= 'table' or #streams == 0 or values.Streams.UseDefaultList then
            streams = self:getDefaultStreams()
        else
            streams = utils.deepcopy(streams)
        end

        values.Language.List = languages
        values.Streams.List = self:processStreams(streams)
    end,

    ---@param values omichat.Configuration
    sanitize = function(_, values)
        values.Streams = values.Streams or {}
        values.Language = values.Language or {}

        values.Streams.List = values._Streams
        values.Language.List = values._Languages
        values._Streams = nil ---@diagnostic disable-line: inject-field
        values._Languages = nil ---@diagnostic disable-line: inject-field
    end,
}
