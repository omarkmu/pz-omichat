# 1.0.0

- Initial release

# 0.6.1

- Fixed an issue where the `$input` token could have a stale value while formatting input for chat
    - This may have been intended initially to reference the original input, but it was applied inconsistently.
    It's better to just give it a meaning of "the input to this option."

# 0.6.0

### Added
- “Narrative style” as an ease-of-use feature for “Character says” style dialogue. This includes the new options:
    - `PredicateUseNarrativeStyle` to determine whether narrative style is used
    - `FilterNarrativeStyle` to transform input content before applying the style
    - `FormatNarrativeDialogueTag` to determine the dialogue tag used (“says”, “exclaims”, etc.)
    - `FormatNarrativePunctuation` to determine the punctuation used when none is included
- **Off-by-default** QoL options for parity with buffy's roleplay chat:
    - Character customization via `EnableCharacterCustomization`
    - Emote buffs via `PredicateApplyBuff` and `BuffCooldown`
- “Echo” functionality for `/safehouse` and `/faction` messages via `OverheadFormatEcho` and `ChatFormatEcho`
- Many other new options:
    - `FilterChatInput`, for transforming chat input to all chat streams
    - `PredicateAllowChatInput`, for determining whether chat input should be accepted
    - `FormatAliases`, for defining aliases for chat and command streams
    - `PredicateAttractZombies`, for configuring which streams attract zombies
    - `PredicateTransmitOverRadio`, to determine whether a message sent over the radio is displayed
    - `FormatOverheadPrefix`, for configuring the prefix of overhead messages
    - `FormatLanguage`, for formatting roleplay languages in chat
    - `OverheadFormatOther`, for controlling the overhead text of chat messages not covered by existing options
    - `RangeVertical`, for per-stream configurable chat ranges
    - `EnableDiscordColorOption`, for determining whether the color option for Discord messages is included
    - `EnableSetName`, which consolidates existing name options and adds new ones
    - `EnableCompatChatBubble` to prevent the chat bubble mod from creating visible messages in the chat window
    - `EnableCompatSearchPlayers` to show players' chat names in the context menu added by the Search Players For Weapons mod
- `/low` command and corresponding options
    - Messages sent on this stream will display prefixed with `[Low]` overhead by default
- `/shout` alias for `/yell`
- `FilterNickname` and `PredicateAllowChatInput` can set the `$error` or `$errorID` tokens to mark a failure and determine what displays
    - This enables showing feedback to the player as to why the input was rejected.
- `$issigned()` function for checking whether a roleplay language is signed
- `$colorquotes()` function for coloring quoted text in messages
- `$stripcolors()` function for removing rich text colors from messages
    - This will only remove colors defined with `<RGB>`, not `<PUSHRGB>`.
    The purpose of this function is removing colors players may have included in their message; these will always use the former.
- `$getunknownlanguagestring()` function to get a string to use for when a player doesn't speak a language
    - This replaces the `unknownLanguageString` token.
- `$escaperichtext()` function to escape input for use in rich text
- `$P` and `$PP` tokens to `FormatTimestamp`
- `$faction` token to `ChatFormatFaction`
- `$admin` token to chat formats
- Various tokens for overhead formats
- `StreamInfo` helper to improve access to stream information

### Fixed
- Fixed info button not displaying sometimes
- Fixed potential stack overflow from very, very long messages
- Fixed code to prevent empty messages from displaying
- Fixed `/pm` being broken by invisible formatting
- Custom admin commands now reject usernames that don't belong to any online players
    - Changing settings for players who aren't online wasn't a bug, it was a feature—really!—but it seemed likely to cause confusion.
- Chat spacing with `<SPACE>` is now context-based
    - In most cases, it should now appear how a regular space would. No more gigantic spaces in the small font!
- Players can no longer use chat after dying
- Sandbox option updates from the admin menu will now propagate to clients
    - This was already the case for most options, but those that required a restart should now support live-updating.
- Significantly decreased the likelihood of MetaFormatters matching on the wrong text

### Changed
- Default `/whisper` range is now 2 tiles
- `FormatTimestamp` default now uses zero-padded hour for 24-hour format
- Chat settings have been grouped into submenus
- `/dance` will now suggest available dances
- PM recipient names can now include name colors
- Improved death handling
    - Chat nicknames and icons will now be cleared on death, just like languages.
- Improved vanilla rich text panel
    - The text panel now allows commands without a leading space—this will make configuring options with `<SPACE>`, `<RGB>`, and other commands much easier.
    - Improper commands will no longer cause an error.
- `EnableCompatTAD` is now an enum option like the new compatibility options
- Renamed `/looc` to `/ooc` and renamed corresponding options
- Renamed `$hourFormatPref` token of `FormatTimestamp` to `$hourFormat`
- Renamed `FilterNickname` and `PredicateAllowLanguage` input tokens to `$input`
- `/pm` format will now be validated before attempting to send
    - No more strange vanilla error message that's styled as a global message.
- Radio messages in an unknown language will now be properly hidden overhead on radios

### Removed
- Removed `EnableSetName` (the old one) and `EnableChatNameAsCharacterName`
    - The new `EnableSetName` option includes the functionality of both.
