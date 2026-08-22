### Supplemental strings for the settings menu
### @do-not-translate Settings are untranslated for now

unrecognized-tag = Unrecognized tag.

-color-target-suffix = <LINE> If this is included on multiple streams, the stream with the tag that matches
    the volume of the message (e.g., Loud, Whisper, Quiet) will be preferred.

# @param $tag string The tag that has similar behavior.
# @param $context string The context in which the tag is used.
-same-as = This is the same as <SPACE> { -highlight-color } { $tag } <POPRGB> , but only applies { $context ->
    [chat] to chat formatting
    [overhead] to overhead formatting
    [action] to embedded actions
    [quote] to embedded quotes
    [narrative] to narrative style formatting
    [sneak-callout] to sneak callouts
    *[other] { $context }
}.

## Format string option headings

heading-args = Available options for the default function (provided with a multimap):

heading-format-string = This setting is a <SPACE> { -highlight-inline(text: "format string") }.
    Click for an overview of the format string syntax.

## Format string option tooltips

arg-allowDefault-language-placeholder = If given, the placeholder will be shown for the default language as well.

arg-cardIcon = The icon to use for messages. Defaults to 'Item_CardDeck'.

arg-colorTargetTag = The tag to use for narrowing if multiple streams include
    <SPACE> { -highlight-inline(text: "ActionColorTarget") } / { -highlight-inline(text: "QuoteColorTarget") }.

arg-defaultName = The name to use by default if other options are not available.

arg-dialogueTag = The narrative style dialogue tag (e.g., 'says,').

arg-exclamationTag = The default dialogue tag for an exclamation. Defaults to 'exclaims'.

arg-flipIcon = The icon to use for messages. Defaults to 'Item_Plate'.

arg-input = Used instead of the value of the { -highlight(text: "input") } token if given.

arg-language = Used instead of the value of the { -highlight(text: "rawLanguage") } token if given.

arg-loudIndicator = The volume indicator to use for a loud message.
    <LINE> Defaults to the value configured under Streams &gt; Volume Indicator, or 'Loud'.

arg-loudTag = The default dialogue tag to use for a loud message. Defaults to 'shouts'.

arg-maxLength = The maximum length of the input. Produces a relevant error if exceeded.

arg-maxLength-filter-status = The maximum length of the input. Produces a relevant error if exceeded. Defaults to 64.

arg-minLength = The minimum length of the input. Produces a relevant error if not met.

arg-minLength-filter-status = The minimum length of the input. Produces a relevant error if not met. Defaults to 8.

arg-mode = The mode to use for the name display.
    <LINE> This can be 'username', 'name', or 'both' to include both separated by a slash.

arg-name = Used instead of the value of the { -highlight(text: "name") } token if given.

arg-names-typing = A list-style multimap to use for the typing message.

arg-noComma = If given, a comma will not be included after the dialogue tag.

arg-prefix = Used instead of the value of the { -highlight(text: "prefix") } token if given.

arg-questionTag = The default dialogue tag for a question. Defaults to 'asks'.

arg-quietIndicator = The volume indicator to use for a quiet message.
    <LINE> Defaults to the value configured under Streams &gt; Volume Indicator, or 'Low'.

arg-recipientName = Used instead of the value of the { -highlight(text: "recipientName") } token if given.

arg-rollIcon = The icon to use for messages. Defaults to 'Item_Dice'.

arg-shortStatementTag = The default dialogue tag for a short statement. Defaults to 'states'.

arg-sneakCalloutTag = The default dialogue tag to use for sneak callouts. Defaults to 'whisper shouts'.

arg-statementTag = The default dialogue tag for a statement. Defaults to 'says'.

arg-truncateTo = A numeric character limit, after which the input will be cut off.

arg-truncateTo-filter-chat-input = A numeric character limit, after which the input will be cut off. Defaults to 2000.

arg-truncateTo-filter-name = A numeric character limit, after which the input will be cut off. Defaults to 40.

arg-whisperIndicator = The volume indicator to use for a whispered message.
    <LINE> Defaults to the value configured under Streams &gt; Volume Indicator, or 'Whisper'.

