# Chat Formats

These [options](./index.md) determine the content that displays for chat messages.

### ChatFormatAdmin
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/admin` messages in chat.

**See also:** [`ColorAdmin`](./colors.md#coloradmin).

### ChatFormatCard
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($gettext(UI_OmiChat_card_local $card)) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for local `/card` messages in chat.
This respects the range and color options of [`/me`](./chat-formats.md#chatformatme).

If blank, `/card` messages will be global instead of local and related options will be ignored.

**Tokens:**
- All tokens in [chat context](../sandbox-options/token-contexts.md#chat).
- `$card`: The translated name of the card that was drawn.

**See also:**
- [`OverheadFormatCard`](./overhead-formats.md#overheadformatcard)
- [`ColorMe`](./colors.md#colorme)
- [`RangeMe`](./ranges.md#rangeme)

### ChatFormatDiscord
**Default:** `$author: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for messages from Discord in chat.
Messages from Discord will not apply name colors.

**See also:** [`ColorDiscord`](./colors.md#colordiscord).

### ChatFormatDo
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $punctuate($capitalize($trim($message))) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/do` messages in chat.
If blank, `/do` messages will be disabled.

Allows players to use `/do` to narrate events.
With the default setting, `/do the lights flicker` will appear in chat as `« The lights flicker. »`.

**See also:**
- [`ColorDo`](./colors.md#colordo)
- [`RangeDo`](./ranges.md#rangedo)
- [`OverheadFormatDo`](./overhead-formats.md#overheadformatdo)
- [`ChatFormatMe`](#chatformatme)

### ChatFormatDoLoud
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $punctuate($capitalize($trim($message))) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/doloud` (`/dl`) messages in chat.
If blank, `/doloud` messages will be disabled.

`/doloud` behaves similarly to [`/do`](#chatformatdo), but has a larger range.

**See also:**
- [`ColorDoLoud`](./colors.md#colordoloud)
- [`RangeDoLoud`](./ranges.md#rangedoloud)
- [`OverheadFormatDoLoud`](./overhead-formats.md#overheadformatdoloud)

### ChatFormatDoQuiet
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $punctuate($capitalize($trim($message))) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/doquiet` (`/dq`) messages in chat.
If blank, `/doquiet` messages will be disabled.

`/doquiet` behaves similarly to [`/do`](#chatformatdo), but has a smaller range.

**See also:**
- [`ColorDoQuiet`](./colors.md#colordoquiet)
- [`RangeDoQuiet`](./ranges.md#rangedoquiet)
- [`OverheadFormatDoQuiet`](./overhead-formats.md#overheadformatdoquiet)

### ChatFormatEcho
**Default:** `(blank by default)`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/safehouse` and `/faction` messages echoed onto the `/say` or `/low` stream.
If blank, echoing will not occur.

**See also:** [`OverheadFormatEcho`](./overhead-formats.md#overheadformatecho)

### ChatFormatFaction
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/faction` messages in chat.

**See also:** [`ColorFaction`](./colors.md#colorfaction).

### ChatFormatFlip
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($gettext($concat(UI_OmiChat_flip_local_ @($heads:heads;tails)))) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for local `/flip` messages in chat.
This respects the range and color options of [`/me`](./chat-formats.md#chatformatme).

If blank, `/flip` messages will be global instead of local and related options will be ignored.

**Tokens:**
- All tokens in [chat context](../sandbox-options/token-contexts.md#chat).
- `$heads`: Populated if the result of the flip was heads.

### ChatFormatFull
**Default:** `$prefix$content`  
**Token Context:** [Processed Chat](../sandbox-options/token-contexts.md#processed-chat)

The format used for the final chat message, after all other formats have been applied.

**Tokens:**
- All tokens in [processed chat context](../sandbox-options/token-contexts.md#processed-chat).
- `$prefix`: The prefix determined by the [`FormatChatPrefix`](../sandbox-options/component-formats.md#formatchatprefix) option.

### ChatFormatGeneral
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/all` messages in chat.

**See also:** [`ColorGeneral`](./colors.md#colorgeneral).

### ChatFormatIncomingPrivate
**Default:** `$($gettext(UI_OmiChat_private_chat_from $name)$): <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for incoming private messages in chat.

**See also:**
- [`ColorPrivate`](./colors.md#colorprivate)
- [`ChatFormatOutgoingPrivate`](#chatformatoutgoingprivate)

### ChatFormatLow
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/low` messages in chat.

**See also:**
- [`ColorLow`](./colors.md#colorlow)
- [`RangeLow`](./ranges.md#rangelow)
- [`OverheadFormatLow`](./overhead-formats.md#overheadformatlow)

### ChatFormatMe
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/me` messages in chat.
If blank, `/me` messages will be disabled.

`/me` messages allow players to describe their actions.
With the default settings, if a player with a character named “Jane” uses `/me smiles` it will appear in chat as `« Jane smiles. »`.

**See also:**
- [`ColorMe`](./colors.md#colorme)
- [`RangeMe`](./ranges.md#rangeme)
- [`OverheadFormatMe`](./overhead-formats.md#overheadformatme)
- [`ChatFormatDo`](#chatformatdo)

### ChatFormatMeLoud
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/meloud` (`/ml`) messages in chat.
If blank, `/meloud` messages will be disabled.

`/meloud` behaves similarly to [`/me`](#chatformatme), but has a larger range.

**See also:**
- [`ColorMeLoud`](./colors.md#colormeloud)
- [`RangeMeLoud`](./ranges.md#rangemeloud)
- [`OverheadFormatMeLoud`](./overhead-formats.md#overheadformatmeloud)

### ChatFormatMeQuiet
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($trimright($message)) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/mequiet` (`/mq`) messages in chat.
If blank, `/mequiet` messages will be disabled.

`/mequiet` behaves similarly to [`/me`](#chatformatme), but has a smaller range.

**See also:**
- [`ColorMeQuiet`](./colors.md#colormequiet)
- [`RangeMeQuiet`](./ranges.md#rangemequiet)
- [`OverheadFormatMeQuiet`](./overhead-formats.md#overheadformatmequiet)

### ChatFormatOoc
**Default:** `$name: <SPACE> (( $message ))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/ooc` (local out-of-character) messages in chat.

**See also:**
- [`ColorOoc`](./colors.md#colorooc)
- [`RangeOoc`](./ranges.md#rangeooc)
- [`OverheadFormatOoc`](./overhead-formats.md#overheadformatooc)

### ChatFormatOutgoingPrivate
**Default:** `$($gettext(UI_OmiChat_private_chat_to $recipientName)$): <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for outgoing private messages in chat.

**Tokens:**
- All tokens in [chat context](../sandbox-options/token-contexts.md#chat).
- `$recipient`: The username of the recipient of the message.
- `$recipientRaw`: The username of the recipient, without name colors.
- `$recipientName`: The chat name of the recipient of the message, as determined by [`FormatName`](./component-formats.md#formatname).
- `$recipientNameRaw`: The chat name of the recipient, without name colors.

**See also:**
- [`ColorPrivate`](./colors.md#colorprivate)
- [`ChatFormatIncomingPrivate`](./chat-formats.md#chatformatincomingprivate)

### ChatFormatRadio
**Default:** `$gettext(UI_OmiChat_radio $frequency): <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for radio messages in chat.

**Tokens:**
- All tokens in [chat context](../sandbox-options/token-contexts.md#chat).
- `$customStream`: The name of the custom stream the original message was sent over, if any.
This has the same values as `$stream`, but will only be populated with custom streams.
- [`$frequency`](../format-strings/tokens.md#frequency)

**See also:** [`ColorRadio`](./colors.md#colorradio).

### ChatFormatRoll
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $punctuate($gettext(UI_OmiChat_roll_local $roll $sides)) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for local `/roll` messages in chat.
This respects the range and color options of [`/me`](./chat-formats.md#chatformatme).

If blank, `/roll` messages will be global instead of local and related options will be ignored.

**Tokens:**
- All tokens in [chat context](../sandbox-options/token-contexts.md#chat).
- `$roll`: The number that was rolled.
- `$sides`: The number of sides on the die that was rolled.

**See also:**
- [`OverheadFormatRoll`](./overhead-formats.md#overheadformatroll)
- [`ColorMe`](./colors.md#colorme)
- [`RangeMe`](./ranges.md#rangeme)

### ChatFormatSafehouse
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/safehouse` messages in chat.

**See also:** [`ColorSafehouse`](./colors.md#colorsafehouse).

### ChatFormatSay
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/say` messages in chat.

**See also:** [`ColorSay`](./colors.md#colorsay).

### ChatFormatServer
**Default:** `$message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for server messages in chat.

**See also:** [`ColorServer`](./colors.md#colorserver).

### ChatFormatUnknownLanguage
**Default:** `$gettext(UI_OmiChat_rp_emote $concats(( ) <SPACE> $name <SPACE> $getunknownlanguagestring($languageRaw $stream () () $message say) <SPACE>))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used when a player character does not speak the [language](./languages.md) of a chat message.

With the default format, this will display as `« Name says/shouts/whispers/signs something in Language. »`.

### ChatFormatUnknownLanguageRadio
**Default:** `$gettext(UI_OmiChat_radio $frequency): $gettext(UI_OmiChat_rp_emote $getunknownlanguagestring($languageRaw $stream () () $message say))`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used when a player character does not speak the [language](./languages.md) of a chat message sent over the radio.

With the default format, this will display as `Radio (100.0 MHz): « Something is said in Language. »`.

**Tokens:**
- All tokens in [chat context](../sandbox-options/token-contexts.md#chat).
- `$customStream`: The name of the custom stream the original message was sent over, if any.
This has the same values as `$stream`, but will only be populated with custom streams.
- [`$frequency`](../format-strings/tokens.md#frequency)

### ChatFormatWhisper
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for local `/whisper` messages in chat.

If populated, the vanilla `/whisper` is changed to `/pm`, and `/whisper` is modified to act as local chat with a very short range.
If blank, local whisper will be disabled and the vanilla `/whisper` will not be renamed.

**See also:**
- [`ColorWhisper`](./colors.md#colorwhisper)
- [`RangeWhisper`](./ranges.md#rangewhisper)
- [`OverheadFormatWhisper`](./overhead-formats.md#overheadformatwhisper)

### ChatFormatYell
**Default:** `$name: <SPACE> $message`  
**Token Context:** [Chat](../sandbox-options/token-contexts.md#chat)

The format used for `/yell` messages in chat.

**See also:** [`ColorYell`](./colors.md#coloryell).
