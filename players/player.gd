extends CharacterBody3D

@onready var label_3d: Label3D = $Label3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test"):
		test.rpc()


func setup(player_data: Statics.PlayerData) -> void:
	label_3d.text = player_data.name
	set_multiplayer_authority(player_data.id)


@rpc("call_local")
func test() -> void:
	var current_player: String = Game.get_current_player().name
	Debug.log(current_player)
	
	# Lunes 10 Semana 2 min 42:22
