class_name MapBuilder
extends RefCounted

const BSP_SCALE_FACTOR: float = 32.0

static var cached_wad_textures: Dictionary = {}

static func get_map_catalog() -> Array:
	var catalog := [
		{
			"id": "de_dust2",
			"name": "de_dust2 — Dust II (.bsp)",
			"desc": "Classic Counter-Strike 1.6 Bomb/Defuse map."
		},
		{
			"id": "de_mirage",
			"name": "de_mirage — Mirage (.bsp)",
			"desc": "Tactical Bomb/Defuse map."
		},
		{
			"id": "tr_range",
			"name": "tr_range — Training Range",
			"desc": "Shooting range for testing weapons, recoil, and audio."
		}
	]

	var dir := DirAccess.open("res://assets/maps/")
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.to_lower().ends_with(".bsp"):
				var map_id := fname.get_basename()
				if map_id != "de_dust2" and map_id != "de_mirage":
					catalog.insert(catalog.size() - 1, {
						"id": map_id,
						"name": map_id + " (.bsp)",
						"desc": "Custom GoldSrc BSP map: " + fname
					})
			fname = dir.get_next()

	return catalog

static func build_map(map_id: String, parent: Node3D) -> Dictionary:
	var map_root := Node3D.new()
	map_root.name = "Map_" + map_id
	parent.add_child(map_root)

	var nav_region := NavigationRegion3D.new()
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.42
	nav_mesh.agent_height = 1.75
	nav_region.navigation_mesh = nav_mesh
	map_root.add_child(nav_region)

	var geo_root := Node3D.new()
	geo_root.name = "Geometry"
	nav_region.add_child(geo_root)

	_setup_lighting(map_root)

	var data := {
		"ct_spawns": [],
		"t_spawns": [],
		"bombsites": [],
		"waypoints": [],
		"training_targets": []
	}

	if map_id == "tr_range":
		_build_training_range(geo_root, data)
	else:
		_build_bsp_level(map_id, geo_root, data)

	var vertices := PackedVector3Array([
		Vector3(-350, 0.05, -350),
		Vector3(350, 0.05, -350),
		Vector3(350, 0.05, 350),
		Vector3(-350, 0.05, 350)
	])
	nav_mesh.set_vertices(vertices)
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))

	return data

static func _setup_lighting(root: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.58, 0.72, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.82, 0.74)
	env.ambient_light_energy = 1.05

	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.light_color = Color(1.0, 0.95, 0.84)
	sun.light_energy = 1.15
	sun.rotation_degrees = Vector3(-52, 38, 0)
	root.add_child(sun)

	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

static func _build_bsp_level(map_id: String, parent: Node3D, data: Dictionary) -> void:
	var candidates := [
		"res://assets/maps/" + map_id + ".bsp",
		"res://assets/maps/" + map_id + "_2x2.bsp",
		"res://maps/" + map_id + ".bsp"
	]

	var bsp_path := ""
	for p in candidates:
		if FileAccess.file_exists(p):
			bsp_path = p
			break

	if bsp_path != "" and _build_goldsrc_bsp_direct(bsp_path, parent, data):
		print(">>> [BSP] Loaded GoldSrc BSP with authentic WAD/MIP textures: ", bsp_path)
		return

	push_warning("[BSP] Could not load " + map_id + ", falling back to Training Range.")
	_build_training_range(parent, data)

