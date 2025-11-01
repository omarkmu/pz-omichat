---Helpers for interpolation functions.
---@namespace omichat

local API = require 'OmiChat/Module/Shared/Core'
local API_C = API --[[@as api.client]]

local concat = table.concat
local sort = table.sort
local utils = API.utils
local config = API.Configuration
local MultiMap = utils.MultiMap
local baseLib = utils.lib.interpolate.Libraries
local stringLib = baseLib.string

local IS_CLIENT = not isServer()

local ASTERISK_CHAR = utils.encodeInvisibleCharacter(config.ID_ASTERISK_SIGNAL)
local ASTERISK_PREFIX_PATTERN = '^(%s*[*' .. ASTERISK_CHAR .. '])(.+)'
local ASTERISK_DELIM_PATTERN = '^"%s*[*' .. ASTERISK_CHAR .. ']'


---@class InterpolationLibrary.Helpers
local Helpers = {}


---Adds quote characters to quote segments if they're not already present.
---@param segments MessageSegment[] The message segments list.
function Helpers.applyAutoQuotes(segments)
    for i = 1, #segments do
        local quote = segments[i]
        if quote.type == 'quote' and quote.text ~= '' then
            quote.text = Helpers.ensureWrapped(quote.text, '"')
        end
    end
end

---Performs formatting shared between multiple default formats.
---@param args Args.PerformSharedOperations Arguments for formatting.
---@return string result The result of applying the formatting.
function Helpers.applySharedFormatting(args)
    local input = args.input
    local tags = args.tags

    local doEmbeddedActions = args.applyEmbeddedActions and Helpers.shouldFormatEmbeddedActions(tags)
    local doEmbeddedQuotes = args.applyEmbeddedQuotes and Helpers.shouldFormatEmbeddedQuotes(tags)

    local doSegments = args.doColorActions
        or args.doColorQuotes
        or args.doReplaceAsterisks
        or doEmbeddedQuotes
        or doEmbeddedActions

    -- if we don't need to process segments, don't bother splitting the string
    if not doSegments then
        if args.applyCase then
            input = Helpers.case(input, tags)
        end

        local isAction = not tags.IsEmbeddedQuote and (tags.Action or tags.IsEmbeddedAction)
        if args.doCapitalize then
            local prefix = ''
            if isAction then
                local matchPrefix, matchInput = input:match(ASTERISK_PREFIX_PATTERN)
                if matchPrefix and matchInput then
                    prefix, input = matchPrefix, matchInput
                end
            end

            input = prefix .. Helpers.capitalize(input)
        end

        if args.doPunctuate then
            local mark = (tags.Loud and not isAction and not tags.IsSneakCallout) and '!' or '.'
            input = Helpers.punctuate(input, mark)
        end

        if args.doAutoQuotes then
            input = Helpers.ensureWrapped(input, '"')
        end

        return input
    end

    local options = args.options
    local segments, prefix, suffix = Helpers.getMessageSegments(input, {
        startInAction = tags.Action,
        optionalActionAsterisk = tags.OptionalActionAsterisk,
        hasInternalQuote = args.hasInternalQuote,
    })

    local doBasicFormatting = args.applyCase or args.doCapitalize or args.doPunctuate

    if doEmbeddedQuotes then
        Helpers.formatEmbeddedQuotes(segments, args.interpolator)
    end

    if doEmbeddedActions then
        Helpers.formatEmbeddedActions(segments, args.interpolator)
    end

    if args.doReplaceAsterisks then
        Helpers.replaceColorActionsAsterisks(segments)
    end

    if doBasicFormatting or doEmbeddedActions or args.doColorActions then
        Helpers.formatQuoteSegments(segments, tags, args)
    end

    if args.doAutoQuotes then
        Helpers.applyAutoQuotes(segments)
    end

    if doBasicFormatting or doEmbeddedQuotes or args.doColorQuotes then
        Helpers.formatActionSegments(segments, tags, args)
    end

    if args.doColorActions then
        Helpers.colorActions(segments, options, tags)
    end

    if args.doColorQuotes then
        Helpers.colorQuotes(segments, options, tags)
    end

    return prefix .. Helpers.combineSegments(segments) .. suffix
