extends CharacterBody3D
class_name Player


signal died(player)
signal spawned(player)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var dodge_speed = 50.0
var dodge_duration = 0.1
var health: int = 20
var default_collision_mask = collision_mask
var is_dead: bool = false

@onready var rotation_speed := 12.0
@onready var gun_controller = $GunController
@onready var dodge: Dodge = $Dodge
@onready var camera_controller: Node3D = $CameraController
@onready var hand: Marker3D = $RotationRoot/Hand
@onready var _rotation_root: Node3D = $RotationRoot
@onready var character_model: Node3D = $RotationRoot/CharacterModel
@onready var character_model_anim_player: AnimationPlayer = $RotationRoot/CharacterModel/AnimationPlayer
@onready var input = $PlayerInput
@onready var name_label: Label3D = $NameLabel
@onready var character_model_surface: MeshInstance3D = $RotationRoot/CharacterModel/RootNode/GeneralSkeleton/Beta_Surface


@export var name_label_text := "Player":
	set(text):
		$NameLabel.text = text


@export var color := Color.BLACK:
	set(new_color):
		var material = StandardMaterial3D.new()
		material.albedo_color = new_color
		$RotationRoot/CharacterModel/RootNode/GeneralSkeleton/Beta_Surface.material_override = material


func _physics_process(delta: float) -> void:
	character_model_anim_player.speed_scale = 1.0

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if input.jumping and is_on_floor():
		character_model_anim_player.play("jump")
		character_model_anim_player.speed_scale = 2.0
		velocity.y = JUMP_VELOCITY
	
	# Reset jump state.
	input.jumping = false

	var direction: Vector3 = (transform.basis * Vector3(input.direction.x, 0, input.direction.y)).normalized()
	
	# Dash
	var speed = dodge_speed if dodge.is_dashing() else SPEED
	# if Input.is_action_just_pressed("dodge") and !dodge.is_dashing() and dodge.can_dash:
	# 	dodge.start_dash(dodge_duration)

	# TODO: починить поворот игрока вслед за камерой (сейчас игрок всегда смотрит прямо)
	# сервер не получает инфу о повороте камеры, надо как-то синхронизировать его, но через CameraSynchronizer не получилось
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
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()


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


func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := Vector3.UP.cross(direction)
	var rotation_basis := Basis(left_axis, Vector3.UP, direction).get_rotation_quaternion()
	var model_scale := _rotation_root.transform.basis.get_scale()
	_rotation_root.transform.basis = Basis(_rotation_root.transform.basis.get_rotation_quaternion().slerp(rotation_basis, delta * rotation_speed)).scaled(model_scale)

func _enter_tree() -> void:
	$PlayerInput.set_multiplayer_authority(str(name).to_int())
	$CameraController.set_multiplayer_authority(str(name).to_int())

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
