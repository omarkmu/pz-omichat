---Handles formatting, encoding, and decoding of chat messages.
---@namespace omichat

---@class(partial) api.client
local API = require 'OmiChat/Module/Client/Core'

local utils = API.utils
local config = API.Configuration
local MultiMap = utils.MultiMap


---@class api.client.format
local Format = {}

---Contains functions for formatting messages and validating the format of commands.
API.format = Format

---Applies message transforms and format options to a message.
---@param message Message The message to build information for.
---@param skipFormatting boolean? Flag for whether the formatting step should be skipped.
---@return MessageInfo? info The processed message information. If building fails, this is `nil`.
---@return string original The original message text.
function Format.buildMessageInfo(message, skipFormatting)
    ---@type MessageInfo
    local info = API.MessageInfo:new(message)
    local text = info:getRawText()

    API.transformation.run(info)

    if not skipFormatting and not info:applyFormatting() then
        return nil, text
    end

    return info, text
end

---Builds the prefixed text for a message.
---@param message Message The message to retrieve text for.
---@return string text The built text. If text could not be built, this returns the original text.
function Format.buildMessageText(message)
    local info, original = Format.buildMessageInfo(message)
    local result = info and info:buildMessageText()
    return result or original
end

---Prepares text for sending to chat.
---@param args Args.FormatChat Options for formatting.
---@return FormatResult result The results of formatting.
function Format.chat(args)
    local username = args.username or API.player.getUsername()
    local name = args.name or username and API.data.getNameInChat(username, args.chatType)
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
    tokens.input = utils.interpolateNamed('FilterChatInput', config.Format.Filter.ChatInput, tokens)

    local err = utils.extractError(tokens)
    if err or tokens.input == '' then
        return { text = '', error = err }
    end

    -- reapply invisible wrapping characters
    tokens.input = before .. tokens.input .. after

    -- apply narrative style
    local isNarrative
    if stream then
        tokens.input, isNarrative, err = Format._applyNarrativeStyle(tokens.input, stream, tokens)

        if err or tokens.input == '' then
            return { text = '', error = err }
        end
    end

    if isNarrative then
        -- add IsNarrativeStyle tag
        if utils.isinstance(tokens.tags, MultiMap) then
            tokens.tags = tokens.tags:withSetValue('IsNarrativeStyle')
        else
            tokens.tags = MultiMap.fromSet({ IsNarrativeStyle = true })
        end
    end

    -- encode language metadata
    tokens.input = language and Format.encodeLanguage(tokens.input, language) or tokens.input

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
    if isAdmin() and API.preferences.getShowAdminIcon() then
        local adminIconFormatter = API._metadataFormatters.adminIcon
        if adminIconFormatter then
            tokens.input = adminIconFormatter:wrap(tokens.input)
        end
    end

    -- apply final overhead format
    local overheadFormatter = API._metadataFormatters.overheadFinal
    if overheadFormatter then
        tokens.prefix = utils.trimleft(utils.interpolateNamed('OverheadPrefix', config.Format.Overhead.Prefix, tokens))
        tokens.input = overheadFormatter:format(tokens.input, tokens)
    end

    -- format mentions
    tokens.input = Format._applyMentions(tokens.input, stream, tokens)

    -- encode online ID for radio
    local player = getSpecificPlayer(0)
    if player then
        local onlineIDFormatter = API._metadataFormatters.onlineID
        if onlineIDFormatter then
            local id = utils.encodeInvisibleInt(player:getOnlineID())
            tokens.input = onlineIDFormatter:format(id) .. tokens.input
        end
    end

    ---@type FormatResult
    return {
        text = tokens.input,
        allowLanguage = allowLanguage,
    }
end

---Decodes information encoded in a message's tag.
---@param message Message The message with the tag to decode.
---@return MessageMetadata metadata
function Format.decodeMessageMetadata(message)
    return API.MessageMetadata:new(message)
end

