# String Customization

Some mod features allow for custom string translations, so that players can see text in their preferred languages.
These features expect strings of a certain format to be included in a separate mod.
This could be an unlisted mod used by specifically a single server, or an extension mod that adds default content for servers.

These translations are not defined using the game's translation system;
see the information about [contributing translations](https://github.com/omarkmu/pz-omichat/blob/main/.github/CONTRIBUTING.md#contributing-translations) for details.

The comment `### @bundle OmiChat` must be included at the top of translation files for them to be included.

## Dialogue Tags

Custom dialogue tags can be specified for narrative style using the [`Dialogue Tag Format`](../configuration/narrative-style.md#dialoguetagformat) option.

When defining a custom dialogue tag, the string `unknown-language-[tag]` should also be defined.
This is used when the player's character doesn't speak the language used for a message with the given tag.
It must include the variables `$name` and `$language`.

A string for signed languages can also be specified with `unknown-language-signed-[tag]`.
This will be used when the language is a signed language.

For example, if the dialogue tag `mutters` were used, the strings could be defined in English as:

```ftl
### @bundle OmiChat

unknown-language-mutters = { $name } mutters something in { $language }.

unknown-language-signed-mutters = { $name } subtly signs something in { $language }.

# or, since unknown-language-signed-mutters is the same as the string for 'whispers':
unknown-language-signed-mutters = { unknown-language-signed-whispers }
```

If a string is not defined for the tag, it will default to the translation for `says` or `signs`, depending on whether the language is signed.

## Roleplay Languages

Roleplay languages allow translations for language names.
These can be defined with a `language-[name]` string.
For example, `language-english` defines the text used for the `English` language.

When retrieving translations, language names will be converted to lowercase and spaces will be rreplaced with hyphens.
Translations for `Haitian Creole`, for example, should be defined using `language-haitian-creole`.

If the translation is absent, the language name will be used as-is regardless of a player's language.
Translations are provided by the mod for the following language names:

- ASL
- Arabic
- Bengali
- Cantonese
- Catalan
- Danish
- Dutch
- English
- Finnish
- French
- German
- Gujarati
- Hausa
- Hawaiian
- Hindi
- Hungarian
- Italian
- Japanese
- Javanese
- Korean
- Latvian
- Malay
- Mandarin
- Marathi
- Norwegian
- Persian
- Polish
- Portuguese
- Punjabi
- Romanian
- Russian
- Shanghainese
- Spanish
- Tagalog
- Tamil
- Telugu
- Thai
- Turkish
- Ukrainian
- Urdu
- Vietnamese
