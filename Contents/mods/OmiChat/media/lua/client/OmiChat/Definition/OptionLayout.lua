---Layout table for sandbox options.

---@alias omichat.CategoryLayoutElement { type: 'heading', text: string }
---@alias omichat.PaddingLayoutElement { type: 'padding', pad: integer? }
---@alias omichat.PresetLayoutElement { type: 'presets', presets: table }

---@alias omichat.LayoutElement
---| string
---| omichat.CategoryLayoutElement
---| omichat.PaddingLayoutElement
---| omichat.PresetLayoutElement


---Creates a layout element for a category heading.
---@param id string
---@return omichat.CategoryLayoutElement
local function category(id)
    return {
        type = 'heading',
        text = getText('Sandbox_OCCategory_' .. id),
    }
end

---Returns a layout element for padding.
---@param padAmount integer?
---@return omichat.PaddingLayoutElement
local function padding(padAmount)
    return {
        type = 'padding',
        pad = padAmount,
    }
end

---Returns a layout element for sandbox option presets.
---@return omichat.PresetLayoutElement
local function presets()
    return {
        type = 'presets',
        presets = {
            {
                name = 'Default',
                options = require 'OmiChat/SandboxPreset/default',
            },
            {
                name = 'Buffy',
                options = require 'OmiChat/SandboxPreset/buffy',
            },
            {
                name = 'Vanilla',
                options = require 'OmiChat/SandboxPreset/vanilla',
            },
        },
    }
end

---Checks the sandbox option layout for unknown or missing options.
---@param layout omichat.LayoutElement[]
---@return omichat.LayoutElement[]
local function check(layout)
    local errors = {}
    local seen = {}
    local vars = SandboxVars.OmiChat

    for i = 1, #layout do
        local el = layout[i]
        if type(el) == 'string' then
            if vars[el] ~= nil then
                seen[el] = true
            elseif seen[el] then
                errors[#errors + 1] = 'Duplicate option: ' .. el
            else
                errors[#errors + 1] = 'Unknown option: ' .. el
            end
        end
    end

    for k in pairs(vars) do
        if not seen[k] then
            errors[#errors + 1] = 'Missing option: ' .. k
        end
    end

    if #errors > 0 then
        error('[OmiChat] Invalid option layout.\n' .. table.concat(errors, '\n'))
    end

    return layout
end


return check {
    presets(),

    category('Basic'),
    'EnableEmotes',
    'EnableSetNameColor',
    'EnableSetSpeechColor',
    'EnableSpeechColorAsDefaultNameColor',
    'EnableFactionColorAsDefault',
    'EnableCaseInsensitiveChatStreams',
    'EnableAlwaysShowChat',

    padding(),
    'EnableCustomShouts',
    'CustomShoutMaxLength',
    'MaximumCustomShouts',

    padding(),
    'EnableCharacterCustomization',
    'EnableCleanCharacter',

    padding(),
    'EnableSetName',
    'FilterNickname',

    padding(),
    'PredicateShowTypingIndicator',
    'FormatTyping',

    padding(),
    'PredicateUseNameColor',
    'PredicateTransmitOverRadio',

    padding(),
    'PredicateApplyBuff',
    'BuffCooldown',

    padding(),
    'FormatAdminIcon',
    'MinimumCommandAccessLevel',

    padding(),
    'PredicateClearOnDeath',

    padding(),
    'FormatInfo',

    category('Compatibility'),
    'EnableCompatBuffyRPGSystem',
    'EnableCompatChatBubble',
    'EnableCompatSearchPlayers',
    'EnableCompatTAD',

    category('Commands'),
    'FormatCard',
    'OverheadFormatCard',
    'ChatFormatCard',
    'CardItems',

    padding(),
    'FormatRoll',
    'OverheadFormatRoll',
    'ChatFormatRoll',
    'DiceItems',

    padding(),
    'FormatFlip',
    'OverheadFormatFlip',
    'ChatFormatFlip',
    'CoinItems',

    category('Ranges'),
    'RangeCallout',
    'RangeSneakCallout',
    'RangeVertical',
    'RangeCalloutZombies',
    'RangeSneakCalloutZombies',
    'RangeMultiplierZombies',
    'PredicateAttractZombies',

    category('Languages'),
    'PredicateAllowLanguage',
    'AvailableLanguages',
    'SignedLanguages',
    'AddLanguageAllowlist',
    'AddLanguageBlocklist',
    'LanguageSlots',
    'InterpretationRolls',
    'InterpretationChance',
    'FormatLanguage',
    'ChatFormatUnknownLanguage',
    'ChatFormatUnknownLanguageRadio',

    category('NarrativeStyle'),
    'PredicateUseNarrativeStyle',
    'FormatNarrativeDialogueTag',
    'FormatNarrativePunctuation',
    'FilterNarrativeStyle',
    'PatternNarrativeCustomTag',

    category('ChatStreams'),
    'FormatAliases',

    padding(),
    'ChatFormatFull',
    'OverheadFormatFull',
    'OverheadFormatOther',
    'FormatChatPrefix',
    'FormatOverheadPrefix',

    padding(),
    'PredicateEnableStream',
    'PredicateAllowChatInput',
    'FilterChatInput',

    padding(),
    'ChatFormatEcho',
    'OverheadFormatEcho',

    padding(),
    'ChatFormatServer',
    'ColorServer',

    padding(),
    'ChatFormatDiscord',
    'ColorDiscord',
    'EnableDiscordColorOption',

    padding(),
    'ChatFormatRadio',
    'ColorRadio',

    padding(),
    'ChatFormatIncomingPrivate',
    'ChatFormatOutgoingPrivate',
    'ColorPrivate',

    padding(),
    'ChatFormatAdmin',
    'ColorAdmin',

    padding(),
    'ChatFormatGeneral',
    'ColorGeneral',

    padding(),
    'ChatFormatFaction',
    'ColorFaction',

    padding(),
    'ChatFormatSafehouse',
    'ColorSafehouse',

    padding(),
    'ChatFormatSay',
    'RangeSay',
    'ColorSay',

    padding(),
    'ChatFormatYell',
    'RangeYell',
    'ColorYell',

    padding(),
    'ChatFormatWhisper',
    'OverheadFormatWhisper',
    'RangeWhisper',
    'ColorWhisper',

    padding(),
    'ChatFormatLow',
    'OverheadFormatLow',
    'RangeLow',
    'ColorLow',

    padding(),
    'ChatFormatOoc',
    'OverheadFormatOoc',
    'RangeOoc',
    'ColorOoc',

    padding(),
    'ChatFormatMe',
    'OverheadFormatMe',
    'RangeMe',
    'ColorMe',

    padding(),
    'ChatFormatMeQuiet',
    'OverheadFormatMeQuiet',
    'RangeMeQuiet',
    'ColorMeQuiet',

    padding(),
    'ChatFormatMeLoud',
    'OverheadFormatMeLoud',
    'RangeMeLoud',
    'ColorMeLoud',

    padding(),
    'ChatFormatDo',
    'OverheadFormatDo',
    'RangeDo',
    'ColorDo',

    padding(),
    'ChatFormatDoQuiet',
    'OverheadFormatDoQuiet',
    'RangeDoQuiet',
    'ColorDoQuiet',

    padding(),
    'ChatFormatDoLoud',
    'OverheadFormatDoLoud',
    'RangeDoLoud',
    'ColorDoLoud',

    category('OtherFormats'),
    'FormatName',
    'FormatMenuName',
    'FormatTag',
    'FormatTimestamp',
    'FormatIcon',
}