arg-whisperTag = The default dialogue tag to use for a whispered message. Defaults to 'whispers'.

## Tag tooltips

tag-Action = Indicates that a stream is a roleplay action (e.g., <SPACE> { -command-inline(name: "me")} ).
    <LINE> This controls various defaults for formatting.

tag-ActionAsterisks = Indicates that an action should be prefixed by two asterisks and a space.

tag-ActionAsterisksChat = { -same-as(tag: "ActionAsterisks", context: "chat") }

tag-ActionAsterisksOverhead = { -same-as(tag: "ActionAsterisks", context: "overhead") }

tag-ActionColorTarget = Indicates the stream that should be used to determine the color of embedded actions.
    { -color-target-suffix }

tag-ActionGuillemets = Indicates that an action should be surrounded by guillemets.
    <LINE> This has no effect if { -highlight(text: "ActionAsterisks") } is specified.

tag-ActionGuillemetsChat = { -same-as(tag: "ActionGuillemets", context: "chat") }

tag-ActionGuillemetsOverhead = { -same-as(tag: "ActionGuillemets", context: "overhead") }

tag-AutoCapitalize = Indicates that messages sent on a stream should automatically have their first letter capitalized.
    <LINE> This does not have an effect for sneak callouts.
    To apply capitalization to those, use <SPACE> { -highlight-inline(text: "AutoCapitalizeSneakCallout") }.

tag-AutoCapitalizeChat = { -same-as(tag: "AutoCapitalize", context: "chat") }

tag-AutoCapitalizeEmbeddedActions = { -same-as(tag: "AutoCapitalize", context: "action") }

tag-AutoCapitalizeEmbeddedQuotes = { -same-as(tag: "AutoCapitalize", context: "quote") }

tag-AutoCapitalizeNarrative = { -same-as(tag: "AutoCapitalize", context: "narrative") }

tag-AutoCapitalizeNonInitialSegments = {
    -same-as(tag: "AutoCapitalize", context: "after the initial quote or action segment of a message")
}

tag-AutoCapitalizeOverhead = { -same-as(tag: "AutoCapitalize", context: "overhead") }

tag-AutoCapitalizeSneakCallout = { -same-as(tag: "AutoCapitalize", context: "sneak-callout") }

tag-AutoColorActions = Indicates that embedded actions should use action colors.

tag-AutoColorQuotes = Indicates that embedded quotes should use quote colors in an action message.

tag-AutoPunctuate = Indicates that a message should automatically include a punctuation mark if one wasn't included.
    <LINE> For streams tagged with <SPACE> { -highlight-inline(text: "Loud") },
    excluding actions and sneak callouts, an exclamation mark will be used.
    <LINE> Otherwise, the mark will be a period.

tag-AutoPunctuateChat = { -same-as(tag: "AutoPunctuate", context: "chat") }

tag-AutoPunctuateEmbeddedActions = { -same-as(tag: "AutoPunctuate", context: "action") }

tag-AutoPunctuateEmbeddedQuotes = { -same-as(tag: "AutoPunctuate", context: "quote") }

tag-AutoPunctuateNarrative = { -same-as(tag: "AutoPunctuate", context: "narrative") }

tag-AutoPunctuateOverhead = { -same-as(tag: "AutoPunctuate", context: "overhead") }

tag-BracketedNames = Indicates that names should be surrounded by square brackets.

tag-Callout = Indicates the stream that should be used for formatting callout messages.

tag-CardCommandTarget = Indicates the stream that should be used for formatting messages from
    the { -command(name: "card") } command.

tag-DoubleBracketedText = Indicates that the message text should be surrounded by pairs of two square brackets.

tag-EchoTarget = Indicates the stream that echo messages should be sent on.

tag-EmbeddedActions = Indicates that embedded actions should be formatted.
    <LINE> This is the default for non-actions unless { -highlight(text: "NoEmbeddedActions") } is specified.
    <LINE> It is also assumed to be true in narrative style if { -highlight(text: "AutoColorActions") } is specified.

