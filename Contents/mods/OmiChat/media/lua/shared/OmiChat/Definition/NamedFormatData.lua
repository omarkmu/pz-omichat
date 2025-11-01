---Information about the tokens and options that format strings accept.
---@namespace omichat

local utils = require 'OmiChat/Utils'


--#region Locals

local TOKENS_NARRATIVE = {
    'narrativeStyle',
    'dialogueTag',
    'unstyled',
}

local TOKENS_MENU_NAME = {
    'name',
    'forename',
    'surname',
    'username',
    'menuType',
}

---@type (FormatDataTranslation | string)[]
local TOKENS_OVERHEAD_NO_NARRATIVE = {
    'chatType',
    'input',
    'username',
    'name',
    'stream',
    'echo',
    'tags',
    'language',
    'languageRaw',
    'callout',
    'sneakCallout',
}

---@type (FormatDataTranslation | string)[]
local TOKENS_CHAT_NO_NARRATIVE = {
    'admin',
    'stream',
    'chatType',
    'author',
    'authorRaw',
    'name',
    'nameRaw',
    'tags',
    'originalTags',
    'originalStream',
    'input',
    'language',
    'languageRaw',
    'unknownLanguage',
    'faction',
    'incomingPM',
    'outgoingPM',
    'recipient',
    'recipientRaw',
    'recipientName',
    'recipientNameRaw',
    'card',
    'heads',
    'roll',
    'sides',
}

---@type (FormatDataTranslation | string)[]
local TOKENS_CHAT_PROCESSED = {
    'tag',
    'chatType',
    'timestamp',
    'admin',
    'echo',
    'stream',
    'iconRaw',
    'buffyRoll',
    'buffyCrit',
    'buffyCritRaw',
    'tags',
    'originalTags',
    'originalStream',
    {
        name = 'input',
        id = 'Sandbox_OmiChat_token_input_processed',
    },
    {
        name = 'language',
        id = 'Sandbox_OmiChat_token_language_processed',
    },
    {
        name = 'icon',
        id = 'Sandbox_OmiChat_token_icon_processed',
    },
}

local OPTIONS_CHAT = {
    'input',
    'name',
    'recipientName',
    'colorTargetTag',
}

local OPTIONS_OVERHEAD = {
    'input',
    'name',
    'colorTargetTag',
}

local OPTIONS_PREFIX = {
    'loudIndicator',
    'quietIndicator',
    'whisperIndicator',
}

local TOKENS_CHAT = utils.appendCopy(TOKENS_CHAT_NO_NARRATIVE, TOKENS_NARRATIVE)
local TOKENS_OVERHEAD = utils.appendCopy(TOKENS_OVERHEAD_NO_NARRATIVE, TOKENS_NARRATIVE)

--#endregion


