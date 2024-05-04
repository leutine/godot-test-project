extends Node


signal player_spawned(player_id, position)
signal player_died(player_id)

var players = {}
var is_connected_to_server: bool = false


@rpc("any_peer", "call_remote", "reliable") 
func client_get_player_info(data: Dictionary) -> void:
	print("%s - client_get_player_info: %s" % [str(multiplayer.get_remote_sender_id()), data])
	for k in data:
		players[k] = PlayerInfo.from_dict(data[k])


@rpc("any_peer", "call_remote", "reliable")
func server_send_player_info(data: Dictionary) -> void:
	print("%s - server_send_player_info: %s" % [str(multiplayer.get_remote_sender_id()), data])


@rpc("any_peer", "call_remote", "reliable")
func server_player_died(player_id: int) -> void:
	print("%s - server_player_died: %s" % [str(multiplayer.get_remote_sender_id()), player_id])


@rpc("any_peer", "call_remote", "reliable") 
func client_player_died(player_id: int) -> void:
	print("%s - client_player_died: %s" % [str(multiplayer.get_remote_sender_id()), str(player_id)])


@rpc("any_peer", "call_remote", "reliable")
func server_player_spawned(data: Dictionary) -> void:
	print("%s - server_player_spawned: %s" % [str(multiplayer.get_remote_sender_id()), data])


@rpc("any_peer", "call_remote", "reliable") 
func client_player_spawned(data: Dictionary) -> void:
	print("%s - client_player_spawned: %s" % [str(multiplayer.get_remote_sender_id()), data])


func join_game(address, port):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer


@rpc("authority", "call_remote", "reliable")
func client_spawn_player(player_id, pos) -> void:
	if player_id == multiplayer.get_unique_id():
		return
	if not players.has(player_id):
		return
	print("%s - client_spawn_player: %s" % [str(multiplayer.get_unique_id()), player_id])
	player_spawned.emit(player_id, pos)
