extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

#@export var teleport_distance = 5.0
var dodge_speed = 50.0
var dodge_duration = 0.1

@onready var start_position = position
@onready var gun_controller = $GunController
@onready var name_label: Label3D = $NameLabel
@onready var dodge: Dodge = $Dodge
@onready var mp_sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var camera_origin: Node3D = $CameraOrigin
@onready var camera_arm: Node3D = $CameraOrigin/CameraArm
@onready var camera: Camera3D = $CameraOrigin/CameraArm/Camera3D
@onready var hand: Marker3D = $Hand
@onready var material: StandardMaterial3D = StandardMaterial3D.new()

@onready var character_model_surface: MeshInstance3D = $CharacterModel/RootNode/GeneralSkeleton/Beta_Surface
@onready var character_model_anim_player: AnimationPlayer = $CharacterModel/AnimationPlayer

var name_label_text = "Player"
var default_collision_mask = collision_mask
var color = Color.BLACK

signal spawned_mob
signal died(player)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	character_model_anim_player.speed_scale = 1.0
	# Add the gravity.
	if not is_on_floor():
		character_model_anim_player.play("jump")
		character_model_anim_player.speed_scale = 2.0
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		character_model_anim_player.play("jump")
		character_model_anim_player.speed_scale = 2.0
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Dash
	if Input.is_action_just_pressed("dodge") and !dodge.is_dashing() and dodge.can_dash:
		dodge.start_dash(dodge_duration)
	if dodge.is_dashing():
		set_collision_mask_value(3, false)

	var speed = dodge_speed if dodge.is_dashing() else SPEED
	
	if direction:
		if character_model_anim_player.current_animation != "running" and is_on_floor():
			character_model_anim_player.play("running")
		#model.look_at(position + direction)
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		if character_model_anim_player.current_animation != "idle" and is_on_floor():
			character_model_anim_player.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	collision_mask = default_collision_mask


func _unhandled_input(_event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
#	if _event.is_action_pressed("ui_accept"):
#		position = start_position
#		velocity = Vector3.ZERO
#		camera.position.z = default_camera_zoom

	if _event.is_action_pressed("spawn_mob"):
#		spawn_mob.rpc(mouse_position)
		die()
	
	if _event.is_action_pressed("swap_weapon"):
		swap_weapon.rpc()


	if _event.is_action_pressed("primary_action"):
		shoot.rpc()


func get_center_position() -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var viewport_center = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)
	var ray_origin = camera.project_ray_origin(viewport_center)
	var ray_end = ray_origin + camera.project_ray_normal(viewport_center) * 1000
	var intersection = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_origin, ray_end))
	var target = intersection.get("position", Vector3())
	return target


func rotate_camera(event: InputEventMouseMotion) -> void:
	if not is_multiplayer_authority(): return
	rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
	#model.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY))
	camera_origin.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
	camera_origin.rotation.x = clamp(camera_origin.rotation.x, deg_to_rad(-90), deg_to_rad(45))
	
	var center = get_center_position()
	hand.look_at(center)


func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotate_camera(event)


#func camera_zoom(multiplier: float):
	#camera.position.z = camera.position.z + multiplier 
	

func _ready():
	name_label.text = name_label_text
	material.albedo_color = color
	character_model_surface.material_override = material
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


@rpc("call_local")
func spawn_mob(mob_position):
	spawned_mob.emit(mob_position)


func set_color(new_color: Color):
	color = new_color
	material.albedo_color = color
	character_model_surface.material_override = material


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
