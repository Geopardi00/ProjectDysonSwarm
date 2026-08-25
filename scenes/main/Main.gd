@tool
extends Control

const GameDataScript := preload("res://scripts/data/GameData.gd")
const LaunchManagerScript := preload("res://scripts/launch/LaunchManager.gd")
const UiAssetsScript := preload("res://scripts/data/UiAssets.gd")
const StrategyScreenScene := preload("res://scenes/ui/StrategyScreen.tscn")
const OptionsScreenScene := preload("res://scenes/ui/OptionsScreen.tscn")
const PauseMenuScreenScene := preload("res://scenes/ui/PauseMenuScreen.tscn")
const OPENING_GLITCH_SHADER := preload("res://assets/shaders/opening_glitch.gdshader")
const OPENING_GLITCH_SOUND := preload("res://audio/sfx/glitch.wav")
const OPENING_CUTSCENE_PATH := "res://assets/cutscene/0001-0360.ogv"
const CUTSCENE_EXPLOSION_SOUND_PATH := "res://audio/sfx/explosion.wav"
const BUTTON_CLICK_SOUND := preload("res://audio/sfx/button_click.wav")
const BUTTON_HOVER_SOUND := preload("res://audio/sfx/button_hover.wav")
const LAUNCH_FAILURE_PANEL := preload("res://assets/ui/panels/launch_failure_panel.png")
const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SAVE_DELAY := 0.25
const UI_SOUND_CONNECTED_META := &"dyson_ui_sound_connected"
const UI_TWEEN_CONNECTED_META := &"dyson_ui_tween_connected"
const UI_TWEEN_SKIP_META := &"skip_global_button_tween"
const UI_TWEEN_BASE_SCALE_META := &"dyson_ui_tween_base_scale"
const UI_TWEEN_BASE_COLOR_META := &"dyson_ui_tween_base_color"
const UI_TWEEN_ACTIVE_META := &"dyson_ui_active_tween"
const UI_TWEEN_HOVERED_META := &"dyson_ui_tween_hovered"
const UI_TWEEN_DOWN_META := &"dyson_ui_tween_down"
const MUSIC_BUS_NAME := &"Music"
const SFX_BUS_NAME := &"SFX"

const SHOW_DEBUG_ACTIONS := true
const LAUNCH_RESULT_MARGIN_TOP := 112
const LAUNCH_RESULT_BUTTON_WIDTH := 220
const LAUNCH_RESULT_BUTTON_HEIGHT := 44
const LAUNCH_FAILURE_PANEL_SIZE := Vector2(812.0, 781.0)
const LAUNCH_FAILURE_TEXT_SIZE := Vector2(684.0, 230.0)
const GAME_OVER_MARGIN_TOP := 112
const FACTION_SELECT_LOGO_SIZE := Vector2(256, 256)
const FACTION_LOGO_HIGHLIGHT_SCALE := Vector2(1.08, 1.08)
const FACTION_LOGO_NORMAL_SCALE := Vector2.ONE
const FACTION_LOGO_HIGHLIGHT_MODULATE := Color(1.18, 1.08, 0.86, 1.0)
const FACTION_LOGO_NORMAL_MODULATE := Color.WHITE
const FACTION_LOGO_HALO_MODULATE := Color(1.0, 0.72, 0.22, 0.42)
const BACKGROUND_MUSIC_PATHS: Array[String] = [
	"res://audio/music/bg_music1.mp3",
	"res://audio/music/bg_music2.mp3",
	"res://audio/music/bg_music3.mp3",
]

@export_category("Opening Screen Layout")
@export_range(-300.0, 300.0, 1.0, "suffix:px") var opening_vertical_offset := 90.0:
	set(value):
		opening_vertical_offset = value
		_update_editor_opening_preview()
@export_range(0.0, 200.0, 1.0, "suffix:px") var opening_title_button_spacing := 28.0:
	set(value):
		opening_title_button_spacing = value
		_update_editor_opening_preview()
@export_range(200.0, 1800.0, 1.0, "suffix:px") var opening_title_width := 1448.0:
	set(value):
		opening_title_width = value
		_update_editor_opening_preview()
@export_range(50.0, 600.0, 1.0, "suffix:px") var opening_title_height := 333.0:
	set(value):
		opening_title_height = value
		_update_editor_opening_preview()
@export_range(100.0, 600.0, 1.0, "suffix:px") var opening_button_width := 220.0:
	set(value):
		opening_button_width = value
		_update_editor_opening_preview()
@export_range(24.0, 160.0, 1.0, "suffix:px") var opening_button_height := 44.0:
	set(value):
		opening_button_height = value
		_update_editor_opening_preview()
@export_range(0.0, 80.0, 1.0, "suffix:px") var opening_menu_button_spacing := 8.0:
	set(value):
		opening_menu_button_spacing = value
		_update_editor_opening_preview()

@export_category("Opening Cutscene")
@export_range(0.0, 2.0, 0.05, "suffix:s") var opening_glitch_duration := 0.4
@export_range(0.0, 15.0, 0.05, "suffix:s") var cutscene_explosion_time := 2.0

@export_category("Corner Logo Layout")
@export_range(-500.0, 1920.0, 1.0, "suffix:px") var corner_logo_x := 10.0:
	set(value):
		corner_logo_x = value
		_update_corner_logo_layout()
@export_range(-500.0, 1080.0, 1.0, "suffix:px") var corner_logo_y := 7.0:
	set(value):
		corner_logo_y = value
		_update_corner_logo_layout()
@export_range(20.0, 1000.0, 1.0, "suffix:px") var corner_logo_width := 272.0:
	set(value):
		corner_logo_width = value
		_update_corner_logo_layout()
@export_range(10.0, 500.0, 0.5, "suffix:px") var corner_logo_height := 62.5:
	set(value):
		corner_logo_height = value
		_update_corner_logo_layout()

@export_category("UI Sounds")
@export_range(0.0, 100.0, 1.0, "suffix:%") var button_hover_volume_percent := 100.0:
	set(value):
		button_hover_volume_percent = value
		_apply_ui_sound_volumes()
@export_range(0.0, 100.0, 1.0, "suffix:%") var button_click_volume_percent := 100.0:
	set(value):
		button_click_volume_percent = value
		_apply_ui_sound_volumes()
@export_range(0.0, 10.0, 0.1, "suffix:%") var button_hover_pitch_variation_percent := 3.0

@export_category("Launch Failure Layout")
@export_range(-800.0, 800.0, 1.0, "suffix:px") var launch_failure_panel_x := 0.0:
	set(value):
		launch_failure_panel_x = value
		_apply_launch_failure_layout()
@export_range(-500.0, 500.0, 1.0, "suffix:px") var launch_failure_panel_y := 0.0:
	set(value):
		launch_failure_panel_y = value
		_apply_launch_failure_layout()
@export_range(-400.0, 800.0, 1.0, "suffix:px") var launch_failure_text_x := 64.0:
	set(value):
		launch_failure_text_x = value
		_apply_launch_failure_layout()
@export_range(-400.0, 700.0, 1.0, "suffix:px") var launch_failure_text_y := 34.0:
	set(value):
		launch_failure_text_y = value
		_apply_launch_failure_layout()

