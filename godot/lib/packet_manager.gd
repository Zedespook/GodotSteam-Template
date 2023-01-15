extends Node


func handle_packet(packet: String):
	match packet:
		"handshake":
			print("A handshake was received.")
		"start_game":
			print("Starting game...")
			var _change_scene: int = get_tree().change_scene("res://scenes/game/game.tscn")
		"add_counter":
			for node in get_tree().get_nodes_in_group("Game"):
				node.add_to_counter()
		_:
			print("Unknown packet received: " + packet)

	print("Packet received: " + packet)
