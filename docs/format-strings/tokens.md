# Tokens

The [format strings](./index.md) that some configuration options accept can include **tokens**,
which are replaced with a relevant value when they're used.
These are specified with a dollar sign followed by the name of the token.
Like [functions](./functions.md), tokens are case-sensitive; `$author` is not the same as `$Author`.

The available tokens for a given option are documented in the in-game configuration menu.

## Error Tokens

The tokens `$error` and `$errorID` can be [set](../format-strings/functions.md#set) in some format strings to display feedback to players.
When set, the operation associated with the filter or predicate will be considered a failure.
If `errorID` is used, it will be interpreted as a string ID, whereas `error` will be displayed as given.
