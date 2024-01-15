# Component Formats

Options that define the string formats used for purposes other than overhead speech bubbles and chat messages.

### FormatAdminIcon
`default → Item_Sledgehamer`  
`tokens → $username`

The format used to determine the value of `$adminIcon` in the [`FormatIcon`](#formaticon) format.
This is only used in that format string when the player is an admin with the relevant option enabled.

### FormatCard
`default → draws $card`  
`tokens → $card`

The format used for local [`/card`](./chat-formats.md#chatformatcard) overhead message content.

### FormatIcon
`default → @($eq($stream card):Item_CardDeck;$eq($stream roll):Item_Dice;$has(@(say;shout;whisper;faction;safehouse;looc;general) $stream):@($adminIcon;$icon))`  
`tokens → $chatType, $stream, $icon`

The format used to determine the value of `$icon` in other formats.
The value of `$icon` in this format string is the icon set with `/seticon`.

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
`default → $ifelse($has(@(general;admin;whisper) $chatType) $username @($name;$forename))`  
`tokens → $chatType, $forename, $surname, $username, $name`

The format used to determine the values of `$name` and `$nameRaw` in other format strings.

If `$name` is specified, it is a name that was set with [`/name`](./feature-flags.md#enablesetname).

### FormatRoll
`default → rolls a $roll on a $sides-sided die`  
`tokens → $roll, $sides`

The format used for local [`/roll`](./chat-formats.md#chatformatroll) overhead message content.

### FormatTag
`default → [$tag]$if($eq($chatType server) :&#32;<SPACE>&#32;)`  
`tokens → $chatType, $stream, $tag`

The format used when `Enable tags` is selected in the chat settings menu.
This describes the chat title that displays to the left of messages (e.g., `[Local]`).

### FormatTimestamp
`default → [$ifelse($eq($hourFormatPref 12) $h $H):$mm]`  
`tokens → $chatType, $stream, $H, $HH, $h, $hh, $m, $mm, $s, $ss, $ampm, $AMPM, $hourFormatPref`

The format used when `Enable timestamps` is selected in the chat settings menu.
