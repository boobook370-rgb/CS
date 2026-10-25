extends Node

const MIX_RATE: int = 22050
var sound_cache: Dictionary = {}

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_prebuild_sounds()
	_load_custom_audio_files()

func _prebuild_sounds() -> void:
	sound_cache["pistol"] = _synth_sound(0.14, 480.0, 90.0, 0.75, true)
	sound_cache["silenced"] = _synth_sound(0.11, 260.0, 80.0, 0.90, false)
	sound_cache["rifle"] = _synth_sound(0.19, 360.0, 65.0, 0.82, true)
	sound_cache["sniper"] = _synth_sound(0.42, 240.0, 40.0, 0.88, true)
	sound_cache["shotgun"] = _synth_sound(0.32, 200.0, 50.0, 0.92, true)
	sound_cache["knife"] = _synth_sound(0.09, 950.0, 320.0, 0.55, false)
	sound_cache["reload"] = _synth_sound(0.22, 620.0, 820.0, 0.35, false)
	sound_cache["step"] = _synth_sound(0.07, 135.0, 75.0, 0.85, false)
	sound_cache["jump"] = _synth_sound(0.11, 180.0, 260.0, 0.50, false)
	sound_cache["hit"] = _synth_sound(0.08, 720.0, 210.0, 0.65, false)
	sound_cache["headshot"] = _synth_sound(0.15, 1300.0, 420.0, 0.55, true)
	sound_cache["explosion"] = _synth_sound(0.85, 110.0, 28.0, 0.96, true)
	sound_cache["flash"] = _synth_sound(0.65, 2400.0, 1950.0, 0.25, false)
	sound_cache["c4_beep"] = _synth_sound(0.09, 1760.0, 1760.0, 0.05, false)
	sound_cache["c4_plant"] = _synth_sound(0.30, 880.0, 1320.0, 0.15, false)
	sound_cache["round_start"] = _synth_sound(0.38, 440.0, 660.0, 0.15, false)
	sound_cache["round_end"] = _synth_sound(0.55, 520.0, 390.0, 0.15, false)
	sound_cache["ui_click"] = _synth_sound(0.04, 1100.0, 900.0, 0.10, false)

