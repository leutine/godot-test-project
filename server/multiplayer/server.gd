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
	print(player_info.to_dict())

	if not players.has(player_info.id):
		players[player_info.id] = player_info

	print("PLAYERS: ", players)
	client_get_player_info.rpc(convert_players())


@rpc("any_peer", "call_local", "reliable") 
func client_get_player_info(data: Dictionary) -> void:
	print("Server: get_player_info")


@rpc("any_peer", "call_local", "reliable")
func client_spawn_player(player_id, pos) -> void:
	print("Player " + str(player_id) + " spawned in " + str(pos))


func peer_connected(id):
	print("Player connected " + str(id))
	while not players.has(id):
		await get_tree().create_timer(0.05).timeout
	client_spawn_player.rpc(id, Vector3(-15, 0, 7))


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
