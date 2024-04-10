# Presets

This page contains [sandbox options](../sandbox-options/index.md) presets to help server operators with configuration.
The presets can be copied by clicking the button that appears the top right of the block on hover.
You can paste them directly into your server's `SandboxVars` file, or use a preset as a base and tweak it.

## Default

This preset contains the default settings of the mod.

```lua
{{#include default.txt}}
```

## Buffy

This preset is based on [buffy's roleplay chat](https://steamcommunity.com/sharedfiles/filedetails/?id=2688851521).
It's designed to loosely mimic the style of that mod through various tweaks of default settings, such as enabling [narrative style](../sandbox-options/filters-predicates.md#predicateusenarrativestyle) and changing the default colors.

Note that this is not a 1-to-1 correspondence; some things in this preset work differently than they do in buffy's mod.
For example, the value for [`EnableSetName`](../sandbox-options/basic-features.md#enablesetname) sets the chat nickname rather than the character's name.

Additionally, some features unique to this mod, such as [`PatternNarrativeCustomTag`](../sandbox-options/component-formats.md#patternnarrativecustomtag), are turned on with this preset.

```lua
{{#include buffy.txt}}
```

## Vanilla

This preset is designed to mimic the vanilla chat.
This disables many of the features of the mod, but still allows players to customize their chat colors.

Server operators can use this to start from the vanilla-style chat and turn on only the features that they're interested in.

```lua
{{#include vanilla.txt}}
```
