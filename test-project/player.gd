extends CharacterBody3D
class_name Player

@export var speed = 10.0
@export var teleport_distance = 5.0
@export var dodge_speed = 500.0
@export var name_label_text = "Player"
@onready var start_position = position
@onready var gun_controller = $GunController
@onready var pivot = $Mesh
@onready var body: MeshInstance3D = $Mesh/Body
@onready var name_label: Label3D = $NameLabel
@onready var mpsync: MultiplayerSynchronizer = $MultiplayerSynchronizer
var default_collision_mask = collision_mask


signal spawned_mob


func get_mouse_position():
	if not is_multiplayer_authority(): return
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera_3d()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 2000
	var intersection = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))
	var target = intersection.get("position", Vector3())
	target.y = pivot.position.y
	return target


func _physics_process(_delta):
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("ui_accept"):
		print("reset!")
		position = start_position
		velocity = Vector3.ZERO
	
	var mouse_position: Vector3 = get_mouse_position()
	if global_transform.origin != mouse_position:
		pivot.look_at(mouse_position, Vector3.UP)
	
	var move_direction2: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction3: Vector3 = Vector3(move_direction2.x, 0, move_direction2.y)
	move_direction3 = move_direction3.normalized()
	if Input.is_action_just_pressed("dodge") and move_direction3 != Vector3.ZERO:
#		teleport.rpc(move_direction3)
		velocity = move_direction3 * dodge_speed
		set_collision_mask_value(3, false)
	else:
		velocity = move_direction3 * speed
	move_and_slide()
	collision_mask = default_collision_mask
	if Input.is_action_pressed("primary_action"):
		gun_controller.shoot.rpc()

@rpc("call_local")
func teleport(direction):
	position = position + (direction * teleport_distance)
	velocity = Vector3.ZERO

func _unhandled_input(_event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	var mouse_position: Vector3 = get_mouse_position()
	
	if Input.is_action_just_pressed("spawn_mob"):
		spawn_mob.rpc(mouse_position)


func _ready():
	name_label.text = name_label_text


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


@rpc("call_local")
func spawn_mob(mob_position):
	spawned_mob.emit(mob_position)


func set_color(color: Color):
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	body.material_override = material
