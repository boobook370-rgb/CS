class_name ViewmodelBuilder
extends RefCounted

static var mdl_cache: Dictionary = {}

const MDL_FILE_MAP := {
	"glock": ["p_glock18.mdl", "v_glock18.mdl"],
	"usp": ["p_usp.mdl", "v_usp.mdl"],
	"deagle": ["p_deagle.mdl", "v_deagle.mdl"],
	"p228": ["p_p228.mdl", "v_p228.mdl"],
	"fiveseven": ["p_fiveseven.mdl", "v_fiveseven.mdl"],
	"shotgun": ["p_m3.mdl", "p_xm1014.mdl", "p_m3super90.mdl"],
	"m249": ["p_m249.mdl", "v_m249.mdl"],
	"mp5": ["p_mp5.mdl", "v_mp5.mdl"],
	"tmp": ["p_tmp.mdl", "v_tmp.mdl"],
	"mac10": ["p_mac10.mdl", "v_mac10.mdl"],
	"ump45": ["p_ump45.mdl", "v_ump45.mdl"],
	"galil": ["p_galil.mdl", "v_galil.mdl"],
	"famas": ["p_famas.mdl", "v_famas.mdl"],
	"ak47": ["p_ak47.mdl", "v_ak47.mdl"],
	"m4a1": ["p_m4a1.mdl", "v_m4a1.mdl"],
	"sg552": ["p_sg552.mdl", "v_sg552.mdl"],
	"aug": ["p_aug.mdl", "v_aug.mdl"],
	"scout": ["p_scout.mdl", "v_scout.mdl"],
	"awp": ["p_awp.mdl", "v_awp.mdl"],
	"g3sg1": ["p_g3sg1.mdl", "v_g3sg1.mdl"],
	"sg550": ["p_sg550.mdl", "v_sg550.mdl"],
	"knife": ["p_knife.mdl", "v_knife.mdl"],
	"he_grenade": ["p_hegrenade.mdl", "v_hegrenade.mdl"],
	"flashbang": ["p_flashbang.mdl", "v_flashbang.mdl"],
	"smoke_grenade": ["p_smokegrenade.mdl", "v_smokegrenade.mdl"],
	"c4": ["p_c4.mdl", "v_c4.mdl"]
}

const MDL_ROTATION_OFFSET := Vector3(0.0, 180.0, 90.0)

