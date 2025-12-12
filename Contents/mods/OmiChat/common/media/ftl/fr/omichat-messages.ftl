### Various user-facing translations

## Chat formatting

# @expect-identical
radio = Radio ({ $frequency } MHz)

private-chat-to = MP à { $name }

private-chat-from = MP de { $name }

faction-radio = (Radio de Faction)

safehouse-radio = (Radio de Refuge)

over-radio = (À la Radio)

admin-indicator = (Administrateur)

## Typing indicator

typing-1 = { $name } est en train d'écrire...

typing-2 = { $name1 } et { $name2 } sont en train d'écrire...

typing-3 = { $name1 }, { $name2 }, et { $name3 } sont en train d'écrire...

typing-many = Plusieurs personnes sont en train d'écrire...

## Command messages

command-card = { $name } tire { $card }

command-card-global = { $name } a tiré { $card }

command-roll = { $name } lance { $roll } sur un dé à { $sides } faces

command-roll-global = { $name } a lancé un { $roll } sur un dé à { $sides } faces

command-flip-heads = { $name } lance une pièce de monnaie et obtient face

command-flip-heads-global = { $name } a lancé une pièce de monnaie et a obtenu face

command-flip-tails = { $name } lance une pièce de monnaie et obtient pile

command-flip-tails-global = { $name } a lancé une pièce de monnaie et a obtenu pile

## Info messages

info-set-name-empty = Aucun nom spécifié. Utilisez /name Nom

info-current-status = Current status: { $status }

info-current-status-unset = No status is set.

info-icon = '{ $name }' est le nom de l'icône pour : { $icon }

info-icon-unknown = '{ $name }' n'est pas un nom d'icône connu.

info-icon-alias = '{ $alias }' est un alias pour '{ $name }', le nom de l'icône pour : { $icon }

info-clear = Console effacée

info-available-emotes = Émoticônes disponibles :

info-available-emotes-with-macro = You can also trigger emotes in chat messages with !emote.

info-command-list = Liste des commandes :

info-available-dances = Danses disponibles :

info-dance-unknown = Danse inconnue. Utilisez '/dance list' pour voir les danses disponibles.

info-dance-unknown-recipe = Vous ne connaissez pas la danse { $dance }.
    Utilisez '/dance list' pour voir les danses disponibles.

info-dance-missing-item = Vous avez besoin d'une carte de danse pour faire la danse { $dance }.
    Utilisez '/dance list' pour voir les danses disponibles.

## Success messages

success-set-name-self = Votre nom est désormais '{ $name }'.

success-set-status-self = Your status has been set to '{ $status }'.

success-reset-name = Votre nom a été réinitialisé.

success-reset-status = Your status has been cleared.

success-clear-names = Tous les pseudonymes ont été effacés.

success-switch-language = Langue active basculée vers { $language }.

success-set-name-other = Le nom a été défini sur '{ $name }' pour le joueur '{ $username }'.

success-reset-name-other = Le nom a été réinitialisé pour le joueur '{ $username }'.

success-set-icon-other = L'icône a été définie pour le joueur '{ $username }'.

success-reset-icon-other = L'icône a été réinitialisée pour le joueur '{ $username }'.

success-add-language-other = Langue de jeu de rôle '{ $language }' ajoutée au joueur '{ $username }'.

success-reset-languages-other = Les langues de jeu de rôle ont été réinitialisées pour le joueur '{ $username }'.

success-set-language-slots-other = Les emplacements de langue ont été définis sur { $slots }
    pour le joueur '{ $username }'.

## Error messages

error-invalid-name = Votre nom ne peut pas être défini sur '{ $name }'.

error-invalid-status = Your status cannot be set to '{ $status }'.

error-signed-radio = Vous ne pouvez pas utiliser la langue des signes via la radio.

error-signed-faction-radio = Vous ne pouvez pas utiliser la langue des signes via la radio de faction.

error-signed-safehouse-radio = Vous ne pouvez pas utiliser la langue des signes via la radio de refuge.

error-unknown-player = Impossible de trouver le joueur '{ $username }'.

error-switch-unknown-language = Impossible de passer à la langue inconnue '{ $language }'.

error-too-many-shouts = Trop de lignes ; jusqu'à { $max } cris personnalisés peuvent être spécifiés.

error-too-long-shout = Le texte du cri ne peut comporter que { $max } caractères au maximum.

error-add-language-full = Le joueur '{ $username }' connaît déjà le nombre maximal de langues.

error-add-language-known = Le joueur '{ $username }' connaît déjà { $language }.

error-add-language-not-configured = '{ $language }' n'est pas une langue configurée.

error-language-unknown = Le joueur '{ $username }' ne connaît pas { $language }.

## Help text

help-text-emote = Trigger an emote animation. Example: /emote yes. To see a list of emotes, use /emote list

