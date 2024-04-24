---Provides API access to OmiChat.
---@class omichat.api.shared
local OmiChat = require 'OmiChat/API/Shared'

require 'OmiChat/API/SharedLanguages'
require 'OmiChat/Component/InterpolatorLibrary'

--#region deprecated string conversion
-- this will be removed in the next major version

local radioReplacement = { 'UI_OmiChat_radio', 'UI_OmiChat_Radio' }
local rpReplacement = { 'UI_OmiChat_rp_emote', 'UI_OmiChat_RPEmote' }
local replacementMap = {
    ChatFormatCard = { { 'UI_OmiChat_card_local', 'UI_OmiChat_CardLocal' }, rpReplacement },
    ChatFormatRoll = { { 'UI_OmiChat_roll_local', 'UI_OmiChat_RollLocal' }, rpReplacement },
    ChatFormatRadio = { radioReplacement },
    ChatFormatFlip = { rpReplacement },
    ChatFormatDo = { rpReplacement },
    ChatFormatDoLoud = { rpReplacement },
    ChatFormatDoQuiet = { rpReplacement },
    ChatFormatMe = { rpReplacement },
    ChatFormatMeLoud = { rpReplacement },
    ChatFormatMeQuiet = { rpReplacement },
    ChatFormatUnknownLanguage = { rpReplacement },
    ChatFormatUnknownLanguageRadio = { radioReplacement, rpReplacement },
    ChatFormatIncomingPrivate = { { 'UI_OmiChat_private_chat_from', 'UI_OmiChat_PrivateChatFrom' } },
    ChatFormatOutgoingPrivate = { { 'UI_OmiChat_private_chat_to', 'UI_OmiChat_PrivateChatTo' } },
}

---Attempts to apply replacements to a sandbox option.
---@param opt StringSandboxOption
---@return string?
local function tryApplyReplacements(opt)
    if opt:getTableName() ~= 'OmiChat' then
        return
    end

    local name = opt:getShortName()
    local replacements = replacementMap[name]
    if not replacements then
        return
    end

    local value = opt:getValue()
    if not value then
        return
    end

    local originalValue = value
    for i = 1, #replacements do
        local replace = replacements[i]
        value = value:gsub(replace[1], replace[2])
    end

    if value ~= originalValue then
        return value
    end
end

---Updates sandbox options containing deprecated strings.
local function updateDeprecatedStrings()
    local hasChanges = false
    local options = getSandboxOptions()

    -- old strings are deprecated, but removing them entirely would be a breaking change for presets
    -- to prevent broken options, replace them with the corresponding new string. this logic will be removed in 2.0
    for i = 0, options:getNumOptions() - 1 do
        local opt = options:getOptionByIndex(i) ---@type unknown
        local value = tryApplyReplacements(opt)
        if value then
            hasChanges = true
            opt:setValue(value)
        end
    end

    if hasChanges then
        options:toLua()
        options:sendToServer()
    end
end

Events.OnGameBoot.Add(function()
    -- fired after sandbox options load server-side
    -- this should be before clients connect
    if not isServer() then
        return
    end

    updateDeprecatedStrings()
end)

Events.OnGameStart.Add(function()
    -- sandbox options have loaded by this point in Host mode
    if not isCoopHost() then
        return
    end

    updateDeprecatedStrings()
end)

--#endregion

Events.EveryDays.Add(OmiChat.utils.cleanupCache)


return OmiChat


---@alias omichat.ChatTypeString
---| 'general'
---| 'whisper'
---| 'say'
---| 'shout'
---| 'faction'
---| 'safehouse'
---| 'radio'
---| 'admin'
---| 'server'

---@alias omichat.MenuTypeString
---| 'trade'
---| 'medical'
---| 'mini_scoreboard'
---| 'search_player'
---| 'typing'

---@alias omichat.CalloutCategory
---| 'callouts'
---| 'sneakcallouts'

---@alias omichat.ColorCategory
---| omichat.CustomStreamName
---| 'general'
---| 'say'
---| 'shout'
---| 'faction'
---| 'safehouse'
---| 'radio'
---| 'admin'
---| 'server'
---| 'private'
---| 'discord'
---| 'name'
---| 'speech'

---@alias omichat.ModDataField
---| 'nicknames'
---| 'nameColors'
---| 'languages'
---| 'languageSlots'
---| 'currentLanguage'
---| 'icons'

---@alias omichat.AdminOption
---| 'ShowIcon'
---| 'KnowAllLanguages'
---| 'IgnoreMessageRange'

---@class omichat.StreamSearchOptions
---@field excludeChatStreams boolean? Whether to exclude chat streams from the search.
---@field excludeCommandStreams boolean? Whether to exclude custom command streams from the search.
---@field includeVanillaCommandStreams boolean? Whether to include vanilla command streams in the search.

