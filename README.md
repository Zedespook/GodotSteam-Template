# GodotSteam Project Base

**THIS PROJECT IS FOR GODOT 3, and therefore is outdated!**

*Please note for this to work, you have to use [GodotSteam](https://gramps.github.io/GodotSteam/), because it will not work with a base Godot build. Make sure to read the [documentation on how to set it up](https://gramps.github.io/GodotSteam/howto-module.html).*

## How to use it?

It's quite simple to use it, and I encourage you to organize your project as you wish. This is really just a skeleton to make you work less, and do more.

The `lobby.tscn` scene is just a set of buttons, with functions connected to handle the "lobby logic." Such as joining/leaving a lobby. After a player joins your lobby, they can recieve packets from other lobby members with a P2P connection method.

All of the networking is P2P by default. All of the P2P logic is stored in `packet_manager.gd`. It's very simple to add and modify existing logic included within this or any of the future templates.

## TODOs

- [ ] 3D/TPS multiplayer template
- [ ] 3D/FPS multiplayer template
- [ ] 2D/top-down multiplayer template
- [ ] 2D/isometric multiplayer template
- [ ] 2D/platformer multiplayer template
