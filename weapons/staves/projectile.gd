class_name Projectile
extends CollisionObject3D

@export var damage: int = 0
@export var max_distance: float = 100.0
@export var direction: Vector3 = Vector3.FORWARD.normalized()
@export var speed: float = 1.0

var _total_distance: float = 0

func _process(delta: float) -> void:
	var distance: float = speed * delta
	_total_distance += distance
	if _total_distance >= max_distance:
		queue_free()
		return
	global_position += distance * direction
