# GodotSteam Project Base

*Please note for this to work, you have to use [GodotSteam](https://gramps.github.io/GodotSteam/). Default Godot builds will not work. Make sure to read the [documentation on how to set it up](https://gramps.github.io/GodotSteam/howto-module.html) I might make a guide here.*

## How to use it?

It's quite simple to use it, and I encourage you to organize your project as you wish. This is really just a skeleton to make you work less, and do more.

The `lobby.tscn` scene is just a set of buttons, with functions connected to handle the "lobby logic." Such as joining/leaving a lobby. After a player joins your lobby, they can recieve packets from other lobby members with a P2P connection method.

All the P2P logic that you may use for your multiplayer game is in the `globals.gd` script, which is also a singleton, meaning it automatically loads when the game starts.

The most important part of the script is:

```python
func _read_P2P_Packet() -> void:
    var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

    if PACKET_SIZE == 0:
        return

    var PACKET = Steam.readP2PPacket(PACKET_SIZE, 0)

    if PACKET.empty():
        print("WARNING: read an empty packet with non-zero size!")

    # var _PACKET_ID: String = str(PACKET.steamIDRemote)
    # var _PACKET_CODE: String = str(PACKET.data[0])
    var READABLE = bytes2var(PACKET.data.subarray(1, PACKET_SIZE - 1))

    if str(READABLE.values()[0]) == "":
        return
    elif READABLE.values()[0] == "handshake":
        print("A handshake was received.")
    elif READABLE.values()[0] == "start_game":
        print("Starting game...")
        var _change_scene: int = get_tree().change_scene("res://source/game/game.tscn")
    elif READABLE.values()[0] == "add_counter":
        for node in get_tree().get_nodes_in_group("Game"):
            node.add_to_counter()

    print("Readable packet: " + str(READABLE))
```

All the packet reading logic is handled at the `if-switch` statement. A packet is a dictionary, so if your packets hold more information than just a message, like player position and such, then you can handle each key/value as their own data.

## To note

**Can you make an example for FPS/TPS/top-down/rouge-like/doom-like game?**
*Depends on the demand. If you guys want it, yes. If not, why should I?*

**Is this your code?**
*Yes, and no. Most of this stuff is just basic stuff I read from the documentation and saw from [ DawnsCrow Games](https://youtu.be/si50G3S1XGU).*

**Where can I message you about feature ideas?**
*I have a [Discord server](https://discord.gg/7EpzqyQb83). You're always welcome to join! Just post that you came with a new idea, and just post it in #coding.*
