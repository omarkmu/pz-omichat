# String Customization

Some mod features allow for custom string translations, so that players can see text in their preferred languages.
These features expect strings of a certain format to be included in a separate mod.
This could be an unlisted mod used by specifically a single server, or an extension mod that adds default content for servers.

## Dialogue Tags

Custom dialogue tags can be specified for [narrative style](../sandbox-options/filters-predicates.md#predicateusenarrativestyle) using the [`FormatNarrativeDialogueTag`](../sandbox-options/component-formats.md#formatnarrativedialoguetag) option.

Two translations should be specified per custom dialogue tag: `UI_OmiChat_NarrativeTag_[Tag]` and `UI_OmiChat_UnknownLanguageNarrative_[Tag]`.

`UI_OmiChat_NarrativeTag_[Tag]` is used as the message content when the given dialogue tag is used.
It requires the `%1` substitution, which will be the message content.

`UI_OmiChat_UnknownLanguageNarrative_[Tag]` is used when a player doesn't know the [language](../sandbox-options/languages.md) used for a message with the given tag, and the latter is used in other cases.
It requires two substitutions: `%1`, the name of the speaker, and `%2`, the unknown language.

For example, if the dialogue tag `gasps` were defined, translations for `UI_OmiChat_NarrativeTag_gasps` and `UI_OmiChat_UnknownLanguageNarrative_gasps` should be specified.
Otherwise, this will default to `[Name] gasps, “[Content]”` in all languages.


## Roleplay Languages

[Roleplay languages](../sandbox-options/languages.md) allow translations for language names.
These can be defined with a `UI_OmiChat_Language_[Language]` string.
For example, `UI_OmiChat_Language_English` defines the text used for the `English` language.

If the language has a space in it, the space will be replaced with an underscore when retrieving translations.
Translations for `Haitian Creole`, for example, should be defined as `UI_OmiChat_Language_Haitian_Creole`.

If the translation is absent, the language name will be used as-is regardless of the in-game language.
Translations are provided by the mod for the following languages:

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
