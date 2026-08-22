### Various user-facing translations

-mod-name = OmiChat

## Chat formatting

# @param $frequency string The radio frequency a message was sent over.
radio = Radio ({ $frequency } MHz)

# @param $name string The recipient of the chat message.
private-chat-to = PM to { $name }

# @param $name string The sender of the chat message.
private-chat-from = PM from { $name }

faction-radio = (Faction Radio)

safehouse-radio = (Safehouse Radio)

over-radio = (Over Radio)

admin-indicator = (Admin)

# @param $language string The translated name of the language being spoken.
placeholder-language-indicator = Speaking { $language }

## Typing indicator

# @param $name string The name of the player who is typing.
typing-1 = { $name } is typing...

# @param $name1 string The name of the first player who is typing.
# @param $name2 string The name of the second player who is typing.
typing-2 = { $name1 } and { $name2 } are typing...

# @param $name1 string The name of the first player who is typing.
# @param $name2 string The name of the second player who is typing.
# @param $name3 string The name of the third player who is typing.
typing-3 = { $name1 }, { $name2 }, and { $name3 } are typing...

typing-many = Several people are typing...

## Command messages

# @param $name string The name of the player who drew a card. This may include rich text formatting.
# @param $card string The full name of the card that was drawn.
# @param $rawName? string The name of the player who drew a card, without formatting.
# @param $space? string The rich text space to include after the name, or an empty string if not rich text.
command-card = { $name }{ $space } draws { $card }

# @param $name string The name of the player who drew a card.
# @param $card string The full name of the card that was drawn.
command-card-global = { $name } drew { $card }

# @param $name string The name of the player who rolled a die. This may include rich text formatting.
# @param $roll integer The result of the dice roll.
# @param $sides integer The number of sides on the die.
# @param $rawName? string The name of the player who rolled a die, without formatting.
# @param $space? string The rich text space to include after the name, or an empty string if not rich text.
command-roll = { $name }{ $space } rolls { $roll } on a { $sides }-sided die

# @param $name string The name of the player who rolled a die. This may include rich text formatting.
# @param $roll integer The result of the dice roll.
# @param $expression string The dice expression. May contain rich text.
# @param $rawName? string The name of the player who rolled a die, without formatting.
# @param $space? string The rich text space to include after the name, or an empty string if not rich text.
command-roll-expression = { $name }{ $space } rolls { $roll } with { $expression }

# @param $name string The name of the player who rolled a die. This may include rich text formatting.
# @param $roll integer The result of the dice roll.
# @param $rawName? string The name of the player who rolled a die, without formatting.
# @param $space? string The rich text space to include after the name, or an empty string if not rich text.
command-roll-percentile = { $name }{ $space } rolls { $roll } on a percentile die

# @param $name string The name of the player who rolled a die.
# @param $roll integer The result of the dice roll.
# @param $sides integer The number of sides on the die.
command-roll-global = { $name } rolled { $roll } on a { $sides }-sided die

# @param $name string The name of the player who rolled a die.
# @param $roll integer The result of the dice roll.
# @param $expression string The dice expression. May contain rich text.
command-roll-global-expression = { $name } rolled { $roll } with { $expression }

# @param $name string The name of the player who rolled a die.
# @param $roll integer The result of the dice roll.
command-roll-global-percentile = { $name } rolled { $roll } on a percentile die

# @param $name string The name of the player who flipped a coin. This may include rich text formatting.
# @param $rawName? string The name of the player who flipped a coin, without formatting.
# @param $space? string The rich text space to include after the name, or an empty string if not rich text.
command-flip-heads = { $name }{ $space } flips a coin and gets heads

# @param $name string The name of the player who flipped a coin.
command-flip-heads-global = { $name } flipped a coin and got heads

# @param $name string The name of the player who flipped a coin. This may include rich text formatting.
# @param $rawName? string The name of the player who flipped a coin, without formatting.
# @param $space? string The rich text space to include after the name, or an empty string if not rich text.
command-flip-tails = { $name }{ $space } flips a coin and gets tails

# @param $name string The name of the player who flipped a coin.
command-flip-tails-global = { $name } flipped a coin and got tails

## Info messages

info-set-name-empty = No name specified. Use /name Name

# @param $status string The current status message that the player has set.
info-current-status = Current status: { $status }

info-current-status-unset = No status is set.

# @param $name string The name of a texture.
# @param $icon string An <IMAGE> rich text component representing the icon.
info-icon = '{ $name }' is the icon name for: { $icon }