@export_category("Background Music")
@export_range(0.0, 100.0, 1.0, "suffix:%") var background_music_volume_percent := 100.0:
	set(value):
		background_music_volume_percent = value
		_apply_background_music_volume()

@export_category("Button Tween")
@export_range(1.0, 1.2, 0.01) var button_hover_scale := 1.04
@export_range(0.8, 1.0, 0.01) var button_press_scale := 0.96
@export_range(0.0, 0.5, 0.01, "suffix:s") var button_hover_duration := 0.10
@export_range(0.0, 0.5, 0.01, "suffix:s") var button_press_duration := 0.05
@export_range(0.0, 0.5, 0.01, "suffix:s") var button_release_duration := 0.09
@export_range(1.0, 1.5, 0.01) var button_hover_brightness := 1.08
@export_range(0.5, 1.0, 0.01) var button_press_brightness := 0.88
@export_range(0.0, 0.5, 0.01, "suffix:s") var button_navigation_delay := 0.08

@onready var root_margin: MarginContainer = $RootMargin
@onready var cargo_loading_screen: CargoLoadingScreen = %CargoLoadingScreen

var game_state: GameState
var launch_manager: LaunchManager
var selected_faction := ""
var active_screen: Control
var corner_logo: TextureRect
var last_launch_result: Dictionary = {}
var music_player: AudioStreamPlayer
var background_music_streams: Array[AudioStream] = []
var current_music_index := 0
var opening_glitch_layer: ColorRect
var opening_glitch_player: AudioStreamPlayer
var opening_cutscene_layer: Control
var opening_cutscene_player: VideoStreamPlayer
var cutscene_explosion_player: AudioStreamPlayer
var cutscene_explosion_played := false
var button_click_player: AudioStreamPlayer
var button_hover_player: AudioStreamPlayer
var launch_failure_panel: TextureRect
var launch_failure_text: Control
var launch_failure_continue_button: Button
var settings_file_path := DEFAULT_SETTINGS_PATH
var master_volume_percent := 100.0
var music_bus_volume_percent := 100.0
var sfx_bus_volume_percent := 100.0
var brightness_percent := 100.0
var settings_save_timer: Timer
var brightness_layer: CanvasLayer
var brightness_filter: ColorRect
var settings_loaded := false
var pause_overlay: PauseMenuScreen
var pause_options_screen: OptionsScreen
var button_navigation_pending := false


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_update_editor_opening_preview")
		return
	var editor_preview := get_node_or_null("EditorOpeningPreview") as Control
	if editor_preview != null:
		editor_preview.visible = false
	_create_settings_save_timer()
	_ensure_audio_buses()
	_load_settings()
	_apply_master_volume()
	_apply_music_bus_volume()
	_apply_sfx_bus_volume()
	_setup_ui_sounds()
	_add_scene_background()
	_add_brightness_filter()
	_apply_brightness()
	_add_corner_logo()
	_start_background_music()
	game_state = GameState.new()
	add_child(game_state)

	launch_manager = LaunchManagerScript.new()
	launch_manager.setup(game_state)

	cargo_loading_screen.launch_requested.connect(_on_launch_requested)
	cargo_loading_screen.assignment_cancelled.connect(_on_assignment_cancelled)
	cargo_loading_screen.button_navigation_delay = button_navigation_delay

	_clear_root_margin()
	_show_opening_screen()


func _exit_tree() -> void:
	if not Engine.is_editor_hint() and get_tree() != null and get_tree().node_added.is_connected(_on_tree_node_added_for_ui_sounds):
		get_tree().node_added.disconnect(_on_tree_node_added_for_ui_sounds)
	if not Engine.is_editor_hint() and settings_loaded:
		_save_settings()


func _setup_ui_sounds() -> void:
	button_hover_player = AudioStreamPlayer.new()
	button_hover_player.name = "ButtonHoverPlayer"
	button_hover_player.stream = BUTTON_HOVER_SOUND
	button_hover_player.bus = SFX_BUS_NAME
	button_hover_player.max_polyphony = 4
	add_child(button_hover_player)

	button_click_player = AudioStreamPlayer.new()
	button_click_player.name = "ButtonClickPlayer"
	button_click_player.stream = BUTTON_CLICK_SOUND
	button_click_player.bus = SFX_BUS_NAME
	button_click_player.max_polyphony = 4
	add_child(button_click_player)
	_apply_ui_sound_volumes()

	get_tree().node_added.connect(_on_tree_node_added_for_ui_sounds)
	for node: Node in find_children("*", "Button", true, false):
		_register_button_ui_sounds(node as Button)


func _on_tree_node_added_for_ui_sounds(node: Node) -> void:
	if node is Button:
		_register_button_ui_sounds(node as Button)


func _register_button_ui_sounds(button: Button) -> void:
	if not button.has_meta(UI_SOUND_CONNECTED_META):
		button.set_meta(UI_SOUND_CONNECTED_META, true)
		button.mouse_entered.connect(_on_ui_button_hovered.bind(button))
		button.button_down.connect(_play_button_click_sound)
	_register_button_tween(button)


func _register_button_tween(button: Button) -> void:
	if button.has_meta(UI_TWEEN_CONNECTED_META) or button.has_meta(UI_TWEEN_SKIP_META):
		return
	button.set_meta(UI_TWEEN_CONNECTED_META, true)
	button.set_meta(UI_TWEEN_BASE_SCALE_META, button.scale)
	button.set_meta(UI_TWEEN_BASE_COLOR_META, button.self_modulate)
	button.set_meta(UI_TWEEN_HOVERED_META, false)
	button.set_meta(UI_TWEEN_DOWN_META, false)
	button.resized.connect(_update_ui_button_pivot.bind(button))
	button.mouse_entered.connect(_on_ui_button_tween_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_ui_button_tween_mouse_exited.bind(button))
	button.button_down.connect(_on_ui_button_tween_down.bind(button))
	button.button_up.connect(_on_ui_button_tween_up.bind(button))
	button.visibility_changed.connect(_on_ui_button_tween_visibility_changed.bind(button))
	_update_ui_button_pivot(button)


func _update_ui_button_pivot(button: Button) -> void:
	if not is_instance_valid(button):
		return
	var centered_pivot := button.size * 0.5
	var pivot_delta := centered_pivot - button.pivot_offset
	var base_scale := button.get_meta(UI_TWEEN_BASE_SCALE_META, button.scale) as Vector2
	# Some authored controls already have a non-unit scale. Compensate their
	# layout position so changing the pivot does not move them at rest.
	button.position -= Vector2(
		(1.0 - base_scale.x) * pivot_delta.x,
		(1.0 - base_scale.y) * pivot_delta.y
	)
	button.pivot_offset = centered_pivot


func _on_ui_button_tween_mouse_entered(button: Button) -> void:
	button.set_meta(UI_TWEEN_HOVERED_META, true)
	if not bool(button.get_meta(UI_TWEEN_DOWN_META, false)):
		_animate_ui_button(button, button_hover_scale, button_hover_brightness, button_hover_duration)


func _on_ui_button_tween_mouse_exited(button: Button) -> void:
	button.set_meta(UI_TWEEN_HOVERED_META, false)
	if not bool(button.get_meta(UI_TWEEN_DOWN_META, false)):
		_animate_ui_button(button, 1.0, 1.0, button_hover_duration)


