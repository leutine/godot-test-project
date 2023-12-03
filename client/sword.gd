extends Node3D
class_name Sword


@onready var attack_cd_timer = $Timer
@onready var anim_player = $AnimationPlayer
@onready var hitbox: CollisionShape3D = $Pivot/KnifeSharp/HitboxArea/Hitbox

var damage = 25
var can_shoot = true

func _ready():
	hitbox.disabled = true


func shoot():
	if not can_shoot:
		return
	can_shoot = false

	if anim_player.is_playing():
		anim_player.stop()
	anim_player.play("shoot")

	attack_cd_timer.start()


func _on_timer_timeout():
	can_shoot = true
	anim_player.play("RESET")


func _on_hitbox_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemies"):
		body.get_hit(damage)
