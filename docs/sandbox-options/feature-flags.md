# Feature Flags

These [options](./index.md) are used to enable or disable basic features of the mod.

**Note:** Custom chat streams are disabled by clearing the contents of their relevant [chat format](./chat-formats.md).

### EnableChatNameAsCharacterName
**Default:** `false`  

Uses players' names set with `/name` as their character names.
Note that this sets the forename and potentially the surname of the player character; the `$forename` and `$surname` tokens will reflect this.
**Enabling this disables resetting names with `/name`.**

See also: [`EnableSetName`](#enablesetname).

### EnableCustomShouts
**Default:** `true`  

This allows players to specify a list of custom shouts that are used when pressing the shout key (default `Q`).
Players can configure custom shouts using an option in the chat settings.

See also:
- [`EnableCustomSneakShouts`](#enablecustomsneakshouts)
- [`MaximumCustomShouts`](./limits.md#maximumcustomshouts)
- [`CustomShoutMaxLength`](./limits.md#customshoutmaxlength)

### EnableCustomSneakShouts
**Default:** `true`  

This is similar to [`EnableCustomShouts`](#enablecustomshouts), but allows specifying a list of shouts used when pressing the shout key *while sneaking*.
Length limits are controlled by the same options as `EnableCustomShouts`.

See also:
- [`MaximumCustomShouts`](./limits.md#maximumcustomshouts)
- [`CustomShoutMaxLength`](./limits.md#customshoutmaxlength)

### EnableEmotes
**Default:** `true`  

Allows players to use [emote](../user-guide/emotes.md) shortcuts in the form of `.emote`.
These are enabled only in local chats.

### EnableFactionColorAsDefault
**Default:** `false`  

If enabled, players' faction tag colors will be used as the default color for `/faction` messages.
This takes precedence over the [`ColorFaction`](./colors.md#colorfaction) setting.

### EnableIconPicker
**Default:** `false`  

Enables a button that allows players to adds icons that show up in chat to their messages.

See also: [`EnableMiscellaneousIcons`](#enablemiscellaneousicons).

### EnableMiscellaneousIcons
**Default:** `false`  

By default, only icons that are known to work in chat are included when [`EnableIconPicker`](#enableiconpicker) is `true`.
If this option is enabled, icons that are unknown will be added to a 'Miscellaneous' category of the icon picker.
This may result in icons that do not work properly, including icons from other mods.

### EnableSetName
**Default:** `true`  

Allows players to set their name in chat using `/name Name`.
Chat names can be reset by using the same command without a name, unless the [`EnableChatNameAsCharacterName`](#enablechatnameascharactername) option is enabled.

See also: [`FilterNickname`](./filters-predicates.md#filternickname).

### EnableSetNameColor
**Default:** `false`  

Allows players to set their name color using the chat settings menu.
Other players will be able to see chat name colors.

See also:
- [`EnableSetName`](#enablesetname)
- [`EnableSetSpeechColor`](#enablesetspeechcolor)
- [`EnableSpeechColorAsDefaultNameColor`](#enablespeechcolorasdefaultnamecolor)

### EnableSetSpeechColor
**Default:** `true`  

Allows players to customize the color used for overhead speech bubbles.
This affects the existing in-game option within the Multiplayer tab of the settings.

See also:
- [`EnableSetNameColor`](#enablesetnamecolor)
- [`EnableSpeechColorAsDefaultNameColor`](#enablespeechcolorasdefaultnamecolor)

### EnableSpeechColorAsDefaultNameColor
**Default:** `true`  

If enabled, players' overhead speech color will be used as their default name color.
This can be used alongside with or independently of [`EnableSetNameColor`](#enablesetnamecolor).

See also:
- [`EnableSetSpeechColor`](#enablesetspeechcolor)