func _on_ui_button_tween_down(button: Button) -> void:
	button.set_meta(UI_TWEEN_DOWN_META, true)
	_animate_ui_button(button, button_press_scale, button_press_brightness, button_press_duration)


func _on_ui_button_tween_up(button: Button) -> void:
	button.set_meta(UI_TWEEN_DOWN_META, false)
	var is_hovered := bool(button.get_meta(UI_TWEEN_HOVERED_META, false)) or button.is_hovered()
	_animate_ui_button(
		button,
		button_hover_scale if is_hovered else 1.0,
		button_hover_brightness if is_hovered else 1.0,
		button_release_duration
	)


func _on_ui_button_tween_visibility_changed(button: Button) -> void:
	if not button.is_visible_in_tree():
		_reset_ui_button_tween(button)


func _animate_ui_button(button: Button, scale_multiplier: float, brightness: float, duration: float) -> void:
	if not _can_animate_ui_button(button):
		_reset_ui_button_tween(button)
		return
	_kill_ui_button_tween(button)
	var base_scale := button.get_meta(UI_TWEEN_BASE_SCALE_META, Vector2.ONE) as Vector2
	var base_color := button.get_meta(UI_TWEEN_BASE_COLOR_META, Color.WHITE) as Color
	var target_color := Color(
		base_color.r * brightness,
		base_color.g * brightness,
		base_color.b * brightness,
		base_color.a
	)
	var tween := button.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", base_scale * scale_multiplier, duration)
	tween.tween_property(button, "self_modulate", target_color, duration)
	button.set_meta(UI_TWEEN_ACTIVE_META, tween)


func _can_animate_ui_button(button: Button) -> bool:
	return (
		is_instance_valid(button)
		and not button.disabled
		and button.is_visible_in_tree()
		and not button.has_meta(UI_TWEEN_SKIP_META)
	)


func _reset_ui_button_tween(button: Button) -> void:
	if not is_instance_valid(button) or not button.has_meta(UI_TWEEN_CONNECTED_META):
		return
	_kill_ui_button_tween(button)
	button.scale = button.get_meta(UI_TWEEN_BASE_SCALE_META, Vector2.ONE) as Vector2
	button.self_modulate = button.get_meta(UI_TWEEN_BASE_COLOR_META, Color.WHITE) as Color
	button.set_meta(UI_TWEEN_HOVERED_META, false)
	button.set_meta(UI_TWEEN_DOWN_META, false)


func _kill_ui_button_tween(button: Button) -> void:
	if not button.has_meta(UI_TWEEN_ACTIVE_META):
		return
	var active_tween = button.get_meta(UI_TWEEN_ACTIVE_META)
	if active_tween is Tween and active_tween.is_valid():
		active_tween.kill()
	button.remove_meta(UI_TWEEN_ACTIVE_META)


func _queue_button_navigation(action: Callable) -> void:
	if button_navigation_pending:
		return
	button_navigation_pending = true
	if button_navigation_delay > 0.0:
		await get_tree().create_timer(button_navigation_delay).timeout
	if is_inside_tree() and action.is_valid():
		action.call()
	button_navigation_pending = false


func _on_ui_button_hovered(button: Button) -> void:
	if button.disabled or not button.is_visible_in_tree() or button_hover_player == null:
		return
	var pitch_variation := button_hover_pitch_variation_percent / 100.0
	button_hover_player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	button_hover_player.play()


func _play_button_click_sound() -> void:
	if button_click_player != null:
		button_click_player.play()


func _apply_ui_sound_volumes() -> void:
	if button_hover_player != null:
		button_hover_player.volume_db = _percent_to_volume_db(button_hover_volume_percent)
	if button_click_player != null:
		button_click_player.volume_db = _percent_to_volume_db(button_click_volume_percent)


func _percent_to_volume_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return linear_to_db(percent / 100.0)


func _create_settings_save_timer() -> void:
	settings_save_timer = Timer.new()
	settings_save_timer.name = "SettingsSaveTimer"
	settings_save_timer.one_shot = true
	settings_save_timer.wait_time = SETTINGS_SAVE_DELAY
	settings_save_timer.timeout.connect(_save_settings)
	add_child(settings_save_timer)


func _ensure_audio_buses() -> void:
	_ensure_audio_bus(MUSIC_BUS_NAME)
	_ensure_audio_bus(SFX_BUS_NAME)


func _ensure_audio_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, &"Master")


