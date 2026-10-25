extends Node

var weapons: Dictionary = {
	"glock": {
		"id": "glock", "name": "9x19mm Sidearm (Glock-18)", "short_name": "Glock-18",
		"slot": 2, "category": "pistol", "buy_cat": 1, "team": "ANY",
		"price": 400, "ammo_price": 20, "kill_reward": 300,
		"damage": 25.0, "armor_pen": 0.65, "fire_rate": 0.14, "reload_time": 2.2,
		"mag_size": 20, "reserve_max": 120, "move_speed": 250.0, "recoil": 0.018, "spread": 0.014,
		"range": 140.0, "auto": false, "alt_mode": "burst", "length": 0.34,
		"country": "Austria", "caliber": "9mm Parabellum", "rpm": "400 RPM",
		"weight": "0.9 kg", "proj_weight": "8.0 grams", "muzzle_vel": "345.0 m/s", "muzzle_energy": "475 joules"
	},
	"usp": {
		"id": "usp", "name": "K&M .45 Tactical (USP)", "short_name": "USP Tactical",
		"slot": 2, "category": "pistol", "buy_cat": 1, "team": "ANY",
		"price": 500, "ammo_price": 25, "kill_reward": 300,
		"damage": 30.0, "armor_pen": 0.68, "fire_rate": 0.15, "reload_time": 2.5,
		"mag_size": 12, "reserve_max": 100, "move_speed": 250.0, "recoil": 0.022, "spread": 0.011,
		"range": 150.0, "auto": false, "alt_mode": "silencer", "length": 0.42,
		"country": "Germany", "caliber": ".45 ACP", "rpm": "400 RPM",
		"weight": "1.0 kg", "proj_weight": "15.2 grams", "muzzle_vel": "270.0 m/s", "muzzle_energy": "553 joules"
	},
	"p228": {
		"id": "p228", "name": "228 Compact (P228)", "short_name": "228 Compact",
		"slot": 2, "category": "pistol", "buy_cat": 1, "team": "ANY",
		"price": 600, "ammo_price": 50, "kill_reward": 300,
		"damage": 32.0, "armor_pen": 0.80, "fire_rate": 0.15, "reload_time": 2.6,
		"mag_size": 13, "reserve_max": 52, "move_speed": 250.0, "recoil": 0.024, "spread": 0.013,
		"range": 150.0, "auto": false, "alt_mode": "none", "length": 0.35,
		"country": "Switzerland / Germany", "caliber": ".357 SIG", "rpm": "400 RPM",
		"weight": "1.03 kg", "proj_weight": "8.1 grams", "muzzle_vel": "426.0 m/s", "muzzle_energy": "735 joules"
	},
	"deagle": {
		"id": "deagle", "name": "Night Hawk .50C (Deagle)", "short_name": "Desert Eagle",
		"slot": 2, "category": "pistol", "buy_cat": 1, "team": "ANY",
		"price": 650, "ammo_price": 40, "kill_reward": 300,
		"damage": 54.0, "armor_pen": 0.93, "fire_rate": 0.26, "reload_time": 2.2,
		"mag_size": 7, "reserve_max": 35, "move_speed": 250.0, "recoil": 0.055, "spread": 0.012,
		"range": 180.0, "auto": false, "alt_mode": "none", "length": 0.44,
		"country": "Israel", "caliber": ".50 Action Express", "rpm": "267 RPM",
		"weight": "1.8 kg", "proj_weight": "19.4 grams", "muzzle_vel": "420.0 m/s", "muzzle_energy": "1650 joules"
	},
	"fiveseven": {
		"id": "fiveseven", "name": "ES Five-Seven", "short_name": "Five-Seven",
		"slot": 2, "category": "pistol", "buy_cat": 1, "team": "CT",
		"price": 750, "ammo_price": 50, "kill_reward": 300,
		"damage": 28.0, "armor_pen": 0.91, "fire_rate": 0.14, "reload_time": 2.8,
		"mag_size": 20, "reserve_max": 100, "move_speed": 250.0, "recoil": 0.020, "spread": 0.011,
		"range": 160.0, "auto": false, "alt_mode": "none", "length": 0.36,
		"country": "Belgium", "caliber": "5.7x28mm", "rpm": "400 RPM",
		"weight": "0.61 kg", "proj_weight": "2.0 grams", "muzzle_vel": "715.0 m/s", "muzzle_energy": "534 joules"
	},
	"elite": {
		"id": "elite", "name": ".40 Dual Elites", "short_name": "Dual Elites",
		"slot": 2, "category": "pistol", "buy_cat": 1, "team": "T",
		"price": 800, "ammo_price": 20, "kill_reward": 300,
		"damage": 32.0, "armor_pen": 0.75, "fire_rate": 0.10, "reload_time": 3.8,
		"mag_size": 30, "reserve_max": 120, "move_speed": 250.0, "recoil": 0.025, "spread": 0.016,
		"range": 145.0, "auto": false, "alt_mode": "none", "length": 0.42,
		"country": "Italy", "caliber": "9mm Parabellum", "rpm": "750 RPM",
		"weight": "2.3 kg", "proj_weight": "8.0 grams", "muzzle_vel": "390.0 m/s", "muzzle_energy": "606 joules"
	},
	"shotgun": {
		"id": "shotgun", "name": "Leone 12 Gauge Super (M3)", "short_name": "M3 Shotgun",
		"slot": 1, "category": "heavy", "buy_cat": 2, "team": "ANY",
		"price": 1700, "ammo_price": 65, "kill_reward": 900,
		"damage": 22.0, "pellets": 8, "armor_pen": 0.65, "fire_rate": 0.88, "reload_time": 3.0,
		"mag_size": 8, "reserve_max": 32, "move_speed": 220.0, "recoil": 0.065, "spread": 0.048,
		"range": 75.0, "auto": false, "alt_mode": "none", "length": 0.68,
		"country": "Italy", "caliber": "12 Gauge", "rpm": "68 RPM",
		"weight": "3.5 kg", "proj_weight": "3.8 grams", "muzzle_vel": "381.0 m/s", "muzzle_energy": "2429 joules"
	},
	"xm1014": {
		"id": "xm1014", "name": "Leone YG1265 Auto Shotgun", "short_name": "XM1014 Auto",
		"slot": 1, "category": "heavy", "buy_cat": 2, "team": "ANY",
		"price": 3000, "ammo_price": 65, "kill_reward": 900,
		"damage": 18.0, "pellets": 6, "armor_pen": 0.70, "fire_rate": 0.26, "reload_time": 2.8,
		"mag_size": 7, "reserve_max": 32, "move_speed": 240.0, "recoil": 0.045, "spread": 0.045,
		"range": 70.0, "auto": true, "alt_mode": "none", "length": 0.68,
		"country": "Italy", "caliber": "12 Gauge", "rpm": "240 RPM",
		"weight": "4.0 kg", "proj_weight": "3.8 grams", "muzzle_vel": "381.0 m/s", "muzzle_energy": "2429 joules"
	},
	"mac10": {
		"id": "mac10", "name": "Ingram MAC-10", "short_name": "MAC-10",
		"slot": 1, "category": "smg", "buy_cat": 3, "team": "T",
		"price": 1400, "ammo_price": 25, "kill_reward": 600,
		"damage": 29.0, "armor_pen": 0.58, "fire_rate": 0.075, "reload_time": 3.1,
		"mag_size": 30, "reserve_max": 100, "move_speed": 250.0, "recoil": 0.022, "spread": 0.024,
		"range": 120.0, "auto": true, "alt_mode": "none", "length": 0.42,
		"country": "United States of America", "caliber": ".45 ACP", "rpm": "857 RPM",
		"weight": "3.82 kg", "proj_weight": "15.2 grams", "muzzle_vel": "280.0 m/s", "muzzle_energy": "584 joules"
	},
	"tmp": {
		"id": "tmp", "name": "Schmidt Machine Pistol (TMP)", "short_name": "TMP",
		"slot": 1, "category": "smg", "buy_cat": 3, "team": "CT",
		"price": 1250, "ammo_price": 20, "kill_reward": 600,
		"damage": 26.0, "armor_pen": 0.60, "fire_rate": 0.07, "reload_time": 2.1,
		"mag_size": 30, "reserve_max": 120, "move_speed": 250.0, "recoil": 0.018, "spread": 0.020,
		"range": 125.0, "auto": true, "alt_mode": "silenced_builtin", "length": 0.46,
		"country": "Austria", "caliber": "9mm Parabellum", "rpm": "857 RPM",
		"weight": "1.3 kg", "proj_weight": "8.0 grams", "muzzle_vel": "386.0 m/s", "muzzle_energy": "592 joules"
	},
	"mp5": {
		"id": "mp5", "name": "K&M Sub-Machine Gun (MP5)", "short_name": "MP5 Navy",
		"slot": 1, "category": "smg", "buy_cat": 3, "team": "ANY",
		"price": 1500, "ammo_price": 20, "kill_reward": 600,
		"damage": 28.0, "armor_pen": 0.68, "fire_rate": 0.08, "reload_time": 2.6,
		"mag_size": 30, "reserve_max": 120, "move_speed": 250.0, "recoil": 0.019, "spread": 0.015,
		"range": 150.0, "auto": true, "alt_mode": "none", "length": 0.54,
		"country": "Germany", "caliber": "9mm Parabellum", "rpm": "800 RPM",
		"weight": "3.42 kg", "proj_weight": "8.0 grams", "muzzle_vel": "345.0 m/s", "muzzle_energy": "637 joules"
	},
	"ump45": {
		"id": "ump45", "name": "K&M UMP45", "short_name": "UMP-45",
		"slot": 1, "category": "smg", "buy_cat": 3, "team": "ANY",
		"price": 1700, "ammo_price": 25, "kill_reward": 600,
		"damage": 32.0, "armor_pen": 0.72, "fire_rate": 0.10, "reload_time": 3.4,
		"mag_size": 25, "reserve_max": 100, "move_speed": 250.0, "recoil": 0.022, "spread": 0.016,
		"range": 155.0, "auto": true, "alt_mode": "none", "length": 0.55,
		"country": "Germany", "caliber": ".45 ACP", "rpm": "600 RPM",
		"weight": "2.27 kg", "proj_weight": "15.2 grams", "muzzle_vel": "306.0 m/s", "muzzle_energy": "625 joules"
	},
	"p90": {
		"id": "p90", "name": "ES C90 (P90)", "short_name": "ES P90",
		"slot": 1, "category": "smg", "buy_cat": 3, "team": "ANY",
		"price": 2350, "ammo_price": 50, "kill_reward": 300,
		"damage": 26.0, "armor_pen": 0.85, "fire_rate": 0.068, "reload_time": 3.3,
		"mag_size": 50, "reserve_max": 100, "move_speed": 245.0, "recoil": 0.018, "spread": 0.017,
		"range": 160.0, "auto": true, "alt_mode": "none", "length": 0.52,
		"country": "Belgium", "caliber": "5.7x28mm", "rpm": "900 RPM",
		"weight": "3.0 kg", "proj_weight": "2.0 grams", "muzzle_vel": "715.0 m/s", "muzzle_energy": "534 joules"
	},
	"galil": {
		"id": "galil", "name": "IDF Defender (Galil ARM)", "short_name": "Galil ARM",
		"slot": 1, "category": "rifle", "buy_cat": 4, "team": "T",
		"price": 2000, "ammo_price": 60, "kill_reward": 300,
		"damage": 30.0, "armor_pen": 0.77, "fire_rate": 0.09, "reload_time": 2.9,
		"mag_size": 35, "reserve_max": 90, "move_speed": 240.0, "recoil": 0.025, "spread": 0.015,
		"range": 220.0, "auto": true, "alt_mode": "none", "length": 0.64,
		"country": "Israel", "caliber": "5.56x45mm NATO", "rpm": "675 RPM",
		"weight": "4.35 kg", "proj_weight": "4.0 grams", "muzzle_vel": "915.0 m/s", "muzzle_energy": "1712 joules"
	},
	"famas": {
		"id": "famas", "name": "Clarion 5.56 (FAMAS)", "short_name": "FAMAS 5.56",
		"slot": 1, "category": "rifle", "buy_cat": 4, "team": "CT",
		"price": 2250, "ammo_price": 60, "kill_reward": 300,
		"damage": 30.0, "armor_pen": 0.75, "fire_rate": 0.088, "reload_time": 3.2,
		"mag_size": 25, "reserve_max": 90, "move_speed": 240.0, "recoil": 0.023, "spread": 0.013,
		"range": 220.0, "auto": true, "alt_mode": "burst", "length": 0.62,
		"country": "France", "caliber": "5.56x45mm NATO", "rpm": "800 RPM",
		"weight": "3.4 kg", "proj_weight": "4.0 grams", "muzzle_vel": "960.0 m/s", "muzzle_energy": "1712 joules"
	},
	"ak47": {
		"id": "ak47", "name": "CV-47 (AK-47 Type II)", "short_name": "AK-47",
		"slot": 1, "category": "rifle", "buy_cat": 4, "team": "T",
		"price": 2500, "ammo_price": 80, "kill_reward": 300,
		"damage": 36.0, "armor_pen": 0.85, "fire_rate": 0.098, "reload_time": 2.45,
		"mag_size": 30, "reserve_max": 90, "move_speed": 221.0, "recoil": 0.032, "spread": 0.014,
		"range": 260.0, "auto": true, "alt_mode": "none", "length": 0.68,
		"country": "Russian Federation", "caliber": "7.62x39mm", "rpm": "600 RPM",
		"weight": "4.7 kg", "proj_weight": "7.9 grams", "muzzle_vel": "709.8 m/s", "muzzle_energy": "1992 joules"
	},
	"m4a1": {
		"id": "m4a1", "name": "Maverick M4A1 Carbine", "short_name": "M4A1 Carbine",
		"slot": 1, "category": "rifle", "buy_cat": 4, "team": "CT",
		"price": 3100, "ammo_price": 60, "kill_reward": 300,
		"damage": 33.0, "armor_pen": 0.80, "fire_rate": 0.088, "reload_time": 3.05,
		"mag_size": 30, "reserve_max": 90, "move_speed": 230.0, "recoil": 0.025, "spread": 0.011,
		"range": 260.0, "auto": true, "alt_mode": "silencer", "length": 0.68,
		"country": "United States of America", "caliber": "5.56x45mm NATO", "rpm": "685 RPM",
		"weight": "3.22 kg", "proj_weight": "4.0 grams", "muzzle_vel": "884.0 m/s", "muzzle_energy": "1570 joules"
	},
	"scout": {
		"id": "scout", "name": "Schmidt Scout", "short_name": "Schmidt Scout",
		"slot": 1, "category": "sniper", "buy_cat": 4, "team": "ANY",
		"price": 2750, "ammo_price": 80, "kill_reward": 300,
		"damage": 75.0, "armor_pen": 0.88, "fire_rate": 1.25, "reload_time": 2.9,
		"mag_size": 10, "reserve_max": 90, "move_speed": 260.0, "recoil": 0.045, "spread": 0.004,
		"range": 350.0, "auto": false, "alt_mode": "scope_2", "length": 0.74,
		"country": "Austria", "caliber": "7.62x51mm NATO", "rpm": "48 RPM",
		"weight": "3.3 kg", "proj_weight": "8.0 grams", "muzzle_vel": "853.0 m/s", "muzzle_energy": "2200 joules"
	},
	"sg552": {
		"id": "sg552", "name": "Krieg 552 Commando (SG 552)", "short_name": "SG 552",
		"slot": 1, "category": "rifle", "buy_cat": 4, "team": "T",
		"price": 3500, "ammo_price": 60, "kill_reward": 300,
		"damage": 33.0, "armor_pen": 0.82, "fire_rate": 0.088, "reload_time": 2.8,
		"mag_size": 30, "reserve_max": 90, "move_speed": 235.0, "recoil": 0.026, "spread": 0.011,
		"range": 270.0, "auto": true, "alt_mode": "scope_1", "length": 0.65,
		"country": "Switzerland", "caliber": "5.56x45mm NATO", "rpm": "700 RPM",
		"weight": "3.1 kg", "proj_weight": "4.0 grams", "muzzle_vel": "884.0 m/s", "muzzle_energy": "1570 joules"
	},
	"aug": {
		"id": "aug", "name": "Bullpup (Steyr AUG)", "short_name": "Steyr AUG",
		"slot": 1, "category": "rifle", "buy_cat": 4, "team": "CT",
		"price": 3500, "ammo_price": 60, "kill_reward": 300,
		"damage": 32.0, "armor_pen": 0.84, "fire_rate": 0.088, "reload_time": 3.3,
		"mag_size": 30, "reserve_max": 90, "move_speed": 240.0, "recoil": 0.024, "spread": 0.010,
		"range": 270.0, "auto": true, "alt_mode": "scope_1", "length": 0.65,
		"country": "Austria", "caliber": "5.56x45mm NATO", "rpm": "727 RPM",
		"weight": "4.09 kg", "proj_weight": "4.0 grams", "muzzle_vel": "884.0 m/s", "muzzle_energy": "1570 joules"
	},
	"awp": {
		"id": "awp", "name": "Magnum Sniper Rifle (AWM)", "short_name": "AWP Magnum",
		"slot": 1, "category": "sniper", "buy_cat": 4, "team": "ANY",
		"price": 4750, "ammo_price": 125, "kill_reward": 300,
		"damage": 115.0, "armor_pen": 0.99, "fire_rate": 1.45, "reload_time": 2.9,
		"mag_size": 10, "reserve_max": 30, "move_speed": 210.0, "recoil": 0.085, "spread": 0.002,
		"range": 420.0, "auto": false, "alt_mode": "scope_2", "length": 0.85,
		"country": "United Kingdom", "caliber": ".338 Lapua Magnum", "rpm": "41 RPM",
		"weight": "6.0 kg", "proj_weight": "16.2 grams", "muzzle_vel": "914.0 m/s", "muzzle_energy": "7000 joules"
	},
	"g3sg1": {
		"id": "g3sg1", "name": "D3/AU-1 (G3SG/1)", "short_name": "G3SG/1",
		"slot": 1, "category": "sniper", "buy_cat": 4, "team": "T",
		"price": 5000, "ammo_price": 80, "kill_reward": 300,
		"damage": 80.0, "armor_pen": 0.88, "fire_rate": 0.25, "reload_time": 3.5,
		"mag_size": 20, "reserve_max": 90, "move_speed": 210.0, "recoil": 0.042, "spread": 0.005,
		"range": 380.0, "auto": true, "alt_mode": "scope_2", "length": 0.80,
		"country": "Germany", "caliber": "7.62x51mm NATO", "rpm": "240 RPM",
		"weight": "4.41 kg", "proj_weight": "8.0 grams", "muzzle_vel": "853.0 m/s", "muzzle_energy": "2200 joules"
	},
	"sg550": {
		"id": "sg550", "name": "Krieg 550 Commando (SG 550)", "short_name": "SG 550",
		"slot": 1, "category": "sniper", "buy_cat": 4, "team": "CT",
		"price": 4200, "ammo_price": 60, "kill_reward": 300,
		"damage": 70.0, "armor_pen": 0.86, "fire_rate": 0.25, "reload_time": 3.4,
		"mag_size": 30, "reserve_max": 90, "move_speed": 210.0, "recoil": 0.038, "spread": 0.005,
		"range": 380.0, "auto": true, "alt_mode": "scope_2", "length": 0.78,
		"country": "Switzerland", "caliber": "5.56x45mm NATO", "rpm": "240 RPM",
		"weight": "7.02 kg", "proj_weight": "4.0 grams", "muzzle_vel": "945.0 m/s", "muzzle_energy": "1650 joules"
	},
	"m249": {
		"id": "m249", "name": "ES M249 Para", "short_name": "M249 Para",
		"slot": 1, "category": "heavy", "buy_cat": 5, "team": "ANY",
		"price": 5750, "ammo_price": 60,
		"mag_size": 100, "reserve_max": 200, "damage": 32.0, "fire_rate": 0.10,
		"spread": 0.022, "recoil": 0.038, "move_speed": 220.0, "armor_pen": 0.80,
		"kill_reward": 300, "reload_time": 4.6, "auto": true, "length": 0.85
	},
}		
