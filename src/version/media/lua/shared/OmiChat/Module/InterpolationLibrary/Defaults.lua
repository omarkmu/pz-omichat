---@namespace omichat
---Functionality for default interpolation formats.

local API = require 'OmiChat/Module/Core/Shared'

---@class(partial) InterpolationLibrary
local Library = require 'OmiChat/Module/Core/InterpolationLibrary'

---@class(partial) InterpolationLibrary.Defaults
Library.Defaults = Library.Defaults or {}


local utils = API.utils
local config = API.Configuration
local MultiMap = utils.MultiMap
local Helpers = Library.Helpers

local rep = string.rep
local concat = table.concat
local getText = utils.getText
local readTags = Helpers.readTags
local readOptions = Helpers.readOptions
local optionOrToken = Helpers.optionOrToken


---Default forwarding function for format strings.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return any?
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
        utils.log.warn.once('Tried to call unknown default: %s', target)
    end
end


---Default format for text of chat messages.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.Chat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

    local defaultNoColon = tags.IsNarrativeStyle or tags.IsServerStream or tags.Action
    local noColon = not tags.IncludeColon and (tags.NoColon or tags.NoColonChat or defaultNoColon)

    ---@type string?
    local name = options:getString('name')
    if name == '' then
        if tags.UseAuthorUsername then
            name = interpolator:tokenString('author')
        else
            name = interpolator:tokenString('name')
        end
    end

    local message = options:getString('input')
    if message == '' then
        ---@cast name -?
        message, name = Helpers.getMessage(interpolator, tags, name, true)
    end

    local includeName = tags.IncludeName or tags.IncludeNameChat
    local excludeName = tags.NoName or tags.NoNameChat or (tags.IsServerStream and not includeName)
    if excludeName then
        name = ''
    end

    if tags.IsIncomingPM and not tags.UseVanillaPM and name ~= '' then
        local parens = config.Format.Other.PMParentheses
        local pmFrom = getText('private-chat-from', { name = ' <SPACE> ' .. name })

        name = rep('(', parens) .. pmFrom .. rep(')', parens)
    elseif tags.IsOutgoingPM and name ~= '' then
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
                local parens = config.Format.Other.PMParentheses
                local pmTo = getText('private-chat-to', { name = ' <SPACE> ' .. name })

                name = rep('(', parens) .. pmTo .. rep(')', parens)
            end
        end
    end

    message = utils.trim(message)
    if message == '' then
        return
    end

    if name == '' then
        name = nil
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

    local prefix = ''
    if tags.IsRadioStream then
        prefix = getText('radio', { frequency = tostring(interpolator:token('frequency') or '???') })
        if name and tags.IsNarrativeStyle then
            noColon = true
        end

        if not tags.NoColon and not tags.NoColonChat then
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

    if tags.DoubleBracketedText then
        message = '[[ <SPACE> ' .. message .. ' <SPACE> ]]'
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
        local volume = Helpers.getVolumeIndicator(options, tags)
        if volume then
            result[#result + 1] = volume
        end
    end

    if tags.IsPerceptionRange and not tags.NoOutOfRangeIndicator and not tags.NoOutOfRangeIndicatorChat then
        result[#result + 1] = '[' .. getText('out-of-range') .. ']'
    end

    if not tags.NoLanguage and not tags.NoLanguageChat and not tags.IsPerceptionRange then
        result[#result + 1] = interpolator:tokenString('language')
    end

    if (tags.OverRadio or tags.OverRadioChat) and not tags.IsUnknownLanguage and not tags.IsRadioStream then
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
            result[#result + 1] = getText('admin-indicator')
        end
    end

    return concat(result)
end

---Default format for actions embedded in dialogue text.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.EmbeddedAction(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.EmbeddedQuote(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
        interpolator:setToken('error', getText('@error.length-max', { max = maxLength }))
        return
    end

    local truncateLength = options:getNumber('truncateTo', 2000) --[[@as integer]]
    if truncateLength > 0 then
        input = input:sub(1, truncateLength)
    end

    return input
end

---Default filter for names.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.FilterName(interpolator, args)
    local options = readOptions(args)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    local maxLength = options:getNumber('maxLength')
    local minLength = options:getNumber('minLength')
    if maxLength > 0 and #input > maxLength then
        interpolator:setToken('error', getText('@error.length-max', { max = maxLength }))
        return
    elseif minLength > 0 and #input < minLength then
        interpolator:setToken('error', getText('@error.length-min', { min = minLength }))
        return
    end

    local truncateLength = utils.tointeger(options:get('truncateTo', 40))
    if truncateLength then
        input = input:sub(1, truncateLength)
    end

    return input
end

---Default filter for narrative style messages.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.FilterStatus(interpolator, args)
    local options = readOptions(args)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    local maxLength = options:getNumber('maxLength', 64)
    local minLength = options:getNumber('minLength', 8)
    if maxLength > 0 and #input > maxLength then
        interpolator:setToken('error', getText('@error.length-max', { max = maxLength }))
        return
    elseif minLength > 0 and #input < minLength then
        interpolator:setToken('error', getText('@error.length-min', { min = minLength }))
        return
    end

    local truncateLength = utils.tointeger(options:get('truncateTo'))
    if truncateLength then
        input = input:sub(1, truncateLength)
    end

    return input
end

---Default format for chat icons.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.Icon(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

    if tags.IsCardCommand then
        return options:getString('cardIcon', 'Item_CardDeck')
    elseif tags.IsFlipCommand then
        return options:getString('flipIcon', 'Item_Coin_Silver')
    elseif tags.IsRollCommand then
        return options:getString('rollIcon', 'Item_Dice')
    end

    local icon = interpolator:tokenString('adminIcon')
    if icon == '' then
        icon = interpolator:tokenString('icon')
    end

    return icon
end

---Default format for roleplay languages in a message prefix.
---@param interpolator omi.Interpolator The interpolator in use.
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

---Default format for placeholder text displaying the current language.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.LanguagePlaceholder(interpolator, args)
    local rawLanguage = interpolator:tokenString('rawLanguage')
    local language = interpolator:tokenString('language')

    local default = API.language.getDefault()
    if language == '' then
        language = default and utils.getTranslatedLanguageName(default) or ''
        if language == '' then
            return
        end
    end

    local options = readOptions(args)
    local allowDefault = options:getBoolean('allowDefault')
    if not allowDefault and rawLanguage == default then
        return
    end

    return getText('placeholder-language-indicator', { language = language })
end

---Default format for a mention in chat text.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string
function Library.Defaults.MentionChat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')

    if tags.IncludeMentionAtSign or tags.IncludeMentionAtSignChat then
        return '@' .. input
    end

    return input
end

---Default format for a mention text in overhead text.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string
function Library.Defaults.MentionOverhead(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')

    if tags.IncludeMentionAtSign or tags.IncludeMentionAtSignOverhead then
        return '@' .. input
    end

    return input
end

---Default format for menu names.
---@param interpolator omi.Interpolator The interpolator in use.
---@return string
function Library.Defaults.MenuName(interpolator)
    local menuType = interpolator:tokenString('menuType') --[[@as MenuTypeString]]
    local name = interpolator:tokenString('name')

    if menuType == 'mini_scoreboard' then
        local username = interpolator:tokenString('username')
        return username .. ' [' .. name .. ']'
    end

    return name
end

---Default format for name display in chat.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string
function Library.Defaults.Name(interpolator, args)
    local options = readOptions(args)
    local chatType = interpolator:tokenString('chatType')

    local name = options:getString('name')
    local mode = options:getString('mode'):lower()

    -- if a mode isn't given, use preset defaults
    if mode == '' then
        local other = config.Format.Other
        local defaultMode = other.DefaultNameModeForChatType[chatType] or other.DefaultNameMode

        -- if a name is given as an option, use it even if username is specified
        local defaultUsernameMode = name ~= '' and 'name' or 'username'

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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.NarrativeChatContent(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')
    local dialogueTag = optionOrToken(interpolator, options, 'dialogueTag')

    local autoCapitalize = tags.AutoCapitalize or tags.AutoCapitalizeChat or tags.AutoCapitalizeNarrative
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
        doPunctuate = tags.AutoPunctuate or tags.AutoPunctuateChat or tags.AutoPunctuateNarrative,
        applyEmbeddedQuotes = true,
        applyEmbeddedActions = true,
        doAutoQuotes = true,
        doReplaceAsterisks = tags.AutoColorActions,
    }

    local comma = options:getBoolean('noComma') and '' or ', '
    return dialogueTag:lower() .. comma .. input
end

---Default overhead content format for narrative style.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.NarrativeOverheadContent(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')
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
        doReplaceAsterisks = tags.AutoColorActions,
    }

    local comma = options:getBoolean('noComma') and '' or ', '
    return dialogueTag .. comma .. input
end

---Default format for a narrative style dialogue tag.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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

    local firstSegment = segments[1]
    if not firstSegment or firstSegment.type ~= 'quote' then
        return options:getString('statementTag', 'says')
    end

    local testInput = utils.trim(Helpers.ensureUnwrapped(firstSegment.text, '"'))
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.Overhead(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

    if tags.HideOverhead then
        return
    end

    local name = optionOrToken(interpolator, options, 'name')
    local message = options:getString('input')
    if message == '' then
        ---@cast name -?
        message, name = Helpers.getMessage(interpolator, tags, name)
    end

    local autoCapitalize = tags.AutoCapitalize or tags.AutoCapitalizeOverhead
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
        doPunctuate = not tags.IsNarrativeStyle and (tags.AutoPunctuate or tags.AutoPunctuateOverhead),
    }

    if tags.OOC then
        message = '(( ' .. message .. ' ))'
    end

    local noName = tags.NoName or tags.NoNameOverhead and not (tags.IncludeName or tags.IncludeNameOverhead)
    local includeName = not noName or tags.IsNarrativeStyle
    if name ~= '' and includeName and not noName then
        local defaultNoColon = tags.IsNarrativeStyle or tags.Action
        local noColon = not tags.IncludeColon and (tags.NoColon or tags.NoColonOverhead or defaultNoColon)

        message = tostring(name) .. (noColon and ' ' or ': ') .. message
    end

    if tags.Action then
        message = Helpers.wrapActionOverhead(message, tags)
    end

    if tags.DoubleBracketedText then
        message = '[[ ' .. message .. ' ]]'
    end

    if (tags.OverRadio or tags.OverRadioOverhead) and not tags.IsUnknownLanguage and not tags.IsRadioStream then
        message = Helpers.getOverRadioIndicator(interpolator:token('chatType')) .. ' ' .. message
    end

    return message
end

---Default format for the full overhead text.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
        local language = interpolator:tokenString('language')
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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
---@param interpolator omi.Interpolator The interpolator in use.
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
---@param interpolator omi.Interpolator The interpolator in use.
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
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
---@return string?
function Library.Defaults.TypingIndicator(interpolator, args)
    local options = readOptions(args)

    if interpolator:tokenBoolean('alt') then
        return getText('typing-many')
    end

    local names = options:get('names') or interpolator:token('names')
    if utils.isinstance(names, MultiMap) then
        local size = names:size()
        if size == 0 then
            return
        end

        local text
        if size == 1 then
            text = getText('typing-1', { name = names:first() })
        elseif size < 4 then
            local i = 1
            local typingArgs = {}

            for el in names:values() do
                typingArgs['name' .. i] = el
                i = i + 1
            end

            text = getText('typing-' .. size, typingArgs)
        else
            text = getText('typing-many')
        end

        return text
    end
end

---Default format for names in the typing indicator display.
---@param interpolator omi.Interpolator The interpolator in use.
---@return string?
function Library.Defaults.TypingName(interpolator)
    return interpolator:tokenString('name')
end

---Default format for the content of a message indicating that a language is unknown.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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

    local language = options:get('language') or interpolator:token('rawLanguage')
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
            local segment = { type = 'quote', text = fragment } ---@type MessageSegment
            Helpers.colorQuotes({ segment }, options, tags)
            fragment = segment.text
        end

        result = result .. ' <SPACE> ' .. fragment
    end

    return Helpers.wrapActionChat(result, tags)
end

---Default format for the overhead content of a message indicating that a language is unknown.
---@param interpolator omi.Interpolator The interpolator in use.
---@param args any? The first argument passed to the default function.
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

    local language = options:get('language') or interpolator:token('rawLanguage')
    local dialogueTag = options:get('dialogueTag') or interpolator:token('dialogueTag')
    local result = Helpers.getBaseUnknownLanguageString(tags, language, name, dialogueTag, true)
    if not result then
        return
    end

    return Helpers.wrapActionOverhead(result, tags)
end
