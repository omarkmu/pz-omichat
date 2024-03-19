# Java Mods

**The [GitHub repository](https://github.com/omarkmu/pz-omichat) includes Java mods that are entirely optional and server-side only.**

The mod functions equivalently in-game without them, but they may be useful to server operators to address [concerns](https://github.com/omarkmu/pz-omichat/issues/9) about messages including invisible characters.

## Mods

The `ChatServer.class` replacement cleans up the server-side `chat` log to get rid of the invisible characters added by this mod. This makes reading these log files much easier.

The `GeneralChat.class` replacement is recommended for servers using the game's Discord integration. This cleans up messages sent from the in-game `/all` chat so they don't display extra characters surrounding the text. This is not necessary if the game isn't using the Discord integration, but it's fine to include either way.

## Installation

To install, unzip the `java.zip` included in a [release](https://github.com/omarkmu/pz-omichat/releases) and copy the `zombie` folder into the server's game directory.
When prompted to replace existing files, do so.

Clients do not need to do this; the relevant methods are called on the server.
