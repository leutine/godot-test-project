extends Node
class_name Dodge

const dash_delay = 3.0

@onready var duration_timer = $DurationTimer
@onready var cooldown_timer = $CooldownTimer

@export var cooldown_duration_s = 3.0

var can_dash = true


func start_dash(duration):
	duration_timer.wait_time = duration
	duration_timer.start()


func is_dashing():
	return !duration_timer.is_stopped()


func end_dash():
	can_dash = false
	await get_tree().create_timer(dash_delay).timeout
	can_dash = true


func _on_DurationTimer_timeout() -> void:
	print_debug("dash timeout!")
	end_dash()