static func _get_texture_library() -> Dictionary:
	if not cached_wad_textures.is_empty():
		return cached_wad_textures

	# 1. Load all WAD3 files
	var wad_candidates := [
		"res://assets/maps/cs_dust.wad",
		"res://cs_dust.wad"
	]
	var map_dir := DirAccess.open("res://assets/maps/")
	if map_dir:
		map_dir.list_dir_begin()
		var fn := map_dir.get_next()
		while fn != "":
			if not map_dir.current_is_dir() and fn.to_lower().ends_with(".wad"):
				var full_w := "res://assets/maps/" + fn
				if not wad_candidates.has(full_w):
					wad_candidates.append(full_w)
			fn = map_dir.get_next()

	for wpath in wad_candidates:
		if FileAccess.file_exists(wpath):
			_load_wad3_into_dict(wpath, cached_wad_textures)

	# 2. Load all .mip files from res://assets/textures/
	_load_mip_dir_into_dict("res://assets/textures", cached_wad_textures)

	print(">>> [TEXTURES] Total GoldSrc WAD/MIP textures decoded: ", cached_wad_textures.size())
	return cached_wad_textures

static func _load_wad3_into_dict(wad_path: String, out_dict: Dictionary) -> void:
	var f := FileAccess.open(wad_path, FileAccess.READ)
	if f == null or f.get_length() < 12:
		return
	var magic := f.get_buffer(4).get_string_from_ascii()
	if magic != "WAD3" and magic != "WAD2":
		return
	var num_lumps: int = f.get_32()
	var dir_offset: int = f.get_32()
	var file_len: int = f.get_length()
	if dir_offset <= 0 or dir_offset + num_lumps * 32 > file_len:
		return

	for i in range(num_lumps):
		f.seek(dir_offset + i * 32)
		var filepos: int = f.get_32()
		var disksize: int = f.get_32()
		var _size: int = f.get_32()
		var ltype: int = f.get_8()
		var _compr: int = f.get_8()
		f.get_16()
		var raw_name := f.get_buffer(16)
		var entry_name := _clean_c_string(raw_name).to_lower()
		if (ltype == 67 or ltype == 68) and filepos > 0 and filepos + 40 <= file_len:
			var parsed := _decode_miptex_at(f, filepos, file_len)
			if not parsed.is_empty():
				out_dict[entry_name] = parsed
				if parsed["name"] != "":
					out_dict[parsed["name"]] = parsed

static func _load_mip_dir_into_dict(folder_path: String, out_dict: Dictionary) -> void:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.to_lower().ends_with(".mip"):
			var full_path := folder_path + "/" + fname
			var f := FileAccess.open(full_path, FileAccess.READ)
			if f != null and f.get_length() > 44:
				var parsed := _decode_miptex_at(f, 0, f.get_length())
				if not parsed.is_empty():
					var base := fname.get_basename().to_lower()
					out_dict[base] = parsed
					# Strip numeric prefix like "0001_0cssandwall" -> "0cssandwall"
					var uscore := base.find("_")
					if uscore > 0 and base.substr(0, uscore).is_valid_int():
						var stripped := base.substr(uscore + 1)
						out_dict[stripped] = parsed
					if parsed["name"] != "":
						out_dict[parsed["name"]] = parsed
		fname = dir.get_next()

