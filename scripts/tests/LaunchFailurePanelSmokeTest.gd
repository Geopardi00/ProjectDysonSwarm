extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://launch_failure_panel_smoke_settings.cfg"


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

	main._show_launch_result({
		"success": false,
		"vehicle_name": "Big Rocket",
		"launch_days": 7,
		"placed_fuel": 100,
		"required_fuel": 200,
		"readiness_before": 25.0,
	})
	await process_frame

	var panel := main.active_screen.get_node("LaunchFailurePanel") as TextureRect
	var text_group := panel.get_node("FailureText") as VBoxContainer
	var details := text_group.get_node("Details") as Label
	var continue_button := main.active_screen.get_node("ContinueButton") as Button
	if panel.texture == null or not panel.texture.resource_path.ends_with("launch_failure_panel.png"):
		_fail(main, "Launch failure screen did not use launch_failure_panel.png.")
		return
	if panel.size != Vector2(812.0, 781.0) or panel.texture.get_size() != Vector2(812.0, 781.0):
		_fail(main, "Launch failure panel did not retain its native 812x781 size.")
		return
	if not details.text.contains("Launch failed. Cargo lost."):
		_fail(main, "Launch failure information was not placed inside the panel.")
		return
	if continue_button.position.y <= panel.position.y + panel.size.y:
		_fail(main, "Launch failure Continue button was not below the panel.")
		return

	var panel_position := panel.position
	var text_position := text_group.position
	var button_position := continue_button.position
	main.launch_failure_panel_x += 8.0
	main.launch_failure_panel_y += 10.0
	main.launch_failure_text_x += 12.0
	main.launch_failure_text_y += 14.0
	if panel.position != panel_position + Vector2(8.0, 10.0):
		_fail(main, "Launch failure panel Inspector controls did not update live.")
		return
	if text_group.position != text_position + Vector2(12.0, 14.0):
		_fail(main, "Launch failure text Inspector controls did not update live.")
		return
	if continue_button.position != button_position + Vector2(8.0, 10.0):
		_fail(main, "Launch failure Continue button did not follow the panel position.")
		return

	_cleanup(main)
	print("Launch failure panel smoke test passed.")
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
