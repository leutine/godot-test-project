extends CharacterBody3D

class_name Enemy


@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var stats = $Stats

var speed = 3.0


func _physics_process(_delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	nav_agent.set_velocity(new_velocity)


func update_target_location(loc):
	nav_agent.set_target_position(loc)

func reset_rotation():
	$Pivot.rotation = Vector3.ZERO


func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()


func _on_stats_died_signal():
	queue_free()


# TODO: добывать урон не через родителя ареа3д (чтобы было универсально)
func _on_hurtbox_area_entered(area: Area3D) -> void:
	var parent = area.get_parent_node_3d()
	var damage = 0
	damage = parent.damage
	anim_player.play("take_hit")
	
	var tween = create_tween().set_loops(1)
	tween.tween_property($Pivot, "rotation", Vector3(0, 0, 1.0), 0.15)
	tween.tween_callback(reset_rotation)
	
	stats.take_hit(damage)
