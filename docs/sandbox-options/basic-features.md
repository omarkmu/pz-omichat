# Basic Features

These [options](./index.md) are used to control basic features of the mod.  
**Note:** Custom chat streams can be disabled by clearing the contents of their relevant [chat format](./chat-formats.md).

### BuffCooldown
**Default:** `15`  
**Minimum:** `0`  
**Maximum:** `1440`

The cooldown for applying [buffs](./filters-predicates.md#predicateapplybuff), in real-time minutes.

### CardItems
**Default:** `CardDeck`

A semicolon-separated list of items players can use for the `/card` command.

The `/card` command will only be available if the player has one of the items in this list in their inventory.
If blank, the command won't require an item.

### CoinItems
`(blank by default)`

A semicolon-separated list of items players can use for the `/flip` command.

The `/flip` command will only be available if the player has one of the items in this list in their inventory.
If blank, the command won't require an item.

### DiceItems
**Default:** `Dice`

A semicolon-separated list of items players can use for the `/roll` command.

The `/roll` command will only be available if the player has one of the items in this list in their inventory.
If blank, the command won't require an item.

### CustomShoutMaxLength
**Default:** `50`  
**Minimum:** `1`  
**Maximum:** `200`

**This option is deprecated and will be removed in a future version in favor of a hardcoded value.**
**To apply length limits, use [`FilterChatInput`](./filters-predicates.md#filterchatinput).**

The maximum length for individual [custom shouts](#enablecustomshouts).

### EnableCharacterCustomization
**Default:** `false`

If enabled, this includes a QoL option in the chat settings that allows players to customize their character. This is intended for roleplay servers.

Customization options available:
- Clean blood & dirt from the character (configurable with [`EnableCleanCharacter`](#enablecleancharacter))
- Change hair color
- Grow long hair
- Grow beard

### EnableCleanCharacter
**Default:** `3 - Clean body and clothing`

Determines the behavior of the “clean blood & dirt” option.
This has no effect unless [`EnableCharacterCustomization`](#enablecharactercustomization) is turned on.

- `1`: Disable
- `2`: Clean body only
- `3`: Clean body and clothing

### EnableCustomShouts
**Default:** `true`

This allows players to specify a list of custom shouts that are used when pressing the shout key (default `Q`).
Players can configure custom shouts using an option in the [chat settings](../user-guide/chat-settings.md).

### EnableDiscordColorOption
**Default:** `3 - Respect server setting`

Determines whether the option to change the color of Discord messages will be included in the [chat settings](../user-guide/chat-settings.md).
If this is set to `3`, the `DiscordEnable` server option will be respected.

- `1`: Yes
- `2`: No
- `3`: Respect server setting

### EnableEmotes
**Default:** `true`

Allows players to use [emote](../user-guide/emote-shortcuts.md) shortcuts in the form of `.emote`.
These are enabled only in local chats.

### EnableFactionColorAsDefault
**Default:** `false`

If enabled, players' faction tag colors will be used as the default color for `/faction` messages.
This takes precedence over the [`ColorFaction`](./colors.md#colorfaction) setting.

### EnableSetName
**Default:** `2 - /name sets chat nickname`

Determines the behavior of the `/name` and `/nickname` chat commands.
**If `/name` is configured to set the character's name, the empty command cannot be used to reset it.**

- `1`: Disallow setting name
- `2`: `/name` sets chat nickname
- `3`: `/name` sets character forename
- `4`: `/name` sets character's full name
- `5`: `/name` sets character's forename, `/nickname` sets chat nickname
- `6`: `/name` sets character's full name, `/nickname` sets chat nickname

### EnableSetNameColor
**Default:** `false`

Allows players to set their name color using the chat settings menu.
Other players will be able to see chat name colors.

### EnableSetSpeechColor
**Default:** `true`

Allows players to customize the color used for overhead speech bubbles.
This affects the existing in-game option within the Multiplayer tab of the settings.

### EnableSpeechColorAsDefaultNameColor
**Default:** `true`

If enabled, players' overhead speech color will be used as their default name color.
This can be used alongside with or independently of [`EnableSetNameColor`](#enablesetnamecolor).

### MaximumCustomShouts
**Default:** `10`  
**Minimum:** `1`  
**Maximum:** `20`

The maximum number of [custom shouts](#enablecustomshouts) that players are allowed to define.

The maximums apply to regular and sneak shouts separately; a value of `10` means a player can specify 10 shouts and 10 sneak shouts.

**This option is deprecated and will be removed in a future version in favor of a hardcoded value.**

### MinimumCommandAccessLevel
**Default:** `16`

The minimum access level needed to execute [admin commands](../user-guide/admins.md#commands) such as `/setname`.

- Admin: 32
- Moderator: 16
- Overseer: 8
- GM: 4
- Observer: 2
- Player: 1
