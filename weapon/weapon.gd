class_name Weapon
extends Node3D
## Composite of the weapon pattern: a weapon is a bundle of AttackComponents.
## Composing a new weapon means building a scene that wires components into
## `attack_components` / `skill_components`; no script required.

@export var weapon_name: String
@export var attack_components: Array[AttackComponent]
@export var skill_components: Array[AttackComponent]

## Peer id of the player holding this weapon; forwarded to every component so
## they can validate who triggered them (see AttackComponent.wielder_id).
var wielder_id: int = 1:
	set(value):
		wielder_id = value
		for attack_component: AttackComponent in attack_components:
			attack_component.wielder_id = value
		for skill_component: AttackComponent in skill_components:
			skill_component.wielder_id = value


func attack(direction: Vector3) -> void:
	for attack_component: AttackComponent in attack_components:
		attack_component.attack(direction)


func skill(direction: Vector3) -> void:
	for skill_component: AttackComponent in skill_components:
		skill_component.attack(direction)
