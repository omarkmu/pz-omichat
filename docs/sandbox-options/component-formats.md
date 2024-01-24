# Component Formats

These [options](./index.md) define string formats used in other format strings, or for purposes other than speech bubbles and chat messages.

### FormatAdminIcon
**Default:** `Item_Sledgehamer` [sic]

The format used to determine the value of `$adminIcon` in the [`FormatIcon`](#formaticon) format.

The `/iconinfo` [command](../user-guide/admins.md#commands) can be used to determine an icon name for this format.
It may also be helpful to enable the [icon picker](../sandbox-options/feature-flags.md#enableiconpicker) to look through possible icons.

**Note: The icon names used when clicking icons in the icon picker are **not** valid values for this format.**
However, they can be used with `/iconinfo` to determine the icon name.

**Tokens:**
- [`$username`](../format-strings/tokens.md#username)

### FormatCard
**Default:** `draws $card`

The format used for local [`/card`](./chat-formats.md#chatformatcard) overhead message content.

**Tokens:**
- `$card`: The card that was drawn, in English.

### FormatIcon
**Default:** `@($eq($stream card):Item_CardDeck;$eq($stream roll):Item_Dice;$has(@(say;shout;whisper;faction;safehouse;looc;general) $stream):@($adminIcon;$icon))`

The format used to determine the value of `$icon` in other formats.

**Tokens:**
- `$adminIcon`: The icon determined by [`FormatAdminIcon`](#formatadminicon).
This is only populated when the player is an admin with the relevant [option](../user-guide/admins.md#admin-menu) enabled.
- [`$chatType`](../format-strings/tokens.md#chattype)
- `$icon`: The icon set with [`/seticon`](../user-guide/admins.md#commands).
- [`$stream`](../format-strings/tokens.md#stream)

### FormatInfo
`(blank by default)`

Information that can be accessed by clicking an info button on the chat.
If blank, the info button will not be visible.

**Tokens:**
- [`$forename`](../format-strings/tokens.md#forename)
- [`$name`](../format-strings/tokens.md#name)
- [`$surname`](../format-strings/tokens.md#surname)
- [`$username`](../format-strings/tokens.md#username)

### FormatMenuName
**Default:** `$ifelse($neq($menuType mini_scoreboard) $name $username &#32;[ $name ])`

The format used for displaying character names within in-game menus such as the trading window, medical check, and the admin mini-scoreboard.
If blank, menus will not be affected.

**Tokens:**
- [`$forename`](../format-strings/tokens.md#forename)
- [`$name`](../format-strings/tokens.md#name)
- [`$surname`](../format-strings/tokens.md#surname)
- [`$username`](../format-strings/tokens.md#username)
- `$menuType`: The type of menu in which the name will appear.
One of `trade`, `medical`, or `mini_scoreboard`.

### FormatName
**Default:** `$ifelse($has(@(general;admin;whisper) $chatType) $username @($name;$forename))`

The format used to determine the values of `$name` and `$nameRaw` in other format strings.

**Tokens:**
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$forename`](../format-strings/tokens.md#forename)
- `$name`: The name that was set with [`/name`](./feature-flags.md#enablesetname), if specified.
- [`$surname`](../format-strings/tokens.md#surname)
- [`$username`](../format-strings/tokens.md#username)

### FormatRoll
**Default:** `rolls a $roll on a $sides-sided die`

The format used for local [`/roll`](./chat-formats.md#chatformatroll) overhead message content.

**Tokens:**
- `$roll`: The number that was rolled. This be wrapped in invisible characters.
- `$sides`: The number of sides on the die that was rolled. This be wrapped in invisible characters.

### FormatTag
**Default:** `[$tag]$if($eq($chatType server) :&#32;<SPACE>&#32;)`

The format used when `Enable tags` is selected in the chat settings menu.
This describes the chat title that displays to the left of messages (e.g., `[Local]`).

**Tokens:**
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$stream`](../format-strings/tokens.md#stream)
- `$tag`: The title of the chat type associated with the message.

### FormatTimestamp
**Default:** `[$ifelse($eq($hourFormatPref 12) $h $H):$mm]`

The format used when `Enable timestamps` is selected in the chat settings menu.

**Tokens:**
- `$ampm`: `am` or `pm`, based on the hour a message was sent.
- `$AMPM`: `AM` or `PM`, based on the hour a message was sent.
- [`$chatType`](../format-strings/tokens.md#chattype)
- `$H`: The hour the message was sent, in 24-hour format.
- `$HH`: The zero-padded hour the message was sent, in 24-hour format.
- `$h`: The hour the message was sent in 12-hour format.
- `$hh`: The zero-padded hour the message was sent in 12-hour format.
- `$hourFormatPref`: 12 if the user prefers 12-hour clock formats; otherwise, 24.
- `$m`: The minute the message was sent.
- `$mm`: The zero-padded minute the message was sent.
- `$s`: The second the message was sent.
- `$ss`: The zero-padded second the message was sent.
- [`$stream`](../format-strings/tokens.md#stream)
