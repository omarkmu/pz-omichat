# Changelog

## 1.3.0

### Added
- `$coloractions()` interpolator function to apply `/me` formatting to actions within a message
    - This has been added to the buffy preset; see that preset for an example.
- `PredicateClearOnDeath` sandbox option to control which mod data fields are cleared on player death

### Fixed
- Admins can now see typing indicators for visible players while invisible
- Typing indicators for faction and safehouse chats (if enabled for those streams) will now only show for members of the faction or safehouse
- Fixed a visual issue with the admin mod data viewer

## 1.2.0

### Added
- Player preference profiles
    - These allow for switching between sets of player preferences.
    Profiles include the chat nickname, shout text, and chat colors.
    This may be useful for playing multiple characters with different speech colors, or for switching between chat “themes.”
- Player preferences to control how suggestions are entered
    - Tab and Enter can be toggled individually.
    If both are disabled, suggestions will only be entered on click.
- Typing indicator controlled by the new options `PredicateShowTypingIndicator` and `FormatTyping`
	- This defaults to **off**; to use this feature, the predicate option must be set.
    To enable typing indicators for ranged streams only (recommended), set `PredicateShowTypingIndicator` to `$isRanged`.
- API functionality for adding emote handler functions
    - This enables emote shortcuts that use something other than `playEmote`.
- Mod data management menu for admins
	- This allows setting mod data for both online and offline players.
    It includes chat nickname, name color, languages, and language slots.
- Compatibility patch for buffy's tabletop roleplay system
    - This populates the tokens `$buffyRoll`, `$buffyCrit`, and `$buffyCritRaw`.
    See the documentation for details.
    - Unlike other compatibility patches, this defaults to **off**.
    This is because there is recommended setup to perform before enabling the patch.
    - To enable the patch for existing settings:
        1. If you're using a preset without any changes, re-apply the preset from the in-game sandbox options menu and skip to the last step.
        2. Modify the `FormatIcon` option to use the dice icon when the message is a roll.
        If you're using a value from one of the presets, you can replace `$eq($stream roll)` with `$any($buffyRoll $eq($stream roll))`.
        3. Modify the `FormatChatPrefix` option to include the critical roll indicator with `$buffyCrit`.
        This can be placed anywhere; if your settings are based on the buffy preset, you can add `$buffyCrit` to the end.
        Otherwise, see the presets for examples.
        4. Set the `EnableCompatBuffyRPGSystem` option to `Enable` or `Enable if mod is enabled`.
- Conversion for strings deprecated in this release and the previous release
    - This should handle automatically updating the outdated values, but relevant options should still be updated.
	The conversion will be removed in a future version.

### Changed
- Chat streams are now case-insensitive by default
	- This can be reverted by disabling the new `EnableCaseInsensitiveChatStreams` option.
- Improved the in-game admin sandbox options menu
	- All options now have tooltips.
	- Options have been organized into sections.
	- Color options include a color selector.
	- Presets can now be applied from this menu.
- Merged the chat customization and character customization setting menus
- The `FormatNarrativePunctuation` option now includes the `$dialogueTag` token
- Faction/safehouse echo messages will no longer display if the player would have seen the original message
- Normalized string names

### Deprecated
- Deprecated two more strings that were in use by presets
	- `UI_OmiChat_error_signed_faction_radio`: use `$disallowsignedoverradio(...)`
	- `UI_OmiChat_error_signed_safehouse_radio`: use `$disallowsignedoverradio(...)`

### Fixed
- Fixed the string key for `UI_OmiChat_Error_CommandCooldown1` in English

## 1.1.1

### Fixed
- `/roll` now respects the correct sandbox option for items

## 1.1.0