# @param $name string The text that the player provided for the /iconinfo command.
info-icon-unknown = '{ $name }' is not a known icon name.

# @param $alias string An alias for a chat icon.
# @param $name string The name of a texture.
# @param $icon string An <IMAGE> rich text component representing the icon.
info-icon-alias = '{ $alias }' is an alias for '{ $name }', the icon name for: { $icon }

info-clear = Console cleared

info-available-emotes = Available emotes:

info-available-emotes-with-macro = You can also trigger emotes in chat messages with !emote.

info-command-list = List of commands:

info-available-dances = Available dances:

info-dance-unknown = Unknown dance. Use '/dance list' to see available dances.

# @param $dance string The text that the player provided for the /dance command.
info-dance-unknown-recipe = You don't know the { $dance } dance. Use '/dance list' to see available dances.

# @param $dance string The text that the player provided for the /dance command.
info-dance-missing-item = You need a dance card to do the { $dance } dance. Use '/dance list' to see available dances.

## Success messages

# @param $name string The text that the player provided for the /name or /nickname command.
success-set-name-self = Your name is now '{ $name }'.

# @param $status string The text that the player provided for the /status command.
success-set-status-self = Your status has been set to '{ $status }'.

success-reset-name = Your name has been reset.

success-reset-status = Your status has been cleared.

success-clear-names = Cleared all nicknames.

# @param $name string The name that the player provided for the /setname command.
# @param $username string The username that the player provided for the /setname command.
success-set-name-other = Name has been set to '{ $name }' for player '{ $username }'.

# @param $username string The username that the player provided for the /resetname command.
success-reset-name-other = Name has been reset for player '{ $username }'.

# @param $username string The username that the player provided for the /seticon command.
success-set-icon-other = Icon has been set for player '{ $username }'.

# @param $username string The username that the player provided for the /reseticon command.
success-reset-icon-other = Icon has been reset for player '{ $username }'.

# @param $language string The language name the player provided for the /addlanguage command.
# @param $username string The username that the player provided for the /addlanguage command.
success-add-language-other = Added roleplay language '{ $language }' to player '{ $username }'.

# @param $username string The username that the player provided for the /resetlanguages command.
success-reset-languages-other = RP languages have been reset for player '{ $username }'.

# @param $slots string The number of slots that the player provided for the /setlanguageslots command.
# @param $username string The username that the player provided for the /setlanguageslots command.
success-set-language-slots-other = Language slots have been set to { $slots } for player '{ $username }'.

## Error messages

# @param $name string The text that the player provided for the /name or /nickname command.
error-invalid-name = Your name cannot be set to '{ $name }'.

# @param $status string The text that the player provided for the /status command.
error-invalid-status = Your status cannot be set to '{ $status }'.

error-signed-radio = You can't use sign language over the radio.

error-signed-faction-radio = You can't use sign language over faction radio.

error-signed-safehouse-radio = You can't use sign language over safehouse radio.

# @param $username string The username provided to the command.
error-unknown-player = Could not find player '{ $username }'.

# @param $language string The text that the player provided for the /language command.
error-switch-unknown-language = Cannot switch to unknown language '{ $language }'.

# @param $max number The maximum number of custom shouts.
error-too-many-shouts = Too many lines; up to { $max } custom shouts can be specified.

# @param $max number The maximum length of a custom shout.
error-too-long-shout = Shout text can only be up to { $max } characters long.

# @param $username string The username that the player provided for the /addlanguage command.
error-add-language-full = Player '{ $username }' already knows the maximum number of languages.

# @param $username string The username that the player provided for the /addlanguage command.
# @param $language string The name of a roleplay language.
error-add-language-known = Player '{ $username }' already knows { $language }.

# @param $language string The username that the player provided for the /addlanguage command.
error-add-language-not-configured = '{ $language }' is not a configured language.

# @param $username string The username that the player provided.
# @param $language string The name of a roleplay language.
error-language-unknown = Player '{ $username }' does not know { $language }.

## Help text

help-text-emote = Trigger an emote animation. Example: /emote yes. To see a list of emotes, use /emote list

help-text-switch-language = Switch your active language. Example: /language Spanish

help-text-name = To set your name, use: /name Name. Example: /name Bob

help-text-name-full = To set your name, use: /name FirstName LastName. Example: /name Bob Smith

help-text-nickname = To set your name in chat, use: /nickname Name. Example: /name Bob

help-text-status = To set a status message, use: /status Description. To clear your status, use: /status clear

