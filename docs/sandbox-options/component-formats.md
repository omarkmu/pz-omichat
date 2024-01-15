# Component Formats

Options that define the string formats used for purposes other than overhead speech bubbles and chat messages.

### FormatAdminIcon
**Default:** `Item_Sledgehamer` [sic]  
**Tokens:** `$username`  

The format used to determine the value of `$adminIcon` in the [`FormatIcon`](#formaticon) format.

The `/iconinfo` [command](../user-guide/admins.md#commands) can be used to determine an icon name for this format.

It may also be helpful to enable the [icon picker](../sandbox-options/feature-flags.md#enableiconpicker) to look through possible icons.
**Note:** The icon names used when clicking icons in the icon picker are **not** valid inputs for this format.
However, they can be used with `/iconinfo` to determine the icon name.

### FormatCard
**Default:** `draws $card`  
**Tokens:** `$card`  

The format used for local [`/card`](./chat-formats.md#chatformatcard) overhead message content.

### FormatIcon
**Default:** `@($eq($stream card):Item_CardDeck;$eq($stream roll):Item_Dice;$has(@(say;shout;whisper;faction;safehouse;looc;general) $stream):@($adminIcon;$icon))`  
**Tokens:** `$chatType, $stream, $icon, $adminIcon`  

The format used to determine the value of `$icon` in other formats.
The value of `$icon` in this format string is the icon set with `/seticon`.

The `$adminIcon` token is only populated when the player is an admin with the relevant option enabled (see [Admin Utilities](../user-guide/admins.md#admin-menu)).
The icon used is determined by [`FormatAdminIcon`](#formatadminicon).

### FormatInfo
`(blank by default)`  
**Tokens:** `$forename, $surname, $username, $name`  

Information that can be accessed by clicking an info button on the chat.
If blank, the info button will not be visible.

### FormatMenuName
**Default:** `$ifelse($neq($menuType mini_scoreboard) $name $username &#32;[ $name ])`  
**Tokens:** `$menuType, $forename, $surname, $username, $name`  

The format used for displaying character names within in-game menus such as the trading window, medical check, and the admin mini-scoreboard.
If blank, menus will not be affected.

### FormatName
**Default:** `$ifelse($has(@(general;admin;whisper) $chatType) $username @($name;$forename))`  
**Tokens:** `$chatType, $forename, $surname, $username, $name`  

The format used to determine the values of `$name` and `$nameRaw` in other format strings.

If `$name` is specified, it is a name that was set with [`/name`](./feature-flags.md#enablesetname).

### FormatRoll
**Default:** `rolls a $roll on a $sides-sided die`  
**Tokens:** `$roll, $sides`  

The format used for local [`/roll`](./chat-formats.md#chatformatroll) overhead message content.

### FormatTag
**Default:** `[$tag]$if($eq($chatType server) :&#32;<SPACE>&#32;)`  
**Tokens:** `$chatType, $stream, $tag`  

The format used when `Enable tags` is selected in the chat settings menu.
This describes the chat title that displays to the left of messages (e.g., `[Local]`).

### FormatTimestamp
**Default:** `[$ifelse($eq($hourFormatPref 12) $h $H):$mm]`  
**Tokens:** `$chatType, $stream, $H, $HH, $h, $hh, $m, $mm, $s, $ss, $ampm, $AMPM, $hourFormatPref`  

The format used when `Enable timestamps` is selected in the chat settings menu.
