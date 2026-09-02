extends Node3D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@onready var spawn_points: Node3D = $SpawnPoints
@onready var enemy_spawn_points: Node3D = $EnemySpawnPoints
@onready var players: Node3D = $Players
@onready var enemies: Node3D = $Enemies

func _ready() -> void:
	for i: int in Game.instance.players.size():
		var player_data: Statics.PlayerData = Game.players[i]
		var player_inst = player_scene.instantiate()
		player_inst.name = str(player_data.id)
		players.add_child(player_inst)
		player_inst.setup(player_data)
		player_inst.global_position = spawn_points.get_child(i).global_position

	if multiplayer.is_server():
		for i: int in enemy_spawn_points.get_child_count():
			var enemy_inst = enemy_scene.instantiate()
			enemy_inst.name = "Enemy%d" % i
			enemies.add_child(enemy_inst)
			enemy_inst.global_position = enemy_spawn_points.get_child(i).global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
