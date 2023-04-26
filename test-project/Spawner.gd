extends Node3D

@export var enemy_type: PackedScene
@export var enemies_num = 3
@export var wait_sec = 1
@export var enemies_remaining = 5

@onready var timer = $Timer


signal spawn_enemy

func start():
	timer.wait_time = wait_sec
	timer.start()



func _on_timer_timeout():
	spawn(enemies_num)


func spawn(number):
	emit_signal("spawn_enemy", number)