static func _decode_miptex_at(f: FileAccess, lump_pos: int, max_len: int) -> Dictionary:
	if lump_pos + 40 > max_len:
		return {}
	f.seek(lump_pos)
	var name_bytes := f.get_buffer(16)
	var tex_name := _clean_c_string(name_bytes).to_lower()
	var w: int = f.get_32()
	var h: int = f.get_32()
	var ofs0: int = f.get_32()
	var _ofs1: int = f.get_32()
	var _ofs2: int = f.get_32()
	var ofs3: int = f.get_32()

	if w <= 0 or h <= 0 or w > 2048 or h > 2048 or (w % 8) != 0 or (h % 8) != 0:
		return {}
	if ofs0 <= 0 or lump_pos + ofs0 + (w * h) > max_len:
		return {}

	var mip3_size: int = (w >> 3) * (h >> 3)
	var pal_count_pos: int = lump_pos + ofs3 + mip3_size
	var pal_pos: int = pal_count_pos + 2
	if ofs3 <= 0 or pal_pos + 768 > max_len:
		var total_mips: int = (w * h) + ((w >> 1) * (h >> 1)) + ((w >> 2) * (h >> 2)) + mip3_size
		pal_pos = lump_pos + ofs0 + total_mips + 2
		if pal_pos + 768 > max_len:
			return {}

	f.seek(lump_pos + ofs0)
	var indices: PackedByteArray = f.get_buffer(w * h)
	f.seek(pal_pos)
	var pal: PackedByteArray = f.get_buffer(768)

	var is_cutout: bool = tex_name.begins_with("{")
	var img: Image
	if is_cutout:
		var rgba := PackedByteArray()
		rgba.resize(w * h * 4)
		for p in range(w * h):
			var idx: int = int(indices[p])
			var c_idx: int = idx * 3
			rgba[p * 4]     = pal[c_idx]
			rgba[p * 4 + 1] = pal[c_idx + 1]
			rgba[p * 4 + 2] = pal[c_idx + 2]
			rgba[p * 4 + 3] = 0 if idx == 255 else 255
		img = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, rgba)
	else:
		var rgb := PackedByteArray()
		rgb.resize(w * h * 3)
		for p in range(w * h):
			var c_idx: int = int(indices[p]) * 3
			rgb[p * 3]     = pal[c_idx]
			rgb[p * 3 + 1] = pal[c_idx + 1]
			rgb[p * 3 + 2] = pal[c_idx + 2]
		img = Image.create_from_data(w, h, false, Image.FORMAT_RGB8, rgb)

	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	return {
		"name": tex_name,
		"width": w,
		"height": h,
		"texture": tex,
		"cutout": is_cutout
	}

static func _clean_c_string(bytes: PackedByteArray) -> String:
	var end := bytes.find(0)
	if end >= 0:
		bytes = bytes.slice(0, end)
	return bytes.get_string_from_ascii().strip_edges()

