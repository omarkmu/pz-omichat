# Java Mods

The [GitHub repository](https://github.com/omarkmu/pz-omichat) includes Java mods that are **optional** and **server-side only.**

The mod functions equivalently in-game without them, but they may be useful to server operators to address [concerns](https://github.com/omarkmu/pz-omichat/issues/9) about messages including invisible characters.

## Functionality

The `ChatServer.class` replacement cleans up the server-side chat and debug logs to get rid of the invisible characters added by this mod. This makes reading these log files much easier.

The `GeneralChat.class` replacement is recommended for servers using the game's Discord integration. This cleans up messages sent from the in-game `/all` chat so they don't display extra characters surrounding the text. This is not necessary if the game isn't using the Discord integration, but it's fine to include either way.

## Installation

Before installation, you should create a backup of the two `.class` files.
This should not be unsafe, but since installation involves replacing these files entirely, it's wise to do so.

To install:
1. Unzip the `java.zip` included in a [release](https://github.com/omarkmu/pz-omichat/releases).
2. Copy each file in the `zombie` folder into the corresponding subfolder within the `zombie` folder of the server's PZ game directory.
This folder is likely within a `java` folder.
If you're prompted to replace files, do so.

Clients do not need to do this; the relevant methods are called on the server.