func _load_custom_audio_files() -> void:
	# Сканируем все папки с аудио
	_scan_audio_dir("res://assets/audio")
	_scan_audio_dir("res://sound")
	_scan_audio_dir("res://cstrike/sound")

	# 1. Попадания / Ранения
	_bind_group("hit_flesh", ["bhit_flesh-1", "bhit_flesh-2", "bhit_flesh-3"])
	_bind_group("hit_helmet", ["bhit_helmet-1"])
	_bind_group("hit_kevlar", ["bhit_kevlar-1"])
	_bind_group("headshot", ["headshot1", "headshot2", "headshot3"])
	_bind_group("pain", ["pl_pain2", "pl_pain4", "pl_pain5", "pl_pain6", "pl_pain7"])
	_bind_group("fallpain", ["pl_fallpain1", "pl_fallpain2", "pl_fallpain3"])

	# 2. Смерти
	_bind_group("death", ["death6", "die1", "die2", "die3", "pl_die1"])

	# 3. Шаги
	_bind_group("step_default", ["pl_step1", "pl_step2", "pl_step3", "pl_step4"])
	_bind_group("step_dirt", ["pl_dirt1", "pl_dirt2", "pl_dirt3", "pl_dirt4"])
	_bind_group("step_duct", ["pl_duct1", "pl_duct2", "pl_duct3", "pl_duct4"])
	_bind_group("step_grate", ["pl_grate1", "pl_grate2", "pl_grate3", "pl_grate4"])
	_bind_group("step_metal", ["pl_metal1", "pl_metal2", "pl_metal3", "pl_metal4"])
	_bind_group("step_snow", ["pl_snow1", "pl_snow2", "pl_snow3", "pl_snow4", "pl_snow5", "pl_snow6"])
	_bind_group("step_tile", ["pl_tile1", "pl_tile2", "pl_tile3", "pl_tile4", "pl_tile5"])
	_bind_group("step_ladder", ["pl_ladder1", "pl_ladder2", "pl_ladder3", "pl_ladder4"])
	_bind_group("step_wade", ["pl_wade1", "pl_wade2", "pl_wade3", "pl_wade4"])
	_bind_group("step_slosh", ["pl_slosh1", "pl_slosh2", "pl_slosh3", "pl_slosh4"])
	_bind_group("step_swim", ["pl_swim1", "pl_swim2", "pl_swim3", "pl_swim4"])

	# 4. Движение и эффекты
	_bind_group("jump", ["pl_jump1", "pl_jump2"])
	_bind_group("breathe", ["breathe1", "breathe2"])
	_bind_group("spray", ["sprayer"])
	_bind_group("shell", ["pl_shell1"])

	# 5. Бомба (C4)
	_bind_if_exists("c4_plant", ["bombpl"])
	_bind_if_exists("c4_defuse", ["bombdef"])
	_bind_if_exists("c4_blow", ["blow"])

	# 6. Итоги раундов
	_bind_if_exists("round_ctwin", ["ctwin"])
	_bind_if_exists("round_terwin", ["terwin"])
	_bind_if_exists("round_draw", ["rounddraw"])

	# 7. Радиокоманды
	_bind_if_exists("radio_affirm", ["ct_affirm", "roger"])
	_bind_if_exists("radio_negative", ["negative"])
	_bind_if_exists("radio_backup", ["ct_backup"])
	_bind_if_exists("radio_coverme", ["ct_coverme"])
	_bind_if_exists("radio_enemyspot", ["ct_enemys"])
	_bind_if_exists("radio_enemydown", ["enemydown"])
	_bind_if_exists("radio_fireinhole", ["ct_fireinhole"])
	_bind_if_exists("radio_imhit", ["ct_imhit"])
	_bind_if_exists("radio_inpos", ["ct_inpos", "com_getinpos", "position"])
	_bind_if_exists("radio_reportingin", ["ct_reportingin", "com_reportin"])
	_bind_if_exists("radio_takepoint", ["ct_point", "takepoint"])
	_bind_if_exists("radio_followme", ["followme", "com_followcom"])
	_bind_if_exists("radio_go", ["go", "com_go", "letsgo"])
	_bind_if_exists("radio_regroup", ["regroup", "sticktog"])
	_bind_if_exists("radio_fallback", ["fallback"])
	_bind_if_exists("radio_stormfront", ["stormfront"])
	_bind_if_exists("radio_clear", ["clear"])
	_bind_if_exists("radio_locknload", ["locknload"])
	_bind_if_exists("radio_moveout", ["moveout"])
	_bind_if_exists("radio_vip", ["vip"])

	# 8. Заложники
	_bind_group("hostage_talk", ["hos1", "hos2", "hos3", "hos4", "hos5"])
	_bind_if_exists("hostage_down", ["hosdown"])
	_bind_if_exists("hostage_rescued", ["rescued"])
	
func _scan_audio_dir(folder_path: String) -> void:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if dir.current_is_dir():
			if not fname.begins_with("."):
				_scan_audio_dir(folder_path + "/" + fname)
		else:
			var clean_file := fname
			if clean_file.ends_with(".import"):
				clean_file = clean_file.trim_suffix(".import")
			var lower := clean_file.to_lower()
			if lower.ends_with(".wav") or lower.ends_with(".mp3") or lower.ends_with(".ogg"):
				var key := lower.get_basename()
				if not sound_cache.has(key):
					var full_path := folder_path + "/" + clean_file
					var stream: AudioStream = _load_audio_stream_safe(full_path)
					if stream != null:
						sound_cache[key] = stream
		fname = dir.get_next()

func _bind_if_exists(target_key: String, candidate_keys: Array) -> void:
	for cand in candidate_keys:
		var k := str(cand).to_lower()
		if sound_cache.has(k):
			sound_cache[target_key] = sound_cache[k]
			return

