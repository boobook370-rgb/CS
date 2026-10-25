class_name CombatActor
extends CharacterBody3D

var actor_name: String = "Player"
var team: String = "CT"
var is_bot: bool = false
var is_alive: bool = true

var health: float = 100.0
var armor: int = 0
var has_helmet: bool = false
var has_defuse_kit: bool = false
var money: int = 800

var kills: int = 0
var deaths: int = 0

var inventory: Dictionary = {1: "", 2: "usp", 3: "knife", 4: "", 5: ""}
var grenades_owned: Array[String] = []
var current_slot: int = 2
var ammo_clip: Dictionary = {}
var ammo_reserve: Dictionary = {}
var silenced_weapons: Dictionary = {}
var burst_weapons: Dictionary = {}
var scope_level: int = 0

var fire_cooldown: float = 0.0
var reload_timer: float = 0.0
var is_reloading: bool = false
var reload_step: int = 0
var recoil_pitch: float = 0.0
var recoil_yaw: float = 0.0
var flash_alpha: float = 0.0
var step_timer: float = 0.0

var is_crouching: bool = false
var is_walking: bool = false
var plant_progress: float = 0.0
var defuse_progress: float = 0.0

var col_shape: CollisionShape3D
var body_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var head_pivot: Node3D
var camera: Camera3D
var viewmodel_pivot: Node3D
var muzzle_light: OmniLight3D
var muzzle_flash_timer: float = 0.0

var yaw: float = 0.0
var pitch: float = 0.0
var spectate_index: int = 0

const GRAVITY: float = 21.0
const JUMP_VELOCITY: float = 7.4
const BASE_SPEED_SCALE: float = 0.028

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 2
	_build_actor_nodes()
	reset_for_new_match()

func _build_actor_nodes() -> void:
	col_shape = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.75
	col_shape.shape = cap
	col_shape.position = Vector3(0, 0.875, 0)
	add_child(col_shape)

	body_mesh = MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.36
	bm.height = 1.45
	body_mesh.mesh = bm
	body_mesh.position = Vector3(0, 0.75, 0)
	add_child(body_mesh)

	head_mesh = MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.22
	hm.height = 0.44
	head_mesh.mesh = hm
	head_mesh.position = Vector3(0, 1.58, 0)
	add_child(head_mesh)

	head_pivot = Node3D.new()
	head_pivot.position = Vector3(0, 1.56, 0)
	add_child(head_pivot)

	camera = Camera3D.new()
	camera.fov = SettingsManager.fov
	camera.current = not is_bot
	head_pivot.add_child(camera)

	viewmodel_pivot = Node3D.new()
	viewmodel_pivot.position = Vector3(0.22, -0.20, -0.35)
	camera.add_child(viewmodel_pivot)

	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1.0, 0.82, 0.35)
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 4.5
	viewmodel_pivot.add_child(muzzle_light)

	_update_team_materials()

func _update_team_materials() -> void:
	var mat := StandardMaterial3D.new()
	if team == "CT":
		mat.albedo_color = Color(0.18, 0.38, 0.68)
	else:
		mat.albedo_color = Color(0.72, 0.42, 0.20)
	mat.roughness = 0.55
	body_mesh.material_override = mat

	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.25, 0.28, 0.32) if team == "CT" else Color(0.82, 0.65, 0.52)
	head_mesh.material_override = hmat

	body_mesh.visible = true
	head_mesh.visible = true

func reset_for_new_match() -> void:
	money = EconomyManager.START_MONEY
	kills = 0
	deaths = 0
	armor = 0
	has_helmet = false
	has_defuse_kit = false
	give_default_loadout()

