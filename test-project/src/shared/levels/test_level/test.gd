extends Node


const SPAWN_RANDOM := 50.0
const PLAYER_TYPE = preload("res://src/shared/scenes/player.tscn")
const ENEMY_TYPE = preload("res://src/shared/scenes/enemy.tscn")

@onready var spawn_points = $PlayerSpawnPoint
@onready var enemy_spawn_points = $EnemiesSpawnPoint
@onready var death_floor_timer: Timer = $CSGs/Wall4/DeathFloorTimer
@onready var players = $Players

var death_floor_bodies: Array[Node3D] = []


func _on_enemy_spawn_timer_timeout() -> void:
	var enemy_spawns = get_tree().get_nodes_in_group("EnemySpawnPoint")
	for i in enemy_spawns:
		if i.get_child_count() != 0:
			continue
		var enemy = ENEMY_TYPE.instantiate()
		i.add_child(enemy)


func _on_void_body_entered(body: Node3D) -> void:
	body.die()


func _on_death_floor_body_entered(body: Node3D) -> void:
	#print_debug(body, " entered death floor")
	death_floor_bodies.append(body)


func _on_death_floor_body_exited(body: Node3D) -> void:
	#print_debug(body, " exited death floor")
	death_floor_bodies.erase(body)


func _on_death_floor_timer_timeout() -> void:
	for b in death_floor_bodies:
		#if b is Player:
		b.get_hit(5)


func _ready():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)


func _exit_tree():
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

func add_player(id: int):
	# TODO: данные от клиента поступают после того, как объект уже был создан
	# надо поправить
	var new_player = PLAYER_TYPE.instantiate()
	# Set player id.
	#new_player.network_id = id
	if Networking.players.has(id):
		new_player.name_label_text = Networking.players[id].name
		new_player.color = Networking.players[id].color
	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)
	new_player.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	new_player.name = str(id)
	players.add_child(new_player, true)

func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()
