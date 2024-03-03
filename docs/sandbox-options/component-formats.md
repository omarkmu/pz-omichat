# Component Formats

These [options](./index.md) define string formats used in other format strings, or for purposes other than speech bubbles and chat messages.

### FormatAdminIcon
**Default:** `Item_Sledgehamer` [sic]

The format used to determine the value of `$adminIcon` in the [`FormatIcon`](#formaticon) format.
This format expects a valid texture name. `/iconinfo` [command](../user-guide/admins.md#commands) can be used to determine an icon name for this format.

**Tokens:**
- [`$username`](../format-strings/tokens.md#username)

### FormatCard
**Default:** `draws $card`

The format used for local [`/card`](./chat-formats.md#chatformatcard) overhead message content.

**Tokens:**
- `$card`: The card that was drawn, in English.
- `$number`: The number of the card, from 1 to 13. 1 is ace, 11 is jack, 12 is queen, and 13 is king.
- `$suit`: The suit  of the card, from 1 to 4. 1 is clubs, 2 is diamonds, 3 is hearts, and 4 is spades.

### FormatChatPrefix
**Default:** `$if($icon $icon <SPACE>)$if($neq($stream server) $timestamp)$tag$language`

The format used to determine the value of the `$prefix` token in [`ChatFormatFull`](./chat-formats.md#chatformatfull).

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- `$language`: The result of the [`FormatLanguage`](../sandbox-options/component-formats.md#formatlanguage) option.
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- `$tag`: The result of the [`FormatTag`](../sandbox-options/component-formats.md#formattag) option.
- `$timestamp`: The result of the [`FormatTimestamp`](../sandbox-options/component-formats.md#formattimestamp) option.

### FormatIcon
**Default:** `@($eq($stream card):Item_CardDeck;$eq($stream roll):Item_Dice;$has(@(say;shout;whisper;faction;safehouse;ooc;general) $stream):@($adminIcon;$icon))`

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

### FormatLanguage
**Default:** `$if($all($language $not($unknownLanguage)) [$language]( <SPACE> ))`

The format used for displaying the [roleplay language](languages.md) in which a message was sent.
The default format will display as `[Language]`.

This controls the value of `$language` in [ChatFormatFull](./chat-formats.md#chatformatfull).

**Tokens:**
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$unknownLanguage`](../format-strings/tokens.md#unknownlanguage)

### FormatMenuName
**Default:** `$ifelse($neq($menuType mini_scoreboard) $name $username &#32;[ $name ])`

The format used for displaying character names within in-game menus such as the trading window, medical check, and the admin mini-scoreboard.
If blank, menus will not be affected.

**Tokens:**
- [`$forename`](../format-strings/tokens.md#forename)
- [`$name`](../format-strings/tokens.md#name): The character name without name colors applied.
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
- `$name`: The name that was set with [`/name`](./basic-features.md#enablesetname), if specified.
- [`$surname`](../format-strings/tokens.md#surname)
- [`$username`](../format-strings/tokens.md#username)

### FormatNarrativeDialogueTag
**Default:** `@($eq($stream shout):shouts;$eq($stream whisper):whispers;$endswith($input ?):asks;$endswith($input !):exclaims;$endswith($input ..):says;$lt($len($input) 10):states;says)`

The format used to determine the dialogue tag used in [narrative style](./filters-predicates.md#predicateusenarrativestyle).

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$input`](../format-strings/tokens#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

### FormatNarrativePunctuation
**Default:** `$unless($sneakCallout @($eq($stream shout):!;.))`

The format used to determine the punctuation used in [narrative style](./filters-predicates.md#predicateusenarrativestyle) if the input doesn't end with punctuation.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$input`](../format-strings/tokens#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

### FormatOverheadPrefix
**Default:** `$concats(( ) $index(@(low:[Low];whisper:[Whisper]) $stream) $if($languageRaw [$languageRaw]))&#32;`

The format used to determine the value of the `$prefix` token in [`OverheadFormatFull`](./overhead-formats.md#overheadformatfull).

**Tokens:**:
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$input`](../format-strings/tokens#input)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

### FormatRoll
**Default:** `rolls a $roll on a $sides-sided die`

The format used for local [`/roll`](./chat-formats.md#chatformatroll) overhead message content.

**Tokens:**
- `$roll`: The number that was rolled. This will be wrapped in invisible characters.
- `$sides`: The number of sides on the die that was rolled. This will be wrapped in invisible characters.

### FormatTag
**Default:** `[$tag]$if($eq($chatType server) (: <SPACE> ))`

The format used when `Enable tags` is selected in the chat settings menu.
This describes the chat title that displays to the left of messages (e.g., `[Local]`).

**Tokens:**
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$stream`](../format-strings/tokens.md#stream)
- `$tag`: The title of the chat type associated with the message.

### FormatTimestamp
**Default:** `[$ifelse($eq($hourFormat 12) $h $HH):$mm]`

The format used when `Enable timestamps` is selected in the chat settings menu.

**Tokens:**
- `$ampm`: `am` or `pm`, based on the hour a message was sent.
- `$AMPM`: `AM` or `PM`, based on the hour a message was sent.
- [`$chatType`](../format-strings/tokens.md#chattype)
- `$H`: The hour the message was sent, in 24-hour format.
- `$HH`: The zero-padded hour the message was sent, in 24-hour format.
- `$h`: The hour the message was sent, in 12-hour format.
- `$hh`: The zero-padded hour the message was sent, in 12-hour format.
- `$m`: The minute the message was sent.
- `$mm`: The zero-padded minute the message was sent.
- `$P`: The hour the message was sent, in the hour format the player prefers.
- `$PP`: The zero-padded hour the message was sent, in the hour format the player prefers.
- `$hourFormat`: 12 if the user prefers 12-hour clock formats; otherwise, 24.
- `$s`: The second the message was sent.
- `$ss`: The zero-padded second the message was sent.
- [`$stream`](../format-strings/tokens.md#stream)
