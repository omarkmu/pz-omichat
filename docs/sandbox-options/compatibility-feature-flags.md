# Compatibility Feature Flags

Compatibility feature flags allow server operators to enable or disable compatibility patches for other mods. These have no effect if the relevant mod is not active.

As of now, there is only one such flag.

### EnableCompatTAD
**Default:** `true`  

Enables the compatibility patch for [True Actions Act 3 - Dancing](https://steamcommunity.com/sharedfiles/filedetails/?id=2648779556).

This adds a `/dance` command that makes the player perform a random dance that they know.
It also allows for selecting particular dances by name; a list of available dance names can be found by using `/help dance` or `/dance list`.