static func build_weapon_mesh(weapon_data: Dictionary, silenced: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "WeaponModel"

	var weapon_id: String = str(weapon_data.get("id", "glock"))
	var target_len: float = float(weapon_data.get("length", 0.55))

	var glb_path: String = "res://assets/models/" + weapon_id + ".glb"
	if ResourceLoader.exists(glb_path):
		var scene_res = load(glb_path)
		if scene_res:
			var inst: Node3D = scene_res.instantiate()
			root.add_child(inst)
			return root

	var mdl_mesh: ArrayMesh = _get_or_load_weapon_mdl(weapon_id, target_len)
	if mdl_mesh != null:
		var mi := MeshInstance3D.new()
		mi.mesh = mdl_mesh
		mi.rotation_degrees = MDL_ROTATION_OFFSET
		mi.position = Vector3(0.0, -0.04, -target_len * 0.35)
		root.add_child(mi)
		return root

	return _build_fallback_procedural(root, weapon_data, silenced)

static func _get_or_load_weapon_mdl(weapon_id: String, target_len: float) -> ArrayMesh:
	if mdl_cache.has(weapon_id):
		return mdl_cache[weapon_id]

	var candidates: Array = MDL_FILE_MAP.get(weapon_id, ["p_" + weapon_id + ".mdl", "v_" + weapon_id + ".mdl"])
	var folders := ["res://assets/models/", "res://cstrike/models/", "res://models/"]

	for folder in folders:
		for fname in candidates:
			var full_path: String = folder + str(fname)
			if FileAccess.file_exists(full_path):
				var mesh: ArrayMesh = _parse_goldsrc_mdl(full_path, target_len)
				if mesh != null:
					mdl_cache[weapon_id] = mesh
					print(">>> [MDL УСПЕХ] Загружена 3D-модель: ", full_path)
					return mesh

	return null

static func _parse_goldsrc_mdl(path: String, desired_length: float) -> ArrayMesh:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null

	var file_len: int = f.get_length()
	if file_len < 212:
		return null

	var magic: int = f.get_32()
	var version: int = f.get_32()
	if magic != 1414743113 or version != 10:
		return null

	f.seek(140)
	var numbones: int = _s32(f.get_32())
	var boneindex: int = _s32(f.get_32())

	f.seek(180)
	var numtextures: int = _s32(f.get_32())
	var textureindex: int = _s32(f.get_32())
	var _texturedataindex: int = _s32(f.get_32())
	var numskinref: int = _s32(f.get_32())
	var _numskinfamilies: int = _s32(f.get_32())
	var skinindex: int = _s32(f.get_32())
	var numbodyparts: int = _s32(f.get_32())
	var bodypartindex: int = _s32(f.get_32())

	var bone_transforms: Array[Transform3D] = []
	bone_transforms.resize(maxi(1, numbones))
	for b in range(numbones):
		var b_ofs: int = boneindex + b * 112
		f.seek(b_ofs + 32)
		var parent: int = _s32(f.get_32())
		f.seek(b_ofs + 64)
		var px: float = f.get_float()
		var py: float = f.get_float()
		var pz: float = f.get_float()
		var rx: float = f.get_float()
		var ry: float = f.get_float()
		var rz: float = f.get_float()

		var local_tr: Transform3D = _goldsrc_angle_matrix(Vector3(px, py, pz), Vector3(rx, ry, rz))
		if parent >= 0 and parent < b:
			bone_transforms[b] = bone_transforms[parent] * local_tr
		else:
			bone_transforms[b] = local_tr

	var materials: Array[StandardMaterial3D] = []
	var tex_sizes: Array[Vector2] = []
	for t in range(numtextures):
		var t_ofs: int = textureindex + t * 80
		f.seek(t_ofs + 64)
		var _flags: int = _s32(f.get_32())
		var w: int = _s32(f.get_32())
		var h: int = _s32(f.get_32())
		var d_ofs: int = _s32(f.get_32())

		var mat := StandardMaterial3D.new()
		mat.roughness = 0.65
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED

		if w > 0 and h > 0 and d_ofs > 0 and (d_ofs + w * h + 768) <= file_len:
			f.seek(d_ofs)
			var indices: PackedByteArray = f.get_buffer(w * h)
			var pal: PackedByteArray = f.get_buffer(768)
			var rgb := PackedByteArray()
			rgb.resize(w * h * 3)
			for p in range(w * h):
				var c_idx: int = int(indices[p]) * 3
				rgb[p * 3] = pal[c_idx]
				rgb[p * 3 + 1] = pal[c_idx + 1]
				rgb[p * 3 + 2] = pal[c_idx + 2]
			var img: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGB8, rgb)
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			mat.albedo_texture = tex
			tex_sizes.append(Vector2(float(w), float(h)))
		else:
			mat.albedo_color = Color(0.35, 0.37, 0.40)
			tex_sizes.append(Vector2(256.0, 256.0))

		materials.append(mat)

	var skin_refs: Array[int] = []
	if skinindex > 0 and numskinref > 0 and (skinindex + numskinref * 2) <= file_len:
		f.seek(skinindex)
		for s in range(numskinref):
			skin_refs.append(f.get_16())

	var raw_tris: Array = []
	var min_pt := Vector3(99999.0, 99999.0, 99999.0)
	var max_pt := Vector3(-99999.0, -99999.0, -99999.0)

	for bp in range(numbodyparts):
		var bp_ofs: int = bodypartindex + bp * 76
		f.seek(bp_ofs + 64)
		var nummodels: int = _s32(f.get_32())
		var _base: int = _s32(f.get_32())
		var modelindex: int = _s32(f.get_32())
		if nummodels <= 0 or modelindex <= 0:
			continue

		var m_ofs: int = modelindex
		f.seek(m_ofs + 72)
		var nummesh: int = _s32(f.get_32())
		var meshindex: int = _s32(f.get_32())
		var numverts: int = _s32(f.get_32())
		var vertinfoindex: int = _s32(f.get_32())
		var vertindex: int = _s32(f.get_32())
		var numnorms: int = _s32(f.get_32())
		var norminfoindex: int = _s32(f.get_32())
		var normindex: int = _s32(f.get_32())

		if numverts <= 0 or nummesh <= 0:
			continue

		f.seek(vertinfoindex)
		var v_bones: PackedByteArray = f.get_buffer(numverts)

		f.seek(vertindex)
		var verts: Array[Vector3] = []
		verts.resize(numverts)
		for v in range(numverts):
			var vx: float = f.get_float()
			var vy: float = f.get_float()
			var vz: float = f.get_float()
			var b_id: int = clampi(int(v_bones[v]), 0, bone_transforms.size() - 1)
			var p_gs: Vector3 = bone_transforms[b_id] * Vector3(vx, vy, vz)
			var p_gd := Vector3(-p_gs.y, p_gs.z, -p_gs.x)
			verts[v] = p_gd
			min_pt = min_pt.min(p_gd)
			max_pt = max_pt.max(p_gd)

		var norms: Array[Vector3] = []
		norms.resize(maxi(1, numnorms))
		if numnorms > 0 and normindex > 0:
			f.seek(norminfoindex)
			var n_bones: PackedByteArray = f.get_buffer(numnorms)
			f.seek(normindex)
			for n in range(numnorms):
				var nx: float = f.get_float()
				var ny: float = f.get_float()
				var nz: float = f.get_float()
				var b_id: int = clampi(int(n_bones[n]), 0, bone_transforms.size() - 1)
				var n_gs: Vector3 = bone_transforms[b_id].basis * Vector3(nx, ny, nz)
				norms[n] = Vector3(-n_gs.y, n_gs.z, -n_gs.x).normalized()

		for mesh_i in range(nummesh):
			var sub_ofs: int = meshindex + mesh_i * 20
			f.seek(sub_ofs)
			var _numtris: int = _s32(f.get_32())
			var triindex: int = _s32(f.get_32())
			var skinref: int = _s32(f.get_32())

			var tex_id: int = 0
			if skinref >= 0 and skinref < skin_refs.size():
				tex_id = skin_refs[skinref]
			var t_size: Vector2 = tex_sizes[tex_id] if (tex_id >= 0 and tex_id < tex_sizes.size()) else Vector2(256.0, 256.0)

			f.seek(triindex)
			while f.get_position() < file_len - 2:
				var cmd: int = _s16(f.get_16())
				if cmd == 0:
					break
				var is_fan: bool = (cmd < 0)
				var count: int = -cmd if is_fan else cmd
				var seq_v: Array = []
				for _k in range(count):
					var vi: int = clampi(_s16(f.get_16()), 0, verts.size() - 1)
					var ni: int = clampi(_s16(f.get_16()), 0, norms.size() - 1)
					var s_px: int = _s16(f.get_16())
					var t_px: int = _s16(f.get_16())
					var uv := Vector2(float(s_px) / maxf(1.0, t_size.x), float(t_px) / maxf(1.0, t_size.y))
					seq_v.append({"v": verts[vi], "n": norms[ni], "uv": uv})

				for k in range(2, count):
					var a: Dictionary
					var b: Dictionary
					var c: Dictionary
					if is_fan:
						a = seq_v[0]
						b = seq_v[k - 1]
						c = seq_v[k]
					else:
						if (k % 2) == 1:
							a = seq_v[k - 1]
							b = seq_v[k - 2]
							c = seq_v[k]
						else:
							a = seq_v[k - 2]
							b = seq_v[k - 1]
							c = seq_v[k]
					raw_tris.append({"tex": tex_id, "a": a, "b": b, "c": c})

	if raw_tris.is_empty():
		return null

	var center: Vector3 = (min_pt + max_pt) * 0.5
	var extents: Vector3 = max_pt - min_pt
	var max_dim: float = maxf(0.001, maxf(extents.x, maxf(extents.y, extents.z)))
	var scale_factor: float = desired_length / max_dim
	var swap_xz: bool = (extents.x > extents.z * 1.25)

	var out_mesh := ArrayMesh.new()
	var grouped: Dictionary = {}
	for tri in raw_tris:
		var tid: int = int(tri["tex"])
		if not grouped.has(tid):
			grouped[tid] = []
		grouped[tid].append(tri)

	for tid in grouped.keys():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if tid >= 0 and tid < materials.size():
			st.set_material(materials[tid])
		else:
			var def_mat := StandardMaterial3D.new()
			def_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			st.set_material(def_mat)

		for tri in grouped[tid]:
			for pt_key in ["a", "b", "c"]:
				var pt: Dictionary = tri[pt_key]
				var pos: Vector3 = (pt["v"] - center) * scale_factor
				var nrm: Vector3 = pt["n"]
				if swap_xz:
					pos = Vector3(-pos.z, pos.y, pos.x)
					nrm = Vector3(-nrm.z, nrm.y, nrm.x)
				st.set_uv(pt["uv"])
				st.set_normal(nrm)
				st.add_vertex(pos)

		st.commit(out_mesh)

	return out_mesh

