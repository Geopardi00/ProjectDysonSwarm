extends Control

const GameDataScript := preload("res://scripts/data/GameData.gd")
const LaunchManagerScript := preload("res://scripts/launch/LaunchManager.gd")
const UiAssetsScript := preload("res://scripts/data/UiAssets.gd")
const StrategyScreenScene := preload("res://scenes/ui/StrategyScreen.tscn")

const SHOW_DEBUG_ACTIONS := true
const CORNER_LOGO_SIZE := Vector2(272, 62.5)
const LAUNCH_RESULT_MARGIN_TOP := 112
const LAUNCH_RESULT_BUTTON_WIDTH := 220
const LAUNCH_RESULT_BUTTON_HEIGHT := 44
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

@onready var root_margin: MarginContainer = $RootMargin
@onready var cargo_loading_screen: Control = %CargoLoadingScreen

var game_state: GameState
var launch_manager: LaunchManager
var selected_faction := ""
var active_screen: Control
var corner_logo: TextureRect
var last_launch_result: Dictionary = {}
var music_player: AudioStreamPlayer
var background_music_streams: Array[AudioStream] = []
var current_music_index := 0


func _ready() -> void:
	_add_scene_background()
	_add_corner_logo()
	_start_background_music()
	game_state = GameState.new()
	add_child(game_state)

	launch_manager = LaunchManagerScript.new()
	launch_manager.setup(game_state)

	cargo_loading_screen.launch_requested.connect(_on_launch_requested)
	cargo_loading_screen.assignment_cancelled.connect(_on_assignment_cancelled)

	_clear_root_margin()
	_show_opening_screen()


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
	music_player.finished.connect(_play_next_background_music)
	add_child(music_player)
	_play_background_music(0)


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


func _show_opening_screen() -> void:
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(false)
	_set_active_screen(_build_opening_screen())


func _build_opening_screen() -> Control:
	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 28)

	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(1448, 333)
	logo.texture = UiAssetsScript.get_title_logo()
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(logo)

	var start_button := Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(220, 44)
	start_button.pressed.connect(_show_faction_select)
	layout.add_child(start_button)

	UiAssetsScript.apply_text_outline(layout)
	return layout


func _build_faction_select_screen() -> Control:
	var layout := Control.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)

	var prompt := Label.new()
	prompt.text = "Select faction"
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

	var start_button := Button.new()
	start_button.text = "Start"
	start_button.anchor_left = 0.5
	start_button.anchor_right = 0.5
	start_button.anchor_top = 0.5
	start_button.anchor_bottom = 0.5
	start_button.offset_left = -120.0
	start_button.offset_top = 164.0
	start_button.offset_right = 120.0
	start_button.offset_bottom = 208.0
	start_button.custom_minimum_size = Vector2(240, 44)
	start_button.disabled = selected_faction == ""
	start_button.modulate = Color(1.18, 1.03, 0.74, 1.0) if selected_faction != "" else Color(0.62, 0.62, 0.62, 1.0)
	start_button.pressed.connect(_on_start_match_pressed)
	layout.add_child(start_button)

	UiAssetsScript.apply_text_outline(layout)
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
	strategy_screen.vehicle_selected.connect(_open_assignment_screen)
	strategy_screen.reset_requested.connect(_on_reset_button_pressed)
	strategy_screen.debug_add_news_requested.connect(_on_debug_add_news_pressed)
	strategy_screen.debug_force_player_win_requested.connect(_on_debug_force_player_win_pressed)
	strategy_screen.debug_force_cpu_win_requested.connect(_on_debug_force_cpu_win_pressed)
	_set_active_screen(strategy_screen)
	strategy_screen.setup(game_state.get_summary(), SHOW_DEBUG_ACTIONS)


func _show_launch_result(result: Dictionary) -> void:
	last_launch_result = result
	cargo_loading_screen.visible = false
	_set_corner_logo_visible(true)
	_set_active_screen(_build_launch_result_screen(result))


func _build_launch_result_screen(result: Dictionary) -> Control:
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
	continue_button.pressed.connect(_on_result_continue_pressed)
	screen.add_child(continue_button)

	UiAssetsScript.apply_text_outline(screen)
	return screen


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
	again_button.pressed.connect(_on_play_again_pressed)
	row.add_child(again_button)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.pressed.connect(_on_main_menu_pressed)
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
	win_button.pressed.connect(_on_debug_force_player_win_pressed)
	row.add_child(win_button)

	var lose_button := Button.new()
	lose_button.text = "Force CPU Win"
	lose_button.pressed.connect(_on_debug_force_cpu_win_pressed)
	row.add_child(lose_button)

	return row


func _open_assignment_screen(vehicle_id: String) -> void:
	_clear_active_screen()
	_set_corner_logo_visible(true)
	cargo_loading_screen.start_assignment(vehicle_id, game_state.moonbase.remaining_requirements.duplicate(true))


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
	corner_logo.custom_minimum_size = CORNER_LOGO_SIZE
	corner_logo.offset_left = 10.0
	corner_logo.offset_top = 7.0
	corner_logo.offset_right = corner_logo.offset_left + CORNER_LOGO_SIZE.x
	corner_logo.offset_bottom = corner_logo.offset_top + CORNER_LOGO_SIZE.y
	corner_logo.texture = texture
	corner_logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	corner_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	corner_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_logo.visible = false
	add_child(corner_logo)


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
