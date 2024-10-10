extends Node



func start_server():
	Networking.start_server()
	start_game()


func start_game():
	get_tree().paused = false
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	change_level.call_deferred(load("res://src/shared/levels/test_level/test.tscn"))


# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())


# The server can restart the level by pressing HOME.
func _input(event):
	if event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
		print("Level restart")
		change_level.call_deferred(load("res://src/shared/levels/test_level/test.tscn"))

	if event.is_action_pressed("ui_cancel"):
		print("Server closed")
		get_tree().quit()


# Server
@rpc("any_peer", "call_remote", "reliable")
func server_send_player_info(data: Dictionary) -> void:
	var player_info = PlayerInfo.from_dict(data)

	if not Networking.players.has(player_info.id):
		Networking.players[player_info.id] = player_info

	print_debug("PLAYERS: ", Networking.convert_players())
	#client_get_player_info.rpc(convert_players())

@rpc("any_peer", "call_remote", "reliable")
func client_get_player_info(_data: Dictionary) -> void:
	print("Server: get_player_info")

@rpc("any_peer", "call_remote", "reliable")
func server_player_died(player_id: int) -> void:
	print("server_player_died: %s" % str(player_id))
	client_player_died.rpc(player_id)


@rpc("any_peer", "call_remote", "reliable")
func client_player_died(player_id: int) -> void:
	print("client_player_died: %s" % str(player_id))
