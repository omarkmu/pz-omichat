# Filters & Predicates

Options that are used to define logic for mod functionality.

Filters are used to transform input values, whereas predicates are used to determine a yes/no value.
For predicates, any value other than the empty string is considered a “yes”.

### FilterNickname
**Default:** `$sub($name 1 50)`  
**Tokens:** `$name`  

Transforms names set by players with `/name`.
The default option will limit names to 50 characters.

If the empty string is returned, the `/name` command will fail.

See also: [`EnableSetName`](./feature-flags.md#enablesetname).

### PredicateUseNameColor
**Default:** `$eq($stream say)`  
**Tokens:** `$stream, $chatType, $author, $authorRaw, $name, $nameRaw`  

Determines whether name colors are used for a message.

See also:
- [`EnableSetNameColor`](./feature-flags.md#enablesetnamecolor)
- [`EnableSpeechColorAsDefaultNameColor`](./feature-flags.md#enablespeechcolorasdefaultnamecolor)

### PredicateAllowLanguage
**Default:** `$has(@(say;shout;whisper) $stream)`  
**Tokens:** `$stream, $message`  

Determines whether [roleplay languages](./languages.md) can be used for a message.
For the purpose of this predicate, `$message` is the unaltered input.
