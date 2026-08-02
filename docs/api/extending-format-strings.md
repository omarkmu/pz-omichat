# Extending Format Strings

[Format strings](../format-strings/index.md) can be extended using the API.
Additional [functions](../format-strings/functions.md) or overrides of existing functions can be included by calling `OmiChat.extension.registerInterpolatorFunction`.

If you think your extension should instead be included in the mod, feel free to [contribute](https://github.com/omarkmu/pz-omichat/blob/main/.github/CONTRIBUTING.md)!

> [!WARNING]
> OmiChat does **not** perform error handling for interpolation functions.
> Extensions should adhere to the convention of returning the empty string for invalid inputs rather than causing an error.
> Return values of `nil` or `false` will also be treated as the empty string.

## Example

A simple example which appends the length of the input:

```lua
-- $example(hello) → hello5
local OmiChat = require 'OmiChat/Client'
OmiChat.extension.registerInterpolatorFunction('example', function(_interpolator, str)
    if not str then
        return
    end

    return str .. #str
end)
```
