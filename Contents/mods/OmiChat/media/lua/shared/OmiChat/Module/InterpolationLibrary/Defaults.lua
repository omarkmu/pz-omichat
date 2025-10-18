---Functionality for default interpolation formats.

local API = require 'OmiChat/Module/Shared/Core'
local Library = require 'OmiChat/Module/InterpolationLibrary/Core' ---@class omichat.InterpolationLibrary

---Contains handlers for the `$Default` interpolation function.
---@class omichat.InterpolationLibrary.Defaults
Library.Defaults = Library.Defaults or {}


local utils = API.utils
local config = API.Configuration
local MultiMap = utils.MultiMap
local Helpers = Library.Helpers

local rep = string.rep
local concat = table.concat
local readTags = Helpers.readTags
local readOptions = Helpers.readOptions
local optionOrToken = Helpers.optionOrToken
local optionOrTokenWrapped = Helpers.optionOrTokenWrapped


---Default forwarding function for format strings.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return unknown?
function Library.Default(interpolator, args)
    local target
    if type(args) == 'string' then
        target = args
    else
        local options = readOptions(args)
        target = optionOrToken(interpolator, options, 'DEFAULT')
    end

    local func = target and Library.Defaults[target]
    if func then
        return func(interpolator, args)
    else
        utils.log.once('Tried to call unknown default: ' .. tostring(target))
    end
end


---Default format for text of chat messages.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.Chat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

    local defaultNoColon = tags.IsNarrativeStyle or tags.IsBuffyRoll or tags.IsServerStream or tags.Action
    local noColon = tags.IsRadioStream or (not tags.IncludeColon and (tags.NoColon or defaultNoColon))

    local name = '' ---@type string?
    local includeName = tags.IncludeName or tags.IncludeNameChat
    local excludeName = tags.NoName or tags.NoNameChat or (tags.IsServerStream and not includeName)
    if not excludeName then
        name = options:getString('name')
        if name == '' then
            if tags.UseAuthorUsername then
                name = interpolator:tokenString('author')
            else
                name = interpolator:tokenString('name')
            end
        end
    end

    local message = options:getString('input')
    if message == '' then
        if tags.IsCardCommand then
            message = getText('UI_OmiChat_CardLocal', interpolator:tokenString('card'))
        elseif tags.IsFlipCommand then
            local result = interpolator:tokenBoolean('heads') and 'Heads' or 'Tails'
            message = getText('UI_OmiChat_FlipLocal' .. result)
        elseif tags.IsRollCommand then
            local roll = interpolator:tokenString('roll')
            local sides = interpolator:tokenString('sides')
            message = getText('UI_OmiChat_RollLocal', roll, sides)
        else
            message = interpolator:tokenString('input')
        end
    end

    if tags.IsIncomingPM and not tags.UseVanillaPM and name ~= '' then
        local parens = config:getVariableAsNumber('PMParenthesisCount') or 1
        local pmFrom = getText('UI_OmiChat_PrivateChatFrom', ' <SPACE> ' .. name)

        name = rep('(', parens) .. pmFrom .. rep(')', parens)
    elseif tags.IsOutgoingPM and not excludeName then
        local recipient = options:getString('recipientName')
        if recipient == '' then
            if tags.UseAuthorUsername then
                recipient = interpolator:tokenString('recipient')
            else
                recipient = interpolator:tokenString('recipientName')
            end
        end

        if recipient ~= '' then
            name = recipient
            if tags.UseVanillaPM then
                name = 'to ' .. name
            else
                local parens = config:getVariableAsNumber('PMParenthesisCount') or 1
                local pmTo = getText('UI_OmiChat_PrivateChatTo', ' <SPACE> ' .. name)

                name = rep('(', parens) .. pmTo .. rep(')', parens)
            end
        end
    end

    message = utils.trim(message)
    if message == '' then
        return
    end

    if tags.OOC then
        message = '(( <SPACE> ' .. message .. ' <SPACE> ))'
    end

    local autoCapitalize = tags.AutoCapitalize or tags.AutoCapitalizeChat
    if tags.IsSneakCallout then
        autoCapitalize = tags.AutoCapitalizeSneakCallout
    end

    message = Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = message,
        applyCase = true,
        applyEmbeddedQuotes = true,
        applyEmbeddedActions = true,
        doCapitalize = not tags.IsNarrativeStyle and autoCapitalize,
        doPunctuate = tags.AutoPunctuate or tags.AutoPunctuateChat or (tags.IsNarrativeStyle and tags.AutoPunctuateNarrative),
        doColorActions = tags.AutoColorActions and tags.IsNarrativeStyle,
        doColorQuotes = tags.AutoColorQuotes,
        hasInternalQuote = tags.IsNarrativeStyle,
    }

    if name == '' then
        name = nil
    end

    local prefix = ''
    if tags.IsRadioStream then
        prefix = getText('UI_OmiChat_Radio', tostring(interpolator:token('frequency') or '???'))
        noColon = true

        if not tags.NoColon then
            prefix = prefix .. ': '
        end

        prefix = prefix .. ' <SPACE> '
    end

    if tags.Action then
        if name then
            message = name .. ' <SPACE> ' .. message
        end

        return prefix .. Helpers.wrapActionChat(message, tags)
    end

    if not name then
        return prefix .. message
    end

    if tags.BracketedNames then
        name = '[' .. name .. ']'
    end

    return prefix .. name .. (noColon and '' or ':') .. ' <SPACE> ' .. message
