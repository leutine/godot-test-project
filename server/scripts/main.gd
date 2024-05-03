extends Node

@export var PORT = 8910
@export var MAX_CLIENTS = 5

var players = {}


func convert_players():
	var result = {}
	for k in players:
		var value = players[k]
		result[k] = value.to_dict()
	return result


func _ready() -> void:
	host_game()


@rpc("any_peer", "call_remote", "reliable")
func server_send_player_info(data: Dictionary) -> void:
	var player_info = PlayerInfo.from_dict(data)

	if not players.has(player_info.id):
		players[player_info.id] = player_info

	print("PLAYERS: ", players)
	client_get_player_info.rpc(convert_players())


@rpc("any_peer", "call_remote", "reliable") 
func client_get_player_info(data: Dictionary) -> void:
	print("Server: get_player_info")


@rpc("any_peer", "call_remote", "reliable")
func client_spawn_player(player_id, pos) -> void:
	print("Player " + str(player_id) + " spawned in " + str(pos))


@rpc("any_peer", "call_remote", "reliable")
func server_player_died(player_id: int) -> void:
	print("server_player_died: %s" % str(player_id))
	client_player_died.rpc(player_id)


@rpc("any_peer", "call_remote", "reliable") 
func client_player_died(player_id: int) -> void:
	print("client_player_died: %s" % str(player_id))


@rpc("any_peer", "call_remote", "reliable")
func server_player_spawned(data: Dictionary) -> void:
	var player_info = PlayerInfo.from_dict(data)
	print("server_player_spawned: %s" % str(player_info.id))
	client_player_spawned.rpc(data)


@rpc("any_peer", "call_remote", "reliable") 
func client_player_spawned(data: Dictionary) -> void:
	var player_info = PlayerInfo.from_dict(data)
	print("client_player_spawned: %s" % str(player_info.id))


func peer_connected(id):
	print("Player connected " + str(id))


func peer_disconnected(id):
	print("Player disconnected " + str(id))
	if not players.has(id):
		return
	players.erase(id)


func host_game():
	var peer = ENetMultiplayerPeer.new()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Server failed: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

	multiplayer.multiplayer_peer = peer
	print("Server created")
	start_game()

func start_game():
	get_tree().paused = false
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	change_level.call_deferred(load("res://scenes/levels/test.tscn"))

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
		change_level.call_deferred(load("res://scenes/levels/test.tscn"))
	
	if event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
		$Level/Players.get_node("")
