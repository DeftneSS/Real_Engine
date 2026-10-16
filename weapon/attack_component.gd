@abstract class_name AttackComponent
extends Node3D
## Leaf of the Weapon composite: performs one kind of attack.
## Attacks are server-authoritative: the wielding peer runs its own cooldown
## and forwards the aim to the server, which is the only peer allowed to
## apply damage or spawn projectiles. A host (which *is* the server) attacks
## directly instead of RPCing itself.

@export var damage: int = 1
@export var cooldown: float = 1
## When true (default), holding the attack input keeps firing at `cooldown`
## rate; when false, only the press edge fires (one shot per press).
@export var automatic: bool = true

## Cosmetic swing/recoil clip, played on every peer when this component fires.
## Never affects damage (see MeleeAttackComponent); null = no animation.
@export var animation_player: AnimationPlayer
## Name of the clip in `animation_player`; empty = nothing plays.
@export var attack_animation: StringName = &""

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


## `just_pressed` marks the press edge of the attack input; semi-automatic
## components (`automatic = false`) only fire on that edge, while automatic
## ones fire on every call, relying on `cooldown` to set the rate.
func attack(direction: Vector3, just_pressed: bool = true) -> void:
	if not automatic and not just_pressed:
		return
	if not _can_attack:
		return
	_start_cooldown()
	_play_attack_animation.rpc()
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


## Cosmetic only: the owning peer broadcasts so every peer sees the swing.
## any_peer + call_local because the owning node's multiplayer authority is
## the server, but a client owner is who actually fires (same reason as
## _attack_request); the sender check stops anyone faking another player's
## swing. Damage stays server-authoritative and never depends on this clip.
@rpc("any_peer", "call_local", "reliable")
func _play_attack_animation() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != 0 and sender != wielder_id:
		return
	if animation_player == null or attack_animation == &"":
		return
	# play() does not restart a clip that is already mid-play, so an attack
	# landing before the previous swing finished would not visibly re-trigger.
	# Stop first so every committed attack restarts the swing.
	if animation_player.is_playing() and animation_player.current_animation == attack_animation:
		animation_player.stop()
	animation_player.play(attack_animation)


func _start_cooldown() -> void:
	_can_attack = false
	_cooldown_timer.start()


func _on_cooldown_timer_timeout() -> void:
	_can_attack = true


@abstract func _attack(_direction: Vector3) -> void
