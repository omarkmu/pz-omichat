# Roleplay Languages

These [options](./index.md) are used to configure roleplay languages.

With the default settings, languages must be manually added to players by admins with [`/addlanguage`](../user-guide/admins.md#commands).
To allow players to set additional languages, the [`LanguageSlots`](#languageslots) option can be used.

### AvailableLanguages
**Default:** `English;French;Italian;German;Spanish;Danish;Dutch;Hungarian;Norwegian;Polish;Portuguese;Russian;Turkish;Japanese;Mandarin;Finnish;Korean;Thai;Ukrainian;ASL`

The roleplay languages that players can use, separated by semicolons.
Up to 32 languages can be specified.
The first language in the list will be treated as the default language player characters speak.

Translations for each language's name can be specified by defining a `UI_OmiChat_Language_[Language]` string (e.g., `UI_OmiChat_Language_English`).
If the translation is absent, the language name will be used as-is regardless of the in-game language.

The default languages have translations provided by the mod, in all languages for which the mod has translations.
In addition to the default languages, translations are included for the following languages:

- Arabic
- Bengali
- Catalan
- Cantonese
- Gujarati
- Hausa
- Hawaiian
- Hindi
- Javanese
- Latvian
- Malay
- Marathi
- Persian
- Punjabi
- Romanian
- Shanghainese
- Tagalog
- Tamil
- Telugu
- Urdu
- Vietnamese

If there's a language that you believe would make sense to include in the base mod, please create a [feature request](https://github.com/omarkmu/pz-omichat/discussions/new?category=ideas)!

### InterpretationChance
**Default:** `25`  
**Minimum:** `0`  
**Maximum:** `100`

The chance for each interpretation roll to succeed.
This is used by the `$getunknownlanguagestring` function.

### InterpretationRolls
**Default:** `2`  
**Minimum:** `0`  
**Maximum:** `100`

The number of rolls to attempt to reveal a word in a message sent with a language the player doesn't understand.
This is used by the `$getunknownlanguagestring` function.

### LanguageSlots
**Default:** `1`  
**Minimum:** `1`  
**Maximum:** `32`

The number of language slots players have by default.

Every player character will know the default language (the first language listed in [`AvailableLanguages`](#availablelanguages)) by default.
The language selection option will only display if the player can add or select a language.

With only one language slot (the default), players will not have the option to add a language. In this case, admins can add languages to a player with [`/addlanguage`](../user-guide/admins.md#commands) or set a player's available language slots with [`/setlanguageslots`](../user-guide/admins.md#commands).

### SignedLanguages
**Default:** `ASL`

The languages in [`AvailableLanguages`](#availablelanguages) that should be treated as signed languages, separated by semicolons.
If a value is included here that is not in `AvailableLanguages`, it will be ignored.
