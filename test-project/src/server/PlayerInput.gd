extends MultiplayerSynchronizer

# Set via RPC to simulate is_action_just_pressed.
@export var jumping := false

# Synchronized property.
@export var direction := Vector2()
@export var is_on_floor_ := true


@rpc("call_local")
func jump():
	jumping = true
