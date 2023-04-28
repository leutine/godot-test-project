extends Node3D


@onready var main_menu = $UI/MainMenu
@onready var address_edit = $UI/MainMenu/MarginContainer/VBoxContainer/AddressEdit
@onready var color_rect = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/ColorRect
@onready var name_edit = $UI/MainMenu/MarginContainer/VBoxContainer/HBoxContainer/NameEdit

const player_colors: Array[Color] = [Color.GREEN_YELLOW, Color.ORANGE_RED, Color.CORNFLOWER_BLUE, Color.BLACK, Color.MEDIUM_PURPLE]
var color_picked_num: int = 0

const Player = preload("res://player.tscn")
const Enemy = preload("res://enemy.tscn")
const PORT = 9999
const SPAWN_RANDOM := 5.0
var enet_peer = ENetMultiplayerPeer.new()


func _ready() -> void:
	color_rect.color = player_colors[0]


func _physics_process(_delta):
	var players = get_tree().get_nodes_in_group("players")
	if players:
		get_tree().call_group("enemies", "update_target_location", players[0].global_transform.origin)


func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	player.name_label_text = name_edit.text
	var pos := Vector2.from_angle(randf() * 2 * PI)
	player.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	player.set_multiplayer_authority(multiplayer.multiplayer_peer.get_unique_id())
	$Players.add_child(player)
	if player.is_multiplayer_authority():
		player.set_color.rpc(color_rect.color)
		player.spawned_mob.connect(spawn_mob)


func _on_host_button_pressed():
	main_menu.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed():
	if address_edit.text == "":
		return
	main_menu.hide()
	
	enet_peer.create_client(address_edit.text, PORT)
#	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer


func remove_player(peer_id):
	var player = $Players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()


@rpc("any_peer")
func client_spawn_mob(mob_position):
	create_enemy(mob_position)


func create_enemy(mob_position):
	var enemy = Enemy.instantiate()
	enemy.name = str(randi())
	enemy.position = mob_position
	$Enemies.add_child(enemy, true)


func spawn_mob(mob_position):
	if not is_multiplayer_authority():
		client_spawn_mob.rpc(mob_position)
		return
	create_enemy(mob_position)


func _on_players_spawner_spawned(player: Player) -> void:
	if player.is_multiplayer_authority():
		player.set_color.rpc(color_rect.color)
		player.set_player_name(name_edit.text)
		player.spawned_mob.connect(spawn_mob)


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_action"):
		color_picked_num += 1
		color_rect.color = player_colors[color_picked_num % player_colors.size()]
