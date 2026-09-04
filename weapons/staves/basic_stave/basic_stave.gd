class_name BasicStave
extends Weapon

@onready var projectile_spawn_point: Marker3D = $ProjectileSpawnPoint
@onready var projectile_scene: PackedScene = preload("res://weapons/staves/projectile.tscn")
@onready var projectiles: Node3D = $Projectiles

@export var projectile_speed: float = 10.0

func _init() -> void:
	weapon_name = "Basic Stave"
	damage = 15

func _attack(_aim_direction: Vector3) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.damage = damage
	projectile.speed = projectile_speed
	projectile.direction = _aim_direction
	projectiles.add_child(projectile)
	projectile.global_position = projectile_spawn_point.global_position