func _load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(settings_file_path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Could not load settings from %s (error %d)." % [settings_file_path, error])
	master_volume_percent = clampf(float(config.get_value("audio", "master_volume_percent", 100.0)), 0.0, 100.0)
	music_bus_volume_percent = clampf(float(config.get_value("audio", "music_volume_percent", 100.0)), 0.0, 100.0)
	sfx_bus_volume_percent = clampf(float(config.get_value("audio", "sfx_volume_percent", 100.0)), 0.0, 100.0)
	brightness_percent = clampf(float(config.get_value("display", "brightness_percent", 100.0)), 50.0, 150.0)
	settings_loaded = true


func _queue_settings_save() -> void:
	if settings_save_timer != null:
		settings_save_timer.start()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume_percent", master_volume_percent)
	config.set_value("audio", "music_volume_percent", music_bus_volume_percent)
	config.set_value("audio", "sfx_volume_percent", sfx_bus_volume_percent)
	config.set_value("display", "brightness_percent", brightness_percent)
	var error := config.save(settings_file_path)
	if error != OK:
		push_warning("Could not save settings to %s (error %d)." % [settings_file_path, error])


func _apply_master_volume() -> void:
	_apply_audio_bus_volume(&"Master", master_volume_percent)


func _apply_music_bus_volume() -> void:
	_apply_audio_bus_volume(MUSIC_BUS_NAME, music_bus_volume_percent)


func _apply_sfx_bus_volume() -> void:
	_apply_audio_bus_volume(SFX_BUS_NAME, sfx_bus_volume_percent)


func _apply_audio_bus_volume(bus_name: StringName, percent: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, percent <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, _percent_to_volume_db(percent))


func _add_brightness_filter() -> void:
	brightness_layer = CanvasLayer.new()
	brightness_layer.name = "BrightnessLayer"
	brightness_layer.layer = 100
	add_child(brightness_layer)
	brightness_filter = ColorRect.new()
	brightness_filter.name = "BrightnessFilter"
	brightness_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brightness_layer.add_child(brightness_filter)
	brightness_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _apply_brightness() -> void:
	if brightness_filter == null:
		return
	if brightness_percent < 100.0:
		var darkness := (100.0 - brightness_percent) / 50.0
		brightness_filter.color = Color(0.0, 0.0, 0.0, darkness * 0.4)
	elif brightness_percent > 100.0:
		var lightness := (brightness_percent - 100.0) / 50.0
		brightness_filter.color = Color(1.0, 1.0, 1.0, lightness * 0.2)
	else:
		brightness_filter.color = Color.TRANSPARENT


func _start_background_music() -> void:
	for music_path: String in BACKGROUND_MUSIC_PATHS:
		var music_stream := _load_background_music_stream(music_path)
		if music_stream == null:
			push_warning("Could not load background music: %s" % music_path)
			continue
		background_music_streams.append(music_stream)
	if background_music_streams.is_empty():
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusicPlayer"
	music_player.bus = MUSIC_BUS_NAME
	music_player.finished.connect(_play_next_background_music)
	add_child(music_player)
	_apply_background_music_volume()
	_play_background_music(0)


func _apply_background_music_volume() -> void:
	if music_player != null:
		music_player.volume_db = _percent_to_volume_db(background_music_volume_percent)


func _load_background_music_stream(music_path: String) -> AudioStream:
	if music_path.get_extension().to_lower() == "mp3":
		var music_data := FileAccess.get_file_as_bytes(music_path)
		if music_data.is_empty():
			return null
		var mp3_stream := AudioStreamMP3.new()
		mp3_stream.data = music_data
		return mp3_stream
	return load(music_path) as AudioStream


func _play_background_music(track_index: int) -> void:
	current_music_index = wrapi(track_index, 0, background_music_streams.size())
	music_player.stream = background_music_streams[current_music_index]
	music_player.play()


func _play_next_background_music() -> void:
	_play_background_music(current_music_index + 1)


func test_big_rocket_success() -> Dictionary:
	return _launch_test_manifest("big_rocket", "big_rocket_success")


func test_shuttle_success() -> Dictionary:
	return _launch_test_manifest("space_shuttle", "shuttle_success")


func test_failed_rocket() -> Dictionary:
	return _launch_test_manifest("big_rocket", "failed_rocket")


func test_spinlaunch() -> Dictionary:
	return _launch_test_manifest("spinlaunch", "spinlaunch")


func _launch_test_manifest(vehicle_id: String, manifest_id: String) -> Dictionary:
	var result := launch_manager.resolve_launch(vehicle_id, GameDataScript.get_test_manifest(manifest_id))
	_show_launch_result(result)
	return result


func _show_faction_select() -> void:
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(true)
	_set_active_screen(_build_faction_select_screen())


func _show_opening_cutscene() -> void:
	if opening_glitch_layer != null or opening_cutscene_layer != null:
		return
	if opening_glitch_duration <= 0.0:
		_begin_opening_cutscene()
		return

	opening_glitch_layer = ColorRect.new()
	opening_glitch_layer.name = "OpeningGlitch"
	opening_glitch_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	opening_glitch_layer.color = Color.WHITE
	opening_glitch_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var glitch_material := ShaderMaterial.new()
	glitch_material.shader = OPENING_GLITCH_SHADER
	opening_glitch_layer.material = glitch_material
	add_child(opening_glitch_layer)
	opening_glitch_player = AudioStreamPlayer.new()
	opening_glitch_player.name = "OpeningGlitchPlayer"
	opening_glitch_player.stream = OPENING_GLITCH_SOUND
	opening_glitch_player.bus = SFX_BUS_NAME
	opening_glitch_player.finished.connect(_on_opening_glitch_sound_finished)
	add_child(opening_glitch_player)
	opening_glitch_player.play()

	var glitch_tween := opening_glitch_layer.create_tween()
	glitch_tween.tween_interval(opening_glitch_duration)
	glitch_tween.tween_callback(_begin_opening_cutscene)


func _begin_opening_cutscene() -> void:
	if opening_glitch_layer != null:
		opening_glitch_layer.queue_free()
		opening_glitch_layer = null
	var cutscene_stream := load(OPENING_CUTSCENE_PATH) as VideoStream
	if cutscene_stream == null:
		push_warning("Could not load opening cutscene: %s" % OPENING_CUTSCENE_PATH)
		_show_faction_select()
		return

	opening_cutscene_layer = Control.new()
	opening_cutscene_layer.name = "OpeningCutscene"
	opening_cutscene_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	opening_cutscene_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	var black_background := ColorRect.new()
	black_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_background.color = Color.BLACK
	black_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opening_cutscene_layer.add_child(black_background)

	opening_cutscene_player = VideoStreamPlayer.new()
	opening_cutscene_player.name = "Video"
	opening_cutscene_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	opening_cutscene_player.expand = true
	opening_cutscene_player.bus = SFX_BUS_NAME
	opening_cutscene_player.stream = cutscene_stream
	opening_cutscene_player.finished.connect(_finish_opening_cutscene)
	opening_cutscene_layer.add_child(opening_cutscene_player)

	var explosion_stream := load(CUTSCENE_EXPLOSION_SOUND_PATH) as AudioStream
	if explosion_stream != null:
		cutscene_explosion_player = AudioStreamPlayer.new()
		cutscene_explosion_player.name = "ExplosionSound"
		cutscene_explosion_player.stream = explosion_stream
		cutscene_explosion_player.bus = SFX_BUS_NAME
		opening_cutscene_layer.add_child(cutscene_explosion_player)
	else:
		push_warning("Could not load cutscene explosion sound: %s" % CUTSCENE_EXPLOSION_SOUND_PATH)
	cutscene_explosion_played = false

	var skip_hint := Label.new()
	skip_hint.text = "ESC TO SKIP"
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip_hint.anchor_left = 0.0
	skip_hint.anchor_right = 1.0
	skip_hint.anchor_top = 1.0
	skip_hint.anchor_bottom = 1.0
	skip_hint.offset_left = 24.0
	skip_hint.offset_top = -52.0
	skip_hint.offset_right = -24.0
	skip_hint.offset_bottom = -20.0
	skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiAssetsScript.apply_text_outline(skip_hint)
	UiAssetsScript.apply_semibold_font(skip_hint)
	opening_cutscene_layer.add_child(skip_hint)

	add_child(opening_cutscene_layer)
	opening_cutscene_player.play()


func _on_opening_glitch_sound_finished() -> void:
	if opening_glitch_player != null:
		opening_glitch_player.queue_free()
		opening_glitch_player = null


func _finish_opening_cutscene() -> void:
	if opening_cutscene_layer == null:
		return
	if opening_cutscene_player != null:
		opening_cutscene_player.stop()
	opening_cutscene_layer.queue_free()
	opening_cutscene_layer = null
	opening_cutscene_player = null
	cutscene_explosion_player = null
	cutscene_explosion_played = false
	_show_faction_select()


func _process(_delta: float) -> void:
	if opening_cutscene_player == null or cutscene_explosion_player == null:
		return
	if cutscene_explosion_played or not opening_cutscene_player.is_playing():
		return
	if opening_cutscene_player.stream_position < cutscene_explosion_time:
		return
	cutscene_explosion_played = true
	cutscene_explosion_player.play()


func _show_opening_screen() -> void:
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(false)
	_set_active_screen(_build_opening_screen())


func _show_options_screen() -> void:
	_open_options_screen(_show_opening_screen)


func _show_faction_options_screen() -> void:
	_open_options_screen(_show_faction_select)


func _open_options_screen(back_callback: Callable) -> void:
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(false)
	var options_screen := OptionsScreenScene.instantiate() as OptionsScreen
	options_screen.button_navigation_delay = button_navigation_delay
	options_screen.back_requested.connect(back_callback)
	options_screen.master_volume_changed.connect(_on_master_volume_changed)
	options_screen.music_volume_changed.connect(_on_music_volume_changed)
	options_screen.sfx_volume_changed.connect(_on_sfx_volume_changed)
	options_screen.brightness_changed.connect(_on_brightness_changed)
	_set_active_screen(options_screen)
	options_screen.setup(master_volume_percent, music_bus_volume_percent, sfx_bus_volume_percent, brightness_percent)


func _on_master_volume_changed(value: float) -> void:
	master_volume_percent = clampf(value, 0.0, 100.0)
	_apply_master_volume()
	_queue_settings_save()


func _on_music_volume_changed(value: float) -> void:
	music_bus_volume_percent = clampf(value, 0.0, 100.0)
	_apply_music_bus_volume()
	_queue_settings_save()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_bus_volume_percent = clampf(value, 0.0, 100.0)
	_apply_sfx_bus_volume()
	_queue_settings_save()


func _on_brightness_changed(value: float) -> void:
	brightness_percent = clampf(value, 50.0, 150.0)
	_apply_brightness()
	_queue_settings_save()


func _exit_game() -> void:
	_save_settings()
	get_tree().quit()


func _build_opening_screen() -> Control:
	var screen := Control.new()
	screen.name = "OpeningScreen"

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	var opening_stack_compensation := opening_button_height + opening_menu_button_spacing
	layout.offset_top = opening_vertical_offset + opening_stack_compensation
	layout.offset_bottom = opening_vertical_offset + opening_stack_compensation
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", int(opening_title_button_spacing))

	var logo := TextureRect.new()
	logo.name = "TitleLogo"
	logo.custom_minimum_size = Vector2(opening_title_width, opening_title_height)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.texture = UiAssetsScript.get_title_logo()
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(logo)

	var button_stack := VBoxContainer.new()
	button_stack.name = "ButtonStack"
	button_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button_stack.add_theme_constant_override("separation", int(opening_menu_button_spacing))
	layout.add_child(button_stack)

	var start_button := _build_opening_menu_button("StartButton", "START", _show_opening_cutscene)
	button_stack.add_child(start_button)
	button_stack.add_child(_build_opening_menu_button("OptionsButton", "OPTIONS", _show_options_screen))
	button_stack.add_child(_build_opening_menu_button("ExitButton", "EXIT GAME", _exit_game))

	UiAssetsScript.apply_text_outline(layout)
	for button: Node in button_stack.get_children():
		UiAssetsScript.apply_semibold_font(button as Control)
	screen.add_child(layout)
	return screen


func _build_opening_menu_button(button_name: String, button_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = button_text
	button.custom_minimum_size = Vector2(opening_button_width, opening_button_height)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_queue_button_navigation.bind(callback))
	return button


func _update_editor_opening_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var preview := get_node_or_null("EditorOpeningPreview") as Control
	if preview == null:
		return
	preview.visible = true
	var layout := preview.get_node_or_null("Layout") as VBoxContainer
	var logo := preview.get_node_or_null("Layout/TitleLogo") as TextureRect
	var button_stack := preview.get_node_or_null("Layout/ButtonStack") as VBoxContainer
	if layout == null or logo == null or button_stack == null:
		return
	var opening_stack_compensation := opening_button_height + opening_menu_button_spacing
	layout.offset_top = opening_vertical_offset + opening_stack_compensation
	layout.offset_bottom = opening_vertical_offset + opening_stack_compensation
	layout.add_theme_constant_override("separation", int(opening_title_button_spacing))
	logo.custom_minimum_size = Vector2(opening_title_width, opening_title_height)
	button_stack.add_theme_constant_override("separation", int(opening_menu_button_spacing))
	for button: Node in button_stack.get_children():
		(button as Button).custom_minimum_size = Vector2(opening_button_width, opening_button_height)
	UiAssetsScript.apply_text_outline(layout)
	for button: Node in button_stack.get_children():
		UiAssetsScript.apply_semibold_font(button as Control)


func _unhandled_input(event: InputEvent) -> void:
	if opening_cutscene_layer != null and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish_opening_cutscene()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	if pause_overlay != null:
		get_viewport().set_input_as_handled()
		_close_pause_menu()
		return
	if _can_open_pause_menu():
		get_viewport().set_input_as_handled()
		_open_pause_menu()


func _can_open_pause_menu() -> bool:
	return cargo_loading_screen.visible or active_screen is StrategyScreen


func _open_pause_menu() -> void:
	if pause_overlay != null or not _can_open_pause_menu():
		return
	pause_overlay = PauseMenuScreenScene.instantiate() as PauseMenuScreen
	pause_overlay.resume_requested.connect(_queue_button_navigation.bind(_close_pause_menu))
	pause_overlay.options_requested.connect(_queue_button_navigation.bind(_show_pause_options))
	pause_overlay.instructions_requested.connect(_queue_button_navigation.bind(_show_pause_instructions))
	pause_overlay.quit_to_main_requested.connect(_queue_button_navigation.bind(_quit_to_opening_menu))
	pause_overlay.exit_game_requested.connect(_queue_button_navigation.bind(_exit_game))
	add_child(pause_overlay)


func _close_pause_menu() -> void:
	if pause_options_screen != null and is_instance_valid(pause_options_screen):
		pause_options_screen.queue_free()
	pause_options_screen = null
	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = null


func _show_pause_options() -> void:
	_show_pause_options_page(false)


func _show_pause_instructions() -> void:
	_show_pause_options_page(true)


func _show_pause_options_page(show_instructions: bool) -> void:
	if pause_overlay == null:
		return
	pause_overlay.set_menu_visible(false)
	if pause_options_screen != null and is_instance_valid(pause_options_screen):
		pause_options_screen.queue_free()
	pause_options_screen = OptionsScreenScene.instantiate() as OptionsScreen
	pause_options_screen.button_navigation_delay = button_navigation_delay
	pause_options_screen.back_requested.connect(_return_to_pause_menu)
	pause_options_screen.master_volume_changed.connect(_on_master_volume_changed)
	pause_options_screen.music_volume_changed.connect(_on_music_volume_changed)
	pause_options_screen.sfx_volume_changed.connect(_on_sfx_volume_changed)
	pause_options_screen.brightness_changed.connect(_on_brightness_changed)
	pause_overlay.add_child(pause_options_screen)
	pause_options_screen.setup(
		master_volume_percent,
		music_bus_volume_percent,
		sfx_bus_volume_percent,
		brightness_percent,
		false
	)
	if show_instructions:
		pause_options_screen.show_instructions_page()


func _return_to_pause_menu() -> void:
	if pause_options_screen != null and is_instance_valid(pause_options_screen):
		pause_options_screen.queue_free()
	pause_options_screen = null
	if pause_overlay != null:
		pause_overlay.set_menu_visible(true)


func _quit_to_opening_menu() -> void:
	_close_pause_menu()
	selected_faction = ""
	cargo_loading_screen.visible = false
	_show_opening_screen()


func _build_faction_select_screen() -> Control:
	var layout := Control.new()
	layout.name = "FactionSelectScreen"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)

	var prompt := Label.new()
	prompt.text = "SELECT FACTION"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.anchor_left = 0.0
	prompt.anchor_right = 1.0
	prompt.anchor_top = 0.5
	prompt.anchor_bottom = 0.5
	prompt.offset_top = -FACTION_SELECT_LOGO_SIZE.y * 0.5 - 58.0
	prompt.offset_bottom = prompt.offset_top + 32.0
	layout.add_child(prompt)

	var faction_row := HBoxContainer.new()
	faction_row.anchor_left = 0.0
	faction_row.anchor_right = 1.0
	faction_row.anchor_top = 0.5
	faction_row.anchor_bottom = 0.5
	faction_row.offset_top = -FACTION_SELECT_LOGO_SIZE.y * 0.5
	faction_row.offset_bottom = FACTION_SELECT_LOGO_SIZE.y * 0.5
	faction_row.alignment = BoxContainer.ALIGNMENT_CENTER
	faction_row.add_theme_constant_override("separation", 80)
	layout.add_child(faction_row)

	for faction_id: String in GameDataScript.FACTIONS.keys():
		var button := _build_faction_logo_button(faction_id)
		faction_row.add_child(button)

	var menu_stack := VBoxContainer.new()
	menu_stack.name = "FactionMenuButtons"
	menu_stack.anchor_left = 0.5
	menu_stack.anchor_right = 0.5
	menu_stack.anchor_top = 0.5
	menu_stack.anchor_bottom = 0.5
	menu_stack.offset_left = -120.0
	menu_stack.offset_top = 164.0
	menu_stack.offset_right = 120.0
	menu_stack.offset_bottom = 312.0
	menu_stack.add_theme_constant_override("separation", 8)
	layout.add_child(menu_stack)

	var start_button := Button.new()
	start_button.name = "StartButton"
	start_button.text = "START"
	start_button.custom_minimum_size = Vector2(240, 44)
	start_button.disabled = selected_faction == ""
	start_button.modulate = Color(1.18, 1.03, 0.74, 1.0) if selected_faction != "" else Color(0.62, 0.62, 0.62, 1.0)
	start_button.pressed.connect(_queue_button_navigation.bind(_on_start_match_pressed))
	menu_stack.add_child(start_button)

	var options_button := Button.new()
	options_button.name = "OptionsButton"
	options_button.text = "OPTIONS"
	options_button.custom_minimum_size = Vector2(240, 44)
	options_button.pressed.connect(_queue_button_navigation.bind(_show_faction_options_screen))
	menu_stack.add_child(options_button)

	var exit_button := Button.new()
	exit_button.name = "ExitButton"
	exit_button.text = "EXIT GAME"
	exit_button.custom_minimum_size = Vector2(240, 44)
	exit_button.pressed.connect(_queue_button_navigation.bind(_exit_game))
	menu_stack.add_child(exit_button)

	UiAssetsScript.apply_text_outline(layout)
	UiAssetsScript.apply_semibold_font(prompt)
	for button: Node in menu_stack.get_children():
		UiAssetsScript.apply_semibold_font(button as Control)
	return layout


