class_name ScenePortalComponent
extends Area3D

@export var target_scene: PackedScene
@export var require_all_players: bool = false
@export var require_enemies_cleared: bool = true
## While locked the portal never triggers; call unlock() on every peer (e.g. from a puzzle's signal).
@export var locked: bool = false

var _triggered: bool = false
var _players_inside: Array[Node3D] = []


func _ready() -> void:
	body_entered.connect(_handle_body_entered)
	body_exited.connect(_handle_body_exited)


func _handle_body_entered(body: Node3D) -> void:
	if not body.is_in_group("players"):
		return

	if not _players_inside.has(body):
		_players_inside.append(body)

	_try_trigger()


func _physics_process(_delta: float) -> void:
	if not _triggered and not _players_inside.is_empty():
		_try_trigger()


func _try_trigger() -> void:
	if not multiplayer.is_server() or _triggered or locked:
		return

	if require_all_players and _players_inside.size() < Game.instance.players.size():
		return

	if require_enemies_cleared and _enemies_remaining() > 0:
		return

	_triggered = true
	_change_scene.rpc()


func _handle_body_exited(body: Node3D) -> void:
	_players_inside.erase(body)


func unlock() -> void:
	locked = false


@rpc("reliable", "call_local")
func _change_scene() -> void:
	get_tree().change_scene_to_packed.call_deferred(target_scene)


func _enemies_remaining() -> int:
	var level: Level = get_tree().current_scene as Level
	return 0 if level == null else level.enemies_remaining()
