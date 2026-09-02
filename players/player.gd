extends CharacterBody3D

@export var move_speed: float = 5
@export var jump_speed: float = 7
@export var acceleration: float = 20
@export var mouse_sensitivity: float = 0.05 
@export var camera_min_pitch: float = -20
@export var camera_max_pitch: float = 30

@onready var label_3d: Label3D = $Label3D
@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var sync_timer: Timer = $SyncTimer
@onready var model: Node3D = $Model
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm_3d: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera_3d: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	sync_timer.timeout.connect(_on_sync_timeout)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		test.rpc()

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
	add_to_group("players")


@rpc("call_local")
func test() -> void:
	var current_player: String = Game.get_current_player().name
	Debug.log(current_player, 10)
	


func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if is_on_floor() and input_synchronizer.jump:
		velocity.y = jump_speed
		input_synchronizer.jump = false
	
	var move_input: Vector2 = input_synchronizer.move_input
	
	var direction: Vector3 = model.transform.basis * Vector3(move_input.x, 0, move_input.y)
	
	var target: Vector2 = Vector2(direction.x, direction.z) * move_speed
	var current_speed: Vector2 = Vector2(velocity.x, velocity.z)
	var result: Vector2 = current_speed.move_toward(target, acceleration * delta)
	
	velocity.x = result.x
	velocity.z = result.y
	
	move_and_slide()

	
	#send_data.rpc(global_position)


#@rpc("call_remote", "unreliable_ordered")
#func send_data(pos: Vector3) -> void:
#	global_position = pos
	
	
	
func _on_sync_timeout() -> void:
	_sync(global_position, velocity)
	

func _sync(pos: Vector3, vel: Vector3) -> void:
	global_position = global_position.lerp(pos, 0.5)
	velocity = velocity.lerp(vel, 0.5)
