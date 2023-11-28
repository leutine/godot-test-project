extends Node


@export var ADDRESS = "localhost"
@export var PORT = 8910
@export var MAX_CLIENTS = 5

signal player_spawned(player_id, position)

var players = {}


@rpc("any_peer", "call_remote", "reliable") 
func client_get_player_info(data: Dictionary) -> void:
	print("%s - get_player_info: %s" % [str(multiplayer.get_unique_id()), data])
	for k in data:
		players[k] = PlayerInfo.from_dict(data[k])


@rpc("any_peer", "call_remote", "reliable")
func server_send_player_info(data: Dictionary) -> void:
	print("%s - server_send_player_info: %s" % [str(multiplayer.get_unique_id()), data])

#func host_game():
#	var peer = ENetMultiplayerPeer.new()
#	var error = peer.create_server(PORT, MAX_CLIENTS)
#	if error != OK:
#		print("Server failed: " + error)
#		return
#	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
#
#	multiplayer.multiplayer_peer = peer
#	print("Server created")

func join_game(address, port):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer

@rpc("authority", "call_remote", "reliable")
func client_spawn_player(player_id, pos) -> void:
	if player_id == multiplayer.get_unique_id():
		return
	if not Server.players.has(player_id):
		return
	print("%s - client_spawn_player: %s" % [str(multiplayer.get_unique_id()), player_id])
	player_spawned.emit(player_id, pos)
