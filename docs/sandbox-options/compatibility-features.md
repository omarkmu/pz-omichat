# Compatibility Features

These [options](./index.md) options control compatibility patches for other mods.
They have no effect if the relevant mod is not active.

### EnableCompatChatBubble
**Default:** `true`

Enables the compatibility patch for [Chat Bubble v0.6](https://steamcommunity.com/sharedfiles/filedetails/?id=2688676019).

This prevents chat bubble messages from showing up in chat when enabling timestamps or tags, by preventing adding them to chat at all.
Chat bubbles still function as expected with this option enabled; they just won't affect the chat window.

### EnableCompatSearchPlayers
**Default:** `true`

Enables the compatibility patch for [Search Players For Weapons](https://steamcommunity.com/sharedfiles/filedetails/?id=2873010748).

This modifies the menu option added by the mod to respect [`FormatMenuName`](../sandbox-options/component-formats.md#formatmenuname).

### EnableCompatTAD
**Default:** `true`

Enables the compatibility patch for [True Actions Act 3 - Dancing](https://steamcommunity.com/sharedfiles/filedetails/?id=2648779556).

This adds a `/dance` command that makes the player perform a random dance that they know.
It also allows for selecting particular dances by name; a list of available dance names can be found by using `/help dance` or `/dance list`.
