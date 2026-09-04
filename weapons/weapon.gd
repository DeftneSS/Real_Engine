class_name Weapon
extends Node3D

@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

@export var weapon_name: String = "Base Weapon"
@export var damage: int = 10

var _can_attack: bool = true

func _ready() -> void:
	var script: Script = get_script()
	if script == Weapon:
		push_error("Empty Base Weapon instantiated.")

func attack(direction: Vector3) -> void:
	if _can_attack:
		_attack(direction)
		_can_attack = false
		#attack_cooldown_timer.start()

func _attack(_direction: Vector3) -> void:
	push_warning("Weapon._perform_attack() not implemented for %s" % weapon_name)

func _on_attack_cooldown_timer_timeout() -> void:
	_can_attack = true
