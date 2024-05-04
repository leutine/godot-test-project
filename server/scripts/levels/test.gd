extends Node

const SPAWN_RANDOM := 50.0
const PLAYER = preload("res://scenes/player.tscn")
const ENEMY = preload("res://scenes/enemy.tscn")

@onready var players = $Players

func _ready():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	# Spawn already connected players.
	for id in multiplayer.get_peers():
		add_player(id)


func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)


func add_player(id: int):
	var new_player = PLAYER.instantiate()
	# Set player id.
	new_player.network_id = id
	if Server.players.has(id):
		new_player.name_label_text = Server.players[id].name
		new_player.color = Server.players[id].color
	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)
	new_player.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	new_player.name = str(id)
	players.add_child(new_player, true)


func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()
