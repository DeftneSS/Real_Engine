class_name HitscanAttackComponent
extends AttackComponent
## Instant ray along the aim: the first HitboxComponent it reaches takes the
## damage, and the world blocks the shot. Resolved on the server (see
## AttackComponent).

@export var max_distance: float = 100.0
## Physics layers the ray can hit (default: world + enemy_hitbox).
@export_flags_3d_physics var hit_mask: int = 5


func _attack(direction: Vector3) -> void:
	if direction.length_squared() == 0.0:
		return
	var from: Vector3 = global_position
	var to: Vector3 = from + direction.normalized() * max_distance
	var query := PhysicsRayQueryParameters3D.create(from, to, hit_mask)
	query.collide_with_areas = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var hitbox: HitboxComponent = hit["collider"] as HitboxComponent
	if hitbox:
		hitbox.take_damage(damage)
