@abstract class_name AttackComponent
extends Node3D
## Leaf of the Weapon composite: performs one kind of attack.
## Attacks are server-authoritative: the wielding peer runs its own cooldown
## and forwards the aim to the server, which is the only peer allowed to
## apply damage or spawn projectiles. A host (which *is* the server) attacks
## directly instead of RPCing itself.

@export var damage: int = 1
@export var cooldown: float = 1

## Peer id of the player holding the owning Weapon (forwarded by Weapon).
var wielder_id: int = 1

var _cooldown_timer: Timer = Timer.new()
var _can_attack: bool = true


func _ready() -> void:
	_cooldown_timer.name = "CooldownTimer"
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = cooldown
	_cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	add_child(_cooldown_timer)


func attack(direction: Vector3) -> void:
	if not _can_attack:
		return
	_start_cooldown()
	if multiplayer.is_server():
		_attack(direction)
	else:
		_attack_request.rpc_id(1, direction)


## Server-only entry point for remote wielders. `_can_attack` doubles as a
## server-side cooldown, so requests cannot land faster than `cooldown`
## even if the client-side timer is bypassed.
@rpc("any_peer", "reliable")
func _attack_request(direction: Vector3) -> void:
	if not multiplayer.is_server() or not _can_attack:
		return
	if multiplayer.get_remote_sender_id() != wielder_id:
		return
	_start_cooldown()
	_attack(direction)


func _start_cooldown() -> void:
	_can_attack = false
	_cooldown_timer.start()


func _on_cooldown_timer_timeout() -> void:
	_can_attack = true


@abstract func _attack(_direction: Vector3) -> void
