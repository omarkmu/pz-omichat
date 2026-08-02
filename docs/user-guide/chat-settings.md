# Chat Settings

In addition to the vanilla settings, OmiChat offers some new settings for players.
With the exception of the [roleplay language](#language-options) settings, these settings will persist across game servers.
You can access the chat settings by clicking on the gear icon at the top right of the chat box.

![Screenshot of collapsed settings](../images/chat-settings-collapsed.png)

## Basic settings

Most of the settings within the **chat settings** submenu exist in vanilla.
The existing settings work equivalently.
There are two new options in this submenu.

![Screenshot of basic settings](../images/chat-settings-basic.png)

The **suggestions** submenu can be used to control whether suggestions are offered based on chat box input and how those suggestions are accepted.

The **retain commands** submenu can be used to determine whether certain commands are “retained,” so that they are set as the initial input the next time the chat is used.
The submenu contains three options: *Chat*, *RP*, and *Other*.
The first option refers to streams such as `/say`, the second refers to streams like `/me`, and the third covers all other commands.

## Customization

The customization settings can be used to tailor the chat to your preferences.

![Screenshot of customization settings](../images/chat-settings-customization.png)

The **enable/disable sign language emotes** option is only shown when the player character knows a [signed language](../configuration/language.md#list-signed).
This controls whether a random [emote animation](./emote-shortcuts.md) is played whenever they send a message.

The **enable/disable name colors** option allows players to toggle the appearance of name colors in their chat.
This will only display if the [`Name Colors`](../configuration/customization.md#enablenamecolors) configuration option is enabled.

The **manage profiles** option is used to open the profile manager, which can be used to customize callouts and chat colors.

![Screenshot of profile manager](../images/profile-manager.png)

### Color customization

The profile manager contains a number of options that allow players to control how the various chat streams display in their chat, as well as the color of their overhead chat messages.

![Screenshot of customization options](../images/color-options.png)

For example, to use <span style="--color-display: rgb(255,102,0)"></span>orange for messages sent with `/yell`, players can use the **/yell color** option.

![Screenshot showing a color option for /yell with the color set to orange](../images/color-option-example-1.png)

The available color customization options depend on server configuration.

### Callout customization

The profile manager also includes options that allow players to set custom messages for when they use callouts (bound to the `Q` key, by default).
These options only show up if the [`Custom Shouts`](../configuration/customization.md#allowcustomshouts) configuration option is enabled.

![Screenshot of the custom callout input options](../images/callout-example-1.png)  
![Screenshot of a player using a custom callout](../images/callout-example-2.png)

### Character customization

If a server has [character customization](../configuration/customization.md#enablecharactercustomization) enabled,
the customization submenu also includes quality of life character modification options.
The available options are self-explanatory.

![Screenshot of character customization settings](../images/chat-settings-customization-2.png)

## Language options

![Screenshot of language settings](../images/chat-settings-language.png)

The **Language** submenu will only display for players that know multiple languages or can add new ones.
From this menu, players can select the roleplay language that they want to use in chat.
The currently selected language will be displayed with a checkmark.
The option to add new languages will only be available if a player has more available [language slots](../configuration/language.md#defaultslots) than languages.

Languages other than the default language will display an indicator for the language when used in chat.
Players with characters that don't speak the language will see a chat message indicating that they don't understand it.
