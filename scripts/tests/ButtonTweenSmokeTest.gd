extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://button_tween_smoke_settings.cfg"


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

	var button := Button.new()
	button.position = Vector2(500.0, 300.0)
	button.size = Vector2(240.0, 60.0)
	button.text = "Tween test"
	main.add_child(button)
	await process_frame
	if not button.has_meta(&"dyson_ui_tween_connected") or button.pivot_offset != button.size * 0.5:
		_fail(main, "Dynamic button did not receive a centered global tween.")
		return

	var scaled_button := Button.new()
	var scaled_button_original_position := Vector2(820.0, 300.0)
	scaled_button.position = scaled_button_original_position
	scaled_button.size = Vector2(240.0, 60.0)
	scaled_button.scale = Vector2(0.75, 0.75)
	main.add_child(scaled_button)
	await process_frame
	var scaled_visual_origin := scaled_button.position + Vector2(
		(1.0 - scaled_button.scale.x) * scaled_button.pivot_offset.x,
		(1.0 - scaled_button.scale.y) * scaled_button.pivot_offset.y
	)
	if not scaled_visual_origin.is_equal_approx(scaled_button_original_position):
		_fail(main, "Centering the tween pivot moved an already-scaled button.")
		return

	button.mouse_entered.emit()
	await create_timer(0.14).timeout
	if not button.scale.is_equal_approx(Vector2.ONE * main.button_hover_scale):
		_fail(main, "Button hover tween did not reach its configured scale.")
		return

	button.button_down.emit()
	await create_timer(0.08).timeout
	if not button.scale.is_equal_approx(Vector2.ONE * main.button_press_scale):
		_fail(main, "Button press tween did not reach its configured scale.")
		return
	button.button_up.emit()
	await create_timer(0.13).timeout
	if not button.scale.is_equal_approx(Vector2.ONE * main.button_hover_scale):
		_fail(main, "Button release did not return to the hovered scale.")
		return

	button.mouse_exited.emit()
	button.mouse_entered.emit()
	button.mouse_exited.emit()
	await create_timer(0.14).timeout
	if not button.scale.is_equal_approx(Vector2.ONE) or not button.self_modulate.is_equal_approx(Color.WHITE):
		_fail(main, "Rapid hover replacement did not restore the button.")
		return

	button.disabled = true
	button.mouse_entered.emit()
	await create_timer(0.14).timeout
	if not button.scale.is_equal_approx(Vector2.ONE):
		_fail(main, "Disabled button responded to the hover tween.")
		return

	main.cargo_loading_screen.start_assignment("big_rocket")
	await process_frame
	var fuel_button := main.cargo_loading_screen.get_node(
		"RootMargin/Layout/AssignmentPanel/AssignmentInfoPanel/Margin/InfoContent/MaterialButtons/FuelButton"
	) as Button
	if not fuel_button.has_meta(&"skip_global_button_tween") or fuel_button.has_meta(&"dyson_ui_tween_connected"):
		_fail(main, "Cargo material button was not excluded from global tweens.")
		return
	main.button_hover_player.stop()
	var fuel_base_scale := fuel_button.scale
	fuel_button.mouse_entered.emit()
	await create_timer(0.14).timeout
	if fuel_button.scale != fuel_base_scale or not main.button_hover_player.playing:
		_fail(main, "Excluded cargo material button lost sounds or gained a tween.")
		return

	main.button_navigation_delay = 0.08
	main._show_opening_screen()
	await process_frame
	var delayed_opening_screen: Control = main.active_screen
	var opening_options_button := main.active_screen.get_node("Layout/ButtonStack/OptionsButton") as Button
	opening_options_button.pressed.emit()
	if main.active_screen != delayed_opening_screen:
		_fail(main, "Opening Options navigation ignored the configured button delay.")
		return
	await create_timer(0.12).timeout
	if not main.active_screen is OptionsScreen:
		_fail(main, "Opening Options navigation did not run after the configured delay.")
		return
	var options_back_button := main.active_screen.get_node("PanelCenter/Panel/ContentMargin/OptionsPage/OptionsBackButton") as Button
	options_back_button.pressed.emit()
	if not main.active_screen is OptionsScreen:
		_fail(main, "Options Back navigation ignored the configured button delay.")
		return
	await create_timer(0.12).timeout
	if main.active_screen is OptionsScreen:
		_fail(main, "Options Back navigation did not run after the configured delay.")
		return

	_cleanup(main)
	print("Button tween smoke test passed.")
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
