---Functionality for default interpolation formats.

local API = require 'OmiChat/API/Shared/Core'

local rep = string.rep
local concat = table.concat
local utils = API.utils
local MultiMap = utils.MultiMap


---@class omichat.InterpolationLibrary
local Library = require 'OmiChat/Component/InterpolationLibrary/Core'

local Helpers = Library.Helpers
local readTags = Helpers.readTags
local readPreset = Helpers.readPreset
local readOptions = Helpers.readOptions
local optionOrToken = Helpers.optionOrToken


---Default format for `/card` command result content.
---@param interpolator omichat.Interpolator
---@return string
function Library.DefaultCardFormat(interpolator)
    return 'draws ' .. interpolator:tokenString('card')
end

---Default format for text of chat messages.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultChatFormat(interpolator, args)
    local options = readOptions(args)
    local preset = readPreset(options)
    local tags = readTags(interpolator)

    local defaultNoColon = tags.IsNarrativeStyle or tags.IsBuffyRoll or tags.IsServerStream
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

    local message = options:getString('message')
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
            message = interpolator:tokenString('message')
        end
    end

    if tags.IsIncomingPM and not tags.UseVanillaPM and name ~= '' then
        local parens = options:getNumber('parenCount', preset == 'Buffy' and 2 or 1)
        local pmFrom = getText('UI_OmiChat_PrivateChatFrom', name)

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
            name = tostring(recipient)
            if tags.UseVanillaPM then
                name = 'to ' .. name
            else
                local parens = options:getNumber('parenCount', preset == 'Buffy' and 2 or 1)
                local pmTo = getText('UI_OmiChat_PrivateChatTo', tostring(name or ''))

                name = rep('(', parens) .. pmTo .. rep(')', parens)
            end
        end
    end

    message = utils.trim(message)
    if message == '' then
        return
    end

    if tags.OOC then
        message = '(( ' .. message .. ' ))'
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
        applyCase = not tags.IsNarrativeStyle,
        applyEmbeddedQuotes = true,
        applyEmbeddedActions = true,
        doCapitalize = not tags.IsNarrativeStyle and autoCapitalize,
        doPunctuate = tags.AutoPunctuate or tags.AutoPunctuateChat or (tags.IsNarrativeStyle and tags.AutoPunctuateNarrative),
        doColorActions = tags.AutoColorActions and tags.IsNarrativeStyle,
        doColorQuotes = tags.AutoColorQuotes,
    }


    if name == '' then
        name = nil
    end

    local prefix = ''
    if tags.IsRadioStream then
        prefix = getText('UI_OmiChat_Radio', interpolator:tokenString('frequency') or '???')
        noColon = true

        if not tags.NoColon then
            prefix = prefix .. ': '
        end

        prefix = prefix .. ' <SPACE> '
    end

    if tags.Action then
        local result = message
        if name then
            result = name .. ' <SPACE> ' .. message
        end

        if tags.UseActionAsterisks or tags.UseActionAsterisksChat then
            result = '** <SPACE> ' .. result
        elseif not (tags.UseActionPlain or tags.UseActionPlainChat) then
            result = getText('UI_OmiChat_RPEmote', ' <SPACE> ' .. result .. ' <SPACE> ')
        end

        return prefix .. result
    end

    if not name then
        return prefix .. message
    end

    if tags.BracketedNames and not tags.NoBracketedNames then
        name = '[' .. name .. ']'
    end

    return prefix .. name .. (noColon and '' or ':') .. ' <SPACE> ' .. message
end

---Default filter for chat input.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultChatInputFilter(interpolator, args)
    local tags = readTags(interpolator)
    if tags.NoSignedOverRadio then
        local errorID = Helpers.checkSignedOverRadio(interpolator)
        if errorID then
            interpolator:setToken('errorID', errorID)
            return
        end
    end

    local options = readOptions(args)
    local text = utils.trim(optionOrToken(interpolator, options, 'input'))
    local maxLen = options:getNumber('maxLength')
    if maxLen > 0 then
        text = text:sub(1, maxLen)
    end

    return text
end

