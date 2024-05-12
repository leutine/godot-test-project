extends CharacterBody3D
class_name Player

# Set by the authority, synchronized on spawn.
@export var network_id := 1:
	set(id):
		network_id = id
		# Give authority over the player input to the appropriate peer.
		$PlayerInput.set_multiplayer_authority(id)


@export var name_label_text := "Player":
	set(text):
		name_label_text = text


@export var color := Color.BLACK:
	set(new_color):
		color = new_color


@rpc("call_local")
func swap_weapon():
	if not is_multiplayer_authority(): return
	#gun_controller.swap()
	pass


@rpc("call_local")
func shoot():
	if not is_multiplayer_authority(): return
	#gun_controller.shoot()
	pass
