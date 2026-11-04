extends SceneTree
##
## Generates a MeshLibrary from the low-poly-dungeon FBX.
##
## Run with:
##   godot --headless --path . -s res://assets/tilesets/low_poly_dungeon/generate_library.gd
##
## Conventions baked into the library (GridMap cell size 2.106 x 3.06 x 2.106):
##   * +X/-X, +Z/-Z : 1-cell pieces are centered on the cell center.
##   * multi-cell pieces (integer span) are anchored to the cell's -X/-Z corner
##     so their far edge lands on a cell boundary.
##   * wall-like pieces (wall/window/bars/door/railing/handrail) are centered on
##     the +X or +Z cell boundary on their thin axis, so they straddle cells.
##   * Y: every piece has its AABB bottom at -CELL_Y/2 (the bottom of the cell),
##     so a piece placed at map y = 0 rests on world y = 0.
##   * collisions: convex polygons only (never trimesh).
##

const SRC := "res://assets/tilesets/low_poly_dungeon/low-poly-dungeon.fbx"
const OUT_DIR := "res://assets/tilesets/low_poly_dungeon"
const OUT_LIB := OUT_DIR + "/low_poly_dungeon_library.tres"
const MAT_DIR := OUT_DIR + "/materials"

const CELL := 2.106
const CELL_Y := 3.06

var _used_names := {}
var _mat_paths := {}

func _init() -> void:
	var t0 := Time.get_ticks_msec()
	print("=== generating low-poly-dungeon MeshLibrary ===")

	var ps: PackedScene = load(SRC)
	if ps == null:
		push_error("cannot load " + SRC)
		quit(1)
		return
	var root: Node = ps.instantiate()

	var out_dir := DirAccess.open(OUT_DIR)
	if out_dir == null:
		push_error("cannot open " + OUT_DIR)
		quit(1)
		return
	if not out_dir.dir_exists("materials"):
		var err := out_dir.make_dir_recursive("materials")
		if err != OK:
			push_error("cannot create materials dir: " + str(err))
			quit(1)
			return

	# Importer axis conversion: FBX Z-up centimetres -> Godot Y-up metres.
	var axis_basis := Basis(Vector3(1, 0, 0), -PI / 2.0).scaled(Vector3(100, 100, 100))
	var axis := Transform3D(axis_basis, Vector3.ZERO)

	# Group mesh instances by mesh resource id (126 unique meshes from 198 nodes).
	var order: Array = []
	var groups := {}
	for c in root.get_children():
		if not (c is MeshInstance3D):
			continue
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var id := mi.mesh.get_instance_id()
		if not groups.has(id):
			groups[id] = []
			order.append(id)
		groups[id].append(mi)

	print("mesh instances: ", _count_instances(groups), " unique meshes: ", order.size())

	var lib := MeshLibrary.new()
	var mat_cache := {}
	var stats := {"items": 0, "wall": 0, "shapes": 0, "surfaces": 0}
	var item_id := 0

	for id in order:
		var group: Array = groups[id]
		var src: MeshInstance3D = group[0]
		var aabb: AABB = axis * src.mesh.get_aabb()

		var wall := _is_wall_like(String(src.name), aabb)
		var thin_axis := _thin_axis(aabb) if wall else ""

		var off := Vector3.ZERO
		off.x = _axis_offset(aabb.size.x, aabb.position.x, thin_axis == "x")
		off.z = _axis_offset(aabb.size.z, aabb.position.z, thin_axis == "z")
		off.y = (-CELL_Y * 0.5) - aabb.position.y

		var xf := Transform3D(Basis.IDENTITY, off) * axis
		var baked := _bake_mesh(src.mesh, xf, mat_cache)
		var shapes := _bake_shapes(src, xf)

		var item_name := _item_name(group)
		lib.create_item(item_id)
		lib.set_item_name(item_id, item_name)
		lib.set_item_mesh(item_id, baked)
		lib.set_item_mesh_cast_shadow(item_id, RenderingServer.SHADOW_CASTING_SETTING_ON)
		if not shapes.is_empty():
			lib.set_item_shapes(item_id, shapes)

		stats["items"] += 1
		stats["shapes"] += int(shapes.size() / 2)
		stats["surfaces"] += baked.get_surface_count()
		if wall:
			stats["wall"] += 1

		print("  [%3d] %-30s wall=%-5s thin=%-1s off=(%7.3f,%7.3f,%7.3f) shapes=%d size=(%6.3f,%6.3f,%6.3f)" % [
			item_id, item_name, str(wall), thin_axis, off.x, off.y, off.z,
			int(shapes.size() / 2), aabb.size.x, aabb.size.y, aabb.size.z])

		item_id += 1

	var save_err := ResourceSaver.save(lib, OUT_LIB)
	if save_err != OK:
		push_error("failed to save library: " + str(save_err))
		root.free()
		quit(1)
		return
	_ensure_uid(OUT_LIB)

	print("saved: ", OUT_LIB)
	print("stats: ", stats)
	print("materials: ", mat_cache.size())
	print("done in ", Time.get_ticks_msec() - t0, " ms")

	root.free()
	quit()

