extends CharacterBody3D

class_name Enemy


@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var speed = 3.0

func _physics_process(_delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	nav_agent.set_velocity(new_velocity)


func update_target_location(loc):
	nav_agent.set_target_position(loc)


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()

func _on_stats_died_signal():
	queue_free()
