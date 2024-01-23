# Overhead Formats

These [options](./index.md) control the content that displays in speech bubbles that appear over a character's head.

**These formats can have an effect on chat formats.**
For example, reversing the overhead text will result in the message content being reversed in chat.

### OverheadFormatCard
**Default:** `&lt; $1 &gt;` (`< $1 >`)  
**Tokens:** `$1`

The overhead format used for local [`/card`](./chat-formats.md#chatformatcard) messages.
If blank, `/card` messages will not display overhead.

### OverheadFormatDo
`(blank by default)`  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`/do`](./chat-formats.md#chatformatdo) messages.
If blank, `/do` messages will not display overhead.

### OverheadFormatDoLoud
`(blank by default)`  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`/doloud`](./chat-formats.md#chatformatdoloud) messages.
If blank, `/doloud` messages will not display overhead.

### OverheadFormatDoQuiet
`(blank by default)`  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`/doquiet`](./chat-formats.md#chatformatdoquiet) messages.
If blank, `/doquiet` messages will not display overhead.

### OverheadFormatFull
**Default:** `$set(_whisper $eq($stream whisper))$if($_whisper [Whispering)$if($languageRaw $ifelse($_whisper ( in) [In)&#32;$languageRaw)$if($any($languageRaw $_whisper) ]&#32;)$1`  
**Tokens:** `$1, $stream, $language, $languageRaw`

The format used for the final overhead message, after all other formats have been applied.

### OverheadFormatLooc
**Default:** `(( $1 ))`  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`/looc`](./chat-formats.md#chatformatlooc) messages.
If blank, `/looc` messages will not display overhead.

### OverheadFormatMe
**Default:** `&lt; $1 &gt;` (`< $1 >`)  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`/me`](./chat-formats.md#chatformatme) messages.
If blank, `/me` messages will not display overhead.

### OverheadFormatMeLoud
**Default:** `&lt; $1 &gt;` (`< $1 >`)  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`/meloud`](./chat-formats.md#chatformatmeloud) messages.
If blank, `/meloud` messages will not display overhead.

### OverheadFormatMeQuiet
**Default:** `&lt; $1 &gt;` (`< $1 >`)  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`/mequiet`](./chat-formats.md#chatformatmequiet) messages.
If blank, `/mequiet` messages will not display overhead.

### OverheadFormatRoll
**Default:** `&lt; $1 &gt;` (`< $1 >`)  
**Tokens:** `$1`

The overhead format used for local [`/roll`](./chat-formats.md#chatformatroll) messages.
If blank, `/roll` messages will not display overhead.

### OverheadFormatWhisper
**Default:** `$1`  
**Tokens:** `$1`

Defines the format used for overhead speech bubbles of [`local /whisper`](./chat-formats.md#chatformatwhisper) messages.
If blank, `/whisper` messages will not display overhead.

This does **not** apply to the vanilla whisper chat.