func _bind_group(group_prefix: String, members: Array) -> void:
	var list: Array[AudioStream] = []
	for m in members:
		var k := str(m).to_lower()
		if sound_cache.has(k):
			list.append(sound_cache[k])
	if not list.is_empty():
		sound_cache[group_prefix + "_group"] = list

func play_group(group_prefix: String, volume_scale: float = 1.0) -> void:
	var key := group_prefix + "_group"
	if sound_cache.has(key):
		var list: Array = sound_cache[key]
		if not list.is_empty():
			var stream: AudioStream = list[randi() % list.size()]
			_play_stream(stream, volume_scale)
			return
	play_2d(group_prefix, volume_scale)

func _play_stream(stream: AudioStream, volume_scale: float) -> void:
	if stream == null or DisplayServer.get_name() == "headless":
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	var base_vol: float = SettingsManager.sfx_volume if SettingsManager.sfx_volume > 0.05 else 0.9
	p.volume_db = linear_to_db(clampf(base_vol * volume_scale, 0.01, 1.0))
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _load_audio_stream_safe(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res
	if path.to_lower().ends_with(".wav") and FileAccess.file_exists(path):
		return _load_wav_direct(path)
	return null

func _load_wav_direct(path: String) -> AudioStreamWAV:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() < 44:
		return null
	var riff := f.get_buffer(4).get_string_from_ascii()
	f.get_32()
	var wave := f.get_buffer(4).get_string_from_ascii()
	if riff != "RIFF" or wave != "WAVE":
		return null

	var channels: int = 1
	var sample_rate: int = 22050
	var bits_per_sample: int = 16
	var pcm_data := PackedByteArray()

	while f.get_position() + 8 <= f.get_length():
		var chunk_id := f.get_buffer(4).get_string_from_ascii()
		var chunk_size: int = f.get_32()
		var next_pos: int = f.get_position() + chunk_size
		if chunk_id == "fmt ":
			f.get_16()
			channels = f.get_16()
			sample_rate = f.get_32()
			f.get_32()
			f.get_16()
			bits_per_sample = f.get_16()
		elif chunk_id == "data":
			var read_len: int = mini(chunk_size, f.get_length() - f.get_position())
			pcm_data = f.get_buffer(read_len)
			break
		f.seek(next_pos + (chunk_size % 2))

	if pcm_data.is_empty():
		return null

	var stream := AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.stereo = (channels >= 2)
	if bits_per_sample == 8:
		for i in range(pcm_data.size()):
			pcm_data[i] = (int(pcm_data[i]) - 128) & 0xFF
		stream.format = AudioStreamWAV.FORMAT_8_BITS
	else:
		stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = pcm_data
	return stream

func _synth_sound(duration: float, freq_start: float, freq_end: float, noise_mix: float, punch: bool) -> AudioStreamWAV:
	var samples: int = int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(freq_start * 100.0 + duration * 1000.0)

	for i in range(samples):
		var t: float = float(i) / float(samples)
		var env: float = pow(1.0 - t, 1.8 if punch else 1.2)
		var freq: float = lerpf(freq_start, freq_end, t)
		phase += (freq * TAU) / float(MIX_RATE)
		var tone: float = sin(phase)
		var noise: float = rng.randf_range(-1.0, 1.0)
		var val: float = lerpf(tone, noise, noise_mix) * env
		if punch and t < 0.08:
			val = clampf(val * 1.6, -1.0, 1.0)
		var pcm: int = clampi(int(val * 28000.0), -32767, 32767)
		data.encode_s16(i * 2, pcm)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

func play_2d(sound_name: String, volume_scale: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var key := sound_name.to_lower()
	if sound_cache.has(key):
		var res = sound_cache[key]
		if res is AudioStream:
			_play_stream(res, volume_scale)
			return
		elif res is Array and not res.is_empty():
			_play_stream(res[randi() % res.size()], volume_scale)
			return

func play_3d(sound_name: String, _world_pos: Vector3, _max_dist: float = 65.0) -> void:
	play_2d(sound_name, 0.95)
