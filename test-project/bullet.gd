extends Node3D
class_name Bullet

@export var speed = 100
@export var damage = 5

const KILL_TIME = 2
var timer = 0

func _physics_process(delta):
	var direction = global_transform.basis.z.normalized()
	global_translate(direction * speed * delta)
	
	timer += delta
	if timer >= KILL_TIME:
		queue_free()


func _on_area_3d_body_entered(body: Node):
	queue_free()
	
	if body.has_node("Stats"):
		var stats = body.get_node("Stats") as Stats
		stats.take_hit(damage)
		
