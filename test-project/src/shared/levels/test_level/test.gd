extends Node


const SPAWN_RANDOM := 50.0
const PLAYER_TYPE = preload("res://src/shared/scenes/player.tscn")
const ENEMY_TYPE = preload("res://src/shared/scenes/enemy.tscn")

@onready var enemy_spawn_points = $EnemiesSpawnPoint
@onready var death_floor_timer: Timer = $CSGs/Wall4/DeathFloorTimer
@onready var players = $Players
@onready var enemies = $Enemies

var death_floor_bodies: Array[Node3D] = []


func _on_enemy_spawn_timer_timeout() -> void:
	for point in enemy_spawn_points.get_children():
		if enemies.get_node_or_null("./%s" % (point.name)):
			continue
		var enemy = ENEMY_TYPE.instantiate()
		enemy.name = point.name
		enemies.add_child(enemy)


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


# TODO: данные от клиента поступают после того, как объект уже был создан
func add_player(id: int):
	print("Add player %s to level" % id)
	var player = PLAYER_TYPE.instantiate()
	player.name = str(id)
	_init_player(player, id)
	players.add_child(player)

func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()

func _init_player(player: Player, id: int) -> void:
	player.position = Vector3(randi_range(-2, 2), 1, randi_range(-2, 2))

	if Networking.players.has(id):
		player.name_label_text = Networking.players[id].name
		player.color = Networking.players[id].color
