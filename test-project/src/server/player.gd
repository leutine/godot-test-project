extends CharacterBody3D
class_name Player

var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")
const JUMP_VELOCITY = 4.5
const SPEED = 5.0

@onready var input := $PlayerInput
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


func _physics_process(delta):
	# Add the gravity.
	print(input.is_on_floor_)
	if not input.is_on_floor_:
		velocity.y -= GRAVITY * delta

	# Handle jump.
	if input.jumping and input.is_on_floor_:
		velocity.y = JUMP_VELOCITY

	# Reset jump state.
	input.jumping = false

	# Handle movement.
	var direction := (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
