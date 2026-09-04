class_name InputSynchronizer

extends MultiplayerSynchronizer

@export var move_input: Vector2
@export var jump: bool
@export var dash: bool
@export var attack: bool

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if Input.is_action_just_pressed("jump"):
		broadcast_jump.rpc()
	
	if Input.is_action_just_pressed("dash"):
		broadcast_dash.rpc()
	
	if Input.is_action_just_pressed("attack"):
		broadcast_attack.rpc()
	

@rpc("call_local")
func broadcast_jump() -> void:
	jump = true

@rpc("call_local")
func broadcast_dash() -> void:
	dash = true

@rpc("call_local")
func broadcast_attack() -> void:
	attack = true
