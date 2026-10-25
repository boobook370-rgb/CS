extends Node

var selected_map_id: String = "de_dust2"
var selected_mode: String = "bomb"
var current_mode: String = "bomb"
var player_team: String = "CT"

var in_main_menu: bool = true
var is_paused: bool = false
var shop_open: bool = false
var friendly_fire: bool = false

var world_root: Node3D
var ui: UIController
var local_player: CombatActor
var actors: Array[CombatActor] = []

var map_data: Dictionary = {}
var map_waypoints: Array = []
var active_smokes: Array = []

var score_ct: int = 0
var score_t: int = 0
var round_number: int = 0

var freeze_timer: float = 0.0
var buy_timer: float = 0.0
var round_timer: float = 105.0
var round_end_timer: float = 0.0
var is_round_over: bool = false
var banner_text: String = ""

var bomb_planted: bool = false
var c4_timer: float = 40.0
var c4_beep_Accumulator: float = 0.0
var bomb_node: Node3D = null
var dropped_c4_node: Node3D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world_root = Node3D.new()
	world_root.name = "WorldRoot"
	add_child(world_root)

	if DisplayServer.get_name() != "headless":
		ui = UIController.new()
		add_child(ui)

func _unhandled_input(event: InputEvent) -> void:
	if in_main_menu:
		return
	if event.is_action_pressed("pause_menu"):
		if shop_open:
			toggle_shop(false)
		else:
			toggle_pause(not is_paused)
	elif event.is_action_pressed("buy_menu") and not is_paused:
		toggle_shop(not shop_open)

func toggle_pause(pause_state: bool) -> void:
	is_paused = pause_state
	if is_instance_valid(ui):
		ui.pause_panel.visible = is_paused
	if is_paused or shop_open or in_main_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_shop(open_state: bool) -> void:
	if open_state and not can_actor_buy(local_player):
		notify_player("Покупка доступна только в первые 25 секунд раунда!")
		return
	shop_open = open_state
	if is_instance_valid(ui):
		ui.toggle_shop(shop_open)
	if shop_open or is_paused or in_main_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func return_to_main_menu() -> void:
	in_main_menu = true
	is_paused = false
	shop_open = false
	_clear_world()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if is_instance_valid(ui):
		ui.show_main_menu(true)

func _clear_world() -> void:
	actors.clear()
	active_smokes.clear()
	local_player = null
	bomb_node = null
	dropped_c4_node = null
	for c in world_root.get_children():
		c.queue_free()