help-text-set-name = Set a player's name in chat. Example: /setname username Name

help-text-reset-name = Reset a player's name in chat. Example: /resetname username

help-text-clear-names = Clears all player chat names. Use /clearnames

help-text-add-language = Add to a player's roleplay language list. Example: /addlanguage username English

help-text-reset-languages = Reset a player's roleplay languages. Example: /resetlanguages username

help-text-set-language-slots = Set the amount of roleplay language slots for a player. Slots must be in [1, 50].
    Example: /setlanguageslots username 5

help-text-set-icon = Set a player's chat icon. Example: /seticon username crowbar

help-text-reset-icon = Reset a player's chat icon. Example: /reseticon username

help-text-icon-info = Get an icon's proper name, for use in format strings. Example: /iconinfo plushspiffo

help-text-flip = Flip a coin. Use /flip

help-text-dance = Use /dance to do a random dance. Use /dance followed by the name of the dance to do a specific dance.
    To see a list of dances, use /dance list

# @do-not-translate
help-text-card = { GETTEXT("UI_ServerOptionDesc_Card") }

help-text-roll = Roll a random number. Use: /roll 20, /roll 2d10 + 3

## Unknown language

# @param $language string The name of a roleplay language.
unknown-language-no-author = Something is said in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-asks = { $name } asks something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-says = { $name } says something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-signs = { $name } signs something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-states = { $name } states something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-shouts = { $name } shouts something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-hisses = { $name } hisses something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-exclaims = { $name } exclaims something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-whispers = { $name } whispers something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-whisper-shouts = { $name } whisper shouts something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-signed-whispers = { $name } subtly signs something in { $language }.

# @param $name string The name of the speaking player.
# @param $language string The name of a roleplay language.
unknown-language-signed-shouts = { $name } energetically signs something in { $language }.

## Volume indicators

volume-indicator-low = Low

volume-indicator-long = Long

volume-indicator-loud = Loud

volume-indicator-whisper = Whisper

## Perception range

out-of-range = Out of Range

# @param $name string The name of the speaking player.
perceived-chat = { $name } says something.

# @param $name string The name of the speaking player.
perceived-chat-whisper = { $name } whispers something.

# @param $name string The name of the speaking player.
perceived-chat-quiet = { $name } says something quietly.

# @param $name string The name of the speaking player.
perceived-chat-loud = { $name } shouts something.

# @param $name string The name of the speaking player.
perceived-chat-signed = { $name } signs something.

# @param $name string The name of the speaking player.
perceived-chat-signed-whisper = { $name } subtly signs something.

# @param $name string The name of the speaking player.
perceived-chat-signed-quiet = { $name } signs something quietly.

# @param $name string The name of the speaking player.
perceived-chat-signed-loud = { $name } energetically signs something.

## Cards

# @param $card string The translated card name.
# @param $suit string The translated card suit name.
card-name = { $card } of { $suit }

card-ace = the Ace

card-jack = the Jack

card-queen = the Queen

card-king = the King

card-two = a Two

card-three = a Three

card-four = a Four

card-five = a Five

card-six = a Six

card-seven = a Seven

card-eight = an Eight

card-nine = a Nine

card-ten = a Ten

card-suit-clubs = Clubs

card-suit-diamonds = Diamonds

card-suit-hearts = Hearts

card-suit-spades = Spades

## Profile manager

message-type-radio = radio

# @translate-optional
message-type-discord = Discord

message-type-server = server

# @param-attribute default-profile-name $index integer The index of the new profile in the list.
# @param-attribute label-color $command string The name of a command prefixed with a leading slash.
# @param-attribute tooltip-color $type string The name of a command prefixed with a leading slash, or a command type.
profile-manager =
    .title = Profile Manager
    .empty = You have no profiles.
    .default-profile-name = Profile { $index }
    .btn-create = Create New Profile
    .btn-delete = Delete Profile
    .btn-duplicate = Duplicate Profile
    .label-color = { $command } color
    .label-color-radio = Radio message color
    .label-color-discord = Discord message color
    .label-color-server = Server message color
    .label-color-name = Name color
    .label-color-speech = Speech color
    .label-nickname = Chat nickname
    .label-profile-name = Profile name
    .label-callouts = Callouts
    .label-sneak-callouts = Sneak callouts
    .tooltip-callouts = Enter one callout per line.
    .tooltip-nickname = Enter a nickname to use when you switch to this profile.
    .tooltip-color = Enter a color in RGB or hex format to set the color used for { $type } messages.
    .tooltip-color-name = Enter a color in RGB or hex format to set the color of your name in chat.
    .tooltip-color-speech = Enter a color in RGB or hex format to set the color of your overhead speech bubbles.
    .tooltip-max-profiles = You already have the maximum number of profiles.

