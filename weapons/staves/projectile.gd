class_name Projectile
extends Node3D

@export var damage: int = 0
@export var max_distance: float = 80.0
@export var direction: Vector3 = Vector3.FORWARD.normalized()
@export var speed: float = 1.0

@onready var area_3d: Area3D = $Area3D

var _total_distance: float = 0
var _has_hit: bool = false

func _ready() -> void:
	# Hits are resolved on the server; freeing there despawns it on every peer.
	if multiplayer.is_server():
		area_3d.area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	var distance: float = speed * delta
	_total_distance += distance
	if _total_distance >= max_distance:
		if multiplayer.is_server():
			queue_free()
		return
	global_position += distance * direction

func _on_area_entered(area: Area3D) -> void:
	var hitbox: HitboxComponent = area as HitboxComponent
	if _has_hit or hitbox == null:
		return
	_has_hit = true
	hitbox.take_damage(damage)
	queue_free()
