extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://pause_menu_smoke_settings.cfg"


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

	main._on_faction_button_pressed("USA")
	main._on_start_match_pressed()
	await process_frame
	var strategy_screen = main.active_screen
	var cancel_event := InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	main._unhandled_input(cancel_event)
	await process_frame
	if main.pause_overlay == null or main.active_screen != strategy_screen:
		_fail(main, "Pause did not preserve the active strategy screen.")
		return
	var expected_buttons: Array[String] = ["ResumeButton", "OptionsButton", "HowToPlayButton", "QuitToMainButton", "ExitGameButton"]
	var buttons: VBoxContainer = main.pause_overlay.get_node("PanelCenter/Panel/ContentMargin/Buttons") as VBoxContainer
	var actual_button_names: Array[String] = []
	for child: Node in buttons.get_children():
		if child is Button:
			actual_button_names.append(child.name)
	if actual_button_names != expected_buttons:
		_fail(main, "Pause menu actions were missing or out of order.")
		return

	main._show_pause_options()
	await process_frame
	if main.pause_options_screen == null or main.pause_options_screen.background.visible:
		_fail(main, "Paused Options did not open over the preserved gameplay screen.")
		return
	main.pause_options_screen.show_instructions_page()
	if not main.pause_options_screen.is_showing_instructions():
		_fail(main, "Paused How To Play page did not open.")
		return
	main._return_to_pause_menu()
	await process_frame
	main._unhandled_input(cancel_event)
	await process_frame
	if main.pause_overlay != null or main.active_screen != strategy_screen:
		_fail(main, "Resuming did not return to the preserved strategy screen.")
		return

	main._open_assignment_screen("big_rocket")
	await process_frame
	var assignment = main.cargo_loading_screen.assignment
	main._open_pause_menu()
	await process_frame
	main._close_pause_menu()
	await process_frame
	if not main.cargo_loading_screen.visible or main.cargo_loading_screen.assignment != assignment:
		_fail(main, "Pause did not preserve the in-progress cargo assignment.")
		return

	_cleanup(main)
	print("Pause menu smoke test passed.")
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