---Encodes message information including chat name and colors into a message's metadata.
---This has no effect if the message already has an encoded tag.
---@param message Message The message to encode.
function Format.encodeMessageMetadata(message)
    if Format.hasEncodedMetadata(message) then
        return
    end

    local author = message:getAuthor() ---@type string?
    if author == '' then
        author = nil
    end

    local text = message:getText()
    local adminFormatter = API.format.get('adminIcon')
    local useAdminIcon = adminFormatter and adminFormatter:isMatch(text)

    local color = author and API.data.getSpeechColor(author)
    local encoded = utils.json.tryEncode {
        language = API.format.decodeLanguage(message),
        name = author and API.data.getNameInChatRichText(author, API.chat.getMessageChatType(message)),
        nameColor = color and utils.color.toHexString(color) or nil,
        icon = author and API.data.getChatIcon(author) or nil,
        adminIcon = useAdminIcon and config.General.AdminIcon or nil,
    }

    message:setCustomTag(encoded or '')
end

---Returns the roleplay language encoded in message content.
---@param message string | Message A message object or string to read.
---@return string? language The untranslated language name, or `nil` if no language was found.
function Format.decodeLanguage(message)
    if not message then
        return
    end

    if type(message) ~= 'string' then
        message = message:getText()
    end

    local formatter = API._metadataFormatters.language
    local decodedMessage = formatter and formatter:read(message --[[@as string]])
    if not decodedMessage then
        return
    end

    local languageId = utils.decodeInvisibleInt(decodedMessage)
    if not languageId or languageId < 1 or languageId > config.MAX_LANGUAGES then
        return
    end

    return API.language.fromID(languageId)
end

---Encodes the provided text with information about the given roleplay language.
---@param text string The text to encode. If this is empty or whitespace, the language will not be encoded.
---@param language string The untranslated name of the language to encode.
---@return string text The text with the language encoded, or the original text if the language could not be found.
function Format.encodeLanguage(text, language)
    local formatter = API._metadataFormatters.language
    local langId = API.language.getID(language)
    if not formatter or not langId or #utils.trim(text) == 0 then
        return text
    end

    local encoded = utils.encodeInvisibleInt(langId) .. text
    return formatter:format(encoded)
end

---Gets a built-in named formatter.
---@param name FormatterName The name of the formatter to retrieve.
---@return MetaFormatter? formatter
function Format.get(name)
    return API._metadataFormatters[name]
end

---Checks whether a message has metadata encoded into its tag.
---@param message Message The message to check.
---@return boolean hasMetadata
function Format.hasEncodedMetadata(message)
    local meta = API.MessageMetadata:new(message)
    return not meta:isEmpty()
end

---Text entry validator that validates against the nickname filter.
---@param entry omi.ui.TextEntry The entry to validate.
---@param text string The text to validate. Defaults to the entry text.
---@return boolean valid Flag for whether the name is valid.
---@return string? nickname The filtered name. Guaranteed if `valid` is `true`.
function Format.validateName(entry, text)
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

    local nickname = utils.interpolateNamed('FilterName', config.Format.Filter.Name, tokens)
    local err = utils.extractError(tokens)
    if not err and not utils.isNilOrWhitespace(nickname) then
        return true, nickname
    end

    entry:setValidateTooltipText(err or getText('UI_OmiChat_Error_InvalidName', utils.escapeRichText(text)))
    return false
end

---Text entry validator that validates against the status filter.
---@param entry omi.ui.TextEntry The entry to validate.
---@param text string The text to validate.
---@return boolean valid Flag for whether the text is valid.
---@return string? status The filtered status. Guaranteed if `valid` is `true`.
function Format.validateStatus(entry, text)
    if not text then
        text = entry:getInternalText()
    end

    text = utils.trim(text)
    if #text == 0 then
        return true
    end

    local tokens = {
        input = text,
        error = '',
        errorID = '',
    }

    local status = utils.interpolateNamed('FilterStatus', config.Format.Filter.Status, tokens)
    local err = utils.extractError(tokens)
    if not err and not utils.isNilOrWhitespace(status) then
        return true, status
    end

    entry:setValidateTooltipText(err or getText('UI_OmiChat_Error_InvalidStatus', utils.escapeRichText(text)))
    return false
end


