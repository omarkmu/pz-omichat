# Functions

Advanced users have access to various [format string](./index.md) functions.
These are specified using a dollar sign before the function name and a set of parentheses to enclose arguments (e.g., `$PI()`).
If invalid inputs are given, the convention of these functions is to return the empty string.

Functions can accept an arbitrary number of arguments, which are delimited by spaces.
These arguments may be tokens, text, or the results of other functions.
Like [tokens](./tokens.md), functions are case-sensitive.

If a function returns multiple values, it will return them as an [at-map](./at-maps.md).
Individual return values can be accessed using the `$NthValue(o n)` function.

To include a literal space or multiple words in a single argument, text within functions can be enclosed within pairs of backticks (`).
A dollar-sign can be used to escape backticks within the enclosed text.

```
$Set(_token `hello world`)$_token → hello world
$Reverse(`)(`) → ()
$Len(`$``) → 1
```

Other mods can [extend](../api/extending-format-strings.md) the list of available functions using the API.

## `$Set(token ...)` {#set}

This is a special function that can set the value of a token.
It sets the value of the token with the name `token` to [`$Concat(...)`](#string-concat) and returns the empty string.

This can be used to redefine existing tokens, or to define entirely new tokens within the string.
To avoid collisions with tokens that may be added in the future, however, custom tokens **require** an underscore prefix.

> `$Set(_value 2)$_value frog$If($GT($_value 1) s)` → `2 frogs`

## String Functions {#section-string}

### `$Byte(s i j)` {#string-byte}

Returns a list of character codes in `s`, from indices `i` (default `1`) to `j` (default `i`).

### `$Capitalize(s)` {#string-capitalize}

Converts the first non-whitespace character in `s` to its uppercase counterpart.

### `$Char(...)` {#string-char}

Returns a string made up of the characters with the integer character codes passed as arguments.

### `$Concat(...)` {#string-concat}

Combines provided arguments into one string.

### `$Concats(separator ...)` {#string-concats}

Combines provided arguments into one string, using `separator` as a separator.

### `$Contains(this other)` {#string-contains}

Returns `true` if `this` contains `other`.
Otherwise, returns the empty string.

### `$EndsWith(this other)` {#string-endswith}

Returns `true` if `this` ends with `other`.
Otherwise, returns the empty string.

### `$EscapeRichText(...)` {#string-escaperichtext}

Escapes the input for use in rich text.

### `$First(s)` {#string-first}

Returns the first character of a given string.

### `$Gsub(s pattern repl n)` {#string-gsub}

Replaces the first `n` copies of the pattern `pattern` in `s` with `repl`.
Returns the result string, the number of matches that occurred, and any match groups that were captured.
This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf-string.gsub).

### `$Index(s i default)` {#string-index}

Returns the character at index `i` in `s`, or `default` if there is no such index.

### `$Last(s)` {#string-last}

Returns the last character of a given string.

### `$Len(s)` {#string-len}

Returns the length of `s`.

### `$Lower(s)` {#string-lower}

Converts given arguments into a lowercase string.

### `$Match(s pattern init)` {#string-match}

Looks for a match of `pattern` in `s` starting from `init`.
Returns any captures from the pattern, or the entire match if none are specified.
This behaves similarly to its [Lua counterpart](https://www.lua.org/manual/5.1/manual.html#pdf-string.match).

### `$Punctuate(s punctuation chars)` {#string-punctuate}

Adds punctuation to the end of `s` if it isn't present.

If `punctuation` is provided, it will be used as the punctuation (default: `.`).

If `chars` is provided, the set of characters considered to be punctuation will be limited to the characters in this string.
By default, the characters `.,!?:/-~` are used.

`$punctuate(hi)` → `hi.`  
`$punctuate(hello !)` → `hello!`
`$punctuate("hey" . ".)` → `"hey"`

### `$Parens(...)` {#string-parens}

Returns the input wrapped in parentheses.

### `$Rep(s n)` {#string-rep}

Returns a string made up of `n` concatenated copies of `s`.

**Use with caution; large strings can take up a lot of memory.**

### `$Reverse(s)` {#string-reverse}

Reverses the given string.

### `$StartsWith(this other)` {#string-startswith}

Returns `true` if `this` starts with `other`.
Otherwise, returns the empty string.

### `$Str(...)` {#string-str}

Converts given arguments into a single string.

### `$StripColors(s)` {#string-stripcolors}

Removes chat colors defined with `<RGB>` from the given string.

### `$Sub(s i j)` {#string-sub}

Returns a substring of `s` from `i` (default `1`) to `j` (default `#s`).

### `$Trim(s)` {#string-trim}

Trims the beginning and end of a given string.

### `$TrimLeft(s)` {#string-trimleft}

Trims the beginning of a given string.

### `$TrimRight(s)` {#string-trimright}

Trims the end of a given string.

### `$Upper(s)` {#string-upper}

Converts given arguments into an uppercase string.

## Boolean Functions {#section-boolean}

### `$All(...)` {#boolean-all}

Returns the last argument if all provided arguments are not the empty string.
Otherwise, returns the empty string.

### `$Any(...)` {#boolean-any}

Returns the first provided argument that's not the empty string, or the empty string if there are none.

### `$EQ(this other)` {#boolean-eq}

Returns `true` if `this` is equivalent to `other`.
Otherwise, returns the empty string.

### `$GT(this other)` {#boolean-gt}

Returns `true` if `this` is greater than `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$GTE(this other)` {#boolean-gte}

Returns `true` if `this` is greater than or equal to `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$If(condition ...)` {#boolean-if}

Returns `$concat(...)` if `condition` is anything other than the empty string.

### `$IfElse(condition yes ...)` {#boolean-ifelse}

Returns `yes` if `condition` is anything other than the empty string.
Otherwise, returns `$Concat(...)`.

### `$LT(this other)` {#boolean-lt}

Returns `true` if `this` is less than `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$LTE(this other)` {#boolean-lte}

Returns `true` if `this` is less than or equal to `other`.
Otherwise, returns the empty string.
If both arguments are numbers, they will be compared numerically.

### `$NEQ(this other)` {#boolean-neq}

Returns `true` if `this` is not equivalent to `other`.
Otherwise, returns the empty string.

### `$Not(value)` {#boolean-not}

Returns `true` if `value` is the empty string.
Otherwise, returns the empty string.

### `$Unless(condition ...)` {#boolean-unless}

Returns `$Concat(...)` if `condition` is the empty string.

## Math Functions {#section-math}

The majority of these functions map directly to their [Lua counterparts](https://www.lua.org/manual/5.1/manual.html#5.6).

### [`$Abs(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.abs) {#math-abs}

Returns the absolute value of `x`.

### [`$Acos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.acos) {#math-acos}

Returns the arc cosine of `x` (in radians).

### `$Add(x y)` {#math-add}

Returns `x + y`.

### [`$Asin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.asin) {#math-asin}

Returns the arc sine of `x` (in radians).

### [`$Atan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan) {#math-atan}

Returns the arc tangent of `x` (in radians).

### [`$Atan2(y x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.atan2) {#math-atan2}

Returns the arc tangent of `y / x` (in radians), but uses the signs of both parameters to find the quadrant of the result.

### [`$Ceil(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ceil) {#math-ceil}

Returns the smallest integer larger than or equal to `x`.

### [`$Cos(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cos) {#math-cos}

Returns the cosine of `x` (assumed to be in radians).

### [`$Cosh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.cosh) {#math-cosh}

Returns the hyperbolic cosine of `x`.

### [`$Deg(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.deg) {#math-deg}

Returns the angle `x` (given in radians) in degrees.

### `$Div(x y)` {#math-div}

Returns `x / y`.

### [`$Exp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.exp) {#math-exp}

Returns the value `e^x`.

### [`$Floor(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.floor) {#math-floor}

Returns the largest integer smaller than or equal to `x`.

### [`$Fmod(x y)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.fmod) {#math-fmod}

Returns the remainder of the division of `x` by `y` that rounds the quotient towards zero.

### [`$Frexp(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.frexp) {#math-frexp}

Returns `m` and `e` such that `x = m2^e`, `e` is an integer, and the absolute value of `m` is in the range `[0.5, 1)` (or zero when `x` is zero).

### `$Int(x)` {#math-int}

Returns the value of `x` converted to an integer.

### `$IsNan(x)` {#math-isnan}

Returns `true` if the string value of `x` is equivalent to the string value of `NaN`.

### [`$Ldexp(m e)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.ldexp) {#math-ldexp}

Returns `m2^e` (`e` should be an integer).

### [`$Log(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log) {#math-log}

Returns the natural logarithm of `x`.

### [`$Log10(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.log10) {#math-log10}

Returns the base-10 logarithm of `x`.

### `$Max(...)` {#math-max}

Returns the maximum among its arguments.
If all arguments are numeric, they are compared as numbers.
Otherwise, they're compared as strings.

### `$Min(...)` {#math-min}

Returns the minimum among its arguments.
If all arguments are numeric, they are compared as numbers.
Otherwise, they're compared as strings.

### `$Mod(x y)` {#math-mod}

Returns `x % y`.

### [`$Modf(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.modf) {#math-modf}

Returns two numbers, the integral part of `x` and the fractional part of `x`.

### `$Mul(x y)` {#math-mul}

Returns `x * y`.

### `$Num(x)` {#math-num}

Returns the value of `x` converted to a number.

### [`$PI()`](https://www.lua.org/manual/5.1/manual.html#pdf-math.pi) {#math-pi}

Returns an approximate value of pi.

### `$Pow(x y)` {#math-pow}

Returns `x ^ y`.

### [`$Rad(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.rad) {#math-rad}

Returns the angle `x` (given in degrees) in radians.

### [`$Sin(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sin) {#math-sin}

Returns the sine of `x` (assumed to be in radians).

### [`$Sinh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sinh) {#math-sinh}

Returns the hyperbolic sine of `x`.

### `$Subtract(x y)` {#math-subtract}

Returns `x - y`.

### [`$Sqrt(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.sqrt) {#math-sqrt}

Returns the square root of `x`.

### [`$Tan(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tan) {#math-tan}

Returns the tangent of `x`.

### [`$Tanh(x)`](https://www.lua.org/manual/5.1/manual.html#pdf-math.tanh) {#math-tanh}

Returns the hyperbolic tangent of `x`.

## At-Map Functions {#section-at-map}

These functions are related to working with [at-maps](./at-maps.md).

### `$Concat(o)` {#map-concat}

Concatenates the values in the at-map.

### `$Concats(separator o)` {#map-concats}

Concatenates the values in the at-map, using `separator` as a separator.

### `$First(o)` {#map-first}

Returns the value of the first entry in the at-map `o`.

### `$Get(o key default)` {#map-get}

Returns the first value associated with `key`, or `default` if there are none.

### `$Has(o key)` {#map-has}

Returns `true` if the at-map contains the key `key`. Otherwise, returns the empty string.

### `$Index(s key default)` {#map-index}

Returns a list of entries associated with `key`, or `default` if there are none.

### `$Last(o)` {#map-last}

Returns the value of the last entry in the at-map `o`.

### `$Len(o)` {#map-len}

Returns the number of entries in the at-map.

### `$List(...)` {#map-list}

Creates an at-map with keys from `1` to `N`, where `N` is the number of provided arguments.
If a single argument is provided and it is an at-map, its values will be used.
Otherwise, the list is made up of all provided arguments.

### `$Map(funcName o ...)` {#map-map}

Maps elements of the at-map `o` onto the function `funcName`.
Additional arguments will be passed to the map function as extra arguments.

`$Concat($Map(Upper @(a;b;c)))` → `ABC`

### `$NthValue(o n)` {#map-nthvalue}

Returns the value of the `n`th entry in the at-map `o`.

### `$Unique(o)` {#map-unique}

Returns an at-map with only the unique values in the at-map `o`.

## Random Functions {#section-random}

These functions are related to generating pseudo-random values.

> [!NOTE]
> Many format strings are seeded with a constant value, to prevent changes when re-evaluating.
> To get pseudo-random values for these, use `$Randomseed()` first.

### `$Choose(...)` {#random-choose}

Selects and returns one of the inputs at random.
If given a single at-map, returns one of its values.

### `$Random(m n)` {#random-random}

Returns a pseudo-random number in `[m, n]`.
If `n` is excluded, returns a number up to `m`.
If both are excluded, returns a random float number.

### `$Randomseed(seed)` {#random-randomseed}

Seeds the randomizer with the given value.

## Other Functions {#section-other}

### `$AddTag(tag)` {#other-addtag}

Adds a tag to the `tags` token.
If there is no `tags` token or it is not an [at-map](./at-maps.md), this does nothing.

### `$ColorActions(s options)` {#other-coloractions}

Wraps actions within `s` in color tags.
Actions are delimited by a quote followed by an asterisk (`" *`).

This accepts the following options in the form of an [at-map](./at-maps.md):
- `colorTargetTag`: if this is given, it will be used as the search tag for the stream to copy the color from. By default, this uses the appropriate tag based on existing tags.
- `optionalAsterisks`: if this is true, actions will begin when any quote is encountered, instead of requiring `" *`.

### `$ColorQuotes(s options)` {#other-colorquotes}

Wraps quoted text within `s` in color tags.

This accepts the following options in the form of an [at-map](./at-maps.md):
- `colorTargetTag`: if this is given, it will be used as the search tag for the stream to copy the color from. By default, this uses the appropriate tag based on existing tags.

### `$Default()` {#other-default}

Returns the default content for a format string.
If used outside of a valid format string, this returns the empty string.

### `$DisallowSignedOverRadio(options)` {#other-disallowsignedoverradio}

Checks that a message is not being sent with a signed language.
Returns the empty string if it is.

Unless `suppressError` is passed, this also sets the [error token](./tokens.md#error-tokens) to a message that will inform the player that they cannot use a signed language over the radio.

This accepts the following options in the form of an [at-map](./at-maps.md):
- `condition`: if this is given and is not truthy, the function will return `true` without checking the language.
- `suppressError`: if this is truthy, the error token will not be set.

### `$FormatRadio(frequency)` {#other-formatradio}

Returns the default formatting for a radio message prefix.

### `$Fragmented(text)` {#other-fragmented}

Returns a partial quote representing a fragment of what a player character understood.
This used for unknown language messages.

### `$GetText(s ...)` {#other-gettext}

Returns a translation.
The first argument must be the translation name.
Subsequent arguments may be translation substitutions.

Due to a limitation of the underlying function, only up to 4 additional substitution arguments are allowed.
Arguments beyond this limit will be ignored.

### `$GetTextOrNull(s ...)` {#other-gettextornull}

Behaves similarly to `$GetText()`, but returns the empty string for unknown translations instead of the translation name.

Due to a limitation of the underlying function, only up to 4 additional substitution arguments are allowed.
Arguments beyond this limit will be ignored.

### `$HasTag(tag)` {#other-hastag}

Checks whether a tag is present in the `tags` token.

### `$IsSigned(language)` {#other-issigned}

Returns `true` if `language` is configured as a signed language.

### `$RemoveTag(tag)` {#other-removetag}

Removes a tag from the `tags` token.
If there is no `tags` token or it is not an [at-map](./at-maps.md), this does nothing.

### `$StreamCategory(stream)` {#other-streamtype}

Returns `'chat'`, `'rp'`, or `'other'` based on the type of the given stream.
If the stream is unknown, returns the empty string.
