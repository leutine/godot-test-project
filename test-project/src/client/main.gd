extends Node


@export var port = 8910
@export var address = "localhost"

@onready var main_menu = $UI/MainMenu
@onready var address_edit = $UI/MainMenu/MarginContainer/VBoxContainer/AddressEdit
@onready var name_edit = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/NameEdit
@onready var color_picker_button = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/ColorPickerButton
@onready var died_label = $UI/HUD/YouDiedLabel
@onready var crosshair_img = $UI/HUD/Crosshair



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
	Networking.server_disconnected.connect(_on_server_disconnected)

func _on_server_disconnected():
	print("Server disconnected")
	main_menu.show()

func _on_host_button_button_down() -> void:
	print("Host button disabled!")

func _on_join_button_button_down() -> void:
	# var address = address_edit.text
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
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("primary_action"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func join_game(address, port):
	Networking.player_info = get_player_info()
	Networking.start_client(address, port)

func start():
	pass