func _build_faction_logo_button(faction_id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = FACTION_SELECT_LOGO_SIZE
	button.toggle_mode = true
	button.button_pressed = faction_id == selected_faction
	button.flat = true
	button.text = ""
	button.pressed.connect(_on_faction_button_pressed.bind(faction_id))
	button.mouse_entered.connect(_set_faction_logo_highlight.bind(button, true))
	button.mouse_exited.connect(_set_faction_logo_highlight.bind(button, false))

	var halo := TextureRect.new()
	halo.name = "Halo"
	halo.set_anchors_preset(Control.PRESET_FULL_RECT)
	halo.offset_left = -14.0
	halo.offset_top = -14.0
	halo.offset_right = 14.0
	halo.offset_bottom = 14.0
	halo.pivot_offset = FACTION_SELECT_LOGO_SIZE * 0.5
	halo.texture = UiAssetsScript.get_faction_logo(faction_id)
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	halo.modulate = FACTION_LOGO_HALO_MODULATE
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.visible = faction_id == selected_faction
	button.add_child(halo)

	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.pivot_offset = FACTION_SELECT_LOGO_SIZE * 0.5
	logo.texture = UiAssetsScript.get_faction_logo(faction_id)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.modulate = FACTION_LOGO_HIGHLIGHT_MODULATE if faction_id == selected_faction else FACTION_LOGO_NORMAL_MODULATE
	logo.scale = FACTION_LOGO_HIGHLIGHT_SCALE if faction_id == selected_faction else FACTION_LOGO_NORMAL_SCALE
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(logo)

	return button


func _set_faction_logo_highlight(button: Button, is_hovered: bool) -> void:
	var is_highlighted := is_hovered or button.button_pressed
	var logo := button.get_node_or_null("Logo") as TextureRect
	if logo != null:
		logo.scale = FACTION_LOGO_HIGHLIGHT_SCALE if is_highlighted else FACTION_LOGO_NORMAL_SCALE
		logo.modulate = FACTION_LOGO_HIGHLIGHT_MODULATE if is_highlighted else FACTION_LOGO_NORMAL_MODULATE

	var halo := button.get_node_or_null("Halo") as TextureRect
	if halo != null:
		halo.visible = is_highlighted


func _show_strategy_screen() -> void:
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(true)
	var strategy_screen := StrategyScreenScene.instantiate()
	strategy_screen.vehicle_selected.connect(_on_strategy_vehicle_selected)
	strategy_screen.reset_requested.connect(_queue_button_navigation.bind(_on_reset_button_pressed))
	strategy_screen.debug_add_news_requested.connect(_on_debug_add_news_pressed)
	strategy_screen.debug_force_player_win_requested.connect(_queue_button_navigation.bind(_on_debug_force_player_win_pressed))
	strategy_screen.debug_force_cpu_win_requested.connect(_queue_button_navigation.bind(_on_debug_force_cpu_win_pressed))
	strategy_screen.debug_launch_failure_requested.connect(_queue_button_navigation.bind(_on_debug_launch_failure_pressed))
	strategy_screen.debug_launch_success_requested.connect(_queue_button_navigation.bind(_on_debug_launch_success_pressed))
	_set_active_screen(strategy_screen)
	strategy_screen.setup(game_state.get_summary(), SHOW_DEBUG_ACTIONS)


func _show_launch_result(result: Dictionary) -> void:
	last_launch_result = result
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(true)
	_set_active_screen(_build_launch_result_screen(result))
	if not bool(result.get("success", false)):
		launch_failure_panel = active_screen.get_node("LaunchFailurePanel") as TextureRect
		launch_failure_text = launch_failure_panel.get_node("FailureText") as Control
		launch_failure_continue_button = active_screen.get_node("ContinueButton") as Button
		_apply_launch_failure_layout()


func _build_launch_result_screen(result: Dictionary) -> Control:
	launch_failure_panel = null
	launch_failure_text = null
	launch_failure_continue_button = null
	if not bool(result.get("success", false)):
		return _build_launch_failure_screen(result)

	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)

	var text_margin := MarginContainer.new()
	text_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_margin.add_theme_constant_override("margin_left", 24)
	text_margin.add_theme_constant_override("margin_top", LAUNCH_RESULT_MARGIN_TOP)
	text_margin.add_theme_constant_override("margin_right", 24)
	text_margin.add_theme_constant_override("margin_bottom", 24)
	screen.add_child(text_margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	text_margin.add_child(layout)

	var title := Label.new()
	title.text = "Launch Result"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = _format_launch_result(result)
	layout.add_child(details)

	var continue_button := Button.new()
	continue_button.text = "Continue"
	continue_button.set_anchors_preset(Control.PRESET_CENTER)
	continue_button.offset_left = -LAUNCH_RESULT_BUTTON_WIDTH * 0.5
	continue_button.offset_top = -LAUNCH_RESULT_BUTTON_HEIGHT * 0.5
	continue_button.offset_right = LAUNCH_RESULT_BUTTON_WIDTH * 0.5
	continue_button.offset_bottom = LAUNCH_RESULT_BUTTON_HEIGHT * 0.5
	continue_button.pressed.connect(_queue_button_navigation.bind(_on_result_continue_pressed))
	screen.add_child(continue_button)

	UiAssetsScript.apply_text_outline(screen)
	return screen


func _build_launch_failure_screen(result: Dictionary) -> Control:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := TextureRect.new()
	panel.name = "LaunchFailurePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -LAUNCH_FAILURE_PANEL_SIZE.x * 0.5 + launch_failure_panel_x
	panel.offset_top = -LAUNCH_FAILURE_PANEL_SIZE.y * 0.5 + launch_failure_panel_y
	panel.offset_right = LAUNCH_FAILURE_PANEL_SIZE.x * 0.5 + launch_failure_panel_x
	panel.offset_bottom = LAUNCH_FAILURE_PANEL_SIZE.y * 0.5 + launch_failure_panel_y
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture = LAUNCH_FAILURE_PANEL
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.modulate.a = 0.85
	screen.add_child(panel)

	var text_group := VBoxContainer.new()
	text_group.name = "FailureText"
	text_group.position = Vector2(launch_failure_text_x, launch_failure_text_y)
	text_group.size = LAUNCH_FAILURE_TEXT_SIZE
	text_group.add_theme_constant_override("separation", 28)
	panel.add_child(text_group)

	var title := Label.new()
	title.name = "Title"
	title.text = "Launch Failure"
	title.add_theme_font_size_override("font_size", 28)
	text_group.add_child(title)

	var details := Label.new()
	details.name = "Details"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = _format_launch_result(result)
	text_group.add_child(details)

	var continue_button := Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.set_anchors_preset(Control.PRESET_CENTER)
	continue_button.offset_left = -LAUNCH_RESULT_BUTTON_WIDTH * 0.5 + launch_failure_panel_x
	continue_button.offset_top = LAUNCH_FAILURE_PANEL_SIZE.y * 0.5 + 16.0 + launch_failure_panel_y
	continue_button.offset_right = LAUNCH_RESULT_BUTTON_WIDTH * 0.5 + launch_failure_panel_x
	continue_button.offset_bottom = (
		LAUNCH_FAILURE_PANEL_SIZE.y * 0.5
		+ 16.0
		+ LAUNCH_RESULT_BUTTON_HEIGHT
		+ launch_failure_panel_y
	)
	continue_button.pressed.connect(_queue_button_navigation.bind(_on_result_continue_pressed))
	screen.add_child(continue_button)

	UiAssetsScript.apply_text_outline(screen)
	return screen


func _apply_launch_failure_layout() -> void:
	if is_instance_valid(launch_failure_panel):
		launch_failure_panel.offset_left = -LAUNCH_FAILURE_PANEL_SIZE.x * 0.5 + launch_failure_panel_x
		launch_failure_panel.offset_top = -LAUNCH_FAILURE_PANEL_SIZE.y * 0.5 + launch_failure_panel_y
		launch_failure_panel.offset_right = LAUNCH_FAILURE_PANEL_SIZE.x * 0.5 + launch_failure_panel_x
		launch_failure_panel.offset_bottom = LAUNCH_FAILURE_PANEL_SIZE.y * 0.5 + launch_failure_panel_y
	if is_instance_valid(launch_failure_text):
		launch_failure_text.position = Vector2(launch_failure_text_x, launch_failure_text_y)
	if is_instance_valid(launch_failure_continue_button):
		launch_failure_continue_button.offset_left = -LAUNCH_RESULT_BUTTON_WIDTH * 0.5 + launch_failure_panel_x
		launch_failure_continue_button.offset_top = (
			LAUNCH_FAILURE_PANEL_SIZE.y * 0.5 + 16.0 + launch_failure_panel_y
		)
		launch_failure_continue_button.offset_right = LAUNCH_RESULT_BUTTON_WIDTH * 0.5 + launch_failure_panel_x
		launch_failure_continue_button.offset_bottom = (
			LAUNCH_FAILURE_PANEL_SIZE.y * 0.5
			+ 16.0
			+ LAUNCH_RESULT_BUTTON_HEIGHT
			+ launch_failure_panel_y
		)


func _show_game_over_screen() -> void:
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(true)
	_set_active_screen(_build_game_over_screen())


func _build_game_over_screen() -> Control:
	var summary := game_state.get_summary()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 32)
	if bool(summary["player_won"]):
		title.text = "Victory"
	else:
		title.text = "Race Lost"
	layout.add_child(title)

	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = _format_game_over(summary)
	layout.add_child(details)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	layout.add_child(row)

	var again_button := Button.new()
	again_button.text = "Play Again" if bool(summary["player_won"]) else "Try Again"
	again_button.pressed.connect(_queue_button_navigation.bind(_on_play_again_pressed))
	row.add_child(again_button)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.pressed.connect(_queue_button_navigation.bind(_on_main_menu_pressed))
	row.add_child(menu_button)

	UiAssetsScript.apply_text_outline(layout)
	return _with_margin(layout, GAME_OVER_MARGIN_TOP)


