# Functions

Advanced users have access to various [format string](./index.md) functions.
These are specified using a dollar sign before the function name and a set of parentheses to enclose arguments (e.g., `$pi()`).
If invalid inputs are given, the convention of these functions is to return the empty string.

Functions can accept an arbitrary number of arguments, which are delimited by spaces.
These arguments may be tokens, text, or the results of other functions.
Unlike [tokens](./tokens.md), functions are case-insensitive.

If a function returns multiple values, it will return them as an [at-map](./at-maps.md).
Individual return values can be accessed using the `$nthvalue(o n)` function.

To include a literal space or multiple words in a single argument, text within functions can be enclosed within parentheses.
Escapes will still function within parentheses, but they are only necessary to escape `)`.

> `$set(_token (hello world))$_token` → `hello world`  
> `$reverse( ($)$() )` → `()`  
> `$len(($@-sign))` → `6`

Other mods can [extend](../api/extending-format-strings.md) the list of available functions using the API.

## `$set` Function

The `$set(token ...)` function is a special function that can set the value of a token.
It sets the value of the token `token` to `$concat(...)` and returns the empty string.

This can be used to redefine existing tokens, or to define entirely new tokens within the string.
To avoid collisions with tokens that may be added in the future, however, custom tokens **require** an underscore prefix.
> `$set(_value 2)$_value frog$if($gt($_value 1) s)` → `2 frogs`

## String Functions

| Function | Description |
| -------- | ----------- |
| `$byte(s i j)` | Returns a list of character codes in `s`, from indices `i` (default `1`) to `j` (default `i`). |
| `$capitalize(s)` | Converts the first character in `s` to its uppercase counterpart. If `s` is wrapped in invisible encoding characters (128–159 or 65535), this will capitalize the first visible character. |
| `$char(...)` | Returns a string made up of the characters with the integer character codes passed as arguments. |
| `$concat(...)` | Combines provided arguments into one string. |
| `$concats(separator ...)` | Combines provided arguments into one string, using `separator` as a separator. |
| `$contains(this other)` | Returns `true` if `this` contains `other`. Otherwise, returns the empty string. |
| `$endswith(this other)` | Returns `true` if `this` ends with `other`. Otherwise, returns the empty string. |
| `$escaperichtext(...)` | Escapes the input for use in rich text. |
| `$first(s)` | Returns the first character of a given string. |
| `$gsub(s pattern repl n)` | Replaces the first `n` copies of the pattern `pattern` in `s` with `repl`. Returns the result string, the number of matches that occurred, and any match groups that were captured. This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf). |
| `$index(s i default)` | Returns the character at index `i` in `s`, or `default` if there is no such index. |
| `$internal(s)` | Returns the visible part of text wrapped in invisible encoding characters (128–159 or 65535), the invisible prefix, and the invisible suffix. |
| `$last(s)` | Returns the last character of a given string. |
| `$len(s)` | Returns the length of `s`. |
| `$lower(s)` | Converts given arguments into a lowercase string. |
| `$match(s pattern init)` |  Looks for a match of `pattern` in `s` starting from `init`. Returns any captures from the pattern, or the entire match if none are specified. This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf). |
| `$punctuate(s punctuation chars)` | Adds punctuation to the end of `s` if it isn't present. If `s` is wrapped in invisible encoding characters (128–159 or 65535), the last visible character will be considered the end.<br><br>If `punctuation` is provided, it will be used as the punctuation (default: `.`).<br><br>If `chars` is provided, the set of characters considered to be punctuation will be limited to the characters in this string. By default, the Lua [pattern](https://www.lua.org/manual/5.1/manual.html#5.4.1) `%p` is used.<br><br>`$punctuate(hi)` → `hi.`<br>`$punctuate(hello !)` → `hello!` |
| `$rep(s n)` | Returns a string made up of `n` concatenated copies of `s`. **Use with caution; large strings can take up a lot of memory.** |
| `$reverse(s)` | Reverses a given string. |
| `$startswith(this other)` | Returns `true` if `this` starts with `other`. Otherwise, returns the empty string. |
| `$str(s)` | Converts given arguments into a single string. |
| `$stripcolors(s)` | Removes chat colors defined with `<RGB>` from the given string. |
| `$sub(s i j)` | Returns a substring of `s` from `i` (default `1`) to `j` (default `#s`). |
| `$trim(s)` | Trims the beginning and end of a given string. |
| `$trimleft(s)` | Trims the beginning of a given string. |
| `$trimright(s)` | Trims the end of a given string. |
| `$upper(s)` | Converts given arguments into an uppercase string. |

