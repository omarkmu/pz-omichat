# Token Contexts

Most [sandbox options](../sandbox-options/index.md) within the same category have access to the same [tokens](../format-strings/tokens.md).
This document serves as a reference for the tokens available to different types of options.

## Chat

The tokens within this context can be used by all [chat format strings](../sandbox-options/chat-formats.md), other than [processed chats](#processed-chat).

- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$buffyCrit`](../format-strings/tokens.md#buffycrit)
- [`$buffyCritRaw`](../format-strings/tokens.md#buffycritraw)
- [`$buffyRoll`](../format-strings/tokens.md#buffyroll)
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
- `$unstyled`: The original content of a message sent in narrative style.
- [`$sneakCallout`](../format-strings/tokens.md#sneakcallout)
- [`$stream`](../format-strings/tokens.md#stream)

## Overhead

The tokens within this context can be used by all [overhead format strings](../sandbox-options/overhead-formats.md).

- [`$1`](../format-strings/tokens.md#1)
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


## Processed Chat

This context contains the tokens that can be used in [`ChatFormatFull`](../sandbox-options/chat-formats.md#chatformatfull) and [`FormatChatPrefix`](../sandbox-options/component-formats.md#formatchatprefix).

- [`$admin`](../format-strings/tokens.md#admin)
- [`$author`](../format-strings/tokens.md#author)
- [`$authorRaw`](../format-strings/tokens.md#authorraw)
- [`$buffyCrit`](../format-strings/tokens.md#buffycrit)
- [`$buffyCritRaw`](../format-strings/tokens.md#buffycritraw)
- [`$buffyRoll`](../format-strings/tokens.md#buffyroll)
- `$content`: The full chat message content, after other formatting has occurred.
- [`$dialogueTag`](../format-strings/tokens.md#dialoguetag)
- [`$echo`](../format-strings/tokens.md#echo)
- [`$icon`](../format-strings/tokens.md#icon)
- [`$iconRaw`](../format-strings/tokens.md#iconraw)
- `$language`: The result of the [`FormatLanguage`](../sandbox-options/component-formats.md#formatlanguage) option.
- [`$name`](../format-strings/tokens.md#name)
- [`$nameRaw`](../format-strings/tokens.md#nameraw)
- `$tag`: The result of the [`FormatTag`](../sandbox-options/component-formats.md#formattag) option.
- `$timestamp`: The result of the [`FormatTimestamp`](../sandbox-options/component-formats.md#formattimestamp) option.