func start_match() -> void:
	_clear_world()
	in_main_menu = false
	is_paused = false
	shop_open = false
	current_mode = selected_mode
	if selected_map_id == "tr_range":
		current_mode = "training"

	score_ct = 0
	score_t = 0
	round_number = 0
	EconomyManager.reset_economy()

	map_data = MapBuilder.build_map(selected_map_id, world_root)
	map_waypoints = map_data.get("waypoints", [])

	local_player = CombatActor.new()
	local_player.actor_name = "Вы (Игрок)"
	local_player.team = player_team
	local_player.is_bot = false
	world_root.add_child(local_player)
	actors.append(local_player)

	if current_mode != "training":
		var bot_names_ct := ["Alpha-CT", "Bravo-CT", "Delta-CT", "Echo-CT", "Frost-CT"]
		var bot_names_t := ["Viper-T", "Kobra-T", "Shadow-T", "Raven-T", "Wolf-T"]
		var count: int = SettingsManager.bot_count_per_team
		for i in range(count):
			if player_team != "CT" or i < count - 1:
				var b_ct := BotAI.new()
				b_ct.actor_name = bot_names_ct[i % bot_names_ct.size()]
				b_ct.team = "CT"
				world_root.add_child(b_ct)
				actors.append(b_ct)
			if player_team != "T" or i < count - 1:
				var b_t := BotAI.new()
				b_t.actor_name = bot_names_t[i % bot_names_t.size()]
				b_t.team = "T"
				world_root.add_child(b_t)
				actors.append(b_t)
	else:
		local_player.money = 16000

	if is_instance_valid(ui):
		ui.show_main_menu(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	start_new_round()

func start_new_round() -> void:
	round_number += 1
	is_round_over = false
	bomb_planted = false
	c4_timer = 40.0
	freeze_timer = 0.0 if current_mode == "training" else 2.5
	buy_timer = 9999.0 if current_mode != "bomb" else 25.0
	round_timer = 999.0 if current_mode == "training" else 105.0
	banner_text = "РАУНД %d — ПОДГОТОВКА" % round_number

	if is_instance_valid(bomb_node):
		bomb_node.queue_free()
		bomb_node = null
	if is_instance_valid(dropped_c4_node):
		dropped_c4_node.queue_free()
		dropped_c4_node = null

	var ct_idx: int = 0
	var t_idx: int = 0
	var ct_spawns: Array = map_data.get("ct_spawns", [Vector3(0, 0.5, -25)])
	var t_spawns: Array = map_data.get("t_spawns", [Vector3(0, 0.5, 25)])
	var t_actors: Array[CombatActor] = []

	for a in actors:
		if not is_instance_valid(a):
			continue
		a.inventory[5] = ""
		if a.team == "CT":
			var sp: Vector3 = ct_spawns[ct_idx % ct_spawns.size()]
			ct_idx += 1
			a.respawn_at(sp, 0.0)
		else:
			var sp: Vector3 = t_spawns[t_idx % t_spawns.size()]
			t_idx += 1
			a.respawn_at(sp, PI)
			t_actors.append(a)

	if current_mode == "bomb" and t_actors.size() > 0:
		var carrier: CombatActor = local_player if local_player.team == "T" else t_actors[0]
		carrier.inventory[5] = "c4"
		if carrier == local_player:
			notify_player("У вас бомба C4! Установите её на точке A или B (Слот 5)")

	SfxManager.play_2d("round_start", 0.8)

func _process(delta: float) -> void:
	if in_main_menu or is_paused:
		return

	for i in range(active_smokes.size() - 1, -1, -1):
		active_smokes[i]["time"] -= delta
		if active_smokes[i]["time"] <= 0.0:
			if is_instance_valid(active_smokes[i]["node"]):
				active_smokes[i]["node"].queue_free()
			active_smokes.remove_at(i)

	if is_instance_valid(dropped_c4_node) and not bomb_planted:
		for a in actors:
			if is_instance_valid(a) and a.is_alive and a.team == "T":
				if a.global_position.distance_to(dropped_c4_node.global_position) < 1.8:
					a.inventory[5] = "c4"
					dropped_c4_node.queue_free()
					dropped_c4_node = null
					if a == local_player:
						notify_player("Вы подобрали бомбу C4!")
					break

	if freeze_timer > 0.0:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			banner_text = ""
		return

	buy_timer = maxf(0.0, buy_timer - delta)

	if is_round_over:
		round_end_timer -= delta
		if round_end_timer <= 0.0:
			start_new_round()
		return

	if bomb_planted:
		c4_timer -= delta
		c4_beep_Accumulator -= delta
		if c4_beep_Accumulator <= 0.0:
			c4_beep_Accumulator = clampf(c4_timer / 40.0, 0.12, 1.0)
			if is_instance_valid(bomb_node):
				SfxManager.play_3d("c4_beep", bomb_node.global_position, 55.0)
		if c4_timer <= 0.0:
			_detonate_planted_c4()
	else:
		round_timer -= delta
		if round_timer <= 0.0:
			if current_mode == "bomb":
				_end_round("CT", "Время раунда истекло — Спецназ защитил объекты!")
			elif current_mode == "tdm":
				var w_team := "CT" if score_ct >= score_t else "T"
				_end_round(w_team, "Матч окончен! Победила команда " + w_team)

func can_actor_buy(actor: CombatActor) -> bool:
	if not is_instance_valid(actor) or not actor.is_alive:
		return false
	if current_mode != "bomb":
		return true
	return buy_timer > 0.0

func is_in_bombsite(pos: Vector3) -> bool:
	for b in map_data.get("bombsites", []):
		if pos.distance_to(b["pos"]) <= float(b["radius"]):
			return true
	return false

func get_nearest_bombsite_pos(pos: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var best_d := 9999.0
	for b in map_data.get("bombsites", []):
		var d := pos.distance_to(b["pos"])
		if d < best_d:
			best_d = d
			best = b["pos"]
	return best

func plant_bomb(planter: CombatActor, pos: Vector3) -> void:
	if bomb_planted or is_round_over:
		return
	bomb_planted = true
	c4_timer = 40.0
	planter.money = EconomyManager.clamp_money(planter.money + EconomyManager.PLANT_PLANTER_BONUS)

	bomb_node = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.32, 0.16, 0.42)
	bomb_node.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.20, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.1, 0.1)
	bomb_node.material_override = mat
	world_root.add_child(bomb_node)
	bomb_node.global_position = pos + Vector3(0, 0.1, 0)

	SfxManager.play_2d("c4_plant", 0.95)
	banner_text = "БОМБА УСТАНОВЛЕНА! (40 секунд до взрыва)"

func defuse_bomb(defuser: CombatActor) -> void:
	if not bomb_planted or is_round_over:
		return
	defuser.money = EconomyManager.clamp_money(defuser.money + EconomyManager.DEFUSE_PLANTER_BONUS)
	_end_round("CT", "Бомба обезврежена! Спецназ (CT) одержал победу!")

func _detonate_planted_c4() -> void:
	if is_instance_valid(bomb_node):
		var bpos := bomb_node.global_position
		SfxManager.play_3d("explosion", bpos, 100.0)
		spawn_explosion_vfx(bpos, Color(1.0, 0.45, 0.1), 12.0)
		for a in actors:
			if is_instance_valid(a) and a.is_alive:
				var d := a.global_position.distance_to(bpos)
				if d < 28.0:
					a.apply_damage(180.0 * (1.0 - d / 28.0), 1.0, null, "C4 Explosion", false)
	_end_round("T", "Цель уничтожена! Террористы (T) одержали победу!")