func give_default_loadout() -> void:
	inventory = {
		1: "",
		2: "usp" if team == "CT" else "glock",
		3: "knife",
		4: "",
		5: ""
	}
	grenades_owned.clear()
	ammo_clip.clear()
	ammo_reserve.clear()
	var start_pistol: String = inventory[2]
	var w: Dictionary = WeaponDatabase.get_weapon(start_pistol)
	ammo_clip[start_pistol] = int(w["mag_size"])
	ammo_reserve[start_pistol] = int(w["reserve_max"])
	ammo_clip["knife"] = 1
	ammo_reserve["knife"] = 0
	switch_slot(2)

func respawn_at(pos: Vector3, look_yaw: float) -> void:
	is_alive = true
	health = 100.0
	is_reloading = false
	reload_timer = 0.0
	reload_step = 0
	plant_progress = 0.0
	defuse_progress = 0.0
	scope_level = 0
	flash_alpha = 0.0
	velocity = Vector3.ZERO
	
	var space := get_world_3d().direct_space_state
	var ray_q := PhysicsRayQueryParameters3D.create(pos + Vector3(0, 1.0, 0), pos - Vector3(0, 15.0, 0), 1, [get_rid()])
	var ray_res: Dictionary = space.intersect_ray(ray_q)
	if not ray_res.is_empty():
		global_position = ray_res["position"] + Vector3(0, 0.05, 0)
	else:
		global_position = pos

	yaw = look_yaw
	pitch = 0.0
	rotation.y = yaw
	head_pivot.rotation.x = 0.0
	col_shape.disabled = false
	_update_team_materials()

	for slot in [1, 2]:
		var wid: String = inventory.get(slot, "")
		if wid != "":
			var w: Dictionary = WeaponDatabase.get_weapon(wid)
			ammo_clip[wid] = int(w["mag_size"])
			ammo_reserve[wid] = int(w["reserve_max"])

	if inventory[1] != "":
		switch_slot(1)
	else:
		switch_slot(2)

	if not is_bot:
		camera.current = true
		camera.fov = SettingsManager.fov
		camera.position = Vector3.ZERO
		camera.rotation = Vector3.ZERO
		viewmodel_pivot.visible = true

func equip_purchased_weapon(weapon_id: String) -> void:
	var w: Dictionary = WeaponDatabase.get_weapon(weapon_id)
	var slot: int = int(w["slot"])
	if slot == 4:
		if not grenades_owned.has(weapon_id):
			grenades_owned.append(weapon_id)
		inventory[4] = grenades_owned[0]
		ammo_clip[weapon_id] = 1
		ammo_reserve[weapon_id] = 0
		switch_slot(4)
		return

	inventory[slot] = weapon_id
	ammo_clip[weapon_id] = int(w["mag_size"])
	ammo_reserve[weapon_id] = int(w["reserve_max"])
	switch_slot(slot)

func has_grenade(weapon_id: String) -> bool:
	return grenades_owned.has(weapon_id)

func get_current_weapon_id() -> String:
	return str(inventory.get(current_slot, "knife"))

func get_current_weapon_data() -> Dictionary:
	return WeaponDatabase.get_weapon(get_current_weapon_id())

func switch_slot(slot: int) -> void:
	if slot == 4 and grenades_owned.size() > 0:
		if current_slot == 4:
			var idx: int = (grenades_owned.find(inventory[4]) + 1) % grenades_owned.size()
			inventory[4] = grenades_owned[idx]
		else:
			inventory[4] = grenades_owned[0]

	if str(inventory.get(slot, "")) == "":
		return
	current_slot = slot
	is_reloading = false
	reload_timer = 0.0
	reload_step = 0
	scope_level = 0
	if not is_bot and is_instance_valid(camera):
		camera.fov = SettingsManager.fov
		var wid: String = get_current_weapon_id()
		if SfxManager.sound_cache.has(wid + "_deploy"):
			SfxManager.play_2d(wid + "_deploy", 0.8)
		elif SfxManager.sound_cache.has(wid + "_boltpull"):
			SfxManager.play_2d(wid + "_boltpull", 0.65)
	_rebuild_viewmodel()

