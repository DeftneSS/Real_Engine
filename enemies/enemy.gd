class_name Enemy
extends CharacterBody3D

@export var move_speed: float = 3
@export var acceleration: float = 20

@onready var label_3d: Label3D = $Label3D
@onready var model: Node3D = $Model


func _ready() -> void:
	label_3d.modulate = Color.RED


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var target: Node3D = _get_nearest_player()
	var target_speed: Vector2 = Vector2.ZERO
	if target:
		var direction: Vector3 = target.global_position - global_position
		direction.y = 0
		direction = direction.normalized()
		target_speed = Vector2(direction.x, direction.z) * move_speed
		model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), 0.1)

	var current_speed: Vector2 = Vector2(velocity.x, velocity.z)
	var result: Vector2 = current_speed.move_toward(target_speed, acceleration * delta)

	velocity.x = result.x
	velocity.z = result.y

	move_and_slide()


func _get_nearest_player() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance: float = INF
	for player: Node in get_tree().get_nodes_in_group("players"):
		var distance: float = global_position.distance_to((player as Node3D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = player
	return nearest
