extends Control

const GameDataScript := preload("res://scripts/data/GameData.gd")
const LaunchManagerScript := preload("res://scripts/launch/LaunchManager.gd")
const UiAssetsScript := preload("res://scripts/data/UiAssets.gd")
const StrategyScreenScene := preload("res://scenes/ui/StrategyScreen.tscn")

const SHOW_DEBUG_ACTIONS := true

@onready var root_margin: MarginContainer = $RootMargin
@onready var cargo_loading_screen: Control = %CargoLoadingScreen

var game_state: GameState
var launch_manager: LaunchManager
var selected_faction := "USA"
var active_screen: Control
var last_launch_result: Dictionary = {}


func _ready() -> void:
	_add_scene_background()
	game_state = GameState.new()
	add_child(game_state)

	launch_manager = LaunchManagerScript.new()
	launch_manager.setup(game_state)

	cargo_loading_screen.launch_requested.connect(_on_launch_requested)
	cargo_loading_screen.assignment_cancelled.connect(_on_assignment_cancelled)

	_clear_root_margin()
	_show_faction_select()


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
	_set_active_screen(_build_faction_select_screen())


func _build_faction_select_screen() -> Control:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "Project Dyson Swarm"
	title.add_theme_font_size_override("font_size", 32)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose your faction. Bonuses are not active yet; this is flavor and CPU setup."
	layout.add_child(subtitle)

	var faction_row := HBoxContainer.new()
	faction_row.add_theme_constant_override("separation", 12)
	layout.add_child(faction_row)

	for faction_id: String in GameDataScript.FACTIONS.keys():
		var faction: Dictionary = GameDataScript.FACTIONS[faction_id]
		var button := _build_faction_card(faction_id, String(faction.get("display_name", faction_id)))
		faction_row.add_child(button)

	var start_button := Button.new()
	start_button.text = "Start Match"
	start_button.custom_minimum_size = Vector2(240, 44)
	start_button.pressed.connect(_on_start_match_pressed)
	layout.add_child(start_button)

	UiAssetsScript.apply_text_outline(layout)
	return _with_margin(layout)


func _build_faction_card(faction_id: String, display_name: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 180)
	button.toggle_mode = true
	button.button_pressed = faction_id == selected_faction
	button.text = ""
	button.pressed.connect(_on_faction_button_pressed.bind(faction_id))

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	button.add_child(content)

	var logo := TextureRect.new()
	logo.custom_minimum_size = Vector2(96, 96)
	logo.texture = UiAssetsScript.get_faction_logo(faction_id)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(logo)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)

	var flavor_label := Label.new()
	flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor_label.text = _get_faction_flavor(faction_id)
	flavor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(flavor_label)

	return button


func _show_strategy_screen() -> void:
	cargo_loading_screen.visible = false
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
	_set_active_screen(_build_launch_result_screen(result))


func _build_launch_result_screen(result: Dictionary) -> Control:
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)

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
	continue_button.custom_minimum_size = Vector2(220, 44)
	continue_button.pressed.connect(_on_result_continue_pressed)
	layout.add_child(continue_button)

	UiAssetsScript.apply_text_outline(layout)
	return _with_margin(layout)


func _show_game_over_screen() -> void:
	cargo_loading_screen.visible = false
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
	return _with_margin(layout)


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


func _with_margin(content: Control) -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
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
