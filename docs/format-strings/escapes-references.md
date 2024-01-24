# Character Escapes & References

[Format strings](./index.md) include special characters that need to be escaped in certain contexts.
They also allow for character references, to make including uncommon characters a bit easier.

## Escapes
The characters `$@();:` can be **escaped** by preceding the character with a dollar sign.
This is useful to avoid using a function or token where you don't intend to.

For example, `$$pi()` would result in `$pi()`.


## References
While handling sandbox options, the game removes certain characters such as `«` and `»`.
The `$char` function can be used to include these characters, but format strings also accept **character references** for ease-of-use.

Both named references and numeric references are supported.
Numeric references behave similarly to the `$char` function; the character with the number specified will be used in place of the reference.

Using character references, `« $1 »` can be specified as `&#171; $1 &#187;` or `&laquo; $1 &raquo;`.

The available characters are limited to those in the [ISO-8859-1](https://www.w3schools.com/charsets/ref_html_8859.asp) character set.
