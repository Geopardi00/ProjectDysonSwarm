extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://game_over_panel_smoke_settings.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := MainScene.instantiate()
	main.settings_file_path = TEST_SETTINGS_PATH
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920.0, 1080.0)
	await process_frame
	await process_frame

	main.game_state.game_over = true
	main.game_state.player_won = true
	main.game_state.winner_name = main.game_state.player_faction
	main._show_game_over_screen()
	await process_frame

	var won_panel := main.active_screen.get_node("GameOverPanel") as TextureRect
	var won_text := won_panel.get_node("GameOverText") as VBoxContainer
	var won_details := won_text.get_node("Details") as Label
	var won_buttons := main.active_screen.get_node("GameOverButtons") as HBoxContainer
	if won_panel.texture == null or not won_panel.texture.resource_path.ends_with("race_won_panel.png"):
		_fail(main, "Won-race screen did not use race_won_panel.png.")
		return
	if won_panel.size != Vector2(812.0, 781.0) or won_panel.texture.get_size() != Vector2(812.0, 781.0):
		_fail(main, "Won-race panel did not retain its native 812x781 size.")
		return
	if not won_details.text.contains("Winning faction:"):
		_fail(main, "Won-race information was not placed inside the panel.")
		return
	if won_buttons.position.y <= won_panel.position.y + won_panel.size.y:
		_fail(main, "Won-race buttons were not below the panel.")
		return

	var panel_position := won_panel.position
	var text_position := won_text.position
	var buttons_position := won_buttons.position
	main.game_over_panel_x += 8.0
	main.game_over_panel_y += 10.0
	main.game_over_text_x += 12.0
	main.game_over_text_y += 14.0
	if won_panel.position != panel_position + Vector2(8.0, 10.0):
		_fail(main, "Game-over panel Inspector controls did not update live.")
		return
	if won_text.position != text_position + Vector2(12.0, 14.0):
		_fail(main, "Game-over text Inspector controls did not update live.")
		return
	if won_buttons.position != buttons_position + Vector2(8.0, 10.0):
		_fail(main, "Game-over buttons did not follow the panel position.")
		return
	var shared_text_position := won_text.position

	main.game_state.player_won = false
	main.game_state.winner_name = "China"
	main._show_game_over_screen()
	await process_frame
	var lost_panel := main.active_screen.get_node("GameOverPanel") as TextureRect
	var lost_text := lost_panel.get_node("GameOverText") as VBoxContainer
	var lost_details := lost_text.get_node("Details") as Label
	var lost_buttons := main.active_screen.get_node("GameOverButtons") as HBoxContainer
	if lost_panel.texture == null or not lost_panel.texture.resource_path.ends_with("race_lost_panel.png"):
		_fail(main, "Lost-race screen did not use race_lost_panel.png.")
		return
	if lost_text.position != shared_text_position:
		_fail(main, "Won and lost race text did not share the same position.")
		return
	if not lost_details.text.contains("Winning CPU faction: China"):
		_fail(main, "Lost-race information was not placed inside the panel.")
		return
	if lost_buttons.position.y <= lost_panel.position.y + lost_panel.size.y:
		_fail(main, "Lost-race buttons were not below the panel.")
		return

	_cleanup(main)
	print("Game over panel smoke test passed.")
	quit(0)


func _cleanup(main) -> void:
	if main != null and is_instance_valid(main):
		main.settings_loaded = false
		main.queue_free()
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))


func _fail(main, message: String) -> void:
	_cleanup(main)
	push_error(message)
	quit(1)
