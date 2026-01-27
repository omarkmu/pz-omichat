### Strings that display in the mod settings menu
### @do-not-translate Settings are untranslated for now

config =
    .title = { -mod-name } Settings

## Reusable terms

-enabled = Enabled

-chat-format = Chat Format

-overhead-format = Overhead Format

-default-color = Default Message Color

-tags = Tags

# @param $command string The name of the command without the leading slash.
-command-tooltip = Options that control the behavior and display of the <SPACE> { -command-color } /{ $command }
    <POPRGB> <SPACE> command.

# @param $command string The name of the command without the leading slash.
-command-tooltip-items = List of items that players can use for the
    <SPACE> { -command-color } /{ $command } <POPRGB> <SPACE> command.
    <BR> If a player doesn't have any of the items in the list, the command will fail.
    If this is blank, the command won't require an item.

-command-option-global = Global
-command-tooltip-global = Controls whether the command should be global, similar to vanilla commands.
    This disables formatting options.

-command-tooltip-overhead = Defines the format of overhead speech bubbles for the command.

-command-tooltip-tags = Tags that modify the appearance and behavior of messages associated with the command.

# @param $name string The name of the section.
# @do-not-translate
-format-section-heading = <BR> <SIZE:medium> { $name } <LINE> <SIZE:small>

## Format string overview

config-format-strings = <CENTRE> <SIZE:large> Format Strings <LINE> <SIZE:small> <LEFT>
    The style of format strings is designed to be fairly simple to modify but flexible enough
    to satisfy most servers' needs for customization.
    They can utilize a few features, which are described below.
    { -format-section-heading(name: "Tokens") }
    Tokens are case-sensitive placeholder values that are replaced with the relevant value when the format is processed.
    They are specified with a dollar sign followed by the name of the token. For example,
    { -highlight(text: "$input") } is used for the input text in various format options.
    Tokens can take on different meanings depending on the option; the info button hover bubble explains
    the use of any available tokens.
    { -format-section-heading(name: "Functions") }
    Functions are specified using a dollar sign before the function name, followed by a set of parentheses to
    enclose arguments (e.g., { -highlight(text: "$Capitalize($input)") }).
    Like tokens, functions are case-sensitive. Function arguments are separated by spaces. To include a space in a
    single argument, enclose text in backticks (e.g., `text with spaces`).
    <BR> For a list of built-in functions and their behavior, see the <SPACE>
    <LINK url=https://omarkmu.github.io/pz-omichat/format-strings/functions.html text="online documentation"> .
    { -format-section-heading(name: "Multimaps") }
    Multimaps (or 'at-maps') can be declared using an { -highlight(text: "@") } symbol followed
    by parenthesized elements.
    Elements are separated using semicolons, and key-value pairs are delimited with a colon.
    For example, { -highlight(text: "@(key:value;other)") } is a multimap
    with two keys: { -highlight(text: "key") } is set to <SPACE> { -highlight-inline(text: "value") },
    and { -highlight(text: "other") } is set to 'other' (when no value is specified, a key is mapped to itself).
    <BR> Other than advanced usage of format strings, these will only be used to provide options to default functions;
    e.g.,  { -highlight(text: "$Default(@(maxLength:100))") } sets a
    { -highlight(text: "maxLength") } option to 100.
    { -format-section-heading(name: "Escapes") }
    The characters { -highlight(text: "$, @, (, ), ;, :, and `") } can be escaped by prefixing the character with a
    dollar sign. For example, { -highlight(text: "$$PI()") } resolves to the text '$PI()', rather than the value of PI.
    This is useful to avoid using a function or token or creating a multimap where you don't intend to.
    { -format-section-heading(name: "Character References") }
    As a convenience feature to avoid having to use <SPACE> { -highlight-inline(text: "$Char()") },
    named references and numeric references can be included in format strings.
    For example, to produce text enclosed by guillemets, { -highlight(text:"&amp;#171; $input &amp;#187;") }
    or { -highlight(text: "&amp;laquo; $input &amp;raquo;") } can be used.

## General settings

config-General = General
    .title = General Settings

