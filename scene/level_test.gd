extends Node3D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@onready var spawn_points: Node3D = $SpawnPoints
@onready var enemy_spawn_points: Node3D = $EnemySpawnPoints
@onready var players: Node3D = $Players
@onready var enemies: Node3D = $Enemies
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

func _ready() -> void:
	player_spawner.spawn_function = _spawn_player
	if not multiplayer.is_server():
		return
	for player_data: Statics.PlayerData in Game.instance.players:
		player_spawner.spawn(player_data.to_dict())

	for i: int in enemy_spawn_points.get_child_count():
		var enemy_inst: Enemy = enemy_scene.instantiate()
		enemy_inst.name = "Enemy%d" % i
		enemies.add_child(enemy_inst)
		enemy_inst.global_position = enemy_spawn_points.get_child(i).global_position


func _spawn_player(data: Dictionary) -> Node:
	var player_data: Statics.PlayerData = Statics.PlayerData.from_dict(data)

	var player_inst: Player = player_scene.instantiate()
	player_inst.name = str(player_data.id)
	player_inst.set_multiplayer_authority(player_data.id)
	var spawn_point: Node3D = spawn_points.get_child(player_data.index)
	player_inst.position = spawn_point.global_position

	return player_inst


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
