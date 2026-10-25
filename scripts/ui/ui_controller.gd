class_name UIController
extends Control

var main_menu_root: Control
var pause_panel: Control
var shop_panel: Control
var hud_panel: Control
var notifications_container: VBoxContainer
var killfeed_container: VBoxContainer

var music_player: AudioStreamPlayer
var catalog_item_list: ItemList
var mode_option: OptionButton
var team_option: OptionButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui_layout()
	_setup_background_music()
	show_main_menu(true)

func _setup_background_music() -> void:
	if music_player != null and is_instance_valid(music_player):
		music_player.queue_free()

	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	var found_stream: AudioStream = null
	var candidates := [
		"res://assets/audio/cstrike_menu_theme.ogg",
		"res://assets/audio/cstrike_menu_theme.mp3",
		"res://assets/audio/menu.mp3",
		"res://assets/audio/cstrike.wav"
	]
	
	for path in candidates:
		if FileAccess.file_exists(path) or ResourceLoader.exists(path):
			found_stream = load(path)
			print(">>> [МУЗЫКА] Загружен файл: ", path)
			break
			
	# Если файла на диске нет, создаем приятную эмбиент-мелодию программно
	if found_stream == null:
		found_stream = _synth_menu_melody()
		print(">>> [МУЗЫКА] Аудиофайл не найден, включена встроенная мелодия меню.")

	music_player.stream = found_stream
	music_player.volume_db = -3.0  # Громкость (в децибелах)
	music_player.autoplay = true
	music_player.finished.connect(func(): music_player.play())
	music_player.play()

# Программный синтезатор расслабляющей мелодии меню
func _synth_menu_melody() -> AudioStreamWAV:
	var mix_rate: int = 22050
	var duration: float = 4.0  # Длительность петли в секундах
	var samples: int = int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)

	# Ноты аккорда меню (частоты в Гц)
	var notes := [220.0, 261.63, 329.63, 392.0, 523.25] 
	
	for i in range(samples):
		var t: float = float(i) / float(mix_rate)
		var val: float = 0.0
		for n_idx in range(notes.size()):
			var freq: float = notes[n_idx]
			var envelope: float = sin(t * PI * (n_idx + 1) / duration) * 0.15
			val += sin(t * TAU * freq) * envelope
			
		var pcm: int = clampi(int(val * 16000.0), -32767, 32767)
		data.encode_s16(i * 2, pcm)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	stream.data = data
	return stream
	
func _setup_ui_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# --- 1. ГЛАВНОЕ МЕНЮ ---
	main_menu_root = Control.new()
	main_menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_menu_root)

	# Фоновое изображение
	# Фоновое изображение
