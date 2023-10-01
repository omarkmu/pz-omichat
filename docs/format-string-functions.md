# Functions

Advanced users have access to various [format string](./format-strings.md) functions.
These are specified using a dollar sign before the function name and a set of parentheses to enclose arguments (e.g., `$pi()`).
If invalid inputs are given, the convention of these functions is to return the empty string.

Functions can accept an arbitrary number of arguments, which are delimited by spaces.
These arguments may be tokens, text, or the results of other functions.
Unlike [tokens](./format-string-tokens.md), functions are case-insensitive.

Note that functions that return multiple values return them as an [at-map](./format-string-at-maps.md).
Individual return values can be accessed using the `$nthvalue(o n)` function.

To include a literal space or multiple words in a single argument, text within functions can be enclosed within parentheses.
Escapes will still function within parentheses, but they are only necessary to escape `)`.

> `$set(_token (hello world))$_token` → `hello world`  
> `$reverse( ($)$() )` → `()`  
> `$len(($@-sign))` → `6`

Other mods can [extend](./format-string-extensions.md) the list of available functions using the API.

## Set Function

The `$set(token ...)` function is a special function that can set the value of a token.
It sets the value of the token `token` to `$concat(...)` and returns the empty string.

This can be used to redefine existing tokens, or to define entirely new tokens within the string.
To avoid collisions with tokens that may be added in the future, however, custom tokens **require** an underscore prefix.
> `$set(_value 2)$_value frog$if($gt($_value 1) s)` → `2 frogs`

## Math Functions

