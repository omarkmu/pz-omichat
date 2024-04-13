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

## `$set(token ...)` {#set}

This is a special function that can set the value of a token.
It sets the value of the token with the name `token` to [`$concat(...)`](#string-concat) and returns the empty string.

This can be used to redefine existing tokens, or to define entirely new tokens within the string.
To avoid collisions with tokens that may be added in the future, however, custom tokens **require** an underscore prefix.
> `$set(_value 2)$_value frog$if($gt($_value 1) s)` → `2 frogs`

## String Functions {#section-string}

### `$byte(s i j)` {#string-byte}
Returns a list of character codes in `s`, from indices `i` (default `1`) to `j` (default `i`).

### `$capitalize(s)` {#string-capitalize}
Converts the first character in `s` to its uppercase counterpart. If `s` is wrapped in invisible encoding characters (128–159 or 65535), this will capitalize the first visible character.

### `$char(...)` {#string-char}
Returns a string made up of the characters with the integer character codes passed as arguments.

### `$concat(...)` {#string-concat}
Combines provided arguments into one string.

### `$concats(separator ...)` {#string-concats}
Combines provided arguments into one string, using `separator` as a separator.

### `$contains(this other)` {#string-contains}
Returns `true` if `this` contains `other`. Otherwise, returns the empty string.

### `$endswith(this other)` {#string-endswith}
Returns `true` if `this` ends with `other`. Otherwise, returns the empty string.

### `$escaperichtext(...)` {#string-escaperichtext}
Escapes the input for use in rich text.

### `$first(s)` {#string-first}
Returns the first character of a given string.

### `$gsub(s pattern repl n)` {#string-gsub}
Replaces the first `n` copies of the pattern `pattern` in `s` with `repl`. Returns the result string, the number of matches that occurred, and any match groups that were captured. This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf).

### `$index(s i default)` {#string-index}
Returns the character at index `i` in `s`, or `default` if there is no such index.

### `$internal(s)` {#string-internal}
Returns the visible part of text wrapped in invisible encoding characters (128–159 or 65535), the invisible prefix, and the invisible suffix.

### `$last(s)` {#string-last}
Returns the last character of a given string.

### `$len(s)` {#string-len}
Returns the length of `s`.

### `$lower(s)` {#string-lower}
Converts given arguments into a lowercase string.

### `$match(s pattern init)` {#string-match}
Looks for a match of `pattern` in `s` starting from `init`. Returns any captures from the pattern, or the entire match if none are specified. This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf).

### `$punctuate(s punctuation chars)` {#string-punctuate}
Adds punctuation to the end of `s` if it isn't present.
If `s` is wrapped in invisible encoding characters (128–159 or 65535), the last visible character will be considered the end.

If `punctuation` is provided, it will be used as the punctuation (default: `.`).

