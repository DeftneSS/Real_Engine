class_name CastleGate
extends Node3D
## Double door. open() swings both leaves toward the gate's -Z side (the side
## players approach from). It only animates locally, so call it on every peer.

@export var open_angle_degrees: float = 100.0
@export var open_duration: float = 1.5

var _is_open: bool = false

@onready var _door_left: Node3D = $DoorLeft
@onready var _door_right: Node3D = $DoorRight


func open() -> void:
	if _is_open:
		return
	_is_open = true

	for door: Node3D in [_door_left, _door_right]:
		# The door mesh pivot is the centre of its bottom edge and both leaves
		# meet at x = 0, so each hinge sits at twice the leaf's x offset.
		var hinge: Vector3 = Vector3(door.position.x * 2.0, door.position.y, door.position.z)
		var target_angle: float = -signf(door.position.x) * deg_to_rad(open_angle_degrees)
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_method(_swing.bind(door, hinge, door.transform), 0.0, target_angle, open_duration)


func _swing(angle: float, door: Node3D, hinge: Vector3, closed: Transform3D) -> void:
	var pivot: Transform3D = Transform3D(Basis.IDENTITY, hinge)
	door.transform = pivot * Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO) * pivot.affine_inverse() * closed
