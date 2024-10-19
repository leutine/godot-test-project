class_name Player extends CharacterBody3D

signal died(player)
signal spawned(player)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var run_speed = 10.0
var dodge_duration = 0.1
var health: int = 20
var default_collision_mask = collision_mask
var is_dead: bool = false

@onready var rotation_speed := 10.0
@onready var gun_controller = $GunController
@onready var dodge: Dodge = $Dodge
@onready var camera_controller: Node3D = $CameraController
@onready var hand: Marker3D = $RotationRoot/Hand
@onready var _rotation_root: Node3D = $RotationRoot
@onready var character_model: Node3D = $RotationRoot/CharacterModel
@onready var character_model_anim_player: AnimationPlayer = $RotationRoot/CharacterModel/AnimationPlayer
@onready var input = $PlayerInput

var is_on_floor_: bool = true
var material = StandardMaterial3D.new()


@export var name_label_text := "Player":
	set(text):
		name_label_text = text
		$NameLabel.text = text

@export var color := Color.BLACK:
	set(new_color):
		color = new_color
		material.albedo_color = new_color

func _apply_gravity(delta):
	if not is_on_floor_:
		velocity.y -= gravity * delta

func _move(delta: float) -> void:
	is_on_floor_ = is_on_floor()

	# Handle jump.
	if input.jump_input > 0 and is_on_floor():
		velocity.y = JUMP_VELOCITY * input.jump_input

	var speed = run_speed if input.run_input else SPEED
	# if Input.is_action_just_pressed("dodge") and !dodge.is_dashing() and dodge.can_dash:
	# 	dodge.start_dash(dodge_duration)

	var direction: Vector3 = (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	direction = camera_controller.global_transform.basis * direction
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()
	
func _animate(delta: float) -> void:
	hand.look_at(camera_controller.get_aim_target())
	character_model_anim_player.speed_scale = 1.0

	# Handle jump.
	if not is_on_floor_:
		character_model_anim_player.speed_scale = 1.0
		character_model_anim_player.play("jump_short")

	# Handle run
	if input.run_input:
		character_model_anim_player.speed_scale = 1.5
	if not is_on_floor_:
		character_model_anim_player.speed_scale = 1.0

	# Handle direction
	var direction: Vector3 = (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	direction = camera_controller.global_transform.basis * direction
	if direction:
		_set_orientation_to_direction(-direction, delta)
		if character_model_anim_player.current_animation != "running" and is_on_floor_:
			character_model_anim_player.play("running")
	else:
		if character_model_anim_player.current_animation != "idle" and is_on_floor_:
			character_model_anim_player.play("idle")

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if is_multiplayer_authority():
		_move(delta)
	else:
		_animate(delta)


func _unhandled_input(_event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	if _event.is_action_pressed("spawn_mob"):
		die()

	if _event.is_action_pressed("swap_weapon"):
		swap_weapon.rpc()

	if _event.is_action_pressed("primary_action"):
		shoot.rpc()
	
	if _event.is_action_pressed("ui_accept") and is_dead:
		respawn()

# TODO: ничего не понятно, но очень интересно
# спасибо https://github.com/BatteryAcid/godot-3d-multiplayer-template/blob/dev-3d-multiplayer-template/scripts/player.gd
func _set_orientation_to_direction(direction: Vector3, delta: float) -> void:
	var from = _rotation_root.global_transform.basis
	var to = Basis(Vector3.UP.cross(direction), Vector3.UP, direction).get_rotation_quaternion()
	var model_transform = Basis(from.slerp(to, delta * rotation_speed))
	model_transform = model_transform.orthonormalized()
	_rotation_root.global_transform.basis = model_transform

func _enter_tree() -> void:
	$PlayerInput.set_multiplayer_authority(str(name).to_int())
	$CameraController.set_multiplayer_authority(str(name).to_int())
	material.albedo_color = color
	$RotationRoot/CharacterModel/RootNode/GeneralSkeleton/Beta_Surface.material_override = material

func _ready() -> void:
	if camera_controller.is_multiplayer_authority():
		camera_controller.setup(self)

@rpc("call_local")
func swap_weapon():
	if not is_multiplayer_authority(): return
	gun_controller.swap()


@rpc("call_local")
func shoot():
	if not is_multiplayer_authority(): return
	gun_controller.shoot()


func respawn():
	visible = true
	is_dead = false
	health = 20
	spawned.emit(self)
	#Networking.server_player_spawned.rpc_id(1, Networking.players[multiplayer.get_unique_id()])


func die():
	visible = false
	is_dead = true
	died.emit(self)
	#Networking.server_player_died.rpc_id(1, multiplayer.get_unique_id())


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
