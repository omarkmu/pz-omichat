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
- [`$input`](../format-strings/tokens.md#input)
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
- [`$input`](../format-strings/tokens.md#input)
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

If the empty string is returned, or either [error token](../format-strings/tokens.md#error-tokens) is set, the command will fail.

**Tokens:**
- [`$input`](../format-strings/tokens.md#input)
- `$target`: If the name being set is the character name, `name`. Otherwise, `nickname`.

**See also:** [`EnableSetName`](./basic-features.md#enablesetname).

### PredicateAllowChatInput
**Default:** `true`

Determines whether chat input is allowed.

If either [error token](../format-strings/tokens.md#error-tokens) is set, the predicate will be considered a failure.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$input`](../format-strings/tokens.md#input)
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
- [`$input`](../format-strings/tokens.md#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

### PredicateApplyBuff
`(blank by default)`

Determines whether messages sent on a stream will apply buffs to a player.
This is a QoL feature intended for roleplay servers.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$input`](../format-strings/tokens.md#input)
- [`$name`](../format-strings/tokens.md#name)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)
- [`$username`](../format-strings/tokens.md#username)

**See also:**
- [`BuffCooldown`](./basic-features.md#buffcooldown)
- [`BuffReduceBoredom`](./basic-features.md#buffreduceboredom)
- [`BuffReduceCigaretteStress`](./basic-features.md#buffreducecigarettestress)
- [`BuffReduceFatigue`](./basic-features.md#buffreducefatigue)
- [`BuffReduceHunger`](./basic-features.md#buffreducehunger)
- [`BuffReduceThirst`](./basic-features.md#buffreducethirst)
- [`BuffReduceUnhappiness`](./basic-features.md#buffreduceunhappiness)

### PredicateAttractZombies
**Default:** `$has(@(say;shout;meloud;doloud) $stream)`

Determines whether a message on a stream will attract zombies.

**Tokens:**
- [`$stream`](../format-strings/tokens.md#stream)

**See also:** [`RangeMultiplierZombies`](./ranges.md#rangemultiplierzombies).

### PredicateClearOnDeath
**Default:** `true`

Determines what information is cleared when a player dies.

For example, if this is set to `$neq($field languages)`, then [roleplay languages](./languages.md) will not be cleared when a player character dies.

**Tokens:**
- `$field`: The field to check. This will be one of `icon`, `languages`, or `nickname`.
- `$username`: The username of the player being checked.

### PredicateEnableStream
**Default:** `true`

Determines whether a stream is enabled.

**Tokens:**
- [`$stream`](../format-strings/tokens.md#stream)

### PredicateShowTypingIndicator
`(blank by default)`

Determines whether input will trigger the typing indicator.

For example, to enable typing indicators for ranged streams only, set `PredicateShowTypingIndicator` to `$isRanged`.

If [`FormatMenuName`](./component-formats.md#formatmenuname) does not resolve for the `typing` menu type, typing indicators will not display.

**Tokens:**
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$input`](../format-strings/tokens.md#input)
- `$isRanged`: Populated if the stream is a ranged stream.
- `$range`: The range of the chat stream. Not included if it's not a ranged stream.
- [`$stream`](../format-strings/tokens.md#stream)

**See also:** [`FormatTyping`](./component-formats.md#formattyping).

### PredicateTransmitOverRadio
**Default:** `$any($has(@(whisper;low) $customStream) $not($customStream))`

Determines whether a message should be transmitted over the radio.

This only controls whether messages that have already been transmitted will be visible.
For faction/safehouse echo messages, use [`ChatFormatEcho`](./chat-formats.md#chatformatecho).

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- `$customStream`: The name of the custom stream the original message was sent over, if any.
This has the same values as `$stream`, but will only be populated with custom streams.
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)

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

For example, with the default settings and a modified predicate, a message sent with `/yell Hey` will be transformed to `shouts, “Hey!”`.
Note that the player name is not included; overhead and chat formats should include it as needed.
See the [buffy preset](../sandbox-presets/index.md#buffy) for examples.

**Tokens:**
- [`$callout`](../format-strings/tokens.md#callout)
- [`$chatType`](../format-strings/tokens.md#chattype)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$input`](../format-strings/tokens.md#input)
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