tag-EmbeddedQuotes = Indicates that embedded quotes should be formatted.
    <LINE> This is the default for actions unless { -highlight(text: "NoEmbeddedQuotes") } is specified.
    <LINE> It is also assumed to be true if { -highlight(text: "AutoColorQuotes") } is specified.

tag-FlipCommandTarget = Indicates the stream that should be used for formatting messages from
    the { -command(name: "flip") } command.

tag-HideOverhead = Indicates that messages should not be shown in overhead speech bubbles.

tag-IgnoreRolesForCustomize = Indicates that players should be able to customize the stream's message color,
    even if they lack the roles to use it.

tag-IncludeColon = Indicates that a colon should be added after names.
    <LINE> This is the default behavior unless in narrative style or on the server message stream.
    <LINE> Takes precedence over <SPACE> { -highlight-inline(text: "NoColon") }.

tag-IncludeAdminIndicator = Indicates that a parenthesized prefix should be included when a message is sent
    from an admin with the icon enabled.

tag-IncludeMentionAtSign = Indicates that mentions should be prefixed with an at-sign.

tag-IncludeMentionAtSignChat = { -same-as(tag: "IncludeMentionAtSign", context: "chat") }

tag-IncludeMentionAtSignOverhead = { -same-as(tag: "IncludeMentionAtSign", context: "overhead") }

tag-IncludeName = Indicates that names should be included in messages.
    <LINE> This is the default behavior unless on the server message stream.

tag-IncludeNameChat = { -same-as(tag: "IncludeName", context: "chat") }

tag-IncludeNameOverhead = { -same-as(tag: "IncludeName", context: "overhead") }

tag-KeepActionAsterisk = Indicates that embedded actions should keep a visible signal asterisk.

tag-Loud = Indicates that a stream should be treated as the loud volume.

tag-Lowercase = Indicates that text should be converted to all lowercase.

tag-NoAdminIndicator = Indicates that a parenthesized prefix should not be included when a message is sent
    from an admin with the icon enabled.
    <LINE> This is the default behavior.
    <LINE> Takes precedence over <SPACE> { -highlight-inline(text: "IncludeAdminIndicator") }.

tag-NoColon = Indicates that a colon should not be added after names.
    <LINE> This is the default behavior in narrative style and on the server message stream.

tag-NoColonChat = { -same-as(tag: "NoColon", context: "chat") }

tag-NoColonOverhead = { -same-as(tag: "NoColon", context: "overhead") }

tag-NoCommandIcon = Indicates that an icon should not be included in a command message
    (e.g., <SPACE> { -command-inline(name: "card") }).

tag-NoEmbeddedActions = Indicates that embedded actions should not be formatted.

tag-NoEmbeddedQuotes = Indicates that embedded quotes should not be formatted.

tag-NoIcon = Indicates that an icon should not be included in a message.
    <LINE> Icons for commands will still be included if this is specified.
    <LINE> To disable them, use <SPACE> { -highlight-inline(text: "NoCommandIcon") }.

tag-NoLanguage = Indicates that the language indicator prefix should not be included.

tag-NoLanguageChat = { -same-as(tag: "NoLanguage", context: "chat") }

tag-NoLanguageOverhead = { -same-as(tag: "NoLanguage", context: "overhead") }

tag-NoName = Indicates that names should not be included in messages.
    <LINE> Takes precedence over <SPACE> { -highlight-inline(text: "IncludeName") }.

tag-NoNameChat = { -same-as(tag: "NoName", context: "chat") }

tag-NoNameOverhead = { -same-as(tag: "NoName", context: "overhead") }

tag-NoOutOfRangeIndicator = Indicates that the out-of-range indicator prefix should not be included.

tag-NoOutOfRangeIndicatorChat = { -same-as(tag: "NoOutOfRangeIndicator", context: "chat") }

tag-NoOutOfRangeIndicatorOverhead = { -same-as(tag: "NoOutOfRangeIndicator", context: "overhead") }

tag-NoPrefixSpace = Indicates that a space should not be included between the prefix and the content in a final format.

