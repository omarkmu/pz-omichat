# Filters & Predicates

These [options](./index.md) are used to define logic for mod functionality.

Filters are used to transform input values, whereas predicates are used to determine a yes/no value.
For predicates, any value other than the empty string is considered a “yes”.

### FilterNickname
**Default:** `$sub($name 1 50)`

Filters names set by players with `/name`.

The default option will limit names to 50 characters.
If the empty string is returned, the `/name` command will fail.

**Tokens:**
- `$name`: The input that was passed to `/name`.

**See also:** [`EnableSetName`](./feature-flags.md#enablesetname).

### PredicateUseNameColor
**Default:** `$eq($stream say)`

Determines whether name colors are used for a message.

**Tokens:**
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$stream`](../format-strings/tokens.md#stream)

**See also:**
- [`EnableSetNameColor`](./feature-flags.md#enablesetnamecolor)
- [`EnableSpeechColorAsDefaultNameColor`](./feature-flags.md#enablespeechcolorasdefaultnamecolor)

### PredicateAllowLanguage
**Default:** `$has(@(say;shout;whisper) $stream)`

Determines whether [roleplay languages](./languages.md) can be used for a message.

**Tokens:**
- `$message`: The input that was passed to the stream.
- [`$stream`](../format-strings/tokens.md#stream)