func _build_debug_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "Debug:"
	row.add_child(label)

	var test_news_button := Button.new()
	test_news_button.text = "Add Test News"
	test_news_button.pressed.connect(_on_debug_add_news_pressed)
	row.add_child(test_news_button)

	var win_button := Button.new()
	win_button.text = "Force Player Win"
	win_button.pressed.connect(_queue_button_navigation.bind(_on_debug_force_player_win_pressed))
	row.add_child(win_button)

	var lose_button := Button.new()
	lose_button.text = "Force CPU Win"
	lose_button.pressed.connect(_queue_button_navigation.bind(_on_debug_force_cpu_win_pressed))
	row.add_child(lose_button)

	return row


func _open_assignment_screen(vehicle_id: String) -> void:
	_clear_active_screen()
	_set_corner_logo_visible(true)
	cargo_loading_screen.start_assignment(vehicle_id, game_state.moonbase.remaining_requirements.duplicate(true))


func _on_strategy_vehicle_selected(vehicle_id: String) -> void:
	_queue_button_navigation(_open_assignment_screen.bind(vehicle_id))


func _on_launch_requested(vehicle_id: String, manifest: Dictionary) -> void:
	var result := launch_manager.resolve_launch(vehicle_id, manifest)
	_show_launch_result(result)


