# Format strings

Various sandbox options use a format string style designed to be flexible enough to satisfy most needs.

All of the format strings have tokens which are replaced with relevant text when necessary.
These are specified with a dollar sign followed by the token name (e.g., `$author`).
Tokens are case-sensitive; `$author` is not the same as `$Author`.
See [Sandbox options](./sandbox-options.md) for a list of tokens used by each format string.

Format strings can also utilize [functions](./format-string-functions.md) to include logic in format strings.

The dollar sign can also be used to escape special characters.
The characters `$@();:` can all be escaped by preceding the character with a dollar sign; `$$pi()` would result in `$pi()`.