tag-NoPrefixSpaceChat = { -same-as(tag: "NoPrefixSpace", context: "chat") }

tag-NoPrefixSpaceOverhead = { -same-as(tag: "NoPrefixSpace", context: "overhead") }

tag-NoSignedOverRadio = Indicates that an error message should be shown when attempting to send a message
    on this stream in a signed language.
    <LINE> The error message notifies the player that signed message cannot be sent over radio.

tag-NoTagColon = Indicates that a colon should not be included after a chat tag.
    <LINE> This is the default behavior unless on the server message stream.

tag-NoTimestamp = Indicates that a timestamp should not be included, even if the option is enabled.

tag-NoTransmitOverRadio = Indicates that messages from a stream should be hidden if transmitted over radio.
    <LINE> This is the default behavior for actions and OOC messages.

tag-NoVolumeIndicator = Indicates that the volume indicator prefix should not be included.

tag-NoVolumeIndicatorChat = { -same-as(tag: "NoVolumeIndicator", context: "chat") }

tag-NoVolumeIndicatorOverhead = { -same-as(tag: "NoVolumeIndicator", context: "overhead") }

tag-OOC = Indicates that messages on a stream are out-of-character.
    <LINE> This wraps the message in two pairs of parentheses.

tag-OptionalActionAsterisk = Indicates that an asterisk is not required to switch
    from a quote segment to an action segment.

tag-OverRadio = Indicates that messages should include a parenthesized prefix showing
    that the message was sent over radio.

tag-OverRadioChat = { -same-as(tag: "OverRadio", context: "chat") }

tag-OverRadioOverhead = { -same-as(tag: "OverRadio", context: "overhead") }

tag-Quiet = Indicates that a stream should be treated as the quiet volume.

tag-QuoteColorTarget = Indicates the stream that should be used to determine the color of embedded quotes.
    { -color-target-suffix }

tag-RollCommandTarget = Indicates the stream that should be used for formatting messages
    from the { -command(name: "roll") } command.

tag-SneakCallout = Indicates the stream that should be used for formatting sneak callout messages.

tag-TagColon = Indicates that a colon should be included after a chat tag.
    <LINE> This is the default behavior on the server message stream.
    <LINE> Takes precedence over <SPACE> { -highlight-inline(text: "Lowercase") }.

tag-TransmitOverRadio = Indicates that messages from a stream should not be hidden if transmitted over radio.

tag-Uppercase = Indicates that text should be converted to all uppercase.
    <LINE> This does not have an effect for sneak callouts.
    To apply uppercase formatting to those, use <SPACE> { -highlight-inline(text: "UppercaseSneakCallout") }.

tag-UppercaseSneakCallout = { -same-as(tag: "Uppercase", context: "sneak-callout") }

tag-UseAuthorUsername = Indicates that the author's username should be used as the message name,
    rather than the name determined by the name format.

tag-UseNameColor = Indicates that a stream should use speech colors as name colors.

tag-UseVanillaPM = Indicates that a PM stream should be formatted like the vanilla PM.

tag-Whisper = Indicates that a stream should be treated as the whisper volume.

## Auto tags (included here for reference)

# IsActionUnknownLanguage
# IsCallout
# IsCardCommand
# IsDiscordStream
# IsEchoMessage
# IsEmbeddedAction
# IsEmbeddedQuote
# IsFlipCommand
# IsIncomingPM
# IsNarrativeStyle
# IsOutgoingPM
# IsPerceptionRange
# IsRadioStream
# IsRollCommand
# IsServerStream
# IsSneakCallout
# IsUnknownLanguage

## Token headings

heading-tokens = Available tokens:

desc-token-embedded = The tokens for this setting differ depending on the context in which it is used.
    <LINE> The following are guaranteed.

## Token descriptions

token-admin = Populated if the message should display as coming from an admin.

token-adminIcon = The admin icon to use for the message. Not given unless applicable.

token-alt-typing = Populated if the 'several people are typing' message should be used for the typing indicator.

token-author = The message author (usually a username). This may include rich text commands.

token-callout = Populated if the message was a callout, including sneak callouts.