func _rebuild_viewmodel() -> void:
	if is_bot:
		return
	for c in viewmodel_pivot.get_children():
		if c != muzzle_light:
			c.queue_free()
	var wid: String = get_current_weapon_id()
	var wdata: Dictionary = WeaponDatabase.get_weapon(wid)
	var is_silenced: bool = bool(silenced_weapons.get(wid, false))
	var mesh_node: Node3D = ViewmodelBuilder.build_weapon_mesh(wdata, is_silenced)
	viewmodel_pivot.add_child(mesh_node)

func _input(event: InputEvent) -> void:
	if is_bot or GameManager.is_paused or GameManager.in_main_menu or GameManager.shop_open:
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if not is_alive:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_cycle_spectator()
		return

	if event is InputEventMouseMotion:
		var sens_scale: float = 0.45 if scope_level > 0 else 1.0
		var sens: float = SettingsManager.mouse_sensitivity * sens_scale
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, -1.48, 1.48)
		rotation.y = yaw
		if is_instance_valid(head_pivot):
			head_pivot.rotation.x = pitch

	if event.is_action_pressed("slot_1"):
		switch_slot(1)
	elif event.is_action_pressed("slot_2"):
		switch_slot(2)
	elif event.is_action_pressed("slot_3"):
		switch_slot(3)
	elif event.is_action_pressed("slot_4"):
		switch_slot(4)
	elif event.is_action_pressed("slot_5"):
		switch_slot(5)
	elif event.is_action_pressed("reload"):
		start_reload()
	elif event.is_action_pressed("alt_fire"):
		trigger_alt_fire()
	elif event.is_action_pressed("buy_ammo_primary"):
		var res: Dictionary = EconomyManager.try_buy_ammo(self, 1, GameManager.can_actor_buy(self))
		GameManager.notify_player(res["reason"])
	elif event.is_action_pressed("buy_ammo_secondary"):
		var res: Dictionary = EconomyManager.try_buy_ammo(self, 2, GameManager.can_actor_buy(self))
		GameManager.notify_player(res["reason"])

func _physics_process(delta: float) -> void:
	if GameManager.in_main_menu or GameManager.is_paused:
		return

	if muzzle_flash_timer > 0.0:
		muzzle_flash_timer -= delta
		if muzzle_flash_timer <= 0.0:
			muzzle_light.light_energy = 0.0

	if flash_alpha > 0.0:
		flash_alpha = maxf(0.0, flash_alpha - delta * 0.42)

	if not is_alive:
		_update_spectator_camera(delta)
		return

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	recoil_pitch = move_toward(recoil_pitch, 0.0, delta * 0.45)
	recoil_yaw = move_toward(recoil_yaw, 0.0, delta * 0.45)

	if is_reloading:
		reload_timer -= delta
		var wid: String = get_current_weapon_id()
		var wdata: Dictionary = get_current_weapon_data()
		var total_time: float = float(wdata.get("reload_time", 2.5))

		if reload_step == 0 and reload_timer <= total_time * 0.55:
			reload_step = 1
			var snd_in := wid + "_clipin"
			if SfxManager.sound_cache.has(snd_in):
				SfxManager.play_2d(snd_in, 1.0)

		if reload_step == 1 and reload_timer <= total_time * 0.20:
			reload_step = 2
			var snd_bolt := wid + "_boltpull"
			if SfxManager.sound_cache.has(snd_bolt):
				SfxManager.play_2d(snd_bolt, 1.0)

		if not is_bot:
			viewmodel_pivot.position.y = -0.32 + sin(reload_timer * 8.0) * 0.04

		if reload_timer <= 0.0:
			_finish_reload()
	else:
		if not is_bot:
			var speed_2d: float = Vector2(velocity.x, velocity.z).length()
			var bob: float = sin(Time.get_ticks_msec() * 0.012) * 0.012 * clampf(speed_2d / 6.0, 0.0, 1.0)
			viewmodel_pivot.position = viewmodel_pivot.position.lerp(Vector3(0.22, -0.20 + bob, -0.35), delta * 14.0)

	if not is_bot:
		head_pivot.rotation.x = clampf(pitch + recoil_pitch, -1.52, 1.52)
		head_pivot.rotation.y = recoil_yaw
		_process_player_movement_and_actions(delta)

