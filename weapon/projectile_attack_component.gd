class_name ProjectileAttackComponent
extends AttackComponent
## Fires `projectile_scene` through a private MultiplayerSpawner: the server
## spawns it once and every peer builds its own copy from the same data
## (never add_child projectiles directly — that creates duplicates on peers).

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 10.0

var _spawner: MultiplayerSpawner


func _ready() -> void:
	super._ready()
	if projectile_scene == null:
		push_error("%s: projectile_scene is not set." % name)
	_spawner = MultiplayerSpawner.new()
	_spawner.name = "ProjectileSpawner"
	# Spawn into the spawner itself: being a plain Node, its Node3D children
	# live in world space instead of following the wielder around.
	_spawner.spawn_path = NodePath(".")
	_spawner.spawn_function = _spawn_projectile
	add_child(_spawner)


# Runs on the server only (see AttackComponent.attack).
func _attack(aim_direction: Vector3) -> void:
	if projectile_scene == null:
		return
	_spawner.spawn({
		"origin": global_position,
		"direction": aim_direction.normalized(),
		"speed": projectile_speed,
		"damage": damage,
	})


func _spawn_projectile(data: Dictionary) -> Node:
	var projectile: Projectile = projectile_scene.instantiate()
	# The spawner is not a Node3D, so local position is world position.
	projectile.position = data["origin"]
	projectile.direction = data["direction"]
	projectile.speed = data["speed"]
	projectile.damage = data["damage"]
	return projectile