---@class omichat.SearchContext
---@field search string The string to search for.
---@field terminateOnExact boolean? If true, exact matches will terminate the search.
---@field max integer? The maximum search results to return.
---@field searchDisplay boolean? If true, the display string will be searched as well.
---@field filter (fun(value: unknown, args: string[]): boolean)|nil Filter function for results.
---@field display (fun(value: unknown, str: string): string?)|nil Function to retrieve display strings for results.
---@field args table? Argument for the filter function.

---@class omichat.SearchResult
---@field value string
---@field exact boolean
---@field display string?

---@class omichat.SearchResults
---@field results omichat.SearchResult[]
---@field exact omichat.SearchResult?


---@class omichat.LanguageInfoStore
---@field languageCount integer
---@field availableLanguages string
---@field signedLanguages string
---@field idToLanguage table<integer, string>
---@field languageToID table<string, integer>
---@field languageIsSignedMap table<string, boolean>

---@class omichat.CustomStreamInfo
---@field name string The name of the custom stream.
---@field formatID integer The constant ID to use for message formatting.
---@field colorOpt string The name of the option used to determine message color.
---@field rangeOpt string The name of the option used to determine message range.
---@field chatFormatOpt string The name of the option used for the chat format.
---@field overheadFormatOpt string The name of the option used for the overhead format.
---@field chatTypes table<omichat.ChatTypeString, true?> Chat types for which this stream is enabled.
---@field streamAlias string? An alias to use for determining color and range.
---@field autoColorOption false? Whether to automatically add a color option for this stream.
---@field defaultRangeOpt string? The option used for the default message range. Defaults to `RangeSay`.
---@field titleID string? The string ID to use for chat tags associated with this stream.

---@class omichat.FormatterInfo
---@field name string The name of the formatter.
---@field formatID integer The formatter's ID.
---@field overheadFormatOpt string? The name of the option used for the overhead format.

---Options for initializing formatters.
---@class omichat.MetaFormatterOptions
---@field format string The format string to use.

---A table containing color values in [0, 255].
---@class omichat.ColorTable
---@field r integer The red value.
---@field g integer The green value.
---@field b integer The blue value.

---A table containing color values in [0.0, 1.0].
---@class omichat.DecimalRGBColorTable
---@field r number The red value.
---@field g number The green value.
---@field b number The blue value.

---A table containing color values in [0.0, 1.0].
---@class omichat.DecimalRGBAColorTable : omichat.DecimalRGBColorTable
---@field a number The alpha value.

---Global mod data.
---@class omichat.ModData
---@field version integer The current mod data version.
---@field nicknames table<string, string> Map of usernames to chat nicknames.
---@field nameColors table<string, string> Map of usernames to chat color strings.
---@field icons table<string, string> Map of usernames to chat icons.
---@field languages table<string, string[]> Map of usernames to roleplay languages.
---@field languageSlots table<string, integer> Map of usernames to roleplay language slots.
---@field currentLanguage table<string, string> Map of usernames to currently selected roleplay languages.

---Player mod data.
---@class omichat.PlayerModData
---@field currentLanguage string?

---Request to update global mod data fields on the server.
---@class omichat.request.ModDataUpdate
---@field target string The target username.
---@field field omichat.ModDataField The field to update.
---@field fromCommand boolean? Whether this request was created from a command.
---@field value unknown? The value to set on the field.

---Request to report the result of drawing a card on the client.
---@class omichat.request.ReportDrawCard
---@field name string? The name of the player who drew the card, if called for a global message.
---@field card integer The card number, in [1, 13].
---@field suit integer The suit number, in [1, 4].

---Request to report the result of flipping a coin on the client.
---@class omichat.request.ReportFlipCoin
---@field heads boolean True if the result of the flip was heads.

---Request to report the result of rolling dice on the client.
---@class omichat.request.ReportRoll
---@field roll integer The value of the dice roll.
---@field sides integer The number of sides on the dice that was rolled.

---Request to display a message on the client.
---@class omichat.request.ShowMessage
---@field text string? The message text.
---@field stringID string? The string ID of a message to translate.
---@field args string[]? Arguments for message translation.
---@field serverAlert boolean? Whether this should be treated as a server alert.

---Request to roll dice on the server.
---@class omichat.request.RollDice
---@field sides integer The number of sides on the dice to roll.

---Request to notify other players about typing status.
---@class omichat.request.Typing
---@field typing boolean Whether the source player is typing.
---@field range integer? Optional range to limit notifications to.

---Request to update client information about typing.
---@class omichat.request.UpdateTyping
---@field username string Whether the target player is typing.
---@field typing boolean Whether the target player is typing.

---Request to handle a command on the server.
---@class omichat.request.Command
---@field command string The command text, excluding the command itself.