config-General-Preset = Preset
    .tooltip = Presets that can be applied to update all settings.
    .action1 = Apply
    .action2 = New
    .action3 = Delete
    .action-tooltip1 = {" "}{ -alert(text: "This will replace all current settings.") }
        <LINE> Apply the settings of the preset.
    .action-tooltip2 = Create a new custom preset using all current values.
    .action-tooltip3 = Delete a custom preset.

config-General-AlwaysShowChat = Always Show Chat
    .tooltip = If enabled, players will be unable to close the chat window.

config-General-CaseInsensitiveChatStreams = Case-Insensitive Streams
    .tooltip = If enabled, chat streams will be case-insensitive.
        <BR> This means that { -command(name: "say") } and { -command(name: "SAY") } will be
        treated equivalently.

config-General-IncludeRangeIndicatorButton = Range Indicator Button
    .tooltip = If enabled, a button to display the range of ranged chats will be included.

config-General-ClearOnDeath = Clear On Death
    .tooltip = Information that is cleared when a player's character dies.
    .option-Icon = Icon
    .option-tooltip-Icon = If enabled, chat icons will be cleared on death.
    .option-Languages = Languages
    .option-tooltip-Languages = If enabled, roleplay languages will be cleared on death.
    .option-Nickname = Chat Nickname
    .option-tooltip-Nickname = If enabled, chat nicknames will be cleared on death.
    .option-Status = Status
    .option-tooltip-Status = If enabled, chat statuses will be cleared on death.

config-General-AdminIcon = Admin Icon
    .tooltip = The name of the texture used when an admin enables display of a chat icon.
        Defines the value of the { -highlight(text: "adminIcon") } token in the icon format.

config-General-InfoText = Info Text
    .tooltip = Information that can be accessed by clicking an info button on the chat window.
        If this is blank, the info button will not be available.
        <BR> This can use rich text formatting to include different colors and fonts.

config-General-Variables = Variables
    .tooltip = Arbitrary key-value pairs that can be used for providing information to extensions and integrations.
        <BR> Currently, the mod does not use anything specified here.
    .placeholder-key = Key
    .placeholder-value = Value

## Buffs

config-Buffs = Buffs

config-Buffs-Enable = { -enabled }
    .tooltip = Controls whether buffs are enabled for streams that allow them.
        Other buff options have no effect if this is off.

config-Buffs-Cooldown = Cooldown
    .tooltip = The cooldown for applying buffs, in real-time minutes.

config-Buffs-Boredom = Boredom Reduction
    .tooltip = The percentage that boredom is reduced by when a buff is applied.

config-Buffs-Unhappiness = Unhappiness Reduction
    .tooltip = The percentage that unhappiness is reduced by when a buff is applied.

config-Buffs-Hunger = Hunger Reduction
    .tooltip = The percentage that hunger is reduced by when a buff is applied.

config-Buffs-Thirst = Thirst Reduction
    .tooltip = The percentage that thirst is reduced by when a buff is applied.

config-Buffs-Fatigue = Fatigue Reduction
    .tooltip = The percentage that fatigue is reduced by when a buff is applied.

config-Buffs-CigaretteStress = Cigarette Stress Reduction
    .tooltip = The percentage that stress from a lack of smoking is reduced by when a buff is applied.

## Callouts

config-Callouts = Callouts
    .title = Callout Settings

config-Callouts-Format = Callout Format
    .tooltip = Format used for the overhead text of callout messages.

config-Callouts-SneakFormat = Sneak Callout Format
    .tooltip = Format used for the overhead text of sneak callout messages.

config-Callouts-Range = Callout Range
    .tooltip = The maximum distance for callouts to be heard by players.

config-Callouts-SneakRange = Sneak Callout Range
    .tooltip = The maximum distance for sneak callouts to be heard by players.

## Commands

config-Commands = Commands

config-Commands-Name = Name Commands
    .tooltip = Options related to commands to set character names.