static func _goldsrc_angle_matrix(pos: Vector3, angles: Vector3) -> Transform3D:
	var cx: float = cos(angles.x)
	var sx: float = sin(angles.x)
	var cy: float = cos(angles.y)
	var sy: float = sin(angles.y)
	var cz: float = cos(angles.z)
	var sz: float = sin(angles.z)

	var x_axis := Vector3(cy * cz, cy * sz, -sy)
	var y_axis := Vector3(sx * sy * cz - cx * sz, sx * sy * sz + cx * cz, sx * cy)
	var z_axis := Vector3(cx * sy * cz + sx * sz, cx * sy * sz - sx * cz, cx * cy)
	return Transform3D(Basis(x_axis, y_axis, z_axis), pos)

static func _s16(u: int) -> int:
	return u - 65536 if u >= 32768 else u

static func _s32(u: int) -> int:
	return u - 4294967296 if u >= 2147483648 else u

static func _build_fallback_procedural(root: Node3D, weapon_data: Dictionary, silenced: bool) -> Node3D:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = weapon_data.get("color", Color(0.25, 0.25, 0.28))
	body_mat.metallic = 0.65
	body_mat.roughness = 0.38

	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.12, 0.13, 0.15)
	dark_mat.metallic = 0.8
	dark_mat.roughness = 0.3

	var length: float = float(weapon_data.get("length", 0.5))
	var cat: String = str(weapon_data.get("category", "pistol"))

	if cat == "melee":
		var blade := MeshInstance3D.new()
		var bm := PrismMesh.new()
		bm.size = Vector3(0.015, 0.22, 0.04)
		blade.mesh = bm
		blade.material_override = body_mat
		blade.rotation_degrees = Vector3(-90, 0, 0)
		blade.position = Vector3(0, 0.01, -0.16)
		root.add_child(blade)
		return root

	var receiver := MeshInstance3D.new()
	var rec_mesh := BoxMesh.new()
	rec_mesh.size = Vector3(0.055, 0.085, length * 0.65)
	receiver.mesh = rec_mesh
	receiver.material_override = body_mat
	receiver.position = Vector3(0, 0, -length * 0.25)
	root.add_child(receiver)

	var barrel := MeshInstance3D.new()
	var bar_mesh := CylinderMesh.new()
	bar_mesh.top_radius = 0.014
	bar_mesh.bottom_radius = 0.016
	bar_mesh.height = length * 0.55
	barrel.mesh = bar_mesh
	barrel.material_override = dark_mat
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.02, -length * 0.68)
	root.add_child(barrel)

	if silenced:
		var sup := MeshInstance3D.new()
		var sup_m := CylinderMesh.new()
		sup_m.top_radius = 0.022
		sup_m.bottom_radius = 0.022
		sup_m.height = 0.18
		sup.mesh = sup_m
		sup.material_override = dark_mat
		sup.rotation_degrees = Vector3(90, 0, 0)
		sup.position = Vector3(0, 0.02, -length * 0.95)
		root.add_child(sup)

	return root
