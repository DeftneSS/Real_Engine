class_name BasicStave
extends Weapon

@onready var projectile_spawn_point: Marker3D = $ProjectileSpawnPoint
@onready var projectile_scene: PackedScene = preload("res://weapons/staves/projectile.tscn")
@onready var projectile_spawner: MultiplayerSpawner = $Projectiles/MultiplayerSpawner

@export var projectile_speed: float = 10.0

func _init() -> void:
	weapon_name = "Basic Stave"
	damage = 15

func _attack(_aim_direction: Vector3) -> void:
	if not projectile_scene:
		pass
	push_error("AAAAAA %s", projectile_scene)
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.damage = damage
	projectile.global_position = projectile_spawn_point.global_position
	projectile.direction = _aim_direction
	projectile_spawner.add_child(projectile)
