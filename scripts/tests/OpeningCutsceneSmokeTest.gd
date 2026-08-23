extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://opening_cutscene_smoke_settings.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := MainScene.instantiate()
	main.settings_file_path = TEST_SETTINGS_PATH
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920, 1080)
	await process_frame
	await process_frame
	main.get_node("EditorOpeningPreview").visible = true
	await process_frame

	var runtime_layout := main.active_screen.get_node_or_null("Layout") as VBoxContainer
	var preview_layout := main.get_node_or_null("EditorOpeningPreview/Layout") as VBoxContainer
	if runtime_layout == null or preview_layout == null:
		_fail("Opening screen layouts were not available for comparison.")
		return
	var runtime_logo := runtime_layout.get_node_or_null("TitleLogo") as TextureRect
	var preview_logo := preview_layout.get_node_or_null("TitleLogo") as TextureRect
	var runtime_buttons := runtime_layout.get_node_or_null("ButtonStack") as VBoxContainer
	var preview_buttons := preview_layout.get_node_or_null("ButtonStack") as VBoxContainer
	if runtime_logo == null or preview_logo == null:
		_fail("Opening title logos were not available for comparison.")
		return
	if runtime_buttons == null or preview_buttons == null or runtime_buttons.get_child_count() != 3 or preview_buttons.get_child_count() != 3:
		_fail("Opening menu did not provide matching Start, Options, and Exit button stacks.")
		return
	var expected_button_names := ["StartButton", "OptionsButton", "ExitButton"]
	for index: int in range(expected_button_names.size()):
		if runtime_buttons.get_child(index).name != expected_button_names[index] or preview_buttons.get_child(index).name != expected_button_names[index]:
			_fail("Opening menu button order did not match the editor preview.")
			return
	if not is_equal_approx(runtime_logo.global_position.y, preview_logo.global_position.y):
		_fail("Runtime opening title position did not match the editor preview: %.1f vs %.1f." % [
			runtime_logo.global_position.y,
			preview_logo.global_position.y,
		])
		return
	if not is_equal_approx(runtime_buttons.global_position.y, preview_buttons.global_position.y):
		_fail("Runtime opening button stack position did not match the editor preview.")
		return

	main.opening_glitch_duration = 0.05
	main.cutscene_explosion_time = 0.0
	main._show_opening_cutscene()
	await process_frame
	if main.opening_glitch_layer == null:
		_fail("Opening glitch effect did not start before the cutscene.")
		return
	if main.opening_cutscene_layer != null:
		_fail("Opening cutscene started before the glitch effect finished.")
		return
	await create_timer(0.1).timeout
	await process_frame

	if main.opening_cutscene_layer == null:
		_fail("Opening cutscene layer was not created.")
		return
	if main.opening_cutscene_player == null or not main.opening_cutscene_player.is_playing():
		_fail("Opening cutscene video did not start playing.")
		return
	if main.cutscene_explosion_player == null or not main.cutscene_explosion_player.is_playing():
		_fail("Cutscene explosion sound did not play at its configured time.")
		return
	if main.music_player != null and main.music_player.stream_paused:
		_fail("Background music was paused during the cutscene.")
		return

	main._finish_opening_cutscene()
	await process_frame

	if main.opening_cutscene_layer != null or main.opening_cutscene_player != null:
		_fail("Opening cutscene was not cleaned up after finishing.")
		return
	if main.active_screen == null:
		_fail("Faction selection did not open after the cutscene.")
		return
	if main.corner_logo == null or not main.corner_logo.visible:
		_fail("Faction selection did not restore the corner logo.")
		return

	main.settings_loaded = false
	_remove_test_settings()
	print("Opening cutscene smoke test passed.")
	quit(0)


func _fail(message: String) -> void:
	_remove_test_settings()
	push_error(message)
	quit(1)


func _remove_test_settings() -> void:
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))