func _process_player_movement_and_actions(delta: float) -> void:
	if GameManager.freeze_timer > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	is_crouching = Input.is_action_pressed("crouch")
	is_walking = Input.is_action_pressed("walk")

	var target_h: float = 1.05 if is_crouching else 1.56
	head_pivot.position.y = lerpf(head_pivot.position.y, target_h, delta * 12.0)

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1.0
	if Input.is_action_pressed("move_back"): input_dir.y += 1.0
	if Input.is_action_pressed("move_left"): input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"): input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var wdata: Dictionary = get_current_weapon_data()
	var max_spd: float = float(wdata.get("move_speed", 240.0)) * BASE_SPEED_SCALE
	if is_crouching:
		max_spd *= 0.48
	elif is_walking:
		max_spd *= 0.54
	if scope_level > 0:
		max_spd *= 0.72

	var wish_dir: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			SfxManager.play_group("jump", 0.7)
		var accel: float = 52.0 if wish_dir.length() > 0.01 else 38.0
		velocity.x = move_toward(velocity.x, wish_dir.x * max_spd, accel * delta)
		velocity.z = move_toward(velocity.z, wish_dir.z * max_spd, accel * delta)

		var horiz_spd: float = Vector2(velocity.x, velocity.z).length()
		if horiz_spd > 2.2 and not is_walking and not is_crouching:
			step_timer -= delta
			if step_timer <= 0.0:
				step_timer = 0.36
				if SfxManager.sound_cache.has("step_dirt_group"):
					SfxManager.play_group("step_dirt", 0.5)
				else:
					SfxManager.play_group("step_default", 0.5)
	else:
		velocity.y -= GRAVITY * delta
		velocity.x = move_toward(velocity.x, wish_dir.x * max_spd, 12.0 * delta)
		velocity.z = move_toward(velocity.z, wish_dir.z * max_spd, 12.0 * delta)

	move_and_slide()

	if not GameManager.shop_open:
		var wid: String = get_current_weapon_id()
		if wid == "c4":
			if Input.is_action_pressed("fire") or Input.is_action_pressed("interact"):
				_process_c4_planting(delta)
			else:
				plant_progress = 0.0
		else:
			var auto_fire: bool = bool(wdata.get("auto", false))
			if auto_fire and Input.is_action_pressed("fire"):
				try_fire()
			elif not auto_fire and Input.is_action_just_pressed("fire"):
				try_fire()

		if team == "CT" and Input.is_action_pressed("interact"):
			_process_c4_defusing(delta)
		else:
			defuse_progress = 0.0

func _process_c4_planting(delta: float) -> void:
	if not GameManager.is_in_bombsite(global_position) or GameManager.bomb_planted:
		plant_progress = 0.0
		return
	velocity.x = 0.0
	velocity.z = 0.0
	plant_progress += delta
	if plant_progress >= 3.0:
		plant_progress = 0.0
		inventory[5] = ""
		switch_slot(1 if inventory[1] != "" else 2)
		GameManager.plant_bomb(self, global_position)

func _process_c4_defusing(delta: float) -> void:
	if not GameManager.bomb_planted or GameManager.bomb_node == null:
		defuse_progress = 0.0
		return
	if global_position.distance_to(GameManager.bomb_node.global_position) > 2.8:
		defuse_progress = 0.0
		return
	velocity.x = 0.0
	velocity.z = 0.0
	var needed: float = 5.0 if has_defuse_kit else 10.0
	defuse_progress += delta / needed
	if defuse_progress >= 1.0:
		defuse_progress = 0.0
		GameManager.defuse_bomb(self)

