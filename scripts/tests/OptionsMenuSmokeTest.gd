extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://options_menu_smoke_test.cfg"

var main_instance
var master_bus := -1
var music_bus := -1
var sfx_bus := -1
var original_master_db := 0.0
var original_master_muted := false
var original_music_db := 0.0
var original_music_muted := false
var original_sfx_db := 0.0
var original_sfx_muted := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_remove_test_settings()
	master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		original_master_db = AudioServer.get_bus_volume_db(master_bus)
		original_master_muted = AudioServer.is_bus_mute(master_bus)
	music_bus = AudioServer.get_bus_index("Music")
	sfx_bus = AudioServer.get_bus_index("SFX")
	if music_bus >= 0:
		original_music_db = AudioServer.get_bus_volume_db(music_bus)
		original_music_muted = AudioServer.is_bus_mute(music_bus)
	if sfx_bus >= 0:
		original_sfx_db = AudioServer.get_bus_volume_db(sfx_bus)
		original_sfx_muted = AudioServer.is_bus_mute(sfx_bus)

	main_instance = MainScene.instantiate()
	main_instance.settings_file_path = TEST_SETTINGS_PATH
	root.add_child(main_instance)
	main_instance.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main_instance.size = Vector2(1920, 1080)
	await process_frame
	await process_frame

	var opening_stack := main_instance.active_screen.get_node_or_null("Layout/ButtonStack") as VBoxContainer
	if opening_stack == null or opening_stack.get_child_count() != 3:
		_fail("Opening menu did not contain three buttons.")
		return
	var expected_names := ["StartButton", "OptionsButton", "ExitButton"]
	for index: int in range(expected_names.size()):
		if opening_stack.get_child(index).name != expected_names[index]:
			_fail("Opening menu buttons were not ordered Start, Options, Exit.")
			return

	main_instance._show_options_screen()
	await process_frame
	var options := main_instance.active_screen as OptionsScreen
	if options == null:
		_fail("Options button flow did not open OptionsScreen.")
		return
	if options.panel_art.texture == null or options.panel_art.texture.resource_path != "res://assets/ui/panels/panel_options.png":
		_fail("Options screen did not use panel_options.png.")
		return
	if not is_equal_approx(options.panel_art.modulate.a, 0.85):
		_fail("Options panel did not use 85 percent opacity.")
		return
	if options.get_selected_difficulty() != "hard":
		_fail("Options did not default to Hard difficulty.")
		return

	options.volume_slider.value = 35.0
	options.music_volume_slider.value = 45.0
	options.sfx_volume_slider.value = 55.0
	options.brightness_slider.value = 125.0
	options.difficulty_option.select(0)
	options.difficulty_option.item_selected.emit(0)
	await process_frame
	if not is_equal_approx(main_instance.master_volume_percent, 35.0):
		_fail("Master volume slider did not update Main.")
		return
	if master_bus >= 0 and (AudioServer.is_bus_mute(master_bus) or not is_equal_approx(AudioServer.get_bus_volume_db(master_bus), linear_to_db(0.35))):
		_fail("Master volume slider did not update the Master audio bus.")
		return
	if (
		music_bus < 0
		or sfx_bus < 0
		or not is_equal_approx(main_instance.music_bus_volume_percent, 45.0)
		or not is_equal_approx(main_instance.sfx_bus_volume_percent, 55.0)
		or not is_equal_approx(AudioServer.get_bus_volume_db(music_bus), linear_to_db(0.45))
		or not is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), linear_to_db(0.55))
	):
		_fail("Music or SFX volume slider did not update its audio bus.")
		return
	var brightness_color: Color = main_instance.brightness_filter.color
	if (
		not is_equal_approx(main_instance.brightness_percent, 125.0)
		or not is_equal_approx(brightness_color.r, 1.0)
		or not is_equal_approx(brightness_color.g, 1.0)
		or not is_equal_approx(brightness_color.b, 1.0)
		or not is_equal_approx(brightness_color.a, 0.1)
	):
		_fail("Brightness slider did not apply the expected brightening filter.")
		return
	if main_instance.selected_difficulty != "easy":
		_fail("Difficulty selector did not update Main.")
		return
	if main_instance.game_state.active_difficulty != "hard":
		_fail("Changing difficulty modified the active match instead of the next match.")
		return

	main_instance._save_settings()
	var saved_config := ConfigFile.new()
	if saved_config.load(TEST_SETTINGS_PATH) != OK:
		_fail("Options settings were not saved.")
		return
	if not is_equal_approx(float(saved_config.get_value("audio", "master_volume_percent", -1.0)), 35.0):
		_fail("Saved Master volume value was incorrect.")
		return
	if not is_equal_approx(float(saved_config.get_value("audio", "music_volume_percent", -1.0)), 45.0):
		_fail("Saved Music volume value was incorrect.")
		return
	if not is_equal_approx(float(saved_config.get_value("audio", "sfx_volume_percent", -1.0)), 55.0):
		_fail("Saved SFX volume value was incorrect.")
		return
	if not is_equal_approx(float(saved_config.get_value("display", "brightness_percent", -1.0)), 125.0):
		_fail("Saved brightness value was incorrect.")
		return
	if String(saved_config.get_value("gameplay", "difficulty", "")) != "easy":
		_fail("Saved difficulty value was incorrect.")
		return
	main_instance.master_volume_percent = 100.0
	main_instance.music_bus_volume_percent = 100.0
	main_instance.sfx_bus_volume_percent = 100.0
	main_instance.brightness_percent = 100.0
	main_instance.selected_difficulty = "hard"
	main_instance._load_settings()
	if (
		not is_equal_approx(main_instance.master_volume_percent, 35.0)
		or not is_equal_approx(main_instance.music_bus_volume_percent, 45.0)
		or not is_equal_approx(main_instance.sfx_bus_volume_percent, 55.0)
		or not is_equal_approx(main_instance.brightness_percent, 125.0)
		or main_instance.selected_difficulty != "easy"
	):
		_fail("Options settings were not restored from disk.")
		return
	main_instance.game_state.start_new_match("USA", main_instance.selected_difficulty)
	if main_instance.game_state.active_difficulty != "easy":
		_fail("The next match did not adopt the saved difficulty.")
		return

	options.show_instructions_page()
	if not options.is_showing_instructions() or not options.instructions_label.text.contains("Reach 100% moonbase readiness before competing factions."):
		_fail("How To Play did not open the requested instructions page.")
		return
	options.show_options_page()
	if options.is_showing_instructions():
		_fail("Instructions Back navigation did not return to Options.")
		return
	options.back_requested.emit()
	await process_frame
	if main_instance.active_screen == null or main_instance.active_screen.name != "OpeningScreen":
		_fail("Options Back navigation did not return to the opening menu.")
		return

	_cleanup()
	print("Options menu smoke test passed.")
	quit(0)


func _cleanup() -> void:
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, original_master_db)
		AudioServer.set_bus_mute(master_bus, original_master_muted)
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, original_music_db)
		AudioServer.set_bus_mute(music_bus, original_music_muted)
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, original_sfx_db)
		AudioServer.set_bus_mute(sfx_bus, original_sfx_muted)
	if main_instance != null and is_instance_valid(main_instance):
		main_instance.settings_loaded = false
		main_instance.queue_free()
	_remove_test_settings()


func _remove_test_settings() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_path)


func _fail(message: String) -> void:
	_cleanup()
	push_error(message)
	quit(1)
