class_name MeleeAttackComponent
extends AttackComponent
## Swing: damages every HitboxComponent overlapping the reach volume of
## `hitbox`, filtered to the horizontal `arc_degrees` arc around the aim.
## Resolved on the server (see AttackComponent). The animated blade is purely
## cosmetic and never sampled here (Design A).

@export var arc_degrees: float = 120.0
## Area3D whose collision shapes define the melee reach volume (Design A: a
## stable, non-animated volume — the cosmetic blade swings separately).
@export var hitbox: Area3D

## Physics layers the swing can touch (default: enemy_hitbox).
@export_flags_3d_physics var hit_mask: int = 4


func _attack(direction: Vector3) -> void:
	if direction.length_squared() == 0.0:
		return
	if hitbox == null:
		return
	var aim: Vector3 = direction.normalized()
	# Aim and enemy offsets are compared in the horizontal (XZ) plane only:
	# enemies stand on the ground and their Area3D origin is at their feet, so
	# a 3D comparison rejects nearby enemies as being "below" the aim.
	var aim_h: Vector3 = Vector3(aim.x, 0.0, aim.z)
	var has_aim_h: bool = aim_h.length_squared() > 0.000001
	if has_aim_h:
		aim_h = aim_h.normalized()
	var cos_half_arc: float = cos(deg_to_rad(arc_degrees * 0.5))
	var damaged: Dictionary = {}
	for child: Node in hitbox.get_children():
		var blade: CollisionShape3D = child as CollisionShape3D
		if blade == null or blade.shape == null:
			continue
		var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		query.shape = blade.shape
		query.transform = blade.global_transform
		query.collision_mask = hit_mask
		query.collide_with_bodies = true
		query.collide_with_areas = true
		for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 32):
			var target: HitboxComponent = hit["collider"] as HitboxComponent
			if target == null or damaged.has(target):
				continue
			var offset: Vector3 = target.global_position - global_position
			if offset != Vector3.ZERO:
				var offset_h: Vector3 = Vector3(offset.x, 0.0, offset.z)
				var in_arc: bool = true
				if has_aim_h and offset_h.length_squared() > 0.000001:
					in_arc = aim_h.dot(offset_h.normalized()) >= cos_half_arc
				if not in_arc:
					continue
			damaged[target] = true
			target.take_damage(damage)