func trigger_alt_fire() -> void:
	var wid: String = get_current_weapon_id()
	var wdata: Dictionary = get_current_weapon_data()
	var alt: String = str(wdata.get("alt_mode", "none"))

	match alt:
		"silencer":
			var cur := bool(silenced_weapons.get(wid, false))
			silenced_weapons[wid] = not cur
			SfxManager.play_2d("reload", 0.6)
			_rebuild_viewmodel()
			if not is_bot:
				GameManager.notify_player("Глушитель " + ("установлен" if not cur else "снят"))
		"burst":
			var cur := bool(burst_weapons.get(wid, false))
			burst_weapons[wid] = not cur
			SfxManager.play_2d("ui_click", 0.7)
			if not is_bot:
				GameManager.notify_player("Режим стрельбы: " + ("Очередь по 3 патрона" if not cur else "Одиночный/Авто"))
		"scope_1":
			scope_level = 0 if scope_level > 0 else 1
			if not is_bot:
				camera.fov = 48.0 if scope_level == 1 else SettingsManager.fov
				SfxManager.play_2d("ui_click", 0.6)
		"scope_2":
			scope_level = (scope_level + 1) % 3
			if not is_bot:
				if scope_level == 1:
					camera.fov = 34.0
				elif scope_level == 2:
					camera.fov = 15.0
				else:
					camera.fov = SettingsManager.fov
				SfxManager.play_2d("ui_click", 0.6)
		"heavy_stab":
			try_fire(true)

func start_reload() -> void:
	if is_reloading:
		return
	var wid: String = get_current_weapon_id()
	var wdata: Dictionary = get_current_weapon_data()
	var max_mag: int = int(wdata.get("mag_size", 1))
	var cur_clip: int = int(ammo_clip.get(wid, 0))
	var cur_res: int = int(ammo_reserve.get(wid, 0))
	if cur_clip >= max_mag or cur_res <= 0 or wdata["category"] in ["melee", "grenade", "c4"]:
		return

	is_reloading = true
	reload_step = 0
	scope_level = 0
	if not is_bot:
		camera.fov = SettingsManager.fov
	reload_timer = float(wdata.get("reload_time", 2.5))

	var snd_out := wid + "_clipout"
	if SfxManager.sound_cache.has(snd_out):
		SfxManager.play_2d(snd_out, 1.0)
	else:
		SfxManager.play_2d("reload", 0.9)

func _finish_reload() -> void:
	is_reloading = false
	var wid: String = get_current_weapon_id()
	var wdata: Dictionary = get_current_weapon_data()
	var max_mag: int = int(wdata.get("mag_size", 1))
	var cur_clip: int = int(ammo_clip.get(wid, 0))
	var cur_res: int = int(ammo_reserve.get(wid, 0))
	var needed: int = max_mag - cur_clip
	var take: int = mini(needed, cur_res)
	ammo_clip[wid] = cur_clip + take
	ammo_reserve[wid] = cur_res - take
	if GameManager.current_mode == "training":
		ammo_reserve[wid] = int(wdata.get("reserve_max", 90))