end

---Capitalizes the first non-invisible character of a string. Handles leading spaces.
---@param input string The input text.
---@return string capitalized The capitalized text.
function Helpers.capitalize(input)
    local prefix, suffix
    input, prefix, suffix = utils.getInternalText(input)

    local spaces, first = input:match('^(%s*)()')
    spaces = spaces or ''
    if first then
        input = input:sub(first)
    end

    -- doesn't actually use the interpolator
    ---@diagnostic disable-next-line: param-type-not-match
    input = stringLib.Capitalize(nil, input)

    return prefix .. spaces .. input .. suffix
end

---Modifies the case of the input depending on the tags.
---@param input string The input text.
---@param tags omi.SetTable<string> A set of tags.
---@return string text The input string with modifications based on the tags.
function Helpers.case(input, tags)
    local doUppercase = tags.Uppercase
    local doLowercase = tags.Lowercase
    if tags.IsNarrativeStyle then
        doUppercase = false
        doLowercase = false
    elseif tags.IsSneakCallout then
        doUppercase = tags.UppercaseSneakCallout
        doLowercase = false
    end

    if doUppercase then
        input = input:upper()
    elseif doLowercase then
        input = input:lower()
    end

    return input
end

---Checks whether the language being sent is signed and returns an error ID if it is.
---The translation of the error assumes the stream is intended to be a "radio" channel for RP purposes.
---@param interpolator omi.Interpolator The interpolator in use.
---@return string? errorID The string ID of the error message.
function Helpers.checkSignedOverRadio(interpolator)
    local language = interpolator:token('languageRaw')
    if not language or not API.language.isSigned(language) then
        return
    end

    local errorID = 'UI_OmiChat_Error_SignedRadio'
    local chatType = interpolator:token('chatType')
    if chatType == 'safehouse' then
        errorID = 'UI_OmiChat_Error_SignedSafehouseRadio'
    elseif chatType == 'faction' then
        errorID = 'UI_OmiChat_Error_SignedFactionRadio'
    end

    return errorID
end

---Colors actions based on the stream tagged with `ActionColorTarget`.
---@param segments MessageSegment[] The message segments list.
---@param options omi.MultiMap? A multimap of options.
---@param tags omi.SetTable<string>? A set of tags.
function Helpers.colorActions(segments, options, tags)
    tags = tags or {}
    local color = Helpers.getColorFromTarget('ActionColorTarget', options, tags)
    if color == '' then
        return
    end

    local keepAsterisk = tags.KeepActionAsterisk
    for i = 1, #segments do
        local part = segments[i]
        if part.type == 'action' then
            local text = part.text:gsub(ASTERISK_CHAR, '*')
            local space, asterisk, after = text:match('^(%s*)(%*)()')
            if asterisk and not keepAsterisk then
                text = space .. text:sub(after)
            end

            part.text = ' <SPACE> ' .. color .. text .. ' <POPRGB> <SPACE> '
        end
    end
end

---Colors quotes based on the stream tagged with `QuoteColorTarget`.
---@param segments MessageSegment[] The message segments list.
---@param options omi.MultiMap? A multimap of options.
---@param tags omi.SetTable<string>? A set of tags.
function Helpers.colorQuotes(segments, options, tags)
    local color = Helpers.getColorFromTarget('QuoteColorTarget', options, tags)
    if color == '' then
        return
    end

    for i = 1, #segments do
        local segment = segments[i]
        if segment.type == 'quote' then
            segment.text = ' <SPACE> ' .. color .. segment.text .. ' <POPRGB> <SPACE> '
        end
    end
end