static func _build_goldsrc_bsp_direct(bsp_path: String, parent: Node3D, data: Dictionary) -> bool:
	var f := FileAccess.open(bsp_path, FileAccess.READ)
	if f == null or f.get_length() < 124:
		return false

	var file_len: int = f.get_length()
	var version: int = f.get_32()
	if version != 30:
		return false

	var lumps: Array = []
	for _i in range(15):
		var l_ofs: int = f.get_32()
		var l_len: int = f.get_32()
		lumps.append({"ofs": l_ofs, "len": l_len})

	var tex_lib: Dictionary = _get_texture_library()

	# Lump 2: LUMP_TEXTURES
	var bsp_textures: Array = []
	var tex_lump_ofs: int = lumps[2]["ofs"]
	var tex_lump_len: int = lumps[2]["len"]
	if tex_lump_ofs > 0 and tex_lump_len >= 4:
		f.seek(tex_lump_ofs)
		var num_tex: int = f.get_32()
		var mip_offsets: Array[int] = []
		for _t in range(num_tex):
			mip_offsets.append( _s32(f.get_32()) )
		for t in range(num_tex):
			var rel_ofs: int = mip_offsets[t]
			if rel_ofs < 0 or tex_lump_ofs + rel_ofs + 40 > file_len:
				bsp_textures.append({"name": "default", "width": 128, "height": 128, "mat": null, "skip": false, "surface": "sand"})
				continue
			var abs_ofs: int = tex_lump_ofs + rel_ofs
			f.seek(abs_ofs)
			var raw_tname := f.get_buffer(16)
			var tname := _clean_c_string(raw_tname).to_lower()
			var tw: int = maxi(8, f.get_32())
			var th: int = maxi(8, f.get_32())
			var emb_ofs0: int = f.get_32()

			var skip_face: bool = (
				tname == "sky" or tname == "aaatrigger" or tname == "clip" or
				tname == "origin" or tname == "null" or tname == "hint" or
				tname == "skip" or tname == "bevel"
			)

			var tex_entry: Dictionary = {}
			if emb_ofs0 > 0:
				tex_entry = _decode_miptex_at(f, abs_ofs, file_len)
			if tex_entry.is_empty() and tex_lib.has(tname):
				tex_entry = tex_lib[tname]
			if tex_entry.is_empty():
				tex_entry = _find_fallback_dust_texture(tname, tex_lib)

			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color.WHITE
			mat.roughness = 0.86
			mat.specular = 0.06
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if not tex_entry.is_empty() and tex_entry.has("texture"):
				mat.albedo_texture = tex_entry["texture"]
				if int(tex_entry.get("width", 0)) > 0:
					tw = int(tex_entry["width"])
				if int(tex_entry.get("height", 0)) > 0:
					th = int(tex_entry["height"])
				if bool(tex_entry.get("cutout", false)):
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					mat.alpha_scissor_threshold = 0.5
			else:
				mat.albedo_color = Color(0.76, 0.68, 0.52)

			var surf_type := _classify_surface_type(tname)
			bsp_textures.append({
				"name": tname,
				"width": float(tw),
				"height": float(th),
				"mat": mat,
				"skip": skip_face,
				"surface": surf_type
			})

	# Lump 3: LUMP_VERTICES
	var verts := PackedVector3Array()
	var v_ofs: int = lumps[3]["ofs"]
	var v_count: int = int(lumps[3]["len"] / 12)
	f.seek(v_ofs)
	verts.resize(v_count)
	for i in range(v_count):
		var qx: float = f.get_float()
		var qy: float = f.get_float()
		var qz: float = f.get_float()
		verts[i] = Vector3(qx, qy, qz)

	# Lump 6: LUMP_TEXINFO
	var texinfos: Array = []
	var ti_ofs: int = lumps[6]["ofs"]
	var ti_count: int = int(lumps[6]["len"] / 40)
	f.seek(ti_ofs)
	for _i in range(ti_count):
		var sx: float = f.get_float()
		var sy: float = f.get_float()
		var sz: float = f.get_float()
		var s_shift: float = f.get_float()
		var tx: float = f.get_float()
		var ty: float = f.get_float()
		var tz: float = f.get_float()
		var t_shift: float = f.get_float()
		var miptex_idx: int = f.get_32()
		var flags: int = f.get_32()
		texinfos.append({
			"s": Vector3(sx, sy, sz),
			"s_shift": s_shift,
			"t": Vector3(tx, ty, tz),
			"t_shift": t_shift,
			"miptex": miptex_idx,
			"flags": flags
		})

	# Lump 12: LUMP_EDGES
	var edges: Array = []
	var e_ofs: int = lumps[12]["ofs"]
	var e_count: int = int(lumps[12]["len"] / 4)
	f.seek(e_ofs)
	edges.resize(e_count)
	for i in range(e_count):
		var v0: int = f.get_16()
		var v1: int = f.get_16()
		edges[i] = Vector2i(v0, v1)

	# Lump 13: LUMP_SURFEDGES
	var surfedges := PackedInt32Array()
	var se_ofs: int = lumps[13]["ofs"]
	var se_count: int = int(lumps[13]["len"] / 4)
	f.seek(se_ofs)
	surfedges.resize(se_count)
	for i in range(se_count):
		surfedges[i] = _s32(f.get_32())

	# Lump 7: LUMP_FACES
	var faces: Array = []
	var fa_ofs: int = lumps[7]["ofs"]
	var fa_count: int = int(lumps[7]["len"] / 20)
	f.seek(fa_ofs)
	faces.resize(fa_count)
	for i in range(fa_count):
		var _plane_id: int = f.get_16()
		var _side: int = f.get_16()
		var first_edge: int = _s32(f.get_32())
		var num_edges: int = f.get_16()
		var texinfo_id: int = f.get_16()
		f.get_32() # styles
		f.get_32() # lightofs
		faces[i] = {
			"first_edge": first_edge,
			"num_edges": num_edges,
			"texinfo": texinfo_id
		}

	# Lump 14: LUMP_MODELS
	var models: Array = []
	var mo_ofs: int = lumps[14]["ofs"]
	var mo_count: int = int(lumps[14]["len"] / 64)
	f.seek(mo_ofs)
	for _i in range(mo_count):
		var mins := Vector3(f.get_float(), f.get_float(), f.get_float())
		var maxs := Vector3(f.get_float(), f.get_float(), f.get_float())
		var orig := Vector3(f.get_float(), f.get_float(), f.get_float())
		f.get_32()
		f.get_32()
		f.get_32()
		f.get_32()
		f.get_32()
		var first_face: int = _s32(f.get_32())
		var num_faces: int = _s32(f.get_32())
		models.append({
			"mins": mins,
			"maxs": maxs,
			"origin": orig,
			"first_face": first_face,
			"num_faces": num_faces
		})

	# Lump 0: LUMP_ENTITIES (extract spawns, bombsites, and brush model roles)
	var model_instructions: Dictionary = {
		0: {"render": true, "solid": true, "origin": Vector3.ZERO}
	}
	var ent_ofs: int = lumps[0]["ofs"]
	var ent_len: int = lumps[0]["len"]
	if ent_ofs > 0 and ent_len > 0 and ent_ofs + ent_len <= file_len:
		f.seek(ent_ofs)
		var ent_text := f.get_buffer(ent_len).get_string_from_ascii()
		_parse_bsp_entities(ent_text, models, model_instructions, data)

	# Build meshes for worldspawn (0) and visible brush entities (crates, doors, walls)
	var floor_samples := PackedVector3Array()
	for m_idx in model_instructions.keys():
		if m_idx < 0 or m_idx >= models.size():
			continue
		var instr: Dictionary = model_instructions[m_idx]
		if not bool(instr.get("render", false)):
			continue
		var m_info: Dictionary = models[m_idx]
		var q_origin: Vector3 = instr.get("origin", Vector3.ZERO) + m_info["origin"]
		var is_solid: bool = bool(instr.get("solid", true))
		_build_bsp_model_node(
			parent,
			m_idx,
			m_info["first_face"],
			m_info["num_faces"],
			q_origin,
			is_solid,
			faces,
			surfedges,
			edges,
			verts,
			texinfos,
			bsp_textures,
			floor_samples
		)

	_finalize_spawns_and_waypoints(floor_samples, data)
	return true

