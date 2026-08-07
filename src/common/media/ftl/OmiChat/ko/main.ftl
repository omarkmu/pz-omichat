### Various user-facing translations

## Chat formatting

radio = 라디오 ({ $frequency } MHz)

private-chat-to = { $name }에게 보낸 개인 메시지

private-chat-from = { KO_WITH_PARTICLE($name, type: "subj") } 보낸 개인 메시지

faction-radio = (조직 라디오)

safehouse-radio = (은신처 라디오)

over-radio = (라디오)

admin-indicator = (관리자)

placeholder-language-indicator = { KO_WITH_PARTICLE($language, type: "ro") } 말하고 있음

## Typing indicator

typing-1 = { KO_WITH_PARTICLE($name, type: "subj") } 입력하고 있습니다...

typing-2 = { KO_WITH_PARTICLE($name1, type: "gwa") } { KO_WITH_PARTICLE($name2, type: "subj") } 입력하고 있습니다...

typing-3 = { $name1 }, { KO_WITH_PARTICLE($name2, type: "gwa") }
    { KO_WITH_PARTICLE($name3, type: "subj") } 입력하고 있습니다...

typing-many = 여러 사람이 입력하고 있습니다...

## Command messages

command-card = { $name }{ KO_PARTICLE($rawName, type: "subj") }
    { KO_WITH_PARTICLE($card, type: "obj", numeral: "sino") } 뽑았습니다

command-card-global = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($card, type: "obj", numeral: "sino") } 뽑았습니다

command-roll = { $name }{ KO_PARTICLE($rawName, type: "subj") } { $sides }면 주사위를 굴려서
    { KO_WITH_PARTICLE($roll, type: "subj", numeral: "sino") } 나왔습니다

command-roll-global = { KO_WITH_PARTICLE($name, type: "subj") } { $sides }면 주사위를 굴려서
    { KO_WITH_PARTICLE($roll, type: "subj", numeral: "sino") } 나왔습니다

command-flip-heads = { $name }{ KO_PARTICLE($rawName, type: "subj") } 동전을 뒤집고 머리를 잡았습니다

command-flip-heads-global = { KO_WITH_PARTICLE($name, type: "subj") } 동전을 뒤집고 머리를 잡았습니다

command-flip-tails = { $name }{ KO_PARTICLE($rawName, type: "subj") } 동전을 뒤집고 꼬리를 잡았습니다

command-flip-tails-global = { KO_WITH_PARTICLE($name, type: "subj") } 동전을 뒤집고 꼬리를 잡았습니다

## Info messages

info-set-name-empty = 이름이 설정되지 않았습니다. '/name Name'을 사용하세요.

info-current-status = 현재 상태: { $status }

info-current-status-unset = 상태가 설정되지 않았습니다.

info-icon = '{ $name }'은(는) 다음 아이콘의 이름입니다. { $icon }

info-icon-unknown = '{ $name }'은(는) 알려진 아이콘 이름이 아닙니다.

info-icon-alias = '{ $alias }'은(는) 다음 아이콘의 이름인 '{ $name }'의 별칭입니다. { $icon }

info-clear = 콘솔을 지웠습니다

info-available-emotes = 사용가능한 이모티콘을:

info-available-emotes-with-macro = You can also trigger emotes in chat messages with !emote.

info-command-list = 사용 가능한 명령어:

info-available-dances = 사용 가능한 춤:

info-dance-unknown = 인식할 수 없는 춤을 입력했습니다. 사용가능한 춤 목록을 보려면, '/dance list'라고 입력하세요.

info-dance-unknown-recipe = 당신은 { $dance } 춤을 알지 못합니다. 사용가능한 춤 목록을 보려면, '/dance list'라고 입력하세요.

info-dance-missing-item =  { $dance } 춤을 사용하기 위해선 해당 춤 카드가 필요합니다.
    사용가능한 춤 목록을 보려면, '/dance list'라고 입력하세요.

## Success messages

success-set-name-self = 당신의 이름은 이제 '{ $name }' 입니다.

success-set-status-self = Your status has been set to '{ $status }'.

success-reset-name = 이름이 리셋되었습니다.

success-reset-status = 상태가 삭제되었습니다.

success-clear-names = 모든 닉네임이 삭제되었습니다.

