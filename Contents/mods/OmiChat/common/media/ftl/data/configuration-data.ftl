### Configuration data
### @do-not-translate

### This does not contain translations.
### It defines data for generating the configuration schema and form.
### This data is also used to generate the documentation website.
### Not exactly typical use of Fluent, but it works reasonably well for structured data.

VERSION = 1

## Data types

# A container for fields.
-container = container

# A string input.
-string = string

# A multi-line string input.
-textbox = textbox

# A format string input.
-format-string = format-string

# An integer number input.
-integer = integer

# A floating point number input.
-number = number

# A color input.
-color = color

# A string list input.
-string-list = string-list

# A list input with objects.
-object-list = object-list

# A list of tags.
# Shortcut for applying related options.
-tags = tags

# A dropdown backed by a string enum field.
-dropdown = dropdown

# A dropdown of compatibility option values.
-compatibility = compatibility

# A checkbox backed by a boolean field.
-checkbox = checkbox

# A checkbox backed by a boolean field, which enables or disables all fields on its page.
-page-checkbox = page-checkbox

# A checkbox group backed by a set field with enum items.
-checkbox-group = checkbox-group

## Variables

# Default padding amount.
-pad = 10

-global-command-toggles =
    Commands.{ $command }.OverheadFormat;
    Commands.{ $command }.Tags

