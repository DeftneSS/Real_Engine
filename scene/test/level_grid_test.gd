extends Camera3D

## Free-fly camera for the tileset test scene.
## WASD to move, Q/E (or Space/Ctrl) to go down/up, Shift to sprint,
## hold right mouse button to look around, R to return to the start view.

@export var speed: float = 14.0
@export var sprint_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.0025

var _looking: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _start_transform: Transform3D


func _ready() -> void:
	_start_transform = global_transform
	_yaw = rotation.y
	_pitch = rotation.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_looking = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _looking else Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseMotion and _looking:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.45, 1.45)
		rotation = Vector3(_pitch, _yaw, 0.0)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			global_transform = _start_transform
			_yaw = rotation.y
			_pitch = rotation.x
		elif event.keycode == KEY_ESCAPE:
			_looking = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	if Input.is_action_pressed("jump") or Input.is_key_pressed(KEY_E):
		direction += Vector3.UP
	if Input.is_action_pressed("dash") or Input.is_key_pressed(KEY_Q):
		direction -= Vector3.UP

	if direction == Vector3.ZERO:
		return

	var current_speed: float = speed * (sprint_multiplier if Input.is_action_pressed("dash") else 1.0)
	global_position += direction.normalized() * current_speed * delta