func _count_instances(groups: Dictionary) -> int:
	var n := 0
	for id in groups:
		n += groups[id].size()
	return n

# --- classification ---------------------------------------------------------

func _is_wall_like(name: String, aabb: AABB) -> bool:
	var n := name.to_lower()
	var named := n.contains("wall") or n.contains("window") or n.contains("bars") \
		or n.contains("door") or n.contains("railing") or n.contains("handrail") \
		or n.contains("handhail")
	if not named:
		return false
	var sx := aabb.size.x
	var sz := aabb.size.z
	var mn := minf(sx, sz)
	var mx := maxf(sx, sz)
	return mn < CELL * 0.6 and mx >= CELL * 0.5 and mx > mn * 1.6

func _thin_axis(aabb: AABB) -> String:
	return "x" if aabb.size.x < aabb.size.z else "z"

func _axis_offset(extent: float, min_val: float, is_thin_wall_axis: bool) -> float:
	if is_thin_wall_axis:
		# Center the wall on the +cell boundary.
		return CELL * 0.5 - (min_val + extent * 0.5)
	var n := extent / CELL
	var r := roundf(n)
	if r >= 2.0 and absf(n - r) <= 0.15:
		# Multi-cell piece: anchor its min edge to the cell's -edge.
		return -CELL * 0.5 - min_val
	# Single-cell (or irregular) piece: center it.
	return -(min_val + extent * 0.5)

# --- mesh baking ------------------------------------------------------------

func _bake_mesh(src: Mesh, xf: Transform3D, mat_cache: Dictionary) -> ArrayMesh:
	var out := ArrayMesh.new()
	var nb := xf.basis
	for s in range(src.get_surface_count()):
		var arrays := src.surface_get_arrays(s)
		var prim: int = src.surface_get_primitive_type(s)

		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in range(verts.size()):
			verts[i] = xf * verts[i]
		arrays[Mesh.ARRAY_VERTEX] = verts

		var normals = arrays[Mesh.ARRAY_NORMAL]
		if normals is PackedVector3Array and normals.size() > 0:
			for i in range(normals.size()):
				normals[i] = (nb * normals[i]).normalized()
			arrays[Mesh.ARRAY_NORMAL] = normals

		var tangents = arrays[Mesh.ARRAY_TANGENT]
		if tangents is PackedFloat32Array and tangents.size() > 0:
			for i in range(0, tangents.size(), 4):
				var t := Vector3(tangents[i], tangents[i + 1], tangents[i + 2])
				t = (nb * t).normalized()
				tangents[i] = t.x
				tangents[i + 1] = t.y
				tangents[i + 2] = t.z
			arrays[Mesh.ARRAY_TANGENT] = tangents

		out.add_surface_from_arrays(prim, arrays)
		var mat := src.surface_get_material(s)
		if mat != null:
			out.surface_set_material(out.get_surface_count() - 1, _material(mat, mat_cache))
	return out

# --- material baking --------------------------------------------------------

