# Sandbox options

In order to be as configurable as possible, this mod offers a *lot* of sandbox options.
This document serves as an explanation of these options.

## Tokens

Many of the options accept [format strings](./format-strings.md); the dollar-sign-prefixed *tokens* that these format strings accept are listed in their documentation.
The full list of tokens follows.
**Not all of these tokens are available to every sandbox option that uses format strings. Each relevant option lists the subset of tokens that it accepts.**

- `$1`: The content of a message in limited format strings.
    - This token is **required** in format strings in which it appears, and it must be the only token present. Invalid use will result in the format string being ignored.
    Additionally, format strings that use this token **disallow** [functions](./format-string-functions.md) and [at-maps](./format-string-at-maps.md).
    This currently only applies to [`MeOverheadFormat`](#meoverheadformat) and [`WhisperOverheadFormat`](#whisperchatformat).
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
- `$ampm`: `am` or `pm`, based on the hour.
- `$AMPM`: `AM` or `PM`, based on the hour.
- `$message`: The message content.
- `$menuType`: The type of menu in which the format string will appear.
    - One of `medical`, `trade`, or `mini_scoreboard`.
- `$name`: The chat name of the relevant player. This will also include the name color, if one is included.
    - Determined by the name set with [`/name`](#allowsetname) or the format specified by [`NameFormat`](#nameformat).
- `$nameRaw`: The same as `$name`, but does not include name colors.
- `$recipient`: The username of the recipient of a private message.
- `$recipientName`: The name of the recipient of a private message.
    - Determined in the same way as `$name`.
- `$surname`: The relevant player's character's surname.
- `$tag`: The title of the chat type associated with the message.
- `$username`: The relevant player's username.


## Feature Flags
Options within this set are used to enable or disable features of the mod.

### AllowCustomShouts
`default → true`

This allows players to specify a list of custom shouts that are used when pressing the shout key (default `Q`).
The number of shouts that can be listed and their maximum lengths can be configured using [`MaximumCustomShouts`](#maximumcustomshouts) and [`CustomShoutMaxLength`](#customshoutmaxlength), respectively.

Players can configure custom shouts using an option in the chat settings.

See also: [`UppercaseCustomShouts`](#uppercasecustomshouts).

### AllowCustomSneakShouts
`default → true`

This is similar to [`AllowCustomShouts`](#allowcustomshouts), but allows specifying a list of shouts used when pressing the shout key *while sneaking*.
Length limits are controlled by the same options as `AllowCustomShouts`.

See also: [`LowercaseCustomSneakShouts`](#lowercasecustomsneakshouts).

### AllowEmotes
`default → true`

Allows players to use [emote](./emotes.md) shortcuts in the form of `.emote`.
These are enabled only in local chats—`/say`, `/yell`, [`/me`](#mechatformat), and [`/whisper`](#whisperchatformat) (if using local whisper).

### AllowSetChatColors
`default → true`

Allows players to customize the colors used in their chat.
This works on a player-by-player basis; unlike [name](#allowsetnamecolor) and [speech](#allowsetspeechcolor) colors, players will only see the custom colors that they've set for themselves.

### AllowSetName
`default → true`

Allows players to set their name in chat using `/name <Name>`.
Chat names can be reset using the same command without a name, unless the [`UseChatNameAsCharacterName`](#usechatnameascharactername) option is enabled.

### AllowSetNameColor
`default → false`

Allows players to set their name color using the chat settings menu.
Other players will be able to see chat name colors.

### AllowSetSpeechColor
`default → true`

Allows players to customize the color used for overhead speech bubbles. This affects the existing in-game option within the Multiplayer tab of the settings.

### EnableEmojiPicker
`default → false`

Enables a button for local chats that allows players to select icons that show up in chat.

### EnableTADCompat
`default → true`

Enables the compatibility patch for [True Actions Act 3 - Dancing](https://steamcommunity.com/sharedfiles/filedetails/?id=2648779556).
This adds a `/dance` command that makes the player perform a random dance.
It also allows for selecting particular dances by name; see `/help dance`.

This has no effect if the mod is not active.

### IncludeMiscellaneousEmoji
`default → false`

By default, only icons that are known to work in chat are included when [`EnableEmojiPicker`](#enableemojipicker) is `true`.
If this option is enabled, icons that are unknown will be added to a 'Miscellaneous' category of the emoji picker.
This may result in icons that do not work properly, including icons from other mods.

### LowercaseCustomSneakShouts
`default → true`

If enabled, [custom sneak shouts](#allowcustomsneakshouts) will be coerced into all lowercase letters.

### UppercaseCustomShouts
`default → true`

If enabled, [custom shouts](#allowcustomshouts) will be coerced into all uppercase letters.

### UseChatNameAsCharacterName
`default → false`

Uses players' names set with [`/name`](#allowsetname) as their character names.
Note that this sets the forename and potentially the surname of the player; the `$forename` and `$surname` tokens will reflect this.
**This disables resetting names with `/name`.**

### UseNameColorInAllChats
`default → false`

By default, name colors only display in `/say` chat.
If this is enabled, it will be respected for all chat types.

### UseSpeechColorAsDefaultNameColor
`default → true`

If enabled, players' overhead speech color will be used as their default name color.
This can be used alongside or independently of [`AllowSetNameColor`](#allowsetnamecolor).


## Limits and Ranges
These numeric options define limits and ranges for various functionality.

### CustomShoutMaxLength
`default → 30, minimum → 1, maximum → 200`

The maximum length for individual [custom shouts](#allowcustomshouts).

### MaximumCustomShouts
`default → 10, minimum → 1, maximum → 20`

The maximum number of [custom shouts](#allowcustomshouts) that players are allowed to define.

### MaximumColorValue
`default → 255, minimum → 0, maximum → 255`

This dictates the maximum value for R, G, and B components of chat colors.
It applies to all chat color customization [settings](#allowsetchatcolors).

### MinimumColorValue
`default → 48, minimum → 0, maximum → 255`

This dictates the minimum value for R, G, and B components of chat colors.
It applies to all chat color customization [settings](#allowsetchatcolors).

### MeRange
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for [`/me`](#mechatformat) messages to be visible.

### NameMaxLength
`default → 50, minimum → 0, maximum → 50`

The maximum length of chat names set with `/name`.

### SayRange
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for `/say` messages to be visible.

### ShoutRange
`default → 60, minimum → 1, maximum → 60`

The maximum distance between players for `/yell` messages to be visible.

### WhisperRange
`default → 3, minimum → 1, maximum → 30`

The maximum distance between players for local `/whisper` messages to be visible.
This applies to the local [`/whisper`](#whisperchatformat) chat, not the default whisper chat.


## Default Colors
These options define the default colors for the chat types added by the mod.
Numbers should be in RGB format, space- or comma-delimited.

### MeColor
`default → 130 130 130`

The default color used for [`/me`](#mechatformat) messages, unless overriden using the [settings](#allowsetchatcolors).

### WhisperColor
`default → 85 48 139`

The default color used for local `/whisper` messages, unless overriden using the [settings](#allowsetchatcolors).
This applies to the local [`/whisper`](#whisperchatformat) chat, not the default whisper chat.


## Message Component Formats
These options define the string formats used for components of messages.

### NameFormat
`default → $forename`  
`tokens → $chatType, $forename, $surname, $username`

The format used to determine the values of `$name` and `$nameRaw` in other format strings.

### TagFormat
`default → [$tag]$if($eq($chatType server) (: <SPACE> ))`  
`tokens → $chatType, $tag`

The format used when `Enable tags` is selected in the chat settings menu.
This describes the chat title that shows up to the left of messages (e.g., `[Local]`).

### TimestampFormat
`default → [$ifelse($eq($hourFormatPref 12) $h $H):$mm]`  
`tokens → $chatType, $H, $HH, $h, $hh, $m, $mm, $ampm, $AMPM, $hourFormatPref`

The format used when `Enable timestamps` is selected in the chat settings menu.


## Message Formats
These options are used to determine the content that displays in messages, overhead speech bubbles, or in menus.


### AdminChatFormat
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/admin` messages in chat.

### DiscordChatFormat
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $message`

The format used for messages from Discord in chat.
Messages from Discord will not apply name colors.

### FactionChatFormat
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/faction` messages in chat.

### GeneralChatFormat
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/all` messages in chat.

### IncomingPrivateChatFormat
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for incoming private messages in chat.

### MeChatFormat
`default → $name <SPACE> $punctuate($trimright($message))`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/me` messages in chat.

Allows players to use `/me` to describe their actions.
If blank, `/me` messages will be disabled.
How these messages appear overhead is controlled by [`MeOverheadFormat`](#meoverheadformat).

### MeOverheadFormat
`(blank by default)`  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/me`](#mechatformat) messages.
If blank, `/me` messages will not display overhead.

### MenuNameFormat
`default → $ifelse($neq($menuType mini_scoreboard) $name $username ( [) $name ])`  
`tokens → $menuType, $forename, $surname, $username, $name`

The format used for displaying character names within in-game menus such as Trading and Medical Check.
If blank, menus will not be affected.

### OutgoingPrivateChatFormat
`default → $gettext(UI_OmiChat_private_chat_to $recipient): <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $recipient, $recipientName, $message`

The format used for outgoing private messages in chat.

### RadioChatFormat
`default → $gettext(UI_OmiChat_radio $frequency): <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $frequency, $message`

The format used for radio messages in chat.

### SafehouseChatFormat
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/safehouse` messages in chat.

### SayChatFormat
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/say` messages in chat.

### ServerChatFormat
`default → $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for server messages in chat.

### ShoutChatFormat
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/yell` messages in chat.

### WhisperChatFormat
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for local `/whisper` messages in chat.

Modifies `/whisper` chat to act as local chat which doesn't attract zombies and has a very short range.
The existing `/whisper` is changed to `/private` (`/pm`).
If blank, local whisper will be disabled and the default `/whisper` will not be renamed.

### WhisperOverheadFormat
`default → ($1)`  
`tokens → $1`

Defines the format used for overhead speech bubbles of local `/whisper` messages.
If blank, `/whisper` messages will not display overhead.
This applies to the local [`/whisper`](#whisperchatformat) chat, not the default whisper chat.
