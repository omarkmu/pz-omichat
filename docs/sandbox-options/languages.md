# Roleplay Languages

These [options](./index.md) are used to configure roleplay languages.

With the default settings, admins must add languages to players manually with the [`/addlanguage`](../user-guide/admins.md#commands) command.
To allow players to set additional languages themselves, the [`LanguageSlots`](#languageslots) option can be used.

### AddLanguageAllowlist
`(blank by default)`

Semicolon-separated list of languages that should display in the “Add” menu for players whose language [slots](#languageslots) exceed their current number of known languages.
If blank, all available languages will be available for adding.

This is recommended for servers that have a large amount of roleplay languages and allow players to add them, since showing only a subset of languages that can be manually added improves player experience.
Admins can still add languages not in this list to players using the [`/addlanguage`](../user-guide/admins.md#commands).

### AddLanguageBlocklist
`(blank by default)`

Semicolon-separated list of languages that will not display in the “Add” menu for players whose language [slots](#languageslots) exceed their current number of known languages.
If blank, no languages will be excluded unless an [allowlist](#addlanguageallowlist) is configured.

### AvailableLanguages
**Default:** `English;French;Italian;German;Spanish;Danish;Dutch;Hungarian;Norwegian;Polish;Portuguese;Russian;Turkish;Japanese;Mandarin;Finnish;Korean;Thai;Ukrainian;ASL`

The roleplay languages that players can use, separated by semicolons.
Up to 1000 languages can be specified.
The first language in the list will be treated as the default language player characters speak.

Server operators are encouraged to define translations for custom languages.
See the [language string customization](../customization/strings.md#roleplay-languages) guide for details and a list of languages for which the mod includes translations.

If there's a language that you believe would make sense to include in the base mod, please create a [feature request](https://github.com/omarkmu/pz-omichat/discussions/new?category=ideas)!

### InterpretationChance
**Default:** `25`  
**Minimum:** `0`  
**Maximum:** `100`

The chance for each interpretation roll to succeed.
This is used by the [`$getunknownlanguagestring`](../format-strings/functions.md#other-getunknownlanguagestring) function.

### InterpretationRolls
**Default:** `2`  
**Minimum:** `0`  
**Maximum:** `100`

The number of rolls to attempt to reveal a word in a message sent with a language the player doesn't understand.
This is used by the [`$getunknownlanguagestring`](../format-strings/functions.md#other-getunknownlanguagestring) function.

### LanguageSlots
**Default:** `1`  
**Minimum:** `1`  
**Maximum:** `50`

The number of language slots players have by default.

Every player character will know the default language (the first language listed in [`AvailableLanguages`](#availablelanguages)) by default.
The language selection option will only display if the player can add or select a language.

With only one language slot (the default), players will not have the option to add a language. In this case, admins can add languages to a player with [`/addlanguage`](../user-guide/admins.md#commands) or set a player's available language slots with [`/setlanguageslots`](../user-guide/admins.md#commands).

### SignedLanguages
**Default:** `ASL`

The languages in [`AvailableLanguages`](#availablelanguages) that should be treated as signed languages, separated by semicolons.
If a value is included here that is not in `AvailableLanguages`, it will be ignored.
