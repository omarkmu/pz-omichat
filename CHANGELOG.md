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
