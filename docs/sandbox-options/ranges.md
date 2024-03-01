# Chat Ranges

These [options](./index.md) define distance maximums for chat messages.

### RangeCallout
**Default:** `60`  
**Minimum:** `1`  
**Maximum:** `60`

The maximum distance for a 'Q' callout to be heard by players.

### RangeCalloutZombies
**Default:** `30`  
**Minimum:** `1`  
**Maximum:** `60`

The maximum distance for a 'Q' callout to attract zombies.

### RangeDo
**Default:** `30`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for [`/do`](./chat-formats.md#chatformatdo) messages to be visible.

### RangeDoLoud
**Default:** `60`  
**Minimum:** `1`  
**Maximum:** `60`

The maximum distance between players for [`/doloud`](./chat-formats.md#chatformatdoloud) messages to be visible.

### RangeDoQuiet
**Default:** `3`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for [`/doquiet`](./chat-formats.md#chatformatdoquiet) messages to be visible.

### RangeLow
**Default:** `5`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for [`/low`](./chat-formats.md#chatformatlow) messages to be visible.

### RangeMe
**Default:** `30`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for [`/me`](./chat-formats.md#chatformatme) messages to be visible.

### RangeMeLoud
**Default:** `60`  
**Minimum:** `1`  
**Maximum:** `60`

The maximum distance between players for [`/meloud`](./chat-formats.md#chatformatmeloud) messages to be visible.

### RangeMeQuiet
**Default:** `3`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for [`/mequiet`](./chat-formats.md#chatformatmequiet) messages to be visible.

### RangeMultiplierZombies
**Default:** `0.0`  
**Minimum:** `0.0`  
**Maximum:** `10.0`

The multiplier that will be applied to chat ranges to determine the zombie attraction range.
If this is set to zero, chat messages (other than callouts) will not attract zombies.

### RangeOoc
**Default:** `30`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for [`/ooc`](./chat-formats.md#chatformatooc) messages to be visible.

### RangeSay
**Default:** `30`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for `/say` messages to be visible.

### RangeSneakCallout
**Default:** `6`  
**Minimum:** `1`  
**Maximum:** `60`

The maximum distance for a 'Q' callout performed while sneaking to be heard by players.

### RangeSneakCalloutZombies
**Default:** `6`  
**Minimum:** `1`  
**Maximum:** `60`

The maximum distance for a 'Q' callout performed while sneaking to attract zombies.

### RangeVertical
**Default:** `@($sneakCallout:1;$index(@(@(shout;meloud;doloud):3;@(whisper;low;mequiet;doquiet):1) $stream 2))`  
**Minimum:** `1`  
**Maximum:** `32`

The maximum Y distance between players for chat messages to be visible.

This option can specify a [format string](../format-strings/index.md) to control the range per stream.
If a number is not returned, messages will not take vertical range into account.

The default option specifies a range of three floors for loud streams, one floor for quiet streams, and two floors otherwise.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)

### RangeWhisper
**Default:** `2`  
**Minimum:** `1`  
**Maximum:** `30`

The maximum distance between players for local [`/whisper`](./chat-formats.md#chatformatwhisper) messages to be visible.

This does **not** apply to the vanilla whisper chat.

### RangeYell
**Default:** `60`  
**Minimum:** `1`  
**Maximum:** `60`

The maximum distance between players for `/yell` messages to be visible.
