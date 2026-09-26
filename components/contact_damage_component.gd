class_name ContactDamageComponent
extends Area3D
## Damages every HitboxComponent it overlaps, every physics frame (server only).
## The target hitbox's invulnerability_time limits how often damage lands.

@export var damage: int = 1


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	for area: Area3D in get_overlapping_areas():
		var hitbox: HitboxComponent = area as HitboxComponent
		if hitbox:
			hitbox.take_damage(damage)
