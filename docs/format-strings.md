# Format strings

Various [sandbox options](./sandbox-options.md) use a format string style designed to be flexible enough to satisfy most needs.
These format strings can make use of tokens and functions to include values and logic.

## Tokens

**Tokens** are placeholders for values that will be replaced when the format string is used.
They are specified with a dollar sign followed by the name of the token (e.g., `$author`).

For more information, see [Tokens](./format-string-tokens.md).

## Functions

**Functions** are used to include logic in format strings.

For more information, see [Functions](./format-string-functions.md).

## At-maps

**At-maps** are multimaps which can be declared and used for logic branches and lists.

For more information, see [At-maps](./format-string-at-maps.md).

## Character references

While handling sandbox options, the game removes characters that aren't within a certain range, such as `«` and `»`.
The `$char` function can be used to include these characters, but format strings also accept **character references**.
These behave similarly to the `$char` function; the character with the number specified will be used in place of the reference.
Both named references and numeric references are supported.

For example, `« $1 »` can be specified as `&#171; $1 &#187;` or `&laquo; $1 &raquo;`.

The available characters are limited to those in the [ISO-8859-1](https://www.w3schools.com/charsets/ref_html_8859.asp) character set.

## Character escapes

The characters `$@();:` can all be escaped by preceding the character with a dollar sign.
This is useful to avoid invoking a function or using a token where you don't intend to.

For example, `$$pi()` would result in `$pi()`.