static func _build_bsp_model_node(
	parent: Node3D,
	model_idx: int,
	first_face: int,
	num_faces: int,
	q_origin: Vector3,
	is_solid: bool,
	faces: Array,
	surfedges: PackedInt32Array,
	edges: Array,
	verts: PackedVector3Array,
	texinfos: Array,
	bsp_textures: Array,
	floor_samples: PackedVector3Array
) -> void:
	var grouped_tris: Dictionary = {}
	var end_face: int = mini(first_face + num_faces, faces.size())

	for f_idx in range(first_face, end_face):
		var face: Dictionary = faces[f_idx]
		var ti_id: int = int(face["texinfo"])
		if ti_id < 0 or ti_id >= texinfos.size():
			continue
		var ti: Dictionary = texinfos[ti_id]
		var mip_id: int = int(ti["miptex"])
		if mip_id < 0 or mip_id >= bsp_textures.size():
			continue
		var btex: Dictionary = bsp_textures[mip_id]
		if bool(btex["skip"]):
			continue

		var f_edge: int = int(face["first_edge"])
		var n_edges: int = int(face["num_edges"])
		if n_edges < 3 or f_edge < 0 or f_edge + n_edges > surfedges.size():
			continue

		var poly_q: Array[Vector3] = []
		var poly_gd: Array[Vector3] = []
		var poly_uv: Array[Vector2] = []
		var s_vec: Vector3 = ti["s"]
		var s_shift: float = ti["s_shift"]
		var t_vec: Vector3 = ti["t"]
		var t_shift: float = ti["t_shift"]
		var tw: float = maxf(1.0, float(btex["width"]))
		var th: float = maxf(1.0, float(btex["height"]))

		for e_step in range(n_edges):
			var se: int = surfedges[f_edge + e_step]
			var e_idx: int = absi(se)
			if e_idx >= edges.size():
				continue
			var edge_pair: Vector2i = edges[e_idx]
			var v_idx: int = edge_pair.x if se >= 0 else edge_pair.y
			if v_idx < 0 or v_idx >= verts.size():
				continue
			var q_local: Vector3 = verts[v_idx]
			var q_world: Vector3 = q_local + q_origin
			var gd_pt := Vector3(-q_world.y, q_world.z, -q_world.x) / BSP_SCALE_FACTOR
			var u: float = (q_local.dot(s_vec) + s_shift) / tw
			var v: float = (q_local.dot(t_vec) + t_shift) / th
			poly_q.append(q_world)
			poly_gd.append(gd_pt)
			poly_uv.append(Vector2(u, v))

		if poly_gd.size() < 3:
			continue

		if not grouped_tris.has(mip_id):
			grouped_tris[mip_id] = []

		var p0: Vector3 = poly_gd[0]
		var uv0: Vector2 = poly_uv[0]
		var nrm: Vector3 = (poly_gd[2] - p0).cross(poly_gd[1] - p0).normalized()
		if nrm.length_squared() < 0.001:
			nrm = Vector3.UP

		if model_idx == 0 and nrm.y > 0.78 and (f_idx % 5 == 0):
			var center := Vector3.ZERO
			for gp in poly_gd:
				center += gp
			floor_samples.append(center / float(poly_gd.size()))

		for k in range(1, poly_gd.size() - 1):
			grouped_tris[mip_id].append({
				"p0": p0, "uv0": uv0,
				"p1": poly_gd[k], "uv1": poly_uv[k],
				"p2": poly_gd[k + 1], "uv2": poly_uv[k + 1],
				"n": nrm
			})

	if grouped_tris.is_empty():
		return

	# Group surfaces by surface type ("sand" vs "stone") so footsteps detect exact ground material
	for surf_kind in ["sand", "stone"]:
		var mesh := ArrayMesh.new()
		var has_surfaces := false
		for mip_id in grouped_tris.keys():
			var btex: Dictionary = bsp_textures[mip_id]
			if str(btex["surface"]) != surf_kind:
				continue
			var tris: Array = grouped_tris[mip_id]
			if tris.is_empty():
				continue
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(btex["mat"])
			for tri in tris:
				var nrm: Vector3 = tri["n"]
				st.set_normal(nrm)
				st.set_uv(tri["uv0"])
				st.add_vertex(tri["p0"])
				st.set_normal(nrm)
				st.set_uv(tri["uv2"])
				st.add_vertex(tri["p2"])
				st.set_normal(nrm)
				st.set_uv(tri["uv1"])
				st.add_vertex(tri["p1"])
			st.commit(mesh)
			has_surfaces = true

		if not has_surfaces:
			continue

		var mi := MeshInstance3D.new()
		mi.name = "BSPModel_%d_%s" % [model_idx, surf_kind]
		mi.mesh = mesh
		parent.add_child(mi)

		if is_solid:
			mi.create_trimesh_collision()
			for ch in mi.get_children():
				if ch is StaticBody3D:
					var sb := ch as StaticBody3D
					sb.collision_layer = 1
					sb.collision_mask = 2
					sb.set_meta("surface_type", surf_kind)