func try_fire(heavy_knife: bool = false) -> void:
	if fire_cooldown > 0.0 or is_reloading or GameManager.freeze_timer > 0.0:
		return

	var wid: String = get_current_weapon_id()
	var wdata: Dictionary = get_current_weapon_data()
	var cat: String = str(wdata.get("category", "pistol"))

	if cat == "grenade":
		_throw_grenade(wid)
		return

	if cat == "melee":
		fire_cooldown = 0.95 if heavy_knife else 0.40
		SfxManager.play_2d("knife", 0.9)
		if not is_bot:
			viewmodel_pivot.position.z = -0.52
		var dmg: float = 65.0 if heavy_knife else 35.0
		_perform_hitscan(dmg, 0.85, 2.8, 0.0, wdata["name"])
		return

	var cur_clip: int = int(ammo_clip.get(wid, 0))
	if cur_clip <= 0:
		SfxManager.play_2d("ui_click", 0.5)
		start_reload()
		return

	var is_burst: bool = bool(burst_weapons.get(wid, false))
	var shots_to_fire: int = mini(3, cur_clip) if is_burst else 1
	ammo_clip[wid] = cur_clip - shots_to_fire
	fire_cooldown = float(wdata.get("fire_rate", 0.12)) * (1.8 if is_burst else 1.0)

	var is_silenced: bool = bool(silenced_weapons.get(wid, false)) or wdata.get("alt_mode") == "silenced_builtin"
	var shoot_snd := wid + "_shoot"

	if is_silenced and SfxManager.sound_cache.has("usp_shoot"):
		SfxManager.play_2d("usp_shoot", 0.85)
	elif SfxManager.sound_cache.has(shoot_snd):
		SfxManager.play_2d(shoot_snd, 1.0)
	elif cat == "sniper":
		SfxManager.play_2d("sniper", 1.0)
	elif wid == "shotgun":
		SfxManager.play_2d("shotgun", 1.0)
	elif cat == "pistol":
		SfxManager.play_2d("pistol", 1.0)
	else:
		SfxManager.play_2d("rifle", 1.0)

	if not is_bot:
		viewmodel_pivot.position.z = -0.26
		if not is_silenced:
			muzzle_light.light_energy = 2.2
			muzzle_flash_timer = 0.045

	var pellets: int = int(wdata.get("pellets", 1))
	var base_spread: float = float(wdata.get("spread", 0.015))
	var vel_2d: float = Vector2(velocity.x, velocity.z).length()
	var move_inaccuracy: float = clampf(vel_2d * 0.006, 0.0, 0.045)
	if not is_on_floor():
		move_inaccuracy += 0.055
	if is_crouching:
		base_spread *= 0.65
	if scope_level > 0:
		base_spread *= 0.25

	for _s in range(shots_to_fire):
		for _p in range(pellets):
			_perform_hitscan(
				float(wdata.get("damage", 30.0)),
				float(wdata.get("armor_pen", 0.7)),
				float(wdata.get("range", 200.0)),
				base_spread + move_inaccuracy,
				str(wdata.get("name", wid))
			)

	var rec: float = float(wdata.get("recoil", 0.03))
	recoil_pitch = clampf(recoil_pitch + rec, 0.0, 0.24)
	recoil_yaw += randf_range(-rec * 0.35, rec * 0.35)

