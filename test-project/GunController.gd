extends Node

@export var starting_weapon: PackedScene

var hand: Marker3D
var equipped_weapon: Node3D

func _ready():
	hand = get_parent().find_child("Hand")
	if starting_weapon:
		equip_weapon(starting_weapon)


func equip_weapon(weapon: PackedScene):
	if equipped_weapon:
		equipped_weapon.queue_free()
	else:
		equipped_weapon = weapon.instantiate()
		hand.add_child(equipped_weapon)

@rpc("call_local")
func shoot():
	if equipped_weapon:
		equipped_weapon.shoot()