---Formats mentions for overhead text.
---@param input string
---@param stream ChatStream
---@param tokens table
---@return string
---@private
function Format._applyMentions(input, stream, tokens)
    if not config.Mentions.Enable then
        return input
    end

    local formatter = API._metadataFormatters.mention
    return (input:gsub('<@(%d+:.-)>', function(match)
        local colon = match and match:find(':')
        if not colon then
            return
        end

        -- avoid breaking segment detection
        local name = utils.trim(match:sub(colon + 1)):gsub('"', "''")

        local onlineID = utils.tointeger(match:sub(1, colon - 1))
        if not onlineID then
            return name
        end

        local wrapped = formatter:wrap(utils.encodeInvisibleInt(onlineID) .. name)

        local mentionTokens = utils.copy(tokens)
        mentionTokens.input = wrapped
        mentionTokens.onlineID = tostring(onlineID)
        mentionTokens.chatType = mentionTokens.chatType or stream:getChatType()
        mentionTokens.stream = mentionTokens.stream or stream:getName()

        local result = utils.interpolateNamed('MentionText', config.Mentions.Format, mentionTokens)
        if utils.trim(result) == '' then
            return name
        end

        return result
    end))
end

---Applies the narrative style given an input and stream.
---@param input string
---@param stream ChatStream
---@param tokens table
---@return string result
---@return boolean? appliedStyle
---@return string? error
---@private
function Format._applyNarrativeStyle(input, stream, tokens)
    if not config.NarrativeStyle.Enable or not stream:canUseNarrativeStyle() then
        return input
    end

    local formatter = API._metadataFormatters.narrative
    if not formatter then
        return input
    end

    local original = input
    local inputTokens = tokens
    tokens = utils.copy(tokens)
    tokens.input = tokens.input or input
    tokens.chatType = tokens.chatType or stream:getChatType()
    tokens.stream = tokens.stream or stream:getName()

    -- filter input
    tokens.error = ''
    tokens.errorID = ''
    input = utils.interpolateNamed('FilterNarrativeInput', config.NarrativeStyle.InputFilter, tokens)

    local err = utils.extractError(tokens)
    if err or input == '' then
        return input == '' and input or original, nil, err
    end

    -- inject tag
    local tags = tokens.tags
    if utils.isinstance(tags, MultiMap) then
        tokens.tags = tags:withSetValue('IsNarrativeStyle')
    else
        tokens.tags = MultiMap.fromSet({ IsNarrativeStyle = true })
    end

    -- get dialogue tag
    local seed = input

    tokens.input = input
    local dialogueTag = utils.interpolateNamed('NarrativeTag', config.NarrativeStyle.DialogueTagFormat, tokens, seed)
    if dialogueTag == '' then
        return original
    end

    input = utils.wrapStringArgument(input, config.ID_NARRATIVE_TEXT)
    dialogueTag = utils.wrapStringArgument(dialogueTag, config.ID_NARRATIVE_TAG)

    tokens.input = input
    tokens.narrativeStyle = '1'
    tokens.dialogueTag = dialogueTag

    local content = utils.interpolateNamed(
        'NarrativeOverheadContent',
        config.NarrativeStyle.OverheadContentFormat,
        tokens,
        seed
    )

    if content == '' then
        return original
    end

    inputTokens.narrativeStyle = '1'
    inputTokens.dialogueTag = dialogueTag

    return formatter:format(content), true
end


return Format

--#region Type Definitions

---@class Args.FormatChat
---@field text string The input text.
---@field stream ChatStream The stream to format the text for.
---@field formatStream? Stream An additional stream to use to format the input. Tags from this stream will also be added to the tags token.
---@field formatter? MetaFormatter A formatter to use to format the input. If not given, the formatter from `formatStream` or `stream` is used.
---@field chatType omi.ChatTypeString The chat type.
---@field language? string The untranslated name of the roleplay language to use for the message.
---@field echoType? integer The echo type identifier, if this is an echo message.
---@field name? string The name to use. Defaults to the resolved chat name for the `username`.
---@field username? string The username of the sending player. Defaults to player 1's username.
---@field tokens? table Initial tokens to pass to interpolation strings.
---@field extraTags? string[] Additional tags to include in the tags token.

---@class FormatResult
---@field text string The formatted text. If formatting fails, this is the empty string.
---@field error? string An error to report to the player.
---@field allowLanguage? boolean Flag for whether roleplay language processing should be allowed.

--#endregion
