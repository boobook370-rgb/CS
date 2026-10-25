class_name BotAI
extends CombatActor

var nav_agent: NavigationAgent3D
var current_enemy: CombatActor = null
var reaction_timer: float = 0.0
var ai_think_timer: float = 0.0
var strafe_dir: float = 1.0
var strafe_timer: float = 0.0
var target_waypoint: Vector3 = Vector3.ZERO
var last_pos: Vector3 = Vector3.ZERO
var stuck_timer: float = 0.0

func _init() -> void:
	is_bot = true

func _ready() -> void:
	super._ready()
	nav_agent = NavigationAgent3D.new()
	nav_agent.path_desired_distance = 1.1
	nav_agent.target_desired_distance = 1.4
	add_child(nav_agent)

func respawn_at(pos: Vector3, look_yaw: float) -> void:
	super.respawn_at(pos, look_yaw)
	current_enemy = null
	target_waypoint = pos
	last_pos = pos
	stuck_timer = 0.0
	_perform_bot_shopping()
	_pick_next_tactical_objective()

func _perform_bot_shopping() -> void:
	if money >= 1000 and armor < 100:
		EconomyManager.try_buy_equipment(self, "kevlar_helmet", true)
	elif money >= 650 and armor < 50:
		EconomyManager.try_buy_equipment(self, "kevlar", true)

	if team == "CT" and not has_defuse_kit and money >= 1200:
		EconomyManager.try_buy_equipment(self, "defuse_kit", true)

	if inventory.get(1, "") == "":
		var preferred: Array[String] = []
		if team == "T":
			preferred = ["ak47", "sg552", "awp", "galil", "mp5", "mac10"]
		else:
			preferred = ["m4a1", "aug", "awp", "famas", "mp5", "tmp"]

		for wid in preferred:
				var w: Dictionary = WeaponDatabase.get_weapon(wid)
				EconomyManager.try_buy_weapon(self, wid, true)
				break

	if money >= 300 and grenades_owned.is_empty():
		EconomyManager.try_buy_weapon(self, "he_grenade", true)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_alive or GameManager.in_main_menu or GameManager.is_paused:
		return

	if GameManager.freeze_timer > 0.0:
		velocity = Vector3.ZERO
		return

	# Ослеплённый бот теряет ориентацию
	if flash_alpha > 1.2:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		move_and_slide()
		return

	ai_think_timer -= delta
	if ai_think_timer <= 0.0:
		ai_think_timer = 0.18
		_scan_for_enemies()
		_evaluate_objectives()

	_execute_combat_and_navigation(delta)

func _scan_for_enemies() -> void:
	var best_enemy: CombatActor = null
	var best_dist: float = 999.0
	var my_eyes := get_eye_position()

	for actor in GameManager.actors:
		if not is_instance_valid(actor) or not actor.is_alive or actor.team == team:
			continue
		var enemy_eyes := actor.get_eye_position()
		var dist := my_eyes.distance_to(enemy_eyes)
		if dist > 85.0:
			continue
		# Проверка дыма и стен
		if GameManager.is_line_blocked_by_smoke(my_eyes, enemy_eyes):
			continue
		if GameManager.has_clear_line_of_sight(my_eyes, enemy_eyes):
			if dist < best_dist:
				best_dist = dist
				best_enemy = actor

	if best_enemy != current_enemy:
		current_enemy = best_enemy
		# Время реакции зависит от сложности: 0=Easy (0.55c), 1=Medium (0.30c), 2=Hard (0.14c)
		var diff: int = SettingsManager.bot_difficulty
		reaction_timer = 0.55 if diff == 0 else (0.30 if diff == 1 else 0.14)

func _evaluate_objectives() -> void:
	# Автоматическая перезарядка в укрытии
	var wid := get_current_weapon_id()
	if current_enemy == null and int(ammo_clip.get(wid, 1)) == 0:
		start_reload()

	if GameManager.current_mode == "bomb":
		if team == "T":
			if inventory.get(5, "") == "c4" and not GameManager.bomb_planted:
				target_waypoint = GameManager.get_nearest_bombsite_pos(global_position)
				nav_agent.target_position = target_waypoint
				return
			elif GameManager.bomb_planted and GameManager.bomb_node != null:
				target_waypoint = GameManager.bomb_node.global_position
				nav_agent.target_position = target_waypoint
				return
		elif team == "CT" and GameManager.bomb_planted and GameManager.bomb_node != null:
			target_waypoint = GameManager.bomb_node.global_position
			nav_agent.target_position = target_waypoint
			return

	if global_position.distance_to(target_waypoint) < 2.2:
		_pick_next_tactical_objective()

