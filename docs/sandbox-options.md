# Sandbox Options

In order to be as configurable as possible, this mod offers a *lot* of sandbox options.
This document serves as an explanation of these options.

Many of the sandbox options accept [format strings](./format-strings.md).
The dollar-sign-prefixed *tokens* that these format strings accept are listed in their documentation.
For a list of available tokens, see [Tokens](./format-string-tokens.md).

To include special characters, [character references](./format-strings.md#character-references) may be used.


## Compatibility Features
Flags for enabling or disable compatibility patches for other mods.
These have no effect if the relevant mod is not active.

### EnableCompatTAD
`default → true`

Enables the compatibility patch for [True Actions Act 3 - Dancing](https://steamcommunity.com/sharedfiles/filedetails/?id=2648779556).
This adds a `/dance` command that makes the player perform a random dance.
It also allows for selecting particular dances by name; see `/help dance`.


## Feature Flags
Options used to enable or disable features of the mod.

### EnableChatNameAsCharacterName
`default → false`

Uses players' names set with [`/name`](#enablesetname) as their character names.
Note that this sets the forename and potentially the surname of the player character; the `$forename` and `$surname` tokens will reflect this.
**Enabling this disables resetting names with `/name`.**

### EnableCustomShouts
`default → true`

This allows players to specify a list of custom shouts that are used when pressing the shout key (default `Q`).
The number of shouts that can be listed and their maximum lengths can be configured using [`MaximumCustomShouts`](#maximumcustomshouts) and [`CustomShoutMaxLength`](#customshoutmaxlength), respectively.

Players can configure custom shouts using an option in the chat settings.

### EnableCustomSneakShouts
`default → true`

This is similar to [`EnableCustomShouts`](#enablecustomshouts), but allows specifying a list of shouts used when pressing the shout key *while sneaking*.
Length limits are controlled by the same options as `EnableCustomShouts`.

### EnableEmotes
`default → true`

Allows players to use [emote](./emotes.md) shortcuts in the form of `.emote`.
These are enabled only in local chats.

### EnableIconPicker
`default → false`

Enables a button for local chats that allows players to select icons that show up in chat.

### EnableMiscellaneousIcons
`default → false`

By default, only icons that are known to work in chat are included when [`EnableIconPicker`](#enableiconpicker) is `true`.
If this option is enabled, icons that are unknown will be added to a 'Miscellaneous' category of the icon picker.
This may result in icons that do not work properly, including icons from other mods.

### EnableNameColorInAllChats
`default → false`

By default, name colors only display in `/say` chat.
If this is enabled, it will be respected for all chat types.

*See also: [`EnableSetNameColor`](#enablesetnamecolor) and [`EnableSpeechColorAsDefaultNameColor`](#enablespeechcolorasdefaultnamecolor).*

### EnableSetName
`default → true`

Allows players to set their name in chat using `/name <Name>`.
Chat names can be reset by using the same command without a name, unless the [`EnableChatNameAsCharacterName`](#enablechatnameascharactername) option is enabled.

### EnableSetNameColor
`default → false`

Allows players to set their name color using the chat settings menu.
Other players will be able to see chat name colors.

### EnableSetSpeechColor
`default → true`

Allows players to customize the color used for overhead speech bubbles.
This affects the existing in-game option within the Multiplayer tab of the settings.

If `/me` is not enabled, this has no effect.

### EnableSpeechColorAsDefaultNameColor
`default → true`

If enabled, players' overhead speech color will be used as their default name color.
This can be used alongside or independently of [`EnableSetNameColor`](#enablesetnamecolor).


## Limits and Ranges
Numeric options that define limits and ranges for various functionality.

### CustomShoutMaxLength
`default → 30, minimum → 1, maximum → 200`

The maximum length for individual [custom shouts](#enablecustomshouts).

### MaximumCustomShouts
`default → 10, minimum → 1, maximum → 20`

The maximum number of [custom shouts](#enablecustomshouts) that players are allowed to define.

### MaximumColorValue
`default → 255, minimum → 0, maximum → 255`

This dictates the maximum value for R, G, and B components of chat colors.
It applies to all chat color customization settings.

### MinimumColorValue
`default → 48, minimum → 0, maximum → 255`

This dictates the minimum value for R, G, and B components of chat colors.
It applies to all chat color customization settings.

### NameMaxLength
`default → 50, minimum → 0, maximum → 50`

The maximum length of chat names set with `/name`.

### RangeLooc
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for [`/looc`](#chatformatlooc) messages to be visible.

### RangeMe
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for [`/me`](#chatformatme) messages to be visible.

### RangeSay
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for `/say` messages to be visible.

### RangeWhisper
`default → 3, minimum → 1, maximum → 30`

The maximum distance between players for local [`/whisper`](#chatformatwhisper)  messages to be visible.
This does not apply to the default whisper chat.

### RangeYell
`default → 60, minimum → 1, maximum → 60`

The maximum distance between players for `/yell` messages to be visible.


## Default Colors
Options that define the default colors for the chat types added by the mod.
Colors should be in RGB format, space- or comma-delimited.

These colors will be used unless overriden by a player's chat color settings.

### ColorAdmin
`default → 255 255 255`

The default color used for `/admin` messages.

### ColorDiscord
`default → 144 137 218`

The default color used for messages from Discord.

### ColorFaction
`default → 22 113 20`

The default color used for `/faction` messages.

### ColorGeneral
`default → 255 165 0`

The default color used for `/all` messages.

### ColorLooc
`default → 48 128 128`

The default color used for [`/looc`](#chatformatlooc) messages.

### ColorMe
`default → 130 130 130`

The default color used for [`/me`](#chatformatme) messages.

### ColorMeWhisper
`default → 85 48 139`

The default color used for [`/mewhisper`](#chatformatmewhisper) messages.

### ColorMeYell
`default → 255 51 51`

The default color used for [`/meyell`](#chatformatmeyell) messages.

### ColorPrivate
`default → 85 26 139`

The default color used for `/pm` (vanilla `/whisper`) messages.

### ColorRadio
`default → 178 178 178`

The default color used for radio messages.

### ColorSafehouse
`default → 22 113 20`

The default color used for `/safehouse` messages.

### ColorSay
`default → 255 255 255`

The default color used for `/say` messages.

### ColorServer
`default → 0 128 255`

The default color used for server messages.

### ColorWhisper
`default → 85 48 139`

The default color used for local [`/whisper`](#chatformatwhisper) messages.
This does not apply to the [default](#colorprivate) whisper chat.

### ColorYell
`default → 255 51 51`

The default color used for `/yell` messages.


## Component Formats
Options that define the string formats used for purposes other than overhead speech bubbles and chat messages.

### FormatMenuName
`default → $ifelse($neq($menuType mini_scoreboard) $name $username &#32;[ $name ])`  
`tokens → $menuType, $forename, $surname, $username, $name`

The format used for displaying character names within in-game menus such as Trading and Medical Check.
If blank, menus will not be affected.

### FormatName
`default → $forename`  
`tokens → $chatType, $forename, $surname, $username`

The format used to determine the values of `$name` and `$nameRaw` in other format strings.

### FormatTag
`default → [$tag]$if($eq($chatType server) :&#32;<SPACE>&#32;)`  
`tokens → $chatType, $tag`

The format used when `Enable tags` is selected in the chat settings menu.
This describes the chat title that shows up to the left of messages (e.g., `[Local]`).

### FormatTimestamp
`default → [$ifelse($eq($hourFormatPref 12) $h $H):$mm]`  
`tokens → $chatType, $H, $HH, $h, $hh, $m, $mm, $ampm, $AMPM, $hourFormatPref`

The format used when `Enable timestamps` is selected in the chat settings menu.


## Overhead Formats
Options used to determine the content that displays in speech bubbles that appear over a character's head.

**These formats can have an effect on chat formats.**
For example, reversing the overhead text will result in the message content being reversed in chat.

### OverheadFormatLooc
`default → (( $1 ))`  
`tokens → $1`

Defines the format used for overhead speech bubbles of local out-of-character [`/looc`](#chatformatlooc) messages.
If blank, `/looc` messages will not display overhead.

### OverheadFormatMe
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/me`](#chatformatme) messages.
If blank, `/me` messages will not display overhead.

### OverheadFormatMeWhisper
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/mewhisper`](#chatformatmewhisper) messages.
If blank, `/mewhisper` messages will not display overhead.

### OverheadFormatMeYell
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/meyell`](#chatformatmeyell) messages.
If blank, `/meyell` messages will not display overhead.

### OverheadFormatWhisper
`default → ($1)`  
`tokens → $1`

Defines the format used for overhead speech bubbles of local [`/whisper`](#chatformatwhisper) messages.
If blank, `/whisper` messages will not display overhead.
This does not apply to the default whisper chat.


## Chat Formats
These options are used to determine the content that displays in chat.

### ChatFormatAdmin
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/admin` messages in chat.

### ChatFormatDiscord
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $message`

The format used for messages from Discord in chat.
Messages from Discord will not apply name colors.

### ChatFormatFaction
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/faction` messages in chat.

### ChatFormatGeneral
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/all` messages in chat.

### ChatFormatIncomingPrivate
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for incoming private messages in chat.

### ChatFormatLooc
`default → $name: <SPACE> (( $message ))`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for local out-of-character `/looc` messages in chat.

### ChatFormatMe
`default → &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/me` messages in chat.

Allows players to use `/me` to describe their actions.
If blank, `/me` messages will be disabled.
How these messages appear overhead is controlled by [`OverheadFormatMe`](#overheadformatme).

### ChatFormatMeWhisper
`default → &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/mewhisper` (`/mew`) messages in chat.
This behaves similarly to [`/me`](#chatformatme), but uses whisper [range](#rangewhisper).

If blank, `/mewhisper` messages will be disabled.

### ChatFormatMeYell
`default → &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/meyell` (`/mey`) messages in chat.
This behaves similarly to [`/me`](#chatformatme), but uses yell [range](#rangeyell).

If blank, `/meyell` messages will be disabled.

### ChatFormatOutgoingPrivate
`default → $gettext(UI_OmiChat_private_chat_to $recipient): <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $recipient, $recipientName, $message`

The format used for outgoing private messages in chat.

### ChatFormatRadio
`default → $gettext(UI_OmiChat_radio $frequency): <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $frequency, $message`

The format used for radio messages in chat.

### ChatFormatSafehouse
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/safehouse` messages in chat.

### ChatFormatSay
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/say` messages in chat.

### ChatFormatServer
`default → $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for server messages in chat.

### ChatFormatWhisper
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for local `/whisper` messages in chat.

Modifies `/whisper` chat to act as local chat which doesn't attract zombies and has a very short range.
If populated, the existing `/whisper` is changed to `/pm` (`/private`).
If blank, local whisper will be disabled and the default `/whisper` will not be renamed.

*See also: [`RangeWhisper`](#rangewhisper), [`OverheadFormatWhisper`](#overheadformatwhisper).*

### ChatFormatYell
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/yell` messages in chat.
