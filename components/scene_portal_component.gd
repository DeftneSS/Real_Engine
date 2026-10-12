class_name ScenePortalComponent
extends Area3D
## Área que manda a todos los peers a otra escena cuando un jugador entra.

@export var target_scene: PackedScene
@export var require_all_players: bool = false

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

	if not multiplayer.is_server() or _triggered:
		return

	if require_all_players and _players_inside.size() < Game.instance.players.size():
		return

	_triggered = true
	_change_scene.rpc()


func _handle_body_exited(body: Node3D) -> void:
	_players_inside.erase(body)


@rpc("reliable", "call_local")
func _change_scene() -> void:
	get_tree().change_scene_to_packed(target_scene)
