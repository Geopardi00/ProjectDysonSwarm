extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const GameDataScript := preload("res://scripts/data/GameData.gd")
const TEST_SETTINGS_PATH := "user://demo_two_round_flow_smoke_settings.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main = MainScene.instantiate()
	main.settings_file_path = TEST_SETTINGS_PATH
	main.demo_mode = true
	main.button_navigation_delay = 0.0
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920.0, 1080.0)
	await process_frame
	await process_frame

	main.selected_faction = "EU"
	main._on_start_match_pressed()
	await process_frame
	if main.game_state.player_faction != "EU" or main.active_screen.name != "StrategyScreen":
		return _fail(main, "Demo match did not start with the selected faction.")

	var first_result: Dictionary = main.launch_manager.resolve_launch(
		"spinlaunch",
		GameDataScript.get_test_manifest("spinlaunch")
	)
	main._show_launch_result(first_result)
	await process_frame
	if main.game_state.launches_attempted != 1 or main.active_screen.get_node_or_null("ContinueButton") == null:
		return _fail(main, "The first launch did not remain on its result screen.")
	main._on_result_continue_pressed()
	await process_frame
	if main.active_screen == null or main.active_screen.name != "StrategyScreen":
		return _fail(main, "The first round did not return to strategy.")

	var second_result: Dictionary = main.launch_manager.resolve_launch(
		"big_rocket",
		GameDataScript.get_test_manifest("failed_rocket")
	)
	main._show_launch_result(second_result)
	await process_frame
	if main.game_state.launches_attempted != 2 or main.active_screen.get_node_or_null("ContinueButton") == null:
		return _fail(main, "The second launch did not remain on its result screen.")
	main._on_result_continue_pressed()
	await process_frame
	if main.active_screen == null or main.active_screen.name != "DemoCompleteScreen":
		return _fail(main, "The demo did not end after the second round.")

	var replay_button := main.active_screen.get_node_or_null(
		"PanelCenter/Panel/ContentMargin/Content/ReplayButton"
	) as Button
	if replay_button == null:
		return _fail(main, "The completed demo did not provide a replay button.")
	replay_button.pressed.emit()
	await process_frame
	await process_frame
	if main.active_screen == null or main.active_screen.name != "OpeningScreen":
		return _fail(main, "Replay did not return to the opening screen.")
	if main.selected_faction != "" or main.game_state.launches_attempted != 0:
		return _fail(main, "Replay did not reset the faction and round counter.")
	if main.game_state.game_over or main.game_state.days_elapsed != 0:
		return _fail(main, "Replay did not reset the match state.")

	_cleanup(main)
	print("Demo two-round flow smoke test passed.")
	quit(0)


func _fail(main, message: String) -> void:
	_cleanup(main)
	push_error(message)
	quit(1)


func _cleanup(main) -> void:
	if main != null and is_instance_valid(main):
		main.settings_loaded = false
		main.queue_free()
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))
