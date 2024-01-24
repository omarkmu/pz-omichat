# Limits

These numeric [options](./index.md) define limits for various mod functionality.

### CustomShoutMaxLength
**Default:** `30`  
**Minimum:** `1`  
**Maximum:** `200`

The maximum length for individual custom [shouts](./feature-flags.md#enablecustomshouts) and [sneak shouts](./feature-flags.md#enablecustomsneakshouts).

### MinimumCommandAccessLevel
**Default:** `16`

The minimum access level needed to execute admin commands such as `/setname`.

- Admin: 32
- Moderator: 16
- Overseer: 8
- GM: 4
- Observer: 2
- Player: 1

### MaximumCustomShouts
**Default:** `10`  
**Minimum:** `1`  
**Maximum:** `20`

The maximum number of custom [shouts](./feature-flags.md#enablecustomshouts) and [sneak shouts](./feature-flags.md#enablecustomsneakshouts) that players are allowed to define.

The two maximums are separate; a value of `10` means a player can specify 10 shouts and 10 sneak shouts.
