class_name HealthComponent
extends Node
## Server-authoritative health. Only the server applies damage; the new value
## is broadcast to every peer so signals fire everywhere.

signal health_changed(current_health: int, max_health: int)
signal died

@export var max_health: int = 6

var current_health: int


func _ready() -> void:
	current_health = max_health


func is_dead() -> bool:
	return current_health <= 0


func take_damage(amount: int) -> void:
	if not multiplayer.is_server() or is_dead():
		return
	_set_health.rpc(maxi(current_health - amount, 0))


# any_peer because the owning node's authority may be a client (players),
# but only the server is allowed to change health.
@rpc("any_peer", "call_local", "reliable")
func _set_health(value: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	current_health = value
	health_changed.emit(current_health, max_health)
	if is_dead():
		died.emit()
