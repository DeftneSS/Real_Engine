class_name HitboxComponent
extends Area3D
## Area that can be hit. Forwards damage to a HealthComponent (server only).

@export var health_component: HealthComponent
## Seconds during which further hits are ignored after taking damage.
@export var invulnerability_time: float = 0.0

var _invulnerable_until_msec: int = 0


func take_damage(amount: int) -> void:
	if not multiplayer.is_server() or health_component == null:
		return
	var now: int = Time.get_ticks_msec()
	if now < _invulnerable_until_msec:
		return
	_invulnerable_until_msec = now + int(invulnerability_time * 1000)
	health_component.take_damage(amount)
