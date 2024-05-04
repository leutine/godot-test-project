extends Node3D


const PLAYER_TYPE = preload("res://scenes/player.tscn")
const ENEMY_TYPE = preload("res://scenes/enemy.tscn")

@onready var spawn_points = $PlayerSpawnPoint
@onready var enemy_spawn_points = $EnemiesSpawnPoint
@onready var death_floor_timer: Timer = $CSGs/Wall4/DeathFloorTimer

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
