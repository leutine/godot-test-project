extends Control

@export var address = "localhost"
@export var PORT = 8910
@export var MAX_CLIENTS = 5

@onready var main_menu = $UI/MainMenu
@onready var name_edit = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/NameEdit
@onready var color_rect = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/ColorRect

const player_colors: Array[Color] = [Color.GREEN_YELLOW, Color.ORANGE_RED, Color.CORNFLOWER_BLUE, Color.BLACK, Color.MEDIUM_PURPLE]
var color_picked_num: int = 0


func get_player_info() -> PlayerInfo:
	var player_info = PlayerInfo.new()
	player_info.name = name_edit.text
	player_info.id = multiplayer.get_unique_id()
	player_info.color = color_rect.color
	return player_info


@rpc("any_peer")
func send_player_info(player_info: PlayerInfo) -> void:
	if not MultiplayerManager.players.has(player_info.id):
		MultiplayerManager.players[player_info.id] = player_info

	if not multiplayer.is_server():
		return

	for i in MultiplayerManager.players:
		var value = MultiplayerManager.players[i]
		send_player_info.rpc(value)


@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scene)
	main_menu.hide()


func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	if "--server" in OS.get_cmdline_args():
		host_game()


func peer_connected(id):
	print("Player connected " + str(id))


func peer_disconnected(id):
	print("Player disconnected " + str(id))


func connected_to_server():
	print("Connected to server: " + str(multiplayer.get_unique_id()))
	send_player_info.rpc_id(1, get_player_info())


func connection_failed():
	print("Connection failed")


func host_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Server failed: " + error)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.multiplayer_peer = peer
	print("Server created")


func _on_host_button_button_down() -> void:
	host_game()
	send_player_info(get_player_info())


func _on_join_button_button_down() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, PORT)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer


func _on_start_button_button_down() -> void:
	start_game.rpc()


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_action"):
		color_picked_num += 1
		color_rect.color = player_colors[color_picked_num % player_colors.size()]
