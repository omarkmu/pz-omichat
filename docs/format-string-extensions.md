# Extensions

[Format strings](./format-strings.md) can be extended by other mods.
Additional [functions](./format-string-functions.md) or overrides of existing functions can be included by calling `OmiChat.registerInterpolatorFunction`.

OmiChat does not perform error handling while performing interpolation.
Extensions should adhere to the convention of returning the empty string for invalid inputs rather than causing an error.
Return values of `nil` or `false` will be treated as the empty string.

If you think your extension should instead be included in the mod, feel free to [contribute](../.github/CONTRIBUTING.md#contributing-code)!

## Example
```lua
-- $example(hello) → hello5
local OmiChat = require 'OmiChat'
OmiChat.registerInterpolatorFunction('example', function(s)
    if not s then
        return
    end

    return s .. #s
end)
```
