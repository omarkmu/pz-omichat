---Client API functionality related to formatting, encoding, and decoding chat messages.

local MessageInfo = require 'OmiChat/Component/MessageInfo'


---@class omichat.api.client
local API = require 'OmiChat/API/Client/Core'

local utils = API.utils
local config = API.Configuration
local MultiMap = utils.MultiMap


---Applies the narrative style given an input and stream.
---@param input string
---@param stream omichat.ChatStream
---@param tokens table
---@return string result
---@return boolean? appliedStyle
---@return string? error
local function applyNarrativeStyle(input, stream, tokens)
    if not config.NarrativeStyle.Enable or not stream:canUseNarrativeStyle() then
        return input
    end

    local formatter = API._metadataFormatters.narrative
    if not formatter then
        return input
    end

    local original = input
    local inputTokens = tokens
    tokens = tokens and utils.copy(tokens) or {}
    tokens.input = tokens.input or input
    tokens.chatType = tokens.chatType or stream:getChatType()
    tokens.stream = tokens.stream or stream:getName()

    -- filter input
    tokens.error = ''
    tokens.errorID = ''
    input = utils.interpolate(config.NarrativeStyle.InputFilter, tokens)

    local err = utils.extractError(tokens)
    if err or input == '' then
        return original, nil, err
    end

    -- get dialogue tag
    local seed = input
    local dialogueTag = utils.interpolate(config.NarrativeStyle.DialogueTagFormat, tokens, seed)
    if dialogueTag == '' then
        return original
    end

    input = utils.wrapStringArgument(input, config.ID_NARRATIVE_TEXT)
    dialogueTag = utils.wrapStringArgument(dialogueTag, config.ID_NARRATIVE_TAG)

    tokens.input = input
    tokens.dialogueTag = dialogueTag

    local content = utils.interpolate(config.NarrativeStyle.OverheadContentFormat, tokens, seed)
    if content == '' then
        return original
    end

    inputTokens.narrativeStyle = '1'
    inputTokens.dialogueTag = dialogueTag

    return formatter:format(content), true
end


---Applies message transforms and format options to a message.
---@see omichat.api.client.buildMessageText
---@param message omichat.Message
---@param skipFormatting boolean?
---@return omichat.MessageInfo? info The processed message information. If building fails, this is `nil`.
---@return string original The original message text.
function API.buildMessageInfo(message, skipFormatting)
    ---@type omichat.MessageInfo
    local info = MessageInfo:new(message)
    local text = info:getRawText()

    -- apply transforms
    for i = 1, #API._transformers do
        local transformer = API._transformers[i]
        if transformer.transform and transformer:transform(info) == true then
            break
        end
    end

    -- apply formatting
    if not skipFormatting and not info:applyFormatting() then
        return nil, text
    end

    return info, text
end

---Builds the prefixed text for a message.
---@param message omichat.Message
---@return string
function API.buildMessageText(message)
    local info, original = API.buildMessageInfo(message)
    local result = info and info:buildMessageText()
    return result or original
end

---Returns the roleplay language encoded in message content.
---@param message omichat.Message | string? A message object or string to read.
---@return string?
function API.decodeLanguage(message)
    if not message then
        return
    end

    if type(message) ~= 'string' then
        message = message:getText()
    end

    local formatter = API._metadataFormatters.language
    message = formatter and formatter:read(message)
    if not message then
        return
    end

    local languageId = utils.decodeInvisibleInt(message)
    if not languageId or languageId < 1 or languageId > config.MAX_LANGUAGES then
        return
    end

    return API.getRoleplayLanguageFromID(languageId)
end

---Encodes the provided text with information about the given roleplay language.
---@param text string The text to encode.
---@param language string The language to encode.
---@return string text
---@return string? language
function API.encodeLanguage(text, language)
    local formatter = API._metadataFormatters.language
    local langId = API.getRoleplayLanguageID(language)
    if not formatter or not langId or #utils.trim(text) == 0 then
        return text
    end

    local encoded = utils.encodeInvisibleInt(langId) .. text
    return formatter:format(encoded)
end

