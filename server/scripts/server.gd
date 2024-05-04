extends Node


var players = {}


func convert_players():
	var result = {}
	for k in players:
		var value = players[k]
		result[k] = value.to_dict()
	return result


@rpc("any_peer", "call_remote", "reliable")
func server_send_player_info(data: Dictionary) -> void:
	var player_info = PlayerInfo.from_dict(data)

	if players.has(player_info.id):
		players[player_info.id] = player_info

	print_debug("PLAYERS: ", convert_players())
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


func peer_connected(id):
	print("Player connected " + str(id))
	if not players.has(id):
		players[id] = PlayerInfo.new()
	print("Current players: ", convert_players())


func peer_disconnected(id):
	print("Player disconnected " + str(id))
	if not players.has(id):
		return
	players.erase(id)
	print("Current players: ", convert_players())


func start_server(port, max_clients):
	var peer = ENetMultiplayerPeer.new()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	var error = peer.create_server(port, max_clients)
	if error != OK:
		print("Server failed: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

	multiplayer.multiplayer_peer = peer
	print("Server started on port " + str(port))