## Boolean Functions

| Function | Description |
| -------- | ----------- |
| `$all(...)` |  Returns the last argument if all provided arguments are not the empty string. Otherwise, returns the empty string. |
| `$any(...)` |  Returns the first provided argument that's not the empty string, or the empty string if there are none. |
| `$eq(this other)` |  Returns `true` if `this` is equivalent to `other`. Otherwise, returns the empty string. |
| `$gt(this other)` |  Returns `true` if `this` is greater than `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically. |
| `$gte(this other)` |  Returns `true` if `this` is greater than or equal to `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically. |
| `$if(condition ...)` |  Returns `$concat(...)` if `condition` is anything other than the empty string. |
| `$ifelse(condition yes ...)` |  Returns `yes` if `condition` is anything other than the empty string. Otherwise, returns `$concat(...)`. |
| `$issigned(language)` | Returns `true` if `language` is configured as a [signed language](../sandbox-options/languages.md#signedlanguages). |
| `$lt(this other)` |  Returns `true` if `this` is less than `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically. |
| `$lte(this other)` |  Returns `true` if `this` is less than or equal to `other`. Otherwise, returns the empty string. If both arguments are numbers, they will be compared numerically. |
| `$neq(this other)` |  Returns `true` if `this` is not equivalent to `other`. Otherwise, returns the empty string. |
| `$not(value)` |  Returns `true` if `value` is the empty string. Otherwise, returns the empty string. |
| `$unless(condition ...)` |  Returns `$concat(...)` if `condition` is the empty string. |

## Math Functions

The majority of these functions map directly to their [Lua counterparts](https://www.lua.org/manual/5.1/manual.html#5.6).

| Function | Description |
| -------- | ----------- |
| [`$abs(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.abs) | Returns the absolute value of `x`. |
| [`$acos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.acos) | Returns the arc cosine of `x` (in radians). |
| `$add(x y)` | Returns `x + y`. |
| [`$asin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.asin) | Returns the arc sine of `x` (in radians). |
| [`$atan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan) | Returns the arc tangent of `x` (in radians). |
| [`$atan2(y x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan2) | Returns the arc tangent of `y / x` (in radians), but uses the signs of both parameters to find the quadrant of the result. |
| [`$ceil(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ceil) | Returns the smallest integer larger than or equal to `x`. |
| [`$cos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cos) | Returns the cosine of `x` (assumed to be in radians). |
| [`$cosh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cosh) | Returns the hyperbolic cosine of `x`. |
| [`$deg(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.deg) | Returns the angle `x` (given in radians) in degrees. |
| `$div(x y)` | Returns `x / y`. |
| [`$exp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.exp) | Returns the value `e^x`. |
| [`$floor(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.floor) | Returns the largest integer smaller than or equal to `x`. |
| [`$fmod(x y)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.fmod) | Returns the remainder of the division of `x` by `y` that rounds the quotient towards zero. |
| [`$frexp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.frexp) | Returns `m` and `e` such that `x = m2^e`, `e` is an integer, and the absolute value of `m` is in the range `[0.5, 1)` (or zero when `x` is zero). |
| `$int(x)` | Returns the value of `x` converted to an integer. |
| `$isnan(x)` | Returns `true` if the string value of `x` is equivalent to the string value of `NaN`. |
| [`$ldexp(m e)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ldexp) | Returns `m2^e` (`e` should be an integer). |
| [`$log(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log) | Returns the natural logarithm of `x`. |
| [`$log10(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log10) | Returns the base-10 logarithm of `x`. |
| `$max(...)` | Returns the maximum among its arguments. If all arguments are numeric, they are compared as numbers. Otherwise, they're compared as strings. |
| `$min(...)` | Returns the minimum among its arguments. If all arguments are numeric, they are compared as numbers. Otherwise, they're compared as strings. |
| `$mod(x y)` | Returns `x % y`. |
| [`$modf(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.modf) | Returns two numbers, the integral part of `x` and the fractional part of `x`. |
| `$mul(x y)` | Returns `x * y`. |
| `$num(x)` | Returns the value of `x` converted to a number. |
| [`$pi()`](https://www.lua.org/manual/5.1/manual.html#pdf-math.pi) | Returns an approximate value of pi. |
| `$pow(x y)` | Returns `x ^ y`. |
| [`$rad(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.rad) | Returns the angle `x` (given in degrees) in radians. |
| [`$sin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sin) | Returns the sine of `x` (assumed to be in radians). |
| [`$sinh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sinh) | Returns the hyperbolic sine of `x`. |
| `$subtract(x y)` | Returns `x - y`. |
| [`$sqrt(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sqrt) | Returns the square root of `x`. |
| [`$tan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tan) | Returns the tangent of `x`. |
| [`$tanh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tanh) | Returns the hyperbolic tangent of `x`. |

## At-Map Functions

These functions are related to working with [at-maps](./at-maps.md).

| Function | Description |
| -------- | ----------- |
| `$concat(o)` | Concatenates the values in the at-map. |
| `$concats(separator o)` | Concatenates the values in the at-map, using `separator` as a separator. |
| `$first(o)` | Returns the value of the first entry in the at-map `o`. |
| `$get(o key default)` | Returns the first value associated with `key`, or `default` if there are none. |
| `$has(o key)` | Returns `true` if the at-map contains the key `key`. Otherwise, returns the empty string. |
| `$index(s key default)` | Returns a list of entries associated with `key`, or `default` if there are none. |
| `$last(o)` | Returns the value of the last entry in the at-map `o`. |
| `$len(o)` | Returns the number of entries in the at-map. |
| `$list(...)` | Creates an at-map with keys from `1` to `N`, where `N` is the number of provided arguments. If a single argument is provided and it is an at-map, its values will be used. Otherwise, the list is made up of all provided arguments. |
| `$map(funcName o ...)` | Maps elements of the at-map `o` onto the function `funcName`. Additional arguments will be passed to the map function as extra arguments.<br><br>`$concat($map(upper @(a;b;c)))` → `ABC` |
| `$nthvalue(o n)` | Returns the value of the `n`th entry in the at-map `o`. |
| `$unique(o)` | Returns an at-map with only the unique values in the at-map `o`. |

## Random Functions

These functions are related to generating pseudo-random values.

**Note:** Predicates (except `PredicateUseNameColor`), filters, `FormatCard`, `FormatRoll`, and all overhead chat formats are seeded with a constant value.
To get pseudo-random values for these, use `$randomseed` first.

| Function | Description |
| -------- | ----------- |
| `$choose(...)` | Selects and returns one of the inputs at random. If given a single at-map, returns one of its values. |
| `$random(m n)` | Returns a pseudo-random number in `[m, n]`. If `n` is excluded, returns a number up to `m`. If both are excluded, returns a random float number. |
| `$randomseed(seed)` | Seeds the randomizer with the given value. |

## Other Functions

**Note:** Due to a limitation of the translation functions (`getText`, `getTextOrNull`), only up to 4 additional substitution arguments are allowed; arguments beyond this limit will be ignored.

| Function | Description |
| -------- | ----------- |
| `$colorquotes(s category)` | Wraps quoted text within `s` in the color category specified, or the `say` color if none is given. |
| `$cooldown(n key suppressError)` | Checks and sets a cooldown associated with `key`. `n` is the number of seconds in the cooldown. |
| `$cooldownset(key n)` | Sets the value of the cooldown associated with `key` to `n` seconds from now. |
| `$cooldownif(condition n key suppressError)` | The same as `$cooldown()`, but only if `condition` is truthy. |
| `$cooldownunless(condition n key suppressError)` | The same as `$cooldown()`, but only if `condition` is falsy. |
| `$cooldownremaining(condition key)` | Returns the number of seconds remaining on a cooldown, or the empty string if there's no such cooldown. |
| `$disallowsignedoverradio(condition suppressError)` | Sets the `errorID` token if `condition` is true and the message language is signed. An error message will inform the player that they cannot use a signed language over the radio, unless `suppressError` is passed. Returns true if the check passed. |
| `$fragmented(text)` | Gets random fragments of the words in a string, replacing other words with ellipses. |
| `$gettext(s ...)` | Returns a translation. The first argument must be the translation name. Subsequent arguments may be translation substitutions. |
| `$gettextornull(s ...)` | Behaves similarly to `$gettext(...)`, but returns the empty string for unknown translations instead of the translation name. |
| `$getunknownlanguagestring(language stream author dialogueTag message category)` | Returns a string to use when the recipient of a message doesn't know the language used. `author` and `dialogueTag` are optional; if supplied, they apply a narrative style to the result. `message` is also optional, and will display a fragment of the message based on the relevant [options](../sandbox-options/languages.md) if provided. `category` is the color category to use for fragmented text. |
| `$isadmin()` | Returns true if the current player is an admin or coop host. |
| `$streamtype(stream)` | Returns `'chat'`, `'rp'`, or `'other'` based on the type of the given stream. If the stream is unknow, returns the empty string. |
