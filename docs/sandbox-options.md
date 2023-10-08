# Sandbox Options

In order to be as configurable as possible, this mod offers a *lot* of sandbox options.
This document serves as an explanation of these options.

Many of the sandbox options accept [format strings](./format-strings.md).
The dollar-sign-prefixed *tokens* that these format strings accept are listed in their documentation.
For a list of available tokens, see [Tokens](./format-string-tokens.md).

To include special characters, [character references](./format-strings.md#character-references) may be used.


## Compatibility Feature Flags
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

Uses players' names set with `/name` as their character names.
Note that this sets the forename and potentially the surname of the player character; the `$forename` and `$surname` tokens will reflect this.
**Enabling this disables resetting names with `/name`.**

See also: [`EnableSetName`](#enablesetname).

### EnableCustomShouts
`default → true`

This allows players to specify a list of custom shouts that are used when pressing the shout key (default `Q`).
Players can configure custom shouts using an option in the chat settings.

See also:
- [`EnableCustomSneakShouts`](#enablecustomsneakshouts)
- [`MaximumCustomShouts`](#maximumcustomshouts)
- [`CustomShoutMaxLength`](#customshoutmaxlength)

### EnableCustomSneakShouts
`default → true`

This is similar to [`EnableCustomShouts`](#enablecustomshouts), but allows specifying a list of shouts used when pressing the shout key *while sneaking*.
Length limits are controlled by the same options as `EnableCustomShouts`.

See also:
- [`MaximumCustomShouts`](#maximumcustomshouts)
- [`CustomShoutMaxLength`](#customshoutmaxlength)

### EnableEmotes
`default → true`

Allows players to use [emote](./emotes.md) shortcuts in the form of `.emote`.
These are enabled only in local chats.

### EnableIconPicker
`default → false`

Enables a button that allows players to adds icons that show up in chat to their messages.

See also: [`EnableMiscellaneousIcons`](#enablemiscellaneousicons).

### EnableMiscellaneousIcons
`default → false`

By default, only icons that are known to work in chat are included when [`EnableIconPicker`](#enableiconpicker) is `true`.
If this option is enabled, icons that are unknown will be added to a 'Miscellaneous' category of the icon picker.
This may result in icons that do not work properly, including icons from other mods.

### EnableSetName
`default → true`

Allows players to set their name in chat using `/name Name`.
Chat names can be reset by using the same command without a name, unless the [`EnableChatNameAsCharacterName`](#enablechatnameascharactername) option is enabled.

See also: [`FilterNickname`](#filternickname).

### EnableSetNameColor
`default → false`

Allows players to set their name color using the chat settings menu.
Other players will be able to see chat name colors.

See also:
- [`EnableSetName`](#enablesetname)
- [`EnableSetSpeechColor`](#enablesetspeechcolor)
- [`EnableSpeechColorAsDefaultNameColor`](#enablespeechcolorasdefaultnamecolor)

### EnableSetSpeechColor
`default → true`

Allows players to customize the color used for overhead speech bubbles.
This affects the existing in-game option within the Multiplayer tab of the settings.

See also:
- [`EnableSetNameColor`](#enablesetnamecolor)
- [`EnableSpeechColorAsDefaultNameColor`](#enablespeechcolorasdefaultnamecolor)

### EnableSpeechColorAsDefaultNameColor
`default → true`

If enabled, players' overhead speech color will be used as their default name color.
This can be used alongside with or independently of [`EnableSetNameColor`](#enablesetnamecolor).

See also:
- [`EnableSetSpeechColor`](#enablesetspeechcolor)


## Limits
Numeric options that define limits for various functionality.

### CustomShoutMaxLength
`default → 30, minimum → 1, maximum → 200`

The maximum length for individual custom [shouts](#enablecustomshouts) and [sneak shouts](#enablecustomsneakshouts).

### MinimumCommandAccessLevel
`default → 16`

The minimum access level needed to execute commands such as `/setname`.

- Admin: 32
- Moderator: 16
- Overseer: 8
- GM: 4
- Observer: 2
- Player: 1

### MaximumCustomShouts
`default → 10, minimum → 1, maximum → 20`

The maximum number of custom [shouts](#enablecustomshouts) and [sneak shouts](#enablecustomsneakshouts) that players are allowed to define.

Note that the two maximums are separate; a value of `10` means a player can specify 10 shouts and 10 sneak shouts.


## Ranges
Numeric options that define distance ranges for chat messages.

### RangeDo
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for [`/do`](#chatformatdo) messages to be visible.

### RangeDoLoud
`default → 60, minimum → 1, maximum → 60`

The maximum distance between players for [`/doloud`](#chatformatdoloud) messages to be visible.

### RangeDoQuiet
`default → 3, minimum → 1, maximum → 30`

The maximum distance between players for [`/doquiet`](#chatformatdoquiet) messages to be visible.

### RangeLooc
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for [`/looc`](#chatformatlooc) messages to be visible.

### RangeMe
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for [`/me`](#chatformatme) messages to be visible.

### RangeMeLoud
`default → 60, minimum → 1, maximum → 60`

The maximum distance between players for [`/meloud`](#chatformatmeloud) messages to be visible.

### RangeMeQuiet
`default → 3, minimum → 1, maximum → 30`

The maximum distance between players for [`/mequiet`](#chatformatmequiet) messages to be visible.

### RangeSay
`default → 30, minimum → 1, maximum → 30`

The maximum distance between players for `/say` messages to be visible.

### RangeWhisper
`default → 3, minimum → 1, maximum → 30`

The maximum distance between players for local [`/whisper`](#chatformatwhisper)  messages to be visible.

This does **not** apply to the vanilla whisper chat.

### RangeYell
`default → 60, minimum → 1, maximum → 60`

The maximum distance between players for `/yell` messages to be visible.


## Default Colors
Options that define the default colors for the chat types added by the mod.
Colors should be in RGB format, space- or comma-delimited.

These colors will be used unless overriden by a player's client-side chat color settings.

### ColorAdmin
`default → 255 255 255`

The default color used for `/admin` messages.

See also: [`ChatFormatAdmin`](#chatformatadmin).

### ColorDiscord
`default → 144 137 218`

The default color used for messages from Discord.

See also: [`ChatFormatDiscord`](#chatformatdiscord).

### ColorDo
`default → 130 130 130`

The default color used for [`/do`](#chatformatdo) messages.

### ColorDoLoud
`default → 255 51 51`

The default color used for [`/doloud`](#chatformatdoloud) messages.

### ColorDoQuiet
`default → 85 48 139`

The default color used for [`/doquiet`](#chatformatdoquiet) messages.

### ColorFaction
`default → 22 113 20`

The default color used for `/faction` messages.

See also: [`ChatFormatFaction`](#chatformatfaction).

### ColorGeneral
`default → 255 165 0`

The default color used for `/all` messages.

See also: [`ChatFormatGeneral`](#chatformatgeneral).

### ColorLooc
`default → 48 128 128`

The default color used for [`/looc`](#chatformatlooc) messages.

### ColorMe
`default → 130 130 130`

The default color used for [`/me`](#chatformatme) messages.

### ColorMeLoud
`default → 255 51 51`

The default color used for [`/meloud`](#chatformatmeloud) messages.

### ColorMeQuiet
`default → 85 48 139`

The default color used for [`/mequiet`](#chatformatmequiet) messages.

### ColorPrivate
`default → 85 26 139`

The default color used for private messages.
This applies to the vanilla `/whisper`, which is `/pm` if [local whisper](#chatformatwhisper) is enabled.

See also
- [`ColorWhisper`](#colorwhisper)
- [`ChatFormatIncomingPrivate`](#chatformatincomingprivate)
- [`ChatFormatOutgoingPrivate`](#chatformatoutgoingprivate)

### ColorRadio
`default → 178 178 178`

The default color used for radio messages.

See also: [`ChatFormatRadio`](#chatformatradio).

### ColorSafehouse
`default → 22 113 20`

The default color used for `/safehouse` messages.

See also: [`ChatFormatSafehouse`](#chatformatsafehouse).

### ColorSay
`default → 255 255 255`

The default color used for `/say` messages.

See also: [`ChatFormatSay`](#chatformatsay).

### ColorServer
`default → 0 128 255`

The default color used for server messages.

See also: [`ChatFormatServer`](#chatformatserver).

### ColorWhisper
`default → 85 48 139`

The default color used for local [`/whisper`](#chatformatwhisper) messages.

This does **not** apply to the vanilla whisper chat.

See also: [`ColorPrivate`](#colorprivate).

### ColorYell
`default → 255 51 51`

The default color used for `/yell` messages.

See also: [`ChatFormatYell`](#chatformatyell).


## Filters & Predicates
Options that are used to define logic for mod functionality.

Filters are used to transform input values.
For predicates, any value other than the empty string is considered `true`.

### FilterNickname
`default → $sub($name 1 50)`  
`tokens → $name`

Transforms names set by players with `/name`.
The default option will limit names to 50 characters.

If the empty string is returned, the `/name` command will fail.

See also [`EnableSetName`](#enablesetname).

### PredicateUseNameColor
`default → $eq($stream say)`  
`tokens → $stream, $chatType, $author, $authorRaw, $name, $nameRaw`

Determines whether name colors are used for a message.

See also:
- [`EnableSetNameColor`](#enablesetnamecolor)
- [`EnableSpeechColorAsDefaultNameColor`](#enablespeechcolorasdefaultnamecolor)


## Component Formats
Options that define the string formats used for purposes other than overhead speech bubbles and chat messages.

### FormatCard
`default → $gettext(UI_OmiChat_card_local $card)`  
`tokens → $card`

The format used for local [`/card`](#chatformatcard) message content.

### FormatInfo
`(blank by default)`  
`tokens → $forename, $surname, $username, $name`

Information that can be accessed by clicking an info button on the chat.
If blank, the info button will not be visible.

### FormatMenuName
`default → $ifelse($neq($menuType mini_scoreboard) $name $username &#32;[ $name ])`  
`tokens → $menuType, $forename, $surname, $username, $name`

The format used for displaying character names within in-game menus such as the trading window, medical check, and the admin mini-scoreboard.
If blank, menus will not be affected.

### FormatName
`default → $ifelse($has(@(general;admin;safehouse;faction;whisper) $chatType) $username $forename)`  
`tokens → $chatType, $forename, $surname, $username`

The format used to determine the values of `$name` and `$nameRaw` in other format strings.

### FormatRoll
`default → $gettext(UI_OmiChat_roll_local $roll $sides)`  
`tokens → $roll, $sides`

The format used for local [`/roll`](#chatformatroll) message content.

### FormatTag
`default → [$tag]$if($eq($chatType server) :&#32;<SPACE>&#32;)`  
`tokens → $chatType, $stream, $tag`

The format used when `Enable tags` is selected in the chat settings menu.
This describes the chat title that displays to the left of messages (e.g., `[Local]`).

### FormatTimestamp
`default → [$ifelse($eq($hourFormatPref 12) $h $H):$mm]`  
`tokens → $chatType, $stream, $H, $HH, $h, $hh, $m, $mm, $ampm, $AMPM, $hourFormatPref`

The format used when `Enable timestamps` is selected in the chat settings menu.


## Overhead Formats
Options that the content that displays in speech bubbles that appear over a character's head.

**These formats can have an effect on chat formats.**
For example, reversing the overhead text will result in the message content being reversed in chat.

### OverheadFormatCard
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

The overhead format used for local [`/card`](#chatformatcard) messages.
If blank, `/card` messages will not display overhead.

### OverheadFormatDo
`(blank by default)`  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/do`](#chatformatdo) messages.
If blank, `/do` messages will not display overhead.

### OverheadFormatDoLoud
`(blank by default)`  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/doloud`](#chatformatdoloud) messages.
If blank, `/doloud` messages will not display overhead.

### OverheadFormatDoQuiet
`(blank by default)`  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/doquiet`](#chatformatdoquiet) messages.
If blank, `/doquiet` messages will not display overhead.

### OverheadFormatLooc
`default → (( $1 ))`  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/looc`](#chatformatlooc) messages.
If blank, `/looc` messages will not display overhead.

### OverheadFormatMe
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/me`](#chatformatme) messages.
If blank, `/me` messages will not display overhead.

### OverheadFormatMeLoud
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/meloud`](#chatformatmeloud) messages.
If blank, `/meloud` messages will not display overhead.

### OverheadFormatMeQuiet
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`/mequiet`](#chatformatmequiet) messages.
If blank, `/mequiet` messages will not display overhead.

### OverheadFormatRoll
`default → &#171; $1 &#187;` (`« $1 »`)  
`tokens → $1`

The overhead format used for local [`/roll`](#chatformatroll) messages.
If blank, `/roll` messages will not display overhead.

### OverheadFormatWhisper
`default → ($1)`  
`tokens → $1`

Defines the format used for overhead speech bubbles of [`local /whisper`](#chatformatwhisper) messages.
If blank, `/whisper` messages will not display overhead.

This does **not** apply to the vanilla whisper chat.


## Chat Formats
Options that determine the content that displays in chat.

### ChatFormatAdmin
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/admin` messages in chat.

See also: [`ColorAdmin`](#coloradmin).

### ChatFormatCard
`default → &#32;<IMAGE:Item_CardDeck&#44;15&#44;14> <SPACE> &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for local `/card` messages in chat.
This respects the range and color options of [`/me`](#chatformatme).

If blank, `/card` messages will be global instead of local and related options will be ignored.

See also:
- [`OverheadFormatCard`](#overheadformatcard)
- [`ColorMe`](#colorme)
- [`RangeMe`](#rangeme)

### ChatFormatDiscord
`default → $author: <SPACE> $message`  
`tokens → $author, $authorRaw, $message`

The format used for messages from Discord in chat.
Messages from Discord will not apply name colors.

See also: [`ColorDiscord`](#colordiscord).

### ChatFormatDo
`default → &#171; <SPACE> $punctuate($capitalize($trim($message))) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/do` messages in chat.
If blank, `/do` messages will be disabled.

Allows players to use `/do` to narrate events.
`/do` allow players to narrate events.
With the default setting, `/do the lights flicker` will appear in chat as `« The lights flicker. »`.

See also:
- [`ColorDo`](#colordo)
- [`RangeDo`](#rangedo)
- [`OverheadFormatDo`](#overheadformatdo)
- [`ChatFormatMe`](#chatformatme)

### ChatFormatDoLoud
`default → &#171; <SPACE> $punctuate($capitalize($trim($message))) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/doloud` (`/dl`) messages in chat.
If blank, `/doloud` messages will be disabled.

`/doloud` behaves similarly to [`/do`](#chatformatdo), but has a larger range.

See also:
- [`ColorDoLoud`](#colordoloud)
- [`RangeDoLoud`](#rangedoloud)
- [`OverheadFormatDoLoud`](#overheadformatdoloud)

### ChatFormatDoQuiet
`default → &#171; <SPACE> $punctuate($capitalize($trim($message))) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/doquiet` (`/dq`) messages in chat.
If blank, `/doquiet` messages will be disabled.

`/doquiet` behaves similarly to [`/do`](#chatformatdo), but has a smaller range.

See also:
- [`ColorDoQuiet`](#colordoquiet)
- [`RangeDoQuiet`](#rangedoquiet)
- [`OverheadFormatDoQuiet`](#overheadformatdoquiet)

### ChatFormatFaction
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/faction` messages in chat.

See also: [`ColorFaction`](#colorfaction).

### ChatFormatGeneral
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/all` messages in chat.

See also: [`ColorGeneral`](#colorgeneral).

### ChatFormatIncomingPrivate
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for incoming private messages in chat.

See also
- [`ColorPrivate`](#colorprivate)
- [`ChatFormatOutgoingPrivate`](#chatformatoutgoingprivate)

### ChatFormatLooc
`default → $name: <SPACE> (( $message ))`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/looc` (local out-of-character) messages in chat.

See also:
- [`ColorLooc`](#colorlooc)
- [`RangeLooc`](#rangelooc)
- [`OverheadFormatLooc`](#overheadformatlooc)

### ChatFormatMe
`default → &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/me` messages in chat.
If blank, `/me` messages will be disabled.

`/me` messages allow players to describe their actions.
With the default settings, if a player with a character named “Jane” uses `/me smiles` it will appear in chat as `« Jane smiles. »`.

See also:
- [`ColorMe`](#colorme)
- [`RangeMe`](#rangeme)
- [`OverheadFormatMe`](#overheadformatme)
- [`ChatFormatDo`](#chatformatdo)

### ChatFormatMeLoud
`default → &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/meloud` (`/ml`) messages in chat.
If blank, `/meloud` messages will be disabled.

`/meloud` behaves similarly to [`/me`](#chatformatme), but has a larger range.

See also:
- [`ColorMeLoud`](#colormeloud)
- [`RangeMeLoud`](#rangemeloud)
- [`OverheadFormatMeLoud`](#overheadformatmeloud)

### ChatFormatMeQuiet
`default → &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/mequiet` (`/mq`) messages in chat.
If blank, `/mequiet` messages will be disabled.

`/mequiet` behaves similarly to [`/me`](#chatformatme), but has a smaller range.

See also:
- [`ColorMeQuiet`](#colormequiet)
- [`RangeMeQuiet`](#rangemequiet)
- [`OverheadFormatMeQuiet`](#overheadformatmequiet)

### ChatFormatOutgoingPrivate
`default → $gettext(UI_OmiChat_private_chat_to $recipientName): <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $recipient, $recipientName, $message`

The format used for outgoing private messages in chat.

See also
- [`ColorPrivate`](#colorprivate)
- [`ChatFormatIncomingPrivate`](#chatformatincomingprivate)

### ChatFormatRadio
`default → $gettext(UI_OmiChat_radio $frequency): <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $frequency, $message`

The format used for radio messages in chat.

See also: [`ColorRadio`](#colorradio).

### ChatFormatRoll
`default → &#32;<IMAGE:Item_Dice&#44;15&#44;14> <SPACE> &#171; <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE> &#187;`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for local `/roll` messages in chat.
This respects the range and color options of [`/me`](#chatformatme).

If blank, `/roll` messages will be global instead of local and related options will be ignored.

See also:
- [`OverheadFormatRoll`](#overheadformatroll)
- [`ColorMe`](#colorme)
- [`RangeMe`](#rangeme)

### ChatFormatSafehouse
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/safehouse` messages in chat.

See also: [`ColorSafehouse`](#colorsafehouse).

### ChatFormatSay
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/say` messages in chat.

See also: [`ColorSay`](#colorsay).

### ChatFormatServer
`default → $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for server messages in chat.

See also: [`ColorServer`](#colorserver).

### ChatFormatWhisper
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for local `/whisper` messages in chat.

Modifies `/whisper` chat to act as local chat which doesn't attract zombies and has a very short range.
If populated, the existing `/whisper` is changed to `/pm`.
If blank, local whisper will be disabled and the default `/whisper` will not be renamed.

See also:
- [`ColorWhisper`](#colorwhisper)
- [`RangeWhisper`](#rangewhisper)
- [`OverheadFormatWhisper`](#overheadformatwhisper)

### ChatFormatYell
`default → $name: <SPACE> $message`  
`tokens → $author, $authorRaw, $name, $nameRaw, $message`

The format used for `/yell` messages in chat.

See also: [`ColorYell`](#coloryell).