token-card = The translated name of the drawn card.

token-chatType = The chat type of the stream.
    <LINE> Possible values: general, whisper, say, shout, faction, safehouse, radio, admin, server.

token-dialogueTag = The dialogue tag for a message using narrative style.

token-echo = Populated for echo messages.

token-error = This can be set to display as an error to the player.

token-errorID = This can be set to a string ID to display a translated error to the player.

token-faction = The faction for this stream. Not given unless the stream has the faction chat type.

token-forename = The relevant player character's forename.

token-frequency = The frequency of a radio message.

token-heads = Populated if the result of a coin flip was heads. Not given otherwise.

token-hourFormat = Set to '12' or '24' depending on the player's hour format preference.

token-icon = The icon to use for the message.

token-icon-processed = The &lt;IMAGE&gt; tag for a chat icon, with leading and trailing spaces.

token-incomingPM = Populated for incoming private messages. Not given otherwise.

token-input = The input text.

token-input-processed = The input text, after all prior processing.

token-language = The name of the roleplay language translated into the current locale.

token-language-processed = The result of the language component format.

token-menuType = The type of menu in which the name will appear.
    <LINE> Possible values: medical, mini_scoreboard, search_player, trade.

token-name = The name to use in chat for the relevant player. This may include rich text commands for the name color.

token-name-component = The player's configured nickname.

token-names-typing = A list-style multimap with names to include in the typing list.

token-narrativeStyle = Populated if narrative style was used for the message. Not given otherwise.

token-onlineID = The online ID of the relevant player.

token-originalStream = The original stream that a radio message was sent over.
    Not given for non-radio messages.

token-originalTags = The tags of the original stream that a radio message was sent over.
    Not given for non-radio messages.

token-outgoingPM = Populated for outgoing private messages. Not given otherwise.

token-prefix-chat-final = The prefix determined by the chat prefix format.

token-prefix-overhead-final = The prefix determined by the overhead prefix format.

token-rawAuthor = The message author (usually a username), without any rich text commands.

token-rawIcon = The name of the icon used for the { -highlight(text: "icon") } token.

token-rawLanguage = The untranslated name of the roleplay language.

token-rawName = The name to use in chat for the relevant player, without any rich text commnds.

token-rawRecipient = The username of the recipient of a PM, without rich text.

token-rawRecipientName = The name to use in chat for the recipient of a PM, without rich text.

token-recipient = The username of the recipient of a PM. This may include rich text for the name color.

token-recipientName = The name to use in chat for the recipient of a PM.
    This may include rich text commands for the name color.

token-roll = The number that was rolled.

token-sides = The number of sides on the die that was rolled.

token-diceExpression = The dice expression that was rolled.

token-sneakCallout = Populated if the message was a callout sent while sneaking.

token-stream = The name of the chat stream on which the message was sent or will be sent.

token-surname = The relevant player character's surname.

token-tag = The result of the tag component format.

token-tag-component = The title of the chat type associated with the message.

token-tags = The tags on the stream for the message.

token-target-filter-name = Set to 'name' if the name being set is the character name. Otherwise, set to 'nickname'.

token-timestamp = The result of the timestamp component format.

token-unknownLanguage = The untranslated name of the message's roleplay language.
    <LINE> Not given unless the message was sent in a language the player character does not know.

token-unstyled = The original content of a message sent in narrative style.

token-username = The username of the relevant player.

token-ampm = Depending on the timestamp, 'am' or 'pm'.

token-AMPM = Depending on the timestamp, 'AM' or 'PM'.

token-h = The unpadded hour in 12-hour format.

token-H = The unpadded hour in 24-hour format.

token-hh = The hour in 12-hour format, zero-padded to two digits.

token-HH = The hour in 24-hour format, zero-padded to two digits.

token-m = The unpadded minute.

token-mm = The minute, zero-padded to two digits.

token-P = The unpadded hour, in the player's preferred hour format.

token-PP = The hour in the player's preferred hour format, zero-padded to two digits.

token-s = The unpadded seconds.

token-ss = The seconds, zero-padded to two digits.
