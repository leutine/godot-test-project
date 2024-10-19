class_name PlayerInput extends MultiplayerSynchronizer

var direction := Vector2.ZERO
var jump_input := 0.0
var run_input := false

func _physics_process(_delta):
	if not is_multiplayer_authority():
		return

	direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	jump_input = Input.get_action_strength("jump")
	run_input = Input.is_action_pressed("dodge")