end

---Default format for the final chat text.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string
function Library.Defaults.ChatFinal(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local prefix = optionOrToken(interpolator, options, 'prefix')

    local prefixSpace = not tags.NoPrefixSpace and not tags.NoPrefixSpaceChat
    if prefixSpace and prefix ~= '' then
        prefix = prefix .. ' <SPACE> '
    end

    return prefix .. optionOrToken(interpolator, options, 'input')
end

---Default format for the chat text prefix.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string
function Library.Defaults.ChatPrefix(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local result = {}

    if not tags.NoTimestamp then
        result[#result + 1] = interpolator:tokenString('timestamp')
    end

    result[#result + 1] = interpolator:tokenString('tag')

    if not tags.NoVolumeIndicator and not tags.NoVolumeIndicatorChat then
        local volume = Helpers.getVolumeIndicator(options, tags, true)
        if volume then
            result[#result + 1] = volume
        end
    end

    if tags.IsPerceptionRange and not tags.NoOutOfRangeIndicator and not tags.NoOutOfRangeIndicatorChat then
        result[#result + 1] = '[' .. getText('UI_OmiChat_OutOfRange') .. ']'
    end

    if not tags.NoLanguage and not tags.NoLanguageChat and not tags.IsPerceptionRange then
        result[#result + 1] = interpolator:tokenString('language')
    end

    local buffyCrit = interpolator:tokenString('buffyCrit')
    if buffyCrit ~= '' then
        result[#result + 1] = ' <SPACE> '
        result[#result + 1] = buffyCrit
    end

    if (tags.OverRadio or tags.OverRadioChat) and not tags.IsUnknownLanguage then
        result[#result + 1] = ' <SPACE> '
        result[#result + 1] = Helpers.getOverRadioIndicator(interpolator:token('chatType'))
    end

    local noIcon = tags.NoIcon
    if tags.IsCommand then
        noIcon = tags.NoCommandIcon
    end

    if not noIcon then
        local icon = interpolator:tokenString('icon')
        if icon ~= '' then
            result[#result + 1] = ' <SPACE> '
            result[#result + 1] = icon
        end
    end

    if tags.IncludeAdminIndicator and not tags.NoAdminIndicator then
        if interpolator:tokenBoolean('admin') then
            result[#result + 1] = ' <SPACE> '
            result[#result + 1] = getText('UI_OmiChat_AdminIndicator')
        end
    end

    return concat(result)
end

---Default format for actions embedded in dialogue text.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.EmbeddedAction(interpolator, args)
    local options = Helpers.readOptions(args)
    local tags = Helpers.readTags(interpolator)

    local input = optionOrToken(interpolator, options, 'input')
    if utils.trim(input) == '' then
        return
    end

    local doCapitalize = tags.AutoCapitalize
        or tags.AutoCapitalizeEmbeddedActions
        or (tags.IsNarrativeStyle and tags.AutoCapitalizeNarrative)
    local doPunctuate = tags.AutoPunctuate
        or tags.AutoPunctuateEmbeddedActions
        or (tags.IsNarrativeStyle and tags.AutoPunctuateNarrative)

    return Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = input,
        applyCase = true,
        doCapitalize = doCapitalize,
        doPunctuate = doPunctuate,
    }
end

---Default format for quotes embedded in actions.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.EmbeddedQuote(interpolator, args)
    local options = Helpers.readOptions(args)
    local tags = Helpers.readTags(interpolator)

    local input = optionOrToken(interpolator, options, 'input')
    if utils.trim(input) == '' then
        return
    end

    local doCapitalize = tags.AutoCapitalize
        or tags.AutoCapitalizeEmbeddedQuotes
        or (tags.IsNarrativeStyle and tags.AutoCapitalizeNarrative)
    local doPunctuate = tags.AutoPunctuate
        or tags.AutoPunctuateEmbeddedQuotes
        or (tags.IsNarrativeStyle and tags.AutoPunctuateNarrative)

    return Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = input,
        applyCase = true,
        doCapitalize = doCapitalize,
        doPunctuate = doPunctuate,
    }
end

---Default filter for chat input.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.FilterChatInput(interpolator, args)
    local tags = readTags(interpolator)
    if tags.NoSignedOverRadio then
        local errorID = Helpers.checkSignedOverRadio(interpolator)
        if errorID then
            interpolator:setToken('errorID', errorID)
            return
        end
    end

    local options = readOptions(args)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    local maxLength = options:getNumber('maxLength')
    if maxLength > 0 and #input > maxLength then
        interpolator:setToken('error', getText('UI_OmiLibrary_Error_LengthMax', tostring(maxLength)))
        return
    end

    local truncateLength = options:getNumber('truncateTo', 2000)
    if truncateLength > 0 then
        input = input:sub(1, truncateLength)
    end

    return input
end

---Default filter for names.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.FilterName(interpolator, args)
    local options = readOptions(args)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    local maxLength = options:getNumber('maxLength')
    local minLength = options:getNumber('minLength')
    if maxLength > 0 and #input > maxLength then
        interpolator:setToken('error', getText('UI_OmiLibrary_Error_LengthMax', tostring(maxLength)))
        return
    elseif minLength > 0 and #input < minLength then
        interpolator:setToken('error', getText('UI_OmiLibrary_Error_LengthMin', tostring(minLength)))
        return
    end

    local truncateLength = tonumber(options:get('truncateTo', 40))
    if truncateLength then
        input = input:sub(1, truncateLength)
    end

    return input
end

---Default filter for narrative style messages.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string
function Library.Defaults.FilterNarrativeInput(interpolator, args)
    local options = readOptions(args)
    local input = optionOrToken(interpolator, options, 'input')

    if utils.startsWith(input, '"') then
        input = input:sub(2)
    end

    if utils.endsWith(input, '"') then
        input = input:sub(1, #input - 1)
    end

    return input
end

---Default filter for statuses.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.FilterStatus(interpolator, args)
    local options = readOptions(args)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    local maxLength = options:getNumber('maxLength', 64)
    local minLength = options:getNumber('minLength', 8)
    if maxLength > 0 and #input > maxLength then
        interpolator:setToken('error', getText('UI_OmiLibrary_Error_LengthMax', tostring(maxLength)))
        return
    elseif minLength > 0 and #input < minLength then
        interpolator:setToken('error', getText('UI_OmiLibrary_Error_LengthMin', tostring(minLength)))
        return
    end

    local truncateLength = tonumber(options:get('truncateTo'))
    if truncateLength then
        input = input:sub(1, truncateLength)
    end

    return input
end

---Default format for `/card` command result content.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string
function Library.Defaults.FormatCard(interpolator)
    return 'draws ' .. interpolator:tokenString('card')
end

---Default format for `/flip` command result content.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string
function Library.Defaults.FormatFlip(interpolator)
    local result = interpolator:toBoolean(interpolator:token('heads')) and 'heads' or 'tails'
    return 'flips a coin and gets ' .. result
end

---Default format for `/roll` command result content.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string
function Library.Defaults.FormatRoll(interpolator)
    local roll = interpolator:tokenString('roll')
    local sides = interpolator:tokenString('sides')
    return 'rolls ' .. roll .. ' on a ' .. sides .. '-sided die'
end

---Default format for chat icons.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.Icon(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

    if tags.IsCardCommand then
        return options:getString('cardIcon', 'Item_CardDeck')
    elseif tags.IsFlipCommand then
        -- the plate is the most coin-like icon I could find in vanilla
        return options:getString('flipIcon', 'Item_Plate')
    elseif tags.IsRollCommand or tags.IsBuffyRoll then
        return options:getString('rollIcon', 'Item_Dice')
    end

    local icon = interpolator:tokenString('adminIcon')
    if icon == '' then
        icon = interpolator:tokenString('icon')
    end

    return icon
end

---Default format for roleplay languages in a message prefix.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string?
function Library.Defaults.Language(interpolator)
    local tags = readTags(interpolator)
    if tags.NoLanguage or tags.IsUnknownLanguage then
        return
    end

    local language = interpolator:tokenString('language')
    if language == '' then
        return
    end

    return '[' .. language .. ']'
end

---Default format for a mention in chat text.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string
function Library.Defaults.MentionChat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')

    -- don't include if already included in mention text
    if tags.IncludeMentionAtSignChat and not tags.IncludeMentionAtSign then
        return '@' .. input
    end

    return input
end

---Default format for mention text.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string
function Library.Defaults.MentionText(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')

    if tags.IncludeMentionAtSign then
        return '@' .. input
    end

    return input
end

---Default format for menu names.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string
function Library.Defaults.MenuName(interpolator)
    local menuType = interpolator:tokenString('menuType') ---@type omichat.MenuTypeString
    local name = interpolator:tokenString('name')

    if menuType == 'mini_scoreboard' then
        local username = interpolator:tokenString('username')
        return username .. '[' .. name .. ']'
    end

    return name
end

---Default format for name display in chat.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string
function Library.Defaults.Name(interpolator, args)
    local options = readOptions(args)
    local chatType = interpolator:token('chatType')

    local name = options:getString('name')
    local mode = options:getString('mode'):lower()
    local defaultUsernameMode = name ~= '' and 'name' or 'username'

    -- if a mode isn't given, use preset defaults
    if mode ~= 'username' and mode ~= 'name' and mode ~= 'both' then
        local defaultMode = config:getVariable('DefaultNameMode_' .. chatType)
            or config:getVariable('DefaultNameMode')

        if defaultMode == 'username' then
            mode = defaultUsernameMode
        elseif defaultMode == 'name' or defaultMode == 'both' then
            mode = defaultMode
        elseif chatType == 'general' or chatType == 'admin' or chatType == 'whisper' then
            mode = defaultUsernameMode
        else
            mode = 'name'
        end
    end

    local username = interpolator:tokenString('username')
    if mode == 'username' then
        return username
    end

    if name == '' then
        name = interpolator:tokenString('name')
    end

    if name == '' then
        name = options:getString('defaultName')
    end

    if name == '' then
        name = interpolator:tokenString('forename')
    end

    if mode == 'name' then
        return name
    end

    return username .. ' / ' .. name
end

---Default chat content format for narrative style.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.NarrativeChatContent(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')
    local dialogueTag = optionOrToken(interpolator, options, 'dialogueTag')

    local segments = Helpers.getMessageSegments(input, { optionalActionAsterisk = tags.OptionalActionAsterisk })
    local startQuote = (segments[1] and segments[1].type == 'quote') and '"' or ''
    local endQuote = (segments[#segments] and segments[#segments].type == 'quote') and '"' or ''

    local comma = options:getBoolean('noComma') and '' or ', '
    input = Helpers.ensureWrapped(input, startQuote, endQuote)

    return dialogueTag:lower() .. comma .. input
end

---Default overhead content format for narrative style.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.NarrativeOverheadContent(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrTokenWrapped(interpolator, options, 'input')
    local dialogueTag = optionOrToken(interpolator, options, 'dialogueTag')

    local autoCapitalize = tags.AutoCapitalize or tags.AutoCapitalizeOverhead or tags.AutoCapitalizeNarrative
    if tags.IsSneakCallout then
        autoCapitalize = tags.AutoCapitalizeSneakCallout
    end

    input = Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = input,
        applyCase = true,
        doCapitalize = autoCapitalize,
        doPunctuate = tags.AutoPunctuate or tags.AutoPunctuateOverhead or tags.AutoPunctuateNarrative,
        applyEmbeddedQuotes = true,
        applyEmbeddedActions = true,
        doAutoQuotes = true,
        doReplaceAsterisks = tags.AutoColorActions and tags.IsNarrativeStyle,
    }

    local comma = options:getBoolean('noComma') and '' or ', '
    return dialogueTag .. comma .. input
end

---Default format for a narrative style dialogue tag.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.NarrativeTag(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    if tags.IsSneakCallout then
        return options:getString('sneakCalloutTag', 'whisper shouts')
    elseif tags.Whisper then
        return options:getString('whisperTag', 'whispers')
    elseif tags.Loud then
        return options:getString('loudTag', 'shouts')
    end

    if config.Mentions.Enable then
        input = input:gsub('<@%d+:(.-)>', '%1')
    end

    -- only use the first dialogue segment to determine the punctuation-based narrative tag
    local segments = Helpers.getMessageSegments(input, {
        onlyFirstSegment = true,
        optionalActionAsterisk = tags.OptionalActionAsterisk,
    })

    if #segments == 0 or segments[1].type ~= 'quote' then
        return options:getString('statementTag', 'says')
    end

    local testInput = Helpers.ensureUnwrapped(segments[1].text, '"')
    testInput = utils.trim(utils.removeInvisible(testInput))

    if utils.endsWith(testInput, '?') then
        return options:getString('questionTag', 'asks')
    elseif utils.endsWith(testInput, '!') then
        return options:getString('exclamationTag', 'exclaims')
    elseif #testInput < 10 and not utils.endsWith(testInput, '...') then
        return options:getString('shortStatementTag', 'states')
    end

    return options:getString('statementTag', 'says')
end

---Default format for overhead text of chat messages.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.Overhead(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

    if tags.HideOverhead then
        return
    end

    local name = optionOrToken(interpolator, options, 'name')
    local input = optionOrTokenWrapped(interpolator, options, 'input')

    local autoCapitalize = tags.AutoCapitalize or tags.AutoCapitalizeOverhead
    if tags.IsSneakCallout then
        autoCapitalize = tags.AutoCapitalizeSneakCallout
    end

    input = Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = input,
        applyCase = true,
        applyEmbeddedQuotes = true,
        applyEmbeddedActions = true,
        doCapitalize = not tags.IsNarrativeStyle and autoCapitalize,
        doPunctuate = not tags.IsNarrativeStyle and (tags.AutoPunctuate or tags.AutoPunctuateOverhead),
    }

    if tags.OOC then
        input = '(( ' .. input .. ' ))'
    end

    local noName = tags.NoName or tags.NoNameOverhead
    local includeName = tags.IncludeName or tags.IncludeNameOverhead or tags.IsNarrativeStyle

    if name and includeName and not noName then
        local defaultNoColon = tags.IsNarrativeStyle or tags.Action
        local noColon = not tags.IncludeColon and (tags.NoColon or defaultNoColon)

        input = tostring(name) .. (noColon and ' ' or ': ') .. input
    end

    if tags.Action then
        input = Helpers.wrapActionOverhead(input, tags)
    end

    if (tags.OverRadio or tags.OverRadioOverhead) and not tags.IsUnknownLanguage then
        input = Helpers.getOverRadioIndicator(interpolator:token('chatType')) .. ' ' .. input
    end

    return input
end

---Default format for the full overhead text.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string
function Library.Defaults.OverheadFinal(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local prefix = optionOrToken(interpolator, options, 'prefix')

    local prefixSpace = not tags.NoPrefixSpace and not tags.NoPrefixSpaceOverhead
    if prefixSpace and prefix ~= '' then
        prefix = prefix .. ' '
    end

    return prefix .. optionOrToken(interpolator, options, 'input')
end

---Default format for the overhead prefix.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.OverheadPrefix(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local result = {}

    if not tags.NoVolumeIndicator and not tags.NoVolumeIndicatorOverhead then
        local volume = Helpers.getVolumeIndicator(options, tags)
        if volume then
            result[#result + 1] = volume
        end
    end

    if tags.IsPerceptionRange and not tags.NoOutOfRangeIndicator and not tags.NoOutOfRangeIndicatorOverhead then
        result[#result + 1] = '[Out of Range]'
    end

    if not tags.NoLanguage and not tags.NoLanguageOverhead and not tags.IsPerceptionRange and not tags.IsUnknownLanguage then
        local language = interpolator:tokenString('languageRaw')
        if language ~= '' then
            result[#result + 1] = '[' .. language .. ']'
        end
    end

    if #result == 0 then
        return
    end

    return concat(result, ' ')
end

---Default chat format for out-of-range, perceived messages.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.PerceptionRangeChat(interpolator, args)
    local tags = readTags(interpolator)
    local options = readOptions(args)

    local name = optionOrToken(interpolator, options, 'name')
    if name == '' then
        return
    end

    name = name .. ' <SPACE> '

    return Helpers.wrapActionChat(Helpers.getPerceivedChatString(name, interpolator, tags), tags)
end

---Default overhead format for out-of-range, perceived messages.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.PerceptionRangeOverhead(interpolator, args)
    local tags = readTags(interpolator)
    local options = readOptions(args)

    local name = optionOrToken(interpolator, options, 'name')
    if name == '' then
        return
    end

    return Helpers.wrapActionOverhead(Helpers.getPerceivedChatString(name, interpolator, tags), tags)
end

---Default format for chat tags in a message prefix.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string
function Library.Defaults.Tag(interpolator)
    local tags = readTags(interpolator)

    local tag = '[' .. interpolator:tokenString('tag') .. ']'
    if tags.TagColon or (tags.IsServerStream and not tags.NoTagColon) then
        return tag .. ':'
    end

    return tag
end

---Default format for chat message timestamps in a message prefix.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string
function Library.Defaults.Timestamp(interpolator)
    local hour
    if interpolator:tokenNumber('hourFormat') == 12 then
        hour = interpolator:tokenString('h')
    else
        hour = interpolator:tokenString('HH')
    end

    return '[' .. hour .. ':' .. interpolator:tokenString('mm') .. ']'
end

---Default format for the typing indicator display.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.TypingIndicator(interpolator, args)
    local options = readOptions(args)

    if interpolator:tokenBoolean('alt') then
        return getText('UI_OmiChat_TypingMany')
    end

    local names = options:get('names') or interpolator:token('names')
    if utils.isinstance(names, MultiMap) then
        ---@cast names omi.MultiMap
        local size = names:size()
        if size == 0 then
            return
        end

        local text
        if size < 4 then
            local list = {}
            for el in names:values() do
                list[#list + 1] = el
            end

            text = getText('UI_OmiChat_Typing' .. size, unpack(list))
        else
            text = getText('UI_OmiChat_TypingMany')
        end

        return text
    end
end

---Default format for names in the typing indicator display.
---@param interpolator omichat.Interpolator The interpolator in use.
---@return string?
function Library.Defaults.TypingName(interpolator)
    return interpolator:tokenString('name')
end

---Default format for the content of a message indicating that a language is unknown.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.UnknownLanguageChat(interpolator, args)
    local tags = readTags(interpolator)
    if tags.IsActionUnknownLanguage then
        return Library.Defaults.Chat(interpolator, args)
    end

    local options = readOptions(args)
    local name = optionOrToken(interpolator, options, 'name')
    if tags.NoName or tags.NoNameChat then
        name = ''
    end

    local language = options:get('language') or interpolator:token('languageRaw')
    local dialogueTag = options:get('dialogueTag') or interpolator:token('dialogueTag')
    local base = Helpers.getBaseUnknownLanguageString(tags, language, name, dialogueTag)
    if not base then
        return
    end

    local result = Helpers.getRadioPrefix(interpolator, tags) .. base

    local opt = options:get('input')
    local message = tostring(opt or interpolator:token('unstyled') or interpolator:token('input') or '')
    local fragment = Helpers.getFragmentedMessage(interpolator, message)
    if fragment then
        if tags.AutoColorQuotes then
            local segment = { type = 'quote', text = fragment } ---@type omichat.MessageSegment
            Helpers.colorQuotes({ segment }, options, tags)
            fragment = segment.text
        end

        result = result .. ' <SPACE> ' .. fragment
    end

    return Helpers.wrapActionChat(result, tags)
end

---Default format for the overhead content of a message indicating that a language is unknown.
---@param interpolator omichat.Interpolator The interpolator in use.
---@param args unknown? The first argument passed to the default function.
---@return string?
function Library.Defaults.UnknownLanguageOverhead(interpolator, args)
    local tags = readTags(interpolator)
    if tags.IsActionUnknownLanguage then
        return Library.Defaults.Overhead(interpolator, args)
    end

    local options = readOptions(args)
    local name = optionOrToken(interpolator, options, 'name')
    if tags.NoName or tags.NoNameOverhead then
        name = ''
    end

    local language = options:get('language') or interpolator:token('languageRaw')
    local dialogueTag = options:get('dialogueTag') or interpolator:token('dialogueTag')
    local result = Helpers.getBaseUnknownLanguageString(tags, language, name, dialogueTag, true)
    if not result then
        return
    end

    return Helpers.wrapActionOverhead(result, tags)
end
