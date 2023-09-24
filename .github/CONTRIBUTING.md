# Contributing

Thank you for your interest in contributing to OmiChat!
This document will provide a general overview of how contributing to the project works.

## Contribution types

There are a few different ways to contribute to the mod:

- Start a [discussion](https://github.com/omarkmu/pz-omichat/discussions), or answer others' questions.
- Create an [issue](https://github.com/omarkmu/pz-omichat/issues/new/choose); report a bug or ask for a feature.
- Contribute [translations](#contributing-translations).
- Create a [pull request](https://github.com/omarkmu/pz-omichat/compare) after reviewing the code contribution [guidelines](#contributing-code) and making your changes in a fork.

## New contributors

If you're not familiar with the project, check out the [README](../README.md). If you're totally new to contributing to GitHub repositories, here are some resources:

- [Set up Git](https://docs.github.com/en/get-started/quickstart/set-up-git)
- [GitHub flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [About forks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks)
- [Collaborating with pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests)

## Contributing code

This section assumes you're familiar with Git and GitHub. If you're not, please see the section above for [new contributors](#new-contributors).

Start by creating a [fork](https://github.com/omarkmu/pz-omichat/fork). In your fork, you may want to create a new branch with `git checkout -b your-branch-name`.

Note that changes which have a significant risk of being disruptive will be merged into the `beta` branch before being added to the mod. Once you're satisfied with your changes, create a [pull request](https://github.com/omarkmu/pz-omichat/compare).

### Guidelines

1. Please adhere to basic code cleanliness. There is no linting process, but contributions should be readable.
2. One of the primary aims of this mod is to be configurable. If you're adding a new feature, consider whether you need to add sandbox options to control it.
3. Make sure the correct functionality is in the right place. The `OmiChatShared` API should contain functionality that should work on both client and server, whereas the `OmiChatClient` and `OmiChatServer` APIs are specific to client and server, respectively.
4. Use type [annotations](https://luals.github.io/wiki/annotations/). Variables and functions should be strongly typed wherever possible, to help catch easily-avoidable problems. You should document your functions and classes, as well.
5. Test your changes. Ideally, you can test them on a dedicated server before creating a PR. If that isn't possible, please indicate that the changes were not tested in the PR.
6. Write clear commit messages. Your commit messages should:
    - Clearly, succintly describe what you did in that commit.
    - Be written in present tense, imperative mood (e.g., “Add x function”, *not* “Added x function”).
    - If you need to provide further information, do so *after* the first line. The first line should provide a quick summary; subsequent lines may have more detail.

## Contributing translations
*Based on the instructions provided [here](https://steamcommunity.com/sharedfiles/filedetails/?id=3006690572).*

To contribute translations:

1. Create a copy of the `media/lua/shared/Translate/EN` folder.
2. Rename the copy to one of the folder names in the table below, based on the translation language.
3. Rename the files inside it to match the language code; i.e., replace `EN` with the folder name.
4. Modify first line in those files to match the translation language.
For translating into Korean, for example, change `UI_EN` to `UI_KO`.
5. Modify the quoted text to your translation. Leave the quotes intact, make sure the final comma remains, and don't change anything to the left of the equals sign.
    - In translations, `%1` represents something that will be replaced when the translation is used.
    The files have comments that explain the context of these substitutions; they should always be present in translations.
6. Save the files with the encoding specified in the table below. For example, for a translation into Estonian, save with UTF-8 encoding.
7. Upload a `.zip` of the folder in a [discussion](https://github.com/omarkmu/pz-omichat/discussions/new?category=translation) post. If you know how, you can instead create a [pull request](https://github.com/omarkmu/pz-omichat/compare) with your translation changes.

| Language             | Translation Folder | Encoding  |
| -------------------- | ------------------ | --------- |
| Argentinian Spanish  | AR                 | ANSI      |
| Catalan              | CA                 | ANSI      |
| Traditional Chinese  | CH                 | UTF-8     |
| Simplified Chinese   | CN                 | UTF-8     |
| Czech                | CS                 | ANSI      |
| Danish               | DA                 | ANSI      |
| German               | DE                 | ANSI      |
| Estonian             | EE                 | UTF-8     |
| Spanish              | ES                 | ANSI      |
| Finnish              | FI                 | ANSI      |
| French               | FR                 | ANSI      |
| Hungarian            | HU                 | ANSI      |
| Indonesian           | ID                 | UTF-8     |
| Italian              | IT                 | ANSI      |
| Japanese             | JP                 | UTF-8     |
| Korean               | KO                 | UTF-16 LE |
| Dutch                | NL                 | ANSI      |
| Norwegian            | NO                 | ANSI      |
| Tagalog              | PH                 | UTF-8     |
| Polish               | PL                 | ANSI      |
| Portuguese           | PT                 | ANSI      |
| Brazilian Portuguese | PTBR               | ANSI      |
| Romanian             | RO                 | UTF-8     |
| Russian              | RU                 | Cp1251    |
| Thai                 | TH                 | UTF-8     |
| Turkish              | TR                 | ANSI      |
| Ukrainian            | UA                 | Cp1252    |