# Фоновое изображение (с защитой от сбоев импорта)
	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	# Безопасная загрузка текстуры через Image (обходит любые ошибки импорта движка)
	var img_path := "res://assets/ui/cs_bg.png"
	if FileAccess.file_exists(img_path):
		var img := Image.new()
		if img.load(img_path) == OK:
			bg_tex.texture = ImageTexture.create_from_image(img)
		else:
			# Если файл поврежден, заливаем красивый темно-синий фон CS 1.6
			var fallback_img := Image.create(1280, 720, false, Image.FORMAT_RGB8)
			fallback_img.fill(Color(0.04, 0.10, 0.18))
			bg_tex.texture = ImageTexture.create_from_image(fallback_img)
	else:
		var fallback_img := Image.create(1280, 720, false, Image.FORMAT_RGB8)
		fallback_img.fill(Color(0.04, 0.10, 0.18))
		bg_tex.texture = ImageTexture.create_from_image(fallback_img)
		
	main_menu_root.add_child(bg_tex)

	# Затемнение слева для читаемости кнопок
	var left_shadow := ColorRect.new()
	left_shadow.offset_left = 0
	left_shadow.offset_top = 0
	left_shadow.offset_right = 380
	left_shadow.offset_bottom = 720
	left_shadow.color = Color(0.02, 0.04, 0.08, 0.78)
	main_menu_root.add_child(left_shadow)

	# Меню настроек матча (Слева)
	var menu_panel := PanelContainer.new()
	menu_panel.offset_left = 35
	menu_panel.offset_top = 45
	menu_panel.offset_right = 345
	menu_panel.offset_bottom = 540
	main_menu_root.add_child(menu_panel)

	var m_vbox := VBoxContainer.new()
	m_vbox.add_theme_constant_override("separation", 10)
	menu_panel.add_child(m_vbox)

	var title := Label.new()
	title.text = "1.6 alibaba"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.15))
	m_vbox.add_child(title)

	var lbl_map := Label.new()
	lbl_map.text = "Карта (.bsp):"
	m_vbox.add_child(lbl_map)

	catalog_item_list = ItemList.new()
	catalog_item_list.custom_minimum_size = Vector2(0, 130)
	for m in MapBuilder.get_map_catalog():
		catalog_item_list.add_item(m["name"])
	catalog_item_list.select(0)
	m_vbox.add_child(catalog_item_list)

	var lbl_mode := Label.new()
	lbl_mode.text = "Режим игры:"
	m_vbox.add_child(lbl_mode)

	mode_option = OptionButton.new()
	mode_option.add_item("Обезвреживание бомбы (Bomb)", 0)
	mode_option.add_item("Командный бой (TDM)", 1)
	mode_option.add_item("Тренировочный полигон", 2)
	mode_option.select(0)
	m_vbox.add_child(mode_option)

	var lbl_team := Label.new()
	lbl_team.text = "Команда:"
	m_vbox.add_child(lbl_team)

	team_option = OptionButton.new()
	team_option.add_item("Спецназ (CT)", 0)
	team_option.add_item("Террористы (T)", 1)
	team_option.select(0)
	m_vbox.add_child(team_option)

	var btn_start := Button.new()
	btn_start.text = "НАЧАТЬ ИГРУ"
	btn_start.custom_minimum_size = Vector2(0, 38)
	btn_start.pressed.connect(_on_start_game_pressed)
	m_vbox.add_child(btn_start)

	var btn_quit := Button.new()
	btn_quit.text = "ВЫХОД ИЗ ИГРЫ"
	btn_quit.pressed.connect(func(): get_tree().quit())
	m_vbox.add_child(btn_quit)

	# --- 2. ИГРОВОЙ HUD ---
	hud_panel = Control.new()
	hud_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_panel)

	# --- 3. ПАУЗА ---
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -160
	pause_panel.offset_right = 160
	pause_panel.offset_top = -100
	pause_panel.offset_bottom = 100
	pause_panel.visible = false
	add_child(pause_panel)

	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 15)
	pause_panel.add_child(p_vbox)

	var p_title := Label.new()
	p_title.text = "ПАУЗА"
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_vbox.add_child(p_title)

	var btn_resume := Button.new()
	btn_resume.text = "Продолжить"
	btn_resume.pressed.connect(func(): GameManager.toggle_pause(false))
	p_vbox.add_child(btn_resume)

	var btn_menu := Button.new()
	btn_menu.text = "Главное меню"
	btn_menu.pressed.connect(func(): GameManager.return_to_main_menu())
	p_vbox.add_child(btn_menu)

	# --- 4. МАГАЗИН ---
	shop_panel = PanelContainer.new()
	shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	shop_panel.offset_left = -280
	shop_panel.offset_right = 280
	shop_panel.offset_top = -220
	shop_panel.offset_bottom = 220
	shop_panel.visible = false
	add_child(shop_panel)

	var s_vbox := VBoxContainer.new()
	shop_panel.add_child(s_vbox)
	var s_title := Label.new()
	s_title.text = "ОРУЖЕЙНЫЙ МАГАЗИН (B)"
	s_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s_vbox.add_child(s_title)

	var s_close := Button.new()
	s_close.text = "Закрыть"
	s_close.pressed.connect(func(): GameManager.toggle_shop(false))
	s_vbox.add_child(s_close)

	notifications_container = VBoxContainer.new()
	notifications_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notifications_container.offset_right = -20
	notifications_container.offset_top = 20
	add_child(notifications_container)

	killfeed_container = VBoxContainer.new()
	killfeed_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	killfeed_container.offset_right = -20
	killfeed_container.offset_top = 80
	add_child(killfeed_container)

func show_main_menu(show: bool) -> void:
	main_menu_root.visible = show
	hud_panel.visible = not show
	if show and music_player and not music_player.playing:
		music_player.play()
	elif not show and music_player:
		music_player.stop()

func toggle_shop(open: bool) -> void:
	shop_panel.visible = open

func notify(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	notifications_container.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)

func add_killfeed_entry(killer: String, victim: String, weapon: String, hs: bool) -> void:
	var lbl := Label.new()
	lbl.text = killer + " [" + weapon + (" HS" if hs else "") + "] " + victim
	killfeed_container.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)

func _on_start_game_pressed() -> void:
	var catalog := MapBuilder.get_map_catalog()
	var sel_idx := 0
	var items := catalog_item_list.get_selected_items()
	if items.size() > 0:
		sel_idx = items[0]
	if sel_idx < catalog.size():
		GameManager.selected_map_id = catalog[sel_idx]["id"]

	match mode_option.selected:
		0: GameManager.selected_mode = "bomb"
		1: GameManager.selected_mode = "tdm"
		2: GameManager.selected_mode = "training"

	GameManager.player_team = "CT" if team_option.selected == 0 else "T"
	GameManager.start_match()
