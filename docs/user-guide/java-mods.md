# Java Mods

The [GitHub repository](https://github.com/omarkmu/pz-omichat) includes Java mod files that are **optional** and **server-side only.**
The mod functions equivalently in-game without them, but the Java mods may be useful to server operators to address [concerns](https://github.com/omarkmu/pz-omichat/issues/9) about messages including invisible characters.

> [!WARNING]
> Java mods are likely to break between updates during b42 unstable!
> If this happens, delete the `.class` files from where they were placed.

## Functionality

The `ChatServer.class` replacement cleans up the server-side `chat` log files to remove data included in messages for mod functionality.

The `GeneralChat.class` replacement is recommended for servers using the game's Discord integration.
This cleans up messages sent from the in-game `/all` chat to remove data included in messages for mod functionality.

## Installation

> [!NOTE]
> Clients do not need to do this. The relevant methods are called on the server.

To install:
1. Unzip the `java.zip` included in a [release](https://github.com/omarkmu/pz-omichat/releases).
2. Copy the `zombie` folder into the game directory (the directory which contains `projectzomboid.jar`).
