extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://demo_opening_flow_smoke_settings.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := MainScene.instantiate()
	main.settings_file_path = TEST_SETTINGS_PATH
	main.demo_mode = true
	main.opening_glitch_duration = 0.05
	main.play_intro_on_boot = false
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920.0, 1080.0)
	await process_frame
	await process_frame

	main._start_opening_transition()
	if main.opening_glitch_layer == null:
		return _fail(main, "Demo Start did not begin the opening glitch.")

	await create_timer(0.1).timeout
	await process_frame
	if main.opening_glitch_layer != null:
		return _fail(main, "Demo opening glitch was not cleaned up.")
	if main.active_screen == null or main.active_screen.name != "FactionSelectScreen":
		return _fail(main, "Demo opening did not go directly to faction selection.")
	if main.corner_logo == null or not main.corner_logo.visible:
		return _fail(main, "Faction selection did not restore the corner logo.")

	_cleanup(main)
	print("Demo opening flow smoke test passed.")
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