config-Commands-Name-Mode = Mode
    .tooltip = Controls the behavior of the { -command(name: "name") } and { -command(name: "nickname") } commands.
        <BR> If this is set to an option that sets the character's forename or full name, players will not be able to
        reset their name with the { -command(name: "name") } command.
    .option-Disable = Disable
    .option-Nickname = /name sets chat nickname
    .option-Forename = /name sets character's forename
    .option-Fullname = /name sets character's full name
    .option-Forename-Plus-Nickname = /name sets character's forename, /nickname sets chat nickname
    .option-Fullname-Plus-Nickname = /name sets character's full name, /nickname sets chat nickname

config-Commands-Status = /status
    .tooltip = Options related to the { -command(name: "status") } command.

config-Commands-Status-Enable = { -enabled }
    .tooltip = If enabled, players will be able to set a status message visible to other players
        with the { -command(name: "status") } command.

config-Commands-Status-Range = Visibility Range
    .tooltip = The range a player has to be within to see another player's status.

config-Commands-Card = /card
    .tooltip = { -command-tooltip(command: "card") }

config-Commands-Card-Global = { -command-option-global }
    .tooltip = { -command-tooltip-global }

config-Commands-Card-OverheadFormat = { -overhead-format }
    .tooltip = { -command-tooltip-overhead }

config-Commands-Card-Items = Card Items
    .tooltip = { -command-tooltip-items(command: "card") }

config-Commands-Card-Tags = { -tags }
    .tooltip = { -command-tooltip-tags }

config-Commands-Roll = /roll
    .tooltip = { -command-tooltip(command: "roll") }

config-Commands-Roll-Global = { -command-option-global }
    .tooltip = { -command-tooltip-global }

config-Commands-Roll-OverheadFormat = { -overhead-format }
    .tooltip = { -command-tooltip-overhead }

config-Commands-Roll-Items = Dice Items
    .tooltip = { -command-tooltip-items(command: "roll") }

config-Commands-Roll-Tags = { -tags }
    .tooltip = { -command-tooltip-tags }

config-Commands-Flip = /flip
    .tooltip = { -command-tooltip(command: "flip") }

config-Commands-Flip-Global = { -command-option-global }
    .tooltip = { -command-tooltip-global }

config-Commands-Flip-OverheadFormat = { -overhead-format }
    .tooltip = { -command-tooltip-overhead }

config-Commands-Flip-Items = Coin Items
    .tooltip = { -command-tooltip-items(command: "flip") }

config-Commands-Flip-Tags = { -tags }
    .tooltip = { -command-tooltip-tags }

## Compatibility

config-Compatibility = Compatibility
    .title = Compatibility Options

config-Compatibility-ApplyOverrides = Automatic Overrides
    .tooltip = If enabled, chat functions called by other mods will be intercepted by this mod.
        <BR> For example, if another mod sends a message directly to <SPACE> { -command-inline(name: "say") },
        this will attempt to apply the configured formatting.

config-Compatibility-ChatBubble = Chat Bubble
    .tooltip = Controls compatibility with the { -highlight(text: "Chat Bubble v0.6") } mod.
        <BR> The compatibility patch prevents image messages from the mod from showing up in chat.

config-Compatibility-SearchPlayers = Search Players For Weapons
    .tooltip = Controls compatibility with the { -highlight(text: "Search Players For Weapons") } mod.
        <BR> The compatibility patch modifies options added by the mod to respect the menu name format.

config-Compatibility-TrueActionsDancing = True Actions Act 3 - Dancing
    .tooltip = Controls compatibility with the { -highlight(text: "True Actions Act 3 - Dancing") } mod.
        <BR> The compatibility patch adds a { -command(name: "dance") } command and emote macros for dances.

## Character/UI customization

config-Customization = Customization

config-Customization-AllowCustomShouts = Custom Shouts
    .tooltip = Allows players to set custom callout text.

config-Customization-EnableNameColors = Name Colors
    .tooltip = If enabled, players' speech colors will be used to color their name in chat.

config-Customization-EnableCharacterCustomization = Character Customization
    .tooltip = Enables quality of life options to change the character's appearance.

config-Customization-CleanEffects = Clean Character Effects
    .tooltip = Controls the effects of the character customization option to clean blood & dirt.
        <BR> If nothing is enabled, the option will be unavailable.
    .option-Body = Clean Body
    .option-Clothing = Clean Clothing

