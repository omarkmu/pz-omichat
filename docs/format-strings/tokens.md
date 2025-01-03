# Tokens

The [format strings](./index.md) that some [sandbox options](../sandbox-options/index.md) accept can include **tokens**,
which are replaced with a relevant value when they're used.
These are specified with a dollar sign followed by the name of the token.
Unlike [functions](./functions.md), tokens are case-sensitive; `$author` is not the same as `$Author`.

Tokens that are used by multiple sandbox options are documented below.
**Some tokens may take on different meanings in certain options; the documentation of an option will indicate if that is the case.**

## Error Tokens

The tokens `$error` and `$errorID` can be [set](../format-strings/functions.md#set) in some format strings to display feedback to players.
When set, the operation associated with the filter or predicate will be considered a failure.
If `errorID` is used, it will be interpreted as a string ID, whereas `error` will be displayed as given.

## `$1`

The `$1` token is frequently used for the content wrapped in invisible special characters.

This is a special token; when it is used by a format string, it **must** be included.
If it isn't, the format string will behave as if only `$1` had been specified.

The invisible characters included in this token are used to encode information for mod functionality.

## `$admin`

Only available in [chat formats](../sandbox-options/chat-formats.md).
Populated if the author of a message is an admin with the chat icon [option](../user-guide/admins.md#admin-menu) enabled.

## `$author`

The author of a message (usually a username).
This may include the name color, if one is included.

## `$authorRaw`

The same as `$author`, but does not include name colors.

## `$buffyCrit`

If the [`EnableCompatBuffyRPGSystem`](../sandbox-options/compatibility-features.md#enablecompatbuffyrpgsystem) option is enabled and the message is a critical roll, this will be formatted text to display the `[CRITICAL SUCCESS/FAILURE!]` text in green or red.

## `$buffyCritRaw`

If the [`EnableCompatBuffyRPGSystem`](../sandbox-options/compatibility-features.md#enablecompatbuffyrpgsystem) option is enabled, this will be populated with either `success` or `failure` for critical rolls.

## `$buffyRoll`

If the [`EnableCompatBuffyRPGSystem`](../sandbox-options/compatibility-features.md#enablecompatbuffyrpgsystem) option is enabled, this will be populated with the roll text (e.g., “rolled X: 5+1=6”) for roll messages.

## `$callout`

Defined if the relevant message was a 'Q' callout.
Unlike [`$sneakCallout`](#sneakcallout), this is defined for both sneak callouts and regular callouts.

## `$chatType`

The type of the chat in which a message was sent.

The value of this token will be one of:
- `general`
- `whisper` (refers to private messages, rather than [local whispers](../sandbox-options/chat-formats.md#chatformatwhisper))
- `say`
- `shout`
- `faction`
- `safehouse`
- `radio`
- `admin`
- `server`

## `$dialogueTag`

The [dialogue tag](../sandbox-options/component-formats.md#formatnarrativedialoguetag) used for a message with [narrative style](../sandbox-options/filters-predicates.md#predicateusenarrativestyle) applied.

## `$echo`

Populated if this is an [echo message](../sandbox-options/chat-formats.md#chatformatecho).

Since echo messages will only be sent over `/say` or `/low`, this is relevant only to those streams and the “full” formats.

## `$forename`

The relevant player character's forename.

## `$frequency`

The radio frequency a message was sent on.

## `$icon`

The `<IMAGE>` tag for the chat icon of a message, with a leading and trailing space.

## `$iconRaw`

The name of the icon used for [`$icon`](#icon).

## `$input`

The input that was sent to a chat or command stream.

This is available for overhead formats, but should **not** be used in place of [`$1`](#1) in the final result.
The invisible characters included in `$1` are necessary for correctly interpreting messages.

## `$language`

The translated [roleplay language](../sandbox-options/languages.md) that a message was sent in.
This will not be defined if the message was sent in the default language.

## `$languageRaw`

The untranslated [roleplay language](../sandbox-options/languages.md) that a message was sent in.
This will not be defined if the message was sent in the default language.

## `$message`

The content of a message.

## `$name`

The chat name of the relevant player. This may include the name color, if one is included.
Determined by the format specified by [`FormatName`](../sandbox-options/component-formats.md#formatname).

## `$nameRaw`

The same as [`$name`](#name), but does not include name colors.

## `$sneakCallout`

Like [`$callout`](#callout), but defined only when the message was sent from a sneak callout.

## `$stream`

The chat stream to which a message was or will be sent.

This can be extended by other mods. In the base mod, however, this will be one of:

- `general`
- `private` (vanilla whisper)
- `say`
- `shout`
- `faction`
- `safehouse`
- `radio`
- `admin`
- `server`
- `discord`
- `ooc`
- `whisper` (local whisper)
- `do`
- `doloud`
- `doquiet`
- `me`
- `meloud`
- `mequiet`
- `mewhisper`
- `card`
- `roll`

## `$surname`

The relevant player character's forename.

## `$unknownLanguage`

Equivalent to [`$language`](#language), but only populated if the language is not known by the player.

## `$username`

The relevant player's username.
