extends MultiplayerSynchronizer

# Set via RPC to simulate is_action_just_pressed.
@export var jumping := false

# Synchronized property.
@export var direction := Vector2.ZERO


@rpc("call_local")
func jump():
	jumping = true

func _physics_process(_delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not is_multiplayer_authority():
		return
	direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if Input.is_action_just_pressed("jump"):
		jump.rpc()
