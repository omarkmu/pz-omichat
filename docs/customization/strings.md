# String Customization

Some mod features allow for custom string translations, so that players can see text in their preferred languages.
These features expect strings of a certain format to be included in a separate mod.
This could be an unlisted mod used by specifically by the server in question, or an extension mod that adds default content.

## Roleplay Languages

[Roleplay languages](../sandbox-options/languages.md) allow translations for language names.
These can be defined with a `UI_OmiChat_Language_[Language]` string.
For example, `UI_OmiChat_Language_English` defines the text used for the `English` language.

If the translation is absent, the language name will be used as-is regardless of the in-game language.