The majority of these functions map directly to their [Lua counterparts](https://www.lua.org/manual/5.1/manual.html#5.6).
Functions that do not are noted as such.

- [`$abs(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.abs)
- [`$acos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.acos)
- `$add(x y)`: Returns the value of `x + y`.
- [`$asin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.asin)
- [`$atan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan)
- [`$atan2(y, x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan2)
- [`$ceil(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ceil)
- [`$cos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cos)
- [`$cosh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cosh)
- [`$deg(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.deg)
- `$div(x y)`: Returns the value of `x / y`.
- [`$exp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.exp)
- [`$floor(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.floor)
- [`$fmod(x, y)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.fmod)
- [`$frexp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.frexp)
- `$int(x)`: Returns the value of `x` converted to an integer.
- `$isnan(x)`: Returns `true` if the string value of `x` is equivalent to the string value of `NaN`.
- [`$ldexp(m, e)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ldexp)
- [`$log(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log)
- [`$log10(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log10)
- `$max(...)`: Returns the maximum among the provided arguments. If all arguments are numeric, they are compared as numbers. Otherwise, they're compared as strings.
- `$min(...)`: Returns the minimum among the provided arguments. If all arguments are numeric, they are compared as numbers. Otherwise, they're compared as strings.
- `$mod(x, y)`: Returns the value of `x % y`.
- [`$modf(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.modf)
- `$mul(x y)`: Returns the value of `x * y`.
- `$num()`: Returns the value of `x` converted to an integer.
- [`$pi()`](https://www.lua.org/manual/5.1/manual.html#pdf-math.pi)
- `$pow(x, y)`: Returns the value of `x ^ y`.
- [`$rad(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.rad)
- [`$sin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sin)
- [`$sinh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sinh)
- `$subtract(x y)`: Returns the value of `x - y`.
- [`$sqrt(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sqrt)
- [`$tan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tan)
- [`$tanh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tanh)

## String Functions

- `$str(s)`: Converts given arguments into a single string.
- `$lower(s)`: Converts given arguments into a lowercase string.
- `$upper(s)`: Converts given arguments into an uppercase string.
- `$reverse(s)`: Reverses a given string.
- `$trim(s)`: Trims the beginning and end of a given string.
- `$trimleft(s)`: Trims the beginning of a given string.
- `$trimright(s)`: Trims the end of a given string.
- `$first(s)`: Returns the first character of a given string.
- `$last(s)`: Returns the last character of a given string.
- `$contains(this other)`: Returns `true` if `this` contains `other`. Otherwise, returns the empty string.
- `$startswith(this other)`: Returns `true` if `this` starts with `other`. Otherwise, returns the empty string.
- `$endswith()`: Returns `true` if `this` ends with `other`. Otherwise, returns the empty string.
- `$concat(...)`: Combines provided arguments into one string.
- `$concats(separator ...)`: Combines provided arguments into one string, using `separator` as a separator.
- `$len(s)`: Returns the length of `s`.
- `$capitalize(s)`: Converts the first character in `s` to its uppercase counterpart.
- `$punctuate(s punctuation chars)`: Adds punctuation to the end of `s` if it isn't present.
    > If `punctuation` is provided, it will be used as the punctuation (default: `.`).
    > If `chars` is provided, the set of characters considered to be punctuation will be limited to the characters in this string.
    > By default, the Lua [pattern](https://www.lua.org/manual/5.1/manual.html#5.4.1) `%p` is used.  
    > `$punctuate(hi)` → `hi.`  
    > `$punctuate(hello !)` → `hello!`
- `$gsub(s pattern repl n)`: Replaces the first `n` copies of the pattern `pattern` in `s` with `repl`. Returns the result string, the number of matches that occurred, and any match groups that were captured. This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf-string.gsub).
- `$sub(s i j)`: Returns a substring of `s` from `i` (default `1`) to `j` (default `#s`).
- `$index(s i default)`: Returns the character at index `i` in `s`, or `default` if there is no such index.
- `$match(s pattern init)`: Looks for a match of `pattern` in `s` starting from `init`. Returns any captures from the pattern, or the entire match if none are specified. This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf-string.match).
- `$char(...)`: Returns a string made up of the characters with the integer character codes passed as arguments.
- `$byte(s i j)`: Returns a list of character codes in `s`, from indices `i` (default `1`) to `j` (default `i`).
- `$rep(s n)`: Returns a string made up of `n` concatenated copies of `s`.

## Boolean Functions

- `$not(value)`: Returns `true` if `value` is the empty string. Otherwise, returns the empty string.
- `$eq(this other)`: Returns `true` if `this` is equivalent to `other`. Otherwise, returns the empty string.
- `$neq(this other)`: Returns `true` if `this` is not equivalent to `other`. Otherwise, returns the empty string.
- `$gt(this other)`: Returns `true` if `this` is greater than `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically.
- `$gte(this other)`: Returns `true` if `this` is greater than or equal to `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically.
- `$lt(this other)`: Returns `true` if `this` is less than `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically.
- `$lte(this other)`: Returns `true` if `this` is less than or equal to `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically.
- `$any(...)`: Returns the first provided argument that's not the empty string, or the empty string if there are none.
- `$all(...)`: Returns the last argument if all provided arguments are not the empty string. Otherwise, returns the empty string.
- `$if(condition ...)`: Returns `$concat(...)` if `condition` is anything other than the empty string.
- `$unless(condition ...)`: Returns `$concat(...)` if `condition` is the empty string.
- `$ifelse(condition yes ...)`: Returns `yes` if `condition` is anything other than the empty string. Otherwise, returns `$concat(...)`.

## At-Map Functions

These functions are related to working with [at-maps](./format-string-at-maps.md).

- `$list(...)`: Creates an at-map with keys from `1` to `N`, where `N` is the number of provided arguments. If a single argument is provided and it is an at-map, its values will be used. Otherwise, the list is made up of all provided arguments.
- `$map(funcName o ...)`: Maps elements of the at-map `o` onto the function `funcName`. Additional arguments will be passed to the map function as extra arguments.
    > `$concat($map(upper @(a;b;c)))` → `ABC`
- `$len(o)`: Returns the number of entries in the at-map.
- `$concat(o)`: Concatenates the values in the at-map.
- `$concats(separator o)`: Concatenates the values in the at-map, using `separator` as a separator.
- `$nthvalue(o n)`: Returns the value of the `n`th entry in the at-map `o`.
- `$first(o)`: Returns the value of the first entry in the at-map `o`.
- `$last(o)`: Returns the value of the last entry in the at-map `o`.
- `$index(s key default)`: Returns a list of entries associated with `key`, or `default` if there are none.
- `$unique(o)`: Returns an at-map with only the unique values in the at-map `o`.


## Translation Functions

These are direct aliases for the built-in `getText` and `getTextOrNull` functions.
Due to a limitation of these functions, only up to 4 additional substitution arguments are allowed; arguments beyond this limit will be ignored.

- `$gettext(s ...)`: Returns a translation. The first argument must be the translation name. Subsequent arguments may be translation substitutions.
- `$gettextornull(s ...)`: Behaves similarly to `$gettext(...)`, but returns the empty string for unknown translations instead of the translation name.

