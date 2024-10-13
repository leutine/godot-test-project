extends Node


const PORT = 8910
const DEFAULT_SERVER_IP = "localhost"
const MAX_CONNECTIONS = 5

var players = {}
var player_info = PlayerInfo.new()

signal player_connected(peer_id: int, player_info: PlayerInfo)
signal player_disconnected(peer_id: int)
signal server_disconnected

func convert_players():
	var result = {}
	for k in players:
		var value = players[k]
		result[k] = value.to_dict()
	return result

func start_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error != OK:
		multiplayer.multiplayer_peer = null
		push_error("Server failed: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on port %s" % PORT)

func start_client(address, port):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		multiplayer.multiplayer_peer = null
		push_error("Client failed: %s" % error)
		return
	multiplayer.multiplayer_peer = peer
	print("Client connected on %s:%s" % [address, port])


func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

@rpc("any_peer", "reliable")
func _register_player(new_player_data):
	var new_player_id = multiplayer.get_remote_sender_id()
	var new_player_info = PlayerInfo.from_dict(new_player_data)
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)


# Signal handlers
func _on_player_connected(id):
	print("Player connected " + str(id))
	var player_info_data = player_info.to_dict()
	_register_player.rpc_id(id, player_info_data)
	print("Current players: ", convert_players())

func _on_player_disconnected(id):
	print("Player disconnected " + str(id))
	players.erase(id)
	player_disconnected.emit(id)
	print("Current players: ", convert_players())

func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail():
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
