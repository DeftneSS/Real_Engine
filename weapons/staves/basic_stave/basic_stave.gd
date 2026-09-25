class_name BasicStave
extends Weapon

@onready var orb: MeshInstance3D = $Orb
@onready var projectile_scene: PackedScene = preload("res://weapons/staves/projectile.tscn")
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner

@export var projectile_speed: float = 10.0

func _init() -> void:
	weapon_name = "Basic Stave"
	damage = 15

func _ready() -> void:
	super()
	projectile_spawner.spawn_function = _spawn_projectile

# Runs only on the wielder's peer (see Player.attack).
func _attack(_aim_direction: Vector3) -> void:
	_request_projectile.rpc_id(1, orb.global_position, _aim_direction)

@rpc("any_peer", "call_local", "reliable")
func _request_projectile(origin: Vector3, aim_direction: Vector3) -> void:
	if multiplayer.get_remote_sender_id() != wielder_id:
		return
	projectile_spawner.spawn({
		"origin": origin,
		"direction": aim_direction.normalized(),
		"speed": projectile_speed,
		"damage": damage,
	})

func _spawn_projectile(data: Dictionary) -> Node:
	var projectile: Projectile = projectile_scene.instantiate()
	projectile.damage = data.damage
	projectile.speed = data.speed
	projectile.direction = data.direction
	# The spawner is not a Node3D, so local position is world position.
	projectile.position = data.origin
	return projectile