static func _classify_surface_type(tname: String) -> String:
	if "rock" in tname or "flr" in tname or ("sand" in tname and not "wall" in tname and not "wll" in tname and not "ccrete" in tname and not "crt" in tname and not "trim" in tname and not "door" in tname):
		return "sand"
	return "stone"

static func _find_fallback_dust_texture(tname: String, tex_lib: Dictionary) -> Dictionary:
	if tex_lib.is_empty():
		return {}
	var candidates := []
	if "crate" in tname or "crt" in tname or "box" in tname:
		candidates = ["mltrycrtesd", "sandcrtlrgsd", "mltrycrtetp"]
	elif "door" in tname or "wood" in tname:
		candidates = ["sandwlldoor", "sandwlldoor2"]
	elif "wndw" in tname or "win" in tname:
		candidates = ["sandwllwndw", "sandwllwndw2"]
	elif "trim" in tname or "arch" in tname:
		candidates = ["sandtrim", "sandccrete"]
	elif "road" in tname or "cobble" in tname or "brick" in tname:
		candidates = ["sandroad", "sandccrete"]
	elif "sand" in tname or "dirt" in tname or "ground" in tname or "flr" in tname:
		candidates = ["-0sand", "-1sand", "-2sand"]
	elif "rock" in tname or "cliff" in tname:
		candidates = ["-0sandrock", "-1sandrock"]
	else:
		candidates = ["0cssandwall", "1cssandwall", "cssandwall2", "sandccrete"]

	for c in candidates:
		if tex_lib.has(c):
			return tex_lib[c]
	return tex_lib[tex_lib.keys()[0]]

