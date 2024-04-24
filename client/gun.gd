extends Node3D


@export var bullet: PackedScene
@export var bullet_speed = 900.0
var damage: int = 5

@export var fire_rate_ms = 400
@onready var rof_timer = $ROFTimer
@onready var anim_player = $AnimationPlayer
@onready var shooting_marker = $BodyPivot/ShootingMarker
@onready var aim_ray_cast: RayCast3D = $BodyPivot/AimRayCast

var can_shoot = true

func _ready():
	rof_timer.wait_time = fire_rate_ms / 1000.0


func shoot():
	if can_shoot:
		if anim_player.is_playing():
			anim_player.stop()
		anim_player.play("shoot")
		var new_bullet: Bullet = bullet.instantiate()
		new_bullet.global_transform = shooting_marker.global_transform
		new_bullet.speed = bullet_speed
		var scene_root = get_tree().root
		scene_root.add_child(new_bullet)

		if aim_ray_cast.is_colliding():
			var node = aim_ray_cast.get_collider()
			if node and node.is_in_group("enemies") or node.is_in_group("players"):
				node.get_hit(damage)

		can_shoot = false
		rof_timer.start()


func _on_timer_timeout():
	can_shoot = true
