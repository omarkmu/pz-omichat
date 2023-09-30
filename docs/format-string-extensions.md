# Extensions

Other mods may include additional [functions](./format-string-functions.md) or override existing functions by calling `OmiChat.registerInterpolatorFunction`.

Extensions should adhere to this convention of returning the empty string for invalid inputs.
Falsy return values will be treated as the empty string.

If you think your extension should instead be included in the mod, feel free to [contribute](../.github/CONTRIBUTING.md#contributing-code)!

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
