# Roleplay Languages

Options that are used to configure roleplay languages.

With the default settings, languages must be manually added to players by admins.
To allow players to set additional languages, the [`LanguageSlots`](#languageslots) option can be used.

### AvailableLanguages
**Default:** `English;French;Italian;German;Spanish;Danish;Dutch;Hungarian;Norwegian;Polish;Portuguese;Russian;Turkish;Japanese;Mandarin;Finnish;Korean;Thai;Ukrainian;ASL`  

The roleplay languages that players can use, separated by semicolons.
The default values are based on the game's available languages.

Up to 32 languages can be specified. The first language in the list will be treated as the default language player characters speak.

Translations for each language's name can be specified by defining a `UI_OmiChat_Language_[Language]` string (e.g., `UI_OmiChat_Language_English`). If the translation is absent, the language name will be used as-is regardless of the in-game language. All of the default languages have translated provided by the mod.

### LanguageSlots
**Default:** `1`  
**Minimum:** `1`  
**Maximum:** `32`  

The number of language slots players have by default.

Every player will know the default language (the first language listed in [`AvailableLanguages`](#availablelanguages)) by default.
With only one language slot, admins must add additional languages to players manually; the language selection option will only display if the player can add or select a language.

### SignedLanguages
**Default:** `ASL`  

The languages in [`AvailableLanguages`](#availablelanguages) that should be treated as signed languages, separated by semicolons.
If a value is included here that is not in `AvailableLanguages`, it will be ignored.
