# Overhead Formats

These [options](./index.md) control the content that displays in speech bubbles that appear over a character's head.
In all of these formats, the [`$1`](../format-strings/tokens.md#1) token **must** be included.

**These formats can have an effect on chat formats.**
The original text will try to be extracted where possible, but modification of characters in these format will be reflected.
For example, reversing the overhead text will result in the message content being reversed in chat.

### OverheadFormatCard
**Default:** `<< $1 >>`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

The overhead format used for local [`/card`](./chat-formats.md#chatformatcard) messages.
If blank, `/card` messages will not display overhead.

### OverheadFormatDo
`(blank by default)`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/do`](./chat-formats.md#chatformatdo) messages.
If blank, `/do` messages will not display overhead.

### OverheadFormatDoLoud
`(blank by default)`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/doloud`](./chat-formats.md#chatformatdoloud) messages.
If blank, `/doloud` messages will not display overhead.

### OverheadFormatDoQuiet
`(blank by default)`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/doquiet`](./chat-formats.md#chatformatdoquiet) messages.
If blank, `/doquiet` messages will not display overhead.

### OverheadFormatEcho
**Default:** `(Over Radio) $1`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [echoed](./chat-formats.md#chatformatecho) messages sent on the `/faction` or `/safehouse` streams.
If blank, `/safehouse` and `/faction` messages will not be echoed.

### OverheadFormatFull
**Default:** `$prefix$1`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

The format used for the final overhead message, after all other formats have been applied.

**Tokens:**
- All tokens in [overhead context](../sandbox-options/token-contexts.md#overhead).
- `$prefix`: The prefix determined by the [`FormatOverheadPrefix`](component-formats.md#formatoverheadprefix) option.

### OverheadFormatLow
**Default:** `$1`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/low`](./chat-formats.md#chatformatlow) messages.
If blank, `/low` messages will not display overhead.

### OverheadFormatMe
**Default:** `<< $1 >>`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/me`](./chat-formats.md#chatformatme) messages.
If blank, `/me` messages will not display overhead.

### OverheadFormatMeLoud
**Default:** `<< $1 >>`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/meloud`](./chat-formats.md#chatformatmeloud) messages.
If blank, `/meloud` messages will not display overhead.

### OverheadFormatMeQuiet
**Default:** `<< $1 >>`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/mequiet`](./chat-formats.md#chatformatmequiet) messages.
If blank, `/mequiet` messages will not display overhead.

### OverheadFormatOoc
**Default:** `(( $1 ))`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`/ooc`](./chat-formats.md#chatformatooc) messages.
If blank, `/ooc` messages will not display overhead.

### OverheadFormatOther
**Default:** `$1`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of messages not covered by other options.

### OverheadFormatRoll
**Default:** `<< $1 >>`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

The overhead format used for local [`/roll`](./chat-formats.md#chatformatroll) messages.
If blank, `/roll` messages will not display overhead.

### OverheadFormatWhisper
**Default:** `$1`  
**Token Context:** [Overhead](../sandbox-options/token-contexts.md#overhead)

Defines the format used for overhead speech bubbles of [`local /whisper`](./chat-formats.md#chatformatwhisper) messages.
If blank, `/whisper` messages will not display overhead.

This does **not** apply to the vanilla whisper chat.