func _on_assignment_cancelled() -> void:
	cargo_loading_screen.visible = false
	_show_strategy_screen()


func _on_result_continue_pressed() -> void:
	if game_state.game_over:
		_show_game_over_screen()
	else:
		_show_strategy_screen()


func _on_faction_button_pressed(faction_id: String) -> void:
	selected_faction = faction_id
	_show_faction_select()


func _on_start_match_pressed() -> void:
	if selected_faction == "":
		return
	game_state.start_new_match(selected_faction)
	_show_strategy_screen()


func _on_reset_button_pressed() -> void:
	game_state.start_new_match(selected_faction)
	_show_strategy_screen()


func _on_play_again_pressed() -> void:
	game_state.start_new_match(selected_faction)
	_show_strategy_screen()


func _on_main_menu_pressed() -> void:
	game_state.start_new_match(selected_faction)
	_show_faction_select()


func _on_debug_add_news_pressed() -> void:
	game_state.news.add_message("Debug bulletin: mission control confirms the news printer still works.")
	_show_strategy_screen()


func _on_debug_launch_failure_pressed() -> void:
	test_failed_rocket()


func _on_debug_launch_success_pressed() -> void:
	test_big_rocket_success()


func _on_debug_force_player_win_pressed() -> void:
	for material: String in game_state.moonbase.remaining_requirements.keys():
		game_state.moonbase.remaining_requirements[material] = 0
	game_state.check_for_winner()
	game_state.news.add_game_over_winner(game_state.player_faction, true)
	_show_game_over_screen()