help-text-switch-language = Changer votre langue active. Exemple : /language Spanish

help-text-name = Pour définir votre nom, utilisez : /name Nom. Exemple : /name Bob

help-text-name-full = Pour définir votre nom, utilisez : /name Prénom Nom. Exemple : /name Bob Smith

help-text-nickname = Pour définir votre nom dans la discussion, utilisez : /nickname Nom. Exemple : /name Bob

help-text-status = To set a status message, use: /status Description. To clear your status, use: /status clear

help-text-set-name = Définir le nom d'un joueur dans la discussion. Exemple : /setname nom_utilisateur Nom

help-text-reset-name = Réinitialiser le nom d'un joueur dans la discussion. Exemple : /resetname nom_utilisateur

help-text-clear-names = Efface tous les noms de chat des joueurs. Utilisez /clearnames

help-text-add-language = Ajoutez à la liste des langues de jeu de rôle d'un joueur.
    Exemple : /addlanguage nom_utilisateur English

help-text-reset-languages = Réinitialisez les langues de jeu de rôle d'un joueur.
    Exemple : /resetlanguages nom_utilisateur

help-text-set-language-slots = Définissez le nombre de créneaux de langue de jeu de rôle pour un joueur.
    Les créneaux doivent être compris entre 1 et 50. Exemple : /setlanguageslots nom_utilisateur 5

help-text-set-icon = Définissez l'icône de discussion d'un joueur. Exemple : /seticon nom_utilisateur crowbar

help-text-reset-icon = Réinitialisez l'icône de discussion d'un joueur. Exemple : /reseticon nom_utilisateur

help-text-icon-info = Obtenez le nom correct d'une icône, à utiliser dans les chaînes de format.
    Exemple : /iconinfo plushspiffo
help-text-flip = Lancez une pièce de monnaie. Utilisez /flip

help-text-dance = Utilisez /dance pour faire une danse aléatoire.
    Utilisez /dance suivi du nom de la danse pour faire une danse spécifique.
    Pour voir une liste de danses, utilisez /dance list

## Unknown language

unknown-language-no-author = Quelque chose est dit en { $language }.

unknown-language-asks = { $name } demande quelque chose en { $language }.

unknown-language-says = { $name } dit quelque chose en { $language }.

unknown-language-signs = { $name } signe quelque chose en { $language }.

unknown-language-states = { $name } déclare quelque chose en { $language }.

unknown-language-shouts = { $name } crie quelque chose en { $language }.

unknown-language-hisses = { $name } siffle quelque chose en { $language }.

unknown-language-exclaims = { $name } s'exclame quelque chose en { $language }.

unknown-language-whispers = { $name } chuchote quelque chose en { $language }.

unknown-language-whisper-shouts = { $name } chuchote quelque chose en { $language }.

unknown-language-signed-whispers = { $name } signe subtilement quelque chose en { $language }.

unknown-language-signed-shouts = { $name } signe énergiquement quelque chose en { $language }.

## Volume indicators

volume-indicator-low = Low

volume-indicator-long = Long

volume-indicator-loud = Loud

volume-indicator-whisper = Whisper

## Perception range

out-of-range = Out of Range

perceived-chat = { $name } says something.

perceived-chat-whisper = { $name } whispers something.

perceived-chat-quiet = { $name } says something quietly.

perceived-chat-loud = { $name } shouts something.

perceived-chat-signed = { $name } signs something.

perceived-chat-signed-whisper = { $name } subtly signs something.

perceived-chat-signed-quiet = { $name } signs something quietly.

perceived-chat-signed-loud = { $name } energetically signs something.

## Cards

card-name = { $card } de { $suit }

card-ace = l'As

card-jack = le Valet

card-queen = la Dame

card-king = le Roi

card-two = un Deux

card-three = un Trois

card-four = un Quatre

card-five = un Cinq

card-six = un Six

card-seven = un Sept

card-eight = un Huit

card-nine = un Neuf

card-ten = un Dix

card-suit-clubs = Trèfles

card-suit-diamonds = Carreaux

card-suit-hearts = Cœurs

card-suit-spades = Piques

## Profile manager

# @expect-identical
message-type-radio = radio

message-type-server = serveur

