extends Node


@export var port = 8910
@export var address = "localhost"

@onready var main_menu = $UI/MainMenu
@onready var name_edit = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/NameEdit
@onready var color_picker_button = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/ColorPickerButton
@onready var died_label = $UI/HUD/YouDiedLabel
@onready var crosshair_img = $UI/HUD/Crosshair


signal player_died(player_id)

var peer: ENetMultiplayerPeer
var players = {}
var is_connected_to_server: bool = false

func get_player_info() -> PlayerInfo:
	var player_info = PlayerInfo.new()
	player_info.name = name_edit.text
	player_info.id = multiplayer.get_unique_id()
	player_info.color = color_picker_button.color
	return player_info

func start_game():
	main_menu.hide()
	crosshair_img.show()

func _ready() -> void:
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)
	#multiplayer.peer_connected.connect(peer_connected)
	#multiplayer.peer_disconnected.connect(peer_disconnected)

func peer_connected(id):
	print("Player connected: " + str(id))

func peer_disconnected(id):
	print("Player disconnected: " + str(id))

func connected_to_server():
	print("Connected to server, player ID: " + str(multiplayer.get_unique_id()))
	server_send_player_info.rpc_id(1, get_player_info().to_dict())
	print("Send PlayerInfo: ", get_player_info().to_dict())

func connection_failed():
	print("Connection failed")
	main_menu.show()

func server_disconnected():
	print("Server disconnected")
	is_connected_to_server = false
	main_menu.show()

func _on_host_button_button_down() -> void:
	print("Host button disabled!")

func _on_join_button_button_down() -> void:
	join_game(address, port)
	start_game()

func _on_player_died(player: Player) -> void:
	if player.name != str(multiplayer.get_unique_id()):
		return
	player.is_dead = true
	died_label.show()
	crosshair_img.hide()
	var tw = create_tween().bind_node(died_label)
	tw.set_parallel()
	tw.set_trans(Tween.TRANS_ELASTIC)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(died_label, "rotation", 2 * PI, 1)
	tw.tween_property(died_label, "theme_override_font_sizes/font_size", 50, 1)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


# Server client
@rpc("any_peer", "call_remote", "reliable")
func client_get_player_info(data: Dictionary) -> void:
	print("%s - client_get_player_info: %s" % [str(multiplayer.get_remote_sender_id()), data])
	for k in data:
		players[k] = PlayerInfo.from_dict(data[k])
	print("Players: ", players)


@rpc("any_peer", "call_remote", "reliable")
func server_send_player_info(data: Dictionary) -> void:
	print("%s - server_send_player_info: %s" % [str(multiplayer.get_remote_sender_id()), data])


@rpc("any_peer", "call_remote", "reliable")
func server_player_died(player_id: int) -> void:
	print("%s - server_player_died: %s" % [str(multiplayer.get_remote_sender_id()), player_id])


@rpc("any_peer", "call_remote", "reliable")
func client_player_died(player_id: int) -> void:
	print("%s - client_player_died: %s" % [str(multiplayer.get_remote_sender_id()), str(player_id)])


func join_game(address, port):
	peer.create_client(address, port)
	#peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer

func start_client():
	peer = Networking.new().start_client()
