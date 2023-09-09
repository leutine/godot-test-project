extends Node

@export var weapons: Array[PackedScene]
@onready var current_weapon = 0

var hand: Marker3D
var equipped_weapon: Node3D

func _ready():
	hand = get_parent().find_child("Hand")
	equip_weapon(weapons[current_weapon])


func equip_weapon(weapon: PackedScene):
	if equipped_weapon:
		equipped_weapon.queue_free()
	equipped_weapon = weapon.instantiate()
	hand.add_child(equipped_weapon)


@rpc("call_local")
func shoot():
	if equipped_weapon:
		equipped_weapon.shoot()


@rpc("call_local")
func swap():
	var next_weapon = (current_weapon + 1) % weapons.size()
	equip_weapon(weapons[next_weapon])
	current_weapon = next_weapon

