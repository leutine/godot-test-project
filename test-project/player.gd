extends CharacterBody3D
class_name Player

@export var move_speed = 1000.0
@export var teleport_distance = 5.0
@export var dodge_speed = 4000.0
@export var dodge_duration = 0.1

@export var name_label_text = "Player"
@export var color = Color.BLACK
@onready var start_position = position
@onready var gun_controller = $GunController
@onready var pivot = $Mesh
@onready var body: MeshInstance3D = $Mesh/Body
@onready var name_label: Label3D = $NameLabel
@onready var dodge = $Dodge

@onready var material: StandardMaterial3D = StandardMaterial3D.new()
var default_collision_mask = collision_mask


signal spawned_mob
signal swapped_weapon


func get_mouse_position():
	if not is_multiplayer_authority(): return
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera_3d()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 2000
	var intersection = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))
	var target = intersection.get("position", Vector3())
	target.y = position.y
	return target


func _physics_process(delta):
	if not is_multiplayer_authority(): return
	var mouse_position: Vector3 = get_mouse_position()
	if global_transform.origin != mouse_position:
		look_at(mouse_position, Vector3.UP)
	
	var move_direction2: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction3: Vector3 = Vector3(move_direction2.x, 0, move_direction2.y)
	move_direction3 = move_direction3.normalized()
	if Input.is_action_just_pressed("dodge") and !dodge.is_dashing() and dodge.can_dash:
#		teleport.rpc(move_direction3)
		dodge.start_dash(dodge_duration)

	if dodge.is_dashing():
		set_collision_mask_value(3, false)
	
	var speed = dodge_speed if dodge.is_dashing() else move_speed
	velocity = move_direction3 * speed * delta
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
	if Input.is_action_just_pressed("ui_accept"):
		position = start_position
		velocity = Vector3.ZERO
		
	var mouse_position: Vector3 = get_mouse_position()
	
	if Input.is_action_just_pressed("spawn_mob"):
		spawn_mob.rpc(mouse_position)
	
	if Input.is_action_just_pressed("swap_weapon"):
		swap_weapon.rpc()


func _ready():
	name_label.text = name_label_text
	material.albedo_color = color
	body.material_override = material


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


@rpc("call_local")
func spawn_mob(mob_position):
	spawned_mob.emit(mob_position)


@rpc("call_local")
func set_color(new_color: Color):
	color = new_color
	material.albedo_color = color
	body.material_override = material


func set_player_name(new_name: String):
	name_label.text = new_name


@rpc("call_local")
func swap_weapon():
	gun_controller.swap.rpc()
	swapped_weapon.emit()