func _perform_hitscan(dmg: float, armor_pen: float, max_range: float, spread: float, weapon_label: String) -> void:
	var eye_origin: Vector3 = get_eye_position()
	var forward: Vector3 = get_look_direction()
	var right: Vector3 = head_pivot.global_transform.basis.x
	var up: Vector3 = head_pivot.global_transform.basis.y
	var dir: Vector3 = (forward + right * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()
	var target_pt: Vector3 = eye_origin + dir * max_range

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(eye_origin, target_pt, 1 | 2, [get_rid()])
	var result: Dictionary = space.intersect_ray(query)

	if result.is_empty():
		return

	var hit_pos: Vector3 = result["position"]
	var hit_normal: Vector3 = result["normal"]
	var collider: Object = result["collider"]

	if collider is CombatActor:
		var victim := collider as CombatActor
		if victim.team != team or GameManager.friendly_fire:
			var is_headshot: bool = (hit_pos.y - victim.global_position.y) > 1.36
			victim.apply_damage(dmg, armor_pen, self, weapon_label, is_headshot)
			GameManager.spawn_hit_spark(hit_pos, Color(0.85, 0.12, 0.12))
	elif collider.has_meta("training_target"):
		GameManager.on_training_target_hit(collider, dmg, hit_pos)
	else:
		GameManager.spawn_bullet_decal(hit_pos, hit_normal)

func _throw_grenade(wid: String) -> void:
	fire_cooldown = 0.85
	grenades_owned.erase(wid)
	if grenades_owned.size() > 0:
		inventory[4] = grenades_owned[0]
	else:
		inventory[4] = ""
		switch_slot(1 if inventory[1] != "" else 2)

	var proj := GrenadeProjectile.new()
	proj.grenade_type = wid
	proj.thrower = self
	GameManager.world_root.add_child(proj)
	proj.global_position = get_eye_position() + get_look_direction() * 0.65
	proj.linear_velocity = get_look_direction() * 16.5 + Vector3(0, 3.2, 0) + velocity * 0.5

func apply_damage(raw_damage: float, armor_pen: float, attacker: Node, weapon_label: String, is_headshot: bool) -> void:
	if not is_alive:
		return

	var final_dmg: float = raw_damage
	if is_headshot:
		final_dmg *= 3.8
		if has_helmet and armor > 0:
			final_dmg *= armor_pen
			armor = maxi(0, armor - int(raw_damage * 0.45))
			SfxManager.play_group("hit_helmet", 1.0)
		else:
			SfxManager.play_group("headshot", 1.0)
	else:
		if armor > 0:
			var absorbed: float = final_dmg * (1.0 - armor_pen)
			armor = maxi(0, armor - int(absorbed * 0.5))
			final_dmg *= armor_pen
			SfxManager.play_group("hit_kevlar", 0.9)
		else:
			SfxManager.play_group("hit_flesh", 0.9)

		if randf() < 0.4:
			SfxManager.play_group("pain", 0.7)

	health -= final_dmg
	if health <= 0.0:
		health = 0.0
		_die(attacker, weapon_label, is_headshot)

func apply_flashbang(duration: float) -> void:
	flash_alpha = clampf(duration, 0.0, 3.8)

func _die(attacker: Node, weapon_label: String, is_headshot: bool) -> void:
	is_alive = false
	deaths += 1
	col_shape.set_deferred("disabled", true)
	body_mesh.visible = false
	head_mesh.visible = false

	SfxManager.play_group("death", 1.0)

	if not is_bot and is_instance_valid(viewmodel_pivot):
		viewmodel_pivot.visible = false

	if inventory.get(5, "") == "c4":
		inventory[5] = ""
		GameManager.drop_c4_pickup(global_position)

	if is_instance_valid(attacker) and attacker is CombatActor and attacker != self:
		var killer := attacker as CombatActor
		killer.kills += 1
		var w: Dictionary = WeaponDatabase.get_weapon(killer.get_current_weapon_id())
		var reward: int = int(w.get("kill_reward", 300))
		killer.money = EconomyManager.clamp_money(killer.money + reward)

	GameManager.on_actor_killed(self, attacker, weapon_label, is_headshot)

func _cycle_spectator() -> void:
	if GameManager.actors.is_empty():
		return
	for _i in range(GameManager.actors.size()):
		spectate_index = (spectate_index + 1) % GameManager.actors.size()
		var cand: CombatActor = GameManager.actors[spectate_index]
		if is_instance_valid(cand) and cand.is_alive:
			return

func _update_spectator_camera(delta: float) -> void:
	if is_bot or GameManager.actors.is_empty():
		return
	var target: CombatActor = null
	if spectate_index < GameManager.actors.size():
		var cand: CombatActor = GameManager.actors[spectate_index]
		if is_instance_valid(cand) and cand.is_alive:
			target = cand
	if target == null:
		for a in GameManager.actors:
			if is_instance_valid(a) and a.is_alive:
				target = a
				break
	if target != null:
		var desired_pos: Vector3 = target.get_eye_position() - target.get_look_direction() * 2.8 + Vector3(0, 0.8, 0)
		camera.global_position = camera.global_position.lerp(desired_pos, delta * 8.0)
		camera.look_at(target.get_eye_position(), Vector3.UP)

func get_eye_position() -> Vector3:
	return head_pivot.global_position

func get_look_direction() -> Vector3:
	return -head_pivot.global_transform.basis.z.normalized()
