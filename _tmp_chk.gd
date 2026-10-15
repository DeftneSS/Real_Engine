extends SceneTree
func _init() -> void:
	for p in ["res://scene/Level test.tscn", "res://scene/Level 2.tscn", "res://scene/Level 3.tscn"]:
		var ps: PackedScene = load(p)
		if ps == null:
			print("FAIL|%s no carga" % p); continue
		var r: Node = ps.instantiate()
		var sc: Script = r.get_script()
		var es: Node = r.get_node_or_null("EndScreen")
		print("SCENE|%-22s script=%-16s es_Level=%s  EndScreen=%s  marc_enemigo=%d" % [
			p.get_file(), sc.resource_path.get_file(),
			"SI" if (r is Level) else "NO", "SI" if es else "no",
			r.get_node("EnemySpawnPoints").get_child_count()])
		r.free()
	quit()
