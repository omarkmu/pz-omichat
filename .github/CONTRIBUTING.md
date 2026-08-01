# Contributing

Thank you for your interest in contributing to OmiChat!
This document provides a general overview of how contributing to the project works.

## Contribution types

There are a few different ways to contribute:

- Create an [issue](https://github.com/omarkmu/pz-omichat/issues/new/choose); report a bug or ask for a feature.
- Contribute [translations](#contributing-translations).
- Create a [pull request](https://github.com/omarkmu/pz-omichat/compare) after reviewing the code contribution [guidelines](#contributing-code) and making your changes in a fork.
- Ask and answer questions on Discord.

## New contributors

If you're not familiar with the project, check out the [documentation](https://omarkmu.github.io/pz-omichat).
If you're totally new to contributing to GitHub repositories, here are some resources:

- [Set up Git](https://docs.github.com/en/get-started/quickstart/set-up-git)
- [GitHub flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [About forks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks)
- [Collaborating with pull requests](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests)

## Contributing code

This section assumes you're familiar with Git and GitHub.

1. Start by creating a [fork](https://github.com/omarkmu/pz-omichat/fork).
2. Check out the fork and switch the the `dev` branch. Changes should all be based on and merged into this branch, not `main`.
3. You may want to create a new branch with `git switch -c your-branch-name`. This is optional.
4. Once you're satisfied with your changes, create a [pull request](https://github.com/omarkmu/pz-omichat/compare/dev...) with the base branch set to `dev`.

### Guidelines

These guidelines are not necessarily strictly enforced, but may come up in code review.

1. Please adhere to basic code cleanliness.
There is no linting process, but contributions should be readable.
The repository includes `.editorconfig` and `.emmyrc.json` files,
which formatters such as the one included with extensions for [EmmyLua](https://github.com/EmmyLuaLs/emmylua-analyzer-rust) can use to maintain code style.
2. One of the primary aims of this mod is to be configurable.
If you're adding a new feature, consider whether you need to add configuration to control it.
3. Make sure the correct functionality is in the right place.
The `OmiChat/Shared` API should contain functionality that should work on both client and server,
whereas the `OmiChat/Client` and `OmiChat/Server` APIs are specific to client and server, respectively.
4. Use type [annotations](https://luals.github.io/wiki/annotations).
Variables and functions should be strongly typed wherever possible, to help catch easily-avoidable problems.
You should document your functions and classes, as well.
5. Test your changes.
Ideally, you can test them on a dedicated server before creating a PR.
If that isn't possible, consider testing using a hosted server and two or more instances of the game running with the `-nosteam` flag.
Please indicate how you tested your changes in the PR.
6. Write clear commit messages. Your commit messages should:
    - Clearly, succintly describe what you did in that commit.
    If you need to provide further information, do so *after* the first line. The first line should provide a quick summary; subsequent lines may have more details.
    - Be written in present tense, imperative mood (e.g., “Add x function”, *not* “Added x function”).

## Contributing translations
OmiChat's translations are defined using [Fluent](https://projectfluent.org) translation files, rather than the game's translation system.

The `.ftl` files should be placed in the `media/ftl` directory, within a subdirectory matching the
[language tag](https://developer.mozilla.org/en-US/docs/Glossary/BCP_47_language_tag) for the language.
See the table below for examples.

The following steps can be used to contribute translations to the mod.
If you're unsure about any of the steps, feel free to ask about it on Discord (@omiyomy).

1. Create a copy of the `common/media/ftl/OmiChat/en` folder.
2. Rename the copy to one of the folder names in the table below, based on the target language.
3. Modify the strings to use your translation.
    - The files have comments that explain the purpose of variable substitutions.
    Anything that is not marked as `@param X?` (where `X` is the variable name) **must** be included in the translation.
4. Create a pull request with your translation changes; see the section on [contributing code](#contributing-code).

| Game Language       | Subdirectory |
| ------------------- | ------------ |
| English             | `en`         |
| Catalan             | `ca`         |
| Czech               | `cs`         |
| Danish              | `da`         |
| Dutch               | `nl`         |
| Finnish             | `fi`         |
| French              | `fr`         |
| German              | `de`         |
| Hungarian           | `hu`         |
| Indonesian          | `id`         |
| Italian             | `it`         |
| Japanese            | `ja`         |
| Korean              | `ko`         |
| Norwegian           | `no`         |
| Polish              | `pl`         |
| Portuguese          | `pt`         |
| Portuguese (Brazil) | `pt-BR`      |
| Romanian            | `ro`         |
| Russian             | `ru`         |
| Simplified Chinese  | `zh-Hans`    |
| Spanish             | `es`         |
| Spanish (Argentina) | `es-AR`      |
| Tagalog             | `tl`         |
| Thai                | `th`         |
| Traditional Chinese | `zh-Hant`    |
| Turkish             | `tr`         |
| Ukrainian           | `uk`         |
