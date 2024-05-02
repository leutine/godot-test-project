extends Node

class_name Stats

signal died_signal

@export var max_hp = 20

var current_hp = max_hp

func take_hit(damage):
	current_hp -= damage
#	print(get_parent(), ' health: %s/%s' % [current_hp, max_hp])
	
	if current_hp <= 0:
		die()


func die():
	emit_signal("died_signal")
