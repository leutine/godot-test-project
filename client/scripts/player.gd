extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

#@export var teleport_distance = 5.0
var dodge_speed = 50.0
var dodge_duration = 0.1

var health: int = 20

@export var rotation_speed := 12.0

@onready var start_position = position
@onready var gun_controller = $GunController
@onready var name_label: Label3D = $NameLabel
@onready var dodge: Dodge = $Dodge
@onready var mp_sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var camera_controller: Node3D = $CameraController
@onready var hand: Marker3D = $RotationRoot/Hand
@onready var material: StandardMaterial3D = StandardMaterial3D.new()
@onready var _rotation_root: Node3D = $RotationRoot
@onready var _move_direction := Vector3.ZERO

@onready var character_model: Node3D = $RotationRoot/CharacterModel
@onready var character_model_surface: MeshInstance3D = $RotationRoot/CharacterModel/RootNode/GeneralSkeleton/Beta_Surface
@onready var character_model_anim_player: AnimationPlayer = $RotationRoot/CharacterModel/AnimationPlayer

var name_label_text = "Player"
var default_collision_mask = collision_mask
var color = Color.BLACK
var is_dead: bool = false

signal spawned_mob
signal died(player)
signal spawned(player)


func _physics_process(delta: float) -> void:
	if Server.is_connected_to_server or not is_multiplayer_authority() or is_dead: return
	character_model_anim_player.speed_scale = 1.0
	# Add the gravity.
	if not is_on_floor():
		#character_model_anim_player.play("jump")
		#character_model_anim_player.speed_scale = 2.0
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		#character_model_anim_player.play("jump")
		#character_model_anim_player.speed_scale = 2.0
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
	
	direction = camera_controller.global_transform.basis * direction
	hand.look_at(camera_controller.get_aim_target())
	if direction:
		_orient_character_to_direction(-direction, delta)
		if character_model_anim_player.current_animation != "running" and is_on_floor():
			character_model_anim_player.play("running")
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

	if _event.is_action_pressed("spawn_mob"):
#		spawn_mob.rpc(mouse_position)
		die()

	if _event.is_action_pressed("swap_weapon"):
		swap_weapon.rpc()

	if _event.is_action_pressed("primary_action"):
		shoot.rpc()
	
	if _event.is_action_pressed("ui_accept") and is_dead:
		respawn()


func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := Vector3.UP.cross(direction)
	var rotation_basis := Basis(left_axis, Vector3.UP, direction).get_rotation_quaternion()
	var model_scale := _rotation_root.transform.basis.get_scale()
	_rotation_root.transform.basis = Basis(_rotation_root.transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * rotation_speed)).scaled(model_scale)


func _ready():
	name_label.text = name_label_text
	material.albedo_color = color
	character_model_surface.material_override = material
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_controller.setup(self)
	camera_controller.camera.current = true


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


func respawn():
	visible = true
	is_dead = false
	health = 20
	spawned.emit(self)
	Server.server_player_spawned.rpc_id(1, Server.players[multiplayer.get_unique_id()])


func die():
	visible = false
	is_dead = true
	died.emit(self)
	Server.server_player_died.rpc_id(1, multiplayer.get_unique_id())


func reset_rotation():
	character_model.rotation = Vector3.ZERO


func get_hit(damage: int) -> void:
	print("Player %s got %s damage!" % [self, damage])
	var tween = create_tween().set_loops(1)
	tween.tween_property(character_model, "rotation", Vector3(0, 0, 1.0), 0.15)
	tween.tween_callback(reset_rotation)
	health -= damage
	if health <= 0:
		die()