-custom-stream-option = This option is only enabled if [`Stream Type`](#list-stream) is set to *custom*.

-ranged-stream-option = This option is only enabled for ranged [chat types](#list-chattype).

-args-overhead =
    input;
    name;
    colorTargetTag

-args-chat = { -args-overhead };recipientName
-args-prefix = loudIndicator;quietIndicator;whisperIndicator

-tokens-narrative = narrativeStyle;dialogueTag;unstyled

-tokens-menu-name =
    name;
    forename;
    surname;
    username;
    menuType

-tokens-chat-no-narrative =
    admin;
    stream;
    chatType;
    author;
    rawAuthor;
    name;
    rawName;
    tags;
    originalTags;
    originalStream;
    input;
    language;
    rawLanguage;
    unknownLanguage;
    faction;
    incomingPM;
    outgoingPM;
    recipient;
    rawRecipient;
    recipientName;
    rawRecipientName;
    card;
    heads;
    roll;
    sides

-tokens-overhead-no-narrative =
    chatType;
    input;
    username;
    name;
    stream;
    echo;
    tags;
    language;
    rawLanguage;
    callout;
    sneakCallout

-tokens-chat = { -tokens-chat-no-narrative };{ -tokens-narrative }
-tokens-overhead = { -tokens-overhead-no-narrative };{ -tokens-narrative }

-tokens-chat-processed =
    tag;
    chatType;
    timestamp;
    admin;
    echo;
    stream;
    rawIcon;
    tags;
    originalTags;
    originalStream;
    input;
    language;
    icon


## General settings

config-General =
    .type = { -container }
    .short-description = Basic features.
    .description = These options are used to control the basic features of the mod.

config-General-Preset =
    .type = { -string }
    .pad-bottom = 16
    .default = Buffy
    .no-doc = true

config-General-AlwaysShowChat =
    .type = { -checkbox }
    .default = false

config-General-CaseInsensitiveChatStreams =
    .type = { -checkbox }
    .pad-bottom = { -pad }
    .default = true

config-General-ClearOnDeath =
    .type = { -checkbox-group }
    .default-all = true
    .options = Icon;Languages;Nickname;Status

config-General-AdminIcon =
    .type = { -string }
    .pad-bottom = { -pad }
    .default = Item_Hammer
    .no-full-width = true

config-General-InfoText =
    .type = { -textbox }
    .max-lines = 50

config-General-Variables =
    .type = { -string-list }
    .default =
        DefaultNameMode:name;
        DefaultNameMode_admin:username;
        DefaultNameMode_whisper:both;
        VolumeIndicatorLoud:Long

## Buffs

config-Buffs =
    .type = { -container }
    .short-description = Options related to buffs.
    .description = These options control buffs, which are configurable boosts to stats that are applied when messages
        are sent on certain streams. <BR> By default, only roleplay streams (e.g., `/me`) apply buffs.
        Whether a stream applies buffs can be changed using the [`Allow Buffs`](./streams.md#list-allowbuffs) option.

config-Buffs-Enable =
    .type = { -page-checkbox }
    .pad-bottom = { -pad }
    .default = true

config-Buffs-Cooldown =
    .type = { -integer }
    .default = 15
    .min = 0
    .max = 1440

config-Buffs-Boredom =
    .type = { -number }
    .default = 0.2
    .min = 0
    .max = 1

config-Buffs-Unhappiness =
    .type = { -number }
    .default = 0.2
    .min = 0
    .max = 1

config-Buffs-Hunger =
    .type = { -number }
    .default = 0.1
    .min = 0
    .max = 1

config-Buffs-Thirst =
    .type = { -number }
    .default = 0.1
    .min = 0
    .max = 1

config-Buffs-Fatigue =
    .type = { -number }
    .default = 0.1
    .min = 0
    .max = 1

config-Buffs-CigaretteStress =
    .type = { -number }
    .default = 0.2
    .min = 0
    .max = 1

## Callouts

config-Callouts =
    .type = { -container }
    .short-description = Options for callouts.
    .description = These options control features related to callouts (shouts).

config-Callouts-Format =
    .type = { -format-string }
    .tokens = { -tokens-overhead }
    .args = { -args-overhead }

config-Callouts-SneakFormat =
    .type = { -format-string }
    .tokens = { -tokens-overhead }
    .args = { -args-overhead }

config-Callouts-Range =
    .type = { -integer }
    .default = 48
    .min = 0
    .max = 60

config-Callouts-SneakRange =
    .type = { -integer }
    .default = 6
    .min = 0
    .max = 60

## Commands

config-Commands =
    .type = { -container }
    .short-description = Options for chat commands.
    .description = These options control various commands that are available in chat.

config-Commands-Name =
    .type = { -container }

config-Commands-Name-Mode =
    .type = { -dropdown }
    .no-label = true
    .default = Nickname
    .options =
        Disable;
        Nickname;
        Forename;
        Fullname;
        Forename-Plus-Nickname;
        Fullname-Plus-Nickname

config-Commands-Status =
    .type = { -container }

config-Commands-Status-Enable =
    .type = { -checkbox }
    .default = true
    .toggle = Commands.Status.Range

config-Commands-Status-Range =
    .type = { -integer }
    .default = 20
    .min = 1
    .max = 100

config-Commands-Card =
    .type = { -container }

config-Commands-Card-Global =
    .type = { -checkbox }
    .toggle-inverse = { -global-command-toggles(command: "Card") }
    .default = false

config-Commands-Card-OverheadFormat =
    .type = { -format-string }
    .tokens = { -tokens-overhead }
    .args = { -args-overhead }

config-Commands-Card-Items =
    .type = { -string-list }
    .default = CardDeck

config-Commands-Card-Tags =
    .type = { -tags }

config-Commands-Roll =
    .type = { -container }

config-Commands-Roll-Global =
    .type = { -checkbox }
    .toggle-inverse = { -global-command-toggles(command: "Roll") }
    .default = false

config-Commands-Roll-OverheadFormat =
    .type = { -format-string }
    .tokens = { -tokens-overhead }
    .args = { -args-overhead }

config-Commands-Roll-Items =
    .type = { -string-list }
    .default =
        Dice;
        Dice_00;
        Dice_4;
        Dice_6;
        Dice_8;
        Dice_10;
        Dice_12;
        Dice_20

config-Commands-Roll-Tags =
    .type = { -tags }

config-Commands-Flip =
    .type = { -container }

config-Commands-Flip-Global =
    .type = { -checkbox }
    .toggle-inverse = { -global-command-toggles(command: "Flip") }
    .default = false

config-Commands-Flip-OverheadFormat =
    .type = { -format-string }
    .tokens = { -tokens-overhead }
    .args = { -args-overhead }

config-Commands-Flip-Items =
    .type = { -string-list }

config-Commands-Flip-Tags =
    .type = { -tags }

## Compatibility

config-Compatibility =
    .type = { -container }
    .short-description = Options to control compatibility with other mods.
    .description = These options control compatibility patches for other mods.
        <BR>
        > [!NOTE] <LINE>
        > Currently, mod compatibility patches are soft-removed.
        They may be reintroduced when the relevant mods are updated for b42.

config-Compatibility-ApplyOverrides =
    .type = { -checkbox }
    .default = true

# hiding compat options until relevant mods are updated
config-Compatibility-ChatBubble =
    .type = { -compatibility }
    .hidden = true

config-Compatibility-SearchPlayers =
    .type = { -compatibility }
    .hidden = true

config-Compatibility-TrueActionsDancing =
    .type = { -compatibility }
    .hidden = true

## Character/UI customization

config-Customization =
    .type = { -container }
    .short-description = Options for player customization.
    .description = These options control the customization options available to players.

config-Customization-AllowCustomShouts =
    .type = { -checkbox }
    .default = true

config-Customization-EnableNameColors =
    .type = { -checkbox }
    .default = true

config-Customization-EnableCharacterCustomization =
    .type = { -checkbox }
    .pad-top = { -pad }
    .toggle = Customization.CleanEffects
    .default = true

config-Customization-CleanEffects =
    .type = { -checkbox-group }
    .default-all = true
    .options = Body;Clothing

## Discord integration

config-Discord =
    .type = { -container }
    .short-description = Options for Discord integration.
    .description = These options control the formatting of messages that come from Discord.

config-Discord-ChatFormat =
    .type = { -format-string }
    .tokens = { -tokens-chat }
    .args = { -args-chat }

config-Discord-DefaultColor =
    .type = { -color }
    .default = 144,137,218

config-Discord-ShowColorOption =
    .type = { -dropdown }
    .pad-top = { -pad }
    .default = Respect-Server-Setting
    .options = Yes;No;Respect-Server-Setting

config-Discord-Tags =
    .type = { -tags }
    .default = OOC;UseAuthorUsername

## Echo messages

config-EchoMessages =
    .type = { -container }
    .short-description = Options for echo messages.
    .description = These options control echo messages,
        which are messages sent on one stream that automatically send to another.

config-EchoMessages-Enable =
    .type = { -page-checkbox }
    .default = true

config-EchoMessages-ChatFormat =
    .type = { -format-string }
    .tokens = { -tokens-chat }
    .args = { -args-chat }

config-EchoMessages-OverheadFormat =
    .type = { -format-string }
    .tokens = { -tokens-overhead }
    .args = { -args-overhead }

config-EchoMessages-Tags =
    .type = { -tags }
    .default = OverRadio

## Format strings

config-Format =
    .type = { -container }
    .short-description = Format strings for advanced customization.
    .description = These [format strings](../format-strings/index.md) can be used for advanced customization.
        <BR> All of these formats default to `$Default()`, which gets the default content.
        The tokens and options that each format accepts are available in the in-game configuration menu.

config-Format-Chat =
    .type = { -container }

config-Format-Chat-Prefix =
    .type = { -format-string }
    .args = { -args-prefix }
    .tokens = { -tokens-chat-processed }
    .token-input = token-input-processed
    .token-language = token-language-processed
    .token-icon = token-icon-processed

config-Format-Chat-Final =
    .type = { -format-string }
    .args = prefix;input
    .tokens = { -tokens-chat-processed };prefix
    .token-input = token-input-processed
    .token-language = token-language-processed
    .token-icon = token-icon-processed
    .token-prefix = token-prefix-chat-final

config-Format-Overhead =
    .type = { -container }

config-Format-Overhead-Prefix =
    .type = { -format-string }
    .args = { -args-prefix }
    .tokens = { -tokens-overhead }

config-Format-Overhead-Final =
    .type = { -format-string }
    .args = prefix;input
    .tokens = { -tokens-overhead };prefix
    .token-prefix = token-prefix-overhead-final

config-Format-PerceptionRange =
    .type = { -container }

config-Format-PerceptionRange-Chat =
    .type = { -format-string }
    .args = name
    .tokens = { -tokens-chat }

config-Format-PerceptionRange-Overhead =
    .type = { -format-string }
    .args = name
    .tokens = { -tokens-overhead }

config-Format-Component =
    .type = { -container }

config-Format-Component-Name =
    .type = { -format-string }
    .args = mode;defaultName;name
    .tokens = chatType;forename;username;surname;username;name
    .token-name = token-name-component

config-Format-Component-Tag =
    .type = { -format-string }
    .tokens = chatType;stream;tags;originalTags;originalStream;tag
    .token-tag = token-tag-component

config-Format-Component-Timestamp =
    .type = { -format-string }
    .tokens = chatType;stream;tags;originalTags;originalStream;hourFormat;P;PP;h;hh;H;HH;m;mm;s;ss;ampm;AMPM

config-Format-Component-Icon =
    .type = { -format-string }
    .tokens = cardIcon;flipIcon;rollIcon;adminIcon;icon

config-Format-Component-Language =
    .type = { -format-string }
    .tokens = chatType;stream;language;rawLanguage;adminIcon;tags;originalTags;originalStream

config-Format-Component-EmbeddedQuote =
    .type = { -format-string }
    .args = input;colorTargetTag
    .tokens = input;tags
    .pad-top = { -pad }
    .description-tokens = desc-token-embedded

config-Format-Component-EmbeddedAction =
    .type = { -format-string }
    .args = input;colorTargetTag
    .tokens = input;tags
    .description-tokens = desc-token-embedded

config-Format-Filter =
    .type = { -container }

config-Format-Filter-ChatInput =
    .type = { -format-string }
    .args = input;maxLength;truncateTo
    .arg-truncateTo = arg-truncateTo-filter-chat-input
    .tokens = { -tokens-overhead }
    .error-tokens = true

config-Format-Filter-Name =
    .type = { -format-string }
    .args = minLength;maxLength;truncateTo
    .arg-truncateTo = arg-truncateTo-filter-name
    .tokens = input;target
    .token-target = token-target-filter-name
    .error-tokens = true

config-Format-Filter-Status =
    .type = { -format-string }
    .args = truncateTo;maxLength;minLength
    .arg-maxLength = arg-maxLength-filter-status
    .arg-minLength = arg-minLength-filter-status
    .tokens = input
    .error-tokens = true

config-Format-MenuName =
    .type = { -container }

config-Format-MenuName-Trade =
    .type = { -format-string }
    .tokens = { -tokens-menu-name }

config-Format-MenuName-Medical =
    .type = { -format-string }
    .tokens = { -tokens-menu-name }

config-Format-MenuName-SearchPlayer =
    .type = { -format-string }
    .tokens = { -tokens-menu-name }

config-Format-MenuName-MiniScoreboard =
    .type = { -format-string }
    .tokens = { -tokens-menu-name }

## Roleplay languages

config-Language =
    .type = { -container }
    .short-description = Options for roleplay languages.
    .description = These options are related to roleplay languages.
        Players will be unable to fully understand messages sent in a language their character cannot speak.

config-Language-UseDefaultList =
    .type = { -checkbox }
    .toggle-inverse = Language.List
    .default = true
    .description = If this is enabled,
        the languages configured in the list will be ignored in favor of the default languages.

config-Language-List =
    .type = { -object-list }
    .max-items = 1000
    .no-label = true
    .full-page = true
    .pad-bottom = 16
    .description = Configuration for roleplay languages.

config-Language-List-Name =
    .type = { -string }

config-Language-List-Signed =
    .type = { -checkbox }
    .default = false

config-Language-DefaultSlots =
    .type = { -integer }
    .default = 1
    .min = 0
    .max = 50

config-Language-InterpretationRolls =
    .type = { -integer }
    .default = 2
    .min = 0
    .max = 10

config-Language-InterpretationChance =
    .type = { -integer }
    .pad-bottom = { -pad }
    .default = 25
    .min = 0
    .max = 100

config-Language-UnknownLanguageOverhead =
    .type = { -format-string }
    .tokens = { -tokens-overhead }
    .args = { -args-overhead };language;dialogueTag
    .pad-top = { -pad }

config-Language-UnknownLanguageChat =
    .type = { -format-string }
    .tokens = { -tokens-chat }
    .args = { -args-chat };language;dialogueTag

config-Language-UnknownLanguageRadio =
    .type = { -format-string }
    .tokens = { -tokens-chat }
    .args = { -args-chat }

config-Language-PlaceholderFormat =
    .type = { -format-string }
    .tokens = language;rawLanguage
    .pad-top = { -pad }
    .args = allowDefault
    .arg-allowDefault = arg-allowDefault-language-placeholder

config-Language-PlaceholderColor =
    .type = { -color }
    .default = 70,70,70
    .pad-bottom = { -pad }

config-Language-SelfAddAllowlist =
    .type = { -string-list }

config-Language-SelfAddBlocklist =
    .type = { -string-list }

## Macros

config-Macros =
    .type = { -container }
    .short-description = Options for macros.
    .description = These options control macros.
        <BR> Currently, the only built-in macro is the one used for [emote shortcuts](../user-guide/emote-shortcuts.md).

config-Macros-Enable =
    .type = { -page-checkbox }
    .default = true

config-Macros-BuiltIn =
    .type = { -checkbox-group }
    .default-all = true
    .options = Emote

## Mentions

config-Mentions =
    .type = { -container }
    .short-description = Options to control mentions.
    .description = These options control mentions.

config-Mentions-Enable =
    .type = { -page-checkbox }
    .default = true

config-Mentions-AlwaysUseNameColors =
    .type = { -page-checkbox }
    .default = true

config-Mentions-Range =
    .type = { -integer }
    .pad-top = { -pad }
    .default = 20
    .min = 0
    .max = 60

config-Mentions-ChatFormat =
    .type = { -format-string }
    .args = input
    .tokens = input;onlineID;stream;chatType

config-Mentions-OverheadFormat =
    .type = { -format-string }
    .args = input
    .tokens = input;onlineID;stream;chatType

## Narrative style

config-NarrativeStyle =
    .type = { -container }
    .short-description = Options to control narrative style.
    .description = These options control narrative style.
        If narrative style is used,
        messages will be enclosed in quotes and prefixed with a dialogue tag depending on the stream.
        <BR> For example, with the default settings,
        a message sent with `/yell Hey` will be transformed to `<Name> shouts, “Hey!”`.

config-NarrativeStyle-Enable =
    .type = { -page-checkbox }
    .default = true

config-NarrativeStyle-OverheadContentFormat =
    .type = { -format-string }
    .args = noComma
    .tokens = { -tokens-overhead }

config-NarrativeStyle-ChatContentFormat =
    .type = { -format-string }
    .args = noComma
    .tokens = { -tokens-chat }
    .pad-bottom = { -pad }

config-NarrativeStyle-DialogueTagFormat =
    .type = { -format-string }
    .args = loudTag;whisperTag;sneakCalloutTag;questionTag;exclamationTag;statementTag;shortStatementTag
    .tokens = { -tokens-overhead-no-narrative }

config-NarrativeStyle-InputFilter =
    .type = { -format-string }
    .args = input
    .tokens = { -tokens-overhead-no-narrative }

## Radio messages

config-Radio =
    .type = { -container }
    .short-description = Options to control radio messages.
    .description = These options control formatting of messages sent over the radio.

config-Radio-ChatFormat =
    .type = { -format-string }
    .tokens = { -tokens-chat };frequency

config-Radio-OverheadFormat =
    .type = { -format-string }
    .tokens = { -tokens-overhead };frequency

config-Radio-DefaultColor =
    .type = { -color }
    .default = 178,178,178

config-Radio-Tags =
    .type = { -tags }
    .default = NoVolumeIndicator

## Server messages

config-ServerMessages =
    .type = { -container }
    .short-description = Options to control server messages.
    .description = These options control formatting of server messages.

config-ServerMessages-ChatFormat =
    .type = { -format-string }
    .args = { -args-chat }
    .tokens = { -tokens-chat }

config-ServerMessages-DefaultColor =
    .type = { -color }
    .default = 0,128,255

config-ServerMessages-Tags =
    .type = { -tags }
    .default = NoTimestamp

## Streams

config-Streams =
    .type = { -container }
    .short-description = Configuration for custom streams.
    .description = These options control custom stream configuration.
        With the exception of [`Use Defaults`](#usedefaultlist) and [`Global Tags`](#globaltags),
        the options on this page are per-stream.

config-Streams-UseDefaultList =
    .type = { -checkbox }
    .toggle-inverse = Streams.List
    .default = true
    .description = If this is enabled,
        the streams configured in the list will be ignored in favor of the default streams.

config-Streams-List =
    .type = { -object-list }
    .max-items = 50
    .no-label = true
    .full-page = true
    .pad-bottom = 16
    .description = Configuration for chat streams.
        The options in this section are per-stream. <BR> Some options are not available for certain chat types;
        if this is the case, they will not be editable in the configuration menu.

config-Streams-List-Enable =
    .type = { -checkbox }
    .pad-bottom = { -pad }
    .default = true

config-Streams-List-Stream =
    .type = { -dropdown }
    .default = custom
    .options =
        custom;
        say;
        yell;
        private;
        faction;
        safehouse;
        general;
        admin;
        whisper;
        low;
        me;
        meloud;
        mequiet;
        mewhisper;
        do;
        doloud;
        doquiet;
        dowhisper;
        ooc

config-Streams-List-Name =
    .type = { -string }
    .extra-description = { -custom-stream-option }

config-Streams-List-Command =
    .type = { -string }

config-Streams-List-ShortCommand =
    .type = { -string }
    .pad-bottom = { -pad }

config-Streams-List-ChatType =
    .type = { -dropdown }
    .default = say
    .options =
        say;
        shout;
        faction;
        safehouse;
        whisper;
        general;
        admin
    .extra-description = { -custom-stream-option }

config-Streams-List-Category =
    .type = { -dropdown }
    .default = chat
    .options = chat;rp;other
    .extra-description = { -custom-stream-option }

config-Streams-List-DefaultColor =
    .type = { -color }

config-Streams-List-Range =
    .type = { -integer }
    .default = 30
    .min = 1
    .max = 60
    .extra-description = { -ranged-stream-option }

config-Streams-List-VerticalRange =
    .type = { -integer }
    .default = 2
    .min = 1
    .max = 32
    .extra-description = { -ranged-stream-option }

config-Streams-List-PerceptionRange =
    .type = { -integer }
    .default = 0
    .min = 0
    .max = 60
    .extra-description = { -ranged-stream-option }

config-Streams-List-PerceptionRangeSigned =
    .type = { -integer }
    .pad-bottom = { -pad }
    .default = 0
    .min = 0
    .max = 60
    .extra-description = { -ranged-stream-option }

config-Streams-List-ChatFormat =
    .type = { -format-string }
    .args = { -args-chat }
    .tokens = { -tokens-chat }

config-Streams-List-OverheadFormat =
    .type = { -format-string }
    .args = { -args-overhead }
    .tokens = { -tokens-overhead }
    .pad-bottom = { -pad }
    .extra-description = { -ranged-stream-option }

config-Streams-List-AllowBuffs =
    .type = { -checkbox }
    .default = false

config-Streams-List-AllowMentions =
    .type = { -checkbox }
    .default = false

config-Streams-List-AllowLanguages =
    .type = { -checkbox }
    .default = false

config-Streams-List-AllowTypingIndicator =
    .type = { -checkbox }
    .default = false

config-Streams-List-AttractZombies =
    .type = { -checkbox }
    .default = false
    .extra-description = { -ranged-stream-option }

config-Streams-List-UseNarrativeStyle =
    .type = { -checkbox }
    .pad-bottom = { -pad }
    .default = false

config-Streams-List-Tags =
    .type = { -tags }

config-Streams-List-Aliases =
    .type = { -string-list }
    .can-reorder = true
    .pad-bottom = { -pad }

config-Streams-GlobalTags =
    .type = { -tags }
    .default = ActionAsterisks;IncludeAdminIndicator

## Typing indicator

config-TypingIndicator =
    .type = { -container }
    .short-description = Options for the typing indicator.
    .description = These options control the typing indicator.

config-TypingIndicator-Enable =
    .type = { -page-checkbox }
    .default = true

config-TypingIndicator-Format =
    .type = { -format-string }
    .args = names
    .arg-names = arg-names-typing
    .tokens = alt;names
    .token-alt = token-alt-typing
    .token-names = token-names-typing

config-TypingIndicator-NameFormat =
    .type = { -format-string }
    .tokens = name;forename;surname;username

## Zombie attraction

config-ZombieAttraction =
    .type = { -container }
    .short-description = Options related to attracting zombies.
    .description = These options control attraction of zombies from chat messages.

config-ZombieAttraction-ChatRangeMultiplier =
    .type = { -number }
    .default = 0
    .min = 0
    .max = 10

config-ZombieAttraction-CalloutRange =
    .type = { -number }
    .default = 30
    .min = 1
    .max = 60

config-ZombieAttraction-SneakCalloutRange =
    .type = { -number }
    .default = 6
    .min = 1
    .max = 60
