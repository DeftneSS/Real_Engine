class_name BasicStave
extends Weapon

@onready var orb: MeshInstance3D = $Orb
@onready var projectile_scene: PackedScene = preload("res://weapons/staves/projectile.tscn")
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner

@export var projectile_speed: float = 10.0

func _init() -> void:
	weapon_name = "Basic Stave"
	damage = 15

func _attack(_aim_direction: Vector3) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.damage = damage
	projectile.speed = projectile_speed
	projectile.direction = _aim_direction
	projectile_spawner.add_child(projectile)
	projectile.global_position = orb.global_position