success-set-name-other = '{ $name }'라는 이름이 '{ $username }' 플레이어에게 적용되었습니다.

success-reset-name-other = '{ $username }'의 이름이 리셋되었습니다.

success-set-icon-other = 플레이어 '{ $username }'의 이아콘을 설정했습니다.

success-reset-icon-other = 플레이어 '{ $username }'의 이아콘을 재설정했습니다.

success-add-language-other = 플레이어 '{ $username }'에게 '{ $language }' 롤플레이 언어를 추가했습니다.

success-reset-languages-other = 플레이어 '{ $username }'의 롤플레이 언어가 리셋되었습니다.

success-set-language-slots-other = 플레이어 '{ $username }'의 언어 슬롯이
    { KO_WITH_PARTICLE($slots, type: "ro") } 설정되었습니다.

## Error messages

error-invalid-name = '{ $name }'은 이름으로 사용할 수 없습니다.

error-invalid-status = Your status cannot be set to '{ $status }'.

error-signed-radio = 라디오에서는 수화를 사용할 수 없습니다.

error-signed-faction-radio = 조직 라디오에서는 수화를 사용할 수 없습니다.

error-signed-safehouse-radio = 은신처 라디오에서는 수화를 사용할 수 없습니다.

error-unknown-player = 플레이어 { KO_WITH_PARTICLE($username, type: "obj", wrap: "'") } 찾지 못했습니다.

error-switch-unknown-language = 알 수 없는 언어 { KO_WITH_PARTICLE($language, type: "ro", wrap: "'") } 전환할 수 없습니다.

error-too-many-shouts = 너무 깁니다. { $max }번까지 외침을 사용할 수 있습니다.

error-too-long-shout = 외칠 수 있는 단어수는 { $max }개 입니다.

error-add-language-full = 플레이어 { KO_WITH_PARTICLE($username, type: "subj", wrap: "'") } 이미 쵀대 롤플레이 언어
    수를 알고 있습니다.

error-add-language-known = 플레이어 { KO_WITH_PARTICLE($username, type: "subj", wrap: "'") }
    { KO_WITH_PARTICLE($language, type: "obj") } 이미 알고 있습니다.

error-add-language-not-configured = 설정에 '{ $language }' 언어가 포함되어 있지 않습니다.

error-language-unknown = 플레이어 { KO_WITH_PARTICLE($username, type: "subj", wrap: "'") }
    { KO_WITH_PARTICLE($language, type: "obj") } 모릅니다.

## Help text

help-text-emote = Trigger an emote animation. Example: /emote yes. To see a list of emotes, use /emote list

help-text-switch-language = 현재 활성 언어를 전환합니다. Example: /language Spanish

help-text-name = 이름을 설정하기위해, '/name Name'을 사용하세요. Example: /name Bob

help-text-name-full = 이름을 설정하기위해, '/name FirstName LastName'을 사용하세요. Example: /name Bob Smith

help-text-nickname = 채팅에 사용할 이름을 설정하기위해, '/nickname Name'을 사용하세요. Example: /nickname Bob

help-text-status = To set a status message, use: /status Description. To clear your status, use: /status clear

help-text-set-name = 플레이어의 채팅에 사용할 이름을 설정하려면 '/setname'을 사용하세요. Example: /setname username Name

help-text-reset-name = 플레이어의 이름을 재설정하려면 다음 커맨드를 입력하세요. Example: /resetname username

help-text-clear-names = 모든 채팅 이름을 지우려면 '/clearnames'을 사용하세요.

help-text-add-language = 플레이어에게 롤플레이 언어 추가하려면 다음 커맨드를 입력하세요. Example: /addlanguage username English

help-text-reset-languages = 플레이어의 롤플레이 언어를 지우려면 다음 커맨드를 입력하세요. Example: /resetlanguages username

help-text-set-language-slots = 플레이어가 가질 수 있는 롤플레이 언어의 양을 설정하려면 다음 커맨드를 입력하세요.
    입력은 1에서 50까지 사이여야 합니다.
    Example: /setlanguageslots username 5

help-text-set-icon = 플레이어의 아이콘을 설정하려면 다음 커맨드를 입력하세요. Example: /seticon username crowbar

help-text-reset-icon = 플레이어의 아이콘을 재설정하려면 다음 커맨드를 입력하세요. Example: /reseticon username

