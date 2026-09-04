class_name Player

extends CharacterBody3D

@onready var label_3d: Label3D = $Label3D
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var sync_timer: Timer = $SyncTimer
@onready var model: Node3D = $Model
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm_3d: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera_3d: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer

@onready var weapon_socket: Node3D = $Model/WeaponSocket

@onready var basic_stave_scene: PackedScene = preload("res://weapons/staves/basic_stave/basic_stave.tscn")

@export var move_speed: float = 5
@export var jump_speed: float = 7

@export var dash_speed: float = 50
@export var can_dash: bool = true
@export var acceleration: float = 20
@export var is_dashing: bool = false
@export var dash_direction: Vector3 = Vector3.ZERO
@export var dash_friction: float = 120

@export var mouse_sensitivity: float = 0.05 
@export var camera_min_pitch: float = -20
@export var camera_max_pitch: float = 30

var _weapon: Weapon

func _ready() -> void:
	sync_timer.timeout.connect(_on_sync_timeout)
	
	var player_data: Statics.PlayerData = Game.instance.get_player(get_multiplayer_authority())
	label_3d.text = player_data.name
	set_multiplayer_authority(player_data.id)
	camera_3d.current = is_multiplayer_authority()
	if is_multiplayer_authority():
		sync_timer.start()
	add_to_group("players")
	
	_weapon = basic_stave_scene.instantiate()
	weapon_socket.add_child(_weapon)


	
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion:
		camera_pivot.rotation.y -= mouse_motion.relative.x * mouse_sensitivity
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x - mouse_motion.relative.y * mouse_sensitivity,
			deg_to_rad(camera_min_pitch), deg_to_rad(camera_max_pitch))
		model.rotation.y = lerp_angle(model.rotation.y, camera_pivot.rotation.y, 1)



func setup(player_data: Statics.PlayerData) -> void:
	label_3d.text = player_data.name
	set_multiplayer_authority(player_data.id)
	camera_3d.current = is_multiplayer_authority()
	sync_timer.start()
	

@rpc("call_local")
func test() -> void:
	var current_player: String = Game.get_current_player().name
	Debug.log(current_player, 10)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if input_synchronizer.jump:
		if is_on_floor():
			velocity.y = jump_speed
		input_synchronizer.jump = false
	
	var move_input: Vector2 = input_synchronizer.move_input
	var direction: Vector3 = model.transform.basis * Vector3(move_input.x, 0, move_input.y)
	
	if input_synchronizer.dash:
		input_synchronizer.dash = false
		if can_dash:
			if direction.length() > 0.01:
				dash_direction = direction.normalized()
			else:
				dash_direction = -model.transform.basis.z.normalized()
			is_dashing = true
			can_dash = false
			dash_timer.start()
			dash_cooldown_timer.start()
	
	if is_dashing:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	else:
		if input_synchronizer.attack:
			input_synchronizer.attack = false
			attack()
		
		var target: Vector2 = Vector2(direction.x, direction.z) * move_speed
		var current_speed: Vector2 = Vector2(velocity.x, velocity.z)
		var decel: float = acceleration
		if current_speed.length() > move_speed:
			decel = dash_friction
		var result: Vector2 = current_speed.move_toward(target, decel * delta)
		
		velocity.x = result.x
		velocity.z = result.y
	
	move_and_slide()
	

func attack() -> void:
	var direction: Vector3 = -camera_3d.global_transform.basis.z
	_weapon.attack(direction)

func _on_sync_timeout() -> void:
	_sync.rpc(global_position, velocity)
	

@rpc()
func _sync(pos: Vector3, vel: Vector3) -> void:
	global_position = global_position.lerp(pos, 0.5)
	velocity = velocity.lerp(vel, 0.5)


func _on_dash_timer_timeout() -> void:
	is_dashing = false


func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true
