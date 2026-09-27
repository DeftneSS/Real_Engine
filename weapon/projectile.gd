class_name Projectile
extends Area3D

@export var damage: int = 0
@export var max_distance: float = 50.0
@export var speed: float = 1.0
@export var direction: Vector3 = Vector3.FORWARD.normalized()

var _total_distance: float = 0
var _has_hit: bool = false

func _ready() -> void:
	# Hits are resolved on the server; freeing there despawns it on every peer.
	if multiplayer.is_server():
		area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	# Simulated on the server only; clients render the position replicated by
	# the MultiplayerSynchronizer.
	if not multiplayer.is_server():
		return
	var distance: float = speed * delta
	_total_distance += distance
	if _total_distance >= max_distance:
		# Freeing on the server despawns it on every peer.
		queue_free()
		return
	global_position += distance * direction

func _on_area_entered(area: Area3D) -> void:
	var entered_hitbox: HitboxComponent = area as HitboxComponent
	if _has_hit or entered_hitbox == null:
		return
	_has_hit = true
	entered_hitbox.take_damage(damage)
	queue_free()
