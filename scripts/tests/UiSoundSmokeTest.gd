extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://ui_sound_smoke_settings.cfg"


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

	if main.button_hover_player == null or main.button_hover_player.stream.resource_path != "res://audio/sfx/button_hover.wav":
		_fail(main, "Hover player did not use button_hover.wav.")
		return
	if main.button_click_player == null or main.button_click_player.stream.resource_path != "res://audio/sfx/button_click.wav":
		_fail(main, "Click player did not use button_click.wav.")
		return
	if main.button_hover_player.bus != &"SFX" or main.button_click_player.bus != &"SFX":
		_fail(main, "UI sounds were not routed to the SFX bus.")
		return
	main.button_hover_volume_percent = 25.0
	main.button_click_volume_percent = 40.0
	if (
		not is_equal_approx(main.button_hover_player.volume_db, linear_to_db(0.25))
		or not is_equal_approx(main.button_click_player.volume_db, linear_to_db(0.4))
	):
		_fail(main, "UI sound Inspector volume sliders did not update the players.")
		return
	if main.music_player == null:
		_fail(main, "Background music player was not available for volume testing.")
		return
	if main.music_player.bus != &"Music":
		_fail(main, "Background music was not routed to the Music bus.")
		return
	main.background_music_volume_percent = 30.0
	if not is_equal_approx(main.music_player.volume_db, linear_to_db(0.3)):
		_fail(main, "Background Music Inspector volume slider did not update the player.")
		return

	var dynamic_button := Button.new()
	dynamic_button.text = "UI sound test"
	main.add_child(dynamic_button)
	await process_frame
	if not dynamic_button.has_meta(&"dyson_ui_sound_connected"):
		_fail(main, "A dynamically created button did not receive UI sounds.")
		return

	main.button_hover_player.stop()
	main.button_hover_pitch_variation_percent = 3.0
	dynamic_button.mouse_entered.emit()
	if not main.button_hover_player.playing:
		_fail(main, "Button hover did not play the hover sound.")
		return
	if main.button_hover_player.pitch_scale < 0.97 or main.button_hover_player.pitch_scale > 1.03:
		_fail(main, "Button hover pitch variation exceeded its configured range.")
		return
	main.button_hover_pitch_variation_percent = 0.0
	dynamic_button.mouse_entered.emit()
	if not is_equal_approx(main.button_hover_player.pitch_scale, 1.0):
		_fail(main, "Disabling button hover pitch variation did not restore neutral pitch.")
		return

	main.button_click_player.stop()
	dynamic_button.button_down.emit()
	if not main.button_click_player.playing:
		_fail(main, "Button press did not play the click sound.")
		return

	_cleanup(main)
	print("UI sound smoke test passed.")
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