---Concatenates message segments into a string.
---@param segments MessageSegment[] The message segments list.
---@return string combined A single string containing the merged segments.
function Helpers.combineSegments(segments)
    local result = {}

    for i = 1, #segments do
        result[#result + 1] = segments[i].text
    end

    return concat(result)
end

---Removes the given prefix and suffix from the text, if present.
---@param input string The input text.
---@param prefix string The prefix to remove.
---@param suffix string? The suffix to remove. Defaults to `prefix`.
---@return string unwrapped The unwrapped text.
function Helpers.ensureUnwrapped(input, prefix, suffix)
    suffix = suffix or prefix
    if utils.startsWith(input, prefix) then
        input = input:sub(2)
    end

    if utils.endsWith(input, suffix) then
        input = input:sub(1, #input - 1)
    end

    return input
end

---Wraps text in characters, if it's not already wrapped.
---@param input string The input text.
---@param prefix string The prefix to add.
---@param suffix string? The suffix to add. Defaults to `prefix`.
---@return string wrapped The wrapped text.
function Helpers.ensureWrapped(input, prefix, suffix)
    suffix = suffix or prefix
    if not utils.startsWith(input, prefix) then
        input = prefix .. input
    end

    if not utils.endsWith(input, suffix) then
        input = input .. suffix
    end

    return input
end

---Formats segments that have been tagged as actions.
---@param segments MessageSegment[] The message segments list.
---@param tags omi.SetTable<string> A set of tags.
---@param args Args.PerformSharedOperations Arguments for the formatting.
function Helpers.formatActionSegments(segments, tags, args)
    local skipCapitalize = tags.AutoCapitalizeNonInitialSegments
    local shouldCapitalize = args.doCapitalize or skipCapitalize

    for i = 1, #segments do
        local action = segments[i]
        if action.type == 'action' then
            local text = action.text
            if shouldCapitalize and not skipCapitalize then
                local prefix = ''
                local matchPrefix, matchInput = text:match(ASTERISK_PREFIX_PATTERN)
                if matchPrefix and matchInput then
                    prefix, text = matchPrefix, matchInput
                end

                text = prefix .. Helpers.capitalize(text)
            end

            if args.applyCase then
                text = Helpers.case(text, tags)
            end

            if args.doPunctuate then
                text = Helpers.punctuate(text)
            end

            action.text = text
            skipCapitalize = false
        end
    end
end

---Formats segments that have been tagged as quotes.
---@param segments MessageSegment[] The message segments list.
---@param tags omi.SetTable<string> A set of tags.
---@param args Args.PerformSharedOperations Arguments for the formatting.
function Helpers.formatQuoteSegments(segments, tags, args)
    local skipCapitalize = tags.AutoCapitalizeNonInitialSegments
    local shouldCapitalize = args.doCapitalize or skipCapitalize
    local isFirstPunctuate = true

    for i = 1, #segments do
        local action = segments[i]
        if action.type == 'quote' then
            local prefix, text, suffix = action.text:match('^(%s*"?)(.-)("?%s*)$')
            if shouldCapitalize and not skipCapitalize then
                text = Helpers.capitalize(text)
            end

            if args.applyCase then
                text = Helpers.case(text, tags)
            end

            if args.doPunctuate then
                local mark = (isFirstPunctuate and tags.Loud and not tags.IsSneakCallout) and '!' or '.'
                text = Helpers.punctuate(text, mark)
                isFirstPunctuate = false
            end

            action.text = prefix .. text .. suffix
            skipCapitalize = false
        end
    end
end

---Formats actions based on the embedded action format.
---@param segments MessageSegment[] The message segments list.
---@param interpolator omi.Interpolator The interpolator in use.
function Helpers.formatEmbeddedActions(segments, interpolator)
    local tokens = interpolator:getTokens()

    local tags = tokens.tags
    if utils.isinstance(tags, MultiMap) then
        tokens.tags = tags:withSetValue('IsEmbeddedAction')
    else
        tokens.tags = MultiMap.fromSet({ IsEmbeddedAction = true })
    end

    for i = 1, #segments do
        local action = segments[i]
        if action.type == 'action' then
            tokens.input = action.text

            local result = utils.interpolateNamed('EmbeddedAction', config.Format.Component.EmbeddedAction, tokens)
            action.text = result
        end
    end
end

---Formats quotes based on the embedded quote format.
---@param segments MessageSegment[] The message segments list.
---@param interpolator omi.Interpolator The interpolator in use.
function Helpers.formatEmbeddedQuotes(segments, interpolator)
    local tokens = interpolator:getTokens()

    local tags = tokens.tags
    if utils.isinstance(tags, MultiMap) then
        tokens.tags = tags:withSetValue('IsEmbeddedQuote')
    else
        tokens.tags = MultiMap.fromSet({ IsEmbeddedQuote = true })
    end

    for i = 1, #segments do
        local quote = segments[i]
        if quote.type == 'quote' then
            local text = Helpers.ensureUnwrapped(quote.text, '"')
            tokens.input = text

            local result = utils.interpolateNamed('EmbeddedQuote', config.Format.Component.EmbeddedQuote, tokens)
            if result ~= '' then
                result = Helpers.ensureWrapped(result, '"')
            end

            quote.text = result
        end
    end
end

---Gets a string for the base unknown language string, without a message fragment.
---@param tags omi.SetTable<string> A set of tags.
---@param language string? The untranslated roleplay language name.
---@param author string? The author of the message.
---@param dialogueTag string? The dialogue tag, if narrative style was used for the message.
---@param overhead boolean? Flag for whether the string should be formatted for overhead text instead of chat.
---@return string? text A translated string used to indicate that a language is unknown.
function Helpers.getBaseUnknownLanguageString(tags, language, author, dialogueTag, overhead)
    language = tostring(language or '')
    if language == '' then
        return
    end

    local languageName = utils.getTranslatedLanguageName(language)

    author = tostring(author or '')
    if author ~= '' then
        author = author .. (overhead and ' ' or ' <SPACE> ')
    else
        return getText('UI_OmiChat_UnknownLanguageNoAuthor', languageName)
    end

    dialogueTag = tostring(dialogueTag or '')
    if dialogueTag == '' then
        -- no narrative style tag → pick the most suitable one
        if tags.IsSneakCallout then
            dialogueTag = 'whisper_shouts'
        elseif tags.Whisper then
            dialogueTag = 'whispers'
        elseif tags.Loud then
            dialogueTag = 'shouts'
        else
            dialogueTag = 'says'
        end
    else
        dialogueTag = dialogueTag:gsub('%s', '_')
    end

    local isSigned = API.language.isSigned(language)
    if isSigned then
        local stringID = 'UI_OmiChat_UnknownLanguageSigned_' .. dialogueTag
        local translated = getTextOrNull(stringID, author, languageName)
        if translated then
            return translated
        end

        if dialogueTag == 'exclaims' then
            -- fallback to 'energetically signs'
            return getText('UI_OmiChat_UnknownLanguageSigned_shouts', author, languageName)
        elseif dialogueTag == 'whisper_shouts' or dialogueTag == 'hisses' then
            -- fallback to 'subtly signs'
            return getText('UI_OmiChat_UnknownLanguageSigned_whispers', author, languageName)
        elseif dialogueTag == 'says' or dialogueTag == 'states' then
            -- fallback to 'signs'
            return getText('UI_OmiChat_UnknownLanguage_signs', author, languageName)
        end
    end

    local stringID = 'UI_OmiChat_UnknownLanguage_' .. dialogueTag
    local translated = getTextOrNull(stringID, author, languageName)
    if translated then
        return translated
    end

    stringID = 'UI_OmiChat_UnknownLanguage_' .. (isSigned and 'signs' or 'says')
    return getText(stringID, author, languageName)
end

---Gets a color to use given a target tag.
---@param colorTag string The tag to match against streams to find one to use the color from.
---@param options omi.MultiMap? A multimap of options.
---@param tags omi.SetTable<string>? A set of tags.
---@return string color A color, formatted in rich text.
function Helpers.getColorFromTarget(colorTag, options, tags)
    if not IS_CLIENT then
        return ''
    end

    tags = tags or {}

    local streams = API_C.streams.getChatStreamsWithTag(colorTag)
    local targetTag = options and options:get('colorTargetTag')
    if not targetTag then
        if tags.Loud then
            targetTag = 'Loud'
        elseif tags.Quiet then
            targetTag = 'Quiet'
        elseif tags.Whisper then
            targetTag = 'Whisper'
        end
    end

    local colorStream
    if targetTag then
        for i = 1, #streams do
            local stream = streams[i]
            if stream:hasTag(targetTag) then
                colorStream = stream
                break
            end
        end
    end

    colorStream = colorStream or streams[1]
    if not colorStream then
        return ''
    end

    return utils.color.toRichText(API_C.player.getColorOrDefault(colorStream:getName()), true)
end

---Returns a partial quote representing a fragment of what a player character understood.
---@param interpolator omi.Interpolator The interpolator in use.
---@param message string The message text.
---@return string? fragmented The message text, fragmented to only include some words.
function Helpers.getFragmentedMessage(interpolator, message)
    local parts = message:split('\\s+')
    if #parts <= 1 then
        return
    end

    local rolls = math.min(config.Language.InterpretationRolls, #parts - 1)
    if rolls == 0 then
        return
    end

    -- populate and shuffle
    local indices = {}
    for i = 1, #parts do
        indices[#indices + 1] = i
    end

    for i = #indices, 2, -1 do
        local j = interpolator:random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    -- select indices to include
    local selected = {}
    for _ = 1, rolls do
        if #indices == 0 then
            break
        end

        if interpolator:random(100) < config.Language.InterpretationChance then
            local choice = indices[#indices]
            indices[#indices] = nil
            selected[#selected + 1] = choice
        end
    end

    if #selected == 0 then
        return
    end

    sort(selected)

    -- build fragmented message
    local last = 0
    local built = {}
    for i = 1, #selected do
        local idx = selected[i]
        if idx > last + 1 then
            built[#built + 1] = '...'
        end

        built[#built + 1] = parts[idx]
        last = idx
    end

    if last < #parts then
        built[#built + 1] = '...'
    end

    return '"' .. concat(built, ' ') .. '"'
end

---Gets the segments in a message, tagging them as actions or quotes.
---@param input string The input text.
---@param options Args.GetMessageSegments? Options for retrieving segments.
---@return MessageSegment[] segments A list of message segments.
---@return string prefix Invisible characters that preceded the text.
---@return string suffix Invisible characters that followed the text.
function Helpers.getMessageSegments(input, options)
    options = options or {}
    input = utils.trim(input)

    local inAction = options.startInAction or false
    local onlyFirstSegment = options.onlyFirstSegment
    local requireAsterisk = not options.startInAction and not options.optionalActionAsterisk

    local start = 1
    local pos = 1
    local prefix, suffix
    input, prefix, suffix = utils.getInternalText(input)

    -- avoid triggering actions with an initial asterisk in narrative style
    if not inAction and options.hasInternalQuote then
        local firstQuote = input:find('"')
        pos = firstQuote and (firstQuote + 1) or pos
    end

    local segments = {} ---@type MessageSegment[]
    while pos <= #input do
        if input:sub(pos, pos) == '"' then
            if start ~= pos then
                if inAction then
                    segments[#segments + 1] = {
                        type = 'action',
                        text = input:sub(start, pos - 1),
                    }

                    start = pos
                    inAction = not inAction
                elseif not requireAsterisk or input:match(ASTERISK_DELIM_PATTERN, pos) then
                    segments[#segments + 1] = {
                        type = 'quote',
                        text = input:sub(start, pos),
                    }

                    start = pos + 1
                    inAction = not inAction
                end
            end

            if onlyFirstSegment and #segments > 0 then
                return segments, prefix, suffix
            end
        else
            -- skip mentions
            local _, mentionEnd = input:find('^<@%d+:.->', pos)
            if mentionEnd then
                pos = mentionEnd
            end
        end

        pos = pos + 1
    end

    if #input > 0 and start <= #input then
        segments[#segments + 1] = {
            type = inAction and 'action' or 'quote',
            text = input:sub(start, #input),
        }
    end

    return segments, prefix, suffix
end

---Gets the text to use for an "over radio" indicator.
---@param chatType omi.ChatTypeString? The chat type of the message.
---@return string indicator A translated string representing that a message was sent over radio.
function Helpers.getOverRadioIndicator(chatType)
    if chatType == 'faction' then
        return getText('UI_OmiChat_FactionRadio')
    elseif chatType == 'safehouse' then
        return getText('UI_OmiChat_SafehouseRadio')
    end

    return getText('UI_OmiChat_OverRadio')
end

---Gets the string to display when an out-of-range chat is perceived.
---@param author string The author of the message.
---@param interpolator omi.Interpolator The interpolator in use.
---@param tags omi.SetTable<string> A set of tags.
---@return string text A translated string indicating that a message was out-of-range, but perceived.
function Helpers.getPerceivedChatString(author, interpolator, tags)
    local language = interpolator:token('languageRaw')
    local isSigned = language and API.language.isSigned(language)

    local stringID = 'UI_OmiChat_PerceivedChat'
    if isSigned then
        stringID = stringID .. 'Signed'
    end

    if tags.Whisper then
        stringID = stringID .. '_Whisper'
    elseif tags.Quiet then
        stringID = stringID .. '_Quiet'
    elseif tags.Loud then
        stringID = stringID .. '_Loud'
    end

    return getText(stringID, author)
end

---Gets the prefix to use for a message to indicate that it was sent over the radio.
---@param interpolator omi.Interpolator The interpolator in use.
---@param tags omi.SetTable<string> A set of tags.
---@return string prefix A translated string indicating a radio message and its frequency, or an "over radio" indicator.
function Helpers.getRadioPrefix(interpolator, tags)
    local prefix = ''
    if tags.IsRadioStream then
        prefix = getText('UI_OmiChat_Radio', tostring(interpolator:token('frequency') or '???'))

        if tags.IncludeColon or not (tags.NoColon or tags.IsNarrativeStyle or tags.IsBuffyRoll) then
            prefix = prefix .. ':'
        end

        prefix = prefix .. ' <SPACE> '
    elseif tags.OverRadio or tags.OverRadioChat or tags.IsEchoMessage then
        prefix = Helpers.getOverRadioIndicator(interpolator:token('chatType')) .. ' <SPACE> '
    end

    return prefix
end

---Gets a volume indicator based on tags.
---@param options omi.MultiMap A multimap of options.
---@param tags omi.SetTable<string> A set of tags.
---@param shouldTranslate boolean? Flag for whether translation should be attempted.
---@return string? indicator A translated or untranslated string indicating the volume of a message.
function Helpers.getVolumeIndicator(options, tags, shouldTranslate)
    local indicator
    if not tags.IsSneakCallout and (tags.Loud or tags.IsCallout) then
        indicator = options:getString('loudIndicator', config:getVariable('VolumeIndicatorLoud') or 'Loud')
    elseif tags.Quiet or tags.IsSneakCallout then
        indicator = options:getString('quietIndicator', config:getVariable('VolumeIndicatorQuiet') or 'Low')
    elseif tags.Whisper then
        indicator = options:getString('whisperIndicator', config:getVariable('VolumeIndicatorWhisper') or 'Whisper')
    end

    if not indicator or indicator == '' then
        return
    end

    if shouldTranslate then
        indicator = getTextOrNull('UI_OmiChat_VolumeIndicator_' .. indicator:gsub('%s', '_')) or indicator
    end

    return '[' .. indicator .. ']'
end

---Gets the value of an option, or a token as a fallback.
---@param interpolator omi.Interpolator The interpolator in use.
---@param options omi.MultiMap A multimap of options.
---@param key string The key to use to retrieve the option.
---@param token string? The token to retrieve from the interpolator. Defaults to `key`.
---@return string value The option or token, or the empty string if neither exist.
function Helpers.optionOrToken(interpolator, options, key, token)
    local opt = options:get(key)
    if opt ~= nil then
        return tostring(opt)
    end

    return interpolator:tokenString(token or key)
end

---Gets the value of an option, or a token as a fallback.
---If there's both an option and a token, the value of the option is wrapped in the same characters from the token.
---@param interpolator omi.Interpolator The interpolator in use.
---@param options omi.MultiMap A multimap of options.
---@param key string The key to use to retrieve the option.
---@param token string? The token to retrieve from the interpolator. Defaults to `key`.
---@return string value The option or token, or the empty string if neither exist.
function Helpers.optionOrTokenWrapped(interpolator, options, key, token)
    local tokenValue = interpolator:tokenString(token or key)
    local optionValue = options:get(key)

    if not optionValue then
        return tokenValue
    end

    optionValue = tostring(optionValue)

    local _, prefix, suffix = utils.getInternalText(tokenValue)
    local _, optPrefix, optSuffix = utils.getInternalText(optionValue)

    if optPrefix == prefix and optSuffix == suffix then
        -- already wrapped
        return optionValue
    end

    return prefix .. optionValue .. suffix
end

---Adds punctuation to a string if it isn't already present.
---Handles encoded invisible characters and trailing spaces.
---@param input string The string to punctuate.
---@param punctuation string? The punctuation character to use. Defaults to `.`.
---@param characters string? Characters to treat as punctuation. Defaults to using the punctuation string pattern.
---@return string punctuated Text with punctuation added.
function Helpers.punctuate(input, punctuation, characters)
    local prefix, suffix
    input, prefix, suffix = utils.getInternalText(input)

    local last, spaces = input:match('()(%s*)$')
    spaces = spaces or ''
    if last then
        ---@cast last integer
        input = input:sub(1, last - 1)
    end

    -- if it ends with a mention, always punctuate
    if input:match('<@%d+:.->$') then
        return prefix .. input .. (punctuation or '.') .. spaces .. suffix
    end

    -- doesn't actually use the interpolator
    ---@diagnostic disable-next-line: param-type-not-match
    input = stringLib.Punctuate(nil, input, punctuation, characters)

    return prefix .. input .. spaces .. suffix
end

---Reads at-function options.
---@param args any? An argument to an interpolator function.
---@return omi.MultiMap options The multimap from the argument, or an empty multimap.
function Helpers.readOptions(args)
    if type(args) == 'table' and utils.isinstance(args, MultiMap) then
        return args:toOptions()
    else
        return MultiMap:new()
    end
end

---Reads tags from an interpolator.
---@param interpolator omi.Interpolator The interpolator in use.
---@return omi.SetTable<string> tags A set of tags.
function Helpers.readTags(interpolator)
    local tags
    local originalTags

    if interpolator:token('chatType') == 'radio' then
        tags = interpolator:token('tags')
        originalTags = interpolator:token('originalTags')
    else
        tags = interpolator:token('tags')
    end

    local tagSet = {}
    if utils.isinstance(tags, MultiMap) then
        tagSet = tags:toValueSet()
    end

    if utils.isinstance(originalTags, MultiMap) then
        utils.extend(tagSet, originalTags:toValueSet())
    end

    return tagSet
end

---Replaces asterisks intended for coloring actions with invisible characters.
---This prevents them from displaying overhead while still allowing the action coloring to handle them properly.
---@param segments MessageSegment[] The message segments list.
function Helpers.replaceColorActionsAsterisks(segments)
    for i = 1, #segments do
        local action = segments[i]
        if action.type == 'action' then
            local space, after = action.text:match('^(%s*)%*()')
            if space then
                action.text = space .. ASTERISK_CHAR .. action.text:sub(after)
            end
        end
    end
end

---Checks whether embedded actions should be processed.
---@param tags omi.SetTable<string> A set of tags.
---@return boolean
function Helpers.shouldFormatEmbeddedActions(tags)
    if tags.NoEmbeddedActions then
        return false
    end

    if tags.AutoColorActions and tags.IsNarrativeStyle then
        return true
    end

    return tags.EmbeddedActions or not tags.Action
end

---Checks whether embedded quotes should be processed.
---@param tags omi.SetTable<string> A set of tags.
---@return boolean
function Helpers.shouldFormatEmbeddedQuotes(tags)
    if tags.NoEmbeddedQuotes then
        return false
    end

    return tags.EmbeddedQuotes or tags.Action or tags.AutoColorQuotes or false
end

---Stringifies inputs into a single string.
---@param ...any Arbitary inputs.
---@return string stringified The inputs combined into a single string.
function Helpers.stringify(...)
    return Helpers.stringifySep('', ...)
end

---Stringifies inputs into a single delimited string.
---@param sep string The separator to use.
---@param ...any Arbitary inputs.
---@return string stringified The inputs combined into a single string.
function Helpers.stringifySep(sep, ...)
    local t = {}
    for i = 1, select('#', ...) do
        t[#t + 1] = tostring(select(i, ...) or '')
    end

    return concat(t, sep)
end

---Wraps an action for chat based on the provided tags.
---@param text string The text to wrap.
---@param tags omi.SetTable<string> A set of tags.
---@return string wrapped The text, wrapped in action indicators for chat.
function Helpers.wrapActionChat(text, tags)
    if tags.ActionAsterisks or tags.ActionAsterisksChat then
        return '** <SPACE> ' .. text
    elseif not (tags.ActionPlain or tags.ActionPlainChat) then
        return getText('UI_OmiChat_RPEmote', ' <SPACE> ' .. text .. ' <SPACE> ')
    end

    return text
end

---Wraps an action for an overhead message based on the provided tags.
---@param text string The text to wrap.
---@param tags omi.SetTable<string> A set of tags.
---@return string wrapped The text, wrapped in action indicators for an overhead speech bubble.
function Helpers.wrapActionOverhead(text, tags)
    if tags.ActionAsterisks or tags.ActionAsterisksOverhead then
        return '** ' .. text
    elseif not (tags.ActionPlain or tags.ActionPlainOverhead) then
        return '( ' .. text .. ' )'
    end

    return text
end


return Helpers

--#region Type Definitions

---@class Args.GetMessageSegments
---@field startInAction? boolean Flag for whether the text should start as an action instead of a quote.
---@field hasInternalQuote? boolean Flag for whether the message has an internal quote. This makes the first quote encountered not end an initial quote segment.
---@field optionalActionAsterisk? boolean Flag for whether the asterisk for actions should be considered optional.
---@field onlyFirstSegment? boolean Flag for whether only the first segment should be returned.

---@class Args.PerformSharedOperations
---@field interpolator omi.Interpolator The interpolator in use.
---@field options omi.MultiMap A multimap of options.
---@field tags omi.SetTable<string> A set of tags.
---@field input string The input text.
---@field doCapitalize? boolean Flag for whether the text should be capitalized.
---@field doPunctuate? boolean Flag for whether the text should be punctuated.
---@field applyCase? boolean Flag for whether the case should be updated based on the tags.
---@field applyEmbeddedActions? boolean Flag for whether embedded actions should be styled.
---@field applyEmbeddedQuotes? boolean Flag for whether embedded quotes should be styled.
---@field doColorActions? boolean Flag for whether action segments should be set to use an action color.
---@field doColorQuotes? boolean Flag for whether quote segments should be set to use a quote color.
---@field doReplaceAsterisks? boolean Flag for whether asterisks should be replaced with an invisible signal.
---@field doAutoQuotes? boolean Flag for whether the text should be wrapped in quotes.
---@field hasInternalQuote? boolean Flag for whether the text has an expected internal quote (i.e., is narrative style).


---@class MessageSegment
---@field type 'quote' | 'action' The type of the segment, which dictates its styling.
---@field text string The text of the segment.

--#endregion