func drop_c4_pickup(pos: Vector3) -> void:
	if is_instance_valid(dropped_c4_node):
		dropped_c4_node.queue_free()
	dropped_c4_node = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.30, 0.15, 0.36)
	dropped_c4_node.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.78, 0.15)
	dropped_c4_node.material_override = mat
	world_root.add_child(dropped_c4_node)
	dropped_c4_node.global_position = pos + Vector3(0, 0.15, 0)

func on_actor_killed(victim: CombatActor, killer: Node, weapon_name: String, is_hs: bool) -> void:
	var k_name: String = "Мир"
	if is_instance_valid(killer) and killer is CombatActor:
		k_name = (killer as CombatActor).actor_name

	if is_instance_valid(ui):
		ui.add_killfeed_entry(k_name, victim.actor_name, weapon_name, is_hs)

	if current_mode == "tdm":
		if is_instance_valid(killer) and killer is CombatActor:
			if killer.team == "CT":
				score_ct += 1
			else:
				score_t += 1
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(victim) and not in_main_menu:
				var spawns: Array = map_data.get("ct_spawns" if victim.team == "CT" else "t_spawns", [Vector3.ZERO])
				victim.respawn_at(spawns[randi() % spawns.size()], 0.0)
		)
		return

	if is_round_over or current_mode == "training":
		return

	var alive_ct: int = 0
	var alive_t: int = 0
	for a in actors:
		if is_instance_valid(a) and a.is_alive:
			if a.team == "CT":
				alive_ct += 1
			else:
				alive_t += 1

	if alive_ct == 0:
		_end_round("T", "Террористы (T) победили!")
	elif alive_t == 0 and not bomb_planted:
		_end_round("CT", "Спецназ (CT) победил!")

func _end_round(winner_team: String, message: String) -> void:
	if is_round_over:
		return
	is_round_over = true
	round_end_timer = 4.5
	banner_text = message
	if winner_team == "CT":
		score_ct += 1
	else:
		score_t += 1
	EconomyManager.award_round_end(winner_team, bomb_planted, actors)
	SfxManager.play_2d("round_end", 0.9)

func on_training_target_hit(target_node: Object, dmg: float, hit_pos: Vector3) -> void:
	spawn_hit_spark(hit_pos, Color(1.0, 0.85, 0.2))
	SfxManager.play_3d("hit", hit_pos, 30.0)
	notify_player("Попадание по мишени! Урон: %d" % int(dmg))
	if target_node is Node3D:
		var n := target_node as Node3D
		n.rotation_degrees.x = 75.0
		get_tree().create_timer(1.8).timeout.connect(func():
			if is_instance_valid(n):
				n.rotation_degrees.x = 0.0
		)

func has_clear_line_of_sight(from_pos: Vector3, to_pos: Vector3) -> bool:
	var space := world_root.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from_pos, to_pos, 1)
	var res := space.intersect_ray(q)
	return res.is_empty()

func is_line_blocked_by_smoke(from_pos: Vector3, to_pos: Vector3) -> bool:
	var seg := to_pos - from_pos
	var seg_len := seg.length()
	if seg_len < 0.01:
		return false
	var dir := seg / seg_len
	for s in active_smokes:
		var spos: Vector3 = s["pos"]
		var proj := clampf((spos - from_pos).dot(dir), 0.0, seg_len)
		var closest := from_pos + dir * proj
		if closest.distance_to(spos) <= 4.5:
			return true
	return false

func spawn_bullet_decal(pos: Vector3, normal: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var decal := MeshInstance3D.new()
	var qm := BoxMesh.new()
	qm.size = Vector3(0.08, 0.08, 0.02)
	decal.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.08)
	decal.material_override = mat
	world_root.add_child(decal)
	decal.global_position = pos + normal * 0.015
	get_tree().create_timer(8.0).timeout.connect(func():
		if is_instance_valid(decal):
			decal.queue_free()
	)

func spawn_hit_spark(pos: Vector3, col: Color) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var sp := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	sp.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	sp.material_override = mat
	world_root.add_child(sp)
	sp.global_position = pos
	get_tree().create_timer(0.18).timeout.connect(func():
		if is_instance_valid(sp):
			sp.queue_free()
	)

func spawn_explosion_vfx(pos: Vector3, col: Color, radius: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius * 0.5
	sm.height = radius
	sphere.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.65)
	mat.emission_enabled = true
	mat.emission = col
	sphere.material_override = mat
	world_root.add_child(sphere)
	sphere.global_position = pos
	get_tree().create_timer(0.35).timeout.connect(func():
		if is_instance_valid(sphere):
			sphere.queue_free()
	)

func spawn_smoke_cloud(pos: Vector3) -> void:
	var cloud := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 4.5
	sm.height = 7.0
	cloud.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.72, 0.75, 0.74, 0.88)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloud.material_override = mat
	world_root.add_child(cloud)
	cloud.global_position = pos + Vector3(0, 1.8, 0)
	active_smokes.append({"pos": pos, "node": cloud, "time": 16.0})

func notify_player(text: String) -> void:
	if is_instance_valid(ui):
		ui.notify(text)
