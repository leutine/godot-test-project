extends Node3D
class_name Sword


@export var fire_rate_ms = 400
@onready var rof_timer = $Timer
@onready var anim_player = $AnimationPlayer
@export var damage = 5
var can_shoot = true

func _ready():
	rof_timer.wait_time = fire_rate_ms / 1000.0


func shoot():
	if can_shoot:
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("shoot")
		
		can_shoot = false
		rof_timer.start()
	


func _on_timer_timeout():
	can_shoot = true
	anim_player.play("RESET")