func _pick_next_tactical_objective() -> void:
	if GameManager.map_waypoints.size() > 0:
		target_waypoint = GameManager.map_waypoints[randi() % GameManager.map_waypoints.size()]
		nav_agent.target_position = target_waypoint

func _execute_combat_and_navigation(delta: float) -> void:
	# Если террорист с бомбой дошёл до плента и рядом нет врагов — ставит C4
	if GameManager.current_mode == "bomb" and team == "T" and inventory.get(5, "") == "c4" and not GameManager.bomb_planted:
		if GameManager.is_in_bombsite(global_position) and current_enemy == null:
			if current_slot != 5:
				switch_slot(5)
			_process_c4_planting(delta)
			return

	# Если спецназовец у установленной бомбы и врагов рядом нет — разминирует
	if GameManager.current_mode == "bomb" and team == "CT" and GameManager.bomb_planted and GameManager.bomb_node != null:
		if global_position.distance_to(GameManager.bomb_node.global_position) < 2.3 and current_enemy == null:
			_process_c4_defusing(delta)
			return

	if current_slot == 5:
		switch_slot(1 if inventory[1] != "" else 2)

	var next_pos: Vector3 = nav_agent.get_next_path_position()
	if next_pos.distance_to(global_position) < 0.2:
		next_pos = target_waypoint

	var move_dir := (next_pos - global_position)
	move_dir.y = 0.0
	if move_dir.length() > 0.05:
		move_dir = move_dir.normalized()

	var spd: float = float(get_current_weapon_data().get("move_speed", 235.0)) * BASE_SPEED_SCALE

	# Стрельба и стрейф при контакте с противником
	if is_instance_valid(current_enemy) and current_enemy.is_alive:
		var to_enemy := current_enemy.get_eye_position() - get_eye_position()
		var desired_yaw := atan2(-to_enemy.x, -to_enemy.z)
		var horiz_len := Vector2(to_enemy.x, to_enemy.z).length()
		var desired_pitch := atan2(to_enemy.y, maxf(0.01, horiz_len))

		var turn_speed: float = 5.5 + float(SettingsManager.bot_difficulty) * 3.5
		yaw = lerp_angle(yaw, desired_yaw, delta * turn_speed)
		pitch = lerpf(pitch, desired_pitch, delta * turn_speed)
		rotation.y = yaw

		# Погрешность прицеливания по сложности
		var diff: int = SettingsManager.bot_difficulty
		var aim_jitter: float = 0.055 if diff == 0 else (0.025 if diff == 1 else 0.008)
		head_pivot.rotation.x = clampf(pitch + randf_range(-aim_jitter, aim_jitter), -1.4, 1.4)

		reaction_timer -= delta
		if reaction_timer <= 0.0:
			try_fire()

		strafe_timer -= delta
		if strafe_timer <= 0.0:
			strafe_timer = randf_range(0.45, 1.1)
			strafe_dir = -strafe_dir
		var right_vec := transform.basis.x * strafe_dir
		move_dir = right_vec * 0.65
	else:
		if move_dir.length() > 0.05:
			var desired_yaw := atan2(-move_dir.x, -move_dir.z)
			yaw = lerp_angle(yaw, desired_yaw, delta * 7.0)
			rotation.y = yaw
			pitch = lerpf(pitch, 0.0, delta * 5.0)
			head_pivot.rotation.x = pitch

	# Защита от застревания
	if global_position.distance_to(last_pos) < 0.06 and move_dir.length() > 0.2:
		stuck_timer += delta
		if stuck_timer > 0.85:
			stuck_timer = 0.0
			_pick_next_tactical_objective()
			if is_on_floor():
				velocity.y = JUMP_VELOCITY * 0.85
	else:
		stuck_timer = 0.0
	last_pos = global_position

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	velocity.x = move_toward(velocity.x, move_dir.x * spd, 38.0 * delta)
	velocity.z = move_toward(velocity.z, move_dir.z * spd, 38.0 * delta)
	move_and_slide()
