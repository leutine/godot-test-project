extends CharacterBody3D

class_name Enemy

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var stats = $Stats

@onready var character_model_surface: MeshInstance3D = $CharacterModel/RootNode/GeneralSkeleton/Beta_Surface
@onready var character_model_anim_player: AnimationPlayer = $CharacterModel/AnimationPlayer

var speed = 3.0

func _process(_delta: float) -> void:
	if character_model_anim_player.current_animation != "idle":
		character_model_anim_player.play("idle")


func _physics_process(delta):
	#var current_location = global_transform.origin
	#var next_location = nav_agent.get_next_path_position()
	#var new_velocity = (next_location - current_location).normalized() * speed
	#nav_agent.set_velocity(new_velocity)
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()


func update_target_location(loc):
	nav_agent.set_target_position(loc)


func reset_rotation():
	rotation = Vector3.ZERO


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()


func _on_stats_died_signal():
	queue_free()


func get_hit(damage: int) -> void:
	character_model_anim_player.play("take_hit")
	var tween = create_tween().set_loops(1)
	tween.tween_property(self, "rotation", Vector3(0, 0, 1.0), 0.15)
	tween.tween_callback(reset_rotation)
	
	stats.take_hit(damage)
