# Tokens

The [format strings](./index.md) that some sandbox options accept can include **tokens**, which are replaced with a relevant value when they're used.
These are specified with a dollar sign followed by the name of the token (e.g., `$author`).
Unlike [functions](./functions.md), tokens are case-sensitive; `$author` is not the same as `$Author`.

The table below serves as a complete list of tokens accepted by the various sandbox options.
**Not all of these tokens are available to every sandbox option that uses format strings.** See [Sandbox Options](../sandbox-options/index.md) for details about the tokens that each option accepts.

| Token | Description | Comments |
| ---- | ---- | ---- |
| `$1` | The content of a message wrapped in invisible special characters. | When this token is used by a format string, it **must** be included. If it isn't, the format string will behave as if only `$1` had been specified.<br><br>The invisible characters included in this token are used to encode information for mod functionality. |
| `$author` | The author of a message (usually a username). This may include the name color, if one is included. |  |
| `$authorRaw` | The same as `$author`, but does not include name colors. |  |
| `$card` | The card that was drawn, for a local [`/card`](../sandbox-options/chat-formats.md#chatformatcard) command. | This is only used by [`FormatCard`](../sandbox-options/component-formats.md#formatcard) and [`ChatFormatCard`](../sandbox-options/chat-formats.md#chatformatcard). |
| `$roll` | The number that was rolled, for a local [`/roll`](../sandbox-options/chat-formats.md#chatformatroll) command. | This is only used by [`FormatRoll`](../sandbox-options/component-formats.md#formatroll) and [`ChatFormatRoll`](../sandbox-options/chat-formats.md#chatformatroll). |
| `$sides` | The number of sides on the die that was rolled, for a local [`/roll`](../sandbox-options/chat-formats.md#chatformatroll) command. | This is only used by [`FormatRoll`](../sandbox-options/component-formats.md#formatroll) and [`ChatFormatRoll`](../sandbox-options/chat-formats.md#chatformatroll). |
| `$chatType` | The type of the chat in which the message was sent. | One of `general`, `whisper`, `say`, `shout`, `faction`, `safehouse`, `radio`, `admin`, or `server`.<br><br>Note that `whisper` refers to private chats, not [local whispers](../sandbox-options/chat-formats.md#chatformatwhisper). |
| `$stream` | The chat stream to which a message was sent. | One of:<br>• `general`<br>• `private` (vanilla whisper)<br>• `say`<br>• `shout`<br>• `faction`<br>• `safehouse`<br>• `radio`<br>• `admin`<br>• `server`<br>• `discord`<br>• `looc`<br>• `whisper` (local whisper)<br>• `do`<br>• `doloud`<br>• `doquiet`<br>• `me`<br>• `meloud`<br>• `mequiet`<br>• `card`<br>• `roll` |
| `$language` | The translated [roleplay language](../sandbox-options/languages.md) that the message was sent in. | This will not be defined if the message was sent in the default language. |
| `$languageRaw` | The untranslated roleplay language that the message was sent in. | This will not be defined if the message was sent in the default language. |
| `$unknownLanguage` | Equivalent to `$language`, if the language is not known by the player. | This is only used by [`ChatFormatUnknownLanguage`](../sandbox-options/chat-formats.md#chatformatunknownlanguage). |
| `$unknownLanguageString` | The default string ID to use when a player character doesn't understand the language of a chat message. |  |
| `$frequency` | The radio frequency the message was sent on. |  |
| `$forename` | The relevant player character's forename. |  |
| `$surname` | The relevant player character's surname. |  |
| `$username` | The relevant player's username. |  |
| `$H` | The hour a message was sent, in 24-hour format. |  |
| `$HH` | The zero-padded hour a message was sent, in 24-hour format. |  |
| `$h` | The hour a message was sent in 12-hour format. |  |
| `$hh` | The zero-padded hour a message was sent in 12-hour format. |  |
| `$m` | The minute a message was sent. |  |
| `$mm` | The zero-padded minute a message was sent. |  |
| `$s` | The second a message was sent. |  |
| `$ss` | The zero-padded second a message was sent. |  |
| `$AMPM` | `AM` or `PM`, based on the hour a message was sent. |  |
| `$ampm` | `am` or `pm`, based on the hour a message was sent. |  |
| `$hourFormatPref` | 12 if the user prefers 12-hour clock formats; otherwise, 24. |  |
| `$content` | The full chat message content, after formatting has occurred. | This is only used by [`ChatFormatFull`](../sandbox-options/chat-formats.md#chatformatfull). |
| `$message` | The content of a message. |  |
| `$menuType` | The type of menu in which the format string will appear. | This is only used by [`FormatMenuName`](../sandbox-options/component-formats.md#formatmenuname). |
| `$name` | The chat name of the relevant player. This may include the name color, if one is included. | Determined by the format specified by [`FormatName`](../sandbox-options/component-formats.md#formatname). |
| `$nameRaw` | The same as `$name`, but does not include name colors. |  |
| `$recipient` | The username of the recipient of a private message. |  |
| `$recipentName` | The name of the recipient of a private message. | Determined in the same way as `$name`. |
| `$tag` | The title of the chat type associated with a message. | Determined by [`FormatTag`](../sandbox-options/component-formats.md#formattag). |
| `$timestamp` | The timestamp of a message. | Determined by [`FormatTimestamp`](../sandbox-options/component-formats.md#formattimestamp). |
