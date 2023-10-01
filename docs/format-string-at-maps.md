# At-maps

**At-maps** are multimaps that can be declared and used in [format strings](./format-strings.md).
Their keys can be associated with multiple values.
When used with [functions](./format-string-functions.md#at-map-functions) that accept at-maps, the objects are used directly.

When converted to a string, at-maps use the stringified version of the first available value.
This behavior allows use of at-maps to represent logic branches in a straightforward fashion.
For example, the following expressions have equivalent results:

> `$ifelse($token $token $otherToken)`  
> `@($token:$token;1:$otherToken)`  
> `@($token;$otherToken)`

## Defining At-maps

At-maps are defined with an `@` sign and enclosed by parentheses.
Keys and values are separated by a colon, and entries are separated by a semicolon.

> `@()`  
> An empty at-map.
> Evaluates to the empty string and—like the empty string—is treated as falsy in boolean operations.

> `@(key:value)`  
> An at-map with a single key-value pair.
> Evaluates to `value`.
> If `key` is falsy or evaluates the empty string, it is not added to the at-map.
> Falsy values are possible.

> `@(value)`  
> Specifies an at-map with `value` as both the key and value.
> For example, `@(1)` is equivalent to `@(1:1)`.

> `@(A;B)`  
> `@(A;B:C)`  
> `@(A:B;C)`  
> `@(A:B;C:D)`  
> Specifies an at-map with multiple values.
> The described syntaxes can be combined as desired.

> `@($_map:value)`  
> (where `$_map` is an at-map) Specifies an at-map with all of the values of `$_map` mapped to `value`.
> For example, `@(@(A;B):value)` is equivalent to `@(A:value;B:value)`.
