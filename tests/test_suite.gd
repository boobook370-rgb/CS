extends Node

func run_all_tests() -> bool:
	print("=== ЗАПУСК АВТОМАТИЗИРОВАННЫХ ТЕСТОВ TACTICAL STRIKE 1.6 ===")
	var passed: int = 0
	var failed: int = 0

	# Тест 1: Проверка всех 25 видов оружия
	var expected_weapons := [
		"glock", "usp", "deagle", "p228", "fiveseven",
		"mp5", "tmp", "mac10", "ump45",
		"ak47", "m4a1", "galil", "famas", "aug", "sg552",
		"scout", "awp", "g3sg1", "sg550",
		"m249", "shotgun", "knife",
		"he_grenade", "smoke_grenade", "flashbang"
	]
	var all_found := true
	for wid in expected_weapons:
		if not WeaponDatabase.weapons.has(wid):
			push_error("Оружие отсутствует в базе: " + wid)
			all_found = false
	if all_found:
		print("[PASS] Тест 1: Все 25 видов оружия присутствуют и сконфигурированы.")
		passed += 1
	else:
		failed += 1

	# Тест 2: Проверка экономики и покупки
	var dummy := CombatActor.new()
	dummy.team = "CT"
	add_child(dummy)
	dummy.money = 4000
	var res_buy := EconomyManager.try_buy_weapon(dummy, "m4a1", true)
	var res_helm := EconomyManager.try_buy_equipment(dummy, "kevlar_helmet", true)
	if res_buy["ok"] and dummy.inventory[1] == "m4a1" and dummy.money == 900 and not res_helm["ok"]:
		print("[PASS] Тест 2: Экономика, проверка баланса и покупка оружия работают корректно.")
		passed += 1
	else:
		push_error("Ошибка теста экономики")
		failed += 1

	# Тест 3: Проверка получения урона и брони
	dummy.health = 100.0
	dummy.armor = 100
	dummy.has_helmet = true
	dummy.apply_damage(36.0, 0.78, null, "AK-47", false)
	if dummy.health < 100.0 and dummy.health > 70.0 and dummy.armor < 100:
		print("[PASS] Тест 3: Расчёт урона и поглощения бронёй работает корректно.")
		passed += 1
	else:
		push_error("Ошибка расчёта урона")
		failed += 1
	dummy.queue_free()

	# Тест 4: Генерация карт
	var test_world := Node3D.new()
	add_child(test_world)
	var maps_ok := true
	for m_id in ["de_sandstrike", "de_rustyard", "de_bunker09", "tr_range"]:
		var mdata := MapBuilder.build_map(m_id, test_world)
		if mdata["ct_spawns"].is_empty() or mdata["t_spawns"].is_empty():
			maps_ok = false
	test_world.queue_free()
	if maps_ok:
		print("[PASS] Тест 4: Все карты и точки возрождения генерируются без ошибок.")
		passed += 1
	else:
		failed += 1

	print("=== ИТОГ ТЕСТИРОВАНИЯ: %d УСПЕШНО, %d ОШИБОК ===" % [passed, failed])
	return failed == 0