## Discord integration

config-Discord = Discord

config-Discord-ChatFormat = { -chat-format }
    .tooltip = Controls how messages from Discord appear in chat.

config-Discord-DefaultColor = { -default-color }
    .tooltip = The default color used for messages from Discord.

config-Discord-ShowColorOption = Show Discord Color Option
    .tooltip = Controls whether options to customize Discord message color are shown to the player.
        <BR> The { -option(name: "Respect server setting") } option checks if the Discord integration
        is enabled for the server.
    .option-Yes = Yes
    .option-No = No
    .option-Respect-Server-Setting = Respect server setting

config-Discord-Tags = { -tags }
    .tooltip = Tags that modify the appearance and behavior of messages from Discord.

## Echo messages

config-EchoMessages = Echo Messages

config-EchoMessages-Enable = { -enabled }
    .tooltip = Controls whether messages from { -command(name: "faction") } and { -command(name: "safehouse") }
        are echoed onto another chat.
        <BR> Echoed messages will be sent to the stream with the { -highlight(text: "EchoTarget") } tag.

config-EchoMessages-ChatFormat = { -chat-format }
    .tooltip = Controls how echoed messages appear in chat.

config-EchoMessages-OverheadFormat = { -overhead-format }
    .tooltip = Format used for overhead speech bubbles of echoed messages.

config-EchoMessages-Tags = { -tags }
    .tooltip = Tags that modify the appearance and behavior of echoed messages.

## Formatting

config-Format = Formatting

config-Format-Chat = Chat Text
    .tooltip = Format strings used to control how messages appear in chat.

config-Format-Chat-Prefix = Prefix Format
    .tooltip = Defines the value of the { -highlight(text: "prefix") } token in the final chat format.

config-Format-Chat-Final = Final Format
    .tooltip = Format used for the final chat message, after all other format strings have been applied.

config-Format-Overhead = Overhead Text
    .tooltip = Format strings used to control how ranged messages appear over characters' heads.

config-Format-Overhead-Prefix = Prefix Format
    .tooltip = Defines the value of the { -highlight(text: "prefix") } token in the final overhead format.

config-Format-Overhead-Final = Final Format
    .tooltip = Format used for the final overhead message, after all other format strings have been applied.

config-Format-PerceptionRange = Perception Range Text
    .tooltip = Format strings for text to display when a message is out of range, but
        within range for perceiving that something was said.

config-Format-PerceptionRange-Chat = { -chat-format }
    .tooltip = Defines how out-of-range perceived messages display in chat.

config-Format-PerceptionRange-Overhead = { -overhead-format }
    .tooltip = Defines how out-of-range perceived messages display overhead.

config-Format-Component = Components
    .tooltip = Format strings used to define specific values in other format strings.

config-Format-Component-Name = Name
    .tooltip = Defines the values of the { -highlight(text: "name") }
        and { -highlight(text: "rawName") } tokens in other format strings.

config-Format-Component-Tag = Tag
    .tooltip = Format used for chat tags when a player enables the relevant option.
        This controls the value of the { -highlight(text: "tag") } token in other format strings.

config-Format-Component-Timestamp = Timestamp
    .tooltip = Format used for timestamps when a player enables the relevant option.
        This controls the value of the { -highlight(text: "timestamp") } token in other format strings.

config-Format-Component-Icon = Icon
    .tooltip = Defines the value of the { -highlight(text: "icon") } token in other format strings.

config-Format-Component-Language = Language
    .tooltip = Defines the value of the { -highlight(text: "language") } token
        in the final chat format.

config-Format-Component-EmbeddedQuote = Embedded Quotes
    .tooltip = Defines the format used for quotes embedded in actions.

config-Format-Component-EmbeddedAction = Embedded Actions
    .tooltip = Format used for actions embedded in text.

config-Format-Filter = Filters
    .tooltip = Format strings used to control whether an input is allowed.

config-Format-Filter-ChatInput = Chat Input Filter
    .tooltip = Filters chat input before sending it.
        If this results in the empty string or sets an error token, the input won't be sent.
        <BR> The default filter handles disallowing signed languages over the radio and truncation.