### Added
- French translation (thank you to [Inkredibehl](https://github.com/Inkredibehl)!)
- `/flip` command for coin flips and corresponding options
- `/language` command for quickly switching active language
- Options to control which items are required for `/roll`, `/card`, and `/flip` commands
    - `DiceItems`, `CardItems`, and `CoinItems`.
- `PatternNarrativeCustomTag` option to allow players to specify custom dialogue tags in narrative style
- `EnableCleanCharacter` option to customize behavior of the “clean blood & dirt” option
- `PredicateEnableStream` option to control which streams are enabled
- API functions for adding and removing custom chat buttons
- API functions for adding chat settings
- API support for icons at the message level
    - Message level icons override player icons and the admin icon.
- Stream callback for using a disabled stream
- Improved relevancy of command suggestions
    - The chat can now suggest languages (for `/addlanguage` and `/language`) and perks (for `/addxp`), among other command inputs.
    - The API function `addSuggesterArgType` has also been added to allow extension with more argument types.
- Chance to understand partial messages in other languages (buffy parity)
    - This can be configured with the new `InterpretationRolls` and `InterpretationChance` options.
- Allow/block lists to define a subset of the available languages that can be added by players directly (`AddLanguageAllowlist` and `AddLanguageBlocklist`)
- New format string functions for ease-of-use
    - `$cooldown()`
    - `$cooldownset()`
    - `$cooldownif()`
    - `$cooldownunless()`
    - `$cooldownremaining()`
    - `$disallowsignedoverradio()`
    - `$isadmin()`
    - `$iscoophost()`
    - `$accesslevel()`
    - `$fmtcard()`
    - `$fmtroll()`
    - `$fmtflip()`
    - `$fmtradio()`
    - `$fmtrp()`
    - `$fmtpmfrom()`
    - `$fmtpmto()`
    - `$parens()`
    - `$streamtype()`
- Default translations for more roleplay languages (not added as defaults in `AvailableLanguages`)
    - Catalan
    - Gujarati
    - Hausa
    - Hawaiian
    - Latvian
    - Malay
    - Persian
    - Romanian
    - Tagalog

### Changed
- Increased the maximum configured languages from 32 to 1000
    - No one should configure that many roleplay languages, but now you can!
- Increase the maximum for player language slots from 32 to 50
- Spaces will now be replaced with underscores when retrieving translations for language names
- Improved encoding of command arguments and added new utility functions for encoding them
- Improved disabled command message for chat streams
- Buffs now include fatigue
- Slightly increased buff strength for hunger and thirst

### Deprecated
- Deprecated the `command` field to stream use callbacks in favor of `text`
- Deprecated `suggestUsernames` and `suggestOwnUsername` stream configuration fields in favor of suggestion specs
- Deprecated the `CustomShoutMaxLength` and `MaximumCustomShouts` options; these will be hardcoded in a future version
- Deprecated strings that were in use by presets; these will be removed in a future version
    - `UI_OmiChat_card_local`: use `$fmtCard(card)`
    - `UI_OmiChat_roll_local`: use `$fmtRoll(roll sides)`
    - `UI_OmiChat_radio`: use `$fmtRadio(frequency)`
    - `UI_OmiChat_rp_emote`: use `$fmtRP(...)`
    - `UI_OmiChat_private_chat_from`: use `$fmtPMFrom(name parenCount)`
    - `UI_OmiChat_private_chat_to`: use `$fmtPMTo(name parenCount)`

### Fixed
- Fixed a mix-up in the Korean translations for “says” vs. “asks”
- Fixed the “clean blood & dirt” option not changing the dirty/bloody bar in the inventory
- Fixed a problem in the Search Players for Weapons compatibility patch that could cause a repeat info message
- Fixed a typo in `OmiChat.setRoleplayLanguageSlots`
- Fixed an issue that could cause retain options to not be respected
- Fixed command streams not being case-insensitive
    - Command streams such as `/roll` are case-insensitive in vanilla (`/ROLL` is treated as equivalent).
    This is not the case for chat streams like `/say`.

## 1.0.0

- Initial release

## 0.6.1

### Fixed
- Fixed an issue where the `$input` token could have a stale value while formatting input for chat
    - This may have been intended initially to reference the original input, but it was applied inconsistently.
    It's better to just give it a meaning of "the input to this option."

## 0.6.0

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

## 0.5.0

### Added
- Added roleplay languages and associated options
- Added `/addlanguage`, `/resetlanguages`, and `/setlanguageslots` admin commands
- Added final overhead chat format
- Added caching for interpolators
- Added support for chat icons, with `FormatIcon` format string & `/seticon`, `/reseticon`, and `/iconinfo` admin commands
- Added admin chat menu with options for displaying an icon in chat, understanding all languages, and ignoring message ranges
- Added support for randomization functions in format strings

### Changed
- Improved `/card` messages for non-English languages
- Improved prevention of empty messages
- Custom commands will now be suggested
- Whisper messages now display a `[Whispering]` prefix overhead by default
- `/card` and `/roll` messages will no longer use translations in overhead text by default
    - This is to avoid invisible text for players using in-game languages with different fonts.
    They will still be translated in chat.
- RP messages (e.g., `/me`) will now use angle brackets instead of guillemets in overhead text by default
    - This is for the same reason as the above; guillemets are invisible overhead for some languages (e.g., Korean).
    They will still display with guillemets in chat, for supported languages.
- MetaFormatter now requires an explicit ID

### Fixed
- Messages that shouldn't show over the radio are now hidden overhead too

## 0.4.1
- Added translation for RP chat format
- Added Korean translations (thank you to 우로!)
- Fixed admin sandbox options menu

## 0.4.0

### Added
- Added `EnableFactionColorAsDefault` as an off-by-default option
- Added `RangeMultiplierZombies` option to change zombie attraction behavior of chat messages
- Added retain command options for players

### Changed
- `/meloud` and `/doloud` commands can now attract zombies
- Client dispatch API functions no longer accept a player argument
- Message metadata tags and player preferences now use JSON
- Arbitrary commands will now only suggest usernames to players with an access level
- `/pm` command will no longer suggest the player's own username

### Fixed
- Fixed command suggester suggesting commands unavailable in the current chat tab
- Fixed message redraws not respecting `maxLine` setting
- Fixed message name colors not being constant if `EnableSetNameColor` is off
- Fixed radio message color option only showing if a radio is equipped and turned on

## 0.3.1
- Added clarification that radio messages can't be hidden overhead
- Radio messages can now only use `$frequency` and `$message` tokens

## 0.3.0
- Added `RangeCallout`, `RangeSneakCallout`, `RangeCalloutZombies`, and `RangeSneakCalloutZombies` options
- Improved default PM formats
- Fixed problems with `/pm` formatting

## 0.2.0

### Added
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

### Changed
- Faction and safehouse chats will no longer use usernames by default

### Removed
- Removed `MinimumColorValue` and `MaximumColorValue` options
- Removed `MessageFormatOptions.showInChat` in favor of the `setShowInChat` method on messages

## 0.1.0

### Added
- Added the following streams and corresponding sandbox options:
    - `/looc` (`/l`)
    - `/meloud` (`/ml`)
    - `/mequiet` (`/mq`)
    - `/do` (`/d`)
    - `/doloud` (`/dl`)
    - `/doquiet` (`/dq`)
- Added sandbox options to control default colors for all chat types
- Added parsing for named and numeric character references in format strings

### Changed
- Enabled full format string functionality for overhead format strings
- Improved handling of `<` and `>` characters
- Renamed `/private` to `/pm`
- Renamed various sandbox options for consistency

### Removed
- Removed `AllowMe` and `UseLocalWhisper` options
    - These chats can now be disabled by clearing `ChatFormatMe` and `ChatFormatWhisper`, respectively
- Removed `UseNameColorInAllChats` option
    - `PredicateUseNameColor` can be now be used to selectively enable name colors
- Removed the following options and changed them to always-on:
    - `AllowSetChatColors`
    - `UppercaseCustomShouts`
    - `LowercaseCustomSneakShouts`

## 0.0.1
- Fixed an error that occurred when clearing custom callouts
- Fixed bugs with names containing `<` or `>`

## 0.0.0
- Initial beta release
