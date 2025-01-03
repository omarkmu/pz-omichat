# Basic Features

These [options](./index.md) are used to control basic features of the mod.  
**Note:** Custom chat streams can be disabled by clearing the contents of their relevant [chat format](./chat-formats.md).

### BuffCooldown
**Default:** `15`  
**Minimum:** `0`  
**Maximum:** `1440`

The cooldown for applying [buffs](./filters-predicates.md#predicateapplybuff), in real-time minutes.

### BuffReduceBoredom
**Default:** `0.2`  
**Minimum:** `0.0`  
**Maximum:** `1.0`

The amount that boredom will be reduced by when a [buff](./filters-predicates.md#predicateapplybuff) is applied.

### BuffReduceCigaretteStress
**Default:** `0.2`  
**Minimum:** `0.0`  
**Maximum:** `1.0`

The amount that stress from lack of smoking will be reduced by when a [buff](./filters-predicates.md#predicateapplybuff) is applied.

### BuffReduceFatigue
**Default:** `0.1`  
**Minimum:** `0.0`  
**Maximum:** `1.0`

The amount that fatigue will be reduced by when a [buff](./filters-predicates.md#predicateapplybuff) is applied.

### BuffReduceHunger
**Default:** `0.1`  
**Minimum:** `0.0`  
**Maximum:** `1.0`

The amount that hunger will be reduced by when a [buff](./filters-predicates.md#predicateapplybuff) is applied.

### BuffReduceThirst
**Default:** `0.1`  
**Minimum:** `0.0`  
**Maximum:** `1.0`

The amount that thirst will be reduced by when a [buff](./filters-predicates.md#predicateapplybuff) is applied.

### BuffReduceUnhappiness
**Default:** `0.2`  
**Minimum:** `0.0`  
**Maximum:** `1.0`

The amount that unhappiness will be reduced by when a [buff](./filters-predicates.md#predicateapplybuff) is applied.

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

### EnableAlwaysShowChat
**Default:** `false`

If enabled, players will be unable to close the chat.

### EnableCaseInsensitiveChatStreams
**Default:** `true`

If enabled, chat streams such as `/say` will be case-insensitive.
This will allow players to use `/SAY` or `/Say` for the equivalent effect.

### EnableCharacterCustomization
**Default:** `false`

If enabled, this includes a set of QoL [options](../user-guide/chat-settings.md#character-customization) in the chat settings that allow players to customize their character.
This is intended for roleplay servers.

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
- `3`: `/name` sets character's forename
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

### PatternNarrativeCustomTag
`(blank by default)`

The option used to determine a pattern for custom dialogue tags in [narrative style](./filters-predicates.md#predicateusenarrativestyle).
If blank, custom tag prefixes will be turned off.

For example, if this option is set to `^~(%l+)%s+(.+)` and the other narrative style options are configured, players can input `~inquires What's your name?` to get `Jane inquires, “What's your name?”`.

This option should be a Lua [string pattern](https://www.lua.org/pil/20.2.html) with two [capture groups](https://www.lua.org/pil/20.3.html).
If you're unsure about configuring this, start a [discussion](https://github.com/omarkmu/pz-omichat/discussions/new?category=q-a)!