config-Format-Filter-Name = Name Filter
    .tooltip = Filters names set with the { -command(name: "name") } and { -command(name: "nickname") } commands.
        If this results in the empty string or sets an error token, the command will fail.

config-Format-Filter-Status = Status Filter
    .tooltip = Filters statuses set with the { -command(name: "status") } command.
        If this results in the empty string or sets an error token, the command will fail.
        <BR> The default filter handles enforcing minimum and maximum length.

config-Format-MenuName = In-Game Names
    .tooltip = Options that control how character names are displayed within in-game menus.

config-Format-MenuName-Trade = Trade Window
    .tooltip = The format used for names in the item trading UI.

config-Format-MenuName-Medical = Medical Window
    .tooltip = The format used for names in the medical check UI.

config-Format-MenuName-SearchPlayer = Search Player
    .tooltip = The format used for names in menus from
        <SPACE> { -highlight-inline(text: "Search Players For Weapons") }.
        <BR> This has no effect unless the relevant compatibility option is enabled.

config-Format-MenuName-MiniScoreboard = Mini-Scoreboard
    .tooltip = The format used for names in the admin mini-scoreboard.

config-Format-Other = Other
    .tooltip = Other options related to formatting.

config-Format-Other-PMParentheses = PM Parentheses
    .tooltip = The amount of parentheses to include around names in private messages.

config-Format-Other-DefaultNameMode = Default Name Mode
    .tooltip = The mode to use for the name format unless overridden by an argument.
        <BR> The { -option(name: "name") } mode uses the chat nickname,
        { -option(name: "username") } uses the player username,
        and { -option(name: "both") } includes both separated by a slash.

config-Format-Other-DefaultNameModeForChatType = Default Name Mode (Per Chat Type)
    .tooltip = The mode to use for the name format for a chat type unless overridden by an argument.
        <BR> This maps chat types to options for <SPACE> { -highlight-inline(text: "Default Name Mode") }.
    .placeholder-key = Chat Type
    .placeholder-value = Mode

config-Format-Other-VolumeIndicators = Volume Indicator
    .tooltip = Text to use for volume indicators.
        Keys should be one of <SPACE> { -option-inline(name: "Loud") },
        <SPACE> { -option-inline(name: "Quiet") },
        or <SPACE> { -option-inline(name: "Whisper") }.
    .placeholder-key = Volume
    .placeholder-value = Indicator Text

## Roleplay languages

config-Language = Languages
    .title = Language Settings
    .untitled = (New)

config-Language-UseDefaultList = Use Defaults
    .tooltip = If this is enabled, the languages configured below will be ignored in favor of the default languages.

config-Language-List =
    .empty = No languages configured. Language features will be disabled.

config-Language-List-Name = Name
    .tooltip = The name of the language.

config-Language-List-Signed = Signed
    .tooltip = If this is enabled, the language will be treated as a signed language.

config-Language-DefaultSlots = Default Language Slots
    .tooltip = The number of language slots players have by default.
        <BR> Players can use these slots to choose additional languages beyond
        the primary one that their character can speak.

config-Language-InterpretationRolls = Interpretation Rolls
    .tooltip = The number of rolls to attempt to reveal a word in a message sent
        with a language the player doesn't understand.

config-Language-InterpretationChance = Interpretation Chance
    .tooltip = The percent chance for each interpretation roll to succeed.

config-Language-UnknownLanguageOverhead = Unknown Language Overhead Format
    .tooltip = Controls how messages appear overhead when sent
        using a roleplay language the player's character doesn't speak.

config-Language-UnknownLanguageChat = Unknown Language Chat Format
    .tooltip = Controls how messages appear in chat when sent
        using a roleplay language the player's character doesn't speak.

config-Language-UnknownLanguageRadio = Unknown Language Chat Format (Radio)
    .tooltip = Controls how messages sent over the radio appear in chat when sent
        using a roleplay language the player's character doesn't speak.

config-Language-PlaceholderFormat = Language Indicator Format
    .tooltip = Controls the language indicator text that displays as a placeholder for the chat entry.
        By default, the indicator only shows up for languages other than the default language.

