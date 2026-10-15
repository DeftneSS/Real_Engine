class_name Level
extends Node3D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@onready var spawn_points: Node3D = $SpawnPoints
@onready var enemy_spawn_points: Node3D = $EnemySpawnPoints
@onready var players: Node3D = $Players
@onready var enemies: Node3D = $Enemies
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var end_screen: CanvasLayer = get_node_or_null("EndScreen")

var _ended: bool = false


func _ready() -> void:
	player_spawner.spawn_function = _spawn_player
	if end_screen:
		end_screen.hide()
	enemies.child_exiting_tree.connect(_on_enemy_removed)

	if not multiplayer.is_server():
		return

	await get_tree().create_timer(0.5).timeout
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

	var health: HealthComponent = player_inst.get_node("HealthComponent")
	health.died.connect(_check_end_conditions, CONNECT_DEFERRED)

	return player_inst


func _on_enemy_removed(_node: Node) -> void:
	_check_end_conditions.call_deferred()


func _check_end_conditions() -> void:
	if not is_inside_tree() or _ended or end_screen == null:
		return
	if not multiplayer.is_server():
		return

	if get_tree().get_nodes_in_group("players").is_empty():
		_ended = true
		_show_end.rpc(false)
		return

	if not has_victory_condition():
		return

	if enemies_remaining() == 0:
		_ended = true
		_show_end.rpc(true)


@rpc("reliable", "call_local")
func _show_end(victory: bool) -> void:
	if end_screen == null:
		return
	var label: Label = end_screen.get_node("Label")
	label.text = "¡VICTORIA!" if victory else "DERROTA"
	end_screen.show()

func has_victory_condition() -> bool:
	return false

func enemies_remaining() -> int:
	var count: int = 0
	for child: Node in enemies.get_children():
		if child is Enemy:
			count += 1
	return count
