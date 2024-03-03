# Filters & Predicates

These [options](./index.md) are used to define logic for mod functionality.

Filters are used to transform input values, whereas predicates are used to determine a yes/no value.
For predicates, any value other than the empty string is considered a “yes”.

### FilterChatInput
**Default:** `$trim($input)`

Filters messages before they're sent on a chat stream.
If this returns the empty string, the command won't be sent to the chat stream.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$input`](../format-strings/tokens#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

### FilterNarrativeStyle
**Default:** `@($sneakCallout:$input;$capitalize($input))`

Filters messages sent on a stream with [narrative style](#predicateusenarrativestyle) enabled.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$input`](../format-strings/tokens#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

**See also:**
- [`FormatNarrativeDialogueTag`](./component-formats.md#formatnarrativedialoguetag)
- [`FormatNarrativePunctuation`](./component-formats.md#formatnarrativepunctuation)

### FilterNickname
**Default:** `$sub($input 1 50)`

Filters names set by players with `/name` or `/nickname`.

The default option will limit names to 50 characters.

This format can [set](../format-strings/functions.md#set-function) `error` or `errorID` to provide feedback to the player.
If `errorID` is used, it will be interpreted as a string ID, whereas `error` will be displayed as given.

If the empty string is returned, or either error token is set, the command will fail.

**Tokens:**
- [`$input`](../format-strings/tokens#input)
- `$target`: If the name being set is the character name, `name`. Otherwise, `nickname`.

**See also:** [`EnableSetName`](./basic-features.md#enablesetname).

### PredicateAllowChatInput
**Default:** `true`

Determines whether chat input is allowed.

This format can [set](../format-strings/functions.md#set-function) `error` or `errorID` to provide feedback to the player.
If `errorID` is used, it will be interpreted as a string ID, whereas `error` will be displayed as given.
If either token is set, the predicate will be considered a failure.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$input`](../format-strings/tokens#input)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

### PredicateAllowLanguage
**Default:** `$has(@(say;shout;whisper;low;faction;safehouse) $stream)`

Determines whether [roleplay languages](./languages.md) can be used for a message.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$input`](../format-strings/tokens#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

### PredicateApplyBuff
`(blank by default)`

Determines whether messages sent on a stream will apply a buff to a player.
This is a QoL feature intended for roleplay servers.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$input`](../format-strings/tokens#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

**See also:** [`BuffCooldown`](./basic-features.md#buffcooldown)

### PredicateAttractZombies
**Default:** `$has(@(say;shout;meloud;doloud) $stream)`

Determines whether a message on a stream will attract zombies.

**Tokens:**
- [`$stream`](../format-strings/tokens.md#stream)

**See also:** [`RangeMultiplierZombies`](./ranges.md#rangemultiplierzombies).

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
- [`EnableSetNameColor`](./basic-features.md#enablesetnamecolor)
- [`EnableSpeechColorAsDefaultNameColor`](./basic-features.md#enablespeechcolorasdefaultnamecolor)

### PredicateUseNarrativeStyle
`(blank by default)`

Determines whether the narrative style is used for a message.
If narrative style is used, messages will be enclosed in quotes and prefixed with a dialogue tag depending on the stream.

For example, with the default settings and a modified predicate, a message sent with `/yell Hey` will be transformed to `shouts, "Hey!"`.
Note that the player name is not included; overhead and chat formats should include it as needed.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$input`](../format-strings/tokens#input)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

**See also:**
- [`FilterNarrativeStyle`](#filternarrativestyle)
- [`FormatNarrativeDialogueTag`](./component-formats.md#formatnarrativedialoguetag)
- [`FormatNarrativePunctuation`](./component-formats.md#formatnarrativepunctuation)
