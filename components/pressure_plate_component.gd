class_name PressurePlateComponent
extends Area3D
## Server-authoritative pressure plate: pressed while any node of the "players"
## group stands on it. The server broadcasts each change so every peer sees the
## plate sink/light up and pressed_changed fires everywhere.

signal pressed_changed(pressed: bool)

@export var pressed_depth: float = 0.06
@export var idle_color: Color = Color(0.8, 0.15, 0.1)
@export var pressed_color: Color = Color(0.2, 0.9, 0.3)

var is_pressed: bool = false

var _locked: bool = false

@onready var _plate: MeshInstance3D = $Plate
@onready var _rest_y: float = _plate.position.y
@onready var _material: StandardMaterial3D = _plate.material_override.duplicate() as StandardMaterial3D


func _ready() -> void:
	_plate.material_override = _material
	_update_visuals()
	set_physics_process(multiplayer.is_server())


# Polls overlaps instead of using body_entered/exited so a player that dies on
# the plate (and leaves the "players" group) releases it.
func _physics_process(_delta: float) -> void:
	if _locked:
		return

	var pressed: bool = false
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group("players"):
			pressed = true
			break

	if pressed != is_pressed:
		_set_pressed.rpc(pressed)


## Keeps the plate pressed for good (used once its puzzle is solved).
func lock() -> void:
	_locked = true
	is_pressed = true
	_update_visuals()


@rpc("reliable", "call_local")
func _set_pressed(pressed: bool) -> void:
	if _locked:
		return
	is_pressed = pressed
	_update_visuals()
	pressed_changed.emit(pressed)


func _update_visuals() -> void:
	_plate.position.y = _rest_y - (pressed_depth if is_pressed else 0.0)
	var color: Color = pressed_color if is_pressed else idle_color
	_material.albedo_color = color
	_material.emission = color