---Prepares text for sending to chat.
---@param args omichat.FormatArgs
---@return omichat.FormatResult
function API.formatForChat(args)
    local username = args.username or utils.getPlayerUsername()
    local name = args.name or API.getNameInChat(username, args.chatType)
    local text, before, after = utils.getInternalText(args.text)
    local stream = args.stream
    local formatStream = args.formatStream
    local echoType = args.echoType

    -- set up tokens
    local tagSet = stream and stream:getTags() or {}
    if formatStream then
        utils.extend(tagSet, formatStream:getTags())
    end

    if args.extraTags then
        for i = 1, #args.extraTags do
            tagSet[args.extraTags[i]] = true
        end
    end

    if echoType then
        tagSet.IsEchoMessage = true
    end

    local tokens = args.tokens and utils.copy(args.tokens) or {}
    tokens.chatType = args.chatType
    tokens.input = text
    tokens.username = username
    tokens.name = name
    tokens.stream = stream:getName()
    tokens.echo = echoType ~= nil and '1' or nil
    tokens.tags = MultiMap.fromSet(tagSet)
    tokens.error = ''
    tokens.errorID = ''

    -- check for roleplay language
    local language
    local allowLanguage = args.language and stream and stream:isAllowLanguages()
    if allowLanguage then
        language = args.language
        tokens.languageRaw = language
        tokens.language = language and utils.getTranslatedLanguageName(language)
    end

    -- filter input
    tokens.input = utils.interpolate(config.Format.Filter.ChatInput, tokens)

    local err = utils.extractError(tokens)
    if err or tokens.input == '' then
        return { text = '', error = err }
    end

    -- reapply invisible wrapping characters
    tokens.input = before .. tokens.input .. after

    -- apply narrative style
    local appliedStyle
    if stream then
        tokens.input, appliedStyle, err = applyNarrativeStyle(tokens.input, stream, tokens)

        if err or tokens.input == '' then
            return { text = '', error = err }
        end
    end

    if appliedStyle then
        -- add IsNarrativeStyle tag
        if utils.isinstance(tokens.tags, MultiMap) then
            tokens.tags = tokens.tags:withSetValue('IsNarrativeStyle')
        else
            tokens.tags = MultiMap.fromSet({ IsNarrativeStyle = true })
        end
    end

    -- encode language metadata
    tokens.input = language and API.encodeLanguage(tokens.input, language) or tokens.input

    -- mark as echo message
    if echoType then
        tokens.input = utils.wrapStringArgument(utils.encodeInvisibleInt(echoType), config.ID_ECHO_TYPE) .. tokens.input
    end

    -- apply formatter
    local formatter = args.formatter
        or (formatStream and formatStream:getFormatter())
        or stream:getFormatter()

    if formatter then
        tokens.input = formatter:format(tokens.input, tokens)
    end

    -- add indicator for admin icon
    if isAdmin() and API.getShowAdminIcon() then
        local adminIconFormatter = API._metadataFormatters.adminIcon
        if adminIconFormatter then
            tokens.input = adminIconFormatter:wrap(tokens.input)
        end
    end

    -- apply final overhead format
    local overheadFormatter = API._metadataFormatters.overheadFinal
    if overheadFormatter then
        tokens.prefix = utils.trimleft(utils.interpolate(config.Format.Overhead.Prefix, tokens))
        tokens.input = overheadFormatter:format(tokens.input, tokens)
    end

    -- encode online ID for radio
    local player = getSpecificPlayer(0)
    if player then
        local onlineIDFormatter = API._metadataFormatters.onlineID
        if onlineIDFormatter then
            local id = utils.encodeInvisibleInt(player:getOnlineID())
            tokens.input = onlineIDFormatter:format(id) .. tokens.input
        end
    end

    return {
        text = tokens.input,
        allowLanguage = allowLanguage,
    }
end

---Gets a named formatter.
---@param name omichat.FormatterName
---@return omichat.MetaFormatter?
function API.getFormatter(name)
    return API._metadataFormatters[name]
end

---Text entry validator that validates against the nickname filter.
---@param entry omi.ui.TextEntry
---@param text string?
---@return boolean
---@return string? nickname
function API.validateNicknameText(entry, text)
    if not text then
        text = entry:getInternalText()
    end

    text = utils.trim(text)
    if #text == 0 then
        return true
    end

    local tokens = {
        target = 'nickname',
        input = text,
        error = '',
        errorID = '',
    }

    local nickname = utils.interpolate(config.Format.Filter.Name, tokens)
    local err = utils.extractError(tokens)
    if not err and not utils.isNilOrWhitespace(nickname) then
        return true, nickname
    end

    entry:setValidateTooltipText(err or getText('UI_OmiChat_Error_InvalidName', utils.escapeRichText(text)))
    return false
end
