# Compatibility Features

These [options](./index.md) control compatibility patches for other mods.

All of these features have three possible values:
- `1`: Enable the compatibility patch
- `2`: Disable the compatibility patch
- `3`: Enable the compatibility patch if the mod is enabled

The third option will check for the mod ID before applying the patch.

### EnableCompatBuffyCharacterBios
**Default:** `3 - Enable if mod is enabled`

Enables the compatibility patch for [buffy's character bios](https://steamcommunity.com/sharedfiles/filedetails/?id=2755000912).

This fixes an incompatibility that otherwise causes [commands that update forenames](./basic-features.md#enablesetname) to fail.
It will also make bio update messages appear as server messages rather than `/say` messages.

### EnableCompatBuffyRPGSystem
**Default:** `2 - Disable`

Enables the compatibility patch for [buffy's tabletop RPG system](https://steamcommunity.com/sharedfiles/filedetails/?id=2728250841).

This reads messages that look like rolls from the mod and populates tokens accordingly.
If this option is enabled, the [`$buffyRoll`](../format-strings/tokens.md#buffyroll), [`$buffyCrit`](../format-strings/tokens.md#buffycrit), and [`$buffyCritRaw`](../format-strings/tokens.md#buffycritraw) tokens will be populated where appropriate.

### EnableCompatChatBubble
**Default:** `3 - Enable if mod is enabled`

Enables the compatibility patch for [Chat Bubble v0.6](https://steamcommunity.com/sharedfiles/filedetails/?id=2688676019).

This prevents chat bubble messages from showing up in chat when enabling timestamps or tags, by preventing adding them to chat at all.
Chat bubbles still function as expected with this option enabled; they just won't affect the chat window.

### EnableCompatSearchPlayers
**Default:** `3 - Enable if mod is enabled`

Enables the compatibility patch for [Search Players For Weapons](https://steamcommunity.com/sharedfiles/filedetails/?id=2873010748).

This modifies the menu option added by the mod to respect [`FormatMenuName`](../sandbox-options/component-formats.md#formatmenuname).

### EnableCompatTAD
**Default:** `3 - Enable if mod is enabled`

Enables the compatibility patch for [True Actions Act 3 - Dancing](https://steamcommunity.com/sharedfiles/filedetails/?id=2648779556).

This adds a `/dance` command that makes the player perform a random dance that they know.
It also allows for selecting particular dances by name; a list of available dance names can be found by using `/help dance` or `/dance list`.