static func _parse_bsp_entities(ent_text: String, models: Array, model_instructions: Dictionary, data: Dictionary) -> void:
	var visible_brush_classes := [
		"func_wall", "func_breakable", "func_door", "func_door_rotating",
		"func_plat", "func_pendulum", "func_detail", "func_Button"
	]
	var blocks := ent_text.split("}")
	for block in blocks:
		var cls := ""
		var orig_str := ""
		var model_str := ""
		for line in block.split("\n"):
			var clean := line.strip_edges()
			if clean.begins_with("\"classname\""):
				var p := clean.split("\"")
				if p.size() >= 4:
					cls = p[3].to_lower()
			elif clean.begins_with("\"origin\""):
				var p := clean.split("\"")
				if p.size() >= 4:
					orig_str = p[3]
			elif clean.begins_with("\"model\""):
				var p := clean.split("\"")
				if p.size() >= 4:
					model_str = p[3]

		var q_orig := Vector3.ZERO
		var has_orig := false
		if orig_str != "":
			var nums := orig_str.split(" ", false)
			if nums.size() >= 3:
				q_orig = Vector3(float(nums[0]), float(nums[1]), float(nums[2]))
				has_orig = true

		if model_str.begins_with("*"):
			var m_idx: int = int(model_str.substr(1))
			if m_idx > 0 and m_idx < models.size():
				if cls in visible_brush_classes:
					model_instructions[m_idx] = {"render": true, "solid": true, "origin": q_orig}
				elif cls == "func_illusionary":
					model_instructions[m_idx] = {"render": true, "solid": false, "origin": q_orig}
				elif cls == "func_bomb_target":
					var m_info: Dictionary = models[m_idx]
					var q_center: Vector3 = (m_info["mins"] + m_info["maxs"]) * 0.5 + q_orig
					var gd_center := Vector3(-q_center.y, m_info["mins"].z + 16.0, -q_center.x) / BSP_SCALE_FACTOR
					var site_name := "A" if data["bombsites"].is_empty() else "B"
					data["bombsites"].append({"pos": gd_center, "radius": 8.5, "name": site_name})

		if has_orig:
			var gd_pos := Vector3(-q_orig.y, q_orig.z, -q_orig.x) / BSP_SCALE_FACTOR
			if cls == "info_player_start" or cls == "info_vip_start":
				data["ct_spawns"].append(gd_pos + Vector3(0, 0.25, 0))
			elif cls == "info_player_deathmatch":
				data["t_spawns"].append(gd_pos + Vector3(0, 0.25, 0))
			elif cls == "info_bomb_target":
				var site_name := "A" if data["bombsites"].is_empty() else "B"
				data["bombsites"].append({"pos": gd_pos, "radius": 8.5, "name": site_name})

