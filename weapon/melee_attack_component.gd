class_name MeleeAttackComponent
extends AttackComponent
## Swing: damages every HitboxComponent within `range` of this component that
## lies inside the `arc_degrees` cone around the aim. Resolved on the server
## (see AttackComponent).

@export var range: float = 2.0
@export var arc_degrees: float = 120.0
## Physics layers the swing can touch (default: enemy_hitbox).
@export_flags_3d_physics var hit_mask: int = 4


func _attack(direction: Vector3) -> void:
	if direction.length_squared() == 0.0:
		return
	var aim: Vector3 = direction.normalized()

	var shape := SphereShape3D.new()
	shape.radius = range
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = hit_mask
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var cos_half_arc: float = cos(deg_to_rad(arc_degrees * 0.5))
	var damaged: Dictionary = {}
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var hitbox: HitboxComponent = hit["collider"] as HitboxComponent
		if hitbox == null or damaged.has(hitbox):
			continue
		var offset: Vector3 = hitbox.global_position - global_position
		if offset != Vector3.ZERO and aim.dot(offset.normalized()) < cos_half_arc:
			continue
		damaged[hitbox] = true
		hitbox.take_damage(damage)
