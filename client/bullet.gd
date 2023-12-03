extends Node3D
class_name Bullet

var speed = 900.0
var damage = 5

const KILL_TIME = 2
var timer = 0

func _physics_process(delta):
	var direction = global_transform.basis.z.normalized()
	global_translate(direction * speed * delta)
	
	timer += delta
	if timer >= KILL_TIME:
		queue_free()


func _on_area_3d_body_entered(_body: Node):
	queue_free()