---Default format for the chat text prefix.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string
function Library.DefaultChatPrefix(interpolator, args)
    local options = readOptions(args)
    local preset = readPreset(options)
    local tags = readTags(interpolator)
    local result = {}

    if not tags.NoTimestamp then
        result[#result + 1] = interpolator:tokenString('timestamp')
    end

    result[#result + 1] = interpolator:tokenString('tag')

    if not tags.NoVolumeIndicator and not tags.NoVolumeIndicatorChat then
        local volume = Helpers.getVolumeIndicator(options, tags, preset)
        if volume then
            result[#result + 1] = volume
        end
    end

    if not tags.NoLanguage and not tags.NoLanguageChat then
        result[#result + 1] = interpolator:tokenString('language')
    end

    if tags.OverRadio then
        result[#result + 1] = ' <SPACE> '
        result[#result + 1] = Helpers.getOverRadioText(interpolator:token('chatType'))
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

    local buffyCrit = interpolator:tokenString('buffyCrit')
    if buffyCrit ~= '' then
        result[#result + 1] = ' <SPACE> '
        result[#result + 1] = buffyCrit
    end

    if tags.IncludeAdminIndicator and not tags.NoAdminIndicator then
        if interpolator:tokenBoolean('admin') then
            result[#result + 1] = ' <SPACE> '
            result[#result + 1] = getText('UI_OmiChat_AdminIndicator')
        end
    end

    return concat(result)
end

---Default format for `/flip` command result content.
---@param interpolator omichat.Interpolator
---@return string
function Library.DefaultFlipFormat(interpolator)
    local result = interpolator:toBoolean(interpolator:token('heads')) and 'heads' or 'tails'
    return 'flips a coin and gets ' .. result
end

---Default format for the full chat text.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string
function Library.DefaultFullChatFormat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local prefix = optionOrToken(interpolator, options, 'prefix')

    local prefixSpace = not tags.NoPrefixSpace and not tags.NoPrefixSpaceChat and not options:getBoolean('noPrefixSpace')
    if prefixSpace and prefix ~= '' then
        prefix = prefix .. ' <SPACE> '
    end

    return prefix .. interpolator:tokenString('input')
end

---Default format for the full overhead text.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string
function Library.DefaultFullOverheadFormat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local prefix = optionOrToken(interpolator, options, 'prefix')

    local prefixSpace = not tags.NoPrefixSpace and not tags.NoPrefixSpaceOverhead and
        not options:getBoolean('noPrefixSpace')

    if prefixSpace and prefix ~= '' then
        prefix = prefix .. ' '
    end

    return prefix .. interpolator:tokenString(1)
end

---Default format for chat icons.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultIconFormat(interpolator, args)
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

---Default format for actions embedded in text.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultEmbeddedActionFormat(interpolator, args)
    local options = Helpers.readOptions(args)
    local tags = Helpers.readTags(interpolator)

    local input = tostring(options:get('input') or interpolator:tokenString('input'))
    if utils.trim(input) == '' then
        return
    end

    input = Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = input,
        applyCase = true,
        doCapitalize = tags.AutoCapitalize or (tags.IsNarrativeStyle and tags.AutoCapitalizeNarrative) or tags.AutoCapitalizeEmbeddedActions,
        doPunctuate = tags.AutoPunctuate or (tags.IsNarrativeStyle and tags.AutoPunctuateNarrative) or tags.AutoPunctuateEmbeddedActions,
    }

    return input
end

---Default format for quotes embedded in actions.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultEmbeddedQuoteFormat(interpolator, args)
    local options = Helpers.readOptions(args)
    local tags = Helpers.readTags(interpolator)

    local input = tostring(options:get('input') or interpolator:tokenString('input'))
    if utils.trim(input) == '' then
        return
    end

    return Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = input,
        applyCase = true,
        doCapitalize = tags.AutoCapitalize or (tags.IsNarrativeStyle and tags.AutoCapitalizeNarrative) or tags.AutoCapitalizeEmbeddedQuotes,
        doPunctuate = tags.AutoPunctuate or (tags.IsNarrativeStyle and tags.AutoPunctuateNarrative) or tags.AutoPunctuateEmbeddedQuotes,
    }
end

---Default format for roleplay languages.
---@param interpolator omichat.Interpolator
---@return string?
function Library.DefaultLanguageFormat(interpolator)
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

---Default format for menu names.
---@param interpolator omichat.Interpolator
---@return string
function Library.DefaultMenuNameFormat(interpolator)
    local menuType = interpolator:tokenString('menuType') ---@type omichat.MenuTypeString
    local name = interpolator:tokenString('name')

    if menuType == 'mini_scoreboard' then
        local username = interpolator:tokenString('username')
        return username .. '[' .. name .. ']'
    end

    return name
end

---Default filter for names.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultNameFilter(interpolator, args)
    local options = readOptions(args)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    local maxLength = tonumber(options:get('maxLength'))
    local minLength = tonumber(options:get('minLength'))
    if maxLength and #input > maxLength then
        interpolator:setToken('error', getText('UI_OmiLibrary_Error_LengthMax', tostring(maxLength)))
        return
    elseif minLength and #input < minLength then
        interpolator:setToken('error', getText('UI_OmiLibrary_Error_LengthMin', tostring(minLength)))
        return
    end

    local truncateLength = tonumber(options:get('truncateTo', 40))
    if truncateLength then
        input = input:sub(1, truncateLength)
    end

    return input
end

---Default format for names.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string
function Library.DefaultNameFormat(interpolator, args)
    local options = readOptions(args)
    local preset = readPreset(options)
    local chatType = interpolator:token('chatType')

    local name = options:getString('name')
    local mode = options:getString('mode'):lower()
    local defaultUsernameMode = name ~= '' and 'name' or 'username'

    -- if a mode isn't given, use preset defaults
    if mode ~= 'username' and mode ~= 'name' and mode ~= 'both' then
        if preset == 'Vanilla' then
            mode = defaultUsernameMode
        elseif preset == 'Buffy' then
            if chatType == 'admin' then
                mode = defaultUsernameMode
            elseif chatType == 'whisper' then
                mode = 'both'
            else
                mode = 'name'
            end
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
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultNarrativeChatFormat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local input = optionOrToken(interpolator, options, 'input')
    local dialogueTag = optionOrToken(interpolator, options, 'dialogueTag')

    local segments = Helpers.getMessageSegments(input, { optionalActionAsterisk = tags.OptionalActionAsterisk })

    local startQuote = (segments[1] and segments[1].type == 'quote') and '"' or ''
    local endQuote = (segments[#segments] and segments[#segments].type == 'quote') and '"' or ''

    local content = Helpers.ensureWrapped(input, startQuote, endQuote)
    local dialogueTagIdent = dialogueTag:gsub('%s', '_')

    local translated = getTextOrNull('UI_OmiChat_NarrativeTag_' .. dialogueTagIdent, content)
    if not translated then
        translated = getText('UI_OmiChat_NarrativeTag', dialogueTag, content)
    end

    return translated
end

---Default filter for narrative style messages.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string
function Library.DefaultNarrativeInputFilter(interpolator, args)
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

---Default overhead content format for narrative style.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultNarrativeOverheadFormat(interpolator, args)
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
        doReplaceAsterisks = tags.AutoColorActions and tags.IsNarrativeStyle,
    }

    local comma = options:getBoolean('noComma') and '' or ', '
    return dialogueTag .. comma .. input
end

---Default format for a narrative style dialogue tag.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultNarrativeTag(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)
    local preset = readPreset(options)
    local input = utils.trim(optionOrToken(interpolator, options, 'input'))

    if tags.IsSneakCallout then
        return options:getString('sneakCalloutTag', preset == 'Buffy' and 'whisper shouts' or 'hisses')
    end

    if tags.Loud then
        return options:getString('loudTag', 'shouts')
    elseif tags.Whisper then
        return options:getString('whisperTag', 'whispers')
    end

    -- only use the first quote to determine the punctuation-based narrative tag
    local testInput = utils.getInternalText(input)
    local segments = Helpers.getMessageSegments(testInput, {
        onlyFirstSegment = true,
        optionalActionAsterisk = tags.OptionalActionAsterisk,
    })

    if #segments > 0 and segments[1].type == 'quote' then
        testInput = Helpers.ensureUnwrapped(segments[1].text, '"')
    else
        testInput = ''
    end

    testInput = utils.trim(testInput)
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
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultOverheadFormat(interpolator, args)
    local options = readOptions(args)
    local tags = readTags(interpolator)

    if tags.HideOverhead then
        return
    end

    local name = tostring(options:get('name') or interpolator:token('name'))
    local input = tostring(options:get('input') or interpolator:tokenString(1))

    local autoCapitalize = tags.AutoCapitalize or tags.AutoCapitalizeOverhead
    if tags.IsSneakCallout then
        autoCapitalize = tags.AutoCapitalizeSneakCallout
    end

    input = Helpers.applySharedFormatting {
        interpolator = interpolator,
        options = options,
        tags = tags,
        input = input,
        applyCase = not tags.IsNarrativeStyle,
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
        local defaultNoColon = tags.NoColonOverhead or tags.IsNarrativeStyle or tags.Action
        local noColon = not tags.IncludeColon and (tags.NoColon or defaultNoColon)

        input = tostring(name) .. (noColon and ' ' or ': ') .. input
    end

    if tags.Action then
        if tags.UseActionAsterisks or tags.UseActionAsterisksOverhead then
            input = '** ' .. input
        elseif not (tags.UseActionPlain or tags.UseActionPlainOverhead) then
            input = '( ' .. input .. ' )'
        end
    end

    if tags.OverRadio then
        input = Helpers.getOverRadioText(interpolator:token('chatType')) .. ' ' .. input
    end

    return input
end

---Default format for the overhead prefix.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultOverheadPrefix(interpolator, args)
    local options = readOptions(args)
    local preset = readPreset(options)
    local tags = readTags(interpolator)
    local result = {}


    if not tags.NoVolumeIndicator and not tags.NoVolumeIndicatorOverhead then
        local volume = Helpers.getVolumeIndicator(options, tags, preset)
        if volume then
            result[#result + 1] = volume
        end
    end

    if not tags.NoLanguage and not tags.NoLanguageOverhead then
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

---Default format for `/roll` command result content.
---@param interpolator omichat.Interpolator
---@return string
function Library.DefaultRollFormat(interpolator)
    local roll = interpolator:tokenString('roll')
    local sides = interpolator:tokenString('sides')
    return 'rolls a ' .. roll .. ' on a ' .. sides .. '-sided die'
end

---Default format for chat tags.
---@param interpolator omichat.Interpolator
---@return string
function Library.DefaultTagFormat(interpolator)
    local tags = readTags(interpolator)

    local tag = '[' .. interpolator:tokenString('tag') .. ']'
    if tags.TagColon or (tags.IsServerStream and not tags.NoTagColon) then
        return tag .. ':'
    end

    return tag
end

---Default format for chat message timestamps.
---@param interpolator omichat.Interpolator
---@return string
function Library.DefaultTimestampFormat(interpolator)
    local hour
    if interpolator:tokenNumber('hourFormat') == 12 then
        hour = interpolator:tokenString('h')
    else
        hour = interpolator:tokenString('HH')
    end

    return '[' .. hour .. ':' .. interpolator:tokenString('mm') .. ']'
end

---Default format for the typing indicator display.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultTypingFormat(interpolator, args)
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

---Default format for the content of a message indicating that a language is unknown.
---@param interpolator omichat.Interpolator
---@param args unknown?
---@return string?
function Library.DefaultUnknownLanguageFormat(interpolator, args)
    local tags = readTags(interpolator)
    if tags.IsActionUnknownLanguage then
        return Library.DefaultChatFormat(interpolator, args)
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

    local prefix = ''
    if tags.IsRadioStream then
        prefix = getText('UI_OmiChat_Radio', tostring(interpolator:token('frequency') or '???'))

        if tags.IncludeColon or not (tags.NoColon or tags.NoColonChat or tags.IsNarrativeStyle or tags.IsBuffyRoll) then
            prefix = prefix .. ':'
        end

        prefix = prefix .. ' <SPACE> '
    elseif tags.OverRadio or tags.IsEchoMessage then
        prefix = Helpers.getOverRadioText(interpolator:token('chatType')) .. ' <SPACE> '
    end

    local result = prefix .. base

    local messageOpt = options:get('message')
    local message = tostring(messageOpt or interpolator:token('unstyled') or interpolator:token('message') or '')
    local fragment = Helpers.getFragmentedMessage(interpolator, message)
    if fragment then
        if tags.AutoColorQuotes then
            local segment = { type = 'quote', text = fragment } ---@type omichat.MessageSegment
            Helpers.colorQuotes({ segment }, options, tags)
            fragment = segment.text
        end

        result = result .. ' <SPACE> ' .. fragment
    end

    if tags.UseActionAsterisks or tags.UseActionAsterisksChat then
        return '** <SPACE> ' .. result
    elseif tags.UseActionPlain or tags.UseActionPlainChat then
        return result
    end

    return getText('UI_OmiChat_RPEmote', ' <SPACE> ' .. result)
end