config-Language-PlaceholderColor = Language Indicator Color
    .tooltip = The color to use for the language indicator placeholder text.

config-Language-SelfAddAllowlist = Add Language Allowlist
    .tooltip = The list of languages that should display in the menu for adding languages.

config-Language-SelfAddBlocklist = Add Language Blocklist
    .tooltip = The list of languages that should not display in the menu for adding languages.

## Macros

config-Macros = Macros
    .title = Macro Settings

config-Macros-Enable = { -enabled }
    .tooltip = Controls whether macros, including built-in macros, can be used.

config-Macros-BuiltIn = Built-In Macros
    .tooltip = Controls which built-in macros are enabled.
    .option-Emote = Emotes
    .option-tooltip-Emote = If enabled, players can use shortcuts in chat to trigger animations.

## Mentions

config-Mentions = Mentions

config-Mentions-Enable = { -enabled }
    .tooltip = Controls whether players can use @ to mention other players, which includes their name color in chat.

config-Mentions-AlwaysUseNameColors = Always Use Name Colors
    .tooltip = If this is enabled, the name color option on streams will be ignored for mentions.

config-Mentions-Range = Mention Suggestion Range
    .tooltip = The range a player has to be within to have another player suggested for a mention.
        This has no effect on non-ranged streams and is ignored if set to zero.

config-Mentions-ChatFormat = { -chat-format }
    .tooltip = Defines the format of mentions in the chat.

config-Mentions-OverheadFormat = { -overhead-format }
    .tooltip = Defines the format of mentions in the overhead speech bubble.

## Narrative style

config-NarrativeStyle = Narrative Style

config-NarrativeStyle-Enable = { -enabled }
    .tooltip = Controls whether narrative style is enabled for streams that allow it.

config-NarrativeStyle-OverheadContentFormat = Overhead Content Format
    .tooltip = Defines the format of the narrative style tag and quote in the overhead text.

config-NarrativeStyle-ChatContentFormat = Chat Content Format
    .tooltip = Defines the format of the narrative style tag and quote in the chat.

config-NarrativeStyle-DialogueTagFormat = Dialogue Tag Format
    .tooltip = Defines the dialogue tag used for a message sent in narrative style.

config-NarrativeStyle-InputFilter = Input Filter
    .tooltip = Filters messages sent on a stream with narrative style enabled.

## Radio messages

config-Radio = Radio
    .title = Radio Settings

config-Radio-ChatFormat = { -chat-format }
    .tooltip = Controls how radio messages appear in chat.

config-Radio-OverheadFormat = { -overhead-format }
    .tooltip = Controls how radio messages appear in overhead speech bubbles.

config-Radio-DefaultColor = { -default-color }
    .tooltip = The default color used for radio messages.

config-Radio-Tags = { -tags }
    .tooltip = Tags that modify the appearance and behavior of radio messages.

## Server messages

config-ServerMessages = Server Messages
    .title = Server Message Settings

config-ServerMessages-ChatFormat = { -chat-format }
    .tooltip = Controls how server messages appear in chat.

config-ServerMessages-DefaultColor = { -default-color }
    .tooltip = The default color used for server messages.

config-ServerMessages-Tags = { -tags }
    .tooltip = Tags that modify the appearance and behavior of server messages.

## Streams

config-Streams = Streams
    .title = Stream Settings

config-Streams-UseDefaultList = Use Defaults
    .tooltip = If this is enabled, the streams configured below will be ignored in favor of the default streams.

config-Streams-List =
    .empty = No streams configured. The default streams will be used.

config-Streams-List-Enable = { -enabled }
    .tooltip = Controls whether this stream is enabled.

config-Streams-List-Stream = Stream Type
    .tooltip = The type of the stream.
        <BR> Using a value other than { -option(name: "custom") } for this option disables some other options.
        These will be inherited from the stream type.