If `chars` is provided, the set of characters considered to be punctuation will be limited to the characters in this string. By default, the Lua [pattern](https://www.lua.org/manual/5.1/manual.html#5.4.1) `%p` is used.

`$punctuate(hi)` → `hi.`  
`$punctuate(hello !)` → `hello!`

### `$parens(...)` {#string-parens}
Returns the input wrapped in parentheses.

### `$rep(s n)` {#string-rep}
Returns a string made up of `n` concatenated copies of `s`.

**Use with caution; large strings can take up a lot of memory.**

### `$reverse(s)` {#string-reverse}
Reverses a given string.

### `$startswith(this other)` {#string-startswith}
Returns `true` if `this` starts with `other`.
Otherwise, returns the empty string.

### `$str(s)` {#string-str}
Converts given arguments into a single string.

### `$stripcolors(s)` {#string-stripcolors}
Removes chat colors defined with `<RGB>` from the given string.

### `$sub(s i j)` {#string-sub}
Returns a substring of `s` from `i` (default `1`) to `j` (default `#s`).

### `$trim(s)` {#string-trim}
Trims the beginning and end of a given string.

### `$trimleft(s)` {#string-trimleft}
Trims the beginning of a given string.

### `$trimright(s)` {#string-trimright}
Trims the end of a given string.

### `$upper(s)` {#string-upper}
Converts given arguments into an uppercase string.


## Boolean Functions {#section-boolean}

### `$all(...)` {#boolean-all}
Returns the last argument if all provided arguments are not the empty string.
Otherwise, returns the empty string.

### `$any(...)` {#boolean-any}
Returns the first provided argument that's not the empty string, or the empty string if there are none.

### `$eq(this other)` {#boolean-eq}
Returns `true` if `this` is equivalent to `other`.
Otherwise, returns the empty string.

### `$gt(this other)` {#boolean-gt}
Returns `true` if `this` is greater than `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$gte(this other)` {#boolean-gte}
Returns `true` if `this` is greater than or equal to `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$if(condition ...)` {#boolean-if}
Returns `$concat(...)` if `condition` is anything other than the empty string.

### `$ifelse(condition yes ...)` {#boolean-ifelse}
Returns `yes` if `condition` is anything other than the empty string.
Otherwise, returns `$concat(...)`.

### `$lt(this other)` {#boolean-lt}
Returns `true` if `this` is less than `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$lte(this other)` {#boolean-lte}
Returns `true` if `this` is less than or equal to `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$neq(this other)` {#boolean-neq}
Returns `true` if `this` is not equivalent to `other`.
Otherwise, returns the empty string.

### `$not(value)` {#boolean-not}
Returns `true` if `value` is the empty string.
Otherwise, returns the empty string.

### `$unless(condition ...)` {#boolean-unless}
Returns `$concat(...)` if `condition` is the empty string.


## Math Functions {#section-math}

The majority of these functions map directly to their [Lua counterparts](https://www.lua.org/manual/5.1/manual.html#5.6).

### [`$abs(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.abs) {#math-abs}
Returns the absolute value of `x`.

### [`$acos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.acos) {#math-acos}
Returns the arc cosine of `x` (in radians).

### `$add(x y)` {#math-add}
Returns `x + y`.

### [`$asin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.asin) {#math-asin}
Returns the arc sine of `x` (in radians).

### [`$atan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan) {#math-atan}
Returns the arc tangent of `x` (in radians).

### [`$atan2(y x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan2) {#math-atan2}
Returns the arc tangent of `y / x` (in radians), but uses the signs of both parameters to find the quadrant of the result.

### [`$ceil(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ceil) {#math-ceil}
Returns the smallest integer larger than or equal to `x`.

### [`$cos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cos) {#math-cos}
Returns the cosine of `x` (assumed to be in radians).

### [`$cosh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cosh) {#math-cosh}
Returns the hyperbolic cosine of `x`.

### [`$deg(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.deg) {#math-deg}
Returns the angle `x` (given in radians) in degrees.

### `$div(x y)` {#math-div}
Returns `x / y`.

### [`$exp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.exp) {#math-exp}
Returns the value `e^x`.

### [`$floor(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.floor) {#math-floor}
Returns the largest integer smaller than or equal to `x`.

### [`$fmod(x y)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.fmod) {#math-fmod}
Returns the remainder of the division of `x` by `y` that rounds the quotient towards zero.

### [`$frexp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.frexp) {#math-frexp}
Returns `m` and `e` such that `x = m2^e`, `e` is an integer, and the absolute value of `m` is in the range `[0.5, 1)` (or zero when `x` is zero).

### `$int(x)` {#math-int}
Returns the value of `x` converted to an integer.

### `$isnan(x)` {#math-isnan}
Returns `true` if the string value of `x` is equivalent to the string value of `NaN`.

### [`$ldexp(m e)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ldexp) {#math-ldexp}
Returns `m2^e` (`e` should be an integer).

### [`$log(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log) {#math-log}
Returns the natural logarithm of `x`.

### [`$log10(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log10) {#math-log10}
Returns the base-10 logarithm of `x`.

### `$max(...)` {#math-max}
Returns the maximum among its arguments.
If all arguments are numeric, they are compared as numbers.
Otherwise, they're compared as strings.

### `$min(...)` {#math-min}
Returns the minimum among its arguments.
If all arguments are numeric, they are compared as numbers.
Otherwise, they're compared as strings.

### `$mod(x y)` {#math-mod}
Returns `x % y`.

### [`$modf(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.modf) {#math-modf}
Returns two numbers, the integral part of `x` and the fractional part of `x`.

### `$mul(x y)` {#math-mul}
Returns `x * y`.

### `$num(x)` {#math-num}
Returns the value of `x` converted to a number.

### [`$pi()`](https://www.lua.org/manual/5.1/manual.html#pdf-math.pi) {#math-pi}
Returns an approximate value of pi.

### `$pow(x y)` {#math-pow}
Returns `x ^ y`.

### [`$rad(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.rad) {#math-rad}
Returns the angle `x` (given in degrees) in radians.

### [`$sin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sin) {#math-sin}
Returns the sine of `x` (assumed to be in radians).

### [`$sinh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sinh) {#math-sinh}
Returns the hyperbolic sine of `x`.

### `$subtract(x y)` {#math-subtract}
Returns `x - y`.

### [`$sqrt(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sqrt) {#math-sqrt}
Returns the square root of `x`.

### [`$tan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tan) {#math-tan}
Returns the tangent of `x`.

### [`$tanh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tanh) {#math-tanh}
Returns the hyperbolic tangent of `x`.


## At-Map Functions {#section-at-map}

These functions are related to working with [at-maps](./at-maps.md).

### `$concat(o)` {#map-concat}
Concatenates the values in the at-map.

### `$concats(separator o)` {#map-concats}
Concatenates the values in the at-map, using `separator` as a separator.

### `$first(o)` {#map-first}
Returns the value of the first entry in the at-map `o`.

### `$get(o key default)` {#map-get}
Returns the first value associated with `key`, or `default` if there are none.

### `$has(o key)` {#map-has}
Returns `true` if the at-map contains the key `key`. Otherwise, returns the empty string.

### `$index(s key default)` {#map-index}
Returns a list of entries associated with `key`, or `default` if there are none.

### `$last(o)` {#map-last}
Returns the value of the last entry in the at-map `o`.

### `$len(o)` {#map-len}
Returns the number of entries in the at-map.

### `$list(...)` {#map-list}
Creates an at-map with keys from `1` to `N`, where `N` is the number of provided arguments.
If a single argument is provided and it is an at-map, its values will be used.
Otherwise, the list is made up of all provided arguments.

### `$map(funcName o ...)` {#map-map}
Maps elements of the at-map `o` onto the function `funcName`.
Additional arguments will be passed to the map function as extra arguments.

`$concat($map(upper @(a;b;c)))` → `ABC`

### `$nthvalue(o n)` {#map-nthvalue}
Returns the value of the `n`th entry in the at-map `o`.

### `$unique(o)` {#map-unique}
Returns an at-map with only the unique values in the at-map `o`.


## Random Functions {#section-random}

These functions are related to generating pseudo-random values.

**Note:** Predicates (other than `PredicateUseNameColor`), filters, `FormatCard`, `FormatRoll`, and all overhead chat formats are seeded with a constant value.
To get pseudo-random values for these, use `$randomseed` first.

### `$choose(...)` {#random-choose}
Selects and returns one of the inputs at random.
If given a single at-map, returns one of its values.

### `$random(m n)` {#random-random}
Returns a pseudo-random number in `[m, n]`. If `n` is excluded, returns a number up to `m`.
If both are excluded, returns a random float number.

### `$randomseed(seed)` {#random-randomseed}
Seeds the randomizer with the given value.


## Other Functions {#section-other}

### `$accesslevel()` {#other-accesslevel}
Returns the access level of player 1, as a string.

### `$colorquotes(s category)` {#other-colorquotes}
Wraps quoted text within `s` in the color category specified, or the `say` color if none is given.

### `$cooldown(n key suppressError)` {#other-cooldown}
Checks and sets a cooldown associated with `key`.
`n` is the number of seconds in the cooldown.

### `$cooldownset(key n)` {#other-cooldownset}
Sets the value of the cooldown associated with `key` to `n` seconds from now.

### `$cooldownif(condition n key suppressError)` {#other-cooldownif}
The same as `$cooldown()`, but only if `condition` is truthy.

### `$cooldownunless(condition n key suppressError)` {#other-cooldownunless}
The same as `$cooldown()`, but only if `condition` is falsy.

### `$cooldownremaining(condition key)` {#other-cooldownremaining}
Returns the number of seconds remaining on a cooldown, or the empty string if there's no such cooldown.

### `$disallowsignedoverradio(condition suppressError)` {#other-disallowsignedoverradio}
Sets the `errorID` token if `condition` is true and the message language is signed.
An error message will inform the player that they cannot use a signed language over the radio, unless `suppressError` is passed.
Returns true if the check passed.

### `$fragmented(text)` {#other-fragmented}
Gets random fragments of the words in a string, replacing other words with ellipses.

### `$fmtcard(...)` {#other-fmtcard}
Returns the input formatted with the default formatting for `/card`.

### `$fmtflip(heads)` {#other-fmtflip}
Returns the input formatted with the default formatting for `/flip`.
If `heads` is the empty string, it's treated as a tails flip.

### `$fmtradio(frequency)` {#other-fmtradio}
Returns the default formatting for a radio message prefix.

### `$fmtroll(roll sides)` {#other-fmtroll}
Returns the input formatted with the default formatting for `/roll`.

### `$fmtrp(...)` {#other-fmtrp}
Returns the default formatting for an RP emote.

### `$fmtpmfrom(name parenCount)` {#other-fmtpmfrom}
Returns the default formatting for an incoming PM prefix.
`parenCount` specifies the number of parentheses to use for wrapping.

### `$fmtpmto(name parenCount)` {#other-fmtpmto}
Returns the default formatting for an outgoing PM prefix.
`parenCount` specifies the number of parentheses to use for wrapping.

### `$gettext(s ...)` {#other-gettext}
Returns a translation.
The first argument must be the translation name.
Subsequent arguments may be translation substitutions.

Due to a limitation of the underlying function, only up to 4 additional substitution arguments are allowed.
Arguments beyond this limit will be ignored.

### `$gettextornull(s ...)` {#other-gettextornull}
Behaves similarly to `$gettext()`, but returns the empty string for unknown translations instead of the translation name.

Due to a limitation of the underlying function, only up to 4 additional substitution arguments are allowed.
Arguments beyond this limit will be ignored.

### `$getunknownlanguagestring(language stream author dialogueTag noQuoteColor)` {#other-getunknownlanguagestring}
Returns a string to use when the recipient of a message doesn't know the language used.
`author` and `dialogueTag` are optional; if supplied, they apply a narrative style to the result.

If `noQuoteColor` is supplied, quotes in [interpreted](../sandbox-options/languages.md#interpretationrolls) text won't use the `/say` color.

### `$isadmin()` {#other-isadmin}
Returns true if the current player is an admin.

### `$iscoophost()` {#other-iscoophost}
Returns true if the current player is the coop host.

### `$issigned(language)` {#other-issigned}
Returns `true` if `language` is configured as a [signed language](../sandbox-options/languages.md#signedlanguages).

### `$streamtype(stream)` {#other-streamtype}
Returns `'chat'`, `'rp'`, or `'other'` based on the type of the given stream. If the stream is unknown, returns the empty string.
