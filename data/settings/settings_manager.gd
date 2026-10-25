extends Node

const SAVE_PATH := "user://settings.cfg"

var mouse_sensitivity: float = 0.0022
var fov: float = 78.0
var master_volume: float = 0.85
var sfx_volume: float = 0.90
var music_volume: float = 0.50
var ui_volume: float = 0.80
var fullscreen: bool = false
var resolution_index: int = 1
var bot_difficulty: int = 1 # 0 = Easy, 1 = Medium, 2 = Hard
var bot_count_per_team: int = 4

const RESOLUTIONS := [
	Vector2i(1024, 768),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

var default_keybinds := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"crouch": KEY_CTRL,
	"walk": KEY_SHIFT,
	"reload": KEY_R,
	"interact": KEY_E,
	"buy_menu": KEY_B,
	"buy_ammo_primary": KEY_COMMA,
	"buy_ammo_secondary": KEY_PERIOD,
	"slot_1": KEY_1,
	"slot_2": KEY_2,
	"slot_3": KEY_3,
	"slot_4": KEY_4,
	"slot_5": KEY_5,
	"scoreboard": KEY_TAB,
	"pause_menu": KEY_ESCAPE
}

var custom_keybinds := {}

func _ready() -> void:
	custom_keybinds = default_keybinds.duplicate()
	_setup_input_map()
	load_settings()
	apply_settings()

func _setup_input_map() -> void:
	for action in custom_keybinds.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = custom_keybinds[action]
		InputMap.action_add_event(action, ev)

	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
	InputMap.action_erase_events("fire")
	var m1 := InputEventMouseButton.new()
	m1.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", m1)

	if not InputMap.has_action("alt_fire"):
		InputMap.add_action("alt_fire")
	InputMap.action_erase_events("alt_fire")
	var m2 := InputEventMouseButton.new()
	m2.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("alt_fire", m2)

func rebind_action(action: String, keycode: Key) -> void:
	if not custom_keybinds.has(action):
		return
	custom_keybinds[action] = keycode
	_setup_input_map()
	save_settings()

func apply_settings() -> void:
	if DisplayServer.get_name() != "headless":
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res: Vector2i = RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]
			DisplayServer.window_set_size(res)
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.001, 1.0)))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("video", "fov", fov)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "ui_volume", ui_volume)
	cfg.set_value("game", "bot_difficulty", bot_difficulty)
	cfg.set_value("game", "bot_count_per_team", bot_count_per_team)
	for k in custom_keybinds.keys():
		cfg.set_value("keys", k, int(custom_keybinds[k]))
	cfg.save(SAVE_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	mouse_sensitivity = float(cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))
	resolution_index = int(cfg.get_value("video", "resolution_index", resolution_index))
	fov = float(cfg.get_value("video", "fov", fov))
	master_volume = float(cfg.get_value("audio", "master_volume", master_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", sfx_volume))
	music_volume = float(cfg.get_value("audio", "music_volume", music_volume))
	ui_volume = float(cfg.get_value("audio", "ui_volume", ui_volume))
	bot_difficulty = int(cfg.get_value("game", "bot_difficulty", bot_difficulty))
	bot_count_per_team = int(cfg.get_value("game", "bot_count_per_team", bot_count_per_team))
	for k in default_keybinds.keys():
		custom_keybinds[k] = int(cfg.get_value("keys", k, default_keybinds[k]))
	_setup_input_map()