func _material(mat: Material, cache: Dictionary) -> Material:
	var key := String(mat.resource_path) if not String(mat.resource_path).is_empty() else "id:" + str(mat.get_instance_id())
	if cache.has(key):
		return cache[key]

	var dup: Material = mat.duplicate(true)
	dup.resource_path = ""
	var base := _sanitize_name(dup.resource_name)
	if base.is_empty():
		base = "material"
	var path := MAT_DIR + "/" + base + ".tres"
	if _mat_paths.has(path) and _mat_paths[path] != key:
		var i := 2
		while _mat_paths.has(MAT_DIR + "/" + base + "_" + str(i) + ".tres"):
			i += 1
		path = MAT_DIR + "/" + base + "_" + str(i) + ".tres"
	_mat_paths[path] = key

	var err := ResourceSaver.save(dup, path)
	if err != OK:
		push_error("failed to save material " + path + ": " + str(err))
	else:
		dup.take_over_path(path)
		_ensure_uid(path)
		print("    material: ", dup.resource_name, " -> ", path)
	cache[key] = dup
	return dup

# Add a stable uid="uid://..." to a text resource header if it has none.
func _ensure_uid(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	if text.contains('uid="uid://'):
		return
	var nl := text.find("\n")
	if nl < 0:
		return
	var header := text.substr(0, nl)
	var close := header.rfind("]")
	if close < 0:
		return
	var uid := ResourceUID.id_to_text(ResourceUID.create_id())
	var new_header := header.substr(0, close) + ' uid="' + uid + '"' + header.substr(close)
	var w := FileAccess.open(path, FileAccess.WRITE)
	if w == null:
		return
	w.store_string(new_header + text.substr(nl))
	w.close()
	print("    uid: ", path, " -> ", uid)

func _sanitize_name(s: String) -> String:
	var out := s.to_lower().strip_edges()
	out = out.replace(" ", "_").replace("-", "_")
	return out

# --- collision baking -------------------------------------------------------

func _bake_shapes(src: MeshInstance3D, xf: Transform3D) -> Array:
	var collected: Array = []
	_collect_shapes(src, Transform3D.IDENTITY, collected)
	var out: Array = []
	for entry in collected:
		var shape: Shape3D = entry["shape"]
		var tf: Transform3D = entry["tf"]
		if shape is ConvexPolygonShape3D:
			var pts: PackedVector3Array = (shape as ConvexPolygonShape3D).points
			var new_pts := PackedVector3Array()
			new_pts.resize(pts.size())
			for i in range(pts.size()):
				new_pts[i] = xf * (tf * pts[i])
			var ns := ConvexPolygonShape3D.new()
			ns.points = new_pts
			out.append(ns)
			out.append(Transform3D.IDENTITY)
		else:
			# Should never happen with our import settings, but keep it safe.
			out.append(shape)
			out.append(xf * tf)
	return out

func _collect_shapes(node: Node, parent_tf: Transform3D, out: Array) -> void:
	for c in node.get_children():
		var tf := parent_tf
		if c is Node3D:
			tf = parent_tf * (c as Node3D).transform
		if c is CollisionShape3D and (c as CollisionShape3D).shape != null:
			out.append({"shape": (c as CollisionShape3D).shape, "tf": tf})
		_collect_shapes(c, tf, out)

# --- naming -----------------------------------------------------------------

func _item_name(group: Array) -> String:
	var names := []
	for mi in group:
		names.append(String(mi.name))
	for n in names:
		if not _has_numeric_suffix(n):
			return _unique_name(n)
	return _unique_name(names[0])

func _has_numeric_suffix(s: String) -> bool:
	var parts := s.split("_")
	if parts.size() < 2:
		return false
	var last := parts[parts.size() - 1]
	if last.is_empty():
		return false
	for ch in last:
		if ch < "0" or ch > "9":
			return false
	return true

func _unique_name(base: String) -> String:
	var n := base
	var i := 2
	while _used_names.has(n):
		n = base + " (" + str(i) + ")"
		i += 1
	_used_names[n] = true
	return n