- Removed the `stripColors` format option
    - This has been replaced by the `$stripcolors()` format string function.
    Server operators can use the function as they see fit, rather than having it hardcoded.
- Removed emote getters
    - Emotes added should now be string-to-string mappings exclusively.
- Removed `EnableCustomSneakShouts`
    - This is now covered by `EnableCustomShouts`.
- Removed the custom title ID for `/whisper`
    - Custom title IDs can still be configured via the API, but the local whisper will now use `[Local]` like other local chats.
- Soft-removed the icon picker.
    - This is “soft-removed” because the relevant code is still present. The `EnableIconPicker` and `EnableMiscellaneousIcons` options have been removed.
    - This will likely be added back in a future version with a better UI and implementation.

# 0.5.0
- Added roleplay languages and associated options
- Added `/addlanguage`, `/resetlanguages`, and `/setlanguageslots` admin commands
- Added final overhead chat format
- Added caching for interpolators
- Added support for chat icons, with `FormatIcon` format string & `/seticon`, `/reseticon`, and `/iconinfo` admin commands
- Added admin chat menu with options for displaying an icon in chat, understanding all languages, and ignoring message ranges
- Added support for randomization functions in format strings
- Improved `/card` messages for non-English languages
- Improved prevention of empty messages
- Custom commands will now be suggested
- Messages that shouldn't show over the radio are now hidden overhead too
- Whisper messages now display a `[Whispering]` prefix overhead by default
- `/card` and `/roll` messages will no longer use translations in overhead text by default
    - This is to avoid invisible text for players using in-game languages with different fonts.
    They will still be translated in chat.
- RP messages (e.g., `/me`) will now use angle brackets instead of guillemets in overhead text by default
    - This is for the same reason as the above; guillemets are invisible overhead for some languages (e.g., Korean).
    They will still display with guillemets in chat, for supported languages.
- MetaFormatter now requires an explicit ID

# 0.4.1
- Added translation for RP chat format
- Added Korean translations (thank you to 우로!)
- Fixed admin sandbox options menu

# 0.4.0
- Added `EnableFactionColorAsDefault` as an off-by-default option
- Added `RangeMultiplierZombies` option to change zombie attraction behavior of chat messages
- Added retain command options for players
- `/meloud` and `/doloud` commands can now attract zombies
- Client dispatch API functions no longer accept a player argument
- Message metadata tags and player preferences now use JSON
- Arbitrary commands will now only suggest usernames to players with an access level
- `/pm` command will no longer suggest the player's own username
- Fixed command suggester suggesting commands unavailable in the current chat tab
- Fixed message redraws not respecting `maxLine` setting
- Fixed message name colors not being constant if `EnableSetNameColor` is off
- Fixed radio message color option only showing if a radio is equipped and turned on

# 0.3.1
- Added clarification that radio messages can't be hidden overhead
- Radio messages can now only use `$frequency` and `$message` tokens

# 0.3.0
- Added `RangeCallout`, `RangeSneakCallout`, `RangeCalloutZombies`, and `RangeSneakCalloutZombies` options
- Improved default PM formats
- Fixed problems with `/pm` formatting

# 0.2.0
- Added local versions of `/card` and `/roll` and the following options to control them:
	- `ChatFormatCard`
	- `ChatFormatRoll`
	- `OverheadFormatCard`
	- `OverheadFormatRoll`
	- `FormatCard`
	- `FormatRoll`
- Added `ChatFormatFull` option to customize the final display of chat messages
- Added suggestion list and player preference to disable it
- Added `/setname`, `/resetname`, and `/clearnames` admin commands
- Added server API functions for manipulating nicknames and name colors
- Added chat info button and `FormatInfo` option to control info text content
- Added functionality to mimic various message types with `MimicMessage`
- Removed `MinimumColorValue` and `MaximumColorValue` options
- Removed `MessageFormatOptions.showInChat` in favor of the `setShowInChat` method on messages
- Faction and safehouse chats will no longer use usernames by default

# 0.1.0
- Added the following streams and corresponding sandbox options:
    - `/looc` (`/l`)
    - `/meloud` (`/ml`)
    - `/mequiet` (`/mq`)
    - `/do` (`/d`)
    - `/doloud` (`/dl`)
    - `/doquiet` (`/dq`)
- Added sandbox options to control default colors for all chat types
- Added parsing for named and numeric character references in format strings
- Enabled full format string functionality for overhead format strings
- Improved handling of `<` and `>` characters
- Renamed `/private` to `/pm`
- Renamed various sandbox options for consistency
- Removed `AllowMe` and `UseLocalWhisper` options
    - These chats can now be disabled by clearing `ChatFormatMe` and `ChatFormatWhisper`, respectively
- Removed `UseNameColorInAllChats` option
    - `PredicateUseNameColor` can be now be used to selectively enable name colors
- Removed the following options and changed them to always-on:
    - `AllowSetChatColors`
    - `UppercaseCustomShouts`
    - `LowercaseCustomSneakShouts`

# 0.0.1
- Fixed an error that occurred when clearing custom callouts
- Fixed bugs with names containing `<` or `>`

# 0.0.0
- Initial beta release
