# Limits

Numeric options that define limits for various functionality.

### CustomShoutMaxLength
`default → 30, minimum → 1, maximum → 200`

The maximum length for individual custom [shouts](./feature-flags.md#enablecustomshouts) and [sneak shouts](./feature-flags.md#enablecustomsneakshouts).

### MinimumCommandAccessLevel
`default → 16`

The minimum access level needed to execute admin commands such as `/setname`.

- Admin: 32
- Moderator: 16
- Overseer: 8
- GM: 4
- Observer: 2
- Player: 1

### MaximumCustomShouts
`default → 10, minimum → 1, maximum → 20`

The maximum number of custom [shouts](./feature-flags.md#enablecustomshouts) and [sneak shouts](./feature-flags.md#enablecustomsneakshouts) that players are allowed to define.

Note that the two maximums are separate; a value of `10` means a player can specify 10 shouts and 10 sneak shouts.