config-Streams-List-Name = Name
    .tooltip = The name of the stream.
        <BR> Streams that have duplicate names or share a name with a stream type are ignored.
        <BR> Other reserved names are <SPACE> { -option-inline(name: "server") }, <SPACE>
        { -option-inline(name: "discord") }, <SPACE> { -option-inline(name: "radio") },
        and <SPACE> { -option-inline(name: "speech") }.

config-Streams-List-Command = Command
    .tooltip = The primary command to use to send a message on the stream. Defaults to the name of the stream.

config-Streams-List-ShortCommand = Short Command
    .tooltip = A short command that can be used to send a message on the stream.

config-Streams-List-ChatType = Chat Type
    .tooltip = The type of chat this stream sends messages over.

config-Streams-List-Category = Category
    .tooltip = The category of this stream. <BR> This is used to categorize streams for retaining options.

config-Streams-List-DefaultColor = { -default-color }
    .tooltip = The default color used for messages sent over this stream.

config-Streams-List-Range = Range
    .tooltip = The range of this stream.

config-Streams-List-VerticalRange = Vertical Range
    .tooltip = The vertical range of this stream.
        <BR> A value of 0 means that vertical levels should be ignored.

config-Streams-List-PerceptionRange = Perception Range
    .tooltip = The range in which an indicator that something was said out-of-range will send.
        <BR> A value of 0 means nothing out-of-range will be perceived.

config-Streams-List-PerceptionRangeSigned = Perception Range (Signed)
    .tooltip = The range in which an indicator that something was said out-of-range will send,
        when sent in a signed roleplay language.
        <BR> A value of 0 means nothing out-of-range will be perceived.

config-Streams-List-ChatFormat = { -chat-format }
    .tooltip = Controls how messages sent on this stream appear in chat.

config-Streams-List-OverheadFormat = { -overhead-format }
    .tooltip = Format used for overhead speech bubbles.

config-Streams-List-AllowBuffs = Allow Buffs
    .tooltip = If this is enabled and buffs are turned on, sending a message on this stream will apply a buff.

config-Streams-List-AllowMentions = Allow Mentions
    .tooltip = If this is enabled, mentions will be allowed on this stream.

config-Streams-List-AllowLanguages = Allow RP Languages
    .tooltip = If this is enabled, this stream will use the player's current language when sending messages.

config-Streams-List-AllowTypingIndicator = Allow Typing Indicator
    .tooltip = If this is enabled, typing on the stream will trigger the typing indicator.

config-Streams-List-AttractZombies = Attract Zombies
    .tooltip = If this is enabled and zombie attraction is enabled, messages on this stream can attract zombies.

config-Streams-List-UseNarrativeStyle = Use Narrative Style
    .tooltip = If this is enabled and narrative style is on, messages on this stream will use narrative style.

config-Streams-List-Tags = { -tags }
    .tooltip = Tags that modify the appearance and behavior of the stream.

config-Streams-List-Aliases = Aliases
    .tooltip = List of additional aliases that can be used to send messages on the stream.

config-Streams-List-Roles = Roles
    .tooltip = List of roles that can use this stream. If the list is empty, the stream will not be limited to any roles.

config-Streams-GlobalTags = Global Tags
    .tooltip = Additional tags to include in every stream.

## Typing indicator

config-TypingIndicator = Typing Indicator

config-TypingIndicator-Enable = { -enabled }
    .tooltip = Controls whether the typing indicator is enabled on streams that allow it.

config-TypingIndicator-Format = Typing Format
    .tooltip = Defines the format of the typing indicator message when the typing indicator is enabled.

config-TypingIndicator-NameFormat = Name Format
    .tooltip = Defines the format of names in the typing indicator message.

## Zombie attraction

config-ZombieAttraction = Zombie Attraction

config-ZombieAttraction-ChatRangeMultiplier = Chat Range Multiplier
    .tooltip = A multiplier that will be applied to chat ranges to determine zombie attraction range.
        <BR> If this is zero, non-callout chat messages will not attract zombies.

config-ZombieAttraction-CalloutRange = Callout Range
    .tooltip = The maximum distance for callouts to attract zombies.

config-ZombieAttraction-SneakCalloutRange = Sneak Callout Range
    .tooltip = The maximum distance for sneak callouts to attract zombies.
