# Chat Formats

These [options](./index.md) determine the content that displays for chat messages.

### ChatFormatAdmin
**Default:** `$name: <SPACE> $message`

The format used for `/admin` messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorAdmin`](./colors.md#coloradmin).

### ChatFormatCard
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($gettext(UI_OmiChat_card_local $card)) <SPACE>))`

The format used for local `/card` messages in chat.
This respects the range and color options of [`/me`](./chat-formats.md#chatformatme).

If blank, `/card` messages will be global instead of local and related options will be ignored.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- `$card`: The translated name of the card that was drawn.
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`OverheadFormatCard`](./overhead-formats.md#overheadformatcard)
- [`ColorMe`](./colors.md#colorme)
- [`RangeMe`](./ranges.md#rangeme)

### ChatFormatDiscord
**Default:** `$author: <SPACE> $message`

The format used for messages from Discord in chat.
Messages from Discord will not apply name colors.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorDiscord`](./colors.md#colordiscord).

### ChatFormatDo
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $punctuate($capitalize($trim($message))) <SPACE>))`

The format used for `/do` messages in chat.
If blank, `/do` messages will be disabled.

Allows players to use `/do` to narrate events.
With the default setting, `/do the lights flicker` will appear in chat as `« The lights flicker. »`.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorDo`](./colors.md#colordo)
- [`RangeDo`](./ranges.md#rangedo)
- [`OverheadFormatDo`](./overhead-formats.md#overheadformatdo)
- [`ChatFormatMe`](#chatformatme)

### ChatFormatDoLoud
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $punctuate($capitalize($trim($message))) <SPACE>))`

The format used for `/doloud` (`/dl`) messages in chat.
If blank, `/doloud` messages will be disabled.

`/doloud` behaves similarly to [`/do`](#chatformatdo), but has a larger range.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorDoLoud`](./colors.md#colordoloud)
- [`RangeDoLoud`](./ranges.md#rangedoloud)
- [`OverheadFormatDoLoud`](./overhead-formats.md#overheadformatdoloud)

### ChatFormatDoQuiet
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $punctuate($capitalize($trim($message))) <SPACE>))`

The format used for `/doquiet` (`/dq`) messages in chat.
If blank, `/doquiet` messages will be disabled.

`/doquiet` behaves similarly to [`/do`](#chatformatdo), but has a smaller range.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorDoQuiet`](./colors.md#colordoquiet)
- [`RangeDoQuiet`](./ranges.md#rangedoquiet)
- [`OverheadFormatDoQuiet`](./overhead-formats.md#overheadformatdoquiet)

### ChatFormatEcho
**Default:** `(blank by default)`

The format used for `/safehouse` and `/faction` messages echoed onto the `/say` stream.
If blank, echoing will not occur.

**See also:** [`OverheadFormatEcho`](./overhead-formats.md#overheadformatecho)

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

### ChatFormatFaction
**Default:** `$name: <SPACE> $message`

The format used for `/faction` messages in chat.

**See also:** [`ColorFaction`](./colors.md#colorfaction).

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

### ChatFormatFull
**Default:** `$prefix$content`

The format used for the final chat message, after all other formats have been applied.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- `$content`: The full chat message content, after other formatting has occurred.
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- `$language`: The result of the [`FormatLanguage`](../sandbox-options/component-formats.md#formatlanguage) option.
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- `$prefix`: The prefix determined by the [`FormatChatPrefix`](../sandbox-options/component-formats.md#formatchatprefix) option.
- `$tag`: The result of the [`FormatTag`](../sandbox-options/component-formats.md#formattag) option.
- `$timestamp`: The result of the [`FormatTimestamp`](../sandbox-options/component-formats.md#formattimestamp) option.

### ChatFormatGeneral
**Default:** `$name: <SPACE> $message`

The format used for `/all` messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorGeneral`](./colors.md#colorgeneral).

### ChatFormatIncomingPrivate
**Default:** `$($gettext(UI_OmiChat_private_chat_from $name)$): <SPACE> $message`

The format used for incoming private messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorPrivate`](./colors.md#colorprivate)
- [`ChatFormatOutgoingPrivate`](#chatformatoutgoingprivate)

### ChatFormatLow
**Default:** `$name: <SPACE> $message`

The format used for `/low` messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorLow`](./colors.md#colorlow)
- [`RangeLow`](./ranges.md#rangelow)
- [`OverheadFormatLow`](./overhead-formats.md#overheadformatlow)

### ChatFormatMe
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE>))`

The format used for `/me` messages in chat.
If blank, `/me` messages will be disabled.

`/me` messages allow players to describe their actions.
With the default settings, if a player with a character named “Jane” uses `/me smiles` it will appear in chat as `« Jane smiles. »`.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorMe`](./colors.md#colorme)
- [`RangeMe`](./ranges.md#rangeme)
- [`OverheadFormatMe`](./overhead-formats.md#overheadformatme)
- [`ChatFormatDo`](#chatformatdo)

### ChatFormatMeLoud
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE>))`

The format used for `/meloud` (`/ml`) messages in chat.
If blank, `/meloud` messages will be disabled.

`/meloud` behaves similarly to [`/me`](#chatformatme), but has a larger range.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorMeLoud`](./colors.md#colormeloud)
- [`RangeMeLoud`](./ranges.md#rangemeloud)
- [`OverheadFormatMeLoud`](./overhead-formats.md#overheadformatmeloud)

### ChatFormatMeQuiet
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE>))`

The format used for `/mequiet` (`/mq`) messages in chat.
If blank, `/mequiet` messages will be disabled.

`/mequiet` behaves similarly to [`/me`](#chatformatme), but has a smaller range.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorMeQuiet`](./colors.md#colormequiet)
- [`RangeMeQuiet`](./ranges.md#rangemequiet)
- [`OverheadFormatMeQuiet`](./overhead-formats.md#overheadformatmequiet)

### ChatFormatOoc
**Default:** `$name: <SPACE> (( $message ))`

The format used for `/ooc` (local out-of-character) messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorOoc`](./colors.md#colorooc)
- [`RangeOoc`](./ranges.md#rangeooc)
- [`OverheadFormatOoc`](./overhead-formats.md#overheadformatooc)

### ChatFormatOutgoingPrivate
**Default:** `$($gettext(UI_OmiChat_private_chat_to $recipientName)$): <SPACE> $message`

The format used for outgoing private messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- `$recipient`: The username of the recipient of the message.
- `$recipientRaw`: The username of the recipient, without name colors.
- `$recipientName`: The chat name of the recipient of the message, as determined by [`FormatName`](./component-formats.md#formatname).
- `$recipientNameRaw`: The chat name of the recipient, without name colors.
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorPrivate`](./colors.md#colorprivate)
- [`ChatFormatIncomingPrivate`](./chat-formats.md#chatformatincomingprivate)

### ChatFormatRadio
**Default:** `$gettext(UI_OmiChat_radio $frequency): <SPACE> $message`

The format used for radio messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- `$customStream`: The name of the custom stream the original message was sent over, if any.
This has the same values as `$stream`, but will only be populated with custom streams.
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$frequency`](../format-strings/tokens.md#frequency)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorRadio`](./colors.md#colorradio).

### ChatFormatRoll
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($gettext(UI_OmiChat_roll_local $roll $sides)) <SPACE>))`

The format used for local `/roll` messages in chat.
This respects the range and color options of [`/me`](./chat-formats.md#chatformatme).

If blank, `/roll` messages will be global instead of local and related options will be ignored.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- `$roll`: The number that was rolled.
- `$sides`: The number of sides on the die that was rolled.
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`OverheadFormatRoll`](./overhead-formats.md#overheadformatroll)
- [`ColorMe`](./colors.md#colorme)
- [`RangeMe`](./ranges.md#rangeme)

### ChatFormatSafehouse
**Default:** `$name: <SPACE> $message`

The format used for `/safehouse` messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorSafehouse`](./colors.md#colorsafehouse).

### ChatFormatSay
**Default:** `$name: <SPACE> $message`

The format used for `/say` messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorSay`](./colors.md#colorsay).

### ChatFormatServer
**Default:** `$message`

The format used for server messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorServer`](./colors.md#colorserver).

### ChatFormatUnknownLanguage
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $getunknownlanguagestring($languageRaw $stream) <SPACE>))`

The format used when a player character does not speak the [language](./languages.md) of a chat message.

With the default format, this will display as `« Name says/shouts/whispers/signs something in Language. »`.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)

### ChatFormatUnknownLanguageRadio
**Default:** `$gettext(UI_OmiChat_radio $frequency): $gettext(UI_OmiChat_rp_emote $getunknownlanguagestring($languageRaw $stream))`

The format used when a player character does not speak the [language](./languages.md) of a chat message sent over the radio.

With the default format, this will display as `Radio (100.0 MHz): « Something is said in Language. »`.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- `$customStream`: The name of the custom stream the original message was sent over, if any.
This has the same values as `$stream`, but will only be populated with custom streams.
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$frequency`](../format-strings/tokens.md#frequency)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)

### ChatFormatWhisper
**Default:** `$name: <SPACE> $message`

The format used for local `/whisper` messages in chat.

If populated, the vanilla `/whisper` is changed to `/pm`, and `/whisper` is modified to act as local chat with a very short range.
If blank, local whisper will be disabled and the vanilla `/whisper` will not be renamed.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:**
- [`ColorWhisper`](./colors.md#colorwhisper)
- [`RangeWhisper`](./ranges.md#rangewhisper)
- [`OverheadFormatWhisper`](./overhead-formats.md#overheadformatwhisper)

### ChatFormatYell
**Default:** `$name: <SPACE> $message`

The format used for `/yell` messages in chat.

**Tokens:**
- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$callout`](../format-strings/tokens.md#callout)
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$language`](../format-strings/tokens.md#language)
- [`$languageRaw`](../format-strings/tokens.md#languageraw)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- [`$message`](../format-strings/tokens.md#message)
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)

**See also:** [`ColorYell`](./colors.md#coloryell).
