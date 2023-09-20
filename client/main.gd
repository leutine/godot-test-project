extends Node


const ADDRESS = "localhost"
const PORT = 8910

const Player = preload("res://player.tscn")
#const Enemy = preload("res://enemy.tscn")
#const PORT = 9999
#const SPAWN_RANDOM := 5.0
#var enet_peer = ENetMultiplayerPeer.new()
@onready var main_menu = $UI/MainMenu
@onready var name_edit = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/NameEdit
@onready var color_rect = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/ColorRect

const player_colors: Array[Color] = [Color.GREEN_YELLOW, Color.ORANGE_RED, Color.CORNFLOWER_BLUE, Color.BLACK, Color.MEDIUM_PURPLE]
var color_picked_num: int = 0

func print_players_sync():
	var visibilities = {}
	for p in get_tree().get_nodes_in_group("players"):
		var values = {}
		for i2 in Server.players:
			values[i2] = p.mp_sync.get_visibility_for(i2)
		visibilities[str(p.name)] = values
	print("SYNC VISIBILITY on %s: " % str(multiplayer.get_unique_id()), visibilities)

func get_player_info() -> PlayerInfo:
	var player_info = PlayerInfo.new()
	player_info.name = name_edit.text
	player_info.id = multiplayer.get_unique_id()
	player_info.color = color_rect.color
	return player_info


func get_new_player(player_info: PlayerInfo) -> Player:
	var new_player = Player.instantiate()
	new_player.name = str(player_info.id)
	new_player.color = player_info.color
	new_player.name_label_text = player_info.name
	return new_player

func add_new_player_to_scene(player_id: int) -> void:
	var player_info = Server.players[player_id]
	var new_player = get_new_player(player_info)
	get_tree().root.add_child(new_player)
#	for p_id in Server.players:
#		if p_id != multiplayer.get_unique_id():
#		new_player.mp_sync.set_visibility_for(p_id, true)
	var spawn_points = get_tree().get_nodes_in_group("PlayerSpawnPoint")
	new_player.global_position = spawn_points.pick_random().global_position

func prepare_level() -> void:
	print("%s - level._ready: %s" % [str(multiplayer.get_unique_id()), Server.players])
	for i in Server.players:
		add_new_player_to_scene(i)
	print("PLAYERS on %s: " % str(multiplayer.get_unique_id()), get_tree().get_nodes_in_group("players"))

	print_players_sync()


func spawn_player(player_id, pos) -> void:
	if not Server.players.has(player_id):
		return
	print("%s - spawn_player: %s" % [str(multiplayer.get_unique_id()), str(player_id)])
	add_new_player_to_scene(player_id)

	print_players_sync()


#@rpc("any_peer")
#func send_player_info(data: Dictionary) -> void:
#	var player_info = PlayerInfo.from_dict(data)
#
#	if not Server.players.has(player_info.id):
#		Server.players[player_info.id] = player_info


#@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://level.tscn").instantiate()
	get_tree().root.add_child(scene)
	main_menu.hide()
	prepare_level()
	for p_id in Server.players:
		if p_id != multiplayer.get_unique_id():
			client_ready_to_sync.rpc(multiplayer.get_unique_id())
		for p in get_tree().get_nodes_in_group("players"):
			if p_id != multiplayer.get_unique_id():
				p.mp_sync.set_visibility_for(p_id, true)
	print_players_sync()


func _ready() -> void:
#	multiplayer.peer_connected.connect(peer_connected)
#	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	Server.player_spawned.connect(spawn_player)


func peer_connected(id):
	print("Player connected " + str(id))


func peer_disconnected(id):
	print("Player disconnected " + str(id))


func connected_to_server():
	print("Connected to server: " + str(multiplayer.get_unique_id()))
	Server.server_send_player_info.rpc_id(1, get_player_info().to_dict())


func connection_failed():
	print("Connection failed")

func server_disconnected():
	print("Server disconnected")
	main_menu.show()


@rpc("any_peer")
func client_ready_to_sync(player_id):
	for p in get_tree().get_nodes_in_group("players"):
		p.mp_sync.set_visibility_for(player_id, true)


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


func _on_host_button_button_down() -> void:
	Server.host_game()
	Server.server_send_player_info(get_player_info().to_dict())


func _on_join_button_button_down() -> void:
	Server.join_game(ADDRESS, PORT)
#	Server.server_send_player_info(get_player_info().to_dict())
	while not Server.players:
		await get_tree().create_timer(0.05).timeout
	start_game()


func _on_start_button_button_down() -> void:
#	start_game.rpc()
	start_game()


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_action"):
		color_picked_num += 1
		color_rect.color = player_colors[color_picked_num % player_colors.size()]