func _on_debug_force_cpu_win_pressed() -> void:
	if not game_state.competitors.is_empty():
		game_state.competitors[0].progress_percent = 100.0
	game_state.check_for_winner()
	game_state.news.add_game_over_winner(game_state.winner_name, false)
	_show_game_over_screen()


func _set_active_screen(screen: Control) -> void:
	_clear_active_screen()
	active_screen = screen
	root_margin.add_child(active_screen)


func _clear_active_screen() -> void:
	if active_screen != null and is_instance_valid(active_screen):
		active_screen.queue_free()
	active_screen = null


func _clear_root_margin() -> void:
	for child in root_margin.get_children():
		child.queue_free()


func _add_scene_background() -> void:
	var texture := UiAssetsScript.get_background()
	if texture == null:
		return
	var background := TextureRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)


func _add_corner_logo() -> void:
	var texture := UiAssetsScript.get_title_logo()
	if texture == null:
		return
	corner_logo = TextureRect.new()
	corner_logo.name = "CornerLogo"
	corner_logo.texture = texture
	corner_logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	corner_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	corner_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_logo.visible = false
	add_child(corner_logo)
	_update_corner_logo_layout()


func _update_corner_logo_layout() -> void:
	if corner_logo == null or not is_instance_valid(corner_logo):
		return
	corner_logo.custom_minimum_size = Vector2(corner_logo_width, corner_logo_height)
	corner_logo.offset_left = corner_logo_x
	corner_logo.offset_top = corner_logo_y
	corner_logo.offset_right = corner_logo_x + corner_logo_width
	corner_logo.offset_bottom = corner_logo_y + corner_logo_height


func _set_corner_logo_visible(is_visible: bool) -> void:
	if corner_logo != null:
		corner_logo.visible = is_visible


func _with_margin(content: Control, margin_top := 24) -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", margin_top)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.add_child(content)
	return margin


func _with_panel_art(content: Control, frame_id: String, minimum_size: Vector2) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = minimum_size
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var frame_texture := UiAssetsScript.get_panel_frame(frame_id)
	if frame_texture != null:
		var frame := TextureRect.new()
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.texture = frame_texture
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.modulate.a = 0.85
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(frame)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	wrapper.add_child(margin)
	margin.add_child(content)

	return wrapper


func _format_launch_result(result: Dictionary) -> String:
	if result.is_empty():
		return "Launch result unavailable."

	var lines: Array[String] = [
		"Vehicle: %s" % String(result.get("vehicle_name", "")),
		"Days advanced: %d" % int(result.get("launch_days", 0)),
		"Fuel: %d / %d" % [
			int(result.get("placed_fuel", 0)),
			int(result.get("required_fuel", 0)),
		],
	]

	if bool(result.get("success", false)):
		lines.append("Launch successful.")
		lines.append("Readiness: %.1f%% -> %.1f%%" % [
			float(result.get("readiness_before", 0.0)),
			float(result.get("readiness_after", 0.0)),
		])
		lines.append("")
		lines.append("Delivered construction materials:")
		lines.append(_format_material_amounts(result.get("delivery_result", {}).get("used", {}), "- none"))
		var wasted_text := _format_material_amounts(result.get("delivery_result", {}).get("wasted", {}), "")
		if wasted_text != "":
			lines.append("")
			lines.append("Wasted overdelivery:")
			lines.append(wasted_text)
	else:
		lines.append("Launch failed. Cargo lost.")
		lines.append("Readiness unchanged: %.1f%%" % float(result.get("readiness_before", 0.0)))

	return "\n".join(lines)


func _format_game_over(summary: Dictionary) -> String:
	if bool(summary["player_won"]):
		return "\n".join([
			"Winning faction: %s" % String(summary["winner_name"]),
			"Days elapsed: %d" % int(summary["days_elapsed"]),
			"Launches: %d" % int(summary["launches_attempted"]),
			"Successful launches: %d" % int(summary["successful_launches"]),
			"Failed launches: %d" % int(summary["failed_launches"]),
			"Final readiness: %.1f%%" % float(summary["player_readiness_percent"]),
		])

	return "\n".join([
		"Winning CPU faction: %s" % String(summary["winner_name"]),
		"Player readiness: %.1f%%" % float(summary["player_readiness_percent"]),
		"Days elapsed: %d" % int(summary["days_elapsed"]),
		"Launches: %d" % int(summary["launches_attempted"]),
		"Failed launches: %d" % int(summary["failed_launches"]),
	])


func _format_needs(remaining_requirements: Dictionary) -> String:
	var lines: Array[String] = ["Remaining moonbase needs:"]
	for material: String in GameDataScript.CONSTRUCTION_MATERIALS:
		lines.append("- %s: %d / %d" % [
			_format_material_name(material),
			int(remaining_requirements.get(material, 0)),
			int(GameDataScript.MOONBASE_REQUIREMENTS.get(material, 0)),
		])
	return "\n".join(lines)


func _format_competitors(competitors: Array) -> String:
	var lines: Array[String] = ["CPU competitors:"]
	for competitor: Dictionary in competitors:
		lines.append("- %s: %.1f%%" % [
			String(competitor["display_name"]),
			float(competitor["progress_percent"]),
		])
	return "\n".join(lines)


func _format_news(messages: Array) -> String:
	var lines: Array[String] = []
	for message: String in messages:
		lines.append("- %s" % message)
	return "\n".join(lines)


func _format_material_amounts(materials: Dictionary, empty_text: String) -> String:
	var lines: Array[String] = []
	for material: String in GameDataScript.CONSTRUCTION_MATERIALS:
		var amount := int(materials.get(material, 0))
		if amount > 0:
			lines.append("- %s: %d" % [_format_material_name(material), amount])
	if lines.is_empty():
		return empty_text
	return "\n".join(lines)


func _format_material_name(material: String) -> String:
	return material.replace("_", " ").capitalize()


func _get_faction_flavor(faction_id: String) -> String:
	match faction_id:
		"USA":
			return "high-energy mission control"
		"China":
			return "fast industrial push"
		"EU":
			return "steady cooperative program"
		_:
			return "lunar construction team"


func _on_big_rocket_button_pressed() -> void:
	_open_assignment_screen("big_rocket")


func _on_shuttle_button_pressed() -> void:
	_open_assignment_screen("space_shuttle")


func _on_failed_rocket_button_pressed() -> void:
	test_failed_rocket()


func _on_spinlaunch_button_pressed() -> void:
	_open_assignment_screen("spinlaunch")
