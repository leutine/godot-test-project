extends CharacterBody3D
class_name Player

@export var move_speed = 1000.0
@export var teleport_distance = 5.0
@export var dodge_speed = 4000.0
@export var dodge_duration = 0.1
@export var name_label_text = "Player"
@export var color = Color.BLACK
@export var camera_zoom_step = 2
@export var gravity = 10

@onready var start_position = position
@onready var gun_controller = $GunController
@onready var pivot = $Mesh
@onready var body: MeshInstance3D = $Mesh/Body
@onready var name_label: Label3D = $NameLabel
@onready var dodge: Dodge = $Dodge
@onready var mp_sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var hand: Marker3D = $Mesh/Body/Hand

@onready var material: StandardMaterial3D = StandardMaterial3D.new()
var default_collision_mask = collision_mask
var sync_delta
var move_direction3
var default_camera_zoom
var fall_speed = 0

signal spawned_mob
signal died(player)


func get_mouse_position():
	if not is_multiplayer_authority(): return
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_position) * 100
	var intersection = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))
	var target = intersection.get("position", Vector3())
	target.y = position.y
	return target


func _process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	var mouse_position: Vector3 = get_mouse_position()
	if global_transform.origin != mouse_position:
		pivot.look_at(mouse_position, Vector3.UP)
		hand.look_at(mouse_position, Vector3.UP, true)
#	if Input.is_action_pressed("primary_action"):
#		shoot.rpc()

	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * 10)


func _physics_process(_delta):
	fall_speed = 0
	if not is_multiplayer_authority(): return
	var move_direction2: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_direction3: Vector3 = Vector3(move_direction2.x, 0, move_direction2.y)
	if Input.is_action_just_pressed("dodge") and !dodge.is_dashing() and dodge.can_dash:
#		teleport.rpc(move_direction3)
		dodge.start_dash(dodge_duration)

	if dodge.is_dashing():
		set_collision_mask_value(3, false)
	
	var speed = dodge_speed if dodge.is_dashing() else move_speed
	velocity = move_direction3 * speed
	fall_speed -= gravity
	velocity.y = fall_speed
	move_and_slide()
	collision_mask = default_collision_mask


#@rpc("any_peer", "call_local", "unreliable")
#func update_position(id, pos):
#	if not is_multiplayer_authority() and name == id:
#		position = lerp(position, pos, sync_delta * 15)


@rpc("call_local")
func teleport(direction):
	position = position + (direction * teleport_distance)
	velocity = Vector3.ZERO


func _unhandled_input(_event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
#	if _event.is_action_pressed("ui_accept"):
#		position = start_position
#		velocity = Vector3.ZERO
#		camera.position.z = default_camera_zoom
		
	var mouse_position: Vector3 = get_mouse_position()
	
	if _event.is_action_pressed("spawn_mob"):
#		spawn_mob.rpc(mouse_position)
		die()
	
	if _event.is_action_pressed("swap_weapon"):
		swap_weapon.rpc()
	
	if _event.is_action_pressed("CameraZoomIn"):
		camera_zoom(-camera_zoom_step)
	
	if _event.is_action_pressed("CameraZoomOut"):
		camera_zoom(camera_zoom_step)

	if _event.is_action_pressed("primary_action"):
		shoot.rpc()


func camera_zoom(multiplier: float):
	camera.position.z = camera.position.z + multiplier 
	

func _ready():
	name_label.text = name_label_text
	material.albedo_color = color
	body.material_override = material
	if not is_multiplayer_authority(): return
	camera_pivot.set_as_top_level(true)
	camera.current = true
	default_camera_zoom = camera.position.z


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


@rpc("call_local")
func spawn_mob(mob_position):
	spawned_mob.emit(mob_position)


func set_color(new_color: Color):
	color = new_color
	material.albedo_color = color
	body.material_override = material


func set_player_name(new_name: String):
	name_label.text = new_name


@rpc("call_local")
func swap_weapon():
#	if not is_multiplayer_authority(): return
	gun_controller.swap()


@rpc("call_local")
func shoot():
#	if not is_multiplayer_authority(): return
	gun_controller.shoot()


func die():
	print_debug("oh no, i died")
	queue_free()
	died.emit(self)

#func _on_timer_timeout() -> void:
#	if is_multiplayer_authority():
#		update_position.rpc(name, position)
