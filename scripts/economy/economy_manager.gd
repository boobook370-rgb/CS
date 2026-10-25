extends Node

const START_MONEY: int = 800
const MAX_MONEY: int = 16000
const WIN_ELIMINATION_REWARD: int = 3250
const WIN_BOMB_REWARD: int = 3500
const PLANT_TEAM_BONUS: int = 800
const PLANT_PLANTER_BONUS: int = 300
const DEFUSE_PLANTER_BONUS: int = 300

const LOSS_STREAK_REWARDS := [1400, 1900, 2400, 2900, 3400]

const PRICE_KEVLAR: int = 650
const PRICE_KEVLAR_HELMET: int = 1000
const PRICE_HELMET_UPGRADE: int = 350
const PRICE_DEFUSE_KIT: int = 200

var loss_streak_ct: int = 0
var loss_streak_t: int = 0

func reset_economy() -> void:
	loss_streak_ct = 0
	loss_streak_t = 0

func clamp_money(amount: int) -> int:
	return clampi(amount, 0, MAX_MONEY)

func award_round_end(winner_team: String, bomb_planted: bool, actors: Array) -> void:
	var ct_reward: int = 0
	var t_reward: int = 0

	if winner_team == "CT":
		loss_streak_ct = 0
		var idx := clampi(loss_streak_t, 0, LOSS_STREAK_REWARDS.size() - 1)
		t_reward = LOSS_STREAK_REWARDS[idx]
		if bomb_planted:
			t_reward += PLANT_TEAM_BONUS
		loss_streak_t += 1
		ct_reward = WIN_BOMB_REWARD if bomb_planted else WIN_ELIMINATION_REWARD
	else:
		loss_streak_t = 0
		var idx := clampi(loss_streak_ct, 0, LOSS_STREAK_REWARDS.size() - 1)
		ct_reward = LOSS_STREAK_REWARDS[idx]
		loss_streak_ct += 1
		t_reward = WIN_BOMB_REWARD if bomb_planted else WIN_ELIMINATION_REWARD

	for actor in actors:
		if not is_instance_valid(actor):
			continue
		if actor.team == "CT":
			actor.money = clamp_money(actor.money + ct_reward)
		else:
			actor.money = clamp_money(actor.money + t_reward)

func try_buy_weapon(actor: Node, weapon_id: String, can_buy_now: bool) -> Dictionary:
	if not can_buy_now:
		return {"ok": false, "reason": "Время покупки истекло или вы вне зоны закупки!"}
	if not WeaponDatabase.weapons.has(weapon_id):
		return {"ok": false, "reason": "Оружие не найдено"}

	var w: Dictionary = WeaponDatabase.get_weapon(weapon_id)
	if w["team"] != "ANY" and w["team"] != actor.team:
		return {"ok": false, "reason": "Оружие недоступно для вашей команды"}
	var price: int = int(w["price"])
	if actor.money < price:
		return {"ok": false, "reason": "Недостаточно средств ($%d нужно)" % price}

	if w["slot"] == 4 and actor.has_grenade(weapon_id):
		return {"ok": false, "reason": "Эта граната уже куплена"}

	actor.money -= price
	actor.equip_purchased_weapon(weapon_id)
	return {"ok": true, "reason": "Куплено: %s" % w["name"]}

func try_buy_equipment(actor: Node, item_id: String, can_buy_now: bool) -> Dictionary:
	if not can_buy_now:
		return {"ok": false, "reason": "Время покупки истекло!"}

	match item_id:
		"kevlar":
			if actor.armor >= 100:
				return {"ok": false, "reason": "Бронежилет уже 100%"}
			if actor.money < PRICE_KEVLAR:
				return {"ok": false, "reason": "Недостаточно средств ($650)"}
			actor.money -= PRICE_KEVLAR
			actor.armor = 100
			return {"ok": true, "reason": "Куплен бронежилет Kevlar"}
		"kevlar_helmet":
			if actor.armor >= 100 and actor.has_helmet:
				return {"ok": false, "reason": "У вас уже есть полный комплект брони и шлем"}
			var cost := PRICE_HELMET_UPGRADE if actor.armor >= 100 else PRICE_KEVLAR_HELMET
			if actor.money < cost:
				return {"ok": false, "reason": "Недостаточно средств ($%d)" % cost}
			actor.money -= cost
			actor.armor = 100
			actor.has_helmet = true
			return {"ok": true, "reason": "Куплен Kevlar + Шлем"}
		"defuse_kit":
			if actor.team != "CT":
				return {"ok": false, "reason": "Комплект сапёра доступен только спецназу (CT)"}
			if actor.has_defuse_kit:
				return {"ok": false, "reason": "Комплект сапёра уже куплен"}
			if actor.money < PRICE_DEFUSE_KIT:
				return {"ok": false, "reason": "Недостаточно средств ($200)"}
			actor.money -= PRICE_DEFUSE_KIT
			actor.has_defuse_kit = true
			return {"ok": true, "reason": "Куплен комплект сапёра (ускоряет разминирование в 2 раза)"}

	return {"ok": false, "reason": "Неизвестное снаряжение"}

func try_buy_ammo(actor: Node, slot: int, can_buy_now: bool) -> Dictionary:
	if not can_buy_now:
		return {"ok": false, "reason": "Время покупки истекло!"}
	var w_id: String = actor.inventory.get(slot, "")
	if w_id == "":
		return {"ok": false, "reason": "Оружие в слоте отсутствует"}
	var w: Dictionary = WeaponDatabase.get_weapon(w_id)
	var max_res: int = int(w["reserve_max"])
	var cur_res: int = int(actor.ammo_reserve.get(w_id, 0))
	if cur_res >= max_res:
		return {"ok": false, "reason": "Боезапас полон"}
	var price: int = int(w["ammo_price"])
	if actor.money < price:
		return {"ok": false, "reason": "Недостаточно средств на патроны"}
	actor.money -= price
	actor.ammo_reserve[w_id] = mini(max_res, cur_res + int(w["mag_size"]))
	return {"ok": true, "reason": "Патроны пополнены"}