static func _finalize_spawns_and_waypoints(floor_samples: PackedVector3Array, data: Dictionary) -> void:
	if data["ct_spawns"].is_empty():
		for i in range(6):
			data["ct_spawns"].append(Vector3(-6.0 + i * 2.5, 1.0, -25.0))
	if data["t_spawns"].is_empty():
		for i in range(6):
			data["t_spawns"].append(Vector3(-6.0 + i * 2.5, 1.0, 25.0))

	if data["bombsites"].is_empty():
		var sa: Vector3 = data["ct_spawns"][0] + Vector3(12.0, 0.0, 0.0)
		var sb: Vector3 = data["t_spawns"][0] + Vector3(-12.0, 0.0, 0.0)
		if floor_samples.size() >= 10:
			sa = floor_samples[int(floor_samples.size() * 0.25)]
			sb = floor_samples[int(floor_samples.size() * 0.75)]
		data["bombsites"].append({"pos": sa, "radius": 8.5, "name": "A"})
		data["bombsites"].append({"pos": sb, "radius": 8.5, "name": "B"})

	for sp in data["ct_spawns"]:
		data["waypoints"].append(sp)
	for sp in data["t_spawns"]:
		data["waypoints"].append(sp)
	for bs in data["bombsites"]:
		data["waypoints"].append(bs["pos"])

	var step: int = maxi(1, int(floor_samples.size() / 45))
	for i in range(0, floor_samples.size(), step):
		data["waypoints"].append(floor_samples[i] + Vector3(0, 0.3, 0))

static func _s32(u: int) -> int:
	return u - 4294967296 if u >= 2147483648 else u

static func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, surf_type: String = "stone") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = pos
	body.set_meta("surface_type", surf_type)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	body.add_child(mi)

	parent.add_child(body)
	return body

static func _build_training_range(parent: Node3D, data: Dictionary) -> void:
	_add_box(parent, Vector3(0, -0.5, 0), Vector3(86, 1.0, 86), Color(0.76, 0.68, 0.52), "sand")
	_add_box(parent, Vector3(0, 4.0, -43), Vector3(86, 8.0, 1.0), Color(0.68, 0.60, 0.46), "stone")
	_add_box(parent, Vector3(0, 4.0, 43), Vector3(86, 8.0, 1.0), Color(0.68, 0.60, 0.46), "stone")
	_add_box(parent, Vector3(-43, 4.0, 0), Vector3(1.0, 8.0, 86), Color(0.68, 0.60, 0.46), "stone")
	_add_box(parent, Vector3(43, 4.0, 0), Vector3(1.0, 8.0, 86), Color(0.68, 0.60, 0.46), "stone")
	_add_box(parent, Vector3(0, 0.55, 18), Vector3(18.0, 1.1, 0.8), Color(0.52, 0.48, 0.42), "stone")

	# Crates for testing crouch-jump
	_add_box(parent, Vector3(-8, 0.65, 14), Vector3(1.5, 1.3, 1.5), Color(0.45, 0.50, 0.36), "stone")
	_add_box(parent, Vector3(-11, 0.90, 14), Vector3(1.6, 1.8, 1.6), Color(0.45, 0.50, 0.36), "stone")

	var distances := [8.0, -2.0, -14.0, -28.0]
	for idx in range(distances.size()):
		for x_idx in range(-2, 3):
			var tpos := Vector3(x_idx * 4.5, 1.0, distances[idx])
			var tgt := _add_box(parent, tpos, Vector3(0.9, 1.8, 0.25), Color(0.85, 0.28, 0.20), "stone")
			tgt.set_meta("training_target", true)
			data["training_targets"].append(tgt)

	data["ct_spawns"].append(Vector3(0, 0.2, 22.0))
	data["t_spawns"].append(Vector3(4, 0.2, 22.0))
	data["waypoints"] = [Vector3(0, 0.2, 22.0)]