---@type table<string, FormatData>
return {
    Callouts_Format = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_OVERHEAD,
    },
    Callouts_SneakFormat = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_OVERHEAD,
    },
    Commands_Card_Format = {
        tokens = {
            'suit',
            'number',
            {
                name = 'card',
                id = 'Sandbox_OmiChat_token_card_untranslated',
            },
        },
    },
    Commands_Card_OverheadFormat = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_OVERHEAD,
    },
    Commands_Flip_Format = {
        tokens = {
            'heads',
        },
    },
    Commands_Flip_OverheadFormat = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_OVERHEAD,
    },
    Commands_Roll_Format = {
        tokens = {
            'roll',
            'sides',
        },
    },
    Commands_Roll_OverheadFormat = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_OVERHEAD,
    },
    Discord_ChatFormat = {
        tokens = TOKENS_CHAT,
        options = OPTIONS_CHAT,
    },
    EchoMessages_ChatFormat = {
        tokens = TOKENS_CHAT,
        options = OPTIONS_CHAT,
    },
    EchoMessages_OverheadFormat = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_OVERHEAD,
    },
    Format_Chat_Final = {
        tokens = utils.appendCopy(TOKENS_CHAT_PROCESSED, {
            {
                name = 'prefix',
                id = 'Sandbox_OmiChat_token_prefix_chat_final',
            },
        }),
        options = {
            'prefix',
            'input',
        },
    },
    Format_Chat_Prefix = {
        tokens = TOKENS_CHAT_PROCESSED,
        options = OPTIONS_PREFIX,
    },
    Format_Component_EmbeddedAction = {
        tokenDescription = 'Sandbox_OmiChat_tokendesc_Embedded',
        tokens = {
            'input',
            'tags',
        },
        options = {
            'input',
            'colorTargetTag',
        },
    },
    Format_Component_EmbeddedQuote = {
        tokenDescription = 'Sandbox_OmiChat_tokendesc_Embedded',
        tokens = {
            'input',
            'tags',
        },
        options = {
            'input',
            'colorTargetTag',
        },
    },
    Format_Component_Icon = {
        tokens = {
            'chatType',
            'stream',
            'buffyRoll',
            'icon',
            'adminIcon',
            'tags',
            'originalTags',
            'originalStream',
        },
        options = {
            'cardIcon',
            'flipIcon',
            'rollIcon',
        },
    },
    Format_Component_Language = {
        tokens = {
            'chatType',
            'stream',
            'language',
            'languageRaw',
            'adminIcon',
            'tags',
            'originalTags',
            'originalStream',
        },
    },
    Format_Component_Name = {
        tokens = {
            'chatType',
            'forename',
            'username',
            'surname',
            'username',
            {
                name = 'name',
                id = 'Sandbox_OmiChat_token_name_component',
            },
        },
        options = {
            'mode',
            'defaultName',
            'name',
        },
    },
    Format_Component_Tag = {
        tokens = {
            'chatType',
            'stream',
            'tags',
            'originalTags',
            'originalStream',
            {
                name = 'tag',
                id = 'Sandbox_OmiChat_token_tag_component',
            },
        },
    },
    Format_Component_Timestamp = {
        tokens = {
            'chatType',
            'stream',
            'tags',
            'originalTags',
            'originalStream',
            'hourFormat',
            'P',
            'PP',
            'h',
            'hh',
            'H',
            'HH',
            'm',
            'mm',
            's',
            'ss',
            'ampm',
            'AMPM',
        },
    },
    Format_Filter_ChatInput = {
        canSetError = true,
        tokens = TOKENS_OVERHEAD,
        options = {
            'input',
            'maxLength',
            {
                name = 'truncateTo',
                id = 'Sandbox_OmiChat_option_truncateTo_filter_chat_input',
            },
        },
    },
    Format_Filter_Name = {
        canSetError = true,
        tokens = {
            'input',
            {
                name = 'target',
                id = 'Sandbox_OmiChat_token_target_filter_name',
            },
        },
        options = {
            'minLength',
            'maxLength',
            {
                name = 'truncateTo',
                id = 'Sandbox_OmiChat_option_truncateTo_filter_name',
            },
        },
    },
    Format_Filter_Status = {
        canSetError = true,
        tokens = {
            'input',
        },
        options = {
            'truncateTo',
            {
                name = 'maxLength',
                id = 'Sandbox_OmiChat_option_maxLength_filter_status',
            },
            {
                name = 'minLength',
                id = 'Sandbox_OmiChat_option_minLength_filter_status',
            },
        },
    },
    Format_MenuName_Medical = {
        tokens = TOKENS_MENU_NAME,
    },
    Format_MenuName_MiniScoreboard = {
        tokens = TOKENS_MENU_NAME,
    },
    Format_MenuName_SearchPlayer = {
        tokens = TOKENS_MENU_NAME,
    },
    Format_MenuName_Trade = {
        tokens = TOKENS_MENU_NAME,
    },
    Format_Overhead_Final = {
        tokens = utils.appendCopy(TOKENS_OVERHEAD, {
            {
                name = 'prefix',
                id = 'Sandbox_OmiChat_token_prefix_overhead_final',
            },
        }),
        options = {
            'prefix',
            'input',
        },
    },
    Format_Overhead_Prefix = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_PREFIX,
    },
    Format_PerceptionRange_Chat = {
        tokens = TOKENS_CHAT,
        options = {
            'name',
        },
    },
    Format_PerceptionRange_Overhead = {
        tokens = TOKENS_OVERHEAD,
        options = {
            'name',
        },
    },
    Language_UnknownLanguageChat = {
        tokens = TOKENS_CHAT,
        options = {
            'language',
            'dialogueTag',
            'input',
        },
    },
    Language_UnknownLanguageOverhead = {
        tokens = TOKENS_OVERHEAD,
        options = {
            'language',
            'dialogueTag',
        },
    },
    Language_UnknownLanguageRadio = {
        tokens = TOKENS_CHAT,
        options = OPTIONS_CHAT,
    },
    Mentions_ChatFormat = {
        tokens = {
            'input',
            'onlineID',
            'stream',
            'chatType',
        },
    },
    Mentions_Format = {
        tokens = {
            'input',
            'onlineID',
            'stream',
            'chatType',
        },
    },
    NarrativeStyle_ChatContentFormat = {
        tokens = TOKENS_CHAT,
        options = {
            'noComma',
        },
    },
    NarrativeStyle_DialogueTagFormat = {
        tokens = TOKENS_OVERHEAD_NO_NARRATIVE,
        options = {
            'loudTag',
            'whisperTag',
            'sneakCalloutTag',
            'questionTag',
            'exclamationTag',
            'statementTag',
            'shortStatementTag',
        },
    },
    NarrativeStyle_InputFilter = {
        tokens = TOKENS_OVERHEAD_NO_NARRATIVE,
        options = { 'input' },
    },
    NarrativeStyle_OverheadContentFormat = {
        tokens = TOKENS_OVERHEAD,
        options = {
            'noComma',
        },
    },
    Radio_ChatFormat = {
        tokens = utils.appendCopy(TOKENS_CHAT, {
            'frequency',
        }),
        options = OPTIONS_CHAT,
    },
    ServerMessages_ChatFormat = {
        tokens = TOKENS_CHAT,
        options = OPTIONS_CHAT,
    },
    Streams_List_ChatFormat = {
        tokens = TOKENS_CHAT,
        options = OPTIONS_CHAT,
    },
    Streams_List_OverheadFormat = {
        tokens = TOKENS_OVERHEAD,
        options = OPTIONS_OVERHEAD,
    },
    TypingIndicator_Format = {
        tokens = {
            {
                name = 'alt',
                id = 'Sandbox_OmiChat_token_alt_typing',
            },
            {
                name = 'names',
                id = 'Sandbox_OmiChat_token_names_typing',
            },
        },
        options = {
            {
                name = 'names',
                id = 'Sandbox_OmiChat_option_names_typing',
            },
        },
    },
    TypingIndicator_NameFormat = {
        tokens = {
            'name',
            'forename',
            'surname',
            'username',
        },
    },
}

--#region Type Definitions

---@class FormatData
---@field tokenDescription string? A string ID for the description of a format's tokens.
---@field optionDescription string? A string ID for the description of a format's options.
---@field tokens (FormatDataTranslation | string)[]? A list of token names or translation tables.
---@field options (FormatDataTranslation | string)[]? A list of option names or translation tables.
---@field canSetError boolean? Flag for whether the format can set the error tokens.

--#endregion