## Player data manager

player-data-manager =
    .title = { -mod-name } Player Data
    .editor-title = Edit Player Data
    .no-data = (empty)
    .column-username = Username
    .column-nickname = Chat Nickname
    .column-status = Status
    .column-icon = Icon
    .column-currentLanguage = Current Language
    .column-languages = Languages
    .column-languageSlots = Language Slots

## Configuration presets

preset-custom = User-defined preset.

# @do-not-translate
preset-buffy = {" "}{ -highlight-inline(text: "Buffy") }: settings tailored to roleplay, based on buffy's roleplay chat.
    This is the default preset.

# @do-not-translate
preset-omar = {" "}{ -highlight-inline(text: "Omar") }: settings designed for lighter roleplay, with narrative style disabled.
    This is closer to the default settings from the legacy b41 version of { -mod-name }.

# @do-not-translate
preset-vanilla = {" "}{ -highlight-inline(text: "Vanilla") }: settings designed to mimic vanilla, with many mod features disabled.

dialog-save-preset = Enter a name for the new preset.

# @param $name string The name of the preset.
dialog-confirm-delete-preset = Delete the { $name } custom preset? This cannot be undone.

save-preset-overwrite = Saving will overwrite the existing preset with this name.

# @param $name string The name of the preset.
status-preset = Applied values from the { $name } preset.

## Context menus

context-chat-settings = Chat settings

context-customization = Customization

context-languages = Language

context-clean = Clean blood & dirt

context-hair-color = Change hair color
    .dialog = Enter a color in RGB or hex format to set your hair color, or nothing to reset.

context-grow-hair = Grow hair

context-grow-beard = Grow beard

context-enable-name-colors = Enable name colors

context-disable-name-colors = Disable name colors

context-suggestions = Suggestions

context-suggestions-enable = Enable suggestions

context-suggestions-disable = Disable suggestions

context-suggestions-on-enter = Insert after pressing Enter

context-suggestions-on-tab = Insert after pressing Tab

context-enable-typing-indicator = Enable typing indicator

context-disable-typing-indicator = Disable typing indicator

context-retain-commands = Retain commands

context-retain-commands-chat = Chat

context-retain-commands-rp = RP

context-retain-commands-other = Other

# @param-attribute dialog $language string The name of a roleplay language.
context-add-language = Add
    .dialog = Add { $language } to your language list? This cannot be undone.

context-sign-emotes-enable = Enable sign language animations

context-sign-emotes-disable = Disable sign language animations

context-sign-emotes-tooltip = This controls whether a random animation is played
    when sending a message in a signed language.

context-profiles = Switch profile

context-profile-default = Default

context-manage-profiles = Manage profiles

context-admin = Admin options

context-admin-view-player-data = View player data

context-admin-open-settings = Open settings
    .sandbox-tooltip = { -mod-name } does not use sandbox options for configuration. <BR>
        Click here to open the settings menu, which can also be accessed from the chat window's admin options.

context-admin-show-icon = Display chat icon

context-admin-know-all-languages = Understand all languages

context-admin-ignore-message-range = Ignore message range

## Roleplay languages

language-arabic = Arabic

language-asl = ASL

language-bengali = Bengali

language-cantonese = Cantonese

language-catalan = Catalan

language-danish = Danish

language-dutch = Dutch

language-english = English

language-finnish = Finnish

language-french = French

language-german = German

language-gujarati = Gujarati

language-hausa = Hausa

language-hawaiian = Hawaiian

language-hindi = Hindi

language-hungarian = Hungarian

language-italian = Italian

language-japanese = Japanese

language-javanese = Javanese

language-korean = Korean

language-latvian = Latvian

language-malay = Malay

language-mandarin = Mandarin

language-marathi = Marathi

language-norwegian = Norwegian

language-persian = Persian

language-polish = Polish

language-portuguese = Portuguese

language-punjabi = Punjabi

language-romanian = Romanian

language-russian = Russian

language-shanghainese = Shanghainese

language-spanish = Spanish

language-tagalog = Tagalog

language-tamil = Tamil

language-telugu = Telugu

language-thai = Thai

language-turkish = Turkish

language-ukrainian = Ukrainian

language-urdu = Urdu

language-vietnamese = Vietnamese
