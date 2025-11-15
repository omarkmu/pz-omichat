### Terms used across translations
### @do-not-translate

-command-color = <PUSHRGB:0,1,0>

-highlight-color = <PUSHRGB:0,0.5,1>

-option-color = <PUSHRGB:0.7,0.7,0.7>

# @param $text string The content to wrap in the alert color.
-alert = <PUSHRGB:1,0,0> { $text } <POPRGB>

# @param $name string The name of the command without the leading slash.
-command = <SPACE> { -command-color } /{ $name } <POPRGB> <SPACE>

# @param $name string The name of the command without the leading slash.
-command-inline = { -command-color } /{ $name } <POPRGB>{" "}

# @param $text string The content to wrap in the highlight color.
-highlight = <SPACE> { -highlight-color } { $text } <POPRGB> <SPACE>

# @param $text string The content to wrap in the highlight color.
-highlight-inline = { -highlight-color } { $text } <POPRGB>{" "}

# @param $name string The name of the option.
-option = <SPACE> { -option-color } { $name } <POPRGB> <SPACE>

# @param $name string The name of the option.
-option-inline = { -option-color } { $name } <POPRGB>{" "}
