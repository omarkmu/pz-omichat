return {
    EnableCustomShouts = true,
    EnableEmotes = true,
    EnableSetNameColor = false,
    EnableSetSpeechColor = true,
    EnableSpeechColorAsDefaultNameColor = true,
    EnableFactionColorAsDefault = false,
    EnableCaseInsensitiveChatStreams = true,
    EnableCharacterCustomization = true,
    EnableCleanCharacter = 2,
    EnableSetName = 2,
    EnableDiscordColorOption = 3,
    EnableCompatBuffyRPGSystem = 3,
    EnableCompatChatBubble = 3,
    EnableCompatSearchPlayers = 3,
    EnableCompatTAD = 3,
    CardItems = "CardDeck",
    CoinItems = "",
    DiceItems = "Dice",
    PatternNarrativeCustomTag = "",
    BuffCooldown = 5,
    MaximumCustomShouts = 10,
    CustomShoutMaxLength = 50,
    MinimumCommandAccessLevel = 16,
    RangeCallout = 48,
    RangeSneakCallout = 6,
    RangeCalloutZombies = 30,
    RangeSneakCalloutZombies = 6,
    RangeMultiplierZombies = 0.0,
    RangeDo = 20,
    RangeDoLoud = 48,
    RangeDoQuiet = 4,
    RangeOoc = 20,
    RangeMe = 20,
    RangeMeLoud = 48,
    RangeMeQuiet = 4,
    RangeSay = 16,
    RangeLow = 4,
    RangeWhisper = 2,
    RangeYell = 48,
    RangeVertical = "@($sneakCallout:1;$index(@(@(shout;meloud;doloud):3;@(whisper;low;mequiet;doquiet):1) $stream 2))",
    ColorDiscord = "144 137 218",
    ColorRadio = "178 178 178",
    ColorServer = "0 128 255",
    ColorAdmin = "255 255 255",
    ColorGeneral = "255 165 0",
    ColorDo = "128 0 128",
    ColorDoLoud = "128 0 128",
    ColorDoQuiet = "128 0 128",
    ColorFaction = "22 113 20",
    ColorOoc = "48 128 128",
    ColorMe = "128 0 128",
    ColorMeLoud = "128 0 128",
    ColorMeQuiet = "128 0 128",
    ColorPrivate = "85 26 139",
    ColorSafehouse = "55 148 53",
    ColorSay = "177 210 187",
    ColorLow = "177 210 187",
    ColorWhisper = "177 210 187",
    ColorYell = "255 51 51",
    FilterChatInput = "$trim(@($eq($streamtype($stream) rp):$stripcolors($input);$input))",
    FilterNickname = "$sub($input 1 50)",
    FilterNarrativeStyle = "@($sneakCallout:$input;$capitalize($input))",
    PredicateEnableStream = "true",
    PredicateAllowChatInput = "$disallowSignedOverRadio($has(@(faction;safehouse) $stream))",
    PredicateAllowLanguage = "$has(@(say;shout;whisper;low;faction;safehouse) $stream)",
    PredicateApplyBuff = "$has(@(me;mequiet;meloud) $stream)",
    PredicateAttractZombies = "$has(@(say;shout;meloud;doloud) $stream)",
    PredicateClearOnDeath = "true",
    PredicateShowTypingIndicator = "",
    PredicateTransmitOverRadio = "$all($not($echo) $neq($customStream ooc))",
    PredicateUseNarrativeStyle = "$has(@(say;shout;whisper;low;faction;safehouse) $stream)",
    PredicateUseNameColor = "$not($has(@(general;faction;safehouse;admin;ooc) $stream))",
    AvailableLanguages = "English;French;Italian;German;Spanish;Danish;Dutch;Hungarian;Norwegian;Polish;Portuguese;Russian;Turkish;Japanese;Mandarin;Finnish;Korean;Thai;Ukrainian;ASL",
    SignedLanguages = "ASL",
    AddLanguageAllowlist = "",
    AddLanguageBlocklist = "",
    LanguageSlots = 1,
    InterpretationRolls = 2,
    InterpretationChance = 25,
    FormatAliases = "@(shout:shout;dolow:doquiet;dolong:doloud;melow:mequiet;melong:meloud)",
    FormatInfo = "",
    FormatName = "@($eq($chatType admin):$username;$if($eq($chatType whisper) $username ( / ))@($name;$forename))",
    FormatTag = "[$tag]$if($eq($chatType server) :<SPACE>)",
    FormatTimestamp = "[$ifelse($eq($hourFormat 12) $h $HH):$mm]",
    FormatMenuName = "$ifelse($neq($menuType mini_scoreboard) $name $username &#32;[ $name ])",
    FormatTyping = "$fmttyping($names $alt)",
    FormatCard = "draws $card.",
    FormatRoll = "rolls $roll on a $sides-sided die.",
    FormatFlip = "flips a coin and gets @($heads:heads;tails).",
    FormatAdminIcon = "Item_Hammer",
    FormatIcon = "@($eq($stream card):Item_CardDeck;$any($buffyRoll $eq($stream roll)):Item_Dice;$has(@(say;shout;whisper;faction;safehouse;ooc;general;low) $stream):@($adminIcon;$icon))",
    FormatLanguage = "$if($all($language $not($unknownLanguage)) [$language])",
    FormatOverheadPrefix = "$concats(( ) $if($languageRaw [$languageRaw]) $index(@(@(low;mequiet;doquiet):[Low];@(meloud;doloud):[Long];whisper:[Whisper]) $stream))&#32;",
    FormatChatPrefix = "$if($neq($stream server) $timestamp)$tag$language$index(@(@(low;mequiet;doquiet):[Low];@(meloud;doloud):[Long];whisper:$unless($sneakCallout [Whisper])) $stream)$unless($any($echo $not($icon) $has(@(faction;safehouse;admin) $stream)) $icon $if($admin $parens(Admin)))$buffyCrit",
    FormatNarrativeDialogueTag = "@($sneakCallout:whisper shouts;$eq($stream shout):shouts;$eq($stream whisper):whispers;$endswith($input ?):asks;$endswith($input !):exclaims;$endswith($input ..):says;$lt($len($input) 10):states;says)",
    FormatNarrativePunctuation = "$unless($sneakCallout @($eq($stream shout):!;.))",
    OverheadFormatFull = "$prefix$1",
    OverheadFormatDo = "** $capitalize($punctuate($1))",
    OverheadFormatDoLoud = "** $capitalize($punctuate($1))",
    OverheadFormatDoQuiet = "** $capitalize($punctuate($1))",
    OverheadFormatEcho = "(Over Radio) $1",
    OverheadFormatOoc = "(( $1 ))",
    OverheadFormatMe = "** $name $punctuate($1)",
    OverheadFormatMeLoud = "** $name $punctuate($1)",
    OverheadFormatMeQuiet = "** $name $punctuate($1)",
    OverheadFormatLow = "$name $1",
    OverheadFormatWhisper = "$name $1",
    OverheadFormatCard = "** $name $1",
    OverheadFormatRoll = "** $name $1",
    OverheadFormatFlip = "** $name $1",
    OverheadFormatOther = "$name $1",
    ChatFormatFull = "$if($prefix $prefix <SPACE>)$content",
    ChatFormatDiscord = "$author: <SPACE> $message",
    ChatFormatIncomingPrivate = "$fmtpmfrom(<SPACE>$name 2): <SPACE> $message",
    ChatFormatOutgoingPrivate = "$fmtpmto(<SPACE>$recipientName 2): <SPACE> $message",
    ChatFormatServer = "$message",
    ChatFormatRadio = "$fmtradio($frequency): <SPACE> $if($all($name $not($has(@(do;doloud;doquiet) $customStream))) $name<SPACE>)$message",
    ChatFormatAdmin = "$name: <SPACE> $message",
    ChatFormatCard = "** <SPACE> $name <SPACE> $punctuate($fmtcard($card))",
    ChatFormatRoll = "** <SPACE> $name <SPACE> $punctuate($fmtroll($roll $sides))",
    ChatFormatFlip = "** <SPACE> $name <SPACE> $punctuate($fmtflip($heads))",
    ChatFormatDo = "** <SPACE> $colorquotes($punctuate($capitalize($message)))",
    ChatFormatDoLoud = "** $colorquotes($punctuate($capitalize($message)))",
    ChatFormatDoQuiet = "** $colorquotes($punctuate($capitalize($message)))",
    ChatFormatGeneral = "$name: <SPACE> (( $message ))",
    ChatFormatOoc = "$name: <SPACE> (( $message ))",
    ChatFormatMe = "** <SPACE> $name <SPACE> $colorquotes($punctuate($message))",
    ChatFormatMeLoud = "** <SPACE> $name <SPACE> $colorquotes($punctuate($message))",
    ChatFormatMeQuiet = "** <SPACE> $name <SPACE> $colorquotes($punctuate($message))",
    ChatFormatSafehouse = "(Safehouse Radio) <SPACE>$if($icon $icon <SPACE>) $name <SPACE> $coloractions($message)",
    ChatFormatSay = "$name <SPACE> $coloractions($message)",
    ChatFormatFaction = "(Faction Radio) <SPACE>$if($icon $icon <SPACE>) $name <SPACE> $coloractions($message)",
    ChatFormatLow = "$name <SPACE> $coloractions($message mequiet)",
    ChatFormatWhisper = "$name <SPACE> $coloractions($message mequiet)",
    ChatFormatYell = "$name <SPACE> $coloractions($message meloud)",
    ChatFormatEcho = "(Over Radio) <SPACE>$if($icon $icon <SPACE>) $name <SPACE> $coloractions($message mequiet)",
    ChatFormatUnknownLanguage = "**$if($echo $parens(Over Radio)) <SPACE> $getunknownlanguagestring($languageRaw $stream $name<SPACE> $dialogueTag)",
    ChatFormatUnknownLanguageRadio = "$fmtradio($frequency): <SPACE> $getunknownlanguagestring($languageRaw $stream $if($all($name $not($has(@(do;doloud;doquiet) $customStream))) $name<SPACE>) $dialogueTag)",
}
