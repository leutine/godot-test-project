extends Node3D
class_name Sword


@export var fire_rate_ms = 400
@onready var rof_timer = $Timer
@onready var anim_player = $AnimationPlayer
@onready var hitbox: CollisionShape3D = $Pivot/Body/Blade/HitboxArea/Hitbox
@export var damage = 5
var can_shoot = true

func _ready():
	rof_timer.wait_time = fire_rate_ms / 1000.0
	hitbox.disabled = true


func shoot():
	if can_shoot:
		hitbox.disabled = false
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("shoot")
		
		can_shoot = false
		rof_timer.start()
	


func _on_timer_timeout():
	can_shoot = true
	anim_player.play("RESET")
	hitbox.disabled = true