help-text-icon-info = 아이콘 이름 찾기위해, '/iconinfo'를 사용하세요. Example: /iconinfo plushspiffo

help-text-flip = 동전을 뒤집기 위해, '/flip'을 사용하세요.

help-text-dance = /dance 명령어를 사용하여 랜덤한 춤을 춰보세요. /dance 명령어와 특정 춤 이름을 입력하여 특정 춤을 춰보세요.
    사용가능한 춤 목록을 보려면, '/dance list'라고 입력하세요.

## Unknown language

unknown-language-no-author = { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 했습니다.

unknown-language-asks = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 질문을 물었습니다.

unknown-language-says = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 했습니다.

unknown-language-signs = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 수화를 했습니다.

unknown-language-states = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 했습니다.

unknown-language-shouts = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 소리쳤습니다.

unknown-language-hisses = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 크게 속삭였습니다.

unknown-language-exclaims = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 했습니다.

unknown-language-whispers = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 조용하게 했습니다.

unknown-language-whisper-shouts = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 말을 크게 속삭였습니다.

unknown-language-signed-whispers = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 수화를 몰래 했습니다.

unknown-language-signed-shouts = { KO_WITH_PARTICLE($name, type: "subj") }
    { KO_WITH_PARTICLE($language, type: "ro") } 무슨 수화를 활기차게 했습니다.

## Volume indicators

volume-indicator-low = 조용하게

volume-indicator-long = 시끄럽게

volume-indicator-loud = 시끄럽게

volume-indicator-whisper = 속삭임

## Perception range

out-of-range = 범위를 벗어남

perceived-chat = { KO_WITH_PARTICLE($name, type: "subj") } 무슨 말을 했습니다.

perceived-chat-whisper = { KO_WITH_PARTICLE($name, type: "subj") } 무슨 말을 조용하게 했습니다.

perceived-chat-quiet = { KO_WITH_PARTICLE($name, type: "subj") } 무슨 말을 조용하게 했습니다.

perceived-chat-loud = { KO_WITH_PARTICLE($name, type: "subj") } 무슨 말을 소리쳤습니다.

perceived-chat-signed = { $name } 무슨 수화를 했습니다.

perceived-chat-signed-whisper = { $name } 무슨 수화를 몰래 했습니다.

perceived-chat-signed-quiet = { $name } 무슨 수화를 몰래 했습니다.

perceived-chat-signed-loud = { $name } 무슨 수화를 활기차게 했습니다.

## Cards

card-name = { $suit } { $card }

card-ace = 에이스

card-jack = 잭

card-queen = 퀸

card-king = 킹

card-two = 2

card-three = 3

card-four = 4

card-five = 5

card-six = 6

card-seven = 7

card-eight = 8

card-nine = 9

card-ten = 10

card-suit-clubs = 클로버

card-suit-diamonds = 다이아몬드

card-suit-hearts = 하트

card-suit-spades = 스페이드

## Profile manager

message-type-radio = 라디오

message-type-server = 서버

profile-manager =
    .title = 프로필 관리
    .empty = 프로필이 없습니다.
    .default-profile-name = 프로필 { $index }
    .btn-create = 프로필 만들기
    .btn-delete = 프로필 삭제
    .btn-duplicate = 프로필 복사
    .label-color = { $command } 색
    .label-color-radio = 라디오 메시지 색
    .label-color-discord = Discord 메시지 색
    .label-color-server = 서버 메시지 색
    .label-color-name = 이름 색
    .label-color-speech = 말풍선 색
    .label-nickname = 채팅에 사용할 이름
    .label-profile-name = 프로필명
    .label-callouts = 외치기 말
    .label-sneak-callouts = 조용한 외치기 말
    .tooltip-callouts = 한 줄에 한 문장을 입력합니다.
    .tooltip-nickname = 이 프로필로 쓸 때 사용할 이름을 입력합니다.
    .tooltip-color = RGB 또는 16진수 형식의 색을 입력하여 { $type } 메시지에 사용되는 색을 설정합니다.
    .tooltip-color-name = RGB 또는 16진수 형식의 색을 입력하여 채팅 이름 색을 설정합니다.
    .tooltip-color-speech = RGB 또는 16진수 형식의 색을 입력하여 말풍선의 색을 설정합니다.
    .tooltip-max-profiles = 이미 최대 프로필 수가 있습니다.

## Player data manager

player-data-manager =
    .title = 오미챗 플레이어 데이터
    .editor-title = 데이터 편집
    .no-data = (값 없음)
    .column-username = 사용자 이름
    .column-nickname = 채팅 이름
    .column-status = Status
    .column-icon = 아이콘
    .column-currentLanguage = 현재 언어
    .column-languages = 아는 언어
    .column-languageSlots = 언어 슬롯

## Configuration presets

preset-custom = User-defined preset.

dialog-save-preset = Enter a name for the new preset.

dialog-confirm-delete-preset = Delete the { $name } custom preset? This cannot be undone.

save-preset-overwrite = Saving will overwrite the existing preset with this name.

status-preset = Applied values from the { $name } preset.

## Context menus

context-chat-settings = 채팅 설정

context-customization = 커스터마이징

context-languages = 롤플레이 언어

context-clean = 피와 먼지를 청소하기

context-hair-color = 염색하기
    .dialog = RGB 또는 16진수 형식의 색을 입력하여 머리 색을 설정합니다. 재설정하려면 아무것도 입력하지 마세요.

context-grow-hair = 머리 기르기

context-grow-beard = 수염 기르기

context-enable-name-colors = 이름 색 활성화

context-disable-name-colors = 이름 색 끄기

context-suggestions = 추천

context-suggestions-enable = 추천 활성화

context-suggestions-disable = 추천 끄기

context-suggestions-on-enter = Enter 키를 누른 후 삽입

context-suggestions-on-tab = Tab 키를 누른 후 삽입

context-enable-typing-indicator = 입력 표시기 활성화

context-disable-typing-indicator = 입력 표시기 끄기

context-retain-commands = 입력 유지

context-retain-commands-chat = 채팅

context-retain-commands-rp = 롤플레이

context-retain-commands-other = 기타

context-add-language = 언어 추가
    .dialog = { KO_WITH_PARTICLE($language, type: "obj") } 추가하시겠습니까? 되돌릴 수 없습니다.

context-sign-emotes-enable = 수화 애니매이션 활성화

context-sign-emotes-disable = 수화 애니매이션 끄기

context-sign-emotes-tooltip = 수어로 메시지를 보낼 때 애니메이션 재생 여부를 제어합니다.

context-profiles = 프로필 전환

context-profile-default = 기본 프로필

context-manage-profiles = 프로필 관리

context-admin = 관리자

context-admin-view-player-data = 데이터 관리

context-admin-open-settings = 설정
    .sandbox-tooltip = { -mod-name } does not use sandbox options for configuration. <BR>
        Click here to open the settings menu, which can also be accessed from the chat window's admin options.

context-admin-show-icon = 관리자 아이콘 표시

context-admin-know-all-languages = 모든 언어 이해

context-admin-ignore-message-range = 메시지 범위 무시

## Roleplay languages

language-arabic = 아랍어

language-asl = 수어

language-bengali = 벵골어

language-cantonese = 광둥어

language-catalan = 카탈루냐어

language-danish = 덴마크어

language-dutch = 네덜란드어

language-english = 영어

language-finnish = 핀란드어

language-french = 프랑스어

language-german = 독일어

language-gujarati = 구자라트어

language-hausa = 하우사어

language-hawaiian = 하와이어

language-hindi = 힌디어

language-hungarian = 헝가리어

language-italian = 이탈리아어

language-japanese = 일본어

language-javanese = 자와어

language-korean = 한국어

language-latvian = 라트비아어

language-malay = 말레이어

language-mandarin = 중국어

language-marathi = 마라티어

language-norwegian = 노르웨이어

language-persian = 페르시아어

language-polish = 폴란드어

language-portuguese = 포르투갈어

language-punjabi = 펀자브어

language-romanian = 루마니아어

language-russian = 러시아어

language-shanghainese = 상하이어

language-spanish = 스페인어

language-tagalog = 타갈로그어

language-tamil = 타밀어

language-telugu = 텔루구어

language-thai = 태국어

language-turkish = 튀르키예어

language-ukrainian = 우크라이나어

language-urdu = 우르두어

language-vietnamese = 베트남어
