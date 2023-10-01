# Tokens

The [format strings](./format-strings.md) that some sandbox options accept can include *tokens*, which are replaced with a relevant value when they're used.
These are specified with a dollar sign followed by the name of the token (e.g., `$author`).
Unlike [functions](./format-string-functions.md), tokens are case-sensitive; `$author` is not the same as `$Author`.

The full list of tokens accepted by the various sandbox options follows.
**Not all of these tokens are available to every sandbox option that uses format strings. See [Sandbox Options](./sandbox-options.md) for details about the tokens that each option accepts.**

- `$1`: The content of a message wrapped in invisible special characters.
    - When this token is used by a format string, it **must** be included.
    If it isn't, the format string will behave as if only `$1` had been specified.
    - The invisible characters included in this token are used to encode information for mod functionality.
- `$author`: The author of a message (usually a username). This will also include the name color, if one is included.
- `$authorRaw`: The same as `$author`, but does not include name colors.
- `$chatType`: The type of the chat in which the message was sent.
    - One of `general`, `whisper`, `say`, `shout`, `faction`, `safehouse`, `radio`, `admin`, or `server`.
    - Note that `whisper` refers to PM chats, not local whispers.
- `$frequency`: The radio frequency the message was sent on.
- `$forename`: The relevant player's character's forename.
- `$H`: The hour in 24-hour format.
- `$HH`: The zero-padded hour in 24-hour format.
- `$h`: The hour in 12-hour format.
- `$hh`: The zero-padded hour in 12-hour format.
- `$hourFormatPref`: 12 if the user prefers 12-hour clock formats; otherwise, 24.
- `$m`: The minute.
- `$mm`: The zero-padded minute.
- `$AMPM`: `AM` or `PM`, based on the hour.
- `$ampm`: `am` or `pm`, based on the hour.
- `$message`: The message content.
- `$menuType`: The type of menu in which the format string will appear.
    - One of `medical`, `trade`, or `mini_scoreboard`.
- `$name`: The chat name of the relevant player. This will also include the name color, if one is included.
    - Determined by the name set with [`/name`](./sandbox-options.md#enablesetname) or the format specified by [`FormatName`](./sandbox-options.md#formatname).
- `$nameRaw`: The same as `$name`, but does not include name colors.
- `$recipient`: The username of the recipient of a private message.
- `$recipientName`: The name of the recipient of a private message.
    - Determined in the same way as `$name`.
- `$surname`: The relevant player's character's surname.
- `$tag`: The title of the chat type associated with the message.
    - Determined by [`FormatTag`](./sandbox-options.md#formattag).
- `$timestamp`: The timestamp of the message.
    - Determined by [`FormatTimestamp`](./sandbox-options.md#formattimestamp)
- `$username`: The relevant player's username.