profile-manager =
    .title = Gestionnaire de Profil
    .empty = Vous n'avez aucun profil.
    .default-profile-name = Profil { $index }
    .btn-create = Créer un Nouveau Profil
    .btn-delete = Supprimer le Profil
    .btn-duplicate = Dupliquer le Profil
    .label-color = Couleur de { $command }
    .label-color-radio = Couleur du message radio
    .label-color-discord = Couleur du message Discord
    .label-color-server = Couleur du message du serveur
    .label-color-name = Couleur du nom
    .label-color-speech = Couleur de la parole
    .label-nickname = Pseudo de chat
    .label-profile-name = Nom du profil
    .label-callouts = Appels
    .label-sneak-callouts = Appels furtifs
    .tooltip-callouts = Entrez un appel par ligne.
    .tooltip-nickname = Entrez un pseudo à utiliser lorsque vous passez à ce profil.
    .tooltip-color = Entrez une couleur en format RGB ou hex pour définir la couleur utilisée
        pour les messages de { $type }.
    .tooltip-color-name = Entrez une couleur en format RGB ou hex pour définir la couleur de votre nom dans le chat.
    .tooltip-color-speech = Entrez une couleur en format RGB ou hex pour définir la couleur de vos bulles de discours.
    .tooltip-max-profiles = Vous avez déjà le nombre maximum de profils.

## Player data manager

player-data-manager =
    .title = OmiChat Player Data
    .editor-title = Edit Player Data
    .no-data = (vide)
    .column-username = Nom d'utilisateur
    .column-nickname = Pseudo de chat
    .column-status = Status
    .column-icon = Icône
    .column-currentLanguage = Langue Actuelle
    .column-languages = Langues
    .column-languageSlots = Emplacements de Langue

## Configuration presets

preset-user-defined = User-defined preset

dialog-save-preset = Enter a name for the new preset.

dialog-confirm-delete-preset = Delete the { $name } custom preset? This cannot be undone.

save-preset-overwrite = Saving will overwrite the existing preset with this name.

status-preset = Applied values from the { $name } preset.

## Context menus

context-chat-settings = Paramètres de discussion

context-customization = Personnalisation

context-languages = Langue

context-clean = Nettoyer le sang et la saleté

context-hair-color = Changer la couleur des cheveux
    .dialog = Entrez une couleur au format RGB ou hexadécimal pour définir la couleur de vos cheveux,
        ou rien pour réinitialiser.
context-grow-hair = Faire pousser les cheveux

context-grow-beard = Faire pousser la barbe

context-enable-name-colors = Activer les couleurs de nom

context-disable-name-colors = Désactiver les couleurs de nom

# @expect-identical
context-suggestions = Suggestions

context-suggestions-enable = Activer les suggestions

context-suggestions-disable = Désactiver les suggestions

context-suggestions-on-enter = Insérer après avoir appuyé sur Entrée

context-suggestions-on-tab = Insérer après avoir appuyé sur Tab

context-enable-typing-indicator = Activer l'indicateur de frappe

context-disable-typing-indicator = Désactiver l'indicateur de frappe

context-retain-commands = Conserver les commandes

context-retain-commands-chat = Discussion

# @expect-identical
context-retain-commands-rp = RP

context-retain-commands-other = Autre

context-add-language = Ajouter
    .dialog = Ajouter { $language } à votre liste de langues ? Cette action est irréversible.
context-sign-emotes-enable = Activer les animations de langue des signes

context-sign-emotes-disable = Désactiver les animations de langue des signes

context-sign-emotes-tooltip = Ceci contrôle si une animation aléatoire est jouée lors
    de l'envoi d'un message dans une langue signée.
context-profiles = Changer de profil

context-profile-default = Défaut

context-manage-profiles = Gérer les profils

context-admin = Options administrateur

context-admin-view-player-data = View player data

context-admin-open-settings = Paramètres

context-admin-show-icon = Afficher l'icône de discussion

context-admin-know-all-languages = Comprendre toutes les langues

context-admin-ignore-message-range = Ignorer la plage de message

## Roleplay languages

language-arabic = Arabe

language-asl = Langage des Signes Américain

# @expect-identical
language-bengali = Bengali

language-cantonese = Cantonais

# @expect-identical
language-catalan = Catalan

language-danish = Danois

language-dutch = Néerlandais

language-english = Anglais

language-finnish = Finnois

language-french = Français

language-german = Allemand

# @expect-identical
language-gujarati = Gujarati

language-hausa = Haoussa

language-hawaiian = Hawaïen

# @expect-identical
language-hindi = Hindi

language-hungarian = Hongrois

language-italian = Italien

language-japanese = Japonais

language-javanese = Javanais

language-korean = Coréen

language-latvian = Letton

language-malay = Malais

# @expect-identical
language-mandarin = Mandarin

# @expect-identical
language-marathi = Marathi

language-norwegian = Norvégien

language-persian = Persan

language-polish = Polonais

language-portuguese = Portugais

language-punjabi = Pendjabi

language-romanian = Roumain

language-russian = Russe

language-shanghainese = Shanghaïen

language-spanish = Espagnol

# @expect-identical
language-tagalog = Tagalog

language-tamil = Tamoul

language-telugu = Télougou

language-thai = Thaï

language-turkish = Turc

language-ukrainian = Ukrainien

language-urdu = Ourdou

language-vietnamese = Vietnamien
