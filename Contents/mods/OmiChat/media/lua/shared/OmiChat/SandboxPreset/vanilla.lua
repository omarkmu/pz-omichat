return {
    EnableCustomShouts = false,
    EnableEmotes = false,
    EnableSetNameColor = false,
    EnableSetSpeechColor = false,
    EnableSpeechColorAsDefaultNameColor = false,
    EnableFactionColorAsDefault = false,
    EnableCaseInsensitiveChatStreams = false,
    EnableCharacterCustomization = false,
    EnableCleanCharacter = 3,
    EnableSetName = 1,
    EnableDiscordColorOption = 3,
    EnableCompatBuffyRPGSystem = 2,
    EnableCompatChatBubble = 2,
    EnableCompatSearchPlayers = 2,
    EnableCompatTAD = 2,
    CardItems = "CardDeck",
    CoinItems = "",
    DiceItems = "Dice",
    PatternNarrativeCustomTag = "",
    BuffCooldown = 15,
    MaximumCustomShouts = 10,
    CustomShoutMaxLength = 50,
    MinimumCommandAccessLevel = 16,
    RangeCallout = 60,
    RangeSneakCallout = 6,
    RangeCalloutZombies = 30,
    RangeSneakCalloutZombies = 6,
    RangeMultiplierZombies = 0.0,
    RangeDo = 30,
    RangeDoLoud = 60,
    RangeDoQuiet = 3,
    RangeOoc = 30,
    RangeMe = 30,
    RangeMeLoud = 60,
    RangeMeQuiet = 3,
    RangeSay = 30,
    RangeLow = 5,
    RangeWhisper = 2,
    RangeYell = 60,
    RangeVertical = "32",
    ColorDiscord = "144 137 218",
    ColorRadio = "178 178 178",
    ColorServer = "0 128 255",
    ColorAdmin = "255 255 255",
    ColorGeneral = "255 165 0",
    ColorDo = "130 130 130",
    ColorDoLoud = "255 51 51",
    ColorDoQuiet = "85 48 139",
    ColorFaction = "22 113 20",
    ColorOoc = "48 128 128",
    ColorMe = "130 130 130",
    ColorMeLoud = "255 51 51",
    ColorMeQuiet = "85 48 139",
    ColorPrivate = "85 26 139",
    ColorSafehouse = "55 148 53",
    ColorSay = "255 255 255",
    ColorLow = "85 48 139",
    ColorWhisper = "85 48 139",
    ColorYell = "255 51 51",
    FilterChatInput = "$trim($input)",
    FilterNickname = "$sub($input 1 50)",
    FilterNarrativeStyle = "@($sneakCallout:$input;$capitalize($input))",
    PredicateEnableStream = "true",
    PredicateAllowChatInput = "true",
    PredicateAllowLanguage = "",
    PredicateApplyBuff = "",
    PredicateAttractZombies = "$has(@(say;shout;meloud;doloud) $stream)",
    PredicateShowTypingIndicator = "",
    PredicateTransmitOverRadio = "true",
    PredicateUseNarrativeStyle = "",
    PredicateUseNameColor = "",
    AvailableLanguages = "",
    SignedLanguages = "",
    AddLanguageAllowlist = "",
    AddLanguageBlocklist = "",
    LanguageSlots = 1,
    InterpretationRolls = 0,
    InterpretationChance = 25,
    FormatAliases = "",
    FormatInfo = "",
    FormatName = "$username",
    FormatTag = "[$tag]$if($eq($chatType server) (: <SPACE> ))",
    FormatTimestamp = "[$ifelse($eq($hourFormat 12) $h $HH):$mm]",
    FormatMenuName = "",
    FormatTyping = "$fmttyping($names $alt)",
    FormatCard = "draws $card",
    FormatRoll = "rolls $roll on a $sides-sided die",
    FormatFlip = "flips a coin and gets @($heads:heads;tails)",
    FormatAdminIcon = "Item_Sledgehamer",
    FormatIcon = "@($eq($stream card):Item_CardDeck;$any($buffyRoll $eq($stream roll)):Item_Dice;$has(@(say;shout;whisper;faction;safehouse;ooc;general) $stream):@($adminIcon;$icon))",
    FormatLanguage = "",
    FormatOverheadPrefix = "",
    FormatChatPrefix = "$if($icon $icon <SPACE>)$if($neq($stream server) $timestamp)$tag$language$if($buffyCrit $buffyCrit ( <SPACE>))",
    FormatNarrativeDialogueTag = "@($sneakCallout:hisses;$eq($stream shout):shouts;$eq($stream whisper):whispers;$endswith($input ?):asks;$endswith($input !):exclaims;$endswith($input ..):says;$lt($len($input) 10):states;says)",
    FormatNarrativePunctuation = "$unless($sneakCallout @($eq($stream shout):!;.))",
    OverheadFormatFull = "$prefix$1",
    OverheadFormatDo = "",
    OverheadFormatDoLoud = "",
    OverheadFormatDoQuiet = "",
    OverheadFormatEcho = "(Over Radio) $1",
    OverheadFormatOoc = "(( $1 ))",
    OverheadFormatMe = "<< $1 >>",
    OverheadFormatMeLoud = "<< $1 >>",
    OverheadFormatMeQuiet = "<< $1 >>",
    OverheadFormatLow = "$1",
    OverheadFormatWhisper = "$1",
    OverheadFormatCard = "<< $1 >>",
    OverheadFormatRoll = "<< $1 >>",
    OverheadFormatFlip = "<< $1 >>",
    OverheadFormatOther = "$1",
    ChatFormatFull = "$prefix$content",
    ChatFormatDiscord = "[$author]: <SPACE> $message",
    ChatFormatIncomingPrivate = "[$name]: <SPACE> $message",
    ChatFormatOutgoingPrivate = "[to $recipientName]: <SPACE> $message",
    ChatFormatServer = "$message",
    ChatFormatRadio = "$fmtradio($frequency): <SPACE> $message",
    ChatFormatAdmin = "[$name]: <SPACE> $message",
    ChatFormatCard = "",
    ChatFormatRoll = "",
    ChatFormatFlip = "",
    ChatFormatDo = "",
    ChatFormatDoLoud = "",
    ChatFormatDoQuiet = "",
    ChatFormatGeneral = "[$name]: <SPACE> $message",
    ChatFormatOoc = "",
    ChatFormatMe = "",
    ChatFormatMeLoud = "",
    ChatFormatMeQuiet = "",
    ChatFormatSafehouse = "[$name]: <SPACE> $message",
    ChatFormatSay = "[$name]$unless($buffyRoll :) <SPACE> $message",
    ChatFormatFaction = "[$name]: <SPACE> $message",
    ChatFormatLow = "",
    ChatFormatWhisper = "",
    ChatFormatYell = "[$name]: <SPACE> $message",
    ChatFormatEcho = "",
    ChatFormatUnknownLanguage = "",
    ChatFormatUnknownLanguageRadio = "",
}
