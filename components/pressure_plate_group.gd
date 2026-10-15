class_name PressurePlateGroup
extends Node3D
## Puzzle made of the PressurePlateComponent children of this node: it is solved
## when all of them are held down at the same time. The server checks the plates
## and broadcasts the result, so solved fires on every peer (connect it to
## things like CastleGate.open and ScenePortalComponent.unlock).

signal solved

var _plates: Array[PressurePlateComponent] = []
var _solved: bool = false


func _ready() -> void:
	for child: Node in get_children():
		var plate: PressurePlateComponent = child as PressurePlateComponent
		if plate == null:
			continue
		_plates.append(plate)
		plate.pressed_changed.connect(_on_plate_pressed_changed)


func _on_plate_pressed_changed(_pressed: bool) -> void:
	if not multiplayer.is_server() or _solved:
		return

	for plate: PressurePlateComponent in _plates:
		if not plate.is_pressed:
			return

	_solve.rpc()


@rpc("reliable", "call_local")
func _solve() -> void:
	if _solved:
		return
	_solved = true
	for plate: PressurePlateComponent in _plates:
		plate.lock()
	solved.emit()
